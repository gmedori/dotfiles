import ArgumentParser
import Foundation

fileprivate var stderr = StandardErrorOutputStream()

@available(macOS 10.13, *)
struct DiceCommand: ParsableCommand {

    public enum Error: Swift.Error, CustomStringConvertible {
        case couldNotParseDice(diceString: String)
        case unexpectedError(description: String)

        public var description: String {
            switch self {
            case let .couldNotParseDice(diceString):
                return "Could not parse dice from \"\(diceString)\""
            case let .unexpectedError(description):
                return "Encountered an unexpected problem: \(description)"
            }
        }
    }

    @Flag(name: .shortAndLong, help: "Roll dice with advantage")
    public var advantage: Bool = false

    @Flag(name: .shortAndLong, help: "Roll dice with disadvantage")
    public var disadvantage: Bool = false

    @Argument(help: "The dice to roll, e.g. 2d10")
    public var diceArgs: [String]

    public mutating func run() throws {
        let roller = Roller()
        let dice = try diceArgs.flatMap { diceString -> [Die] in
            return try parseDice(diceString: diceString)
        }
        let results = roller.roll(dice: dice)
        let logger = DiceLogger()
        logger.log(results)
   }

    private func parseDice(diceString: String) throws -> [Die]  {
        let pattern = #"(?<numDice>\d?)d(?<numSides>\d+)"#
        let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])

        let nsrange = NSRange(diceString.startIndex..<diceString.endIndex, in: diceString)
        guard let match = regex.firstMatch(in: diceString, options: [], range: nsrange) else {
            throw DiceCommand.Error.couldNotParseDice(diceString: diceString)
        }

        let numDiceRange = match.range(withName: "numDice")
        let numSidesRange = match.range(withName: "numSides")

        guard numDiceRange.location != NSNotFound, numSidesRange.location != NSNotFound else {
            throw DiceCommand.Error.couldNotParseDice(diceString: diceString)
        }

        guard let numDice = UInt(diceString[numDiceRange]), let numSides = UInt(diceString[numSidesRange]) else {
            throw DiceCommand.Error.unexpectedError(description: "\"\(diceString[numDiceRange])\" and/or \"\(diceString[numSidesRange])\" could not be parsed as an unsigned integer.")
        }

        var toReturn = [Die]()
        (0..<numDice).forEach { _ in
            toReturn.append(Die(numSides: UInt(numSides)))
        }
        return toReturn
    }
}

if #available(macOS 10.13, *) {
    DiceCommand.main()
} else {
    fatalError("dice is unable to run on versions of macOS < 10.13. Please upgrade to something newer.")
}
