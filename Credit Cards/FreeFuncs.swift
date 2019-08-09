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

//------ getContentsOf(directoryURL:)
///Get URLs for Contents Of DirectoryURL
/// - Parameter dirURL: DirectoryURL (URL)
/// - Returns:  Array of URLs
func getContentsOf(dirURL: URL) -> [URL] {
    do {
        let urls = try FileManager.default.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: [], options:  [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
        return urls
    } catch {
        return []
    }
}
