import ArgumentParser
import CommandKit
import Foundation
import System

@main
struct IsWorkMac: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "is-work-mac",
		abstract: "Exit 0 on the work Mac and 1 on any other Mac",
		discussion: """
			The work Mac is enrolled in MDM by IT, and personal Macs aren't, so this \
			reads the enrollment that `profiles status -type enrollment` reports. It \
			prints nothing when it can tell. When it can't, it prints why and exits 2, \
			so a caller that treats only exit 1 as a personal Mac stays safe when \
			enrollment is unknown.
			""",
	)

	func run() async throws {
		let isEnrolled: Bool
		do {
			isEnrolled = try await MDMEnrollment.isEnrolled()
		} catch {
			FileHandle.standardError.write(Data("is-work-mac: \(error)\n".utf8))
			throw ExitCode(2)
		}

		guard isEnrolled else {
			throw ExitCode.failure
		}
	}
}

// MARK: - Supporting Types

enum MDMEnrollment {
	/// Asks `profiles` whether this Mac is enrolled in MDM.
	static func isEnrolled() async throws -> Bool {
		let result = try await Subprocess.run(
			.path(FilePath("/usr/bin/profiles")),
			arguments: ["status", "-type", "enrollment"],
			output: .string(limit: 16 * 1024),
			error: .string(limit: 16 * 1024),
		)

		guard result.terminationStatus.isSuccess else {
			let error = result.standardError?
				.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
			throw RuntimeError(error.isEmpty ? "profiles status failed." : error)
		}

		guard let isEnrolled = isEnrolled(from: result.standardOutput ?? "") else {
			throw RuntimeError("profiles status didn't report an MDM enrollment.")
		}
		return isEnrolled
	}

	/// Reads the `MDM enrollment:` line of `profiles status -type enrollment`,
	/// whose value is `No`, `Yes`, or `Yes (User Approved)`. Returns `nil` when
	/// the line is missing.
	static func isEnrolled(from output: String) -> Bool? {
		for line in output.split(whereSeparator: \.isNewline) {
			let parts = line.split(separator: ":", maxSplits: 1)
			guard
				parts.count == 2,
				parts[0].trimmingCharacters(in: .whitespaces) == "MDM enrollment"
			else {
				continue
			}

			return parts[1].trimmingCharacters(in: .whitespaces).hasPrefix("Yes")
		}

		return nil
	}
}
