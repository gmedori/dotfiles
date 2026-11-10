import ArgumentParser
import Foundation

struct TeleportCheckout {
	let rootDirectory: URL

	var enterpriseDirectory: URL {
		rootDirectory.appending(path: "e", directoryHint: .isDirectory)
	}

	init(path: String, fileManager: FileManager = .default) throws {
		let expandedPath = (path as NSString).expandingTildeInPath
		let workingDirectory = URL(
			fileURLWithPath: fileManager.currentDirectoryPath,
			isDirectory: true
		)
		rootDirectory = URL(
			fileURLWithPath: expandedPath,
			relativeTo: workingDirectory
		)
		.standardizedFileURL
		.resolvingSymlinksInPath()

		var isDirectory: ObjCBool = false
		guard fileManager.fileExists(
			atPath: rootDirectory.path,
			isDirectory: &isDirectory
		), isDirectory.boolValue else {
			throw ValidationError(
				"Teleport checkout is not a directory: \(rootDirectory.path)"
			)
		}

		let makefile = rootDirectory.appending(path: "Makefile")
		let deployScript = enterpriseDirectory.appending(path: "scripts/deploy-cloud.sh")
		guard fileManager.fileExists(atPath: makefile.path),
			fileManager.fileExists(atPath: deployScript.path)
		else {
			throw ValidationError(
				"Directory does not look like a Teleport checkout: \(rootDirectory.path)"
			)
		}
	}
}
