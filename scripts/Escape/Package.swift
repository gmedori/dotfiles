// swift-tools-version: 6.4

import PackageDescription

let swiftSettings: [SwiftSetting] = [
	.enableUpcomingFeature("ExistentialAny"),
	.enableUpcomingFeature("InferIsolatedConformances"),
	.enableUpcomingFeature("MemberImportVisibility"),
	.enableUpcomingFeature("NonisolatedNonsendingByDefault"),
]

let package = Package(
	name: "Escape",
	platforms: [.macOS(.v14)],
	products: [
		.executable(name: "EscapeClient", targets: ["EscapeClient"]),
		.library(name: "Escape", targets: ["Escape"]),
	],
	targets: [
		.target(name: "Escape", swiftSettings: swiftSettings),
		.executableTarget(name: "EscapeClient", dependencies: ["Escape"], swiftSettings: swiftSettings),
		.testTarget(name: "EscapeTests", dependencies: ["Escape"], swiftSettings: swiftSettings),
	],
)
