//
//  LMRedesignScreens.swift
//  LightMeter
//
//  Faithful Figma -> SwiftUI redesign of the Light Meter app.
//
//  This file assembles reusable, LM-prefixed components into two full
//  preview/demo screens:
//
//    • LMMainScreen     — camera viewfinder with a frosted readout card,
//                         a settings button, capture controls, and the
//                         capsule tab bar.
//    • LMRecordsScreen  — a scrollable list of measurement record cards
//                         over the records gradient, plus the tab bar.
//
//  Everything here is self-contained, compilable, and uses the `LM` design
//  system (see LMDesign.swift) VERBATIM for colors, fonts, radii, materials,
//  and spacing. These are demo screens driven by mock data — they are NOT
//  wired to any app model.
//
//  iOS 17+ / SwiftUI.
//

import SwiftUI

// MARK: - Mock Model

/// A single light-measurement record (mock data for the demo screens).
struct LMRecord: Identifiable {
    let id = UUID()
    /// Display index, e.g. `3` → shown as "#3".
    let index: Int
    /// Pre-formatted date line, e.g. `2026-10-31`.
    let dateLine: String
    /// Pre-formatted time line (localized), e.g. `12:32 AM` / `오전 06:32`.
    let timeLine: String
    /// Brightness value with unit, e.g. `900 Lux`.
    let brightness: String
    /// Color-temperature value with unit, e.g. `1,200K`.
    let temperature: String
    /// The backing store record's id, used to delete on swipe. `nil` in previews.
    var recordID: UUID? = nil
}

extension LMRecord {
    /// Mock records mirroring the Figma "Records" screen content.
    static let mock: [LMRecord] = [
        LMRecord(index: 3, dateLine: "2026-10-31", timeLine: "12:32 AM",
                 brightness: "900 Lux", temperature: "1,200K"),
        LMRecord(index: 2, dateLine: "2026-09-27", timeLine: "오전 06:32",
                 brightness: "600 Lux", temperature: "5,600K"),
        LMRecord(index: 1, dateLine: "2026-05-26", timeLine: "오후 07:30",
                 brightness: "120 Lux", temperature: "3,800K"),
    ]
}

// MARK: - Tab Bar

/// The four primary tabs shown in the capsule tab bar.
enum LMTab: String, CaseIterable, Identifiable {
    case brightness  = "Brightness"
    case temperature = "Temperature"
    case check       = "Check"
    case records     = "Records"

    var id: String { rawValue }

    /// SF Symbol used for each tab (Inter/Figma icons approximated with SF Symbols).
    var symbol: String {
        switch self {
        case .brightness:  return "sun.max"
        case .temperature: return "thermometer.medium"
        case .check:       return "magnifyingglass"
        case .records:     return "record.circle"
        }
    }

    /// Localized tab label per the Figma design (Brightness · Color Temp ·
    /// Analysis · Records).
    func title(_ language: AppLanguage) -> String {
        let key: String
        switch self {
        case .brightness:  key = "tab_brightness"
        case .temperature: key = "tab_color_temp"
        case .check:       key = "tab_analysis"
        case .records:     key = "tab_records"
        }
        return LocalizedStrings.translate(key: key, language: language)
    }
}

/// A single tappable item inside `LMCapsuleTabBar`.
private struct LMTabItem: View {
    let tab: LMTab
    let isSelected: Bool
    var language: AppLanguage = .english
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 18, weight: .regular))
                Text(tab.title(language))
                    .font(LM.font(LM.FontSize.micro, .medium))
            }
            // On the dark bar: selected tab = dark text on a white pill;
            // unselected = light (near-white) text/icons.
            .foregroundStyle(isSelected ? LM.textPrimary : LM.readoutText.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: LM.pillRadius, style: .continuous)
                        .fill(LM.glassTintStrong)
                        .overlay {
                            RoundedRectangle(cornerRadius: LM.pillRadius, style: .continuous)
                                .strokeBorder(LM.hairline, lineWidth: 1)
                        }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Frosted capsule tab bar with four tabs and a glass highlight on the
