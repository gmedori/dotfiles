import ArgumentParser
import CommandKit
import Foundation

// MARK: - tsh Command Group

struct Tsh: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "tsh",
		abstract: "Manage the tsh executable available in ~/dotfiles/scripts/bin",
		subcommands: [ListInstallations.self, Use.self, Current.self, Unlink.self],
	)

	// MARK: - List

	struct ListInstallations: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			commandName: "list",
			abstract: "List discovered tsh installations",
			aliases: ["ls"],
		)

		func run() async throws {
			let discovery = TshDiscovery()
			let installations = await discovery.discover()
			let linkManager = TshLinkManager()
			let linkState = linkManager.state()

			guard !installations.isEmpty else {
				print("No tsh installations found.")
				printLinkProblem(for: linkState)
				TshEnvironment.printWarningIfNeeded()
				return
			}

			let activeURL = linkState.targetURL?.resolvingSymlinksInPath()
			let table = TshInstallationTable(installations: installations)
			print(table.header)

			for installation in installations {
				print(table.row(for: installation, isActive: installation.url == activeURL))
			}

			printLinkProblem(for: linkState)
			TshEnvironment.printWarningIfNeeded()
		}

		private func printLinkProblem(for state: TshLinkState) {
			switch state {
				case .broken(let targetURL):
					print("\nWarning: ~/dotfiles/scripts/bin/tsh points to missing file \(targetURL.path).")
				case .occupied:
					print("\nWarning: ~/dotfiles/scripts/bin/tsh exists but is not a symbolic link.")
				case .missing, .linked:
					break
			}
		}
	}

	// MARK: - Use

	struct Use: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			commandName: "use",
			abstract: "Select a tsh installation by version or path",
			aliases: ["switch"],
		)

		@Argument(help: "The exact tsh version to select")
		var version: String?

		@Option(name: .long, help: "Select the tsh executable at this path")
		var path: String?

		@Option(name: .long, help: "Limit a version selection to this installation source")
		var source: TshSource?

		func validate() throws {
			guard (version == nil) != (path == nil) else {
				throw ValidationError("Supply either a version or --path, but not both.")
			}

			if path != nil, source != nil {
				throw ValidationError("--source can only be used when selecting by version.")
			}
		}

		func run() async throws {
			try TshEnvironment.requireManagedUpdatesDisabled()

			let discovery = TshDiscovery()
			let installation: TshInstallation
			if let path {
				installation = try await discovery.installation(at: path)
			} else if let version {
				let installations = await discovery.discover()
				installation = try TshSelector.select(
					version: version,
					source: source,
					from: installations
				)
			} else {
				throw ValidationError("Supply either a version or --path.")
			}

			let linkManager = TshLinkManager()
			let changed = try linkManager.link(to: installation.url)
			if changed {
				print("Switched tsh to \(installation.version).")
			} else {
				print("tsh \(installation.version) is already selected.")
			}
			print("~/dotfiles/scripts/bin/tsh -> \(installation.displayPath)")

			if let warning = linkManager.pathWarning() {
				print("Warning: \(warning)")
			}
		}
	}

	// MARK: - Current

	struct Current: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			commandName: "current",
			abstract: "Show the currently selected tsh installation",
			aliases: ["which"],
		)

		func run() async throws {
			let linkManager = TshLinkManager()
			switch linkManager.state() {
				case .missing:
					print("No tsh installation is selected.")
				case .occupied:
					throw RuntimeError("~/dotfiles/scripts/bin/tsh exists but is not a symbolic link.")
				case .broken(let targetURL):
					throw RuntimeError("~/dotfiles/scripts/bin/tsh points to missing file \(targetURL.path).")
				case .linked(let targetURL):
					let installation = try await TshDiscovery().installation(at: targetURL.path)
					print("Version: \(installation.version)")
					print("Source:  \(installation.source.rawValue)")
					print("Path:    \(installation.displayPath)")
			}

			print(
				"Managed updates: "
					+ (TshEnvironment.managedUpdatesDisabled ? "disabled" : "not disabled")
			)
			TshEnvironment.printWarningIfNeeded()

			if let warning = linkManager.pathWarning() {
				print("Warning: \(warning)")
			}
		}
	}

	// MARK: - Unlink

	struct Unlink: ParsableCommand {
		static let configuration = CommandConfiguration(
			commandName: "unlink",
			abstract: "Remove the managed tsh symbolic link",
			aliases: ["remove"],
		)

		func run() throws {
			let removed = try TshLinkManager().unlink()
			print(removed ? "Removed ~/dotfiles/scripts/bin/tsh." : "No tsh installation was selected.")
		}
	}
}

// MARK: - List Formatting

private struct TshInstallationTable {
	private let versionWidth: Int
	private let sourceWidth: Int

	init(installations: [TshInstallation]) {
		versionWidth = max("VERSION".count, installations.map(\.version.count).max() ?? 0)
		sourceWidth = max("SOURCE".count, installations.map(\.source.rawValue.count).max() ?? 0)
	}

	var header: String {
		formattedRow(marker: " ", version: "VERSION", source: "SOURCE", location: "PATH")
	}

	func row(for installation: TshInstallation, isActive: Bool) -> String {
		formattedRow(
			marker: isActive ? "*" : " ",
			version: installation.version,
			source: installation.source.rawValue,
			location: installation.displayPath
		)
	}

	private func formattedRow(
		marker: String,
		version: String,
		source: String,
		location: String
	) -> String {
		let selectionAndVersion = "\(marker) \(padded(version, to: versionWidth))"
		return [selectionAndVersion, padded(source, to: sourceWidth), location]
			.joined(separator: "  ")
	}

	private func padded(_ value: String, to width: Int) -> String {
		value.padding(toLength: width, withPad: " ", startingAt: 0)
	}
}
