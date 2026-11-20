/// The ANSI escape sequences that `Escape` writes.
enum ControlSequence {
	/// The escape character that starts every control sequence.
	static let escape = "\u{1B}"

	/// Erases the current line and moves the cursor to its start.
	static let clearLine = "\(escape)[2K\r"

	/// Sets the text color to `foreground` and the background color to `background`.
	static func colors(foreground: Color = .reset, background: Color = .reset) -> String {
		"\(escape)[\(foreground.foregroundCode);\(background.backgroundCode)m"
	}
}
