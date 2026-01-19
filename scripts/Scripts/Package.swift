// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Scripts",
	platforms: [.macOS(.v14)],
	products: [
		.executable(name: "iosd", targets: ["iosd"]),
		.executable(name: "chapter-splitter", targets: ["chapter-splitter"]),
		.executable(name: "dia", targets: ["dia"]),
		.executable(name: "notify", targets: ["notify"]),
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
		.executableTarget(
			name: "chapter-splitter",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				"Escape",
				"Command",
			]
		),
		.executableTarget(
			name: "dia",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				"Escape",
				"Command",
			]
		),
		.executableTarget(
			name: "notify",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
			]
		),
	]
)
