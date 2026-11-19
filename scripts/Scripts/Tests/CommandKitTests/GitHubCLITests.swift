import Foundation
import Testing
@testable import CommandKit

/// Runs `/bin/sh -c` in place of `gh`, so each test scripts what "gh" prints and how it exits.
@Suite("GitHub CLI")
struct GitHubCLITests {
	let shell = GitHubCLI(executable: .path("/bin/sh"))

	@Test("Returns standard output when gh succeeds")
	func returnsOutput() async throws {
		#expect(try await shell.output(["-c", "printf 'https://github.com/o/r/pull/1'"]) == "https://github.com/o/r/pull/1")
	}

	@Test("Throws what gh printed to standard error when it fails")
	func throwsStandardError() async {
		await #expect {
			try await shell.output(["-c", "echo 'no pull requests found' >&2; exit 1"])
		} throws: { error in
			(error as? RuntimeError)?.description == "no pull requests found"
		}
	}

	@Test("Names the command when gh fails without printing anything")
	func namesSilentFailures() async {
		let gh = GitHubCLI(executable: .path("/usr/bin/false"))
		await #expect {
			try await gh.output(["pr", "view", "12", "--json", "body"])
		} throws: { error in
			(error as? RuntimeError)?.description == "gh pr view failed."
		}
		#expect(GitHubCLI.commandName(["browse", "--commit", "--", "file.swift:3"]) == "gh browse")
		#expect(GitHubCLI.commandName(["api", "graphql", "-f", "query=x"]) == "gh api graphql")
		#expect(GitHubCLI.commandName([]) == "gh")
	}

	@Test("Returns both streams without throwing when gh fails")
	func returnsFailedOutput() async throws {
		let output = try await shell.run(["-c", "echo out; echo err >&2; exit 3"])

		#expect(!output.succeeded)
		#expect(output.standardOutput == "out\n")
		#expect(output.standardError == "err\n")
	}

	@Test("Runs gh from the given folder")
	func runsInDirectory() async throws {
		let directory = FileManager.default.temporaryDirectory.appending(path: "commandkit-\(UUID().uuidString)")
		try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
		defer { try? FileManager.default.removeItem(at: directory) }

		let path = try await shell.output(["-c", "pwd -P"], in: directory)

		#expect(path.trimmingCharacters(in: .newlines) == directory.resolvingSymlinksInPath().path(percentEncoded: false).replacing(/^\/var\//, with: "/private/var/").trimmingSuffixSlash)
	}

	@Test("Throws when gh can't be run")
	func throwsWhenMissing() async {
		await #expect {
			try await GitHubCLI(executable: .path("/nonexistent/gh")).run([])
		} throws: { error in
			(error as? RuntimeError)?.description.hasPrefix("Could not run gh.") == true
		}
	}
}

extension String {
	fileprivate var trimmingSuffixSlash: String {
		count > 1 && hasSuffix("/") ? String(dropLast()) : self
	}
}
