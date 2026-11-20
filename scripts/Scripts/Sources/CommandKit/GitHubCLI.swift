import Foundation
import Subprocess
import System

/// Runs `gh`, the GitHub CLI.
public struct GitHubCLI: Sendable {
	/// The `gh` to run. Tests swap in a stand-in.
	public var executable: Executable

	/// Creates a client for `executable`, which is the `gh` found in `PATH` unless a test passes another.
	public init(executable: Executable = .name("gh")) {
		self.executable = executable
	}

	/// Runs `gh` with `arguments`, from `directory` when it's given, and returns what it printed
	/// whether or not it succeeded. Throws only when `gh` can't be run.
	public func run(_ arguments: [String], in directory: URL? = nil) async throws -> Output {
		let result: ExecutionResult<Void, StringOutput<Unicode.UTF8>, StringOutput<Unicode.UTF8>>
		do {
			result = try await Subprocess.run(
				executable,
				arguments: Arguments(arguments),
				workingDirectory: directory.map { FilePath($0.path(percentEncoded: false)) },
				output: .string(limit: Self.outputLimit),
				error: .string(limit: Self.outputLimit),
			)
		} catch {
			throw RuntimeError("Could not run gh. Make sure GitHub CLI is installed and available in PATH: \(error)")
		}
		return Output(
			succeeded: result.terminationStatus.isSuccess,
			standardOutput: result.standardOutput ?? "",
			standardError: result.standardError ?? "",
		)
	}

	/// Runs `gh` with `arguments`, from `directory` when it's given, and returns its standard output.
	/// When `gh` fails, it throws a `RuntimeError` with what `gh` printed to standard error.
	public func output(_ arguments: [String], in directory: URL? = nil) async throws -> String {
		let output = try await run(arguments, in: directory)
		guard output.succeeded else {
			let error = output.standardError.trimmingCharacters(in: .whitespacesAndNewlines)
			throw RuntimeError(error.isEmpty ? "\(Self.commandName(arguments)) failed." : error)
		}

		return output.standardOutput
	}
}

// MARK: - Supporting Types

extension GitHubCLI {
	/// What `gh` printed, and whether it exited successfully.
	public struct Output: Sendable {
		/// Whether `gh` exited with status 0.
		public var succeeded: Bool
		/// Everything `gh` printed to standard output.
		public var standardOutput: String
		/// Everything `gh` printed to standard error.
		public var standardError: String
	}
}

// MARK: - Static Members

extension GitHubCLI {
	/// The most `gh` can print to each of standard output and standard error.
	public static let outputLimit = 1024 * 1024

	/// The command as `gh` and its first two arguments that aren't options, like `gh pr view`.
	static func commandName(_ arguments: [String]) -> String {
		let words = arguments.prefix { !$0.hasPrefix("-") }.prefix(2)
		return (["gh"] + words).joined(separator: " ")
	}
}
