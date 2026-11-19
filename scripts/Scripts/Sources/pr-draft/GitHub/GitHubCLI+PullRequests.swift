import CommandKit

// MARK: - GitHub CLI + Pull Requests

extension GitHubCLI {
	/// Whether this `gh` can upload files with `--attach`. It's `false` when `gh` can't be run.
	func supportsAttach() async -> Bool {
		guard let output = try? await run(["pr", "create", "--help"]) else {
			return false
		}
		return (output.standardOutput + output.standardError).contains("--attach")
	}
}
