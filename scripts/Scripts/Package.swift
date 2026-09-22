// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Scripts",
	platforms: [.macOS(.v14)],
	products: [
		.executable(name: "iosd", targets: ["iosd"]),
		.executable(name: "chapter-splitter", targets: ["chapter-splitter"]),
		.executable(name: "github-permalink", targets: ["github-permalink"]),
		.executable(name: "notify", targets: ["notify"]),
		.executable(name: "pr-watch", targets: ["pr-watch"]),
		.executable(name: "tp", targets: ["tp"]),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
		.package(url: "https://github.com/swiftlang/swift-subprocess.git", .upToNextMinor(from: "0.5.0")),
		.package(name: "Escape", path: "../Escape"),
	],
	targets: [
		.target(
			name: "CommandKit",
			dependencies: [
				.product(name: "Subprocess", package: "swift-subprocess"),
				"Escape",
			],
		),
		.executableTarget(
			name: "iosd",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				"CommandKit",
			],
		),
		.executableTarget(
			name: "chapter-splitter",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				.product(name: "Subprocess", package: "swift-subprocess"),
				"Escape",
			],
		),
		.executableTarget(
			name: "github-permalink",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				"CommandKit",
			],
		),
		.executableTarget(
			name: "notify",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
			],
		),
		.executableTarget(
			name: "pr-watch",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				"CommandKit",
			],
		),
		.executableTarget(
			name: "tp",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				"CommandKit",
			],
		),
		.testTarget(
			name: "tpTests",
			dependencies: ["tp"],
		),
	],
)
