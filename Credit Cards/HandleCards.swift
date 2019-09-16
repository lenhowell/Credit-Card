//
//  HandleCards.swift
//  Credit Cards
//
//  Created by Lenard Howell on 8/9/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Cocoa    // needed to access NSStoryboard & NSWindowController for segue

//MARK:- Globals for UserInputs
// Parameters for UserInputs
var usrLineItem          = LineItem()
var usrCatItemFromVendor = CategoryItem()
var usrCatItemFromTran   = CategoryItem()
var usrCatItemPrefered   = CategoryItem()
// Returns from UserInputs
var usrCatItemReturned  = CategoryItem()
var usrFixVendor        = true
var usrIgnoreVendors    = [String: Int]()


//MARK:---- handleCards - 25-85 = 60-lines

func handleCards(fileName: String, cardType: String, cardArray: [String], dictDescripKeyWords: [String: String]) -> [LineItem] {
    let cardArrayCount = cardArray.count
    var lineItemArray = [LineItem]()                // Create Array variable(lineItemArray) Type lineItem.
    var lineNum = 0

    //MARK: Read Header
    // Derive a Dictionary of Column Numbers from header
    var headerLine = ""
    var headers = [String]()
    while lineNum < cardArrayCount {
        headerLine = cardArray[lineNum]
        lineNum += 1
        let components = headerLine.components(separatedBy: ",")
        if components.count >= 3  {
            headers = components
            break
        }
    }

    if headers.isEmpty {
        handleError(codeFile: "HandleCards", codeLineNum: #line, type: .dataError, action: .alertAndDisplay,  fileName: fileName, dataLineNum: lineNum, lineText: "", errorMsg: "Headers not found.")
        return lineItemArray
    }

    let dictColNums = makeDictColNums(headers: headers)

    let hasCatHeader: Bool
    if dictColNums["CATE"] == nil {
        hasCatHeader = false
        let msg = "No \"Catagory\" in Headers"
        handleError(codeFile: "HandleCards", codeLineNum: #line, type: .dataWarning, action: .display, fileName: fileName, dataLineNum: lineNum, lineText: headerLine, errorMsg: msg)
    } else {
        hasCatHeader = true
    }

    //MARK: Read Transactions

    while lineNum < cardArrayCount {
        let tran = cardArray[lineNum]
        lineNum += 1
        if tran.trim.count < 16 { continue }    // Blank line or ",,,,,,,,,,,"

        Stats.processedCount += 1
        let lineItem = makeLineItem(fromTransFileLine: tran, dictColNums: dictColNums, dictDescripKeyWords: dictDescripKeyWords, cardType: cardType, hasCatHeader: hasCatHeader, fileName: fileName, lineNum: lineNum)

        if !lineItem.desc.isEmpty || !lineItem.postDate.isEmpty || lineItem.debit != 0  || lineItem.credit != 0 {
            // Check for duplicate from another file
            if dictTranDupes[lineItem] == nil || dictTranDupes[lineItem] == fileName {
                dictTranDupes[lineItem] = fileName      // mark for dupes check
                lineItemArray.append(lineItem)          // Add new output Record
            } else {
                let msg = "Duplicate transaction"
                handleError(codeFile: "HandleCards", codeLineNum: #line, type: .dataWarning, action: .alertAndDisplay, fileName: fileName, dataLineNum: lineNum, lineText: tran, errorMsg: msg)
            }
        } else {
            // debug trap - empty line
        }
    }//end line-by-line loop

    return lineItemArray
}//end func handleCards

//MARK:---- makeLineItem - 89-163 = 74-lines
// uses Global Vars: dictCatLookupByVendor(I/O), Stats(I/O)
internal func makeLineItem(fromTransFileLine: String, dictColNums: [String: Int], dictDescripKeyWords: [String: String], cardType: String, hasCatHeader: Bool, fileName: String, lineNum: Int) -> LineItem {

    var lineItem = LineItem(fromTransFileLine: fromTransFileLine, dictColNums: dictColNums, fileName: fileName, lineNum: lineNum)
    lineItem.cardType = cardType

    // Check for Modified Transaction
    let modTranKey = fromTransFileLine.trim
    if let modTrans = dictModifiedTrans[modTranKey] {
        lineItem.genCat = modTrans.category             // Here if found this transaction in MyModifiedTransactions.txt
        lineItem.catSource = modTrans.source
        Stats.userModTransUsed += 1
        return lineItem                                 // Use the User-Modified genCat & catSource without looking further
    }

    var catItemFromVendor   = CategoryItem()
    var catItemPrefered     = CategoryItem()
    var isClearWinner       = false
    var catFromTran     = dictMyCatAliases[lineItem.rawCat] ?? "?" + lineItem.rawCat
    var catItemFromTran = CategoryItem(category: catFromTran, source: cardType)

    let descKey = makeDescKey(from: lineItem.desc, dictDescripKeyWords: dictDescripKeyWords, fileName: fileName)
    lineItem.descKey = descKey
    if !descKey.isEmpty {
        if let cV = dictCatLookupByVendor[descKey] {
            catItemFromVendor = cV                  // ------ Here if Lookup by Vendor was successful
            (catItemPrefered, isClearWinner) = pickTheBestCat(catItemVendor: catItemFromVendor, catItemTransa: catItemFromTran)
            lineItem.genCat = catItemPrefered.category    // Generated Cat is the prefered one
            lineItem.catSource = catItemPrefered.source
            //print("\(#line) Cat for \(descKey) = \(catItemFromVendor.category);  TransCat = \(catFromLineItem)  Chose: \(catItemPrefered.category)")
            Stats.successfulLookupCount += 1
            uniqueCategoryCounts[descKey, default: 0] += 1

        } else {                   // ------ Here if NOT found in Category-Lookup-by-Vendor Dictionary
            findShorterDescKey(descKey) // Have we already found a truncated (shorter) version of descKey?
            let source = cardType
            // If Transaction-Line has a Category, put it in the Vendor file.

            if catFromTran.count < 3 { catFromTran = "" }

            if let catTran = dictMyCatAliases[catFromTran] {
                catFromTran = catTran
                isClearWinner = !catFromTran.hasPrefix("?") // if no "?", we have a winner
            } else {
                print("HandleCards#\(#line): Unknown Category: \"\(lineItem.rawCat)\" from \(descKey)")
                isClearWinner = false
            }
            catItemFromTran = CategoryItem(category: catFromTran, source: source)
            catItemPrefered = usrCatItemFromTran
            lineItem.genCat = catFromTran
            if gLearnMode {
                dictCatLookupByVendor[descKey] = CategoryItem(category: catFromTran, source: source) //Do Actual Insert

                Stats.addedCatCount += 1
            } else {
                Stats.descWithNoCat += 1
            }
            // print("Category that was inserted = Key==> \(key) Value ==> \(self.rawCat) Source ==> \(source)")
        }//end if NOT found in Category-Lookup-by-Vendor Dictionary


        if gUserInputMode && !isClearWinner && usrIgnoreVendors[lineItem.descKey] == nil {
            showUserInputForm(lineItem: lineItem, catItemFromVendor: catItemFromVendor, catItemFromTran: catItemFromTran, catItemPrefered: catItemPrefered)
            catItemPrefered = usrCatItemReturned
        }
        if gLearnMode && catItemPrefered != catItemFromVendor {
            dictCatLookupByVendor[descKey] = catItemPrefered //Do Actual Insert
            Stats.changedCatCount += 1
        }
    } else {
        // debug trap
    }//endif descKey empty or not

    return lineItem
}//end func makeLineItem

func showUserInputForm(lineItem: LineItem, catItemFromVendor: CategoryItem, catItemFromTran: CategoryItem, catItemPrefered: CategoryItem) -> CategoryItem {
    usrLineItem = lineItem
    usrCatItemFromVendor = catItemFromVendor
    usrCatItemFromTran   = catItemFromTran
    usrCatItemPrefered   = catItemPrefered
    let storyBoard = NSStoryboard(name: "Main", bundle: nil)
    let UserInputWindowController = storyBoard.instantiateController(withIdentifier: "UserInputWindowController") as! NSWindowController
    if let userInputWindow = UserInputWindowController.window {
        //let userVC = storyBoard.instantiateController(withIdentifier: "UserInput") as! UserInputVC

        let application = NSApplication.shared
        let returnVal = application.runModal(for: userInputWindow) // <==

        userInputWindow.close()                     // Return here from userInputWindow
        if returnVal == .abort { exit(101) }
        if returnVal == .OK {
            if usrFixVendor && gLearnMode {
                if lineItem.descKey.trim.isEmpty {
                    // debug trap
                }
                dictCatLookupByVendor[lineItem.descKey] = usrCatItemReturned
                Stats.changedCatCount += 1
            } else {
                let transKey = lineItem.transText
                dictModifiedTrans[transKey] = usrCatItemReturned
            }
        }
    } else {
        handleError(codeFile: "HandleCards", codeLineNum: #line, type: .codeError, action: .alertAndDisplay, errorMsg: "Could not open User-Input window.")
    }//end if let
    return catItemPrefered
}//end func

//MARK:---- makeDictColNums - 200-218 = 18-lines

//---- makeDictColNums - Infer which columns have the relevant data based in the Header row. Returns dictColNums
internal func makeDictColNums(headers: [String]) -> [String: Int] {
    var dictColNums = [String: Int]()
    for colNum in 0..<headers.count {
        let rawKey = headers[colNum].uppercased().trim.replacingOccurrences(of: "\"", with: "")
        let key: String
        if rawKey == "DATE" {                                                   // "Date"
            key = "TRAN"
        } else if rawKey.hasPrefix("ORIG") && rawKey.hasSuffix("DESCRIPTION") { // "Original Description"
            key = "DESC"
        } else if rawKey.hasPrefix("MERCH") && rawKey.hasSuffix("CATEGORY") {   // "Merchant Category"
            key = "CATE"
        } else {
            key = String(rawKey.replacingOccurrences(of: "\"", with: "").prefix(4))
        }
        dictColNums[key] = colNum
    }//next colNum

    return dictColNums
}//end func

internal func findShorterDescKey(_ descKey: String) {
    let descKeyCount = descKey.count
    for (key, value) in dictCatLookupByVendor {
        let keyCount = key.count
        if descKeyCount < keyCount && descKeyCount > 3 {
            if key.prefix(descKeyCount) == descKey {
                print("Found \(descKey) (\(descKey.count)) as subset of \(key) (\(keyCount)) : \(value)")
                //
            }
        } else if descKeyCount > keyCount && keyCount > 3 {
            if descKey.prefix(keyCount) == key {
                print("Found \(descKey) (\(descKey.count)) as superset of \(key) (\(keyCount)) : \(value)")
                //
            }
        }
    }//next key,value
}//end func

//TODO: Prioritize prefered cards
//TODO: Add Unit Test
//---- pickTheBestCat - Returns (catItemPrefered, isClearWinner) tuple.
internal func pickTheBestCat(catItemVendor: CategoryItem, catItemTransa: CategoryItem) -> (CategoryItem, Bool) {
    let weak    = false
    let strong  = true
    let catVendor = catItemVendor.category
    let catTransa = catItemTransa.category
    if catItemVendor.source.hasPrefix("$")                  { return (catItemVendor, strong) }  // User modified
    let catVendStrong = !catVendor.isEmpty && !catVendor.hasPrefix("?") && !catVendor.contains("Unkno") && !catVendor.contains("Merch")
    let catTranStrong = !catTransa.isEmpty && !catTransa.hasPrefix("?") && !catTransa.contains("Unkno") && !catTransa.contains("Merch")

    if (catVendor == catTransa)                             { return (catItemTransa, catTranStrong) } // Both the same.

    if catVendStrong && catTranStrong                       { return (catItemTransa, weak) }    // tie: both strong
    if !catVendStrong && catTranStrong                      { return (catItemTransa, strong) }  // Transaction strong
    if catVendStrong && !catTranStrong                      { return (catItemVendor, strong) }  // Vendor strong

    if catVendor.isEmpty || catVendor == "?"                { return (catItemTransa, weak) }    // catVendor missing
    if catTransa.isEmpty || catTransa == "?"                { return (catItemVendor, weak) }    // catTransa missing
    if catVendor.hasPrefix("?") && !catTransa.hasPrefix("?") { return (catItemTransa, weak) }   // use the cat with no "?"
    if catTransa.hasPrefix("?") && !catVendor.hasPrefix("?") { return (catItemVendor, weak) }   //      "
    if catTransa.contains("Unkno")                          { return (catItemVendor, weak) }    // "Unknown"
    if catVendor.contains("Unkno")                          { return (catItemTransa, weak) }    //      "
    if catTransa.contains("Merch")                          { return (catItemVendor, weak) }    // "Merchandise" is weak
    if catVendor.contains("Merch")                          { return (catItemTransa, weak) }    //      "
    return (catItemTransa, weak)
}
