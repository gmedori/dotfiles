import ArgumentParser
import CommandKit
import Foundation
import System

@main
struct GitHubPermalink: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "github-permalink",
		abstract: "Create a GitHub permalink for a file and line selection",
	)

	@Argument(help: "Root of the local Git repository containing the file")
	var repositoryRoot: String

	@Argument(help: "Absolute file path, or a path relative to the repository root")
	var filePath: String

	@Argument(help: "First selected line (1-based)")
	var startLine: Int

	@Argument(help: "Last selected line (1-based); defaults to the first line")
	var endLine: Int?

	func validate() throws {
		guard startLine > 0 else {
			throw ValidationError("The start line must be greater than zero.")
		}

		if let endLine, endLine < startLine {
			throw ValidationError("The end line must not be before the start line.")
		}
	}

	func run() async throws {
		let (repositoryURL, relativePath) = try resolvePaths()
		let lastLine = endLine ?? startLine
		let lineSelection = startLine == lastLine
			? "\(startLine)"
			: "\(startLine)-\(lastLine)"
		let location = "\(relativePath):\(lineSelection)"

		let result: ExecutionResult<
			Void,
			StringOutput<Unicode.UTF8>,
			StringOutput<Unicode.UTF8>,
		>
		do {
			result = try await Subprocess.run(
				.name("gh"),
				arguments: ["browse", "--commit", "--no-browser", "--", location],
				workingDirectory: FilePath(repositoryURL.path),
				output: .string(limit: 64 * 1024),
				error: .string(limit: 64 * 1024),
			)
		} catch {
			throw RuntimeError(
				"Could not run gh. Make sure GitHub CLI is installed and available in PATH: \(error)",
			)
		}

		guard result.terminationStatus.isSuccess else {
			let error = result.standardError?
				.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
			throw RuntimeError(error.isEmpty ? "gh browse failed." : error)
		}

		let permalink = result.standardOutput?
			.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
		guard !permalink.isEmpty else {
			throw RuntimeError("gh browse did not return a permalink.")
		}

		print(permalink)
	}

	private func resolvePaths() throws -> (repository: URL, relativePath: String) {
		let fileManager = FileManager.default
		let workingDirectory = URL(
			fileURLWithPath: fileManager.currentDirectoryPath,
			isDirectory: true,
		)
		let repositoryURL = URL(
			fileURLWithPath: repositoryRoot,
			relativeTo: workingDirectory,
		)
		.standardizedFileURL
		.resolvingSymlinksInPath()

		var repositoryIsDirectory: ObjCBool = false
		guard
			fileManager.fileExists(
				atPath: repositoryURL.path,
				isDirectory: &repositoryIsDirectory,
			),
			repositoryIsDirectory.boolValue
		else {
			throw ValidationError(
				"Repository root is not a directory: \(repositoryURL.path)",
			)
		}

		let fileURL: URL = if filePath.hasPrefix("/") {
			URL(fileURLWithPath: filePath)
		} else {
			repositoryURL.appendingPathComponent(filePath)
		}

		let resolvedFileURL = fileURL
			.standardizedFileURL
			.resolvingSymlinksInPath()
		var fileIsDirectory: ObjCBool = false
		guard
			fileManager.fileExists(
				atPath: resolvedFileURL.path,
				isDirectory: &fileIsDirectory,
			),
			!fileIsDirectory.boolValue
		else {
			throw ValidationError("File does not exist: \(resolvedFileURL.path)")
		}

		let repositoryPrefix = repositoryURL.path + "/"
		guard resolvedFileURL.path.hasPrefix(repositoryPrefix) else {
			throw ValidationError(
				"File is outside the repository root: \(resolvedFileURL.path)",
			)
		}

		let relativePath = String(
			resolvedFileURL.path.dropFirst(repositoryPrefix.count),
		)
		return (repositoryURL, relativePath)
	}
}
