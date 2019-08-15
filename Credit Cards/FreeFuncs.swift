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

// Uses Globals: descKeysuppressionList, descKeyLength, descKeySeparator
public func makeDescKey(from desc: String) -> String {
    let descKeyLong = desc.replacingOccurrences(of: "["+descKeysuppressionList+"]", with: "", options: .regularExpression, range: nil)
    let descKey = String(descKeyLong.prefix(descKeyLength))         // Truncate
    return descKey
}
