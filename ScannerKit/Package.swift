// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScannerKit",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "ScannerKit", targets: ["ScannerKit"]),
    ],
    targets: [
        .target(name: "ScannerKit"),
    ]
)
