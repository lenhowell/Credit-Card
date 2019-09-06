//
//  DescriptionKey.swift
//  Credit Cards
//
//  Created by George Bauer on 8/18/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Foundation

//MARK:- Globals
let descKeysuppressionList = " \";_@/,#*-"
let descKeyLength          = 18
var dictDescKeyAlgorithm = [String: Int]()

//MARK:- makeDescKey 17-216 = 199-lines
public func makeDescKey(from desc: String, fileName: String = "") -> String {
    var descKeyLong = desc
    var key2 = ""
    var ccPrefix = ""

    //-- Truncate at Double Space -- [TOOJAY'S  OCOEE LLC] -> [TOOJAY'S]
    let posDblSpc = descKeyLong.firstIntIndexOf("  ")
    if posDblSpc >= 0 {
        //print("✅ Got double-space at pos \(posDblSpc) in \(descKeyLong)")
        if posDblSpc >= 2 {
            key2 = String(descKeyLong.prefix(posDblSpc))
            descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "01.Truncate @ Dbl-Space")
        } else {
            // Debug Trap: Never hit
        }
    }

    //-- Eliminate apostrophies -- [TOOJAY'S] -> [TOOJAYS]
    key2 = descKeyLong.replacingOccurrences(of: "['`]", with: "", options: .regularExpression, range: nil)
    descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "02.Remove apostrophy")

    //-- Find KeyWords in Description
    let descKeyUpper = descKeyLong.uppercased()
    for (keyWord, descKeyWord) in dictDescKeyWords {
        if descKeyWord.isPrefix {
            if descKeyUpper.hasPrefix(keyWord) {
                return descKeyWord.descKey
            }
        } else {
            if descKeyUpper.contains(keyWord) {
                return descKeyWord.descKey
            }
        }
    }//next

    //-- Remove spaces around " & " -- [STOP & SHOP 0620] -> [STOP&SHOP 0620]
    key2 = descKeyLong.replacingOccurrences(of: " ?& ?", with: "&", options: .regularExpression, range: nil)
    descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "03.Fix \"&\" spaces")

    //--  Change " AND " to "&" -- [TINAS NAIL AND SKIN] -> [TINAS NAIL&SKIN]
    key2 = descKeyLong.replacingOccurrences(of: " +AND +", with: "&", options: .regularExpression, range: nil)
    descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "04.Change \" AND \" to \"&\"")

    //-- Remove "SQU*", "SQ *", etc. from beginning of line. -- [TLF*CITY LINE FLORIST] -> [CITY LINE FLORIST]
    key2 = descKeyLong.replacingOccurrences(of: #"^...\*"#, with: "", options: .regularExpression, range: nil)
    if key2 != descKeyLong {
        ccPrefix = String(descKeyLong.prefix(3))
    }
    descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "05.Remove \"SQU*\" etc.")

    //-- Remove 2nd "SQU*", "SQ *", etc. from beginning of line. [SQ *SQ *FOREFLIGHT] -> [FOREFLIGHT]
    key2 = descKeyLong.replacingOccurrences(of: #"^...\*"#, with: "", options: .regularExpression, range: nil)
    descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "06.Remove 2nd \"SQU*\" etc.")

