import Testing
@testable import LightMeter

struct ComparisonGeneratorTests {

    // MARK: - Helpers

    /// Independent oracle: compute expected range index using the same boundary logic as LuxInterpreter.
    private func expectedRangeIndex(for lux: Double) -> Int {
        if lux > 10000 { return 7 }
        if lux > 2000 { return 6 }
        if lux > 1000 { return 5 }
        if lux > 500 { return 4 }
        if lux > 200 { return 3 }
        if lux > 100 { return 2 }
        if lux > 10 { return 1 }
        return 0
    }

    /// Short environment labels matching ComparisonGenerator's internal array.
    private let labels = [
        "very dark outdoors",
        "hallways and movie theaters",
        "a living room",
        "an office",
        "a study room",
        "a bright window indoors",
        "a cloudy day outdoors",
        "direct sunlight"
    ]

    /// Maps a LuxInterpreter description to its range index.
    private func interpreterDescriptionToIndex(_ description: String) -> Int {
        switch description {
        case "Very dark outdoors, full moon night": return 0
        case "Hallways, bathrooms, movie theaters": return 1
        case "Living room relaxation, dining, hotel rooms": return 2
        case "General office work, kitchen cooking, light reading": return 3
        case "Focused studying, precision handwork, store displays": return 4
        case "Bright window (indoors), broadcast studios, operating rooms": return 5
        case "Cloudy day outdoors, sunset outdoors": return 6
        case "Direct sunlight on a clear day, noon outdoors": return 7
        default: return -1
        }
    }

    // MARK: - Property 1: Comparison sentence completeness
    // **Validates: Requirements 6.5, 6.7**

    @Test func property_comparisonSentenceCompleteness() {
        var rng = SystemRandomNumberGenerator()

        for _ in 0..<150 {
            let lux = Double.random(in: -1000...200000, using: &rng)
            let result = ComparisonGenerator.generate(lux: lux)
            #expect(!result.isEmpty, "Sentence should be non-empty for lux=\(lux)")
        }
    }

    // MARK: - Property 2: Comparison sentence correctness
    // **Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.6**