/// selected item.
struct LMCapsuleTabBar: View {
    @Binding var selection: LMTab
    var language: AppLanguage = .english

    var body: some View {
        HStack(spacing: 4) {
            ForEach(LMTab.allCases) { tab in
                LMTabItem(tab: tab, isSelected: tab == selection, language: language) {
                    withAnimation(.snappy(duration: 0.22)) { selection = tab }
                }
            }
        }
        .padding(6)
        .lmGlass(cornerRadius: LM.pillRadius, tint: LM.readoutGlass, dark: true)
    }
}

// MARK: - Settings Button

/// Circular frosted "settings" button (top-right of each screen).
struct LMSettingsButton: View {
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: "gearshape")
                .font(.system(size: 18, weight: .regular))
        }
        .buttonStyle(LMGlassCircleButtonStyle(diameter: 44))
    }
}

// MARK: - Readout Card

/// A labelled row in the expanded readout, e.g. Color Tone → "Candlelight 🔥".
struct LMInfoRow: Identifiable {
    let id = UUID()
    let label: String
    let value: String
}

/// Top-left frosted readout card on the main screen: a large lux value with a
/// "LUX" unit, and the color-temperature underneath.
struct LMGlassReadoutCard: View {
    var lux: String = "120"
    var unit: String = "LUX"
    var temperature: String = "3,800K"
    /// Optional expanded "user guide" content. When `guideDescription` is set,
    /// the card grows to show a divider, an optional title, the description and
    /// an optional tip (the captured-state card in the Figma).
    var guideTitle: String? = nil
    var guideDescription: String? = nil
    var guideTip: String? = nil
    /// Optional labelled rows (Color Tone, Recommended environments) shown below
    /// the divider — the Temperature tab card in the Figma.
    var infoRows: [LMInfoRow] = []

    private var isExpanded: Bool { guideDescription != nil || !infoRows.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(lux)
                    .font(LM.font(LM.FontSize.display, .semibold))   // Semi Bold 50pt
                    .tracking(-1)                                     // -2% of 50pt
                    .foregroundStyle(LM.readoutNumberGradient)        // FAFAFA + gradation
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)                          // fit "100,000+" in-card
                Text(unit)
                    .font(LM.font(LM.FontSize.h2, .regular))          // Regular 16pt
                    .foregroundStyle(LM.readoutText)
            }
            Text(temperature)
                .font(LM.font(LM.FontSize.h1, .regular))              // Regular 18pt
                .foregroundStyle(LM.readoutText)

            if isExpanded {
                Rectangle()                                           // Line: FAFAFA 1pt
                    .fill(LM.readoutText.opacity(0.5))
                    .frame(height: 1)
                    .padding(.top, 6)

                if let guideTitle {
                    Text(guideTitle)                                  // title case per spec
                        .font(LM.font(LM.FontSize.caption, .bold))    // Bold 12pt
                        .foregroundStyle(LM.readoutText)
                        .padding(.top, 4)
                }
                if let guideDescription {
                    Text(guideDescription)
                        .font(LM.font(LM.FontSize.body, .bold))       // (env) Bold 14pt
                        .foregroundStyle(LM.readoutText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let guideTip {
                    Text(guideTip)
                        .font(LM.font(LM.FontSize.body, .regular))    // (tip) Regular 14pt
                        .foregroundStyle(LM.readoutText)              // full #FAFAFA per spec
                        .fixedSize(horizontal: false, vertical: true)
                }

                ForEach(infoRows) { row in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.label)
                            .font(LM.font(LM.FontSize.caption, .bold))
                            .foregroundStyle(LM.readoutText)
                        Text(row.value)
                            .font(LM.font(LM.FontSize.body, .regular))
                            .foregroundStyle(LM.readoutText)         // full #FAFAFA per spec
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)   // full-width card (Figma 318pt)
        .lmGlass(tint: LM.readoutGlass, dark: true)
        .animation(.snappy(duration: 0.25), value: isExpanded)
    }
}

// MARK: - Capture Controls

