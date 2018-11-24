// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Karbon",
    products: [
		.executable(name: "Server", targets: ["Server"]),
        .library(name: "Service", targets: ["Service"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mayur-mahajan/swift-nio.git", .revision("26324082af963922fda832c626287a81d532f8d4")),
        .package(url: "https://github.com/mayur-mahajan/NetService.git", .revision("7dd736338a5ce7acf11fd01b4e8d4038990f09ec"))
    ],
    targets: [
        .target(name: "Server", dependencies: ["Service"]),
        .target(name: "Service", dependencies: ["NIO", "NIOHTTP1", "NIOConcurrencyHelpers", "NIOFoundationCompat", "NetService"]),
        .testTarget(name: "ServerTests", dependencies: ["Server"]),
    ]
)
