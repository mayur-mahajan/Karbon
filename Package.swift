// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Karbon",
    products: [
		.executable(name: "Server", targets: ["Server"]),
        .library(name: "Service", targets: ["Service"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.0.0")
    ],
    targets: [
        .target(name: "Server", dependencies: ["Service"]),
        .target(name: "Service", dependencies: ["NIO", "NIOHTTP1", "NIOConcurrencyHelpers", "NIOFoundationCompat"]),
        .testTarget(name: "ServerTests", dependencies: ["Server"]),
    ]
)
