// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AURA",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "AURA", targets: ["AURA"])
    ],
    targets: [
        .executableTarget(
            name: "AURA",
            path: "Sources/AURA"
        )
    ],
    swiftLanguageModes: [.v5]
)
