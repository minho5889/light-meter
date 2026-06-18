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
    @State private var showCoach = false
    @State private var coachIntent: CoachIntent = .room
    @State private var captureFlash = false
    @AppStorage("lm_tutorial_seen_v1") private var tutorialSeen = false
    @State private var showTutorial = false
    @State private var tutorialStartStep = 0

    private var language: AppLanguage { cameraViewModel.appLanguage }
    private var isCameraTab: Bool { selection != .records }
    private var canCapture: Bool {
        selection == .brightness && !isCaptured && cameraViewModel.permissionGranted
    }

    var body: some View {
        ZStack(alignment: .top) {
            backgroundLayer
            contentLayer
            topBar
            bottomBar
        }
        .overlay {
            // Quick camera "shutter" flash on capture.
            Color.white
                .opacity(captureFlash ? 0.85 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(false)
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
        .sheet(isPresented: $showCoach) {
            LMCoachSheet(image: frozenFrame, lux: capturedLux, kelvin: capturedKelvin,
                         language: language, service: LightingCoach.service(), initialIntent: coachIntent)
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
            case .ambience:    ambienceContent
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
            VStack(alignment: .leading, spacing: 12) {
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
                if isCaptured {
                    vibePill
                    coachButton
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, LM.pad)
        .padding(.top, 64)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    /// The captured reading's vibe, surfaced right in the capture moment (a
    /// frosted pill so it reads over the frozen frame) — ties the Gen-Z vibe
    /// into the core loop, matching the Records / Coach / Diary surfaces.
    private var vibePill: some View {
        let v = LightVibe.of(lux: capturedLux, kelvin: capturedKelvin)
        return HStack(spacing: 6) {
            Text(v.emoji).font(.system(size: 15))
            Text(v.name)
                .font(.custom("CaveatBrush-Regular", size: 22))
                .foregroundStyle(LM.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .lmGlass(cornerRadius: LM.pillRadius)
    }

    /// Opens the AI Lighting Coach for the just-captured snapshot + readings.
    private var coachButton: some View {
        let label: String
        switch language {
        case .korean:  label = "AI 조명 코치"
        case .french:  label = "Coach lumière IA"
        case .english: label = "AI Lighting Coach"
        }
        return Button { LMHaptics.soft(); showCoach = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text(label)
            }
            .font(LM.font(LM.FontSize.body, .semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Capsule().fill(LM.accent))
            .shadow(color: LM.accent.opacity(0.4), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
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

    private var ambienceContent: some View {
        let m = cameraViewModel.measurement
        var lux = m.lux
        var kelvin = m.colorTemperature
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        if let s = env["LM_LUX"], let v = Double(s) { lux = v }
        if let s = env["LM_KELVIN"], let v = Double(s) { kelvin = v }
        #endif
        return LMAmbienceView(lux: lux, kelvin: kelvin, language: language)
    }

    private var recordsContent: some View {
        Group {
            if mappedRecords.isEmpty {
                recordsEmptyState
            } else {
                LMRecordsList(records: mappedRecords, language: language, onDelete: deleteRecord)
                    .padding(.top, 56)
            }
        }
    }

    /// Friendly, on-brand empty state for the Records / Light Diary tab.
    private var recordsEmptyState: some View {
        let subtitle: String
        switch language {
        case .korean:  subtitle = "측정을 캡처하면 라이트 다이어리가 시작돼요 ✨"
        case .french:  subtitle = "Capture une mesure pour démarrer ton Light Diary ✨"
        case .english: subtitle = "Capture a reading to start your Light Diary ✨"
        }
        return VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 34))
                .foregroundStyle(LM.accent)
            Text(LocalizedStrings.translate(key: "ui_no_records", language: language))
                .font(LM.font(LM.FontSize.h2, .bold))
                .foregroundStyle(LM.textPrimary)
            Text(subtitle)
                .font(LM.font(LM.FontSize.caption, .medium))
                .foregroundStyle(LM.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var permissionDenied: some View {
        let message: String
        let buttonLabel: String
        switch language {
        case .korean:
            message = "빛을 측정하려면 카메라 접근 권한이 필요합니다.\n설정에서 권한을 허용해 주세요."
            buttonLabel = "설정 열기"
        case .french:
            message = "L'accès à la caméra est requis pour mesurer la lumière.\nActivez-le dans Réglages."
            buttonLabel = "Ouvrir Réglages"
        case .english:
            message = "Camera access is required to measure light.\nPlease enable it in Settings."
            buttonLabel = "Open Settings"
        }
        return VStack(spacing: 20) {
            Spacer()
            Image(systemName: "camera.fill")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(.white.opacity(0.8))
            Text(message)
                .font(LM.font(LM.FontSize.body))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text(buttonLabel)
                    .font(LM.font(LM.FontSize.body, .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(LM.accent))
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(LM.pad)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Top bar (settings + back)

    private var topBar: some View {
        HStack(alignment: .top) {
            Spacer()
            if cameraViewModel.permissionGranted {
                LMSettingsButton(language: language) { showSettings = true }
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
                    language: language,
                    onCapture: capture,
                    onFlip: { cameraViewModel.toggleCamera() }
                )
                .padding(.bottom, 24)
            } else if isCaptured {
                backControl
                    .padding(.bottom, 24)
            }
            if cameraViewModel.permissionGranted {
                LMCapsuleTabBar(selection: $selection, language: language)
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

        // Shutter flash: snap to white, then fade out.
        captureFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            withAnimation(.easeOut(duration: 0.35)) { captureFlash = false }
        }

        let lux = cameraViewModel.measurement.lux
        let kelvin = cameraViewModel.measurement.colorTemperature
        Task {
            let frame = await cameraViewModel.captureFrameAsync()
            await MainActor.run {
                frozenFrame = frame
                capturedLux = lux
                capturedKelvin = kelvin
                let photoData = frame.flatMap { LMImage.jpegData($0) }
                cameraViewModel.recordsStore.saveRecord(lux: lux, kelvin: kelvin, photoData: photoData)
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
                title: t("Read the room", "빛 읽기", "Capte la lumière"),
                body: t("Point anywhere — brightness and color temp, live.",
                        "어디든 비추면 밝기와 색온도가 실시간으로 나와요.",
                        "Pointe n'importe où — luminosité et température, en direct."),
                shape: .roundedRect, inset: 12),
            TutorialStep(
                target: .capture,
                title: t("Snap it", "찰칵, 고정", "Fige l'instant"),
                body: t("Tap to freeze the reading — a quick plain-English take, saved to Records.",
                        "탭하면 측정값이 고정되고, 쉬운 해설과 함께 기록에 저장돼요.",
                        "Touche pour figer la mesure — un résumé clair, gardé dans l'historique."),
                shape: .circle, inset: 10),
            TutorialStep(
                target: .tabs,
                title: t("Switch it up", "네 가지 화면", "Quatre vues"),
                body: t("Brightness, color temp, a quick light check, and your saved reads.",
                        "밝기, 색온도, 빛 진단, 그리고 저장한 기록까지.",
                        "Luminosité, température, un check lumière, et tes mesures."),
                shape: .roundedRect, inset: 8),
            TutorialStep(
                target: .settings,
                title: t("Want more?", "더 깊게?", "Envie de plus ?"),
                body: t("Tap the gear for Advanced — calibration, EV, f-stops, flicker.",
                        "톱니바퀴를 눌러 고급 모드로 — 보정, EV, 조리개, 플리커까지.",
                        "Touche l'engrenage pour le mode Avancé : calibration, EV, ouvertures, flicker."),
                shape: .circle, inset: 8),
        ]
    }

    // MARK: - Helpers

    private func tabIndex(_ tab: LMTab) -> Int {
        switch tab {
        case .brightness:  return 0
        case .temperature: return 1
        case .ambience:    return 2
        case .records:     return 3
        }
    }

    private var mappedRecords: [LMRecord] {
        let records = cameraViewModel.recordsStore.records
        return records.enumerated().map { offset, record in
            let v = LightVibe.of(lux: record.lux, kelvin: record.kelvin)
            return LMRecord(
                index: records.count - offset,
                dateLine: Self.dateFormatter.string(from: record.timestamp),
                timeLine: Self.timeFormatter.string(from: record.timestamp),
                brightness: "\(Int(record.lux)) Lux",
                temperature: "\(formatNumber(record.kelvin))K",
                recordID: record.id,
                photoData: record.photoData,
                vibe: v.name,
                emoji: v.emoji,
                luxValue: record.lux,
                kelvinValue: record.kelvin
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
            cameraViewModel.recordsStore.saveRecord(lux: 900, kelvin: 1200, photoData: sampleSnapshot(.systemOrange, .systemPink))
            cameraViewModel.recordsStore.saveRecord(lux: 600, kelvin: 5600, photoData: sampleSnapshot(.systemTeal, .systemBlue))
            cameraViewModel.recordsStore.saveRecord(lux: 120, kelvin: 3800, photoData: sampleSnapshot(.systemIndigo, .systemPurple))
            cameraViewModel.recordsStore.saveRecord(lux: 300, kelvin: 4500) // no photo → placeholder
        }
        switch env["LM_TAB"] {
        case "temperature": selection = .temperature
        case "ambience":    selection = .ambience
        case "records":     selection = .records
        default:            break
        }
        if env["LM_CAPTURED"] != nil {
            isCaptured = true
            capturedLux = Double(env["LM_LUX"] ?? "") ?? capturedLux
            capturedKelvin = Double(env["LM_KELVIN"] ?? "") ?? capturedKelvin
        }
        if env["LM_SETTINGS"] != nil { showSettings = true }
        if let s = env["LM_TUTSTEP"], let n = Int(s) {
            tutorialStartStep = n
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { showTutorial = true }
        }
        if let coach = env["LM_COACH"] {
            isCaptured = true
            capturedLux = Double(env["LM_LUX"] ?? "") ?? 80
            capturedKelvin = Double(env["LM_KELVIN"] ?? "") ?? 3000
            coachIntent = (coach == "selfie") ? .selfie : .room
            if let d = sampleSnapshot(.systemOrange, .systemPink), let img = UIImage(data: d) { frozenFrame = img }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { showCoach = true }
        }
        #endif
    }

    #if DEBUG
    /// A synthetic "snapshot" (gradient + soft highlights) so seeded Records show
    /// real photo cards on the simulator, which has no camera.
    private func sampleSnapshot(_ top: UIColor, _ bottom: UIColor) -> Data? {
        let size = CGSize(width: 900, height: 1200)
        let fmt = UIGraphicsImageRendererFormat.default()
        fmt.scale = 1; fmt.opaque = true
        let img = UIGraphicsImageRenderer(size: size, format: fmt).image { ctx in
            let cg = ctx.cgContext
            if let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: [top.cgColor, bottom.cgColor] as CFArray, locations: [0, 1]) {
                cg.drawLinearGradient(grad, start: .zero,
                                      end: CGPoint(x: size.width, y: size.height), options: [])
            }
            cg.setFillColor(UIColor.white.withAlphaComponent(0.16).cgColor)
            cg.fillEllipse(in: CGRect(x: size.width * 0.45, y: size.height * 0.12, width: 380, height: 380))
            cg.fillEllipse(in: CGRect(x: size.width * 0.02, y: size.height * 0.62, width: 240, height: 240))
        }
        return LMImage.jpegData(img, maxDimension: 1100, quality: 0.7)
    }
    #endif
}

#Preview {
    RegularRootView()
}
