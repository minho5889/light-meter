//
//  LMCoach.swift
//  LightMeter
//
//  The AI Lighting Coach (Regular mode). Sends the captured snapshot + the
//  measured lux / color temperature to a model and shows expert, plain-language
//  lighting advice.
//
//  Backend-agnostic by design: the UI talks to a `LightingCoachService`. A
//  `StubLightingCoachService` makes the whole experience testable offline (and
//  on the simulator, which has no camera); `RemoteLightingCoachService` calls a
//  configured proxy endpoint (your Bedrock Nova 2 Lite / Claude Lambda) when
//  one is set. Nothing here ever holds a cloud key — that lives in the proxy.
//

import SwiftUI
import UIKit

// MARK: - Model

struct CoachAdvice: Equatable, Sendable {
    /// One-line verdict, e.g. "Cozy, but a bit dim to read."
    let headline: String
    /// A few short, actionable suggestions.
    let tips: [String]
}

// MARK: - Service

/// Takes the snapshot as JPEG `Data` (Sendable) rather than a UIImage, so it
/// crosses the async boundary cleanly under Swift 6 strict concurrency.
protocol LightingCoachService: Sendable {
    func advise(imageData: Data?, lux: Double, kelvin: Double, language: AppLanguage) async throws -> CoachAdvice
}

/// Picks the configured remote proxy if `lm_coach_endpoint` is set, else the
/// offline stub. Keeps the rest of the app from caring which is live.
enum LightingCoach {
    static func service() -> LightingCoachService {
        if let raw = UserDefaults.standard.string(forKey: "lm_coach_endpoint"),
           let url = URL(string: raw), !raw.isEmpty {
            return RemoteLightingCoachService(endpoint: url)
        }
        return StubLightingCoachService()
    }
}

// MARK: - Stub (offline, for build-out & simulator)

/// Believable, rule-based advice so the Coach UX is fully testable without a
/// backend. Swap for the real model by setting `lm_coach_endpoint`.
struct StubLightingCoachService: LightingCoachService {
    func advise(imageData: Data?, lux: Double, kelvin: Double, language: AppLanguage) async throws -> CoachAdvice {
        try? await Task.sleep(nanoseconds: 1_300_000_000)   // mimic model latency
        func t(_ en: String, _ ko: String, _ fr: String) -> String {
            switch language { case .korean: return ko; case .french: return fr; case .english: return en }
        }
        let dim = lux < 100, bright = lux > 400
        let warm = kelvin < 3300, cool = kelvin > 4700
        let level = dim ? t("dim", "어둡고", "tamisée")
                        : bright ? t("bright", "밝고", "lumineuse")
                                 : t("moderate", "적당하고", "modérée")
        let warmth = warm ? t("warm", "따뜻한", "chaude")
                          : cool ? t("cool", "차가운", "froide")
                                 : t("neutral", "중간", "neutre")
        let headline = t("This light is \(level) and \(warmth).",
                         "지금 빛은 \(level) \(warmth) 느낌이에요.",
                         "Cette lumière est \(level) et \(warmth).")
        var tips: [String] = []
        if dim {
            tips.append(t("To read or work, add a brighter lamp — aim for ~300–500 lux.",
                          "독서나 작업엔 더 밝은 조명을 더해 ~300–500 lux를 맞춰보세요.",
                          "Pour lire ou travailler, ajoute une lampe plus forte — vise ~300–500 lux."))
        }
        if bright && cool {
            tips.append(t("Great for focus, but harsh for evenings — warm it up after sunset.",
                          "집중엔 좋지만 저녁엔 눈이 부셔요 — 해가 지면 색을 따뜻하게 하세요.",
                          "Parfait pour se concentrer, mais dur le soir — réchauffe-la après le coucher du soleil."))
        }
        if warm && dim {
            tips.append(t("Lovely for relaxing or winding down before bed.",
                          "휴식이나 잠들기 전 분위기로 좋아요.",
                          "Idéale pour se détendre ou avant de dormir."))
        }
        if tips.isEmpty {
            tips.append(t("Nicely balanced for most everyday tasks.",
                          "대부분의 일상 활동에 잘 맞아요.",
                          "Bien équilibrée pour la plupart des tâches du quotidien."))
        }
        return CoachAdvice(headline: headline, tips: tips)
    }
}

