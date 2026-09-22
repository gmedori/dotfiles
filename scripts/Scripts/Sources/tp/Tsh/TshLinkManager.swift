import CommandKit
import Darwin
import Foundation

// MARK: - Link State

enum TshLinkState: Equatable {
	case missing
	case occupied
	case broken(URL)
	case linked(URL)

	var targetURL: URL? {
		switch self {
			case .broken(let targetURL), .linked(let targetURL):
				return targetURL
			case .missing, .occupied:
				return nil
		}
	}
}

// MARK: - Link Manager

struct TshLinkManager {
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

	var linkURL: URL {
		homeDirectory.appending(path: "scripts/bin/tsh")
	}

	// MARK: - State

	func state() -> TshLinkState {
		let destination: String
		do {
			destination = try fileManager.destinationOfSymbolicLink(atPath: linkURL.path)
		} catch {
			return fileManager.fileExists(atPath: linkURL.path) ? .occupied : .missing
		}

		let targetURL = URL(
			fileURLWithPath: destination,
			relativeTo: linkURL.deletingLastPathComponent()
		).standardizedFileURL

		return fileManager.fileExists(atPath: targetURL.path)
			? .linked(targetURL)
			: .broken(targetURL)
	}

	// MARK: - Mutation

	@discardableResult
	func link(to targetURL: URL) throws -> Bool {
		let targetURL = targetURL.resolvingSymlinksInPath().standardizedFileURL
		guard targetURL.path != linkURL.path else {
			throw RuntimeError("Cannot link ~/scripts/bin/tsh to itself.")
		}

		switch state() {
			case .occupied:
				throw RuntimeError(
					"~/scripts/bin/tsh exists but is not a symbolic link; refusing to replace it."
				)
			case .linked(let currentTargetURL)
				where currentTargetURL.resolvingSymlinksInPath().path == targetURL.path:
				return false
			case .missing, .broken, .linked:
				break
		}

		try fileManager.createDirectory(
			at: linkURL.deletingLastPathComponent(),
			withIntermediateDirectories: true
		)

		let temporaryLinkURL = linkURL.deletingLastPathComponent()
			.appending(path: ".tsh.\(UUID().uuidString).tmp")
		try fileManager.createSymbolicLink(
			at: temporaryLinkURL,
			withDestinationURL: targetURL
		)
		defer {
			try? fileManager.removeItem(at: temporaryLinkURL)
		}

		guard rename(temporaryLinkURL.path, linkURL.path) == 0 else {
			throw RuntimeError(
				"Could not update ~/scripts/bin/tsh: \(String(cString: strerror(errno)))"
			)
		}

		return true
	}

	@discardableResult
	func unlink() throws -> Bool {
		switch state() {
			case .missing:
				return false
			case .occupied:
				throw RuntimeError(
					"~/scripts/bin/tsh exists but is not a symbolic link; refusing to remove it."
				)
			case .broken, .linked:
				try fileManager.removeItem(at: linkURL)
				return true
		}
	}

	// MARK: - PATH Validation

	func pathWarning() -> String? {
		guard case .linked = state() else {
			return nil
		}

		guard let path = environment["PATH"] else {
			return "~/scripts/bin is not in PATH."
		}

		let workingDirectory = URL(
			fileURLWithPath: fileManager.currentDirectoryPath,
			isDirectory: true
		)
		for component in path.split(separator: ":", omittingEmptySubsequences: false) {
			let directory = component.isEmpty
				? workingDirectory
				: URL(fileURLWithPath: String(component), isDirectory: true)
			let candidateURL = directory.appending(path: "tsh").standardizedFileURL
			guard fileManager.isExecutableFile(atPath: candidateURL.path) else {
				continue
			}

			if candidateURL.path == linkURL.path {
				return nil
			}
			return TshPathFormatter.display(candidateURL)
				+ " appears before ~/scripts/bin/tsh in PATH."
		}

		return "~/scripts/bin is not in PATH."
	}
}
