import SwiftUI

struct FlickerCheckView: View {
    var viewModel: CameraViewModel

    var body: some View {
        ZStack {
            // Transparent background to let the shared camera preview show through
            Color.clear
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // Glassmorphic main control panel
                VStack(spacing: 24) {
                    headerView
                    gaugeAndWaveArea
                    safetyDescriptionCard
                    controlTriggerButton
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .cornerRadius(32)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 96) // Clear custom bottom tab bar capsule
            }
        }
        .onDisappear {
            // Auto-safety reset on tab switch
            if viewModel.flicker.isCheckingFlicker {
                viewModel.stopFlickerCheck()
            }
        }
    }

    // MARK: - Helper Subviews

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStrings.translate(key: "ui_light_check", language: viewModel.appLanguage))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(2.0)
                
                Text(LocalizedStrings.translate(key: "tab_check", language: viewModel.appLanguage))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            Spacer()
            
            // Active check pulsing dot
            if viewModel.flicker.isCheckingFlicker {
                HStack(spacing: 6) {
                    Circle()
                        .fill(safetyColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(viewModel.flicker.isCheckingFlicker ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel.flicker.isCheckingFlicker)
                    
                    Text(LocalizedStrings.translate(key: "ui_analyzing", language: viewModel.appLanguage))
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(safetyColor)
                        .tracking(1.0)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(safetyColor.opacity(0.15))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 4)
    }

    private var gaugeAndWaveArea: some View {
        HStack(spacing: 24) {
            // Circular Safety Gauge
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 10)
                    .frame(width: 130, height: 130)

                Circle()
                    .trim(from: 0.0, to: viewModel.flicker.isCheckingFlicker ? CGFloat(min(1.0, viewModel.flicker.flickerPercentage / 100.0)) : 0.0)
                    .stroke(
                        AngularGradient(
                            colors: [safetyColor.opacity(0.5), safetyColor],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.5), value: viewModel.flicker.flickerPercentage)
 
                VStack(spacing: 2) {
                    Text(viewModel.flicker.isCheckingFlicker ? String(format: "%.1f%%", viewModel.flicker.flickerPercentage) : "0.0%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(viewModel.flicker.isCheckingFlicker && viewModel.flicker.flickerFrequency > 5 ? String(format: "%.0f Hz", viewModel.flicker.flickerFrequency) : "-- Hz")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(width: 130, height: 130)

            // Real-Time Oscilloscope Wave Scope
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStrings.translate(key: "ui_wave_scope", language: viewModel.appLanguage))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.0)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                        .frame(height: 100)
                    
                    // Wave drawing
                    WaveScopePath(waveData: viewModel.flicker.waveData)
                        .stroke(
                            LinearGradient(
                                colors: [safetyColor, safetyColor.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                        )
                        .frame(height: 100)
                        .padding(.vertical, 8)
                        .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.8), value: viewModel.flicker.waveData)
                }
            }
        }
    }

    private var safetyDescriptionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.flicker.isCheckingFlicker ? FlickerInterpreter.safetyLevelTitle(level: viewModel.flicker.flickerSafetyLevel, language: viewModel.appLanguage).uppercased() : "READY")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(viewModel.flicker.isCheckingFlicker ? safetyColor : .white.opacity(0.6))
                
            Text(viewModel.flicker.isCheckingFlicker ? viewModel.flicker.flickerDescription : LocalizedStrings.translate(key: "ui_flicker_ready_desc", language: viewModel.appLanguage))
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var controlTriggerButton: some View {
        Button(action: {
            if viewModel.flicker.isCheckingFlicker {
                viewModel.stopFlickerCheck()
            } else {
                viewModel.startFlickerCheck()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: viewModel.flicker.isCheckingFlicker ? "stop.fill" : "bolt.shield.fill")
                    .font(.system(size: 16, weight: .semibold))
                
                Text(viewModel.flicker.isCheckingFlicker ? LocalizedStrings.translate(key: "ui_stop_check", language: viewModel.appLanguage) : LocalizedStrings.translate(key: "ui_start_check", language: viewModel.appLanguage))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundColor(viewModel.flicker.isCheckingFlicker ? .white : .black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(viewModel.flicker.isCheckingFlicker ? Color.red.opacity(0.8) : Color.white)
            .cornerRadius(16)
            .shadow(color: (viewModel.flicker.isCheckingFlicker ? Color.red : Color.white).opacity(0.2), radius: 10, x: 0, y: 5)
        }
    }

    // MARK: - Helper UI Properties

    private var safetyColor: Color {
        guard viewModel.flicker.isCheckingFlicker else { return .green }
        switch viewModel.flicker.flickerSafetyLevel {
        case "Very Safe", "Safe":
            return .green
        case "Caution":
            return .orange
        case "Dangerous", "Very Dangerous":
            return .red
        default:
            return .green
        }
    }
}

/// Custom Shape to draw the raw oscilloscope waveform path based on standard normalized values.
struct WaveScopePath: Shape {
    let waveData: [Float]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard !waveData.isEmpty else {
            // Draw flat line if no wave data is available
            path.move(to: CGPoint(x: 0, y: rect.height / 2))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height / 2))
            return path
        }

        let stepX = rect.width / CGFloat(waveData.count - 1)
        
        for i in 0..<waveData.count {
            let x = CGFloat(i) * stepX
            
            // Map standardized brightness [0.0, 1.0] to visual height of the scope [height, 0]
            // We invert it so higher brightness represents a wave peak (near y = 0).
            let sampleValue = CGFloat(waveData[i])
            let y = rect.height - (sampleValue * rect.height)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return path
    }
}
