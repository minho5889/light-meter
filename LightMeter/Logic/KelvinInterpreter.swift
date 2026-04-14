struct KelvinInterpreter {
    /// Maps a Kelvin value to its color tone label and recommended environment.
    /// Values below 1000 fall back to the "Below 2,000K" range.
    static func interpret(kelvin: Double) -> InterpretationResult {
        if kelvin >= 10000 {
            return InterpretationResult(
                description: "Blue Sky 🧊",
                tip: "Clear day shade, specialized lab environments"
            )
        } else if kelvin >= 6500 {
            return InterpretationResult(
                description: "Cool White ❄",
                tip: "Hospitals, factories, warehouses"
            )
        } else if kelvin >= 5000 {
            return InterpretationResult(
                description: "Daylight 📖",
                tip: "Study rooms, offices, precision work (improves focus)"
            )
        } else if kelvin >= 3500 {
            return InterpretationResult(
                description: "Natural White 🌤",
                tip: "Kitchens, dressing rooms, bathrooms"
            )
        } else if kelvin >= 2000 {
            return InterpretationResult(
                description: "Warm White 💡",
                tip: "Bedrooms, living rooms, relaxation spaces"
            )
        } else {
            return InterpretationResult(
                description: "Candlelight / Sunset 🔥",
                tip: "Psychological calm, pre-sleep, atmospheric cafes"
            )
        }
    }
}
