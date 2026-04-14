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
                "InterpretationResult.swift",
                "LuxCalculator.swift",
                "ColorTemperatureCalculator.swift",
                "LuxInterpreter.swift",
                "KelvinInterpreter.swift",
                "ComparisonGenerator.swift",
                "LuxRange.swift"
            ]
        ),
        .testTarget(
            name: "LightMeterTests",
            dependencies: ["LightMeter"],
            path: "LightMeterTests",
            sources: [
                "LuxCalculatorTests.swift",
                "ColorTemperatureCalculatorTests.swift",
                "LuxInterpreterTests.swift",
                "KelvinInterpreterTests.swift",
                "ComparisonGeneratorTests.swift",
                "LuxRangeTests.swift"
            ]
        )
    ]
)
