import ArgumentParser
import CommandKit
import Foundation

/// Finds the `tsh` binaries on this Mac.
struct TshDiscovery {
	/// The file manager that reads the folders `tsh` is installed in.
	let fileManager: FileManager
	/// The home folder, which holds `Applications`, `.tsh`, and `code`.
	let homeDirectory: URL
	/// The environment, for `PATH` and `TELEPORT_HOME`.
	let environment: [String: String]

	private var workingDirectoryURL: URL {
		URL(
			fileURLWithPath: fileManager.currentDirectoryPath,
			isDirectory: true,
		)
	}

	init(
		fileManager: FileManager = .default,
		homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
		environment: [String: String] = ProcessInfo.processInfo.environment,
	) {
		self.fileManager = fileManager
		self.homeDirectory = homeDirectory.standardizedFileURL
		self.environment = environment
	}

	/// Every installation found, newest version first. A binary found in more than one place is listed
	/// once, with the source of the first place that found it.
	@concurrent
	func discover() async -> [TshInstallation] {
		let candidates = await candidates()
		let installations = await withTaskGroup(of: TshInstallation?.self) { group in
			for candidate in candidates {
				group.addTask {
					await TshVersionProbe.installation(
						at: candidate.url,
						source: candidate.source,
					)
				}
			}

			var installations: [TshInstallation] = []
			for await installation in group {
				if let installation {
					installations.append(installation)
				}
			}
			return installations
		}

		return installations.sorted(by: Self.sortInstallations)
	}

	/// The installation at `suppliedPath`, which can start with `~`. Throws when it isn't a `tsh`
	/// binary that reports a Teleport version.
	@concurrent
	func installation(at suppliedPath: String) async throws -> TshInstallation {
		let suppliedURL = url(for: suppliedPath)
		let managedLinkURL = homeDirectory
			.appending(path: "dotfiles/scripts/bin/tsh")
			.standardizedFileURL

		guard suppliedURL != managedLinkURL else {
			throw ValidationError("Select the tsh executable itself, not ~/dotfiles/scripts/bin/tsh.")
		}
		guard let candidate = candidate(at: suppliedURL, suggestedSource: .other) else {
			throw ValidationError(
				"No executable, non-symlinked tsh binary found at \(suppliedURL.path)."
			)
		}
		guard let installation = await TshVersionProbe.installation(
			at: candidate.url,
			source: candidate.source,
		) else {
			throw ValidationError(
				"Could not determine a Teleport version by running '\(candidate.url.path) version'."
			)
		}

		return installation
	}
}

// MARK: - Supporting Types

extension TshDiscovery {
	/// A binary that looks like `tsh`, before it's run for its version.
	struct Candidate: Sendable {
		/// The binary, with symbolic links resolved.
		var url: URL
		/// Where the binary came from.
		var source: TshSource
	}
}

// MARK: - Private Helpers

extension TshDiscovery {
	private static func sortInstallations(
		_ lhs: TshInstallation,
		_ rhs: TshInstallation,
	) -> Bool {
		let comparison = lhs.version.compare(rhs.version, options: .numeric)
		if comparison != .orderedSame {
			return comparison == .orderedDescending
		}
		if lhs.source != rhs.source {
			return lhs.source.rawValue < rhs.source.rawValue
		}
		return lhs.url.path < rhs.url.path
	}

	// MARK: Candidate Collection

	private func candidates() async -> [Candidate] {
		let urlsBySource: [(urls: [URL], source: TshSource)] = await [
			(applicationURLs(), .standalone),
			(managedToolsDirectoryURLs().flatMap(recursivelyNamedTshURLs(in:)), .managed),
			(homebrewURLs(), .homebrew),
			(pathEnvironmentURLs(), .other),
			(sourceBuildURLs(), .source),
		]

		var candidatesByURL: [URL: Candidate] = [:]
		for (urls, source) in urlsBySource {
			for url in urls {
				guard let candidate = candidate(at: url, suggestedSource: source) else {
					continue
				}

				if candidatesByURL[candidate.url] == nil {
					candidatesByURL[candidate.url] = candidate
				}
			}
		}

		return Array(candidatesByURL.values)
	}

	// MARK: Candidate Sources

	private func applicationURLs() -> [URL] {
		let applicationDirectoryURLs = [
			URL(fileURLWithPath: "/Applications", isDirectory: true),
			homeDirectory.appending(path: "Applications", directoryHint: .isDirectory),
		]

		return applicationDirectoryURLs.flatMap { directoryURL in
			[
				directoryURL.appending(path: "tsh.app/Contents/MacOS/tsh"),
				directoryURL.appending(
					path: "Teleport Connect.app/Contents/MacOS/tsh.app/Contents/MacOS/tsh"
				),
			]
		}
	}

	private func managedToolsDirectoryURLs() -> [URL] {
		var directoryURLs = [homeDirectory.appending(path: ".tsh/bin")]
		if let configuredHome = environment["TELEPORT_HOME"], !configuredHome.isEmpty {
			let toolsDirectoryURL = url(for: configuredHome).appending(path: "bin")
			if !directoryURLs.contains(toolsDirectoryURL) {
				directoryURLs.append(toolsDirectoryURL)
			}
		}
		return directoryURLs
	}

