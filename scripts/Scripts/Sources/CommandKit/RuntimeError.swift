public struct RuntimeError: Error, CustomStringConvertible, Sendable {
	public let description: String

	public init(_ description: String) {
		self.description = description
	}
}
