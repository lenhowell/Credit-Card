//
//  StringExtension.swift
//  TestSharedCode
//
//  Created by George Bauer on 10/11/17.
//  Copyright © 2017-2019 GeorgeBauer. All rights reserved.
//  Ver 1.7.3   7/09/2019 Add removeEnclosingQuotes()
//      1.7.2   7/04/2019 PadRight now optionally truncates with ellipsis or does not truncate at all.
//      1.7.1   4/23/2019 Depricate mid(). Add substring(begin,end) & substring(begin,length)
//      1.7.0   3/31/2019 Change extension to StringProtocol. Added firstIntIndexOf, lastIntIndexOf, allIntIndexesOf

import Foundation

// String extensions: 
// subscript(i), subscript(range), left(i), right(i), mid(i,len), rightJust(len),
// indexOf(str), indexOfRev(str), trim, contains(str), containsIgnoringCase(str), pluralize(n)
extension StringProtocol {

    //------ subscript: allows string to be sliced by ints: e.g. str[2] ------
    /// Int wrapper for str[str.index(str.startIndex, offsetBy: int)] -> Character
    subscript (_ i: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: i)]
    }

//    /// Int wrapper for str[index(startIndex, offsetBy: i)] -> String
//    subscript (_ i: Int) -> String {
//        return String(self[i])
//    }

    /// Int wrapper for str[HalfOpenRange] -> String    ([start..<end])
    subscript (bounds: CountableRange<Int>) -> String {
        if bounds.lowerBound >= self.count        { return "" }     // protection
        if bounds.lowerBound < 0                  { return "" }     // protection
        if bounds.lowerBound >= bounds.upperBound { return "" }     // protection

        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end   = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }

    /// Int wrapper for str[ClosedRange] -> String  ([start...])
    subscript (bounds: CountableClosedRange<Int>) -> String {
        if bounds.lowerBound > self.count { return "" }             // protection
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end   = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }

    /// Int wrapper for str[CountablePartialRangeFrom<Int>] -> String ([start...])
    subscript (bounds: CountablePartialRangeFrom<Int>) -> String {
        if bounds.lowerBound > self.count { return "" }             // protection
        if bounds.lowerBound < 0          { return "" }             // protection
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        return String(self[start...])
    }

    /// Int wrapper for str[PartialRangeThrough<Int>] -> String
    subscript (bounds: PartialRangeThrough<Int>) -> String {
        let end   = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[...end])
    }

    /// Int wrapper for str[PartialRangeUpTo<Int>] -> String
    subscript (bounds: PartialRangeUpTo<Int>) -> String {
        let end   = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[..<end])
    }

    //---- left - get 1st n chars ----
    /// Same as String(.prefix()), but protected from negative numbers
    func left(_ length: Int) -> String {
        return String(self.prefix( Swift.max(length, 0)))
    }
    //---- right - get last n chars ----
    /// Same as String(.suffix()), but protected from negative numbers
    func right(_ length: Int) -> String {
        return String(self.suffix(Swift.max(length, 0)))
    }

    //---- substring - extract a string starting at 'begin', of length (zero-based Int) ----
    /// Extract a string starting at 'begin', of length (zero-based Ints)
    /// - Parameters:
    ///   - begin: Int Starting point for extracted String
    ///   - length: Int Length of extracted String
    /// - Returns: Extracted String
    func substring(begin: Int, length: Int = Int.max) -> String {
        if length == 0 { return "" }
        let lenOrig = self.count                        // length of subject str
        if begin > lenOrig || begin < 0 || length < 0 { return "" }

        var lenNew = Swift.max(length, 0)                     // length of extracted string
        if lenNew == 0 ||  begin > lenOrig - lenNew {
            lenNew = lenOrig - begin
        }

        let startIndexNew = index(startIndex, offsetBy: begin)
        let endIndex = index(startIndex, offsetBy: begin + lenNew)
        return String(self[startIndexNew..<endIndex])
    }

    //---- substring - extract a string starting at 'begin', of length (zero-based Int) ----
    /// Extract a string starting at 'begin', through 'end'
    /// - Parameters:
    ///   - begin: Int Starting point for extracted String
    ///   - end:   pointer to last Character of extracted String
    /// - Returns: Extracted String
    func substring(begin: Int, end: Int) -> String {
        if end < begin || begin < 0 { return "" }
        let endPt: Int
        if end >= self.count {
            endPt = self.count
        } else {
            endPt = end + 1
        }
        let startIndexNew = index(startIndex, offsetBy: begin)
        let endIndexNew   = index(startIndex, offsetBy: endPt)
        return String(self[startIndexNew..<endIndexNew])
    }

    //---- rightJust - format right justify a String in a field ------
    /// Returns a String of specified length representing an Integer right-justified.
    /// Does not truncate when Int is too long.
    /// - Parameter fieldLen: length of returned String
    /// - Returns: new String padded with spaces
    func rightJust(_ fieldLen: Int) -> String {
        guard self.count < fieldLen else { return String(self) }
        let maxStr = String(repeating: " ", count: fieldLen)
        return (maxStr + self).right(fieldLen)
    }

    //---- PadRight - add spaces to right ---- ToDo: Add parameter to allow non-space padding ???
    /// Add spaces (or fillChr) to end of String to fill a field
    /// - Parameters:
    ///   - width: Size of field (length of resulting String)
    ///   - truncate: If true, truncate String that is too big to fit.
    ///   - useEllipsis: If truncated, make lat character an ellipsis (…)
    ///   - fillChr: Optional fill character (defaults to space)
    /// - Returns: New String of length width
    func PadRight(_ width: Int, truncate: Bool = true, useEllipsis: Bool = false , fillChr: Character = " ") -> String {
        let len = self.count
        if len >= width {                               // Truncate
            if len == width || !truncate { return String(self) }                // No change
            if !useEllipsis              { return String(self.prefix(width)) }  // Simply Truncate
            return String(self.prefix(width-1) + "…")                           // Truncate with ellipsis
        }
        //                                              // Pad
        let fill = String(repeating: fillChr, count: width - len)
        return self + fill
    }

    //---- PadLeft - add spaces to left ---- ToDo: Add parameter to allow non-space padding ???
    /// Add spaces ((or fillChr) to left side of String to fill a field
    /// - Parameters:
    ///   - width: Size of field (length of resulting String)
    ///   - fillChr: Optional fill character (defaults to space)
    /// - Returns: New String of length width
    func PadLeft(_ width: Int, fillChr: Character = " ") -> String {
        let len = self.count
        if width <= len { return String(self.prefix(width)) }
        let fill = String(repeating: fillChr, count: width - len)
        return fill + self
    }

    //---- firstIntIndexOf - find Int index of searchforStr starting at startPoint
    /// Find 1st Int index of searchforStr in self, starting at startingAt.
    /// - Parameter searchforStr: String to be searched for
    /// - Parameter startingAt:   Int index to start searching
    /// - Returns: Int index (if found) or -1 (if not found)
    func firstIntIndexOf(_ searchforStr: String, startingAt: Int = 0) -> Int {
//        guard let index = range(of: searchforStr)?.lowerBound else { return -1 }
//        return distance(from: startIndex, to: index)
        if startingAt >= self.count { return -1 }                       // beyond end
        let startInt = Swift.max(startingAt, 0)                         // min startingAt = 0
        let myStartIndex = self.index(self.startIndex, offsetBy: startInt)
        let searchRange = myStartIndex..<self.endIndex
        guard let matchRange = range(of: searchforStr, options: .literal, range: searchRange)
            else { return -1 }
        return distance(from: startIndex, to: matchRange.lowerBound)
    }

    //---- lastIntIndexOf - find last Int index of str in self
    /// Find last Int index of searchforStr.
    /// - Parameter searchforStr: String to be searched for
    /// - Returns: Int index (if found) or -1 (if not found)
    func lastIntIndexOf(_ searchforStr: String) -> Int {
        guard var foundIndex = range(of: searchforStr)?.lowerBound else { return -1 }
        while true {
            let searchIndex  = self.index(foundIndex, offsetBy: 1)
            if searchIndex >= endIndex { break }
            let searchRange = searchIndex..<self.endIndex
            guard let index = range(of: searchforStr, options: .literal, range: searchRange)?.lowerBound else { break }
            foundIndex = index
        }// loop
        return distance(from: startIndex, to: foundIndex)
    }//end func

    //---- allIntIndexesOf - find last Int index of searchforStr
    /// Find last Int index of searchforStr.
    /// - Parameter searchforStr: String to be searched for
    /// - Returns: Int index (if found) or -1 (if not found)
    func allIntIndexesOf(_ searchforStr: String) -> [Int] {
        guard var foundIndex = range(of: searchforStr)?.lowerBound else { return [] }
        var indexes = [Int]()
        while true {
            indexes.append(distance(from: startIndex, to: foundIndex))
            let searchIndex  = self.index(foundIndex, offsetBy: 1)
            if searchIndex >= endIndex { break }
            let searchRange = searchIndex..<self.endIndex
            guard let index = range(of: searchforStr, options: .literal, range: searchRange)?.lowerBound else { break }
            foundIndex = index
        }// loop
        return indexes
    }//end func

    //---- trim - remove whitespace (and newlines)) at both ends ------
    /// Same as ".trimmingCharacters(in: .whitespacesAndNewlines)"
    var trim: String { return self.trimmingCharacters(in: .whitespacesAndNewlines) }

    //---- trimStart & trimEnd - Remove ONLY whitespace from Left or Right
    /// Remove whitespace ONLY from left side (uses RegEx)
    var trimStart: String {
        return self.replacingOccurrences(of: "^\\s+", with: "", options: .regularExpression)
    }
    /// Remove whitespace ONLY from right side (uses RegEx)
    var trimEnd: String {
        return self.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
    }

    public func removeEnclosingQuotes() -> String {
        let str = self.trimmingCharacters(in: .whitespacesAndNewlines)
        if str.hasPrefix("\"") && str.hasSuffix("\"") {
            let newStr = String(str.dropFirst().dropLast())
            return newStr
        }
        return str
    }

    //---- pluralize - Pluralize a word (English) ------
    /// Pluralize an English word if count > 0
    /// - Parameter count: Triggers pluralization if > 0
    /// - Returns: Pluralized word
    func pluralize(_ count: Int) -> String {
        var str: String
        if count == 1 || self.count < 2 {
            //str = self as? String ?? String(self)
            str = String(self)
        } else {
            let last2Chars =  self.right(2)
            let lastChar = last2Chars.right(1)
            let secondToLastChar = last2Chars.left(1)
            var prefix = "", suffix = ""

            if lastChar.lowercased() == "y" && vowels.filter({x in x == secondToLastChar}).isEmpty {
                prefix = self.left(self.count - 1)
                suffix = "ies"
            } else if (lastChar.lowercased() == "s" || (lastChar.lowercased() == "o")
                && consonants.filter({x in x == secondToLastChar}).count > 0) {
                //prefix = self as? String ?? String(self)
                prefix = String(self)
                suffix = "es"
            } else {
                //prefix = self as? String ?? String(self)
                prefix = String(self)
                suffix = "s"
            }
            str = prefix + (lastChar != lastChar.uppercased() ? suffix : suffix.uppercased())
        }
        return str
    }
    private var vowels: [String] {
        get {
            return ["a", "e", "i", "o", "u"]
        }
    }
    private var consonants: [String] {
        get {
            return ["b", "c", "d", "f", "g", "h", "j", "k", "l", "m", "n", "p", "q", "r", "s", "t", "v", "w", "x", "z"]
        }
    }

}//end extension String


