//
//  LMActivityVerdict.swift
//  LightMeter
//
//  The Analysis tab's tap-through verdict: tapping an activity pill answers
//  whether the CURRENT light suits that activity. Copy and the per-activity
//  lux/Kelvin ranges come verbatim from the team's "Light Meter.xlsx"
//  In-App Text sheet; the layout is:
//
//      <Activity name>
//      Brightness:
//      <verdict sentence>
//      <current> -> <min> ~ <max> LUX
//      Color Temperature:
//      <verdict sentence>
//      <current> -> <min> ~ <max> K
//
//  Rendered in-place over the camera on the standard dark glass; a bottom
//  Back control returns to the grid.
//

import SwiftUI

struct LMActivityVerdictView: View {
    let chip: ActivityChip
    let lux: Double
    let kelvin: Double
    var language: AppLanguage = .english

    private var brightnessKey: String {
        if chip.suitableLux.contains(lux) { return "verdict_brightness_good" }
        return lux < chip.suitableLux.lowerBound ? "verdict_brightness_dark" : "verdict_brightness_bright"
    }

    private var kelvinKey: String {
        if chip.suitableKelvin.contains(kelvin) { return "verdict_kelvin_good" }
        return kelvin < chip.suitableKelvin.lowerBound ? "verdict_kelvin_low" : "verdict_kelvin_high"
    }

    private func t(_ key: String) -> String {
        LocalizedStrings.translate(key: key, language: language)
    }

    private func fmt(_ value: Double) -> String {
        Self.numberFormatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    /// "20 -> 30 ~ 100 LUX" — current reading vs the activity's suitable range.
    private func rangeLine(current: Double, range: ClosedRange<Double>, unit: String) -> String {
        "\(fmt(current)) -> \(fmt(range.lowerBound)) ~ \(fmt(range.upperBound)) \(unit)"
    }

    var body: some View {
        VStack(spacing: 22) {
            Text(chip.localizedName(language: language))
                .font(LM.font(LM.FontSize.h1, .bold))
                .foregroundStyle(LM.readoutText)
                .multilineTextAlignment(.center)

            verdictBlock(
                label: t("verdict_brightness_label"),
                sentence: t(brightnessKey),
                values: rangeLine(current: lux, range: chip.suitableLux, unit: "LUX"))

            verdictBlock(
                label: t("verdict_kelvin_label"),
                sentence: t(kelvinKey),
                values: rangeLine(current: kelvin, range: chip.suitableKelvin, unit: "K"))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .lmGlass(tint: LM.readoutGlass, dark: true)
        .accessibilityElement(children: .combine)
    }

    private func verdictBlock(label: String, sentence: String, values: String) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(LM.font(LM.FontSize.h2, .bold))
                .foregroundStyle(LM.readoutText)
            Text(sentence)
                .font(LM.font(LM.FontSize.body, .regular))
                .foregroundStyle(LM.readoutText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(values)
                .font(LM.font(LM.FontSize.body, .medium))
                .foregroundStyle(LM.readoutText.opacity(0.85))
        }
    }

    private static let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()
}

#Preview("Verdict") {
    ZStack {
        Color(hex: 0x8A8A86).ignoresSafeArea()
        LMActivityVerdictView(chip: .tvAndMovies, lux: 20, kelvin: 3500)
            .padding(.horizontal, LM.readoutMargin)
    }
}
