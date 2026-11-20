// swift-tools-version: 6.4

import PackageDescription

let swiftSettings: [SwiftSetting] = [
	.enableUpcomingFeature("ExistentialAny"),
	.enableUpcomingFeature("InferIsolatedConformances"),
	.enableUpcomingFeature("MemberImportVisibility"),
	.enableUpcomingFeature("NonisolatedNonsendingByDefault"),
]

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
		.executable(name: "ths", targets: ["ths"]),
		.executable(name: "is-work-mac", targets: ["is-work-mac"]),
		.executable(name: "pr-draft", targets: ["pr-draft"]),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
		.package(url: "https://github.com/swiftlang/swift-subprocess.git", .upToNextMinor(from: "0.5.0")),
		.package(url: "https://github.com/jpsim/Yams.git", from: "5.1.0"),
		.package(name: "Escape", path: "../Escape"),
	],
	targets: [
		.target(
			name: "CommandKit",
			dependencies: [
				.product(name: "Subprocess", package: "swift-subprocess"),
				"Escape",
			],
			swiftSettings: swiftSettings,
		),
		.executableTarget(
			name: "iosd",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				"CommandKit",
			],
			swiftSettings: swiftSettings,
		),
		.executableTarget(
			name: "chapter-splitter",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				.product(name: "Subprocess", package: "swift-subprocess"),
				"Escape",
			],
			swiftSettings: swiftSettings,
		),
		.executableTarget(
			name: "github-permalink",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				"CommandKit",
			],
			swiftSettings: swiftSettings,
		),
		.executableTarget(
			name: "notify",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser")
			],
			swiftSettings: swiftSettings,
		),
		.executableTarget(
			name: "pr-watch",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				"CommandKit",
			],
			swiftSettings: swiftSettings,
		),
		.executableTarget(
			name: "tp",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				"CommandKit",
			],
			swiftSettings: swiftSettings,
		),
		.executableTarget(
			name: "ths",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				"CommandKit",
				"Yams",
			],
			swiftSettings: swiftSettings,
		),
		.executableTarget(
			name: "is-work-mac",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				"CommandKit",
			],
			swiftSettings: swiftSettings,
		),
		.executableTarget(
			name: "pr-draft",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				"CommandKit",
				"Yams",
			],
			swiftSettings: swiftSettings,
		),
		.testTarget(
			name: "tpTests",
			dependencies: ["tp"],
			swiftSettings: swiftSettings,
		),
		.testTarget(
			name: "thsTests",
			dependencies: ["ths"],
			swiftSettings: swiftSettings,
		),
		.testTarget(
			name: "is-work-macTests",
			dependencies: ["is-work-mac"],
			swiftSettings: swiftSettings,
		),
		.testTarget(
			name: "pr-draftTests",
			dependencies: ["pr-draft", "CommandKit"],
			swiftSettings: swiftSettings,
		),
		.testTarget(
			name: "CommandKitTests",
			dependencies: ["CommandKit"],
			swiftSettings: swiftSettings,
		),
	],
)
