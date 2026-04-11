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
                "LuxInterpreter.swift",
                "KelvinInterpreter.swift",
                "ComparisonGenerator.swift"
            ]
        ),
        .testTarget(
            name: "LightMeterTests",
            dependencies: ["LightMeter"],
            path: "LightMeterTests",
            sources: [
                "LuxInterpreterTests.swift",
                "KelvinInterpreterTests.swift",
                "ComparisonGeneratorTests.swift"
            ]
        )
    ]
)
