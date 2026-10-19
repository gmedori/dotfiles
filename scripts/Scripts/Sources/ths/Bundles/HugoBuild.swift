import CommandKit
import Foundation
import System

// MARK: - Hugo Build

/// Runs the site's production build, the same one the site repo's AGENTS.md requires before a
/// change is done. The build has to finish with no warnings, so any `WARN` or `ERROR` line counts as
/// a failure.
enum HugoBuild {
	static let arguments = ["--gc", "--minify", "--cleanDestinationDir"]

	/// Builds the site. Returns `nil` when the build is clean, or an error message with Hugo's
	/// warnings and errors.
	static func run(in siteDirectory: URL) async -> Message? {
		let command = "hugo " + arguments.joined(separator: " ")
		let result: ExecutionResult<
			Void,
			StringOutput<Unicode.UTF8>,
			StringOutput<Unicode.UTF8>
		>
		do {
			result = try await Subprocess.run(
				.name("hugo"),
				arguments: Arguments(arguments),
				workingDirectory: FilePath(siteDirectory.path(percentEncoded: false)),
				output: .string(limit: 1024 * 1024),
				error: .string(limit: 1024 * 1024),
			)
		} catch {
			return Message(
				kind: .error,
				headline: "Couldn't run \(command): \(error)",
				details: ["Install Hugo's extended edition with `brew install hugo`."],
			)
		}

		let output = (result.standardOutput ?? "") + "\n" + (result.standardError ?? "")
		let problems = output.split(separator: "\n").filter { $0.hasPrefix("WARN") || $0.hasPrefix("ERROR") }
		guard !result.terminationStatus.isSuccess || !problems.isEmpty else {
			return nil
		}

		return Message(
			kind: .error,
			headline: "The production build (\(command)) didn't finish cleanly",
			details: problems.isEmpty ? [output.trimmingCharacters(in: .whitespacesAndNewlines)] : problems.map(String.init),
		)
	}
}