// MARK: - Remote (proxy → Bedrock Nova 2 Lite / Claude)

/// Posts the snapshot + readings to your proxy and decodes the advice. The proxy
/// (a tiny Lambda) holds the cloud credentials and calls the model.
struct RemoteLightingCoachService: LightingCoachService {
    let endpoint: URL

    struct Payload: Encodable {
        let image_base64: String?
        let lux: Double
        let kelvin: Double
        let language: String
    }
    struct Response: Decodable {
        let headline: String
        let tips: [String]
    }

    func advise(imageData: Data?, lux: Double, kelvin: Double, language: AppLanguage) async throws -> CoachAdvice {
        let payload = Payload(
            image_base64: imageData?.base64EncodedString(),
            lux: lux, kelvin: kelvin,
            language: language.rawValue
        )
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return CoachAdvice(headline: decoded.headline, tips: decoded.tips)
    }
}

// MARK: - Coach sheet

struct LMCoachSheet: View {
    let image: UIImage?
    let lux: Double
    let kelvin: Double
    var language: AppLanguage = .english
    var service: LightingCoachService = StubLightingCoachService()

    @Environment(\.dismiss) private var dismiss
    @State private var advice: CoachAdvice?
    @State private var failed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label(t("Lighting Coach", "조명 코치", "Coach lumière"), systemImage: "sparkles")
                    .font(LM.font(LM.FontSize.h1, .bold))
                    .foregroundStyle(LM.textPrimary)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(LM.textSecondary)
                        .padding(8)
                        .background(Circle().fill(LM.glassTintStrong))
                }
                .buttonStyle(.plain)
            }

            if let image {
                Image(uiImage: image)
                    .resizable().scaledToFill()
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: LM.cardRadius, style: .continuous))
            }

            Text("\(Int(lux)) lux · \(Int(kelvin))K")
                .font(LM.font(LM.FontSize.caption, .semibold))
                .foregroundStyle(LM.textSecondary)

            if let advice {
                VStack(alignment: .leading, spacing: 12) {
                    Text(advice.headline)
                        .font(LM.font(LM.FontSize.h2, .bold))
                        .foregroundStyle(LM.accent)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(advice.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(LM.accent)
                                .padding(.top, 2)
                            Text(tip)
                                .font(LM.font(LM.FontSize.body, .medium))
                                .foregroundStyle(LM.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .transition(.opacity)
            } else if failed {
                VStack(alignment: .leading, spacing: 12) {
                    Text(t("Couldn't reach the coach.", "코치에 연결하지 못했어요.", "Coach injoignable."))
                        .font(LM.font(LM.FontSize.body, .medium))
                        .foregroundStyle(LM.textPrimary)
                    Button(t("Try again", "다시 시도", "Réessayer")) { Task { await load() } }
                        .font(LM.font(LM.FontSize.body, .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(Capsule().fill(LM.accent))
                }
            } else {
                HStack(spacing: 10) {
                    ProgressView().tint(LM.accent)
                    Text(t("Reading your light…", "빛을 분석하고 있어요…", "Analyse de ta lumière…"))
                        .font(LM.font(LM.FontSize.body, .medium))
                        .foregroundStyle(LM.textSecondary)
                }
                .padding(.vertical, 8)
            }

            Spacer(minLength: 0)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .presentationDetents([.medium, .large])
        .task { await load() }
    }

    private func load() async {
        advice = nil
        failed = false
        // Convert to Data here (on the main actor) so nothing non-Sendable
        // crosses into the service.
        let data = image.flatMap { LMImage.jpegData($0, maxDimension: 1024, quality: 0.6) }
        do {
            let result = try await service.advise(imageData: data, lux: lux, kelvin: kelvin, language: language)
            withAnimation(.easeOut(duration: 0.25)) { advice = result }
        } catch {
            withAnimation { failed = true }
        }
    }

    private func t(_ en: String, _ ko: String, _ fr: String) -> String {
        switch language { case .korean: return ko; case .french: return fr; case .english: return en }
    }
}
