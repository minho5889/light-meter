//
//  LMActivityVerdict.swift
//  LightMeter
//
//  The Analysis tab's tap-through verdict, per the Figma 04_Check_2 screen:
//  tapping an activity pill answers, in plain language, whether the CURRENT
//  light suits that activity — a brightness line (from the same lux-range ↔
//  activity mapping the grid already uses) and a color-temperature line
//  (from the activity's recommended CCT range). Rendered in-place over the
//  camera on the familiar dark glass; a bottom Back control returns to the
//  grid.
//

import SwiftUI

struct LMActivityVerdictView: View {
    let chip: ActivityChip
    let lux: Double
    let kelvin: Double
    var language: AppLanguage = .english

    private var name: String { chip.localizedName(language: language) }

    /// Which brightness verdict applies at the current lux.
    private var brightnessKey: String {
        let index = LuxRange.rangeIndex(for: lux)
        let suitable = chip.suitableLuxIndices
        guard let low = suitable.min(), let high = suitable.max() else {
            return "verdict_brightness_off"
        }
        if suitable.contains(index) { return "verdict_brightness_ideal" }
        if index < low { return "verdict_brightness_dark" }
        if index > high { return "verdict_brightness_bright" }
        return "verdict_brightness_off"   // inside min…max but in a gap
    }

    private var kelvinKey: String {
        if chip.suitableKelvin.contains(kelvin) { return "verdict_kelvin_good" }
        return kelvin < chip.suitableKelvin.lowerBound ? "verdict_kelvin_warm" : "verdict_kelvin_cool"
    }

    private func line(_ key: String) -> String {
        String(format: LocalizedStrings.translate(key: key, language: language), name)
    }

    var body: some View {
        VStack(spacing: 28) {
            verdictBlock(headline: line(brightnessKey),
                         value: "\(Int(lux)) LUX")
            verdictBlock(headline: line(kelvinKey),
                         value: "\(Self.kelvinFormatter.string(from: NSNumber(value: kelvin)) ?? "\(Int(kelvin))") Kelvin")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .lmGlass(tint: LM.readoutGlass, dark: true)
        .accessibilityElement(children: .combine)
    }

    private func verdictBlock(headline: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(headline)
                .font(LM.font(LM.FontSize.h2, .bold))
                .foregroundStyle(LM.readoutText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(value)
                .font(LM.font(LM.FontSize.body, .regular))
                .foregroundStyle(LM.readoutText.opacity(0.85))
        }
    }

    private static let kelvinFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()
}

#Preview("Verdict") {
    ZStack {
        Color(hex: 0x8A8A86).ignoresSafeArea()
        LMActivityVerdictView(chip: .tvAndMovies, lux: 150, kelvin: 3800, language: .korean)
            .padding(.horizontal, LM.readoutMargin)
    }
}
