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
    // Readout values frozen at capture time. The live `cameraViewModel.measurement`
    // keeps updating ~10x/sec after a capture, so the captured card MUST read these
    // snapshots (not the live measurement) to hold steady. See `capture()`.
    @State private var capturedLux: Double? = nil
    @State private var capturedKelvin: Double? = nil
    /// Activity whose suitability verdict is showing on the Analysis tab
    /// (nil = the pill grid), per the Figma 04_Check_2 tap-through.
    @State private var analysisActivity: ActivityChip? = nil
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
        .onAppear {
            cameraViewModel.requestPermission()
            applyDebugLaunchOptions()
        }
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
        // When captured, hold the frozen snapshot; otherwise track live.
        let lux = isCaptured ? (capturedLux ?? m.lux) : m.lux
        let kelvin = isCaptured ? (capturedKelvin ?? m.colorTemperature) : m.colorTemperature
        let interp = isCaptured
            ? LuxInterpreter.interpret(lux: lux, language: language)
            : nil
        return LMGlassReadoutCard(
            lux: luxDisplay(lux),
            unit: "LUX",
            temperature: "\(formatNumber(kelvin))K",
            guideTitle: interp != nil
                ? LocalizedStrings.translate(key: "ui_actionable_tip", language: language)
                : nil,
            guideDescription: interp?.description,
            guideTip: interp?.tip
        )
        .padding(.horizontal, LM.readoutMargin)
        .padding(.top, 64)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var temperatureContent: some View {
        let m = cameraViewModel.measurement
        let interp = KelvinInterpreter.interpret(kelvin: m.colorTemperature, language: language)
        return LMGlassReadoutCard(
            lux: formatNumber(m.colorTemperature),
            unit: "K",
            temperature: "\(luxDisplay(m.lux)) LUX",
            infoRows: [
                LMInfoRow(
                    label: LocalizedStrings.translate(key: "ui_color_tone", language: language),
                    value: interp.description),
                LMInfoRow(
                    label: LocalizedStrings.translate(key: "ui_recommended_activities", language: language),
                    value: interp.tip),
            ]
        )
        .padding(.horizontal, LM.readoutMargin)
        .padding(.top, 64)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder private var checkContent: some View {
        let labels = activities.map { $0.localizedName(language: language) }
        if let chip = analysisActivity {
            // Tap-through verdict for the selected activity (04_Check_2).
            let m = cameraViewModel.measurement
            LMActivityVerdictView(chip: chip, lux: m.lux,
                                  kelvin: m.colorTemperature, language: language)
                .padding(.horizontal, LM.readoutMargin)
                .padding(.top, 64)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else {
            ScrollView {
                LMActivityGrid(activities: labels) { label in
                    if let index = labels.firstIndex(of: label) {
                        withAnimation(.snappy(duration: 0.25)) {
                            analysisActivity = activities[index]
                        }
                    }
                }
                .padding(.top, 64)
                .padding(.bottom, 140)
            }
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
                LMRecordsList(records: mappedRecords, language: language, onDelete: deleteRecord)
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
            Spacer()
            if cameraViewModel.permissionGranted {
                LMSettingsButton { showSettings = true }
            }
        }
        .padding(.horizontal, LM.pad)
        .padding(.top, LM.pad)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    /// Bottom-center "Back" circle (the btn_back Figma component), reused by
    /// the captured Brightness state and the Analysis verdict state.
    private func backButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .semibold))
                Text(LocalizedStrings.translate(key: "ui_back", language: language))
                    .font(LM.font(LM.FontSize.caption, .medium))
            }
        }
        .buttonStyle(LMBackButtonStyle())
        .accessibilityLabel(LocalizedStrings.translate(key: "ui_back", language: language))
    }

    /// Back over a captured frame (replaces the shutter), per the Figma
    /// Brightness-detail screen.
    private var backControl: some View {
        backButton {
            withAnimation(.snappy(duration: 0.25)) {
                isCaptured = false
                frozenFrame = nil
                capturedLux = nil
                capturedKelvin = nil
            }
        }
    }

    /// Captured-state bottom controls: Back (centered, replaces the shutter)
    /// paired with the camera-flip button in the same trailing position it
    /// holds live — per the Figma Brightness-detail screens, both stay
    /// available once captured rather than the flip button disappearing.
    private var capturedControls: some View {
        ZStack {
            backControl
            HStack {
                Spacer()
                Button {
                    cameraViewModel.toggleCamera()
                } label: {
                    Image(systemName: "camera.rotate")
                        .font(.system(size: 18, weight: .regular))
                }
                .buttonStyle(LMGlassCircleButtonStyle(diameter: 46))
                .accessibilityLabel(LocalizedStrings.translate(key: "accessibility_switch_camera", language: language))
            }
            .padding(.trailing, 46)
        }
        .frame(maxWidth: .infinity)
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
            } else if isCaptured && selection == .brightness {
                capturedControls
                    .padding(.bottom, 24)
            } else if selection == .check && analysisActivity != nil {
                // Back from the activity verdict to the pill grid.
                backButton {
                    withAnimation(.snappy(duration: 0.25)) { analysisActivity = nil }
                }
                .padding(.bottom, 24)
            }
            if cameraViewModel.permissionGranted {
                LMCapsuleTabBar(selection: $selection, language: language)
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
                capturedLux = lux
                capturedKelvin = kelvin
                cameraViewModel.recordsStore.saveRecord(lux: lux, kelvin: kelvin)
                withAnimation(.snappy(duration: 0.25)) { isCaptured = true }
            }
        }
    }

    private func handleTabChange(to newTab: LMTab) {
        isCaptured = false
        frozenFrame = nil
        capturedLux = nil
        capturedKelvin = nil
        analysisActivity = nil
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
                brightness: "\(luxDisplay(record.lux)) Lux",
                temperature: "\(formatNumber(record.kelvin))K",
                recordID: record.id
            )
        }
    }

    private func deleteRecord(_ record: LMRecord) {
        guard let id = record.recordID else { return }
        cameraViewModel.recordsStore.deleteRecord(id: id)
    }

    private func formatNumber(_ value: Double) -> String {
        Self.decimalFormatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    /// Lux readout string per the Figma: thousands separators, capped at
    /// "100,000+" for extreme values (e.g. direct sunlight).
    private func luxDisplay(_ lux: Double) -> String {
        lux >= 100_000 ? "100,000+" : formatNumber(lux)
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

    // MARK: - Debug launch hooks (screenshot / UI review aid; stripped in Release)

    private func applyDebugLaunchOptions() {
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        if env["LM_SEED"] != nil {
            cameraViewModel.recordsStore.saveRecord(lux: 900, kelvin: 1200)
            cameraViewModel.recordsStore.saveRecord(lux: 600, kelvin: 5600)
            cameraViewModel.recordsStore.saveRecord(lux: 120, kelvin: 3800)
        }
        switch env["LM_TAB"] {
        case "temperature": selection = .temperature
        case "check":       selection = .check
        case "records":     selection = .records
        default:            break
        }
        if env["LM_CAPTURED"] != nil {
            // Seed frozen readout values so the captured card is verifiable in the
            // simulator (where the live camera always reads 0).
            capturedLux = Double(env["LM_LUX"] ?? "") ?? 12345
            capturedKelvin = Double(env["LM_KELVIN"] ?? "") ?? 3800
            isCaptured = true
        }
        if env["LM_SETTINGS"] != nil { showSettings = true }
        #endif
    }
}

#Preview {
    RegularRootView()
}