    @Test func property_comparisonSentenceCorrectness() {
        var rng = SystemRandomNumberGenerator()

        for _ in 0..<150 {
            let lux = Double.random(in: -1000...200000, using: &rng)
            let result = ComparisonGenerator.generate(lux: lux)
            let index = expectedRangeIndex(for: lux)

            if index == 0 {
                #expect(result.contains("Darker than"), "Index 0 should start with 'Darker than' for lux=\(lux)")
                #expect(result.contains(labels[1]), "Index 0 should reference label[1] for lux=\(lux)")
            } else if index == 7 {
                #expect(result.contains("Brighter than"), "Index 7 should start with 'Brighter than' for lux=\(lux)")
                #expect(result.contains(labels[6]), "Index 7 should reference label[6] for lux=\(lux)")
            } else {
                #expect(result.contains("Brighter than \(labels[index - 1])"),
                    "Middle index \(index) should reference lower label for lux=\(lux)")
                #expect(result.contains("but darker than \(labels[index + 1])"),
                    "Middle index \(index) should reference upper label for lux=\(lux)")
            }
        }
    }

    // MARK: - Property 3: Comparison range consistency
    // **Validates: Requirements 6.1, 6.6**

    @Test func property_comparisonRangeConsistency() {
        var rng = SystemRandomNumberGenerator()

        for _ in 0..<150 {
            let lux = Double.random(in: -1000...200000, using: &rng)
            let sentence = ComparisonGenerator.generate(lux: lux)
            let interpreterResult = LuxInterpreter.interpret(lux: lux, language: .english)
            let interpreterIndex = interpreterDescriptionToIndex(interpreterResult.description)

            #expect(interpreterIndex >= 0, "Unknown interpreter description for lux=\(lux)")

            // Verify the sentence references the correct adjacent labels for the interpreter's index
            if interpreterIndex == 0 {
                #expect(sentence.contains(labels[1]),
                    "Index 0: sentence should reference upper adjacent label for lux=\(lux)")
            } else if interpreterIndex == 7 {
                #expect(sentence.contains(labels[6]),
                    "Index 7: sentence should reference lower adjacent label for lux=\(lux)")
            } else {
                #expect(sentence.contains(labels[interpreterIndex - 1]),
                    "Index \(interpreterIndex): sentence should reference lower adjacent label for lux=\(lux)")
                #expect(sentence.contains(labels[interpreterIndex + 1]),
                    "Index \(interpreterIndex): sentence should reference upper adjacent label for lux=\(lux)")
            }
        }
    }

    // MARK: - Unit Tests: Representative values per range

    @Test func range_veryDark() {
        let s = ComparisonGenerator.generate(lux: 5)
        #expect(s == "Darker than hallways and movie theaters")
    }

    @Test func range_hallways() {
        let s = ComparisonGenerator.generate(lux: 50)
        #expect(s == "Brighter than very dark outdoors but darker than a living room")
    }

    @Test func range_livingRoom() {
        let s = ComparisonGenerator.generate(lux: 150)
        #expect(s == "Brighter than hallways and movie theaters but darker than an office")
    }

    @Test func range_office() {
        let s = ComparisonGenerator.generate(lux: 350)
        #expect(s == "Brighter than a living room but darker than a study room")
    }

    @Test func range_studyRoom() {
        let s = ComparisonGenerator.generate(lux: 750)
        #expect(s == "Brighter than an office but darker than a bright window indoors")
    }

    @Test func range_brightWindow() {
        let s = ComparisonGenerator.generate(lux: 1500)
        #expect(s == "Brighter than a study room but darker than a cloudy day outdoors")
    }

    @Test func range_cloudyDay() {
        let s = ComparisonGenerator.generate(lux: 5000)
        #expect(s == "Brighter than a bright window indoors but darker than direct sunlight")
    }

    @Test func range_directSunlight() {
        let s = ComparisonGenerator.generate(lux: 50000)
        #expect(s == "Brighter than a cloudy day outdoors")
    }

    // MARK: - Unit Tests: Boundary values

    @Test func boundary_0() {
        let s = ComparisonGenerator.generate(lux: 0)
        #expect(s == "Darker than hallways and movie theaters")
    }

    @Test func boundary_10() {
        let s = ComparisonGenerator.generate(lux: 10)
        #expect(s == "Darker than hallways and movie theaters")
    }

    @Test func boundary_11() {
        let s = ComparisonGenerator.generate(lux: 11)
        #expect(s == "Brighter than very dark outdoors but darker than a living room")
    }

    @Test func boundary_100() {
        let s = ComparisonGenerator.generate(lux: 100)
        #expect(s == "Brighter than very dark outdoors but darker than a living room")
    }

    @Test func boundary_101() {
        let s = ComparisonGenerator.generate(lux: 101)
        #expect(s == "Brighter than hallways and movie theaters but darker than an office")
    }

    @Test func boundary_200() {
        let s = ComparisonGenerator.generate(lux: 200)
        #expect(s == "Brighter than hallways and movie theaters but darker than an office")
    }

    @Test func boundary_201() {
        let s = ComparisonGenerator.generate(lux: 201)
        #expect(s == "Brighter than a living room but darker than a study room")
    }

    @Test func boundary_500() {
        let s = ComparisonGenerator.generate(lux: 500)
        #expect(s == "Brighter than a living room but darker than a study room")
    }

    @Test func boundary_501() {
        let s = ComparisonGenerator.generate(lux: 501)
        #expect(s == "Brighter than an office but darker than a bright window indoors")
    }

    @Test func boundary_1000() {
        let s = ComparisonGenerator.generate(lux: 1000)
        #expect(s == "Brighter than an office but darker than a bright window indoors")
    }

    @Test func boundary_1001() {
        let s = ComparisonGenerator.generate(lux: 1001)
        #expect(s == "Brighter than a study room but darker than a cloudy day outdoors")
    }

    @Test func boundary_2000() {
        let s = ComparisonGenerator.generate(lux: 2000)
        #expect(s == "Brighter than a study room but darker than a cloudy day outdoors")
    }

    @Test func boundary_2001() {
        let s = ComparisonGenerator.generate(lux: 2001)
        #expect(s == "Brighter than a bright window indoors but darker than direct sunlight")
    }

    @Test func boundary_10000() {
        let s = ComparisonGenerator.generate(lux: 10000)
        #expect(s == "Brighter than a bright window indoors but darker than direct sunlight")
    }

    @Test func boundary_10001() {
        let s = ComparisonGenerator.generate(lux: 10001)
        #expect(s == "Brighter than a cloudy day outdoors")
    }

    // MARK: - Unit Tests: Negative value

    @Test func negativeValue_producesDarkerSentence() {
        let s = ComparisonGenerator.generate(lux: -50)
        #expect(s == "Darker than hallways and movie theaters")
    }

    // MARK: - Unit Tests: Sentence format patterns

    @Test func lowestRange_startsWithDarkerThan() {
        let s = ComparisonGenerator.generate(lux: 3)
        #expect(s.hasPrefix("Darker than"))
    }

    @Test func highestRange_startsWithBrighterThan() {
        let s = ComparisonGenerator.generate(lux: 99999)
        #expect(s.hasPrefix("Brighter than"))
    }

    @Test func middleRange_containsBrighterAndDarker() {
        let s = ComparisonGenerator.generate(lux: 300)
        #expect(s.contains("Brighter than"))
        #expect(s.contains("but darker than"))
    }
}
