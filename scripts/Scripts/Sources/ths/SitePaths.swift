import ArgumentParser
import Foundation

/// The two directories every `ths` subcommand works between. One is the source directory, The
/// Honking Smith folder in the vault, and the other is the website repo. Each comes from its flag,
/// or from its environment variable when the flag isn't given. When neither is set, validation
/// fails with the `fish` command that sets the variable, so the fix is in the error itself.
struct SitePaths: ParsableArguments {
	@Option(help: ArgumentHelp(
		"The Honking Smith folder in the vault. Defaults to `$\(Self.sourceVariable)`.",
		valueName: "path",
	))
	var source: String? = nil

	@Option(help: ArgumentHelp(
		"The website repo. Defaults to `$\(Self.siteVariable)`.",
		valueName: "path",
	))
	var site: String? = nil

	/// The source directory. Throws the error `validate()` does when it isn't set or isn't a directory.
	var sourceDirectory: URL {
		get throws {
			try Self.directory(
				source,
				flag: "--source",
				variable: Self.sourceVariable,
				setCommand: Self.sourceSetCommand,
			)
		}
	}

	/// The website repo. Throws the error `validate()` does when it isn't set or isn't a directory.
	var siteDirectory: URL {
		get throws {
			try Self.directory(
				site,
				flag: "--site",
				variable: Self.siteVariable,
				setCommand: Self.siteSetCommand,
			)
		}
	}

	func validate() throws {
		_ = try sourceDirectory
		let siteDirectory = try siteDirectory
		let blog = siteDirectory.appending(path: "content/blog")
		guard FileManager.default.fileExists(atPath: blog.path(percentEncoded: false)) else {
			throw ValidationError(
				"\(siteDirectory.path(percentEncoded: false)) has no content/blog folder, so it isn't the site repo."
			)
		}
	}
}

// MARK: - Static Members

extension SitePaths {
	/// The variable that holds the source directory when `--source` isn't given.
	static let sourceVariable = "THS_SOURCE_DIR"
	/// The variable that holds the website repo when `--site` isn't given.
	static let siteVariable = "THS_SITE_DIR"
	/// The `fish` command that sets `sourceVariable` for every session.
	static let sourceSetCommand = #"set -Ux THS_SOURCE_DIR "$HOME/gooseOS/The Honking Smith""#
	/// The `fish` command that sets `siteVariable` for every session.
	static let siteSetCommand = "set -Ux THS_SITE_DIR $HOME/code/the-honking-smith-dot-com"
}

// MARK: - Private Helpers

extension SitePaths {
	/// The directory that `flagValue` names, or else `variable` does. Throws with `setCommand` when
	/// neither is set, and when the path isn't a directory.
	private static func directory(
		_ flagValue: String?,
		flag: String,
		variable: String,
		setCommand: String,
	) throws -> URL {
		let environmentValue = ProcessInfo.processInfo.environment[variable]
		guard let path = flagValue ?? environmentValue, !path.isEmpty else {
			throw ValidationError("""
				No \(flag.dropFirst(2)) directory. Pass `\(flag)`, or set `$\(variable)` once for every `fish` session:

				  \(setCommand)
				""")
		}

		let expanded = path.expandingTilde(homeDirectory: FileManager.default.homeDirectoryForCurrentUser)
		let url = URL(filePath: expanded, directoryHint: .isDirectory).standardizedFileURL
		var isDirectory: ObjCBool = false
		guard
			FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
			isDirectory.boolValue
		else {
			throw ValidationError("\(url.path) isn't a directory.")
		}

		return url
	}
}
