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
    @State private var capturedLux: Double = 0
    @State private var capturedKelvin: Double = 0
    @State private var showSettings = false
    @AppStorage("lm_tutorial_seen_v1") private var tutorialSeen = false
    @State private var showTutorial = false
    @State private var tutorialStartStep = 0

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
        .overlayPreferenceValue(TutorialAnchorKey.self) { prefs in
            GeometryReader { geo in
                if showTutorial {
                    TutorialOverlay(
                        steps: tutorialSteps,
                        anchors: prefs.mapValues { geo[$0] },
                        isActive: $showTutorial,
                        startIndex: tutorialStartStep
                    )
                }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showSettings) {
            RegularSettingsSheet(language: language, onReplayTutorial: {
                showSettings = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    isCaptured = false
                    selection = .brightness
                    showTutorial = true
                }
            })
        }
        .onAppear {
            cameraViewModel.requestPermission()
            applyDebugLaunchOptions()
            maybeStartTutorial()
        }
        .onChange(of: cameraViewModel.permissionGranted) { _, _ in maybeStartTutorial() }
        .onChange(of: showTutorial) { wasShowing, showing in
            if wasShowing && !showing { tutorialSeen = true }
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
        // Captured state freezes the readout at the snapshot values; live
        // state tracks the camera.
        let luxValue = isCaptured ? capturedLux : m.lux
        let kelvinValue = isCaptured ? capturedKelvin : m.colorTemperature
        let interp = isCaptured
            ? LuxInterpreter.interpret(lux: luxValue, language: language)
            : nil
        return HStack(alignment: .top) {
            LMGlassReadoutCard(
                lux: "\(Int(luxValue))",
                unit: "LUX",
                temperature: "\(formatNumber(kelvinValue))K",
                guideTitle: interp != nil
                    ? LocalizedStrings.translate(key: "ui_user_guide", language: language)
                    : nil,
                guideDescription: interp?.description,
                guideTip: interp?.tip
            )
            .tutorialAnchor(.readout)
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
                LMRecordsList(records: mappedRecords, language: language, onDelete: deleteRecord)
                    .padding(.top, 56)
            }
        }
    }

    private var permissionDenied: some View {
        let message: String
        switch language {
        case .korean: message = "빛을 측정하려면 카메라 접근 권한이 필요합니다.\n설정에서 권한을 허용해 주세요."
        case .french: message = "L'accès à la caméra est requis pour mesurer la lumière.\nActivez-le dans Réglages."
        case .english: message = "Camera access is required to measure light.\nPlease enable it in Settings."
        }
        return VStack {
            Spacer()
            Text(message)
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
                    .tutorialAnchor(.settings)
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
            } else if isCaptured {
                backControl
                    .padding(.bottom, 24)
            }
            if cameraViewModel.permissionGranted {
                LMCapsuleTabBar(selection: $selection)
                    .tutorialAnchor(.tabs)
                    .padding(.horizontal, LM.pad)
                    .padding(.bottom, LM.gap)
            }
        }
    }

    /// Bottom-center "Back" control shown in the captured state — a white circle
    /// + label where the shutter button sits, matching the Figma.
    private var backControl: some View {
        Button {
            withAnimation(.snappy(duration: 0.25)) {
                isCaptured = false
                frozenFrame = nil
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(LM.textPrimary)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(.white))
                    .overlay(Circle().strokeBorder(LM.hairline, lineWidth: 1))
                    .shadow(color: .black.opacity(0.18), radius: 8, y: 2)
                Text(LocalizedStrings.translate(key: "ui_back", language: language))
                    .font(LM.font(LM.FontSize.micro, .medium))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 3)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(LocalizedStrings.translate(key: "ui_back", language: language))
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
        let index = tabIndex(newTab)
        cameraViewModel.activeTab = index
        switch TabTransitionAction.resolve(from: previousTabIndex, to: index) {
        case .startSession: cameraViewModel.startSession()
        case .stopSession:  cameraViewModel.stopSession()
        case .none:         break
        }
        previousTabIndex = index
    }

    // MARK: - Tutorial

    private func maybeStartTutorial() {
        guard !tutorialSeen, !showTutorial, cameraViewModel.permissionGranted else { return }
        selection = .brightness
        isCaptured = false
        // Let the layout settle so the spotlight anchors resolve.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if !tutorialSeen, !showTutorial, cameraViewModel.permissionGranted {
                showTutorial = true
            }
        }
    }

    private var tutorialSteps: [TutorialStep] {
        func t(_ en: String, _ ko: String, _ fr: String) -> String {
            switch language { case .korean: return ko; case .french: return fr; case .english: return en }
        }
        return [
            TutorialStep(
                target: .readout,
                title: t("Live reading", "실시간 측정", "Mesure en direct"),
                body: t("Point at any scene — this shows the brightness in lux and the color temperature, updating live.",
                        "어디든 비춰 보세요. 밝기(럭스)와 색온도가 실시간으로 표시됩니다.",
                        "Visez une scène — la luminosité (lux) et la température de couleur s'affichent en direct."),
                shape: .roundedRect, inset: 12),
            TutorialStep(
                target: .capture,
                title: t("Capture it", "캡처하기", "Capturer"),
                body: t("Tap to freeze the reading. You'll get a plain-language guide, and it's saved to Records.",
                        "탭하면 측정값이 고정됩니다. 쉬운 설명을 보여주고 기록에도 저장돼요.",
                        "Touchez pour figer la mesure. Vous obtenez un guide simple, enregistré dans l'historique."),
                shape: .circle, inset: 10),
            TutorialStep(
                target: .tabs,
                title: t("Four views", "네 가지 화면", "Quatre vues"),
                body: t("Switch between Brightness, color Temperature, a light Check, and your saved Records.",
                        "밝기, 색온도, 빛 진단(Check), 저장된 기록(Records)을 전환할 수 있어요.",
                        "Basculez entre Luminosité, Température, Check de la lumière et Historique."),
                shape: .roundedRect, inset: 8),
            TutorialStep(
                target: .settings,
                title: t("Want more?", "더 필요하세요?", "Besoin de plus ?"),
                body: t("Tap the gear and switch to Advanced mode for calibration, EV, f-stops and flicker analysis.",
                        "톱니바퀴를 눌러 고급 모드로 전환하면 보정, EV, 조리개, 플리커 분석을 쓸 수 있어요.",
                        "Touchez l'engrenage et passez en mode Avancé : calibration, EV, ouvertures et flicker."),
                shape: .circle, inset: 8),
        ]
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
        if env["LM_CAPTURED"] != nil { isCaptured = true }
        if env["LM_SETTINGS"] != nil { showSettings = true }
        if let s = env["LM_TUTSTEP"], let n = Int(s) {
            tutorialStartStep = n
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { showTutorial = true }
        }
        #endif
    }
}

#Preview {
    RegularRootView()
}
