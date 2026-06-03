import SwiftUI

struct RecordsView: View {
    @ObservedObject var cameraViewModel: CameraViewModel

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    /// Formats a Double as a locale-aware integer string with thousands separators.
    private static func formatValue(_ value: Double) -> String {
        return numberFormatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    var body: some View {
        ZStack {
            // Dark elegant background theme for records history
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header Title Section
                HStack {
                    Text(LocalizedStrings.translate(key: "tab_records", language: cameraViewModel.appLanguage).uppercased())
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1.5)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                if cameraViewModel.records.isEmpty {
                    emptyStateView
                } else {
                    recordsListView
                }
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "list.clipboard")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.2))
            
            Text(LocalizedStrings.translate(key: "ui_no_records", language: cameraViewModel.appLanguage))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
            
            Text(LocalizedStrings.translate(key: "ui_records_empty_desc", language: cameraViewModel.appLanguage))
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
    }

    private var recordsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(cameraViewModel.records.enumerated()), id: \.element.id) { index, record in
                    let reverseIndex = cameraViewModel.records.count - index
                    
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 12) {
                            // Header Row: #Index + Localized Timestamp
                            HStack {
                                Text("#\(reverseIndex)")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.5))
                                
                                Spacer()
                                
                                Text("\(Self.dateFormatter.string(from: record.timestamp))  \(Self.timeFormatter.string(from: record.timestamp))")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            
                            // Lux & Kelvin Values Row
                            HStack(alignment: .firstTextBaseline, spacing: 16) {
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(Self.formatValue(record.lux))
                                        .font(.system(size: 26, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("LUX")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                
                                Text("\(Self.formatValue(record.kelvin))K")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            // Horizontal tags of active activities
                            if !record.activeChips.isEmpty {
                                HStack(spacing: 8) {
                                    ForEach(record.activeChips, id: \.self) { chip in
                                        Text(chip.localizedName(language: cameraViewModel.appLanguage))
                                            .font(.system(size: 10, weight: .bold, design: .rounded))
                                            .foregroundColor(.white.opacity(0.7))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding(18)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        
                        // Swipe-to-delete helper or explicit trash button
                        Button(action: {
                            withAnimation(.easeInOut) {
                                cameraViewModel.deleteRecord(id: record.id)
                            }
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.red.opacity(0.8))
                                .frame(width: 50, height: 80)
                                .padding(.leading, 12)
                        }
                        .accessibilityLabel("Delete record")
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 120) // Bottom padding to clear custom floating tab bar
        }
    }
}
