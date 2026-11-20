/// The 16 ANSI terminal colors, and `reset` for the terminal's own colors.
///
/// The bright colors are the high-intensity versions that most terminals show for SGR codes 90 to 97
/// and 100 to 107.
public enum Color: Sendable {
	case black
	case red
	case green
	case yellow
	case blue
	case magenta
	case cyan
	case white
	case reset
	case brightBlack
	case brightRed
	case brightGreen
	case brightYellow
	case brightBlue
	case brightMagenta
	case brightCyan
	case brightWhite

	/// The SGR code that sets this color as the text color.
	var foregroundCode: Int {
		switch self {
			case .black: 30
			case .red: 31
			case .green: 32
			case .yellow: 33
			case .blue: 34
			case .magenta: 35
			case .cyan: 36
			case .white: 37
			case .reset: 39
			case .brightBlack: 90
			case .brightRed: 91
			case .brightGreen: 92
			case .brightYellow: 93
			case .brightBlue: 94
			case .brightMagenta: 95
			case .brightCyan: 96
			case .brightWhite: 97
		}
	}

	/// The SGR code that sets this color as the background color.
	var backgroundCode: Int {
		switch self {
			case .black: 40
			case .red: 41
			case .green: 42
			case .yellow: 43
			case .blue: 44
			case .magenta: 45
			case .cyan: 46
			case .white: 47
			case .reset: 49
			case .brightBlack: 100
			case .brightRed: 101
			case .brightGreen: 102
			case .brightYellow: 103
			case .brightBlue: 104
			case .brightMagenta: 105
			case .brightCyan: 106
			case .brightWhite: 107
		}
	}
}
