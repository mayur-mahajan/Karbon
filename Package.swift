// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Karbon",
    products: [
		.executable(name: "Server", targets: ["Server"]),
        .library(name: "Service", targets: ["Service"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mayur-mahajan/swift-nio.git", .revision("2e2cc6029b9fc2a00530db9c57c5f55f169fb668")),
        .package(url: "https://github.com/mayur-mahajan/NetService.git", .revision("9635f7299d006e5228dba8840160eac0e8c40fb5"))
    ],
    targets: [
        .target(name: "Server", dependencies: ["Service"]),
        .target(name: "Service", dependencies: ["NIO", "NIOHTTP1", "NIOConcurrencyHelpers", "NIOFoundationCompat", "NetService"]),
        .testTarget(name: "ServerTests", dependencies: ["Server"]),
    ]
)
