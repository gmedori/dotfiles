import CommandKit
import Foundation
import System

/// Runs `tsh version` to learn which Teleport version a `tsh` binary is.
enum TshVersionProbe {
	/// How many seconds `tsh version` gets before the probe gives up on it.
	static let timeoutInSeconds = 5

	/// The installation at `url`, or `nil` when the binary doesn't run, doesn't finish in time, or
	/// doesn't report a Teleport version.
	static func installation(at url: URL, source: TshSource) async -> TshInstallation? {
		guard
			case let .completed(result) = await runVersion(at: url),
			result.succeeded
		else {
			return nil
		}

		let output = [result.standardOutput, result.standardError]
			.filter { !$0.isEmpty }
			.joined(separator: "\n")
		guard let version = TshVersionParser.version(from: output) else {
			return nil
		}

		return TshInstallation(
			version: version,
			versionOutput: output,
			url: url,
			source: source,
		)
	}
}

// MARK: - Supporting Types

extension TshVersionProbe {
	/// What `tsh version` printed, and whether it exited successfully.
	struct Output: Sendable {
		/// Whether `tsh version` exited with status 0.
		var succeeded: Bool
		/// What it printed to standard output, trimmed.
		var standardOutput: String
		/// What it printed to standard error, trimmed.
		var standardError: String
	}

	/// How running `tsh version` ended.
	enum Outcome: Sendable {
		/// It finished, with what it printed.
		case completed(Output)
		/// It couldn't run, or didn't finish in time.
		case unavailable
	}
}

// MARK: - Private Helpers

extension TshVersionProbe {
	private static func runVersion(at url: URL) async -> Outcome {
		await withTaskGroup(of: Outcome.self) { group in
			group.addTask {
				do {
					let isolatedHomeURL = FileManager.default
						.temporaryDirectory
						.appending(path: "tp-tsh-version-\(UUID().uuidString)")
					let result = try await Subprocess.run(
						.path(FilePath(url.path)),
						arguments: ["version"],
						environment: .inherit.updating([
							"TELEPORT_TOOLS_VERSION": "off",
							"TELEPORT_HOME": isolatedHomeURL.path,
						]),
						output: .string(limit: 4096),
						error: .string(limit: 4096),
					)
					return .completed(
						Output(
							succeeded: result.terminationStatus.isSuccess,
							standardOutput: result.standardOutput?
								.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
							standardError: result.standardError?
								.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
						)
					)
				} catch {
					// Ignoring the error here means a binary that can't run isn't listed as an installation.
					return .unavailable
				}
			}

			group.addTask {
				// Ignoring the error here is safe, since this task only marks the timeout, and canceling it
				// once the other task finishes makes no difference to the outcome.
				try? await Task.sleep(for: .seconds(timeoutInSeconds))
				return .unavailable
			}

			let outcome = await group.next() ?? .unavailable
			group.cancelAll()
			return outcome
		}
	}
}
