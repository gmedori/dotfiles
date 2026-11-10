import CommandKit
import Foundation
import System

// MARK: - Version Probe

enum TshVersionProbe {
	static func installation(at url: URL, source: TshSource) async -> TshInstallation? {
		guard case .completed(let result) = await runVersion(at: url),
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
			source: source
		)
	}

	// MARK: - Process Execution

	private static func runVersion(at url: URL) async -> ProbeOutcome {
		await withTaskGroup(of: ProbeOutcome.self) { group in
			group.addTask {
				do {
					let isolatedHomeURL = FileManager.default.temporaryDirectory
						.appending(path: "tp-tsh-version-\(UUID().uuidString)")
					let result = try await Subprocess.run(
						.path(FilePath(url.path)),
						arguments: ["version"],
						environment: .inherit.updating([
							"TELEPORT_TOOLS_VERSION": "off",
							"TELEPORT_HOME": isolatedHomeURL.path,
						]),
						output: .string(limit: 4096),
						error: .string(limit: 4096)
					)
					return .completed(
						ProbeOutput(
							succeeded: result.terminationStatus.isSuccess,
							standardOutput: result.standardOutput?
								.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
							standardError: result.standardError?
								.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
						)
					)
				} catch {
					return .unavailable
				}
			}

			group.addTask {
				do {
					try await Task.sleep(for: .seconds(5))
				} catch {
					return .unavailable
				}
				return .unavailable
			}

			let outcome = await group.next() ?? .unavailable
			group.cancelAll()
			return outcome
		}
	}
}

// MARK: - Probe Results

private struct ProbeOutput: Sendable {
	let succeeded: Bool
	let standardOutput: String
	let standardError: String
}

private enum ProbeOutcome: Sendable {
	case completed(ProbeOutput)
	case unavailable
}
