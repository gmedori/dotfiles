import CommandKit
import Darwin
import Foundation

/// The symbolic link at `~/dotfiles/scripts/bin/tsh` that selects which `tsh` runs.
struct ManagedTshLink {
	/// The file manager that reads and changes the link.
	let fileManager: FileManager
	/// The home folder that holds `dotfiles`. Tests swap in a temporary folder.
	let homeDirectory: URL
	/// The environment whose `PATH` `pathWarning()` checks.
	let environment: [String: String]

	/// The link's location.
	var linkURL: URL {
		homeDirectory.appending(path: "dotfiles/scripts/bin/tsh")
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

	/// Whether the link exists and where it points.
	func state() -> State {
		let destination: String
		do {
			destination = try fileManager.destinationOfSymbolicLink(atPath: linkURL.path)
		} catch {
			return fileManager.fileExists(atPath: linkURL.path) ? .occupied : .missing
		}

		let targetURL = URL(
			fileURLWithPath: destination,
			relativeTo: linkURL.deletingLastPathComponent(),
		).standardizedFileURL

		return fileManager.fileExists(atPath: targetURL.path)
			? .linked(targetURL)
			: .broken(targetURL)
	}

	/// Points the link at `targetURL`, replacing it atomically. Returns `false` when it already
	/// pointed there. Throws instead of replacing a file that isn't a symbolic link.
	@discardableResult
	func link(to targetURL: URL) throws -> Bool {
		let targetURL = targetURL.resolvingSymlinksInPath().standardizedFileURL
		guard targetURL.path != linkURL.path else {
			throw RuntimeError("Cannot link ~/dotfiles/scripts/bin/tsh to itself.")
		}

		switch state() {
			case .occupied:
				throw RuntimeError(
					"~/dotfiles/scripts/bin/tsh exists but is not a symbolic link; refusing to replace it."
				)
			case let .linked(currentTargetURL)
			where currentTargetURL.resolvingSymlinksInPath().path == targetURL.path:
				return false
			case .missing, .broken, .linked:
				break
		}

		try fileManager.createDirectory(
			at: linkURL.deletingLastPathComponent(),
			withIntermediateDirectories: true,
		)

		let temporaryLinkURL = linkURL.deletingLastPathComponent()
			.appending(path: ".tsh.\(UUID().uuidString).tmp")
		try fileManager.createSymbolicLink(
			at: temporaryLinkURL,
			withDestinationURL: targetURL,
		)
		defer {
			// Ignoring the error here is what lets a successful `rename` through, since it has already
			// moved the temporary link away. After a failed one, a stray temporary link is harmless.
			try? fileManager.removeItem(at: temporaryLinkURL)
		}

		guard rename(temporaryLinkURL.path, linkURL.path) == 0 else {
			throw RuntimeError(
				"Could not update ~/dotfiles/scripts/bin/tsh: \(String(cString: strerror(errno)))"
			)
		}

		return true
	}

	/// Removes the link. Returns `false` when there was none. Throws instead of removing a file that
	/// isn't a symbolic link.
	@discardableResult
	func unlink() throws -> Bool {
		switch state() {
			case .missing:
				return false
			case .occupied:
				throw RuntimeError(
					"~/dotfiles/scripts/bin/tsh exists but is not a symbolic link; refusing to remove it."
				)
			case .broken, .linked:
				try fileManager.removeItem(at: linkURL)
				return true
		}
	}

	/// A warning when the linked `tsh` isn't the one `PATH` finds first, or `nil` when it is or
	/// nothing is linked.
	func pathWarning() -> String? {
		guard case .linked = state() else {
			return nil
		}
		guard let path = environment["PATH"] else {
			return "~/dotfiles/scripts/bin is not in PATH."
		}

		let workingDirectory = URL(
			fileURLWithPath: fileManager.currentDirectoryPath,
			isDirectory: true,
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
				+ " appears before ~/dotfiles/scripts/bin/tsh in PATH."
		}

		return "~/dotfiles/scripts/bin is not in PATH."
	}
}

// MARK: - Supporting Types

extension ManagedTshLink {
	/// What's at the link's location.
	enum State: Equatable {
		/// Nothing.
		case missing
		/// A file or folder that isn't a symbolic link, which `tp` never replaces.
		case occupied
		/// A symbolic link to something that doesn't exist.
		case broken(URL)
		/// A symbolic link to an existing file.
		case linked(URL)

		/// Where the link points, or `nil` when there's no link.
		var targetURL: URL? {
			switch self {
				case let .broken(targetURL), let .linked(targetURL):
					targetURL
				case .missing, .occupied:
					nil
			}
		}
	}
}
