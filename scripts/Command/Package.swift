// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Command",
	platforms: [.macOS(.v14)],
	products: [
		.library(name: "Command", targets: ["Command"]),
		.executable(name: "CommandPlayground", targets: ["CommandPlayground"]),
	],
	targets: [
		.target(name: "Command"),
		.executableTarget(name: "CommandPlayground", dependencies: ["Command"]),
		.testTarget(name: "CommandTests", dependencies: ["Command"]),
	]
)
