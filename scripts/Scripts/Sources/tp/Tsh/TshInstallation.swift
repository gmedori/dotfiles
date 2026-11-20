import Foundation

/// A `tsh` binary on this Mac and the Teleport version it reports.
struct TshInstallation: Equatable, Sendable {
	/// The version `tsh version` reports, without a leading `v`.
	var version: String
	/// Everything `tsh version` printed.
	var versionOutput: String
	/// The binary, with symbolic links resolved.
	var url: URL
	/// Where the binary came from.
	var source: TshSource

	/// The binary's path, with the home folder shortened to `~`.
	var displayPath: String {
		TshPathFormatter.display(url)
	}
}
