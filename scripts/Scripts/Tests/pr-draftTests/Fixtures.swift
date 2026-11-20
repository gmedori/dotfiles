import CommandKit
import Foundation
import System

/// A throwaway vault in the temp folder, deleted when the fixture goes away.
final class TemporaryVault {
	let root: URL

	init() throws {
		self.root = FileManager.default
			.temporaryDirectory
			.appending(path: "pr-draft-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
			.resolvingSymlinksInPath()
		try FileManager.default.createDirectory(
			at: root.appending(path: ".obsidian"),
			withIntermediateDirectories: true,
		)
	}

	deinit {
		// Ignoring the error here leaves the vault in the temp folder, which doesn't change any result.
		try? FileManager.default.removeItem(at: root)
	}

	/// Writes a file at `path` from the vault root, creating its folders. A file's contents default to
	/// its path, so copies can be told apart.
	@discardableResult
	func write(_ path: String, _ contents: String? = nil) throws -> URL {
		let url = root.appending(path: path)
		try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
		try (contents ?? path).write(to: url, atomically: true, encoding: .utf8)
		return url
	}

	func read(_ url: URL) throws -> String {
		try String(contentsOf: url, encoding: .utf8)
	}
}

extension URL {
	/// The path without a trailing slash or the `/private` that `pwd -P` puts in front of temp
	/// folders. It works on folders that no longer exist, which `resolvingSymlinksInPath()` leaves
	/// alone.
	var normalizedPath: String {
		var path = standardizedFileURL.path(percentEncoded: false)
		if path.hasPrefix("/private/") {
			path.removeFirst("/private".count)
		}
		return path.count > 1 && path.hasSuffix("/") ? String(path.dropLast()) : path
	}
}

/// A stand-in for `gh` that records each call and acts on the pull request body in its folder.
///
/// `gh pr create` and `gh pr edit` copy the `--body-file` to the folder's `pr-body`, replace each
/// attached file's staged path with an upload URL, and print a pull request URL for `create`.
/// Listing a staged path in `fail-create` or `fail-edit` makes that upload fail, and a `no-pr` file
/// makes `create` fail outright. `gh pr view` prints `pr-body`.
struct FakeGitHubCLI {
	static let url = "https://github.com/gmedori/example/pull/7"
	static let script = """
		#!/bin/sh
		dir="$(dirname "$0")"
		pwd -P >> "$dir/pwd"
		for arg in "$@"; do printf '%s\\n' "$arg" >> "$dir/args"; done
		printf -- '--\\n' >> "$dir/args"
		command="$1 $2"
		subcommand="$2"
		if [ "$command" = "pr view" ]; then cat "$dir/pr-body"; exit 0; fi
		if [ "$command" = "pr create" ] && [ "$3" = "--help" ]; then echo "      --attach file   Attach an image or video file"; exit 0; fi
		if [ "$command" = "pr create" ] && [ -f "$dir/no-pr" ]; then echo "a pull request for branch already exists" >&2; exit 1; fi
		body=""
		attach=""
		while [ $# -gt 0 ]; do
			case "$1" in
				--body-file) body="$2"; shift ;;
				--attach) attach="$attach ${2%%#*}"; shift ;;
			esac
			shift
		done
		cp "$body" "$dir/pr-body"
		status=0
		for file in $attach; do
			if grep -qxF "$file" "$dir/fail-$subcommand" 2>/dev/null; then status=1; continue; fi
			sed -i '' "s|($file)|(https://github.com/user-attachments/assets/${file#./})|g" "$dir/pr-body"
		done
		if [ "$command" = "pr create" ]; then echo "\(FakeGitHubCLI.url)"; fi
		exit $status
		"""

	let directory: URL

	var cli: GitHubCLI {
		GitHubCLI(executable: .path(FilePath(directory.appending(path: "gh").path(percentEncoded: false))))
	}

	init() throws {
		self.directory = FileManager.default
			.temporaryDirectory
			.appending(path: "pr-draft-fake-gh-\(UUID().uuidString)", directoryHint: .isDirectory)
			.resolvingSymlinksInPath()
		try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
		let script = directory.appending(path: "gh")
		try Self.script.write(to: script, atomically: true, encoding: .utf8)
		try FileManager.default.setAttributes(
			[.posixPermissions: 0o755],
			ofItemAtPath: script.path(percentEncoded: false),
		)
	}

	/// Makes the staged paths fail to upload in `gh pr create` or `gh pr edit`.
	func fail(_ staged: [String], in subcommand: String) throws {
		try staged.joined(separator: "\n")
			.appending("\n")
			.write(to: directory.appending(path: "fail-\(subcommand)"), atomically: true, encoding: .utf8)
	}

	func failToOpen() throws {
		try "".write(to: directory.appending(path: "no-pr"), atomically: true, encoding: .utf8)
	}

	/// The arguments of each call, in order.
	func calls() throws -> [[String]] {
		let text = try String(contentsOf: directory.appending(path: "args"), encoding: .utf8)
		var calls: [[String]] = []
		var current: [String] = []
		for line in text.split(separator: "\n", omittingEmptySubsequences: false).dropLast() {
			if line == "--" {
				calls.append(current)
				current = []
			} else {
				current.append(String(line))
			}
		}
		return calls
	}

	/// The folder each call ran in, in order.
	func workingDirectories() throws -> [String] {
		try String(contentsOf: directory.appending(path: "pwd"), encoding: .utf8)
			.split(separator: "\n")
			.map(String.init)
	}

	func pullRequestBody() throws -> String {
		try String(contentsOf: directory.appending(path: "pr-body"), encoding: .utf8)
	}
}
