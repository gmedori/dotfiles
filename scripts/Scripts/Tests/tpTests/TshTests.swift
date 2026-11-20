import Foundation
import Testing
@testable import tp

// MARK: - Version Parsing

struct `tsh version parsing` {
	@Test
	func `Parses release output`() {
		let output = "Teleport v18.8.2 git:v18.8.2-0-g2baa4e20 go1.25.10"
		#expect(TshVersionParser.version(from: output) == "18.8.2")
	}

	@Test
	func `Parses development and enterprise output`() {
		let output = "Teleport Enterprise v19.0.0-prealpha.2 git:local go1.26"
		#expect(TshVersionParser.version(from: output) == "19.0.0-prealpha.2")
	}

	@Test
	func `Ignores unrelated diagnostics`() {
		let output = "A warning from tsh\nTeleport v17.7.1 git:v17.7.1 go1.24"
		#expect(TshVersionParser.version(from: output) == "17.7.1")
	}
}

// MARK: - Selection

struct `tsh selection` {
	private let connect = TshInstallation(
		version: "18.8.2",
		versionOutput: "Teleport v18.8.2",
		url: URL(fileURLWithPath: "/Applications/Teleport Connect.app/Contents/MacOS/tsh"),
		source: .connect,
	)
	private let local = TshInstallation(
		version: "18.8.2",
		versionOutput: "Teleport v18.8.2",
		url: URL(fileURLWithPath: "/Users/test/code/teleport/build/tsh"),
		source: .source,
	)

	@Test
	func `Accepts versions with a leading v`() throws {
		let selected = try TshSelector.select(
			version: "v18.8.2",
			source: .connect,
			from: [connect, local],
		)
		#expect(selected == connect)
	}

	@Test
	func `Uses source to distinguish matching versions`() throws {
		let selected = try TshSelector.select(
			version: "18.8.2",
			source: .source,
			from: [connect, local],
		)
		#expect(selected == local)
	}

	@Test
	func `Refuses an ambiguous version`() {
		do {
			_ = try TshSelector.select(
				version: "18.8.2",
				source: nil,
				from: [connect, local],
			)
			Issue.record("Expected an ambiguous version to be rejected")
		} catch {
			#expect(String(describing: error).contains("Multiple installations"))
		}
	}
}

// MARK: - Symbolic Link Management

struct `tsh symbolic link management` {
	@Test
	func `Creates and atomically replaces the managed link`() throws {
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

	@Test
	func `Refuses to overwrite a regular file`() throws {
		let fixture = try Fixture()
		defer { fixture.remove() }

		let candidate = try fixture.makeCandidate(named: "candidate")
		let manager = fixture.manager()
		try FileManager.default.createDirectory(
			at: manager.linkURL.deletingLastPathComponent(),
			withIntermediateDirectories: true,
		)
		#expect(FileManager.default.createFile(
			atPath: manager.linkURL.path,
			contents: Data("keep me".utf8),
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

	@Test
	func `Removes a broken managed link`() throws {
		let fixture = try Fixture()
		defer { fixture.remove() }

		let manager = fixture.manager()
		try FileManager.default.createDirectory(
			at: manager.linkURL.deletingLastPathComponent(),
			withIntermediateDirectories: true,
		)
		let missing = fixture.root.appending(path: "missing")
		try FileManager.default.createSymbolicLink(
			at: manager.linkURL,
			withDestinationURL: missing,
		)

		#expect(manager.state() == .broken(missing))
		#expect(try manager.unlink())
		#expect(manager.state() == .missing)
	}
}

// MARK: - Environment

struct `tsh environment` {
	@Test
	func `Only off disables managed updates`() {
		#expect(TshEnvironment.managedUpdatesDisabled(in: ["TELEPORT_TOOLS_VERSION": "off"]))
		#expect(!TshEnvironment.managedUpdatesDisabled(in: [:]))
		#expect(!TshEnvironment.managedUpdatesDisabled(
			in: ["TELEPORT_TOOLS_VERSION": "18.8.2"]
		))
	}

	@Test
	func `Provides fish configuration guidance`() {
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
		self.root = FileManager.default
			.temporaryDirectory
			.appending(path: "tp-tests-\(UUID().uuidString)")
		try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
	}

	func manager() -> TshLinkManager {
		TshLinkManager(
			homeDirectory: root,
			environment: ["PATH": root.appending(path: "dotfiles/scripts/bin").path],
		)
	}

	func makeCandidate(named name: String) throws -> URL {
		let candidates = root.appending(path: "candidates", directoryHint: .isDirectory)
		try FileManager.default.createDirectory(at: candidates, withIntermediateDirectories: true)
		let candidate = candidates.appending(path: name)
		guard FileManager.default.createFile(
			atPath: candidate.path,
			contents: Data(name.utf8),
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
