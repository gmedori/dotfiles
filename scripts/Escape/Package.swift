// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Escape",
	platforms: [.macOS(.v14)],
	products: [
		.executable(
			name: "EscapeClient",
			targets: ["EscapeClient"]
		),
		.library(
			name: "Escape",
			targets: ["Escape"]
		),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(name: "Escape"),
		.executableTarget(name: "EscapeClient", dependencies: ["Escape"]),
		.testTarget(
			name: "EscapeTests",
			dependencies: ["Escape"]
		),
	]
)
