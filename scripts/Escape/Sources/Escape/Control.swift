public func clearLine() {
	echo(ControlConstants.clearLineSequence)
}

enum ControlConstants {
	static let clearLineSequence = "\(escape)[2K\r"
}
