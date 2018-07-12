// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Karbon",
    products: [
		.executable(name: "Server", targets: ["Server"]),
        .library(name: "Service", targets: ["Service"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mayur-mahajan/swift-nio.git", .revision("d913c886befe2f92ae250ad1666131b6013e32d9")),
        .package(url: "https://github.com/mayur-mahajan/NetService.git", .revision("75ed5c4aa92eaaa53dfafaa9e12a0dce5211d23a"))
    ],
    targets: [
        .target(name: "Server", dependencies: ["Service"]),
        .target(name: "Service", dependencies: ["NIO", "NIOHTTP1", "NIOConcurrencyHelpers", "NIOFoundationCompat", "NetService"]),
        .testTarget(name: "ServerTests", dependencies: ["Server"]),
    ]
)
