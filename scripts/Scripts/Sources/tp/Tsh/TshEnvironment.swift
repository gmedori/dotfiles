import CommandKit
import Foundation

/// Checks that Teleport's managed updates are off, since they would override the `tsh` that
/// `tp tsh use` selects.
enum TshEnvironment {
	// MARK: Configuration

	/// The variable that turns managed updates off.
	static let managedUpdatesVariable = "TELEPORT_TOOLS_VERSION"
	/// The value of `managedUpdatesVariable` that turns managed updates off.
	static let managedUpdatesDisabledValue = "off"
	/// The command that turns managed updates off in every `fish` session.
	static let fishConfigurationCommand =
		"echo 'set -gx TELEPORT_TOOLS_VERSION off' >> ~/.config/fish/config.fish"

	/// Whether this process's environment turns managed updates off.
	static var managedUpdatesDisabled: Bool {
		managedUpdatesDisabled(in: ProcessInfo.processInfo.environment)
	}

	/// Whether `environment` turns managed updates off.
	static func managedUpdatesDisabled(in environment: [String: String]) -> Bool {
		environment[managedUpdatesVariable] == managedUpdatesDisabledValue
	}

	// MARK: Validation

	/// Throws, with the command that fixes it, unless managed updates are off.
	static func requireManagedUpdatesDisabled() throws {
		guard managedUpdatesDisabled else {
			throw RuntimeError(
				"TELEPORT_TOOLS_VERSION must be set to 'off' before switching tsh versions.\n"
					+ "Append it to your fish config:\n  \(fishConfigurationCommand)\n"
					+ "Then start a new fish session."
			)
		}
	}

	/// Prints a warning, with the command that fixes it, unless managed updates are off.
	static func printWarningIfNeeded() {
		guard !managedUpdatesDisabled else {
			return
		}

		writeToStandardError(
			"Warning: TELEPORT_TOOLS_VERSION is not set to 'off'.\n"
				+ "Append it to your fish config:\n  \(fishConfigurationCommand)\n"
		)
	}
}

// MARK: - Private Helpers

extension TshEnvironment {
	private static func writeToStandardError(_ message: String) {
		FileHandle.standardError.write(Data(message.utf8))
	}
}
