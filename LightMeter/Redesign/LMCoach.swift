//
//  LMCoach.swift
//  LightMeter
//
//  The AI Lighting Coach (Regular mode). Sends the captured snapshot + the
//  measured lux / color temperature to a model and returns:
//    • a Gen-Z "vibe" (aesthetic name + emoji) → a shareable Light Vibe card,
//    • a plain-language verdict + actionable lighting tips.
//
//  Backend-agnostic: the UI talks to a `LightingCoachService`. A
//  `StubLightingCoachService` makes the whole experience testable offline (and
//  on the simulator, which has no camera); `RemoteLightingCoachService` calls a
//  configured proxy (your Bedrock Nova 2 Lite / Claude Lambda) when one is set.
//  Nothing here holds a cloud key — that lives in the proxy.
//

import SwiftUI
import UIKit

// MARK: - Model

struct CoachAdvice: Equatable, Sendable {
    /// Aesthetic vibe name for the shareable card, e.g. "Golden Hour Glow".
    let vibe: String
    /// A single emoji that matches the vibe.
    let emoji: String
    /// One-line practical verdict, e.g. "Cozy, but a bit dim to read."
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

/// Believable, rule-based advice + vibe so the Coach UX is fully testable
/// without a backend. Swap for the real model by setting `lm_coach_endpoint`.
struct StubLightingCoachService: LightingCoachService {
    func advise(imageData: Data?, lux: Double, kelvin: Double, language: AppLanguage) async throws -> CoachAdvice {
        try? await Task.sleep(nanoseconds: 1_300_000_000)   // mimic model latency
        func t(_ en: String, _ ko: String, _ fr: String) -> String {
            switch language { case .korean: return ko; case .french: return fr; case .english: return en }
        }
        let dim = lux < 100, bright = lux > 400
        let warm = kelvin < 3300, cool = kelvin > 4700

        // Vibe names use global Gen-Z aesthetic vocabulary (kept in English on
        // purpose — these terms travel, and they render in the handwritten card font).
        let (vibe, emoji): (String, String)
        switch (dim, bright, warm, cool) {
        case (_, true, true, _):   (vibe, emoji) = ("Golden Hour Glow", "🌅")
        case (_, true, _, true):   (vibe, emoji) = ("Clean Girl Daylight", "🤍")
        case (_, true, _, _):      (vibe, emoji) = ("Main Character Energy", "✨")
        case (true, _, true, _):   (vibe, emoji) = ("Cozy Cabincore", "🕯️")
        case (true, _, _, true):   (vibe, emoji) = ("Moody Midnight", "🌃")
        case (true, _, _, _):      (vibe, emoji) = ("Sleepy Wind-down", "🌙")
        case (_, _, true, _):      (vibe, emoji) = ("Soft Sunset", "🌇")
        case (_, _, _, true):      (vibe, emoji) = ("Studio Clean", "🎬")
        default:                   (vibe, emoji) = ("Soft Daylight", "☁️")
        }

        let level = dim ? t("dim", "어둡고", "tamisée") : bright ? t("bright", "밝고", "lumineuse") : t("moderate", "적당하고", "modérée")
        let warmth = warm ? t("warm", "따뜻한", "chaude") : cool ? t("cool", "차가운", "froide") : t("neutral", "중간", "neutre")
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
        return CoachAdvice(vibe: vibe, emoji: emoji, headline: headline, tips: tips)
    }
}

// MARK: - Remote (proxy → Bedrock Nova 2 Lite / Claude)

struct RemoteLightingCoachService: LightingCoachService {
    let endpoint: URL

    struct Payload: Encodable {
        let image_base64: String?
        let lux: Double
        let kelvin: Double
        let language: String
    }
    struct Response: Decodable {
        let vibe: String?
        let emoji: String?
        let headline: String
        let tips: [String]
    }