/// Bottom capture controls on the main screen: a large white shutter button
/// with a secondary glass "flip camera" button to its right.
struct LMCaptureControls: View {
    var onCapture: () -> Void = {}
    var onFlip: () -> Void = {}

    var body: some View {
        ZStack {
            // Centered shutter.
            Button(action: onCapture) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: LM.buttonCircle + 16, height: LM.buttonCircle + 16)
                    Circle()
                        .fill(.white)
                        .frame(width: LM.buttonCircle, height: LM.buttonCircle)
                        .overlay {
                            Circle().strokeBorder(LM.hairline, lineWidth: 2)
                        }
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
                }
            }
            .buttonStyle(LMShutterButtonStyle())

            // Flip-camera button, offset to the trailing side.
            HStack {
                Spacer()
                Button(action: onFlip) {
                    Image(systemName: "camera.rotate")
                        .font(.system(size: 18, weight: .regular))
                }
                .buttonStyle(LMGlassCircleButtonStyle(diameter: 46))
            }
            .padding(.trailing, 46)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Record Card

/// A single record card on the Records screen.
struct LMRecordCard: View {
    let record: LMRecord
    var language: AppLanguage = .english

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: index (left) + date/time (right).
            HStack(alignment: .top) {
                Text("#\(record.index)")
                    .font(LM.font(LM.FontSize.body, .semibold))
                    .foregroundStyle(LM.readoutText)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(record.dateLine)
                        .font(LM.font(LM.FontSize.body, .medium))
                        .foregroundStyle(LM.readoutText)
                    Text(record.timeLine)
                        .font(LM.font(LM.FontSize.caption))
                        .foregroundStyle(LM.readoutText.opacity(0.7))
                }
            }

            // Two-column metrics (Brightness / Temperature), left-aligned.
            HStack(alignment: .top, spacing: LM.gap) {
                metric(title: LocalizedStrings.translate(key: "tab_brightness", language: language),
                       value: record.brightness)
                metric(title: LocalizedStrings.translate(key: "tab_temperature", language: language),
                       value: record.temperature)
            }
        }
        .padding(LM.pad)
        .frame(maxWidth: .infinity)
        .lmGlass(tint: LM.readoutGlass, dark: true)
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(LM.font(LM.FontSize.caption, .medium))
                .foregroundStyle(LM.readoutText.opacity(0.7))
            Text(value)
                .font(LM.font(LM.FontSize.h2, .semibold))
                .foregroundStyle(LM.readoutText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// An interactive record row: drag the card left to reveal a red-tinted trash
/// button, then tap it to delete. Matches the Figma "swiped" state.
private struct LMSwipeRow: View {
    let record: LMRecord
    let revealed: Bool
    var language: AppLanguage = .english
    var onRevealChange: (Bool) -> Void
    var onDelete: () -> Void

    @State private var dragOffset: CGFloat = 0
    private let revealWidth: CGFloat = 76

    private var offset: CGFloat {
        let base = revealed ? -revealWidth : 0
        return min(0, max(-revealWidth - 16, base + dragOffset))
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Trash button revealed behind the card's trailing edge.
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(LM.readoutText)
                    .frame(width: 52, height: 52)
                    .background {
                        Circle()
                            .fill(LM.glass)
                            .environment(\.colorScheme, .dark)   // dark frosted circle
                            .overlay { Circle().fill(LM.readoutGlass) }
                            .overlay { Circle().strokeBorder(LM.hairline, lineWidth: 1) }
                    }
            }
            .buttonStyle(.plain)
            .padding(.trailing, 12)
            .opacity(offset < -8 ? 1 : 0)

            LMRecordCard(record: record, language: language)
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            if abs(value.translation.width) > abs(value.translation.height) {
                                dragOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            let projected = (revealed ? -revealWidth : 0) + value.translation.width
                            dragOffset = 0
                            onRevealChange(projected < -revealWidth / 2)
                        }
                )
        }
        .animation(.snappy(duration: 0.25), value: revealed)
        .animation(.interactiveSpring(response: 0.2), value: dragOffset)
    }
}

