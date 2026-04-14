struct ComparisonGenerator {
    private static let ranges: [(upperBound: Double, label: String)] = [
        (10, "very dark outdoors"),
        (100, "hallways and movie theaters"),
        (200, "a living room"),
        (500, "an office"),
        (1000, "a study room"),
        (2000, "a bright window indoors"),
        (10000, "a cloudy day outdoors"),
        (.infinity, "direct sunlight")
    ]

    /// Returns a contextual comparison sentence for the given lux value.
    /// - Lowest range (0–10): "Darker than [upper adjacent environment]"
    /// - Highest range (10,001+): "Brighter than [lower adjacent environment]"
    /// - Middle ranges: "Brighter than [lower environment] but darker than [upper environment]"
    static func generate(lux: Double) -> String {
        let index = LuxRange.rangeIndex(for: lux)

        if index == 0 {
            return "Darker than \(ranges[1].label)"
        } else if index == 7 {
            return "Brighter than \(ranges[6].label)"
        } else {
            return "Brighter than \(ranges[index - 1].label) but darker than \(ranges[index + 1].label)"
        }
    }
}
