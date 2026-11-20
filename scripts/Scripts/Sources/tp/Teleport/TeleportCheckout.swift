import ArgumentParser
import Foundation

/// A Teleport checkout with the enterprise submodule that holds the Cloud deploy script.
struct TeleportCheckout {
	/// The checkout's root folder, with symbolic links resolved.
	let rootDirectory: URL

	/// The enterprise submodule, `e`.
	var enterpriseDirectory: URL {
		rootDirectory.appending(path: "e", directoryHint: .isDirectory)
	}

	/// Finds the checkout at `path`, which can be relative to the working directory or start with `~`.
	/// Throws when the folder doesn't have the Makefile and the enterprise deploy script.
	init(path: String, fileManager: FileManager = .default) throws {
		let expandedPath = path.expandingTilde(homeDirectory: fileManager.homeDirectoryForCurrentUser)
		let workingDirectory = URL(
			fileURLWithPath: fileManager.currentDirectoryPath,
			isDirectory: true,
		)
		self.rootDirectory = URL(
			fileURLWithPath: expandedPath,
			relativeTo: workingDirectory,
		)
		.standardizedFileURL
		.resolvingSymlinksInPath()

		var isDirectory: ObjCBool = false
		guard
			fileManager.fileExists(atPath: rootDirectory.path, isDirectory: &isDirectory),
			isDirectory.boolValue
		else {
			throw ValidationError(
				"Teleport checkout is not a directory: \(rootDirectory.path)"
			)
		}

		let makefile = rootDirectory.appending(path: "Makefile")
		let deployScript = enterpriseDirectory.appending(path: "scripts/deploy-cloud.sh")
		guard
			fileManager.fileExists(atPath: makefile.path),
			fileManager.fileExists(atPath: deployScript.path)
		else {
			throw ValidationError(
				"Directory does not look like a Teleport checkout: \(rootDirectory.path)"
			)
		}
	}
}
