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
                "Logic/FlickerAnalyzer.swift",
                "Design/DesignConstants.swift",
                "Logic/AppLanguage.swift",
                "Logic/LocalizedStrings.swift",
                "Logic/FlickerInterpreter.swift",
                "Logic/ActivityChip.swift",
                "Logic/SignalSmoother.swift",
                "Logic/TintInterpreter.swift",
                "Logic/CalibrationStore.swift"
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
                "Logic/FlickerAnalyzerTests.swift",
                "Formatting/NumberFormattingTests.swift",
                "Logic/FlickerInterpreterTests.swift",
                "Logic/LocalizationTests.swift",
                "Logic/SignalSmootherTests.swift",
                "Logic/TintInterpreterTests.swift",
                "Logic/CalibrationStoreTests.swift"
            ]
        )
    ]
)
