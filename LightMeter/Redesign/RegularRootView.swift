//
//  RegularRootView.swift
//  LightMeter
//
//  The "Regular" (light-user) experience — the Figma redesign wired to the
//  live camera and the existing models. It reuses the same CameraViewModel /
//  Measurement / Records pipeline as the original app, presenting it with the
//  LM* frosted-glass components. Advanced mode (ContentView) is untouched.
//
//  Tabs:
//    • Brightness  — live lux/Kelvin glass card; capture freezes the frame,
//                    saves a record, and expands the card with the interpretation.
//    • Temperature — live Kelvin + tone.
//    • Check       — activity-suitability grid.
//    • Records     — saved measurements as glass cards.
//

import SwiftUI
import AudioToolbox

struct RegularRootView: View {
    @State private var cameraViewModel = CameraViewModel()
    @State private var selection: LMTab = .brightness
    @State private var previousTabIndex = 0
    @State private var isCaptured = false
    @State private var frozenFrame: UIImage? = nil
    @State private var showSettings = false

    private var language: AppLanguage { cameraViewModel.appLanguage }
    private var isCameraTab: Bool { selection != .records }
    private var canCapture: Bool {
        selection == .brightness && !isCaptured && cameraViewModel.permissionGranted
    }

    /// The 8 standard activities, in the Figma's reading order.
    private let activities: [ActivityChip] = [
        .readingAndStudy, .officeAndFocus, .tvAndMovies, .diningAndSocial,
        .sleepAndComfort, .babyAndParenting, .datingAndRomance, .coffeeAndTeaTime,
    ]

