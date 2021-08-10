//
//  File.swift
//  
//
//  Created by dragonite on 7/3/21.
//

import Foundation

extension String {
    subscript(_ range: NSRange) -> String {
        let start = self.index(self.startIndex, offsetBy: range.lowerBound)
        let end = self.index(self.startIndex, offsetBy: range.upperBound)
        let subString = self[start..<end]
        return String(subString)
    }
}
