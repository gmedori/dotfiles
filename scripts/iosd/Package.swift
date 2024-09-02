// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "iosd",
	platforms: [.macOS(.v14)],
	products: [
		.executable(name: "iosd", targets: ["iosd"])
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(name: "Escape", path: "../Escape"),
		.package(name: "Command", path: "../Command"),
	],
	targets: [
		.executableTarget(
			name: "iosd",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				"Escape",
				"Command",
			]
		),
	]
)
