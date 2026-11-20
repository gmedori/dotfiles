import CommandKit
import Foundation
import System

/// Reads whether this Mac is enrolled in MDM, which is how `is-work-mac` tells the work Mac apart.
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
