import SwiftUI

struct CalibrationView: View {
    @ObservedObject var viewModel: CameraViewModel
    @Environment(\.dismiss) var dismiss
    @State private var targetLuxString: String = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Current reading card
                    VStack(spacing: 12) {
                        Text(LocalizedStrings.translate(key: "ui_calibrate_current", language: viewModel.appLanguage))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .tracking(1.0)
                        
                        Text("\(Int(viewModel.lux)) LUX")
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    
                    // Input Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStrings.translate(key: "ui_calibrate_enter_known", language: viewModel.appLanguage))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack {
                            TextField(LocalizedStrings.translate(key: "ui_calibrate_known_placeholder", language: viewModel.appLanguage), text: $targetLuxString)
                                .keyboardType(.numberPad)
                                .focused($isInputFocused)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(isInputFocused ? Color.green.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1.5)
                                )
                            
                            Text("LUX")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.trailing)
                        }
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(24)
                    
                    // Live multiplier preview
                    if let targetLux = Double(targetLuxString), targetLux > 0 {
                        let computed = CalibrationStore.calculateMultiplier(measuredLux: viewModel.lux, targetLux: targetLux)
                        VStack(spacing: 8) {
                            Text(LocalizedStrings.translate(key: "ui_calibrate_new_factor", language: viewModel.appLanguage))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text(String(format: LocalizedStrings.translate(key: "ui_calibrate_multiplier_fmt", language: viewModel.appLanguage), computed))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.green.opacity(0.25), lineWidth: 1)
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    Spacer()
                    
                    // Actions Area
                    VStack(spacing: 12) {
                        Button(action: {
                            if let targetLux = Double(targetLuxString), targetLux > 0 {
                                viewModel.calibrate(to: targetLux)
                                dismiss()
                            }
                        }) {
                            Text(LocalizedStrings.translate(key: "ui_calibrate_apply", language: viewModel.appLanguage))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Double(targetLuxString) == nil || Double(targetLuxString)! <= 0 ? Color.white.opacity(0.3) : Color.white)
                                .cornerRadius(16)
                        }
                        .disabled(Double(targetLuxString) == nil || Double(targetLuxString)! <= 0)
                        
                        Button(action: {
                            viewModel.resetCalibration()
                            dismiss()
                        }) {
                            Text(LocalizedStrings.translate(key: "ui_calibrate_reset", language: viewModel.appLanguage))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.red.opacity(0.9))
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.bottom, 16)
                }
                .padding(20)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: targetLuxString)
            }
            .navigationTitle(LocalizedStrings.translate(key: "ui_calibrate_title", language: viewModel.appLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStrings.translate(key: "ui_calibrate_cancel", language: viewModel.appLanguage)) {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                isInputFocused = true
            }
        }
    }
}