    func advise(imageData: Data?, lux: Double, kelvin: Double, language: AppLanguage) async throws -> CoachAdvice {
        let payload = Payload(image_base64: imageData?.base64EncodedString(),
                              lux: lux, kelvin: kelvin, language: language.rawValue)
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
        return CoachAdvice(vibe: decoded.vibe ?? "Your Light",
                           emoji: decoded.emoji ?? "✨",
                           headline: decoded.headline,
                           tips: decoded.tips)
    }
}

// MARK: - Shareable Light Vibe card

/// The aesthetic, shareable card: the snapshot + the AI vibe name + readings +
/// app watermark. Sized relative to `width` so it looks identical on screen and
/// when rendered to a high-res image for sharing.
struct LMVibeCard: View {
    let image: UIImage?
    let emoji: String
    let vibe: String
    let lux: Double
    let kelvin: Double
    var width: CGFloat = 320

    private var height: CGFloat { width * 1.25 }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                LinearGradient(colors: [LM.accent, Color(hex: 0xC6502F)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            LinearGradient(colors: [.black.opacity(0.0), .black.opacity(0.15), .black.opacity(0.78)],
                           startPoint: .top, endPoint: .bottom)

            VStack(alignment: .leading, spacing: width * 0.018) {
                Spacer()
                Text(emoji).font(.system(size: width * 0.15))
                Text(vibe)
                    .font(.custom("CaveatBrush-Regular", size: width * 0.135))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(Int(lux)) lux · \(Int(kelvin))K")
                    .font(.system(size: width * 0.046, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                HStack(spacing: width * 0.018) {
                    Image(systemName: "sun.max.fill")
                    Text("Sunny Light Meter")
                }
                .font(.system(size: width * 0.04, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
                .padding(.top, width * 0.01)
            }
            .shadow(color: .black.opacity(0.4), radius: 4, y: 1)
            .padding(width * 0.07)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: width * 0.06, style: .continuous))
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
    @State private var shareCard: Image?

    var body: some View {
        ScrollView {
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

                if let advice {
                    LMVibeCard(image: image, emoji: advice.emoji, vibe: advice.vibe,
                               lux: lux, kelvin: kelvin, width: 300)
                        .frame(maxWidth: .infinity)
                        .transition(.opacity)

                    if let shareCard {
                        ShareLink(item: shareCard,
                                  preview: SharePreview(t("My light vibe", "내 빛 분위기", "Mon ambiance"),
                                                        image: shareCard)) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text(t("Share your vibe", "내 분위기 공유", "Partager mon ambiance"))
                            }
                            .font(LM.font(LM.FontSize.body, .semibold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Capsule().fill(LM.accent))
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(advice.headline)
                            .font(LM.font(LM.FontSize.h2, .bold))
                            .foregroundStyle(LM.textPrimary)
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
                    .padding(.vertical, 24)
                }
            }
            .padding(22)
        }
        .presentationDetents([.large])
        .task { await load() }
    }

    @MainActor
    private func load() async {
        advice = nil
        failed = false
        shareCard = nil
        let data = image.flatMap { LMImage.jpegData($0, maxDimension: 1024, quality: 0.6) }
        do {
            let result = try await service.advise(imageData: data, lux: lux, kelvin: kelvin, language: language)
            withAnimation(.easeOut(duration: 0.25)) { advice = result }
            renderShareCard(result)
        } catch {
            withAnimation { failed = true }
        }
    }

    @MainActor
    private func renderShareCard(_ advice: CoachAdvice) {
        let card = LMVibeCard(image: image, emoji: advice.emoji, vibe: advice.vibe,
                              lux: lux, kelvin: kelvin, width: 360)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        if let ui = renderer.uiImage { shareCard = Image(uiImage: ui) }
    }

    private func t(_ en: String, _ ko: String, _ fr: String) -> String {
        switch language { case .korean: return ko; case .french: return fr; case .english: return en }
    }
}
