/// A failure with the message a tool prints for it.
public struct RuntimeError: Error, CustomStringConvertible, Sendable {
	/// The message, written for the person running the tool.
	public let description: String

	/// Creates an error with `description` as its message.
	public init(_ description: String) {
		self.description = description
	}
}