// MARK: - Records List

/// Scrollable list of record cards with interactive swipe-to-delete.
struct LMRecordsList: View {
    let records: [LMRecord]
    var language: AppLanguage = .english
    /// Called with the record to delete when its trash button is tapped.
    var onDelete: ((LMRecord) -> Void)? = nil

    @State private var revealedID: UUID? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: LM.gap + 4) {
                ForEach(records) { record in
                    LMSwipeRow(
                        record: record,
                        revealed: revealedID == record.id,
                        language: language,
                        onRevealChange: { open in
                            withAnimation(.snappy(duration: 0.25)) {
                                revealedID = open ? record.id : nil
                            }
                        },
                        onDelete: {
                            withAnimation(.snappy(duration: 0.25)) { revealedID = nil }
                            onDelete?(record)
                        }
                    )
                }
            }
            .padding(.horizontal, LM.pad)
            .padding(.top, LM.pad)
            .padding(.bottom, 120) // clear the floating tab bar
        }
    }
}

// MARK: - Camera Background Placeholder

/// A soft gray gradient standing in for the live camera feed in previews.
struct LMCameraBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0xD8D6D2),
                    Color(hex: 0xC2BEB8),
                    Color(hex: 0x9C9690),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            // Faint diagonal sheen to suggest a real photographic surface.
            LinearGradient(
                colors: [Color.white.opacity(0.25), Color.clear],
                startPoint: .topLeading,
                endPoint: .center
            )
            // Bottom scrim so controls read clearly.
            LM.scrimGradient
                .opacity(0.35)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Main Screen

/// Full main (camera) screen: viewfinder background, frosted readout card,
/// settings button, capture controls, and the capsule tab bar.
struct LMMainScreen: View {
    @State private var selection: LMTab = .brightness

    var body: some View {
        ZStack(alignment: .top) {
            LMCameraBackground()

            // Top row: readout card (left) + settings (right).
            HStack(alignment: .top) {
                LMGlassReadoutCard(lux: "120", unit: "LUX", temperature: "3,800K")
                Spacer()
                LMSettingsButton()
            }
            .padding(.horizontal, LM.pad)
            .padding(.top, LM.pad)

            // Bottom: capture controls above the tab bar.
            VStack(spacing: 0) {
                Spacer()
                LMCaptureControls()
                    .padding(.bottom, 28)
                LMCapsuleTabBar(selection: $selection)
                    .padding(.horizontal, LM.pad)
                    .padding(.bottom, LM.gap)
            }
        }
    }
}

// MARK: - Records Screen

/// Full records screen: scrollable list of record cards over the records
/// gradient, a settings button, and the capsule tab bar (Records active).
struct LMRecordsScreen: View {
    @State private var selection: LMTab = .records
    private let records = LMRecord.mock

    var body: some View {
        ZStack(alignment: .top) {
            LM.recordsGradient
                .ignoresSafeArea()

            LMRecordsList(records: records)

            // Floating settings button, top-right.
            HStack {
                Spacer()
                LMSettingsButton()
            }
            .padding(.horizontal, LM.pad)
            .padding(.top, LM.pad)

            // Floating tab bar pinned to the bottom.
            VStack {
                Spacer()
                LMCapsuleTabBar(selection: $selection)
                    .padding(.horizontal, LM.pad)
                    .padding(.bottom, LM.gap)
            }
        }
    }
}

// MARK: - Previews

#Preview("LM Main Screen") {
    LMMainScreen()
}

#Preview("LM Records Screen") {
    LMRecordsScreen()
}

#Preview("LM Components") {
    ZStack {
        LM.recordsGradient.ignoresSafeArea()
        VStack(spacing: LM.gap) {
            HStack(alignment: .top) {
                LMGlassReadoutCard()
                Spacer()
                LMSettingsButton()
            }
            LMRecordCard(record: LMRecord.mock[0])
            LMCaptureControls()
                .frame(height: 100)
            LMCapsuleTabBar(selection: .constant(.brightness))
        }
        .padding(LM.pad)
    }
}
