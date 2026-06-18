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
    /// Stable identity = the backing record's id when present, so the list
    /// doesn't recreate rows (and re-decode photos) when the store reloads.
    let id: UUID
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
    /// The captured snapshot (downscaled JPEG), if any.
    var photoData: Data? = nil

    init(index: Int, dateLine: String, timeLine: String, brightness: String,
         temperature: String, recordID: UUID? = nil, photoData: Data? = nil) {
        self.id = recordID ?? UUID()
        self.index = index
        self.dateLine = dateLine
        self.timeLine = timeLine
        self.brightness = brightness
        self.temperature = temperature
        self.recordID = recordID
        self.photoData = photoData
    }
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
    case ambience    = "Ambience"
    case records     = "Records"

    var id: String { rawValue }

    /// SF Symbol used for each tab (Inter/Figma icons approximated with SF Symbols).
    var symbol: String {
        switch self {
        case .brightness:  return "sun.max"
        case .temperature: return "thermometer.medium"
        case .ambience:    return "lightbulb.fill"
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
    /// Optional expanded "user guide" content. When `guideDescription` is set,
    /// the card grows to show a divider, an optional title, the description and
    /// an optional tip (the captured-state card in the Figma).
    var guideTitle: String? = nil
    var guideDescription: String? = nil
    var guideTip: String? = nil

    private var isExpanded: Bool { guideDescription != nil }

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

            if isExpanded {
                Divider()
                    .overlay(LM.hairline)
                    .padding(.top, 6)

                if let guideTitle {
                    Text(guideTitle.uppercased())
                        .font(LM.font(LM.FontSize.caption, .semibold))
                        .foregroundStyle(LM.textSecondary)
                        .padding(.top, 4)
                }
                if let guideDescription {
                    Text(guideDescription)
                        .font(LM.font(LM.FontSize.body, .semibold))
                        .foregroundStyle(LM.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let guideTip {
                    Text(guideTip)
                        .font(LM.font(LM.FontSize.caption))
                        .foregroundStyle(LM.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        // Collapsed: a fixed, compact card. Expanded (captured): fills the
        // content width like the Figma's wide guide card.
        .frame(minWidth: isExpanded ? 0 : 220,
               maxWidth: isExpanded ? .infinity : 220,
               alignment: .leading)
        .lmGlass(tint: LM.glassTintSoft)
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
            .buttonStyle(.plain)
            .tutorialAnchor(.capture)

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
    var language: AppLanguage = .english
    var expanded: Bool = false
    /// Called when the user taps the expand/full-screen affordance.
    var onFullscreen: () -> Void = {}

    @State private var image: UIImage? = nil

    private var hasPhoto: Bool { record.photoData != nil }
    private var height: CGFloat { expanded ? 320 : 120 }

    var body: some View {
        content
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.45), radius: 3, y: 1)
            .padding(LM.pad)
            // Fill the card; the snapshot sits behind via `.background` so the
            // greedy scaledToFill image doesn't dominate layout.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .frame(height: height)
            .background { backgroundLayer }
            .clipShape(RoundedRectangle(cornerRadius: LM.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: LM.cardRadius, style: .continuous)
                    .strokeBorder(LM.hairline, lineWidth: 1)
            }
            .overlay(alignment: .center) {
                if expanded && hasPhoto {
                    Button(action: onFullscreen) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(14)
                            .background(Circle().fill(.black.opacity(0.4)))
                            .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
            }
            .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
            .task(id: record.id) { loadImage() }
    }

    /// Snapshot (or placeholder) + a scrim so the white text reads over it.
    private var backgroundLayer: some View {
        ZStack {
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                LinearGradient(colors: [Color(hex: 0x6E6A66), Color(hex: 0x45423F)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "photo")
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(.white.opacity(0.3))
            }
            LinearGradient(colors: [.black.opacity(0.05), .black.opacity(0.2), .black.opacity(0.7)],
                           startPoint: .top, endPoint: .bottom)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text("#\(record.index)")
                    .font(LM.font(LM.FontSize.body, .bold))
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(record.dateLine).font(LM.font(LM.FontSize.caption, .semibold))
                    Text(record.timeLine).font(LM.font(LM.FontSize.micro)).opacity(0.85)
                }
            }
            Spacer(minLength: 0)
            HStack(spacing: 0) {
                metric(LocalizedStrings.translate(key: "tab_brightness", language: language), record.brightness)
                metric(LocalizedStrings.translate(key: "tab_temperature", language: language), record.temperature)
            }
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(LM.font(LM.FontSize.micro, .medium))
                .opacity(0.85)
            Text(value)
                .font(LM.font(LM.FontSize.h2, .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func loadImage() {
        guard image == nil, let data = record.photoData else { return }
        image = LMImage.downsample(data, maxPixel: 1100)
    }
}

/// An interactive record row: drag the card left to reveal a red-tinted trash
/// button, then tap it to delete. Matches the Figma "swiped" state.
private struct LMSwipeRow: View {
    let record: LMRecord
    var language: AppLanguage = .english
    let revealed: Bool
    let expanded: Bool
    var onRevealChange: (Bool) -> Void
    var onDelete: () -> Void
    var onTap: () -> Void
    var onFullscreen: () -> Void

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
            .padding(.trailing, 12)
            .opacity(offset < -8 ? 1 : 0)

            LMRecordCard(record: record, language: language, expanded: expanded, onFullscreen: onFullscreen)
                .offset(x: offset)
                .contentShape(Rectangle())
                .onTapGesture { onTap() }
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
        .animation(.snappy(duration: 0.3), value: expanded)
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
    @State private var expandedID: UUID? = nil
    @State private var fullscreen: LMRecord? = nil
    @State private var debugApplied = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: LM.gap + 4) {
                ForEach(records) { record in
                    LMSwipeRow(
                        record: record,
                        language: language,
                        revealed: revealedID == record.id,
                        expanded: expandedID == record.id,
                        onRevealChange: { open in
                            withAnimation(.snappy(duration: 0.25)) {
                                revealedID = open ? record.id : nil
                            }
                        },
                        onDelete: {
                            withAnimation(.snappy(duration: 0.25)) { revealedID = nil }
                            onDelete?(record)
                        },
                        onTap: {
                            // Only records with a snapshot expand.
                            guard record.photoData != nil else { return }
                            withAnimation(.snappy(duration: 0.3)) {
                                expandedID = (expandedID == record.id) ? nil : record.id
                            }
                        },
                        onFullscreen: { fullscreen = record }
                    )
                }
            }
            .padding(.horizontal, LM.pad)
            .padding(.top, LM.pad)
            .padding(.bottom, 120) // clear the floating tab bar
        }
        .fullScreenCover(item: $fullscreen) { record in
            LMSnapshotViewer(record: record, language: language)
        }
        .onAppear { applyDebugRecordsState() }
        .onChange(of: records.count) { _, _ in applyDebugRecordsState() }
    }

    /// DEBUG screenshot aids: pre-expand / pre-open the first photo record.
    private func applyDebugRecordsState() {
        #if DEBUG
        guard !debugApplied, !records.isEmpty else { return }
        let env = ProcessInfo.processInfo.environment
        let firstPhoto = records.first { $0.photoData != nil }
        if env["LM_EXPAND"] != nil { expandedID = firstPhoto?.id; debugApplied = true }
        if env["LM_FULLSCREEN"] != nil { fullscreen = firstPhoto; debugApplied = true }
        #endif
    }
}

// MARK: - Full-screen Snapshot Viewer

/// Shows a record's snapshot full-screen with its readout; tap anywhere or the
/// close button to dismiss.
struct LMSnapshotViewer: View {
    let record: LMRecord
    var language: AppLanguage = .english

    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image {
                Image(uiImage: image).resizable().scaledToFit().ignoresSafeArea()
            } else {
                ProgressView().tint(.white)
            }

            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Circle().fill(.black.opacity(0.5)))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                HStack(spacing: 28) {
                    caption(LocalizedStrings.translate(key: "tab_brightness", language: language), record.brightness)
                    caption(LocalizedStrings.translate(key: "tab_temperature", language: language), record.temperature)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 24)
                .background(Capsule().fill(.black.opacity(0.5)))
            }
            .padding(20)
        }
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
        .task(id: record.id) {
            if let data = record.photoData {
                image = LMImage.downsample(data, maxPixel: 2000)
            }
        }
    }

    private func caption(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(LM.font(LM.FontSize.micro, .medium))
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(LM.font(LM.FontSize.h2, .bold))
                .foregroundStyle(.white)
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
