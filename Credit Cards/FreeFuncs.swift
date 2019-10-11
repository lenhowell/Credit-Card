//
//  FreeFuncs.swift
//  Credit Cards
//
//  Created by George Bauer on 8/9/19.
//  Copyright © 2019 George Bauer. All rights reserved.
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
    if let str = pasteboard.string(forType: NSPasteboard.PasteboardType.string) {
        return str
    }
    return ""
}

public enum FormatType {
    case None, Number, Percent, Dollar, NoDollar, Comma
}
//---- formatCell -
public func formatCell(_ value: Double, formatType: FormatType, digits: Int,
                       doReplaceZero: Bool = true, zeroCell: String = "") -> String {
    if doReplaceZero && value == 0.0 {
        return ""
    }
    var format = ""
    switch formatType {
    case .Number:                                       // -1234.5
        format = "%.\(digits)f"   // "%.2f%" -> "#.00"
        return String(format: format, value)
    case .Percent:                                      // -123.4%
        format = "%.\(digits)f%%" // "%.1f%%" -> "#.0%"
        return String(format: format, value*100)
    case .Dollar:                                       // ($1,234.5)
        let formatter = NumberFormatter()
        formatter.numberStyle  = .currencyAccounting
        formatter.maximumFractionDigits = digits
        return formatter.string(for: value) ?? "?Dollar?"
    case .NoDollar:                                     // (1,234.5)
        let formatter = NumberFormatter()
        formatter.numberStyle  = .currencyAccounting
        formatter.maximumFractionDigits = digits
        let str = formatter.string(for: value) ?? "$?Dollar?"
        let str2 = str.replacingOccurrences(of: "$", with: "")
        return str2
    case .Comma:                                        // -1,234.5
        let formatter = NumberFormatter()
        formatter.numberStyle  = .decimal
        formatter.maximumFractionDigits = digits
        return formatter.string(for: value) ?? "?Comma?"
    default:
        return "\(value)"                               // -1234.567
    }

}//end func

//---- compareTextNum - compares 2 strings either numerically or case-insensitive.
public func compareTextNum(lft: String, rgt: String, ascending: Bool) -> Bool {
    let lStripped = sortStr(lft)
    let rStripped = sortStr(rgt)
    if Double(lStripped) == nil || Double(rStripped) == nil {
        if ascending  && lft < rgt { return true }
        if !ascending && lft > rgt { return true }
        return false
    }
    let lVal = Double(lStripped) ?? 0
    let rVal = Double(rStripped) ?? 0
    if ascending  && lVal < rVal { return true }
    if !ascending && lVal > rVal { return true }
    return false
}

//---- sortStr - returns a string that is sortable, either numerically or case-insensitive.
public func sortStr(_ str: String) -> String {
    var txt = str
    txt = txt.replacingOccurrences(of: "$", with: "")
    txt = txt.replacingOccurrences(of: "%", with: "")
    txt = txt.replacingOccurrences(of: ",", with: "").trim
    if txt.hasPrefix("(") && txt.hasSuffix(")") { txt = "-" + String(txt.dropFirst().dropLast()) }
    return txt.uppercased()
}


//MARK:- Date Extensions

extension Date {

    //---- Date.toString
    ///Convert to String using formats like "MM/dd/yyyy hh:mm:ss"
    /// - parameter format: String like "MM/dd/yyyy hh:mm:ss"
    func toString(_ format: String) -> String {
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

