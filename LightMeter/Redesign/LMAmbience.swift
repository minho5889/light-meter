//
//  LMAmbience.swift
//  LightMeter
//
//  The "Ambience" tab (Regular mode) — a Philips-Hue-style lighting advisor.
//  It reads the room's current brightness + color temperature and, for a chosen
//  mood scene, suggests how to adjust the in-room lighting (brighten / dim,
//  warm / cool) to dial that vibe in. Suggestions only — no hardware control.
//

import SwiftUI

// MARK: - Scene model

/// A Hue-style ambient lighting target: a mood with ideal lux + Kelvin ranges
/// and a warmth/level swatch.
struct LightScene: Identifiable {
    let id: String
    let icon: String
    let lux: ClosedRange<Double>
    let kelvin: ClosedRange<Double>
    let swatch: [Color]
    let nameEN: String
    let nameKO: String
    let nameFR: String

    func name(_ lang: AppLanguage) -> String {
        switch lang {
        case .korean:  return nameKO
        case .french:  return nameFR
        case .english: return nameEN
        }
    }

    var luxMid: Double { (lux.lowerBound + lux.upperBound) / 2 }
    var kelvinMid: Double { (kelvin.lowerBound + kelvin.upperBound) / 2 }

    /// Rough closeness of a reading to this scene (0 = perfect); lower is nearer.
    func distance(lux l: Double, kelvin k: Double) -> Double {
        let luxErr = abs(l - luxMid) / max(luxMid, 1)
        let kErr = abs(k - kelvinMid) / max(kelvinMid, 1)
        return luxErr + kErr
    }

    /// How the room's brightness should move toward this scene.
    /// `.increase` = brighten, `.decrease` = dim, `.ok` = already in range.
    func brightnessAdjust(lux: Double) -> SceneAdjust {
        if lux < self.lux.lowerBound { return .increase }
        if lux > self.lux.upperBound { return .decrease }
        return .ok
    }

    /// How the room's warmth should move toward this scene.
    /// `.increase` = warm it up (lower Kelvin), `.decrease` = cool it down.
    func warmthAdjust(kelvin: Double) -> SceneAdjust {
        if kelvin > self.kelvin.upperBound { return .increase }
        if kelvin < self.kelvin.lowerBound { return .decrease }
        return .ok
    }

    static let all: [LightScene] = [
        LightScene(id: "relax", icon: "moon.stars.fill", lux: 20...80, kelvin: 2000...2700,
                   swatch: [Color(hex: 0xFFB26B), Color(hex: 0xFF7E3D)],
                   nameEN: "Relax", nameKO: "휴식", nameFR: "Détente"),
        LightScene(id: "read", icon: "book.fill", lux: 300...500, kelvin: 3500...4500,
                   swatch: [Color(hex: 0xFFE7C2), Color(hex: 0xFFC279)],
                   nameEN: "Read", nameKO: "독서", nameFR: "Lecture"),
        LightScene(id: "focus", icon: "bolt.fill", lux: 500...750, kelvin: 4800...5800,
                   swatch: [Color(hex: 0xDCEBFF), Color(hex: 0x9FC2FF)],
                   nameEN: "Focus", nameKO: "집중", nameFR: "Focus"),
        LightScene(id: "dinner", icon: "fork.knife", lux: 100...200, kelvin: 2500...3000,
                   swatch: [Color(hex: 0xFFC78A), Color(hex: 0xF59E5E)],
                   nameEN: "Dinner", nameKO: "식사", nameFR: "Dîner"),
        LightScene(id: "movie", icon: "tv.fill", lux: 5...40, kelvin: 2400...2900,
                   swatch: [Color(hex: 0xC77B4A), Color(hex: 0x6E3F2E)],
                   nameEN: "Movie", nameKO: "영화", nameFR: "Cinéma"),
        LightScene(id: "winddown", icon: "bed.double.fill", lux: 5...20, kelvin: 1800...2300,
                   swatch: [Color(hex: 0xFF8A5C), Color(hex: 0xC6502F)],
                   nameEN: "Wind-down", nameKO: "취침 준비", nameFR: "Coucher"),
    ]

