public func clearLine() {
	echo(ControlConstants.clearLineSequence)
}

enum ControlConstants {
	static let clearLineSequence: String = "\(escape)[2K\r"
}
