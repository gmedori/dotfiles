import ArgumentParser

/// Where a `tsh` installation came from.
enum TshSource: String, CaseIterable, ExpressibleByArgument, Sendable {
	/// The `tsh` inside Teleport Connect.
	case connect
	/// The standalone `tsh.app`.
	case standalone
	/// A version that managed updates installed under the Teleport home folder.
	case managed
	/// Homebrew's `teleport` formula.
	case homebrew
	/// A build from a checkout under `~/code`.
	case source
	/// Any other `tsh`, like one found in `PATH` or given with `--path`.
	case other
}
