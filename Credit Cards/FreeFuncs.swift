//
//  FreeFuncs.swift
//  Credit Cards
//
//  Created by George Bauer on 8/9/19.
//  Copyright © 2019-2021 George Bauer. All rights reserved.
//

import Cocoa    // Cocoa is needed to recognize NSPasteboard

//MARK: - General purpose funcs

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

//---- sendSummaryToClipBoard - Called from SummaryTable
public func sendSummaryToClipBoard(tableDicts: [[String : String]]) {
    // List of names from SummaryTable + "Other"
    let headers = ["Tax","Investment","Barbara","EveManbeck","AndrewWhitehill",
                   "Auto","Aviation","BeachCove","NorthBeachTower","Home","Travel","Merchandise",
                   "Cable/Internet","Healthcare","Charity","Phone","Food",
                   "Insurance","Computer","Entertainment","Professional","Income",
                   "Unknown","Other"]
    var headerDict = [String: String]()
    for header in headers {
        headerDict[header] = header
    }
    var catNet = [String: Double]()
    for tableDict in tableDicts {
        let str  = sortStr(tableDict[SummaryColID.netCredit] ?? "0")
        let val  = Double(str) ?? 0.0
        let name = tableDict[SummaryColID.name] ?? "Other"
        let cat  = headerDict[name] ?? "Other"
        if name == "Other" || cat == "Other" {
            print("👹 FreeFuncs#\(#line) \(SummaryColID.name) -> \(name) -> Other $\(val)")
        }
        catNet[cat, default: 0.0] += val
    }
    let line1 = "1stDate\tLastDate\t" + headers.joined(separator: "\t")
    var line2 = "\(Stats.firstDate)\t\(Stats.lastDate)\t"
    for name in headers {
        let val = catNet[name, default: 0.0]
        line2 += String(val) + "\t"
    }
    copyStringToClipBoard(textToCopy: line1 + "\n" + line2)
}

public enum FormatType {
    case none, number, percent, dollar, noDollar, comma
}
//---- formatCell -
public func formatCell(_ value: Double, formatType: FormatType, digits: Int,
                       doReplaceZero: Bool = true, zeroCell: String = "") -> String {
    if doReplaceZero && value == 0.0 {
        return ""
    }
    var format = ""
    switch formatType {
    case .number:                                       // -1234.5
        format = "%.\(digits)f"   // "%.2f%" -> "#.00"
        return String(format: format, value)
    case .percent:                                      // -123.4%
        format = "%.\(digits)f%%" // "%.1f%%" -> "#.0%"
        return String(format: format, value*100)
    case .dollar:                                       // ($1,234.5)
        let formatter = NumberFormatter()
        formatter.numberStyle  = .currencyAccounting
        formatter.maximumFractionDigits = digits
        return formatter.string(for: value) ?? "?Dollar?"
    case .noDollar:                                     // (1,234.5)
        let formatter = NumberFormatter()
        formatter.numberStyle  = .currencyAccounting
        formatter.maximumFractionDigits = digits
        let str = formatter.string(for: value) ?? "$?Dollar?"
        let str2 = str.replacingOccurrences(of: "$", with: "")
        return str2
    case .comma:                                        // -1,234.5
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

func dateDif(dateStr1: String, dateStr2: String) -> Int {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let date1 = dateFormatter.date(from: dateStr1) ?? Date.distantPast
    let date2 = dateFormatter.date(from: dateStr2) ?? Date.distantPast
    let interval = date2.timeIntervalSince(date1)
    let dblDiff = Double(interval) / (3600*24)
    let diff: Int
    if dblDiff >= 0 {
        diff = Int(dblDiff + 0.001)
    } else {
        diff = Int(dblDiff - 0.001)
    }
    return diff
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

//---- textToDbl - returns an optional Double from "(12,345.6)" or "15%" or "-$123", etc.
public func textToDbl(_ str: String) -> Double? {
    var txt = str.replacingOccurrences(of: "[$%,;]", with: "", options: .regularExpression, range: nil).trim
    if txt.isEmpty || txt == "-" { return 0 }
    if txt.hasPrefix("(") && txt.hasSuffix(")") { txt = "-" + String(txt.dropFirst().dropLast()) }
    return Double(txt)
}



//MARK: - Date Extensions

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

