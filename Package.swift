// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "PhasirApp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .executable(name: "PhasirApp", targets: ["PhasirApp"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "PhasirApp",
            path: "Sources"
        )
    ]
)
