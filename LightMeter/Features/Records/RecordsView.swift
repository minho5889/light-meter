import SwiftUI

struct RecordsView: View {
    var cameraViewModel: CameraViewModel

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

    private var safeAreaTop: CGFloat {
        let keyWindow = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .filter { $0.isKeyWindow }
            .first
        return keyWindow?.safeAreaInsets.top ?? 47
    }

    var body: some View {
        ZStack {
            // Dark elegant background theme for records history
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header Title Section
                HStack {
                    Text(LocalizedStrings.translate(key: "tab_records", language: cameraViewModel.appLanguage).uppercased())
                        .font(DesignConstants.fontTitle)
                        .foregroundColor(.white)
                        .tracking(1.5)
                    
                    Spacer()
                    
                    if let exportURL = cameraViewModel.recordsStore.exportURL {
                        ShareLink(item: exportURL) {
                            Image(systemName: "square.and.arrow.up")
                                .font(DesignConstants.fontSM.weight(.bold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.white.opacity(0.12))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Export CSV")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, max(16, safeAreaTop + 12))
                .padding(.bottom, 12)

                if cameraViewModel.recordsStore.records.isEmpty {
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
                .font(DesignConstants.fontMD.weight(.bold))
                .foregroundColor(.white.opacity(0.6))
            
            Text(LocalizedStrings.translate(key: "ui_records_empty_desc", language: cameraViewModel.appLanguage))
                .font(DesignConstants.fontXXS)
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
    }

    private var recordsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(cameraViewModel.recordsStore.records.enumerated()), id: \.element.id) { index, record in
                    RecordRowView(
                        record: record,
                        reverseIndex: cameraViewModel.recordsStore.records.count - index,
                        appLanguage: cameraViewModel.appLanguage,
                        onDelete: {
                            withAnimation(.easeInOut) {
                                _ = cameraViewModel.recordsStore.deleteRecord(id: record.id)
                            }
                        }
                    )
                    .padding(.horizontal)
                }
                
                if cameraViewModel.recordsStore.hasMorePages {
                    ProgressView()
                        .tint(.white)
                        .padding(.vertical, 16)
                        .onAppear {
                            cameraViewModel.recordsStore.loadNextPage()
                        }
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 120) // Bottom padding to clear custom floating tab bar
        }
    }
}

// MARK: - Helper Subviews

struct RecordRowView: View {
    let record: LightRecord
    let reverseIndex: Int
    let appLanguage: AppLanguage
    let onDelete: () -> Void

    @ScaledMetric(relativeTo: .title3) private var valueSize: CGFloat = 26

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

    private static func formatValue(_ value: Double) -> String {
        return numberFormatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    private var accessibilityLabelText: String {
        let dateStr = Self.dateFormatter.string(from: record.timestamp)
        let timeStr = Self.timeFormatter.string(from: record.timestamp)
        
        let recordLabel: String
        let luxLabel: String
        let kelvinLabel: String
        
        switch appLanguage {
        case .korean:
            recordLabel = "기록 \(reverseIndex)번"
            luxLabel = "\(Self.formatValue(record.lux)) 룩스"
            kelvinLabel = "\(Self.formatValue(record.kelvin)) 켈빈"
        case .french:
            recordLabel = "Enregistrement \(reverseIndex)"
            luxLabel = "\(Self.formatValue(record.lux)) lux"
            kelvinLabel = "\(Self.formatValue(record.kelvin)) Kelvin"
        case .english:
            recordLabel = "Record \(reverseIndex)"
            luxLabel = "\(Self.formatValue(record.lux)) lux"
            kelvinLabel = "\(Self.formatValue(record.kelvin)) Kelvin"
        }
        
        var parts = [
            recordLabel,
            "\(dateStr) \(timeStr)",
            luxLabel,
            kelvinLabel
        ]
        
        if !record.activeChips.isEmpty {
            let chipsNames = record.activeChips.map { $0.localizedName(language: appLanguage) }.joined(separator: ", ")
            let recommendedFor = appLanguage == .korean ? "권장 활동: \(chipsNames)" : (appLanguage == .french ? "Recommandé pour : \(chipsNames)" : "Recommended for: \(chipsNames)")
            parts.append(recommendedFor)
        }
        
        return parts.joined(separator: ", ")
    }

    private var shareText: String {
        let dateStr = Self.dateFormatter.string(from: record.timestamp)
        let timeStr = Self.timeFormatter.string(from: record.timestamp)
        
        let luxVal = Self.formatValue(record.lux)
        let kelvinVal = Self.formatValue(record.kelvin)
        
        var text = ""
        switch appLanguage {
        case .korean:
            text = "LightMeter 측정 기록\n일시: \(dateStr) \(timeStr)\n밝기: \(luxVal) LUX\n색온도: \(kelvinVal)K"
        case .french:
            text = "Enregistrement LightMeter\nDate: \(dateStr) \(timeStr)\nLuminosité: \(luxVal) LUX\nTempérature: \(kelvinVal)K"
        case .english:
            text = "LightMeter Reading\nDate: \(dateStr) \(timeStr)\nLuminance: \(luxVal) LUX\nColor Temp: \(kelvinVal)K"
        }
        
        if !record.activeChips.isEmpty {
            let chipsNames = record.activeChips.map { $0.localizedName(language: appLanguage) }.joined(separator: ", ")
            let recom = appLanguage == .korean ? "권장 활동" : (appLanguage == .french ? "Activités recommandées" : "Recommended Activities")
            text += "\n\(recom): \(chipsNames)"
        }
        
        return text
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                // Header Row: #Index + Localized Timestamp
                HStack {
                    Text("#\(reverseIndex)")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Spacer()
                    
                    Text("\(Self.dateFormatter.string(from: record.timestamp))  \(Self.timeFormatter.string(from: record.timestamp))")
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                
                // Lux & Kelvin Values Row
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(Self.formatValue(record.lux))
                            .font(.system(size: valueSize, weight: .bold, design: .rounded))
                        Text("LUX")
                            .font(.system(.caption2, design: .rounded).weight(.bold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Text("\(Self.formatValue(record.kelvin))K")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Horizontal tags of active activities
                if !record.activeChips.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(record.activeChips, id: \.self) { chip in
                            Text(chip.localizedName(language: appLanguage))
                                .font(.system(.caption2, design: .rounded).weight(.bold))
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
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabelText)
            
            // Share record button
            ShareLink(item: shareText) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(.body).weight(.semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 50, height: 80)
            }
            .accessibilityLabel(String(format: LocalizedStrings.translate(key: "accessibility_share_record", language: appLanguage), reverseIndex))

            // Swipe-to-delete helper or explicit trash button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(.body).weight(.semibold))
                    .foregroundColor(.red.opacity(0.8))
                    .frame(width: 50, height: 80)
                    .padding(.leading, 12)
            }
            .accessibilityLabel(String(format: LocalizedStrings.translate(key: "accessibility_delete_record", language: appLanguage), reverseIndex))
        }
    }
}
