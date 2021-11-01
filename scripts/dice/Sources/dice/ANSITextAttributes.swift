indirect enum ANSITextAttribute: Int {
    case `default` = 0

    case blackFG = 30
    case redFG = 31
    case greenFG = 32
    case yellowFG = 33
    case blueFG = 34
    case magentaFG = 35
    case cyanFG = 36
    case whiteFG = 37

    case blackBG = 40
    case redBG = 41
    case greenBG = 42
    case yellowBG = 43
    case blueBG = 44
    case magentaBG = 45
    case cyanBG = 46
    case whiteBG = 47

    case grayFG = 90 // technically "bright black"
    case brightRedFG = 91
    case brightGreenFG = 92
    case brightYellowFG = 93
    case brightBlueFG = 94
    case brightMagentaFG = 95
    case brightCyanFG = 96
    case brightWhiteFG = 97

    case grayBG = 100 // technically "bright black"
    case brightRedBG = 101
    case brightGreenBG = 102
    case brightYellowBG = 103
    case brightBlueBG = 104
    case brightMagentaBG = 105
    case brightCyanBG = 106
    case brightWhiteBG = 107

    case bold = 1
    case faint = 2
    case italic = 3
    case underline = 4
}

extension Array where Element == ANSITextAttribute {
    func ansiEscapeString() -> String {
        let joinedOptions = self
            .map(\.rawValue)
            .map(String.init)
            .joined(separator: ";")

        return "\u{001B}[\(joinedOptions)m"
    }
}

extension String.StringInterpolation {
    mutating func appendInterpolation<T: CustomStringConvertible>(_ value: T, colors: ANSITextAttribute...) {
        let colorString = colors.ansiEscapeString()
        let resetString = [ANSITextAttribute.default].ansiEscapeString()
        appendInterpolation("\(colorString)\(value)\(resetString)")
    }
}
