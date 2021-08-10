struct DiceLogger {
    private static let topLeft: Character = "\u{250F}"
    private static let topRight: Character = "\u{2513}"
    private static let bottomLeft: Character = "\u{2517}"
    private static let bottomRight: Character = "\u{251B}"
    private static let horizontalLine: Character = "\u{2501}"
    private static let verticalLine: Character = "\u{2503}"

    private static let upTee: Character = "\u{2533}"
    private static let downTee: Character = "\u{253B}"
    private static let leftTee: Character = "\u{2523}"
    private static let rightTee: Character = "\u{252B}"

    func log(_ diceResults: [DiceResult]) {
//        diceResults.forEach { dieResult in
//            let str = "Rolling a D\(dieResult.die.numSides) --> Got a \(dieResult.result, colors: .blackFG, .greenBG, .italic)"
//            let boxed = box(str)
//            print(boxed)
//        }
        print(box(results: diceResults))
    }

    private func box(results: [DiceResult]) -> String {
        var toReturn = ""
        var insideEscapeSequence = false

        enum LineLevel: CaseIterable {
            case top, title, middle, result, bottom
        }

        func append(character: Character, forWidthOf s: String) {
            for c in s {
                if insideEscapeSequence && c == "m" {
                    insideEscapeSequence = false
                    continue
                }

                if insideEscapeSequence || c == "\u{001B}" {
                    insideEscapeSequence = true
                    continue
                }

                toReturn.append(character)
            }
        }


        for line in LineLevel.allCases {
            switch line {
            case .top:
                toReturn.addBoxChar(.heavyDownAndRight)
            case.title:
                toReturn.addBoxChar(.heavyVertical)
            case .middle:
                toReturn.addBoxChar(.downLightAndRightUpHeavy)
            case .result:
                toReturn.addBoxChar(.lightVertical)
            case .bottom:
                toReturn.addBoxChar(.lightUpAndRight)
            }

            // center columns

            for (index, result) in results.enumerated() {
                let title = " D\(result.die.numSides) "
                var resultString = "\(result.result, colors: .greenFG)"
                let maxWidth = title.countIgnoringEscapeSequences

                let diff = maxWidth - resultString.countIgnoringEscapeSequences

                if diff % 2 == 0 {
                    resultString = "\(String(repeating: " ", count: diff/2))\(resultString)\(String(repeating: " ", count: diff/2))"
                } else {
                    resultString = "\(String(repeating: " ", count: diff/2 + 1))\(resultString)\(String(repeating: " ", count: diff/2))"
                }


                switch line {
                case .top:
                    toReturn.addBoxChar(.heavyHorizontal, count: maxWidth)
                    toReturn.addBoxChar(.heavyDownAndHorizontal)
                case.title:
                    toReturn.append(title)
                    toReturn.addBoxChar(.heavyVertical)
                case .middle:
                    toReturn.addBoxChar(.heavyHorizontal, count: maxWidth)
                    toReturn.addBoxChar(.downLightAndUpHorizontalHeavy)
                case .result:
                    toReturn.append(resultString)
                    toReturn.addBoxChar(.lightVertical)
                case .bottom:
                    toReturn.addBoxChar(.lightHorizontal, count: maxWidth)
                    toReturn.addBoxChar(.lightUpAndHorizontal)
                }
            }

            let totalTitle = " Total "
            let totalResult = results.reduce(0, { $0 + $1.result })
            let maxWidth = totalTitle.countIgnoringEscapeSequences
            var resultString = "\(totalResult)"
            let diff = totalTitle.countIgnoringEscapeSequences - resultString.countIgnoringEscapeSequences
            if diff % 2 == 0 {
                resultString = "\(String(repeating: " ", count: diff/2))\(resultString)\(String(repeating: " ", count: diff/2))"
            } else {
                resultString = "\(String(repeating: " ", count: diff/2 + 1))\(resultString)\(String(repeating: " ", count: diff/2))"
            }

            switch line {
            case .top:
                toReturn.addBoxChar(.heavyHorizontal, count: maxWidth)
            case.title:
                toReturn.append(totalTitle)
            case .middle:
                toReturn.addBoxChar(.heavyHorizontal, count: maxWidth)
            case .result:
                toReturn.append(resultString)
            case .bottom:
                toReturn.addBoxChar(.lightHorizontal, count: maxWidth)
            }



            switch line {
            case .top:
                toReturn.addBoxChar(.heavyDownAndLeft)
            case.title:
                toReturn.addBoxChar(.heavyVertical)
            case .middle:
                toReturn.addBoxChar(.downLightAndLeftUpHeavy)
            case .result:
                toReturn.addBoxChar(.lightVertical)
            case .bottom:
                toReturn.addBoxChar(.lightUpAndLeft)
            }

            toReturn.append("\n")
        }

        return toReturn
    }

    private func box(_ string: String, withPadding padding: Int = 0) -> String {
        var toReturn = ""
        var insideEscapeSequence = false

        func append(character: Character, forWidthOf s: String) {
            for c in string {
                if insideEscapeSequence && c == "m" {
                    insideEscapeSequence = false
                    continue
                }

                if insideEscapeSequence || c == "\u{001B}" {
                    insideEscapeSequence = true
                    continue
                }

                toReturn.append(character)
            }
        }

        toReturn.addBoxChar(.heavyDownAndRight)
        append(character: Self.horizontalLine, forWidthOf: string)
        toReturn.addBoxChar(.heavyDownAndLeft)
        toReturn.append("\n")
        toReturn.addBoxChar(.heavyVertical)
        toReturn.append(string)
        toReturn.addBoxChar(.heavyVertical)
        toReturn.append("\n")
        toReturn.addBoxChar(.heavyUpAndRight)
        append(character: Self.horizontalLine, forWidthOf: string)
        toReturn.addBoxChar(.heavyUpAndLeft)

        return toReturn
    }
}

