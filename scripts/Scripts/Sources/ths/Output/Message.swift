/// An error or warning printed after the list of posts. It's a line saying what's wrong, then lines
/// saying how to fix it.
struct Message: Equatable, Sendable {
	/// Whether it's an error or a warning, which decides the label it's printed with.
	var kind: Kind
	/// The line saying what's wrong.
	var headline: String
	/// The lines saying how to fix it, each printed indented under the headline.
	var details: [String]
}

// MARK: - Supporting Types

extension Message {
	/// Whether a message is an error or a warning.
	enum Kind: Sendable {
		/// A problem, which makes the command exit 1.
		case error
		/// Something to fix that doesn't block the post or change the exit status.
		case warning
	}
}
