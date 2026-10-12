// swift-tools-version: 6.3
import PackageDescription

let strict: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("ImmutableWeakCaptures"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .treatAllWarnings(as: .error),
]

let mainActorByDefault = strict + [.defaultIsolation(MainActor.self)]

let package = Package(
    name: "Waft",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Waft", targets: ["Waft"]),
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/argmax-oss-swift.git", exact: "1.1.1"),
        .package(url: "https://github.com/sparkle-project/Sparkle.git", exact: "2.10.0"),
    ],
    targets: [
        .target(
            name: "WaftCore",
            swiftSettings: strict + [.strictMemorySafety()],
        ),
        .target(
            name: "WaftSpeech",
            dependencies: [
                "WaftCore",
                .product(name: "WhisperKit", package: "argmax-oss-swift"),
            ],
            swiftSettings: strict,
        ),
        .target(
            name: "WaftPlatform",
            dependencies: [
                "WaftCore",
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            swiftSettings: strict,
        ),
        .target(
            name: "WaftFeatures",
            dependencies: ["WaftCore"],
            swiftSettings: mainActorByDefault,
        ),
        .executableTarget(
            name: "Waft",
            dependencies: ["WaftCore", "WaftFeatures", "WaftPlatform", "WaftSpeech"],
            swiftSettings: mainActorByDefault,
        ),
    ],
)
