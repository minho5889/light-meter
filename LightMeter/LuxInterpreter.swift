struct LuxInterpreter {
    /// Maps a lux value to its environment description and user guide tip.
    /// Negative values fall back to the 0–10 range.
    static func interpret(lux: Double) -> InterpretationResult {
        if lux > 10000 {
            return InterpretationResult(
                description: "Direct sunlight on a clear day, noon outdoors",
                tip: "Strong sunlight. Protect your eyes and watch for plant burns."
            )
        } else if lux > 2000 {
            return InterpretationResult(
                description: "Cloudy day outdoors, sunset outdoors",
                tip: "Good for outdoor activities. Partial shade level for plants."
            )
        } else if lux > 1000 {
            return InterpretationResult(
                description: "Bright window (indoors), broadcast studios, operating rooms",
                tip: "Very bright. Suitable for video production or professional work."
            )
        } else if lux > 500 {
            return InterpretationResult(
                description: "Focused studying, precision handwork, store displays",
                tip: "Recommended for study rooms or detailed tasks like sewing."
            )
        } else if lux > 200 {
            return InterpretationResult(
                description: "General office work, kitchen cooking, light reading",
                tip: "The most standard brightness for daily activities and office work."
            )
        } else if lux > 100 {
            return InterpretationResult(
                description: "Living room relaxation, dining, hotel rooms",
                tip: "Optimal for comfortable rest. Good for watching TV."
            )
        } else if lux > 10 {
            return InterpretationResult(
                description: "Hallways, bathrooms, storage rooms, movie theaters",
                tip: "Suitable for passing through. Not appropriate for extended work."
            )
        } else {
            return InterpretationResult(
                description: "Very dark outdoors, full moon night",
                tip: "Pre-sleep conditions. Be careful when moving around."
            )
        }
    }
}