    /// Gen-Z aesthetic "looks" — same engine, trend-named targets. Names stay in
    /// English (global aesthetic vocabulary), like the vibe names.
    static let aesthetics: [LightScene] = [
        LightScene(id: "goldenhour", icon: "sun.horizon.fill", lux: 200...500, kelvin: 2500...3200,
                   swatch: [Color(hex: 0xFFB26B), Color(hex: 0xFF7E3D)],
                   nameEN: "Golden Hour", nameKO: "Golden Hour", nameFR: "Golden Hour"),
        LightScene(id: "cleangirl", icon: "sparkles", lux: 400...800, kelvin: 4500...5500,
                   swatch: [Color(hex: 0xEAF2FF), Color(hex: 0xC9D8EE)],
                   nameEN: "Clean Girl", nameKO: "Clean Girl", nameFR: "Clean Girl"),
        LightScene(id: "cottagecore", icon: "leaf.fill", lux: 60...180, kelvin: 2400...3000,
                   swatch: [Color(hex: 0xE8C98A), Color(hex: 0xB98E5A)],
                   nameEN: "Cottagecore", nameKO: "Cottagecore", nameFR: "Cottagecore"),
        LightScene(id: "darkacademia", icon: "books.vertical.fill", lux: 30...100, kelvin: 2300...2900,
                   swatch: [Color(hex: 0xA6743E), Color(hex: 0x5A3B22)],
                   nameEN: "Dark Academia", nameKO: "Dark Academia", nameFR: "Dark Academia"),
        LightScene(id: "y2k", icon: "sparkle", lux: 150...500, kelvin: 5000...6500,
                   swatch: [Color(hex: 0xB57BFF), Color(hex: 0xFF6AD5)],
                   nameEN: "Y2K Neon", nameKO: "Y2K Neon", nameFR: "Y2K Neon"),
        LightScene(id: "softgirl", icon: "heart.fill", lux: 250...600, kelvin: 3200...4200,
                   swatch: [Color(hex: 0xFFD6E0), Color(hex: 0xFFB39C)],
                   nameEN: "Soft Girl", nameKO: "Soft Girl", nameFR: "Soft Girl"),
    ]

    static func closest(in scenes: [LightScene], lux: Double, kelvin: Double) -> LightScene {
        scenes.min { $0.distance(lux: lux, kelvin: kelvin) < $1.distance(lux: lux, kelvin: kelvin) } ?? scenes[0]
    }

    static func closest(lux: Double, kelvin: Double) -> LightScene {
        closest(in: all, lux: lux, kelvin: kelvin)
    }
}

/// Direction a reading should move to reach a scene's target range.
enum SceneAdjust: Equatable { case ok, increase, decrease }

/// Which catalog the Ambience tab is showing.
enum AmbienceSet: String, CaseIterable { case moods, aesthetics }

// MARK: - Ambience screen

struct LMAmbienceView: View {
    let lux: Double
    let kelvin: Double
    var language: AppLanguage = .english

    @State private var selectedID: String?
    @State private var sceneSet: AmbienceSet = .moods

    private var hasReading: Bool { lux > 0.5 }
    private var scenes: [LightScene] { sceneSet == .moods ? LightScene.all : LightScene.aesthetics }
    private var selected: LightScene {
        scenes.first { $0.id == selectedID } ?? LightScene.closest(in: scenes, lux: lux, kelvin: kelvin)
    }

    private let columns = [GridItem(.flexible(), spacing: LM.gap),
                           GridItem(.flexible(), spacing: LM.gap)]

    var body: some View {
        ScrollView {
            VStack(spacing: LM.gap + 2) {
                header
                Picker("", selection: $sceneSet) {
                    Text(t("Moods", "무드", "Ambiances")).tag(AmbienceSet.moods)
                    Text(t("Aesthetics", "감성", "Esthétiques")).tag(AmbienceSet.aesthetics)
                }
                .pickerStyle(.segmented)
                LazyVGrid(columns: columns, spacing: LM.gap) {
                    ForEach(scenes) { scene in
                        sceneTile(scene)
                    }
                }
                if hasReading { guidanceCard }
            }
            .padding(.horizontal, LM.pad)
            .padding(.top, 64)
            .padding(.bottom, 140)
            .animation(.snappy(duration: 0.25), value: sceneSet)
        }
        .onChange(of: sceneSet) { _, _ in LMHaptics.tap(); selectedID = nil }
        .onAppear {
            #if DEBUG
            if ProcessInfo.processInfo.environment["LM_AMBSET"] == "aesthetics" { sceneSet = .aesthetics }
            #endif
        }
    }

