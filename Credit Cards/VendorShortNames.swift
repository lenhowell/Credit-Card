//
//  VendorShortNames.swift
//  Credit Cards
//
//  Created by George Bauer on 9/21/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Cocoa

//MARK:- Globals for UserInputs
// Parameters for UserInputs
var usrVendrShortName = ""
var usrVendrLongName = ""
// Returns from UserInputs
var usrVendrPrefix = ""
var usrVendrFullDescKey = ""

//MARK:- Vendor Description funcs
//----findTruncatedDescs - In "VendorCategoryLookup.txt" find multiple names that are similar
func findTruncatedDescs(vendorNameDescs: [String], dictShortNames: inout [String: String]) -> Bool {
    // Sort by length - longest to shortest
    let VendorCatLookupSortedByLength = vendorNameDescs.sorted(by: {$0.count > $1.count})
    guard let minLen = VendorCatLookupSortedByLength.last?.count else {
        print("\nFreeFuncs#\(#line) findTruncatedDescs:  No vendorNameDescs found.")
        return false      // empty
    }

    outerLoop:
    for (idx, descLong) in VendorCatLookupSortedByLength.enumerated() {
        let longLen = descLong.count
        if longLen <= minLen { break }
        for i in idx+1..<VendorCatLookupSortedByLength.count {
            let descShort = VendorCatLookupSortedByLength[i]
            let shortLen  = descShort.count
            if descLong.prefix(shortLen) == descShort {
                let truncLong = descLong.dropFirst(shortLen)
                let match = findPrefixMatch(name: descShort, dictShortNames: dictShortNames)
                if (shortLen > 9 || truncLong.hasPrefix(" ")) && match.fullDescKey.isEmpty {
                    //print("Possible dupe \"\(descShort)\"(\(shortLen)) is part of \"\(descLong)\"(\(longLen))")
                    let returnVal = showUserInputShortNameForm(shortName: descShort, longName: descLong)
                    if returnVal == .OK {
                        dictShortNames[usrVendrPrefix] = usrVendrFullDescKey
                    } else if returnVal == .stop {
                        break outerLoop
                    } else if returnVal == .abort {
                        return false
                    }
                } else {
                    //print("Too short for a dupe \(descShort) (\(shortLen)) is part of \(descLong) (\(longLen))")
                }
            } else  if descLong.prefix(9) == descShort.prefix(9) {
                //print("Not a dupe, but same at 9 \"\(descShort)\"(\(shortLen)) is part of \"\(descLong)\"(\(longLen))")
            }
        }//next i
    }//next desc
    print("\nFreeFuncs#\(#line) findTruncatedDescs: dictShortNames.count = \(dictShortNames.count) ")
    for (key,val) in dictShortNames.sorted(by: <) {
        print("\(val.PadRight(23, truncate: false)) <==    \(key)")
    }
    return true
}//end func findTruncatedDescs


func showUserInputShortNameForm(shortName: String, longName: String) -> NSApplication.ModalResponse {
    usrVendrShortName = shortName
    usrVendrLongName = longName
    let storyBoard = NSStoryboard(name: "Main", bundle: nil)
    let UserInputWindowController = storyBoard.instantiateController(withIdentifier: "UserInputShortNameWC") as! NSWindowController
    var returnVal: NSApplication.ModalResponse = .continue
    if let userInputWindow = UserInputWindowController.window {
        //let userVC = storyBoard.instantiateController(withIdentifier: "UserInput") as! UserInputVC

        let application = NSApplication.shared
        returnVal = application.runModal(for: userInputWindow) // <==  UserInputVC

        userInputWindow.close()                     // Return here from userInputWindow
    } else {
        handleError(codeFile: "FreeFuncs", codeLineNum: #line, type: .codeError, action: .alertAndDisplay, errorMsg: "Could not open User-Input-ShortName window.")
    }//end if let
    return returnVal
}//end func

func findPrefixMatch(name: String, dictShortNames: [String: String]) -> (prefix: String, fullDescKey: String) {
    for (prefix, fullDescKey) in dictShortNames {
        if name.hasPrefix(prefix) || name == prefix.trim {
            return (prefix, fullDescKey)
        }
    }
    return ("","")
}