//    if descKeyLong.contains("SWEET TOMATOES 72 Q14") {
//        // debug trap
//    }

    // Truncate Line upon th following matches

    //-- Truncate at Phone Number [123-456-7890...] -- [GOLF TAILOR 888-241-2460 OK] -> [GOLF TAILOR]
    //(must be done before removing "-")
    var regexp = #"\d+-\d+-\d+.*"#
    if let range = descKeyLong.range(of:regexp, options: .regularExpression) {
        key2 = descKeyLong.replacingCharacters(in: range, with: "").trim
        descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "07.Remove phone number")
    }

    //-- Truncate at bare Number(>=3 digits) [ #12...], [ 12...] -- [GULF OIL 92063634] -> [GULF OIL]
    regexp = #" #?\d\d\d.*"#
    if let range = descKeyLong.range(of:regexp, options: .regularExpression) {
        key2 = descKeyLong.replacingCharacters(in: range, with: "").trim
        //let result = descKeyLong[range]
        //print("[\(key2)] = [\(descKeyLong)] - [\(result)]")
        descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "08.Truncate @ bare number >=3")
    }

    //-- Truncate at " - " if pos > 7       [C2 - VANGUARD KITCHEN]  [REVERSE - DUP CREDIT - BLOOMINGDALES NEW] 9ok
    let posDash = descKeyLong.firstIntIndexOf(" - ")
    if posDash > 7  {
        key2 = String(descKeyLong.prefix(posDash))
        descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "09.Truncate @ \" - \" if > 7")
        //
    }

    //-- Truncate at Spc, 0orMore Letters, 2orMore digits at end -- [KFC J235016] -> [KFC]
    regexp = #" #?\w?\d\d+$"#
    if let range = descKeyLong.range(of:regexp, options: .regularExpression) {
        key2 = descKeyLong.replacingCharacters(in: range, with: "").trim
        //let result = descKeyLong[range]
        //print("[\(key2)] = [\(descKeyLong)] - [\(result)]")
        descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "10.Truncate @ trailing number >1 dig")
    }

    //-- Truncate at  embedded Number(>=3 digits) [#123...] -- [BP#9155029GENES AUTO] -> [BP]
    //(must be done before removing "#")
    regexp = #"#\d\d\d.*"#
    if let range = descKeyLong.range(of:regexp, options: .regularExpression) {
        key2 = descKeyLong.replacingCharacters(in: range, with: "").trim
        //let result = descKeyLong[range]
        //print("[\(key2)] = [\(descKeyLong)] - [\(result)]")
        descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "11.Truncate @ embedded # + 3dig")
    }

    //-- Truncate at [ Fx123...] Spc 0orMore Caps 0orMore x's -- [VIOC AE0034] -> [VIOC]
    regexp = #" [A-Z]*x*\d\d\d+.*"#
    if let range = descKeyLong.range(of:regexp, options: .regularExpression) {
        key2 = descKeyLong.replacingCharacters(in: range, with: "").trim
        //let result = descKeyLong[range]
        //print("[\(key2)] = [\(descKeyLong)] - [\(result)]")
        descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "12.Truncate @ [ Fx123]")
    }



    //TODO: Eliminate use of firstIntIndexOf()

    //-- Truncate at "#..." -- [ZIPS #9] -> [ZIPS ]
    let posHash = descKeyLong.firstIntIndexOf("#")
    if posHash >= 0 {
        //print("✅ Got (#) at pos \(posHash) in \(descKeyLong)")
        if posHash >= 2 {
            key2 = String(descKeyLong.prefix(posHash))
            descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "13.Truncate @ \"#\"")
        } else {
            // Debug Trap: Never hit
        }
    }

    //-- Truncate at "xx..." -- [AAA ORLANDO TOW #xxx] -> [AAA ORLANDO TOW #]
    //(must be done before uppercasing or you will mess up "EXXON")
    let posX = descKeyLong.firstIntIndexOf("xx")
    if posX >= 0 {
        //print("✅ Got (xx) at pos \(posX) in \(descKeyLong)")
        if posX >= 2 {
            key2 = String(descKeyLong.prefix(posX))
            descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "14.Truncate @ \"xxx...\"")
        } else {
            // Debug Trap: Never hit
        }
    }

    //-- VZWRLSS*APOCC VISN     (7)
    // Truncate at "*..." if it is chr #7 or greater -- [SPRINT *WIRELESS] -> [SPRINT ]
    let posStar = descKeyLong.firstIntIndexOf("*")
    if posStar >= 0 {
        //print("✅ Got (*) at pos \(posStar) in \(descKeyLong)")
        if posStar >= 6 {
            key2 = String(descKeyLong.prefix(posStar))
            descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "15.Truncate @ \"*\" if pos>5")
        } else {
            // Debug Trap - "PP*WHIRLWIND SUN N FUN..."
        }
    }


    //-- Replace chars in suppression list with spaces -- [STEAK-N-SHAKE] -> [STEAK N SHAKE]
    key2 = descKeyLong.replacingOccurrences(of: "["+descKeysuppressionList+"]", with: " ", options: .regularExpression, range: nil)
    descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "16.Char Suppression List.")

    if descKeyLong.isEmpty { return "" }

    //-- Check last char in descKeyLong -- [PILOT 00337] -> [PILOT]; [TW8442595572] -> [TW]
    if let chr = descKeyLong.last {
        if chr.isWholeNumber {
            let comps = descKeyLong.components(separatedBy: " ")
            let lastWord = comps.last ?? descKeyLong
            if lastWord.count > 1 {
                key2 = stripTrailingNumber(descKeyLong, fileName: fileName)
                descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "17.Strip trailing digits off last word.")
            } else {
                // "SUPER 8", "DTGC 1", "DTGC_1", "STAR SHOWER 2"
            }
        }
    }

    descKeyLong = descKeyLong.uppercased()

    //-- Remove "THE" "INC", "LLC" -- [TREELANDS INC] -> [TREELANDS ];  [GUNDRY MD  LLC] -> [GUNDRY MD  ]
    key2 = descKeyLong.replacingOccurrences(of: #"^THE\b|\bINC\b|\bLLC\b"#, with: "", options: .regularExpression, range: nil).trim
    descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "18.Remove \"INC\" & \"LLC\" ")

    descKeyLong = descKeyLong.trim

    //-- Remove Double Spaces -- [DMV   BRIDGEPORT BRANC] -> [DMV BRIDGEPORT BRANC]
    key2 = descKeyLong.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression, range: nil)
    descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "19.Squish double spaces")

    if !ccPrefix.isEmpty && descKeyLong.count < 9 {
        print("⚠️ \(ccPrefix) + \"\(descKeyLong)\"   \(descKeyLong.count)")
        descKeyLong = ccPrefix + " " + descKeyLong
        print(descKeyLong)
        //"SWA EARLYBRD", "ALG AIR", "HUM HUMANN"
    }

    // Truncate
    let descKey = String(descKeyLong.prefix(descKeyLength)).trim

    return descKey
}//end func makeDescKey