    // MARK: header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(sceneSet == .moods
                 ? t("Set the mood", "분위기 설정", "Crée l'ambiance")
                 : t("Pick your aesthetic", "감성 고르기", "Choisis ton esthétique"))
                .font(LM.font(LM.FontSize.h1, .bold))
                .foregroundStyle(LM.textPrimary)
            if hasReading {
                Text(t("Now: \(Int(lux)) lx · \(Int(kelvin))K · \(warmthLabel(kelvin)). Closest to ",
                        "현재: \(Int(lux)) lx · \(Int(kelvin))K · \(warmthLabel(kelvin)). 가장 가까운 분위기는 ",
                        "Actuel : \(Int(lux)) lx · \(Int(kelvin))K · \(warmthLabel(kelvin)). Plus proche de ")
                     + LightScene.closest(in: scenes, lux: lux, kelvin: kelvin).name(language) + ".")
                    .font(LM.font(LM.FontSize.caption, .medium))
                    .foregroundStyle(LM.textSecondary)
            } else {
                Text(t("Point at your room to get lighting suggestions.",
                        "방을 비추면 조명 추천을 받을 수 있어요.",
                        "Vise ta pièce pour des suggestions d'éclairage."))
                    .font(LM.font(LM.FontSize.caption, .medium))
                    .foregroundStyle(LM.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LM.pad)
        .lmGlass(tint: LM.glassTintMed)
    }

    // MARK: scene tile

    private func sceneTile(_ scene: LightScene) -> some View {
        let isSelected = scene.id == selected.id && hasReading
        return Button {
            LMHaptics.tap()
            withAnimation(.snappy(duration: 0.2)) { selectedID = scene.id }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: scene.swatch, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    Image(systemName: scene.icon)
                        .font(.system(size: LM.FontSize.h2, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.25), radius: 2)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(scene.name(language))
                        .font(LM.font(LM.FontSize.body, .semibold))
                        .foregroundStyle(LM.textPrimary)
                    Text("\(warmthLabel(scene.kelvinMid)) · \(levelLabel(scene.luxMid))")
                        .font(LM.font(LM.FontSize.micro, .medium))
                        .foregroundStyle(LM.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lmGlass(tint: isSelected ? LM.glassTintStrong : LM.glassTintMed)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: LM.cardRadius, style: .continuous)
                        .strokeBorder(LM.accent, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: guidance

    private var guidanceCard: some View {
        let scene = selected
        return VStack(alignment: .leading, spacing: 8) {
            Text(scene.name(language))
                .font(LM.font(LM.FontSize.h2, .bold))
                .foregroundStyle(LM.textPrimary)
            Text(t("Aim ~\(Int(scene.luxMid)) lx · \(Int(scene.kelvinMid))K",
                    "목표 ~\(Int(scene.luxMid)) lx · \(Int(scene.kelvinMid))K",
                    "Vise ~\(Int(scene.luxMid)) lx · \(Int(scene.kelvinMid))K"))
                .font(LM.font(LM.FontSize.caption, .medium))
                .foregroundStyle(LM.textSecondary)
            Text(suggestion(for: scene))
                .font(LM.font(LM.FontSize.body, .semibold))
                .foregroundStyle(LM.accent)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LM.pad)
        .lmGlass(tint: LM.glassTintMed)
    }

    private func suggestion(for scene: LightScene) -> String {
        let name = scene.name(language)
        var parts: [String] = []
        switch scene.brightnessAdjust(lux: lux) {
        case .increase: parts.append(t("brighten the room", "조명을 더 밝게", "monte la luminosité"))
        case .decrease: parts.append(t("dim it down", "조명을 더 어둡게", "baisse l'intensité"))
        case .ok: break
        }
        switch scene.warmthAdjust(kelvin: kelvin) {
        case .increase: parts.append(t("warm the light", "색을 더 따뜻하게", "réchauffe la lumière"))
        case .decrease: parts.append(t("cool it down", "색을 더 차갑게", "refroidis la lumière"))
        case .ok: break
        }
        if parts.isEmpty {
            return t("You're right in the \(name) zone. ✨",
                     "지금 딱 \(name) 분위기예요. ✨",
                     "Tu es pile dans l'ambiance \(name). ✨")
        }
        let joined = parts.joined(separator: t(" and ", ", ", " et "))
        return t("For \(name): \(joined).",
                 "\(name) 분위기엔 \(joined) 해보세요.",
                 "Pour \(name) : \(joined).")
    }

    // MARK: labels & i18n

    private func warmthLabel(_ k: Double) -> String {
        if k < 3300 { return t("Warm", "따뜻함", "Chaud") }
        if k <= 4700 { return t("Neutral", "중간", "Neutre") }
        return t("Cool", "차가움", "Froid")
    }

    private func levelLabel(_ l: Double) -> String {
        if l < 100 { return t("Dim", "어두움", "Tamisé") }
        if l <= 400 { return t("Medium", "보통", "Moyen") }
        return t("Bright", "밝음", "Lumineux")
    }

    private func t(_ en: String, _ ko: String, _ fr: String) -> String {
        language.tr(en, ko, fr)
    }
}
