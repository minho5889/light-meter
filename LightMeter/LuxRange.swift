enum LuxRange {
    /// Canonical lux thresholds shared across all consumers.
    static let thresholds: [Double] = [10, 100, 200, 500, 1000, 2000, 10000]

    /// Maps a lux value to a zero-based range index (0–7).
    /// Index 0 = darkest (≤10 lux), index 7 = brightest (>10000 lux).
    static func rangeIndex(for lux: Double) -> Int {
        if lux > 10000 { return 7 }
        if lux > 2000 { return 6 }
        if lux > 1000 { return 5 }
        if lux > 500 { return 4 }
        if lux > 200 { return 3 }
        if lux > 100 { return 2 }
        if lux > 10 { return 1 }
        return 0
    }
}
