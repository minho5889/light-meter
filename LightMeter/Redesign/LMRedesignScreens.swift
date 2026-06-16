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
}

/// A single tappable item inside `LMCapsuleTabBar`.
private struct LMTabItem: View {
    let tab: LMTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 18, weight: .regular))
                Text(tab.rawValue)
                    .font(LM.font(LM.FontSize.micro, .medium))
            }
            .foregroundStyle(isSelected ? LM.textPrimary : LM.textSecondary)
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

    var body: some View {
        HStack(spacing: 4) {
            ForEach(LMTab.allCases) { tab in
                LMTabItem(tab: tab, isSelected: tab == selection) {
                    withAnimation(.snappy(duration: 0.22)) { selection = tab }
                }
            }
        }
        .padding(6)
        .lmGlass(cornerRadius: LM.pillRadius)
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
                .foregroundStyle(LM.textPrimary)
                .frame(width: 44, height: 44)
                .background {
                    Circle()
                        .fill(LM.glass)
                        .overlay { Circle().fill(LM.glassTintMed) }
                        .overlay { Circle().strokeBorder(LM.hairline, lineWidth: 1) }
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Readout Card

/// Top-left frosted readout card on the main screen: a large lux value with a
/// "LUX" unit, and the color-temperature underneath.
struct LMGlassReadoutCard: View {
    var lux: String = "120"
    var unit: String = "LUX"
    var temperature: String = "3,800K"

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(lux)
                    .font(LM.font(LM.FontSize.display, .bold))
                    .foregroundStyle(LM.textPrimary)
                Text(unit)
                    .font(LM.font(LM.FontSize.body, .semibold))
                    .foregroundStyle(LM.textSecondary)
            }
            Text(temperature)
                .font(LM.font(LM.FontSize.h2, .medium))
                .foregroundStyle(LM.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(width: 220, alignment: .leading)
        .lmGlass(tint: LM.glassTintSoft)
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
            .buttonStyle(.plain)

            // Flip-camera button, offset to the trailing side.
            HStack {
                Spacer()
                Button(action: onFlip) {
                    Image(systemName: "camera.rotate")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(LM.textPrimary)
                        .frame(width: 48, height: 48)
                        .background {
                            Circle()
                                .fill(LM.glass)
                                .overlay { Circle().fill(LM.glassTintMed) }
                                .overlay { Circle().strokeBorder(LM.hairline, lineWidth: 1) }
                        }
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 36)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Record Card

/// A single record card on the Records screen.
struct LMRecordCard: View {
    let record: LMRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: index (left) + date/time (right).
            HStack(alignment: .top) {
                Text("#\(record.index)")
                    .font(LM.font(LM.FontSize.body, .semibold))
                    .foregroundStyle(LM.textPrimary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(record.dateLine)
                        .font(LM.font(LM.FontSize.body, .medium))
                        .foregroundStyle(LM.textPrimary)
                    Text(record.timeLine)
                        .font(LM.font(LM.FontSize.caption))
                        .foregroundStyle(LM.textSecondary)
                }
            }

            Divider()
                .overlay(LM.hairline)

            // Two-column metrics.
            HStack(spacing: 0) {
                metric(title: "밝기", value: record.brightness)
                metric(title: "색온도", value: record.temperature)
            }
        }
        .padding(LM.pad)
        .frame(maxWidth: .infinity)
        .lmGlass(tint: LM.glassTintMed)
    }

    private func metric(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(LM.font(LM.FontSize.caption, .medium))
                .foregroundStyle(LM.textSecondary)
            Text(value)
                .font(LM.font(LM.FontSize.h2, .semibold))
                .foregroundStyle(LM.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// A record card with a trailing swipe-to-delete affordance, matching the
/// Figma "swiped" state (a red-tinted circular trash button revealed at the
/// trailing edge).
struct LMSwipableRecordCard: View {
    let record: LMRecord
    /// When `true` the card is shown in its revealed (swiped) state.
    var revealed: Bool = false
    var onDelete: () -> Void = {}

    private let revealWidth: CGFloat = 72

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button sitting behind the card's trailing edge.
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(LM.textPrimary)
                    .frame(width: 52, height: 52)
                    .background {
                        Circle()
                            .fill(LM.glass)
                            .overlay { Circle().fill(LM.deleteTint) }
                            .overlay { Circle().strokeBorder(LM.hairline, lineWidth: 1) }
                    }
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)

            LMRecordCard(record: record)
                .offset(x: revealed ? -revealWidth : 0)
        }
        .animation(.snappy(duration: 0.25), value: revealed)
    }
}

// MARK: - Records List

/// Scrollable list of record cards (with one card shown in its swiped state to
/// mirror the Figma render).
struct LMRecordsList: View {
    let records: [LMRecord]
    /// Index of the card to show in its revealed (swiped) state, if any.
    var revealedIndex: Int? = 1

    var body: some View {
        ScrollView {
            VStack(spacing: LM.gap + 4) {
                ForEach(Array(records.enumerated()), id: \.element.id) { idx, record in
                    LMSwipableRecordCard(record: record, revealed: idx == revealedIndex)
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
