// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Karbon",
    products: [
		.executable(name: "Server", targets: ["Server"]),
        .library(name: "Service", targets: ["Service"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.0.0"),
        .package(url: "https://github.com/Bouke/NetService.git", from: "0.3.0")
//        .package(url: "https://github.com/mayur-mahajan/swift-nio.git", .revision("2e2cc6029b9fc2a00530db9c57c5f55f169fb668")),
//        .package(url: "https://github.com/mayur-mahajan/NetService.git", .revision("22cd18c243f30d63214f23973a1d654821b8dbb2"))
    ],
    targets: [
        .target(name: "Server", dependencies: ["Service"]),
        .target(name: "Service", dependencies: ["NIO", "NIOHTTP1", "NIOConcurrencyHelpers", "NIOFoundationCompat", "NetService"]),
        .testTarget(name: "ServerTests", dependencies: ["Server"]),
    ]
)
