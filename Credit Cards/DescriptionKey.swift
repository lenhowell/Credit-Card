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
let descKeyLength          = 18   //         16->195 14->191 12->187 11->180 10->179 9->

/*
 "RACETRAC465"          "RACETRAC599"        ok to 8
 "APPLEBEES"            "APPLEBEES NEI"      ok to 9
 "SPEEDWAY X6462"       "SPEEDWAY X6757"     ok to 9
 "AMAZON COM"           "AMAZON COM AMZ"     ok to 10
 "MCDONALDS F3625"      "MCDONALDS F4902"    ok to 10
 "MCDONALDS F7973"      "MCDONALDS FX2025"   ok to 10
 "BOSTON MARKET 01"     "BOSTON MARKET 09"   ok to 14
 "GOLDEN CORRAL 08"     "GOLDEN CORRAL 26"   ok to 14
 "PROMO PRICING CR"     "PROMO PRICING DE"   ok to 14
 "INTEREST CHARGE"     "INTEREST CHARGED"    ok to 15

 "VERIZON WRL MY A"     "VERIZON WRLS P"
 "COUNTRY CORNER C"     "COUNTRY HOUSE RE"   needs 9 or 10
 "ORLANDO APOPKA A"     "ORLANDO CLEANERS"   needs 9 or 10

 SQ *SQ *FOREFLIGHT
 SQ *RETHREADS
 SQ *WAKEMANS WHITE
 SQ *THE ADVENTURE P
 SQ *UCBC BAKERY CAF
 SQU*SQ *GOLD STAR COAC

 TLF*CITY LINE FLORIST
 TST* WINDMILL TAVERN
 PHR*CONNECTICUTORTHOP
 PHR*ConnecticutOrthopaedi
 MTA*MNR STATION TIX
 BB *SAVE THE CHILDREN
 BB *SHRINERS HOSPITALS
 APL*APPLE ONLINE STORE
 APL*ITUNES.COM/BILL
 PSV* Momentum Alert
 PAY*THE BARNARD HOUSE BED
 OPC*CONNECTICUT DEPT REV
 SR *Stansberry Research
 Ref*Formulyst.com
 GLT*GOLF TAILOR
 SP * BLACKBOXDEALZ
 IPM*INVESTORPLACE MED
 EMS*TACGLASSES

 DROPBOX*6J696N7MMMSW   (7)
 SPRINT *WIRELESS       (7)
 OPC TAX*SERVICE FEE    (7)
 HEALTHY*BACK INSTITUTE (7)
 LIFELOC*STANDARD       (7)
 CLKBANK*COM_5GFZUFBM   (7)
 PAYPAL *TAJSBLUES02    (7)
 PAYPAL *DLM1130        (7)
 CLKBANK*ORGANIFI       (7)

 REVERSE EMS*TACGLASSES         (11)
 SECURITY CREDIT-EMS*TACGLASSES (19)
 REVERSE PAYPAL *DLM1130        (15)
 SECURITY CREDIT-PAYPAL *DLM1130 (23)

 FOOD BAZAAR #36
 APPLE STORE  #R102
 ZIPS #9
 TACO BELL#
 NH LIQUOR STORE #66

 */
