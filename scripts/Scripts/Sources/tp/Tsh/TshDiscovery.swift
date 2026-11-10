import ArgumentParser
import CommandKit
import Foundation

// MARK: - Discovery

struct TshDiscovery {
	let fileManager: FileManager
	let homeDirectory: URL
	let environment: [String: String]

	init(
		fileManager: FileManager = .default,
		homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
		environment: [String: String] = ProcessInfo.processInfo.environment
	) {
		self.fileManager = fileManager
		self.homeDirectory = homeDirectory.standardizedFileURL
		self.environment = environment
	}

	// MARK: - Public API

	func discover() async -> [TshInstallation] {
		let candidates = await candidates()
		let installations = await withTaskGroup(of: TshInstallation?.self) { group in
			for candidate in candidates {
				group.addTask {
					await TshVersionProbe.installation(
						at: candidate.url,
						source: candidate.source
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

	func installation(at suppliedPath: String) async throws -> TshInstallation {
		let suppliedURL = url(for: suppliedPath)
		let managedLinkURL = homeDirectory
			.appending(path: "scripts/bin/tsh")
			.standardizedFileURL

		guard suppliedURL != managedLinkURL else {
			throw ValidationError("Select the tsh executable itself, not ~/scripts/bin/tsh.")
		}
		guard let candidate = candidate(at: suppliedURL, suggestedSource: .other) else {
			throw ValidationError(
				"No executable, non-symlinked tsh binary found at \(suppliedURL.path)."
			)
		}
		guard let installation = await TshVersionProbe.installation(
			at: candidate.url,
			source: candidate.source
		) else {
			throw ValidationError(
				"Could not determine a Teleport version by running '\(candidate.url.path) version'."
			)
		}

		return installation
	}

	// MARK: - Candidate Collection

	private func candidates() async -> [TshCandidate] {
		var candidatesByURL: [URL: TshCandidate] = [:]

		func add(_ urls: [URL], source: TshSource) {
			for url in urls {
				guard let candidate = candidate(at: url, suggestedSource: source) else {
					continue
				}
				if candidatesByURL[candidate.url] == nil {
					candidatesByURL[candidate.url] = candidate
				}
			}
		}

		add(applicationURLs(), source: .standalone)
		for directoryURL in managedToolsDirectoryURLs() {
			add(recursivelyNamedTshURLs(in: directoryURL), source: .managed)
		}
		add(homebrewURLs(), source: .homebrew)
		add(pathEnvironmentURLs(), source: .other)
		add(await sourceBuildURLs(), source: .source)

		return Array(candidatesByURL.values)
	}

	// MARK: - Candidate Sources

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
			guard let versionDirectoryURLs = try? fileManager.contentsOfDirectory(
				at: cellarURL,
				includingPropertiesForKeys: [.isDirectoryKey],
				options: [.skipsHiddenFiles]
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
			options: [.skipsHiddenFiles]
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
			directoryHint: .isDirectory
		)
		var isDirectory: ObjCBool = false
		guard fileManager.fileExists(
			atPath: codeDirectoryURL.path,
			isDirectory: &isDirectory
		), isDirectory.boolValue else {
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
				error: .discarded
			)
			guard result.terminationStatus.isSuccess else {
				return []
			}
			return (result.standardOutput ?? "")
				.split(whereSeparator: \.isNewline)
				.map { URL(fileURLWithPath: String($0)) }
		} catch {
			return []
		}
	}

	// MARK: - Candidate Validation

	private func candidate(at url: URL, suggestedSource: TshSource) -> TshCandidate? {
		let managedLinkURL = homeDirectory
			.appending(path: "scripts/bin/tsh")
			.standardizedFileURL
		let suppliedURL = url.standardizedFileURL
		guard suppliedURL != managedLinkURL else {
			return nil
		}

		let resolvedURL = suppliedURL.resolvingSymlinksInPath().standardizedFileURL
		guard resolvedURL != managedLinkURL,
			fileManager.isExecutableFile(atPath: resolvedURL.path),
			isRegularFile(resolvedURL),
			isMachOBinary(resolvedURL)
		else {
			return nil
		}

		return TshCandidate(
			url: resolvedURL,
			source: source(for: resolvedURL, fallback: suggestedSource)
		)
	}

	private func isRegularFile(_ url: URL) -> Bool {
		guard let values = try? url.resourceValues(forKeys: [
			.isRegularFileKey,
			.isSymbolicLinkKey,
		]) else {
			return false
		}
		return values.isRegularFile == true && values.isSymbolicLink != true
	}

	private func isMachOBinary(_ url: URL) -> Bool {
		guard let handle = try? FileHandle(forReadingFrom: url) else {
			return false
		}
		defer { try? handle.close() }

		guard let data = try? handle.read(upToCount: 4), data.count == 4 else {
			return false
		}
		let magic = data.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
		return [
			0xFEEDFACE, 0xCEFAEDFE,
			0xFEEDFACF, 0xCFFAEDFE,
			0xCAFEBABE, 0xBEBAFECA,
			0xCAFEBABF, 0xBFBAFECA,
		].contains(magic)
	}

	// MARK: - Source Classification

	private func source(for url: URL, fallback: TshSource) -> TshSource {
		let path = url.path
		let homePath = homeDirectory.path
		if managedToolsDirectoryURLs().contains(where: {
			path.hasPrefix($0.standardizedFileURL.path + "/")
		}) {
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

	// MARK: - Helpers

	private var workingDirectoryURL: URL {
		URL(
			fileURLWithPath: fileManager.currentDirectoryPath,
			isDirectory: true
		)
	}

	private func url(for path: String) -> URL {
		let expandedPath = (path as NSString).expandingTildeInPath
		return URL(
			fileURLWithPath: expandedPath,
			relativeTo: workingDirectoryURL
		).standardizedFileURL
	}

	private static func sortInstallations(
		_ lhs: TshInstallation,
		_ rhs: TshInstallation
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
}

// MARK: - Discovery Candidate

private struct TshCandidate: Sendable {
	let url: URL
	let source: TshSource
}
