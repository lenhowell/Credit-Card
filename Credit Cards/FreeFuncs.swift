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
