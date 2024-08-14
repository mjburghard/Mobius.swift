// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Mobius",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v8),
    ],
    products: [
        .library(name: "MobiusCore", targets: ["MobiusCore"]),
        .library(name: "MobiusExtras", targets: ["MobiusExtras"]),
        .library(name: "MobiusNimble", targets: ["MobiusNimble"]),
        .library(name: "MobiusTest", targets: ["MobiusTest"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-case-paths", .upToNextMinor(from: "0.10.1")),
        .package(url: "https://github.com/Quick/Nimble", from: "13.0.0"),
        .package(url: "https://github.com/Quick/Quick", from: "7.0.0"),
    ],
    targets: [
        .target(name: "MobiusCore", dependencies: [.product(name: "CasePaths", package: "swift-case-paths")], path: "MobiusCore/Source"),
        .target(name: "MobiusExtras", dependencies: ["MobiusCore"], path: "MobiusExtras/Source"),
        .target(name: "MobiusNimble", dependencies: ["MobiusCore", "MobiusTest", "Nimble"], path: "MobiusNimble/Source"),
        .target(name: "MobiusTest", dependencies: ["MobiusCore"], path: "MobiusTest/Source"),
        .target(name: "MobiusThrowableAssertion", path: "MobiusThrowableAssertion/Source"),

        .testTarget(
            name: "MobiusCoreTests",
            dependencies: ["MobiusCore", "Nimble", "Quick", "MobiusThrowableAssertion"],
            path: "MobiusCore/Test"
        ),
        .testTarget(
            name: "MobiusExtrasTests",
            dependencies: ["MobiusCore", "MobiusExtras", "Nimble", "Quick", "MobiusThrowableAssertion"],
            path: "MobiusExtras/Test"
        ),
        .testTarget(name: "MobiusNimbleTests", dependencies: ["MobiusNimble", "Quick"], path: "MobiusNimble/Test"),
        .testTarget(name: "MobiusTestTests", dependencies: ["MobiusTest", "Quick", "Nimble"], path: "MobiusTest/Test"),
    ],
    swiftLanguageVersions: [.v5]
)
