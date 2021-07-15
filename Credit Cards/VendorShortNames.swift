//
//  VendorShortNames.swift
//  Credit Cards
//
//  Created by George Bauer on 9/21/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Cocoa

//MARK:- Globals for UserInputs
//TODO: Change to use segue & eliminate globals
// Parameters for UserInputs
var usrVendrShortName = ""
var usrVendrLongName = ""
// Returns from UserInputs
var usrVendrPrefix = ""
var usrVendrFullDescKey = ""

//MARK:- findTruncatedDescs
//---- findTruncatedDescs - In "VendorCategoryLookup.txt" find multiple names that are similar
func findTruncatedDescs(vendorNameDescs: [String]) -> Bool {
    // Sort by length - longest to shortest
    let vendorCatLookupSortedByLength = vendorNameDescs.sorted(by: {$0.count > $1.count})
    guard let minLen = vendorCatLookupSortedByLength.last?.count else {
        print("\n😡 VendorShortNames#\(#line): No vendorNameDescs found.")
        return false      // empty
    }

    outerLoop:
    for (idx, descLong) in vendorCatLookupSortedByLength.enumerated() {
        let longLen = descLong.count
        if longLen <= minLen {
            break   // There are no more entries shorter than this one.
        }
        for i in idx+1..<vendorCatLookupSortedByLength.count {
            let descShort = vendorCatLookupSortedByLength[i]
            let shortLen  = descShort.count
            if descLong.prefix(shortLen) == descShort {
                let truncLong = descLong.dropFirst(shortLen)
                let match = findPrefixMatch(name: descShort, dictShortNames: gDictVendorShortNames)

                if match.fullDescKey.isEmpty {
                    if (shortLen > 9 || truncLong.hasPrefix(" ")) {
                        //print("😡 VendorShortNames#\(#line): Possible dupe \"\(descShort)\"(\(shortLen)) is part of \"\(descLong)\"(\(longLen))")
                        let returnVal = showUserInputShortNameForm(shortName: descShort, longName: descLong)
                        if returnVal == .OK {           // OK: Add (prefix,descKey) to list
                            gDictVendorShortNames[usrVendrPrefix] = usrVendrFullDescKey //move to showUserInputShortNameForm?
                        } else if returnVal == .cancel {// Ignore: Do nothing
                            // do nothing
                        } else if returnVal == .stop {  // Abort, but save the results so far
                            break outerLoop
                        } else if returnVal == .abort { // Abort, do not save
                            return false
                        }
                    } else {
                        print("😡 VendorShortNames#\(#line): Too short for a dupe \(descShort) (\(shortLen)) is part of \(descLong) (\(longLen))")

                    }
                } else {
                    print("😡 VendorShortNames#\(#line): \(descShort) already in file as \(match.fullDescKey)")
                    //
                }

            } else  if descLong.prefix(9) == descShort.prefix(9) {
                print("😡 VendorShortNames#\(#line): Not a dupe, but same at 9 \"\(descShort)\"(\(shortLen)) is part of \"\(descLong)\"(\(longLen))")
                //
            }

        }//next i
    }//next desc
    print("\n😋 VendorShortNames#\(#line) gDictVendorShortNames.count = \(gDictVendorShortNames.count) ")
    for (key,val) in gDictVendorShortNames.sorted(by: <) {
        print("\(val.PadRight(23, truncate: false)) <==    \(key)")
    }
    return true
}//end func findTruncatedDescs

//MARK:- Show Input-ShortName Form
//---- showUserInputShortNameForm - Present UserInputShortName Window Controller
//TODO: Change to use segue & eliminate globals
func showUserInputShortNameForm(shortName: String, longName: String) -> NSApplication.ModalResponse {
    usrVendrShortName = shortName
    usrVendrLongName = longName
    let storyBoard = NSStoryboard(name: "Main", bundle: nil)
    var returnVal: NSApplication.ModalResponse = .continue

    guard let userInputWindowController = storyBoard.instantiateController(withIdentifier: "UserInputShortNameWC") as? NSWindowController else {
        let msg = "Unable to open UserInputShortNameWC Window"
        handleError(codeFile: "VendorShortNames", codeLineNum: #line, type: .codeError, action: .alertAndDisplay, errorMsg: msg)
        return returnVal
    }

    if let userInputWindow = userInputWindowController.window {
        //let userVC = storyBoard.instantiateController(withIdentifier: "UserInput") as! UserInputVC

        let application = NSApplication.shared
        returnVal = application.runModal(for: userInputWindow) // <==  UserInputVC

        userInputWindow.close()                     // Return here from userInputWindow
    } else {
        handleError(codeFile: "VendorShortNames", codeLineNum: #line, type: .codeError, action: .alertAndDisplay, errorMsg: "Could not open User-Input-ShortName window.")
    }//end if let
    return returnVal
}//end func

//MARK:- findPrefixMatch
//---- findPrefixMatch - Go through the ShortName hash to find a match
func findPrefixMatch(name: String, dictShortNames: [String: String]) -> (prefix: String, fullDescKey: String) {
    for (prefix, fullDescKey) in dictShortNames {
        // There may be a space at the end of ShortName
        if name.hasPrefix(prefix) || name == prefix.trim {
            return (prefix, fullDescKey)
        }
    }
    return ("","")
}
