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