public func makeDescKey(from desc: String, fileName: String = "") -> String {
    //let descKeysuppressionList = " \";_/,#*-"
    //let descKeyLength          = 18   //         16->195 14->191 12->187 11->180 10->179 9->
    //let descKeySeparator       = " "  // 30->479 16->437 14->406 12->377         10->353 9->
    // 30->397 20->381 18->375
    //                 18->361
    var descKeyLong = ""
    var key2 = ""

    // Eliminate apostrophies Allen's => Allens
    key2 = desc.replacingOccurrences(of: "['`]", with: "", options: .regularExpression, range: nil)
    descKeyLong = checkDif(newStr: key2, oldStr: desc, doPrint: false, comment: "Remove apostrophy")

    //    if desc.contains("PARKER") {
    //        print(desc)
    //        let x = 1
    //    }

    if desc.contains("MOTEL") {
        print("FreeFuncs \(#line) \(desc)") // Debug Trap
    }

    // Remove spaces around " & "
    key2 = descKeyLong.replacingOccurrences(of: " ?& ?", with: "&", options: .regularExpression, range: nil)
    descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "Fix \"&\" spaces")

    //  Change " AND " to "&"
    key2 = descKeyLong.replacingOccurrences(of: " +AND +", with: "&", options: .regularExpression, range: nil)
    descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "Fix \" AND \"")

    // Remove "SQU*", "SQ *", "APL*" ,from beginning of line.
    key2 = descKeyLong.replacingOccurrences(of: #"^...\*"#, with: "", options: .regularExpression, range: nil)
    descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "Remove \"SQU*\" etc.")

    // Remove 2nd "SQU*", "SQ *", "APL*" ,from beginning of line.
    key2 = descKeyLong.replacingOccurrences(of: #"^\w\w.\*"#, with: "", options: .regularExpression, range: nil)
    descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "Remove repeat \"SQU*\" etc.")

    // Truncate Line upon th following matches

    // Truncate at Phone Number [123-456-7890...] (must be done before removing "-")
    var regexp = #"\d+-\d+-\d+.*"#
    if let range = descKeyLong.range(of:regexp, options: .regularExpression) {
        key2 = descKeyLong.replacingCharacters(in: range, with: "").trim
        descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "Remove phone number")
    }

    // Truncate at bare Number(>=2 digits) [ #12...], [ 12...]
    regexp = #" #?\d\d.*"#
    if let range = descKeyLong.range(of:regexp, options: .regularExpression) {
        key2 = descKeyLong.replacingCharacters(in: range, with: "").trim
        //let result = descKeyLong[range]
        //print("[\(key2)] = [\(descKeyLong)] - [\(result)]")
        descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "Remove bare number")
    }

    // Truncate at  embedded Number(>=3 digits) [#123...] (must be done before removing "#")
    regexp = #"#\d\d\d.*"#
    if let range = descKeyLong.range(of:regexp, options: .regularExpression) {
        key2 = descKeyLong.replacingCharacters(in: range, with: "").trim
        //let result = descKeyLong[range]
        //print("[\(key2)] = [\(descKeyLong)] - [\(result)]")
        descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "Remove embedded number")
    }

    // Truncate at [ Fx123...] Spc 0orMore Caps 0orMore x's
    regexp = #" [A-Z]*x*\d\d+.*"#
    if let range = descKeyLong.range(of:regexp, options: .regularExpression) {
        key2 = descKeyLong.replacingCharacters(in: range, with: "").trim
        //let result = descKeyLong[range]
        //print("[\(key2)] = [\(descKeyLong)] - [\(result)]")
        descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "Remove [ Fx123]")
    }



    // Truncate at "xx..." (must be done before uppercasing or you will mess up "EXXON")
    let posX = descKeyLong.firstIntIndexOf("xx")
    if posX >= 0 {
        //print("✅ Got (xx) at pos \(posX) in \(descKeyLong)")
        if posX >= 2 {
            key2 = String(descKeyLong.prefix(posX))
            descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "Remove \"xxx...\"")
        } else {
            //let x=1 // Debug Trap
        }
    }




    // APPLE STORE  #R102  (# at 13)
    // Truncate at "#..."
    let posHash = descKeyLong.firstIntIndexOf("#")
    if posHash >= 0 {
        //print("✅ Got (#) at pos \(posHash) in \(descKeyLong)")
        if posHash >= 2 {
            key2 = String(descKeyLong.prefix(posHash))
            descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "Remove \"#...\"")
        } else {
            //let x=1 // Debug Trap
        }
    }

    // VZWRLSS*APOCC VISN     (7)
    // Truncate at "*..." if it is chr #7 or greater
    let posStar = descKeyLong.firstIntIndexOf("*")
    if posStar >= 0 {
        //print("✅ Got (*) at pos \(posStar) in \(descKeyLong)")
        if posStar >= 6 {
            key2 = String(descKeyLong.prefix(posStar))
            descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "Remove \"*...\"")
        } else {
            //let x=1 // Debug Trap
        }
    }


    // Replace chars in suppression list with spaces
    descKeyLong = descKeyLong.replacingOccurrences(of: "["+descKeysuppressionList+"]", with: " ", options: .regularExpression, range: nil)

    if descKeyLong.isEmpty { return "" }

    if descKeyLong[descKeyLong.count-1].isNumber {
        descKeyLong = stripTrailingNumber(descKeyLong, fileName: fileName)
    }
    if descKeyLong[descKeyLong.count-1].isNumber {
        descKeyLong = stripTrailingNumber(descKeyLong, fileName: fileName)
    }

    descKeyLong = descKeyLong.trim

    // Remove Double Spaces
    key2 = descKeyLong.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression, range: nil)
    descKeyLong = checkDif(newStr: key2, oldStr: descKeyLong, doPrint: false, comment: "Squish double spaces")

    // Truncate & uppercase
    var descKey = String(descKeyLong.prefix(descKeyLength)).trim.uppercased()
    if descKey[descKey.count-1].isNumber {
        descKey = stripTrailingNumber(descKey, fileName: fileName)
    }

    return descKey
}//end func makeDescKey

