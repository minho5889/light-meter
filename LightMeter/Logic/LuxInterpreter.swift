struct LuxInterpreter {
    private static let results: [InterpretationResult] = [
        // index 0: ≤10 lux
        InterpretationResult(
            description: "Very dark outdoors, full moon night",
            tip: "Pre-sleep conditions. Be careful when moving around."
        ),
        // index 1: >10 lux
        InterpretationResult(
            description: "Hallways, bathrooms, storage rooms, movie theaters",
            tip: "Suitable for passing through. Not appropriate for extended work."
        ),
        // index 2: >100 lux
        InterpretationResult(
            description: "Living room relaxation, dining, hotel rooms",
            tip: "Optimal for comfortable rest. Good for watching TV."
        ),
        // index 3: >200 lux
        InterpretationResult(
            description: "General office work, kitchen cooking, light reading",
            tip: "The most standard brightness for daily activities and office work."
        ),
        // index 4: >500 lux
        InterpretationResult(
            description: "Focused studying, precision handwork, store displays",
            tip: "Recommended for study rooms or detailed tasks like sewing."
        ),
        // index 5: >1000 lux
        InterpretationResult(
            description: "Bright window (indoors), broadcast studios, operating rooms",
            tip: "Very bright. Suitable for video production or professional work."
        ),
        // index 6: >2000 lux
        InterpretationResult(
            description: "Cloudy day outdoors, sunset outdoors",
            tip: "Good for outdoor activities. Partial shade level for plants."
        ),
        // index 7: >10000 lux
        InterpretationResult(
            description: "Direct sunlight on a clear day, noon outdoors",
            tip: "Strong sunlight. Protect your eyes and watch for plant burns."
        )
    ]

    /// Maps a lux value to its environment description and user guide tip.
    /// Negative values fall back to the 0–10 range.
    static func interpret(lux: Double) -> InterpretationResult {
        let index = LuxRange.rangeIndex(for: lux)
        return results[index]
    }
}