fileprivate enum BoxDrawing: Character {
                                                   // MARK: - Light and heavy solid lines
    case lightHorizontal = "\u{2500}"              // ─
    case heavyHorizontal = "\u{2501}"              // ━
    case lightVertical = "\u{2502}"                // │
    case heavyVertical = "\u{2503}"                // ┃

                                                   // MARK: - Light and heavy dashed lines
    case lightTripleDashHorizontal = "\u{2504}"    // ┄
    case heavyTripleDashHorizontal = "\u{2505}"    // ┅
    case lightTripleDashVertical = "\u{2506}"      // ┆
    case heavyTripleDashVertical = "\u{2507}"      // ┇
    case lightQuadrupleDashHorizontal = "\u{2508}" // ┈
    case heavyQuadrupleDashHorizontal = "\u{2509}" // ┉
    case lightQuadrupleDashVertical = "\u{250A}"   // ┊
    case heavyQuadrupleDashVertical = "\u{250B}"   // ┋

                                                   // MARK: - Light and heavy line box components

    case lightDownAndRight = "\u{250C}"            // ┌
    case downLightAndRightHeavy = "\u{250D}"       // ┍
    case downHeavyAndRightLight = "\u{250E}"       // ┎
    case heavyDownAndRight = "\u{250F}"            // ┏

    case lightDownAndLeft = "\u{2510}"             // ┐
    case downLightAndLeftHeavy = "\u{2511}"        // ┑
    case downHeavyAndLeftLight = "\u{2512}"        // ┒
    case heavyDownAndLeft = "\u{2513}"             // ┓

    case lightUpAndRight = "\u{2514}"             // └
    case upLightAndRightHeavy = "\u{2515}"        // ┕
    case upHeavyAndRightLight = "\u{2516}"        // ┖
    case heavyUpAndRight = "\u{2517}"             // ┗

    case lightUpAndLeft = "\u{2518}"             // ┘
    case upLightAndLeftHeavy = "\u{2519}"        // ┙
    case upHeavyAndLeftLight = "\u{251A}"        // ┚
    case heavyUpAndLeft = "\u{251B}"             // ┛

    case lightVerticalAndRight = "\u{251C}" // ├
    case verticalLightAndRightHeavy = "\u{251D}" // ┝
    case upHeavyAndRightDownLight = "\u{251E}" // ┞
    case downHeavyAndRightUpLight = "\u{251F}" // ┟
    case verticalHeavyAndRightLight = "\u{2520}" // ┠
    case downLightAndRightUpHeavy = "\u{2521}" // ┡
    case upLightAndRightDownHeavy = "\u{2522}" // ┢
    case heavyVerticalAndRight = "\u{2523}" // ┣

    case lightVerticalAndLeft = "\u{2524}" // ┤
    case verticalLightAndLeftHeavy = "\u{2525}" // ┥
    case upHeavyAndLeftDownLight = "\u{2526}" // ┦
    case downHeavyAndLeftUpLight = "\u{2527}" // ┧
    case verticalHeavyAndLeftLight = "\u{2528}" // ┨
    case downLightAndLeftUpHeavy = "\u{2529}" // ┩
    case upLightAndLeftDownHeavy = "\u{252A}" // ┪
    case heavyVerticalAndLeft = "\u{252B}" // ┫

    case lightDownAndHorizontal = "\u{252C}" // ┬
    case leftHeavyAndRightDownLight = "\u{252D}" // ┭
    case rightHeavyAndLeftDownLight = "\u{252E}" // ┮
    case downLightAndHorizontalHeavy = "\u{252F}" // ┯
    case downHeavyAndHorizontalLight = "\u{2530}" // ┰
    case rightLightAndLeftDownHeavy = "\u{2531}" // ┱
    case leftLightAndRightDownHeavy = "\u{2532}" // ┲
    case heavyDownAndHorizontal = "\u{2533}" // ┳

    case lightUpAndHorizontal = "\u{2534}" // ┴
    case leftHeavyAndRightUpLight = "\u{2535}" // ┵
    case rightHeavyAndLeftUpLight = "\u{2536}" // ┶
    case upLightAndHorizontalHeavy = "\u{2537}" // ┷
    case upHeavyAndHorizontalLight = "\u{2538}" // ┸
    case rightLightAndLeftUpHeavy = "\u{2539}" // ┹
    case leftLightAndRightUpHeavy = "\u{253A}" // ┺
    case heavyUpAndHorizontal = "\u{253B}" // ┻

    case lightVerticalAndHorizontal = "\u{253C}" // ┼
    case leftHeavyAndRightVerticalLight = "\u{253D}" // ┽
    case rightHeavyAndLeftVerticalLight = "\u{253E}" // ┾
    case verticalLightAndHorizontalHeavy = "\u{253F}" // ┿
    case upHeavyAndDownHorizontalLight = "\u{2540}" // ╀
    case downHeavyAndUpHorizontalLight = "\u{2541}" // ╁
    case verticalHeavyAndHorizontalLight = "\u{2542}" // ╂
    case leftUpHeavyAndRightDownLight = "\u{2543}" // ╃
    case rightUpHeavyAndLeftDownLight = "\u{2544}" // ╄
    case leftDownHeavyAndRightUpLight = "\u{2545}" // ╅
    case rightDownHeavyAndLeftUpLight = "\u{2546}" // ╆
    case downLightAndUpHorizontalHeavy = "\u{2547}" // ╇
    case upLightAndDownHorizontalHeavy = "\u{2548}" // ╈
    case rightLightAndLeftVerticalHeavy = "\u{2549}" // ╉
    case leftLightAndRightVerticalHeavy = "\u{254A}" // ╊
    case heavyVerticalAndHorizontal = "\u{254B}" // ╋

}

fileprivate extension String {
    mutating func addBoxChar(_ boxChar: BoxDrawing, count: Int = 1) {
        for _ in 0..<count {
            self.append(boxChar.rawValue)
        }
    }

    var countIgnoringEscapeSequences: Int {
        var insideEscapeSequence = false
        var count = 0

        for c in self {
            if insideEscapeSequence && c == "m" {
                insideEscapeSequence = false
                continue
            }

            if insideEscapeSequence || c == "\u{001B}" {
                insideEscapeSequence = true
                continue
            }

            count += 1
        }

        return count
    }
}