/*
 🔹 C1V-09-02-2018 - 08-10-2019.csv STOP & SHOP
 🔹 C1V-10-01-2017 - 09-01-2018.csv VIOC
 🔹 CIT-07-2-2017 - 08-11-2019.csv HARRYS 888 212
 🔹 CIT-07-2-2017 - 08-11-2019.csv HSUS DM 866
 🔹 CIT-07-2-2017 - 08-11-2019.csv TW8442595572 844
 🔹 CIT-07-2-2017 - 08-11-2019.csv TW8442595572 844
 🔹 CIT-07-2-2017 - 08-11-2019.csv E ZPASS MA 877
 🔹 CIT-07-2-2017 - 08-11-2019.csv REVERSE SLEEP AID AVI 877 652
 🔹 CIT-07-2-2017 - 08-11-2019.csv REVERSE SLEEP AID AVI 877
 🔹 CIT-07-2-2017 - 08-11-2019.csv MEMBERSHIP FEE MAR 18 FEB
 🔹 CIT-07-2-2017 - 08-11-2019.csv NUCIFIC 888
 🔹 CIT-07-2-2017 - 08-11-2019.csv NUCIFIC 888
 🔹 CIT-07-2-2017 - 08-11-2019.csv STAR SHOWER 2


 VERIZON WRLS D2587-01          many good
 🔹 1  C1R-2019-08-03.csv VERIZON WRLS P2027 01 => VERIZON WRLS P2027
 PILOT_00337                    2 good
 🔹 1  C1V-09-02-2018 - 08-10-2019.csv PILOT 00337 => PILOT
 SUPER 8                         3 BAD
 🔹 1  C1V-10-01-2017 - 09-01-2018.csv SUPER 8 => SUPER
 STAR SHOWER 2 8448630169 NJ     1 ?
 🔹 1  CIT-07-2-2017 - 08-11-2019.csv STAR SHOWER 2 => STAR SHOWER

 */

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

 Squish double spaces (replace 1 or more spaces with a single space)
 str = str.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression, range: nil)


 let searchString = "Please contact us at <a href=\"tel:8882223434\" ><font color=\"#003871\"><b> 888.222.3434 </b></font></a> for assistance"
 let regexp = "\\d+(\\.\\d+)+"       //  \d+(\.\d+)+    1 or more digits followed by 1 or more of (dot followed by 1 or more digits)
 if let range = searchString.range(of:regexp, options: .regularExpression) {
 let result = searchString[range]
 print(result) // <---- prints "888.222.3434"
 }


 */

// if has space starting at end, if num start counting back til space, if got space truncate
// if not space starting at end, if num start counting back til space, if got Lettr truncate
internal func stripTrailingNumber(_ keyIn: String, fileName: String = "") -> String {
    var key = keyIn
    var key2 = key

    // Replace (spc) (1 or more digits) (word boundry) with spc
    key2 = key.replacingOccurrences(of:  #" \d+\b"#, with: " ", options: .regularExpression, range: nil).trim
    if key2 != key {
        print("🔹 1 ",fileName, key, "=>" , key2)   // CIRCLE B 10 => CIRCLE B (# was too short)
        return key2.trim
    }

    if key.contains(" ") {      // has a space
        for index in (1..<key.count).reversed() {
            if key[index] == " " {
                key2 = String(key.prefix(index))
                break
            }
        }
        print("🔹 2 ",fileName, key, "=>" , key2)
        key = key2          // MCDONALDS F13620 => MCDONALDS  VIOC AE0034 => VIOC    (# starts with letters)
    } else {                // no space
        for index in stride(from: key.count-1, through: 1, by: -1) {
            if !key[index].isNumber {
                key2 = String(key.prefix(index+1))
                break
            }
        }
        print("🔹 3 ",fileName, key, "=>" , key2)
        key = key2                  // STP&SHPFUEL0663 => STP&SHPFUEL (no space between name & #)
    }
    return key.trim
}//end func stripTrailingNumber

func checkDif(newStr: String, oldStr: String, doPrint: Bool, comment: String) -> String {
    if oldStr != newStr {
        if doPrint {
            print("🍎 [\(oldStr)] -> [\(newStr)]  \(comment)")
            return newStr
        }
        return newStr
    }
    return oldStr
}
