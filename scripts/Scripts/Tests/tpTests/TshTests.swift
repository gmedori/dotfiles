import Foundation
import Testing
@testable import tp

// MARK: - Version Parsing

@Suite("tsh version parsing")
struct TshVersionParsingTests {
	@Test("Parses release output")
	func parsesReleaseOutput() {
		let output = "Teleport v18.8.2 git:v18.8.2-0-g2baa4e20 go1.25.10"
		#expect(TshVersionParser.version(from: output) == "18.8.2")
	}

	@Test("Parses development and enterprise output")
	func parsesDevelopmentOutput() {
		let output = "Teleport Enterprise v19.0.0-prealpha.2 git:local go1.26"
		#expect(TshVersionParser.version(from: output) == "19.0.0-prealpha.2")
	}

	@Test("Ignores unrelated diagnostics")
	func ignoresDiagnostics() {
		let output = "A warning from tsh\nTeleport v17.7.1 git:v17.7.1 go1.24"
		#expect(TshVersionParser.version(from: output) == "17.7.1")
	}
}

// MARK: - Selection

@Suite("tsh selection")
struct TshSelectionTests {
	private let connect = TshInstallation(
		version: "18.8.2",
		versionOutput: "Teleport v18.8.2",
		url: URL(fileURLWithPath: "/Applications/Teleport Connect.app/Contents/MacOS/tsh"),
		source: .connect
	)
	private let local = TshInstallation(
		version: "18.8.2",
		versionOutput: "Teleport v18.8.2",
		url: URL(fileURLWithPath: "/Users/test/code/teleport/build/tsh"),
		source: .source
	)

	@Test("Accepts versions with a leading v")
	func acceptsLeadingV() throws {
		let selected = try TshSelector.select(
			version: "v18.8.2",
			source: .connect,
			from: [connect, local]
		)
		#expect(selected == connect)
	}

	@Test("Uses source to distinguish matching versions")
	func distinguishesSources() throws {
		let selected = try TshSelector.select(
			version: "18.8.2",
			source: .source,
			from: [connect, local]
		)
		#expect(selected == local)
	}

	@Test("Refuses an ambiguous version")
	func refusesAmbiguousVersion() {
		do {
			_ = try TshSelector.select(
				version: "18.8.2",
				source: nil,
				from: [connect, local]
			)
			Issue.record("Expected an ambiguous version to be rejected")
		} catch {
			#expect(String(describing: error).contains("Multiple installations"))
		}
	}
}

// MARK: - Symbolic Link Management

@Suite("tsh symbolic link management")
struct TshLinkManagerTests {
	@Test("Creates and atomically replaces the managed link")
	func createsAndReplacesLink() throws {
		let fixture = try Fixture()
		defer { fixture.remove() }

		let first = try fixture.makeCandidate(named: "first")
		let second = try fixture.makeCandidate(named: "second")
		let manager = fixture.manager()

		#expect(try manager.link(to: first))
		#expect(manager.state() == .linked(first))
		#expect(try !manager.link(to: first))

		#expect(try manager.link(to: second))
		#expect(manager.state() == .linked(second))
	}

	@Test("Refuses to overwrite a regular file")
	func preservesRegularFile() throws {
		let fixture = try Fixture()
		defer { fixture.remove() }

		let candidate = try fixture.makeCandidate(named: "candidate")
		let manager = fixture.manager()
		try FileManager.default.createDirectory(
			at: manager.linkURL.deletingLastPathComponent(),
			withIntermediateDirectories: true
		)
		#expect(FileManager.default.createFile(
			atPath: manager.linkURL.path,
			contents: Data("keep me".utf8)
		))

		do {
			_ = try manager.link(to: candidate)
			Issue.record("Expected a regular file to be preserved")
		} catch {
			#expect(String(describing: error).contains("refusing to replace"))
		}

		let contents = try String(contentsOf: manager.linkURL, encoding: .utf8)
		#expect(contents == "keep me")
	}

	@Test("Removes a broken managed link")
	func removesBrokenLink() throws {
		let fixture = try Fixture()
		defer { fixture.remove() }

		let manager = fixture.manager()
		try FileManager.default.createDirectory(
			at: manager.linkURL.deletingLastPathComponent(),
			withIntermediateDirectories: true
		)
		let missing = fixture.root.appending(path: "missing")
		try FileManager.default.createSymbolicLink(
			at: manager.linkURL,
			withDestinationURL: missing
		)

		#expect(manager.state() == .broken(missing))
		#expect(try manager.unlink())
		#expect(manager.state() == .missing)
	}
}

// MARK: - Environment

@Suite("tsh environment")
struct TshEnvironmentTests {
	@Test("Only off disables managed updates")
	func requiresOff() {
		#expect(TshEnvironment.managedUpdatesDisabled(in: ["TELEPORT_TOOLS_VERSION": "off"]))
		#expect(!TshEnvironment.managedUpdatesDisabled(in: [:]))
		#expect(!TshEnvironment.managedUpdatesDisabled(
			in: ["TELEPORT_TOOLS_VERSION": "18.8.2"]
		))
	}

	@Test("Provides fish configuration guidance")
	func providesFishGuidance() {
		#expect(
			TshEnvironment.fishConfigurationCommand
				== "echo 'set -gx TELEPORT_TOOLS_VERSION off' >> ~/.config/fish/config.fish"
		)
	}
}

// MARK: - Fixtures

private struct Fixture {
	let root: URL

	init() throws {
		root = FileManager.default.temporaryDirectory
			.appending(path: "tp-tests-\(UUID().uuidString)")
		try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
	}

	func manager() -> TshLinkManager {
		TshLinkManager(
			homeDirectory: root,
			environment: ["PATH": root.appending(path: "dotfiles/scripts/bin").path]
		)
	}

	func makeCandidate(named name: String) throws -> URL {
		let candidates = root.appending(path: "candidates", directoryHint: .isDirectory)
		try FileManager.default.createDirectory(at: candidates, withIntermediateDirectories: true)
		let candidate = candidates.appending(path: name)
		guard FileManager.default.createFile(
			atPath: candidate.path,
			contents: Data(name.utf8)
		) else {
			throw FixtureError.couldNotCreateCandidate
		}
		return candidate
	}

	func remove() {
		try? FileManager.default.removeItem(at: root)
	}
}

private enum FixtureError: Error {
	case couldNotCreateCandidate
}
