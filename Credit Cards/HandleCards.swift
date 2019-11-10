//
//  HandleCards.swift
//  Credit Cards
//
//  Created by Lenard Howell on 8/9/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Cocoa    // needed to access NSStoryboard & NSWindowController for segue

//MARK:- Globals for UserInputVendorCatForm
// Parameters for UserInputVendorCatForm
var usrLineItem          = LineItem()
var usrCatItemFromVendor = CategoryItem()
var usrCatItemFromTran   = CategoryItem()
var usrCatItemPrefered   = CategoryItem()
var usrBatchMode         = true
// Returns from UserInputVendorCatForm
var usrCatItemReturned  = CategoryItem()
var usrFixVendor        = true
var usrIgnoreVendors    = [String: Int]()

//MARK:---- handleCards - 25-91 = 66-lines

func handleCards(fileName: String, cardType: String, cardArray: [String], acct: Account?) -> [LineItem] {
    let cardArrayCount = cardArray.count
    var lineItemArray = [LineItem]()                // Create Array variable(lineItemArray) Type lineItem.
    var lineNum = 0

    //MARK: Read Header
    // Derive a Dictionary of Column Numbers from header
    var headerLine = ""
    var headers = [String]()
    Stats.lineItemCount = cardArrayCount
    while lineNum < cardArrayCount {
        headerLine = cardArray[lineNum]
        lineNum += 1
        let components = FileIO.parseCommaDelimitedLine(headerLine)// headerLine.components(separatedBy: ",")
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
        let tran = cardArray[lineNum].trim
        lineNum += 1
        if tran.trim.count < 16 { continue }    // Blank line or ",,,,,,,,,,,"

        Stats.processedCount += 1
        Stats.lineItemNumber = lineNum

        // ---------- Make the basic LineItem ----------
        let lineItem = makeLineItem(fromTransFileLine: tran, dictColNums: dictColNums, dictVendorShortNames: gDictVendorShortNames, cardType: cardType, hasCatHeader: hasCatHeader, fileName: fileName, lineNum: lineNum, acct: acct)

        if !lineItem.desc.isEmpty || !lineItem.postDate.isEmpty || lineItem.debit != 0  || lineItem.credit != 0 {
            // Check for duplicate from another file
            let signature = lineItem.signature()
            if gDictTranDupes[signature] == nil || gDictTranDupes[signature] == fileName {
                gDictTranDupes[signature] = fileName        // mark for dupes check
                lineItemArray.append(lineItem)              // Add new output Record
            } else {
                let msg = "Duplicate transaction of one from \(gDictTranDupes[signature] ?? "?")"
                handleError(codeFile: "HandleCards", codeLineNum: #line, type: .dataWarning, action: .display, fileName: fileName, dataLineNum: lineNum, lineText: tran, errorMsg: msg)
                Stats.duplicateCount += 1
            }
        } else {
            // debug trap - empty line
        }
    }//end line-by-line loop

    return lineItemArray
}//end func handleCards

//MARK: makeLineItem 104-lines
//---- makeLineItem - Uses support files & possible user-input 95-199 = 104-lines
internal func makeLineItem(fromTransFileLine: String,
                           dictColNums: [String: Int],
                           dictVendorShortNames: [String: String],
                           cardType: String,
                           hasCatHeader: Bool,
                           fileName: String,
                           lineNum: Int,
                           acct: Account?) -> LineItem {
    // Uses Globals: gLearnMode, gUserInputMode, gDictModifiedTrans, gDictMyCatAliases
    // Modifies Gloabals: gDictVendorCatLookup, Stats

    // If an "Account" record has been read-in for this item, set signAmount & tran accordingly
    var isActivity = false
    var signAmount = 1.0

    if let account = acct {
        if account.type == .activity {
            isActivity = true
        }
        if account.amount == .credit {
            signAmount = -1.0
        }
    }

    // Use LineItem.init to tranlate the transaction entry to a LineItem.
    if fromTransFileLine.contains("NEW YORK, NY") {
        // Debug Trap
    }
    var lineItem = LineItem(fromTransFileLine: fromTransFileLine, dictColNums: dictColNums, fileName: fileName, lineNum: lineNum, signAmount: signAmount)

    // Add descKey & cardType
    lineItem.cardType = cardType
    if isActivity {
        lineItem = extractTranFromActivity(lineItem: lineItem)
    }
    let descKey = makeDescKey(from: lineItem.desc, dictVendorShortNames: dictVendorShortNames, fileName: fileName)
    lineItem.descKey = descKey

    // Check for Modified Transaction
    let modTranKey = lineItem.signature()
    if let modTrans = gDictModifiedTrans[modTranKey] {
        //TODO: Add Memo to transaction
        lineItem.genCat = modTrans.category     // Here if found transaction in MyModifiedTransactions.txt
        lineItem.catSource = modTrans.source
        Stats.userModTransUsed += 1
        return lineItem                         // Use User-Modified .genCat & .catSource without looking further
    }
    if descKey.isEmpty { return lineItem }      // Missing descKey

    var catItemFromVendor = CategoryItem()
    var catItemPrefered   = CategoryItem()
    var isClearWinner     = false
    var catFromTran       = gDictMyCatAliases[lineItem.rawCat] ?? lineItem.rawCat + "-?"
    var catItemFromTran   = CategoryItem(category: catFromTran, source: cardType)

    if let catVend = gDictVendorCatLookup[descKey] {
        catItemFromVendor = catVend             // ------ Here if Lookup by Vendor was successful
        (catItemPrefered, isClearWinner) = pickTheBestCat(catItemVendor: catItemFromVendor, catItemTransa: catItemFromTran)
        if lineItem.genCat != catItemPrefered.category {
            lineItem.genCat     = catItemPrefered.category    // Generated Cat is the prefered one
            lineItem.catSource  = catItemPrefered.source
        }
        Stats.successfulLookupCount += 1

    } else {                   // ------ Here if NOT found in Category-Lookup-by-Vendor Dictionary
        findShorterDescKey(descKey) // Does nothing?
        catItemFromVendor = CategoryItem(category: "?", source: "")

        // If Transaction-Line has a Category, put it in the Vendor file.
        if catFromTran.count < 3 { catFromTran = "" }

        if let catTran = gDictMyCatAliases[catFromTran] {
            catFromTran = catTran
            isClearWinner = !catFromTran.hasSuffix("?") // if no "?", we have a winner
        } else {
            print("HandleCards#\(#line): Unknown Category: \"\(lineItem.rawCat)\" from \(descKey) (line#\(lineNum) in \(fileName))")
            isClearWinner = false
        }
        catItemFromTran = CategoryItem(category: catFromTran, source: cardType)
        catItemPrefered = catItemFromTran
        lineItem.genCat = catFromTran
        if gLearnMode {
            gDictVendorCatLookup[descKey] = CategoryItem(category: catFromTran, source: cardType) //Do Actual Insert
            Stats.addedCatCount += 1
        } else {
            Stats.descWithNoCat += 1
        }
        // print("Category that was inserted = Key==> \(key) Value ==> \(self.rawCat) Source ==> \(source)")
    }//end if NOT found in Category-Lookup-by-Vendor Dictionary

    // if we're not ignoring this vendor
    if usrIgnoreVendors[lineItem.descKey] == nil {

        // if in User-Input-Mode && No Clear Winner
        if gLearnMode {
            if gUserInputMode && !isClearWinner {
                _ = showUserInputVendorCatForm(lineItem: lineItem, batchMode: true, catItemFromVendor: catItemFromVendor, catItemFromTran: catItemFromTran, catItemPrefered: catItemPrefered)
                // ...and we're back.
                catItemPrefered = usrCatItemReturned
            } else if catItemPrefered.category != catItemFromVendor.category && isClearWinner {
                gDictVendorCatLookup[descKey] = catItemPrefered  // Do Actual Insert into VendorCategoryLookup
                Stats.changedVendrCatCount += 1
            }
        }
    }

    return lineItem
}//end func makeLineItem

//MARK: showUserInputVendorCatForm

//---- showUserInputVendorCatForm - Allow User to intervene using the UserInputCat form.
// Inserts/changes gDictVendorCatLookup or gDictModifiedTrans
func showUserInputVendorCatForm(lineItem: LineItem,
                                batchMode:          Bool,
                                catItemFromVendor:  CategoryItem,
                                catItemFromTran:    CategoryItem,
                                catItemPrefered:    CategoryItem) -> CategoryItem {
    usrLineItem = lineItem
    usrBatchMode         = batchMode
    usrCatItemFromVendor = catItemFromVendor
    usrCatItemFromTran   = catItemFromTran
    usrCatItemPrefered   = catItemPrefered
    var catItemToReturn  = CategoryItem(category: lineItem.genCat, source: lineItem.catSource)

    let storyBoard = NSStoryboard(name: "Main", bundle: nil)
    guard let userInputWindowController = storyBoard.instantiateController(withIdentifier: "UserInputWindowController") as? NSWindowController else {
        let msg = "Unable to open UserInputWindowController"
        handleError(codeFile: "HandleCards", codeLineNum: #line, type: .codeError, action: .alertAndDisplay, errorMsg: msg)
        return CategoryItem()
    }
    if let userInputWindow = userInputWindowController.window {
        //let userVC = storyBoard.instantiateController(withIdentifier: "UserInput") as! UserInputVC
        let application = NSApplication.shared
        let returnVal = application.runModal(for: userInputWindow) // <=================  UserInputVC
        // ...and we're back.
        userInputWindow.close()                     // Return here from userInputWindow
        switch returnVal {
        case .abort:
             exit(101)

        case .OK:                                   // .OK - Make changes requested by user
            if usrFixVendor {                       // Fix VendorCategoryLookup value
                gDictVendorCatLookup[lineItem.descKey] = usrCatItemReturned
                Stats.changedVendrCatCount += 1
                if !batchMode {
                    writeVendorCategoriesToFile(url: gVendorCatLookupFileURL, dictCat: gDictVendorCatLookup)
                }
            } else {                                // New category for this transaction only.
                let transKey = lineItem.signature()
                gDictModifiedTrans[transKey] = usrCatItemReturned
                writeModTransTofile(url: gMyModifiedTransURL, dictModTrans: gDictModifiedTrans)
            }
            catItemToReturn = usrCatItemReturned

        case .cancel:                               // .cancel - Do nothing
            break

        case .continue:                             // .continue - Continue app with no user input
            gUserInputMode =  false

        default:                                    // Except for .cancel, we should not be here
            print("HandleCards#\(#line) Unknown return value \(returnVal)")
        }//end switch

    } else {
        let msg = "Could not open User-Input window."
        handleError(codeFile: "HandleCards", codeLineNum: #line, type: .codeError, action: .alertAndDisplay, errorMsg: msg)
    }//end if let
    return catItemToReturn
}//end func

//MARK: makeDictColNums

//---- makeDictColNums - Infer which columns have the relevant data based in the Header row. Returns dictColNums
internal func makeDictColNums(headers: [String]) -> [String: Int] {
    // "Check Number", "Date Written", "Date Cleared", "Payee", "Amount"
    // ML settled-activity: "Trade Date","Settlement Date" "Description 2"
    var dictColNums = [String: Int]()
    for colNum in 0..<headers.count {
        let rawKey = headers[colNum].uppercased().trim.replacingOccurrences(of: "\"", with: "").trim
        let key: String
        if rawKey == "DATE" || rawKey.hasSuffix("WRITTEN") {
            key = "TRAN"                                            // Transaction Date
        } else if rawKey.hasSuffix("CLEARED") {
                key = "POST"                                        // POSTED Date

        } else if rawKey == "TRADE DATE" {
                key = "TRAN"                                        // Transaction Date - ML Settled Activity
        } else if rawKey == "SETTLEMENT DATE" {
                key = "POST"                                        // POSTED Date - ML Settled Activity

        } else if  rawKey == "PAYEE" || (rawKey.hasPrefix("ORIG") && rawKey.hasSuffix("DESCRIPTION")) { // "Original Description"
            key = "DESC"                                            // DESCRIPTION
        } else if (rawKey.hasPrefix("MERCH") && rawKey.hasSuffix("CATEGORY")) {   // "Merchant Category"
            key = "CATE"                                            // CATEGORY
        } else if rawKey.hasSuffix("NUMBER") {
            key = "NUMBER"                                          // CHECK NUMBER

        } else if rawKey == "DESCRIPTION 1" {
            key = "CATE"                                            // CATEGORY - ML Settled Activity
        } else if rawKey == "DESCRIPTION 2" {
            key = "DESC"                                            // CATEGORY - ML Settled Activity

        } else if rawKey.contains("NOTE") { 
            key = "MEMO"                                            // MEMO
        } else if rawKey.hasPrefix("ACCOUNT ") {
            switch rawKey.suffix(4) {
            case "NAME":
                key = "ACCNAME"
            case "TION":
                key = "ACCREG"
            default:
                key = "ACCNUM"
            }
        } else {
            key = String(rawKey.replacingOccurrences(of: "\"", with: "").prefix(4))
            if key != "POST" && key != "DESC" && key != "AMOU" && key != "DEBI" && key != "CRED" && key != "CATE" {
                print("HandleCards#\(#line) unknown column type: \(rawKey)")
                //
            }
        }
        if dictColNums[key] == nil {
            dictColNums[key] = colNum
        } else {
            // Here more than 1 rawKey points to same column
        }
    }//next colNum

    return dictColNums
}//end func

//---- findShorterDescKey - Does nothing yet
internal func findShorterDescKey(_ descKey: String) {
    let descKeyCount = descKey.count
    for (key, value) in gDictVendorCatLookup {
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

//---- pickTheBestCat - Returns (catItemPrefered, isClearWinner) tuple.
internal func pickTheBestCat(catItemVendor: CategoryItem, catItemTransa: CategoryItem) -> (catItem: CategoryItem, isStrong: Bool) {
    let weak    = false
    let strong  = true
    let catVendor = catItemVendor.category
    let catTransa = catItemTransa.category
    if catItemVendor.source.hasPrefix("$")                  { return (catItemVendor, strong) }  // User modified: Locked-in

    let catVendStrong = !catVendor.isEmpty && !catVendor.hasSuffix("?") && !catVendor.contains("Unknow")
    let catTranStrong = !catTransa.isEmpty && !catTransa.hasSuffix("?") && !catTransa.contains("Unknow") 
    if (catVendor == catTransa)                             { return (catItemTransa, catTranStrong) } // Both the same.

    if catVendStrong  && catTranStrong                      { return (catItemTransa, weak) }    // tie: both strong
    if !catVendStrong && catTranStrong                      { return (catItemTransa, strong) }  // Transaction strong
    if catVendStrong  && !catTranStrong                     { return (catItemVendor, strong) }  // Vendor strong

    if catVendor.isEmpty || catVendor == "?"                {   // catVendor missing
        return (catItemTransa, weak)
    }
    if catTransa.isEmpty || catTransa == "?"                {   // catTransa missing
        return (catItemVendor, weak)
    }
    if catTransa.contains("Unkno")                          {   // "Unknown"
        return (catItemVendor, weak)
    }
    if catVendor.contains("Unkno")                          {   // "Unknown"
        return (catItemTransa, weak)
    }    //      "
    return (catItemTransa, weak)
}

/*
 Cat => SubCat => Vendor => Spreadsheet
 */