	private func homebrewURLs() -> [URL] {
		let cellarURLs = [
			URL(fileURLWithPath: "/opt/homebrew/Cellar/teleport", isDirectory: true),
			URL(fileURLWithPath: "/usr/local/Cellar/teleport", isDirectory: true),
		]

		return cellarURLs.flatMap { cellarURL -> [URL] in
			// Ignoring the error here means a Cellar folder that doesn't exist adds no candidates.
			guard let versionDirectoryURLs = try? fileManager.contentsOfDirectory(
				at: cellarURL,
				includingPropertiesForKeys: [.isDirectoryKey],
				options: [.skipsHiddenFiles],
			) else {
				return []
			}

			return versionDirectoryURLs.map { $0.appending(path: "bin/tsh") }
		}
	}

	private func pathEnvironmentURLs() -> [URL] {
		var urls = [
			URL(fileURLWithPath: "/usr/local/bin/tsh"),
			URL(fileURLWithPath: "/opt/homebrew/bin/tsh"),
		]

		for component in (environment["PATH"] ?? "")
			.split(separator: ":", omittingEmptySubsequences: false)
		{
			let directoryURL = component.isEmpty
				? workingDirectoryURL
				: URL(fileURLWithPath: String(component), isDirectory: true)
			urls.append(directoryURL.appending(path: "tsh"))
		}

		return urls
	}

	private func recursivelyNamedTshURLs(in rootURL: URL) -> [URL] {
		guard let enumerator = fileManager.enumerator(
			at: rootURL,
			includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey],
			options: [.skipsHiddenFiles],
		) else {
			return []
		}

		return enumerator.compactMap { element in
			guard let url = element as? URL, url.lastPathComponent == "tsh" else {
				return nil
			}

			return url
		}
	}

	private func sourceBuildURLs() async -> [URL] {
		let codeDirectoryURL = homeDirectory.appending(
			path: "code",
			directoryHint: .isDirectory,
		)
		var isDirectory: ObjCBool = false
		guard
			fileManager.fileExists(atPath: codeDirectoryURL.path, isDirectory: &isDirectory),
			isDirectory.boolValue
		else {
			return []
		}

		// Source build output is normally ignored by Git. --no-ignore includes it,
		// while ripgrep's default hidden-file behavior avoids metadata such as .git.
		do {
			let result = try await Subprocess.run(
				.name("rg"),
				arguments: [
					"--files",
					"--no-ignore",
					"--glob", "tsh",
					codeDirectoryURL.path,
				],
				output: .string(limit: 1024 * 1024),
				error: .discarded,
			)
			guard result.terminationStatus.isSuccess else {
				return []
			}

			return (result.standardOutput ?? "")
				.split(whereSeparator: \.isNewline)
				.map { URL(fileURLWithPath: String($0)) }
		} catch {
			// Ignoring the error here means a Mac without ripgrep finds no source builds.
			return []
		}
	}

	// MARK: Candidate Validation

	private func candidate(at url: URL, suggestedSource: TshSource) -> Candidate? {
		let managedLinkURL = homeDirectory
			.appending(path: "dotfiles/scripts/bin/tsh")
			.standardizedFileURL
		let suppliedURL = url.standardizedFileURL
		guard suppliedURL != managedLinkURL else {
			return nil
		}

		let resolvedURL = suppliedURL.resolvingSymlinksInPath().standardizedFileURL
		guard
			resolvedURL != managedLinkURL,
			fileManager.isExecutableFile(atPath: resolvedURL.path),
			isRegularFile(resolvedURL),
			isMachOBinary(resolvedURL)
		else {
			return nil
		}

		return Candidate(
			url: resolvedURL,
			source: source(for: resolvedURL, fallback: suggestedSource),
		)
	}

	private func isRegularFile(_ url: URL) -> Bool {
		// Ignoring the error here means a file whose type can't be read isn't a candidate.
		guard let values = try? url.resourceValues(forKeys: [
			.isRegularFileKey,
			.isSymbolicLinkKey,
		]) else {
			return false
		}

		return values.isRegularFile == true && values.isSymbolicLink != true
	}

	private func isMachOBinary(_ url: URL) -> Bool {
		// Ignoring these errors means a file that can't be opened or read isn't a candidate. Closing a
		// handle that was only read from can't lose anything.
		guard let handle = try? FileHandle(forReadingFrom: url) else {
			return false
		}

		defer { try? handle.close() }

		guard let data = try? handle.read(upToCount: 4), data.count == 4 else {
			return false
		}

		let magic = data.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
		return [
			0xFEED_FACE, 0xCEFA_EDFE,
			0xFEED_FACF, 0xCFFA_EDFE,
			0xCAFE_BABE, 0xBEBA_FECA,
			0xCAFE_BABF, 0xBFBA_FECA,
		].contains(magic)
	}

	// MARK: Source Classification

	private func source(for url: URL, fallback: TshSource) -> TshSource {
		let path = url.path
		let homePath = homeDirectory.path
		let managedDirectoryPaths = managedToolsDirectoryURLs().map { $0.standardizedFileURL.path + "/" }
		if managedDirectoryPaths.contains(where: { path.hasPrefix($0) }) {
			return .managed
		}
		if path.contains("/Teleport Connect.app/") {
			return .connect
		}
		if path.contains("/tsh.app/") {
			return .standalone
		}
		if path.contains("/Cellar/teleport/") {
			return .homebrew
		}
		if path.hasPrefix(homePath + "/code/") {
			return .source
		}
		return fallback
	}

	private func url(for path: String) -> URL {
		URL(
			fileURLWithPath: path.expandingTilde(homeDirectory: homeDirectory),
			relativeTo: workingDirectoryURL,
		).standardizedFileURL
	}
}
