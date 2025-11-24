// swift-tools-version:5.9
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