    var body: some View {
        ZStack(alignment: .top) {
            backgroundLayer
            contentLayer
            topBar
            bottomBar
        }
        .sheet(isPresented: $showSettings) {
            RegularSettingsSheet(language: language)
        }
        .onAppear { cameraViewModel.requestPermission() }
        .onChange(of: selection) { _, newTab in handleTabChange(to: newTab) }
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.willEnterForegroundNotification)) { _ in
            cameraViewModel.startSession()
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.didEnterBackgroundNotification)) { _ in
            cameraViewModel.stopSession()
        }
    }

    // MARK: - Background

    @ViewBuilder private var backgroundLayer: some View {
        if !cameraViewModel.permissionGranted {
            Color.black.ignoresSafeArea()
        } else if selection == .records {
            LM.recordsGradient.ignoresSafeArea()
        } else if isCaptured, let frame = frozenFrame {
            Image(uiImage: frame)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            LM.scrimGradient.opacity(0.25).ignoresSafeArea()
        } else {
            CameraPreviewView(session: cameraViewModel.session)
                .ignoresSafeArea()
            LM.scrimGradient.opacity(0.20).ignoresSafeArea()
        }
    }

    // MARK: - Content

    @ViewBuilder private var contentLayer: some View {
        if !cameraViewModel.permissionGranted {
            permissionDenied
        } else {
            switch selection {
            case .brightness:  brightnessContent
            case .temperature: temperatureContent
            case .check:       checkContent
            case .records:     recordsContent
            }
        }
    }

    private var brightnessContent: some View {
        let m = cameraViewModel.measurement
        let interp = isCaptured
            ? LuxInterpreter.interpret(lux: m.lux, language: language)
            : nil
        return HStack(alignment: .top) {
            LMGlassReadoutCard(
                lux: "\(Int(m.lux))",
                unit: "LUX",
                temperature: "\(formatNumber(m.colorTemperature))K",
                guideTitle: interp != nil
                    ? LocalizedStrings.translate(key: "ui_user_guide", language: language)
                    : nil,
                guideDescription: interp?.description,
                guideTip: interp?.tip
            )
            Spacer(minLength: 0)
        }
        .padding(.horizontal, LM.pad)
        .padding(.top, 64)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var temperatureContent: some View {
        let m = cameraViewModel.measurement
        let interp = KelvinInterpreter.interpret(kelvin: m.colorTemperature, language: language)
        return HStack(alignment: .top) {
            LMGlassReadoutCard(
                lux: formatNumber(m.colorTemperature),
                unit: "K",
                temperature: interp.description
            )
            Spacer(minLength: 0)
        }
        .padding(.horizontal, LM.pad)
        .padding(.top, 64)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var checkContent: some View {
        let labels = activities.map { $0.localizedName(language: language) }
        return ScrollView {
            LMActivityGrid(activities: labels)
                .padding(.top, 64)
                .padding(.bottom, 140)
        }
    }

    private var recordsContent: some View {
        Group {
            if mappedRecords.isEmpty {
                VStack(spacing: LM.gap) {
                    Image(systemName: "tray")
                        .font(.system(size: 34))
                        .foregroundStyle(LM.textSecondary)
                    Text(LocalizedStrings.translate(key: "ui_no_records", language: language))
                        .font(LM.font(LM.FontSize.h2, .semibold))
                        .foregroundStyle(LM.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LMRecordsList(records: mappedRecords, revealedIndex: nil)
                    .padding(.top, 56)
            }
        }
    }

    private var permissionDenied: some View {
        VStack {
            Spacer()
            Text("Camera access is required to measure light.\nPlease enable it in Settings.")
                .font(LM.font(LM.FontSize.body))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        }
    }

    // MARK: - Top bar (settings + back)

    private var topBar: some View {
        HStack(alignment: .top) {
            if isCaptured {
                Button {
                    withAnimation(.snappy(duration: 0.25)) {
                        isCaptured = false
                        frozenFrame = nil
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
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
                .accessibilityLabel("Back to live")
            }
            Spacer()
            if cameraViewModel.permissionGranted {
                LMSettingsButton { showSettings = true }
            }
        }
        .padding(.horizontal, LM.pad)
        .padding(.top, LM.pad)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Bottom bar (capture + tab bar)

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Spacer()
            if canCapture {
                LMCaptureControls(
                    onCapture: capture,
                    onFlip: { cameraViewModel.toggleCamera() }
                )
                .padding(.bottom, 24)
            }
            if cameraViewModel.permissionGranted {
                LMCapsuleTabBar(selection: $selection)
                    .padding(.horizontal, LM.pad)
                    .padding(.bottom, LM.gap)
            }
        }
    }

    // MARK: - Actions

    private func capture() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        AudioServicesPlaySystemSound(1108)

        let lux = cameraViewModel.measurement.lux
        let kelvin = cameraViewModel.measurement.colorTemperature
        Task {
            let frame = await cameraViewModel.captureFrameAsync()
            await MainActor.run {
                frozenFrame = frame
                cameraViewModel.recordsStore.saveRecord(lux: lux, kelvin: kelvin)
                withAnimation(.snappy(duration: 0.25)) { isCaptured = true }
            }
        }
    }

    private func handleTabChange(to newTab: LMTab) {
        isCaptured = false
        frozenFrame = nil
        let index = tabIndex(newTab)
        cameraViewModel.activeTab = index
        switch TabTransitionAction.resolve(from: previousTabIndex, to: index) {
        case .startSession: cameraViewModel.startSession()
        case .stopSession:  cameraViewModel.stopSession()
        case .none:         break
        }
        previousTabIndex = index
    }

    // MARK: - Helpers

    private func tabIndex(_ tab: LMTab) -> Int {
        switch tab {
        case .brightness:  return 0
        case .temperature: return 1
        case .check:       return 2
        case .records:     return 3
        }
    }

    private var mappedRecords: [LMRecord] {
        let records = cameraViewModel.recordsStore.records
        return records.enumerated().map { offset, record in
            LMRecord(
                index: records.count - offset,
                dateLine: Self.dateFormatter.string(from: record.timestamp),
                timeLine: Self.timeFormatter.string(from: record.timestamp),
                brightness: "\(Int(record.lux)) Lux",
                temperature: "\(formatNumber(record.kelvin))K"
            )
        }
    }

    private func formatNumber(_ value: Double) -> String {
        Self.decimalFormatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    private static let decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()
}

#Preview {
    RegularRootView()
}
