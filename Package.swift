// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LightMeter",
    platforms: [.iOS(.v17), .macOS(.v14)],
    targets: [
        .target(
            name: "LightMeter",
            path: "LightMeter",
            exclude: ["Info.plist"],
            sources: [
                "Logic/InterpretationResult.swift",
                "Logic/LuxCalculator.swift",
                "Logic/ColorTemperatureCalculator.swift",
                "Logic/LuxInterpreter.swift",
                "Logic/KelvinInterpreter.swift",
                "Logic/ComparisonGenerator.swift",
                "Logic/LuxRange.swift",
                "Logic/TabTransitionAction.swift",
                "Design/DesignConstants.swift"
            ]
        ),
        .testTarget(
            name: "LightMeterTests",
            dependencies: ["LightMeter"],
            path: "LightMeterTests",
            sources: [
                "Logic/LuxCalculatorTests.swift",
                "Logic/ColorTemperatureCalculatorTests.swift",
                "Logic/LuxInterpreterTests.swift",
                "Logic/KelvinInterpreterTests.swift",
                "Logic/ComparisonGeneratorTests.swift",
                "Logic/LuxRangeTests.swift",
                "Logic/TabTransitionActionTests.swift",
                "Formatting/NumberFormattingTests.swift"
            ]
        )
    ]
)
