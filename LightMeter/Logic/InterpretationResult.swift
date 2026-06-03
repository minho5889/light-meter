public struct InterpretationResult: Equatable, Sendable {
    public let description: String
    public let tip: String

    public init(description: String, tip: String) {
        self.description = description
        self.tip = tip
    }
}
