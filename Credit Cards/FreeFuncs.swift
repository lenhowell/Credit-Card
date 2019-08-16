//
//  FreeFuncs.swift
//  Credit Cards
//
//  Created by Lenard Howell on 8/9/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Cocoa    // Cocoa is needed to recognize NSPasteboard

//MARK:- General purpose funcs

public func copyStringToClipBoard(textToCopy: String) {
    let pasteBoard = NSPasteboard.general
    pasteBoard.clearContents()
    pasteBoard.setString(textToCopy, forType: NSPasteboard.PasteboardType.string)
}

public func getStringFromClipBoard() -> String {
    let pasteboard = NSPasteboard.general
    var string = ""
    if let str = pasteboard.string(forType: NSPasteboard.PasteboardType.string) {
        string = str
    }
    pasteboard.clearContents()
    return string
}

public func getTransFileList(transDirURL: URL) -> [URL] {
    print("\nFreeFuncs.getTransFileList \(#line)")
    do {
        let fileURLs = try FileManager.default.contentsOfDirectory(at: transDirURL, includingPropertiesForKeys: [], options:  [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
        let csvURLs = fileURLs.filter{ $0.pathExtension.lowercased() == "csv" }
        let transURLs = csvURLs.filter{ $0.lastPathComponent.components(separatedBy: "-")[0].count <= 6 }
        print("\(transURLs.count) Transaction Files found.")
        print(transURLs)
        print()
        return transURLs
    } catch {
        print(error)
    }
    return []
}

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
 */
public func makeDescKey(from desc: String) -> String {

    let descKeysuppressionList = " \";/.#*-"
    let descKeyLength          = 10     // 16->195 14->191 12->187 11->180 10->179 9->
    //let descKeySeparator       = " "

    // Eliminate apostrophies Allen's => Allens
    var descKeyLong = desc.replacingOccurrences(of: "['`]", with: "", options: .regularExpression, range: nil)

    // Truncate at "xx..."
    let posX = descKeyLong.firstIntIndexOf("xx")
    if posX >= 0 {
        //print("✅", posX, descKeyLong)
        if posX >= 2 {
            descKeyLong = String(descKeyLong.prefix(posX))
        }
    }

    // Truncate at "#..."
    let posHash = descKeyLong.firstIntIndexOf("#")
    if posHash >= 0 {
        //print("✅", posHash, descKeyLong)
        if posHash >= 2 {
            descKeyLong = String(descKeyLong.prefix(posHash))
        }
    }

    // Truncate at "*..." if it is chr #7 or greater
    let posStar = descKeyLong.firstIntIndexOf("*")
    if posStar >= 0 {
        //print("✅", posStar, descKeyLong)
        if posStar >= 6 {
            descKeyLong = String(descKeyLong.prefix(posStar))
        }
    }

    // Replace chars in suppression list with space
    descKeyLong = descKeyLong.replacingOccurrences(of: "["+descKeysuppressionList+"]", with: " ", options: .regularExpression, range: nil)

    // Remove Double Space
    descKeyLong = descKeyLong.replacingOccurrences(of: "  ", with: " ")

    let descKey = String(descKeyLong.prefix(descKeyLength)).trim.uppercased()         // Truncate & uppercase

    return descKey
}

//MARK:- Date Extensions
extension Date {

    //---- Date.ToString
    ///Convert to String using formats like "MM/dd/yyyy hh:mm:ss"
    /// - parameter format: String like "MM/dd/yyyy hh:mm:ss"
    func ToString(_ format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        let out = dateFormatter.string(from: self)
        return out
    }

    //---- Date.getComponents -
    ///Get DateComponents .year, .month, .day, .hour, .minute, .second, calendar, .timeZone, .weekday, .weekdayOrdinal, .quarter, .weekOfMonth, .weekOfYear
    func getComponents() -> DateComponents {
        let unitFlags:Set<Calendar.Component> = [ .year, .month, .day, .hour, .minute, .second, .calendar, .timeZone, .weekday, .weekdayOrdinal, .quarter, .weekOfMonth, .weekOfYear ]
        let dateComponents = Calendar.current.dateComponents(unitFlags, from: self)
        return dateComponents
    }

}//end Date extension

