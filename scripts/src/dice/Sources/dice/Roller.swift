class Roller {
    func roll(dice: [Die]) -> [DiceResult] {
        var results = [Die: UInt]()
        for die in dice {
            results[die] = UInt.random(in: 1...die.numSides)
        }
        return results.map { die, result in DiceResult(die: die, result: result)}
    }
}

struct DiceResult {
    let die: Die
    let secondaryDie: Die?
    let result: UInt
    let hadAdvantage: Bool
    let hadDisadvantage: Bool

    init(die: Die, secondaryDie: Die? = nil, result: UInt, hadAdvantage: Bool = false, hadDisadvantage: Bool = false) {
        self.die = die
        self.secondaryDie = secondaryDie
        self.result = result
        self.hadAdvantage = hadAdvantage
        self.hadDisadvantage = hadDisadvantage
    }
}