//MARK:- Helper funcs

// if multiple words: remove ast word
// if only one word:
internal func stripTrailingNumber(_ keyIn: String, fileName: String = "") -> String {
    var key = keyIn
    var key2 = key

    // Replace [(spc) (2 or more digits) (word boundry)] with spc
    key2 = key.replacingOccurrences(of:  #" \d\d+\b"#, with: " ", options: .regularExpression, range: nil).trim
    if key2 != key {    // "PILOT 00337", "SUPER 8", "STAR SHOWER 2", "DTGC 1", "JETBLUE     2"
        print("🔹 1 ",fileName, key, "=>" , key2)   // CIRCLE B 10 => CIRCLE B (# was too short)
        return key2.trim
    }

    if key.contains(" ") {      // has a space
        let indexSp = key.lastIndex(of: " ") ?? key.startIndex
        key2 = String(key[..<indexSp])  // String(key.prefix(upTo: indexSp))
        print("🔹 2 ",fileName, "\(key)  =>  \"\(key2)\"")
        key = key2          // MCDONALDS F13620 => MCDONALDS  VIOC AE0034 => VIOC    (# starts with letters)
    } else {                // no space
        let indexLet = key.lastIndex(where: {!$0.isNumber}) ?? key.index(before: key.endIndex) // optional
        key2 = String(key[...indexLet])                                 // "AE1B"
        print("🔹 3 ",fileName, "\(key)  =>  \"\(key2)\"")
        key = key2                  // STP&SHPFUEL0663 => STP&SHPFUEL (no space between name & #)
    }
    return key.trim
}//end func stripTrailingNumber

//---- checkDif - If there is a difference: record it, mayby print it, & return new value
func checkDif(newStr: String, oldStr: String, doPrint: Bool, comment: String) -> String {
    if oldStr != newStr {
        let algToPrint = 0   // CHANGE THIS NUMBER TO PRINT A PARTICULAR ALGORITHM
        let algNumber = Int(comment.prefix(2)) ?? 0

        if doPrint || algNumber == algToPrint {
            print("🍎 [\(oldStr)] -> [\(newStr)]  \(comment)")
            // Debug Trap
        }
        dictDescKeyAlgorithm[comment, default: 0] += 1
        return newStr
    }
    return oldStr
}//end func

/*
 Regular Expressions - RegEx

 Special Characters      * ? + [ ( ) { } ^ $ | \ . /

 Character Classes
 \b    Word boundary, if outside of a [Set]. BACKSPACE, if within a [Set].   \B    Not word boundary.
 \s    White space character.    \S    Non-white space character.
 \d    Digit character.          \D    Non-digit character.
 \w    Word character.           \W    Non-word character.

 Operators
 |       Or
 *       0 or more times. Match as many times as possible.
 +       1 or more times. Match as many times as possible.
 ?       0 or 1 times. Prefer 1.
 *?      0 or more times. Match as few times as possible.
 +?      1 or more times. Match as few times as possible.
 ??      0 or 1 times. Prefer 0.
 *+      0 or more times. Match as many times as possible when first encountered, do not retry with fewer even if overall match fails (Possessive Match).
 ++      1 or more times. Possessive match.
 ?+      0 or 1 times. Possessive match.
 {n} {n}? {n}+    Exactly n times.
 {n,}    n or more.
 {n,}?   At least n times, but no more than required for an overall pattern match.
 {n,m}   Between n and m times.
 {n,m}?  Between n and m times. Match as few times as possible, but not less than n.

 Anchors
 ^    Beginning of a line.
 $    End of a line.
 .    Any character.
 \    Escape following character.

 Groups and Ranges
 (...)    Capturing parentheses (capturing group).
 (?:...)  Non-capturing parentheses. Matches but doesn’t capture. Somewhat more efficient than capturing parentheses.
 (?!...)  Negative look-ahead. True if the parenthesized pattern does not match at the current input position.
 [...]    Any one character in the set.
 [^...]   Negated set. Not any one in the set.

  */
