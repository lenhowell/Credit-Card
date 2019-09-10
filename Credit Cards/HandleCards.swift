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


//MARK:---- handleCards - 13-63 = 50-lines

func handleCards(fileName: String, cardType: String, cardArray: [String]) -> [LineItem] {
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
        if tran.trim.isEmpty { continue }

        let lineItem = makeLineItem(fromTransFileLine: tran, dictColNums: dictColNums, cardType: cardType, hasCatHeader: hasCatHeader, fileName: fileName, lineNum: lineNum)

        if !lineItem.desc.isEmpty || !lineItem.postDate.isEmpty || lineItem.debit != 0  || lineItem.credit != 0 {
            // Check for duplicate from another file
            if dictTransactions[lineItem] == nil || dictTransactions[lineItem] == fileName {
                dictTransactions[lineItem] = fileName   // mark for dupes check
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

//MARK:---- makeLineItem - 68-108 = 40-lines
// uses Global Vars: dictCatLookupByVendor(I/O), Stats(I/O)
internal func makeLineItem(fromTransFileLine: String, dictColNums: [String: Int], cardType: String, hasCatHeader: Bool, fileName: String, lineNum: Int) -> LineItem {

    var lineItem = LineItem(fromTransFileLine: fromTransFileLine, dictColNums: dictColNums, fileName: fileName, lineNum: lineNum)
    lineItem.cardType = cardType

    var descKey = makeDescKey(from: lineItem.desc, fileName: fileName)
    lineItem.descKey = descKey
    var catItemFromVendor   = CategoryItem()
    var catItemPrefered     = CategoryItem()
    var isClearWinner       = false
    let catFromLineItem = dictMyCatAliases[lineItem.rawCat] ?? "?" + lineItem.rawCat
    let catItemFromTran = CategoryItem(category: catFromLineItem, source: cardType)

    // Check for Modified Transaction
    let modTranKey = fromTransFileLine.trim
    if let modTrans = dictModifiedTrans[modTranKey] {
        lineItem.genCat = modTrans.category
        lineItem.catSource = modTrans.source
        descKey = ""                            //Prevent further processing
    }

    if !descKey.isEmpty {
        if let cV = dictCatLookupByVendor[descKey] {
            catItemFromVendor = cV                  // Here if Lookup of KEY was successful
            lineItem.genCat = catItemFromVendor.category
            lineItem.catSource = catItemFromVendor.source

            //TODO: Implement Learning mode
            //TODO: Recognize "LOCKED" Vendors
            //if catItemFromVendor.category != catFromLineItem {
                (catItemPrefered, isClearWinner) = pickTheBestCat(catItemVendor: catItemFromVendor, catItemTransa: catItemFromTran)
                lineItem.genCat = catItemPrefered.category
                lineItem.catSource = catItemPrefered.source
                //print("\(#line) Cat for \(descKey) = \(catItemFromVendor.category);  TransCat = \(catFromLineItem)  Chose: \(catItemPrefered.category)")
            //}
            Stats.successfulLookupCount += 1
            uniqueCategoryCounts[descKey, default: 0] += 1

        } else {                   // Here if NOT found in Category-Lookup-by-Vendor Dictionary
            let source = cardType
            // If Transaction-Line has a Category, put it in the Vendor file.

            if hasCatHeader {
                if lineItem.rawCat.count >= 3 {
                    let myCatFromTran  = dictMyCatAliases[lineItem.rawCat] ?? "?" + lineItem.rawCat

                    if let catTran = dictMyCatAliases[myCatFromTran] {
                        usrCatItemFromTran = CategoryItem(category: catTran, source: cardType)
                        isClearWinner = true
                    } else {
                        print("HandleCards#\(#line): Unknown Category: \"\(myCatFromTran)\" from \(descKey)")
                        isClearWinner = false
                    }

                    dictCatLookupByVendor[descKey] = CategoryItem(category: myCatFromTran, source: source) //Do Actual Insert
                    Stats.addedCatCount += 1
                    // print("Category that was inserted = Key==> \(key) Value ==> \(self.rawCat) Source ==> \(source)")
                } else {
                    Stats.descWithNoCat += 1
                    handleError(codeFile: "HandleCards", codeLineNum: #line, type: .dataWarning, action: .printOnly, fileName: fileName, dataLineNum: lineNum, lineText: fromTransFileLine, errorMsg: "Raw Category too short to be legit: \"\(lineItem.rawCat)\"")
                }
            } else {
                Stats.descWithNoCat += 1
            }// hasCatHeader or not
        }

        if gUserInputMode && !isClearWinner && usrIgnoreVendors[lineItem.descKey] == nil {
            showUserInputForm(lineItem: lineItem, catItemFromVendor: catItemFromVendor, catItemFromTran: catItemFromTran, catItemPrefered: catItemPrefered)
        } else if gLearnMode && catItemPrefered != catItemFromVendor {
            dictCatLookupByVendor[descKey] = catItemPrefered //Do Actual Insert
            Stats.changedCatCount += 1
        }

    }//endif descKey empty

    Stats.processedCount += 1
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
        userInputWindow.close()
        if returnVal == .abort { exit(101) }
        if returnVal == .OK {
            if usrFixVendor {
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

//MARK:---- makeDictColNums - 112-130 = 18-lines

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

//TODO: Prioritize prefered cards
//---- pickTheBestCat - Returns
internal func pickTheBestCat(catItemVendor: CategoryItem, catItemTransa: CategoryItem) -> (CategoryItem, Bool) {
    let catVendor = catItemVendor.category
    let catTransa = catItemTransa.category
    if catItemVendor.source.hasPrefix("$")                  { return (catItemVendor, true) } // User modified
    let catVendStrong = !catVendor.isEmpty && !catVendor.hasPrefix("?") && !catVendor.contains("Unkno") && !catVendor.contains("Merch")
    let catTranStrong = !catTransa.isEmpty && !catTransa.hasPrefix("?") && !catTransa.contains("Unkno") && !catTransa.contains("Merch")

    if (catVendor == catTransa)                             { return (catItemTransa, catTranStrong) } // Both the same.

    if catVendStrong && catTranStrong                       { return (catItemVendor, false) }
    if !catVendStrong && catTranStrong                      { return (catItemTransa, true) }
    if catVendStrong && !catTranStrong                      { return (catItemVendor, true) }

    if catVendor.isEmpty || catVendor == "?"                { return (catItemTransa, false) } // catVendor missing
    if catTransa.isEmpty || catTransa == "?"                { return (catItemVendor, false) } // catTransa missing
    if catVendor.hasPrefix("?") && !catTransa.hasPrefix("?") { return (catItemTransa, false) } // use the cat with no "?"
    if catTransa.hasPrefix("?") && !catVendor.hasPrefix("?") { return (catItemVendor, false) } //      "
    if catTransa.contains("Unkno")                          { return (catItemVendor, false) } // "Unknown"
    if catVendor.contains("Unkno")                          { return (catItemTransa, false) } //      "
    if catTransa.contains("Merch")                          { return (catItemVendor, false) } // "Merchandise" is weak
    if catVendor.contains("Merch")                          { return (catItemTransa, false) } //      "
    return (catItemTransa,false)
}
