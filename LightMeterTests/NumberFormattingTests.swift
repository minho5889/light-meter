import Foundation
import Testing

struct NumberFormattingTests {

    // MARK: - Property 1: Number formatting round-trip
    // **Validates: Requirements 5.5**
    // Tag: Feature: 07-code-review-polish, Property 1: Number formatting round-trip

    @Test func property_numberFormattingRoundTrip() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_US")

        for _ in 0..<200 {
            let value = Double.random(in: 0...200_000)
            let expected = value.rounded(.toNearestOrAwayFromZero)

            let formatted = formatter.string(from: NSNumber(value: value))!
            let parsed = formatter.number(from: formatted)!.doubleValue

            #expect(
                parsed == expected,
                "Round-trip failed for \(value): formatted=\"\(formatted)\", parsed=\(parsed), expected=\(expected)"
            )
        }
    }
}
