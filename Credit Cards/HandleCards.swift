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

func handleCards(fileName: String, cardType: String, cardArray: [String], dictVendorShortNames: inout [String: String]) -> [LineItem] {
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
        let tran = cardArray[lineNum].trim
        lineNum += 1
        if tran.trim.count < 16 { continue }    // Blank line or ",,,,,,,,,,,"

        Stats.processedCount += 1
        let lineItem = makeLineItem(fromTransFileLine: tran, dictColNums: dictColNums, dictVendorShortNames: dictVendorShortNames, cardType: cardType, hasCatHeader: hasCatHeader, fileName: fileName, lineNum: lineNum)

        if !lineItem.desc.isEmpty || !lineItem.postDate.isEmpty || lineItem.debit != 0  || lineItem.credit != 0 {
            // Check for duplicate from another file
            //FIXME: Not all dupes are picked up
            let signature = makeSignature(lineItem: lineItem)
            if dictTranDupes[signature] == nil || dictTranDupes[signature] == fileName {
                if tran.contains("VAZZYS OSTERIA") && tran.contains("18.83") {
                    //
                }
                dictTranDupes[signature] = fileName      // mark for dupes check
                lineItemArray.append(lineItem)          // Add new output Record
            } else {
                let msg = "Duplicate transaction of one from \(dictTranDupes[signature]!)"
                handleError(codeFile: "HandleCards", codeLineNum: #line, type: .dataWarning, action: .display, fileName: fileName, dataLineNum: lineNum, lineText: tran, errorMsg: msg)
                Stats.duplicateCount += 1
            }
        } else {
            // debug trap - empty line
        }
    }//end line-by-line loop

    return lineItemArray
}//end func handleCards

func makeSignature(lineItem: LineItem) -> String {
    var dateStr = ""
    let da = lineItem.tranDate
    if da.contains("/") {
        let comps = da.components(separatedBy: "/")
        var yy = comps[2].trim
        if yy.count <= 2 { yy = "20" + yy }
        var mm = comps[0].trim
        if mm.count < 2 { mm = "0" + mm }
        var dd = comps[1].trim
        if dd.count < 2 { dd = "0" + dd }
        dateStr = "\(yy)-\(mm)-\(dd)"
    } else if da.contains("-") {
        dateStr = da
    } else {
        //
    }
    let vendr = lineItem.descKey.prefix(4)
    let cardNum = lineItem.cardNum
    let credit =  String(format: "%.2f", lineItem.credit)//  lineItem.credit)
    let debit =  String(format: "%.2f", lineItem.debit)
    let signature = "\(dateStr),\(cardNum),\(vendr),\(credit),\(debit)"
    return signature
}

//MARK:---- makeLineItem - 89-163 = 74-lines
// uses Global Vars: dictVendorCatLookup(I/O), Stats(I/O)
internal func makeLineItem(fromTransFileLine: String, dictColNums: [String: Int], dictVendorShortNames: [String: String], cardType: String, hasCatHeader: Bool, fileName: String, lineNum: Int) -> LineItem {

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

    let descKey = makeDescKey(from: lineItem.desc, dictVendorShortNames: dictVendorShortNames, fileName: fileName)
    lineItem.descKey = descKey
    if !descKey.isEmpty {
        if let cV = dictVendorCatLookup[descKey] {
            catItemFromVendor = cV                  // ------ Here if Lookup by Vendor was successful
            (catItemPrefered, isClearWinner) = pickTheBestCat(catItemVendor: catItemFromVendor, catItemTransa: catItemFromTran)
            if lineItem.genCat != catItemPrefered.category {
                lineItem.genCat     = catItemPrefered.category    // Generated Cat is the prefered one
                lineItem.catSource  = catItemPrefered.source
            }
            //print("\(#line) Cat for \(descKey) = \(catItemFromVendor.category);  TransCat = \(catFromLineItem)  Chose: \(catItemPrefered.category)")
            Stats.successfulLookupCount += 1
//            if cV.category.contains("?") {
//                print("HandleCards#\(#line) \(lineItem.descKey) \(catItemPrefered.category) isClearWinner=\(isClearWinner)  VendorCat=\(catItemFromVendor.category) TransCat=\(catItemFromTran.category)")
//            }
            uniqueCategoryCounts[descKey, default: 0] += 1

        } else {                   // ------ Here if NOT found in Category-Lookup-by-Vendor Dictionary
            findShorterDescKey(descKey) // Have we already found a truncated (shorter) version of descKey?
            catItemFromVendor = CategoryItem(category: "?", source: "")

            // If Transaction-Line has a Category, put it in the Vendor file.
            if catFromTran.count < 3 { catFromTran = "" }

            if let catTran = dictMyCatAliases[catFromTran] {
                catFromTran = catTran
                isClearWinner = !catFromTran.hasPrefix("?") // if no "?", we have a winner
            } else {
                print("HandleCards#\(#line): Unknown Category: \"\(lineItem.rawCat)\" from \(descKey) (line#\(lineNum) in \(fileName))")
                isClearWinner = false
            }
            catItemFromTran = CategoryItem(category: catFromTran, source: cardType)
            catItemPrefered = catItemFromTran
            lineItem.genCat = catFromTran
            if gLearnMode {
                dictVendorCatLookup[descKey] = CategoryItem(category: catFromTran, source: cardType) //Do Actual Insert
                Stats.addedCatCount += 1
            } else {
                Stats.descWithNoCat += 1
            }
            // print("Category that was inserted = Key==> \(key) Value ==> \(self.rawCat) Source ==> \(source)")
        }//end if NOT found in Category-Lookup-by-Vendor Dictionary

        // if we're not ignoring this vendor
        if usrIgnoreVendors[lineItem.descKey] == nil {

            // if in User-Input-Mode && No Clear Winner
            if gUserInputMode && !isClearWinner {
                showUserInputForm(lineItem: lineItem, catItemFromVendor: catItemFromVendor, catItemFromTran: catItemFromTran, catItemPrefered: catItemPrefered)
                catItemPrefered = usrCatItemReturned
            } else if gLearnMode && catItemPrefered != catItemFromVendor {
                dictVendorCatLookup[descKey] = catItemPrefered  // Do Actual Insert into VendorCategoryLookup
                Stats.changedCatCount += 1
            }
        }
    } else {
        // debug trap
    }//endif descKey empty or not

    return lineItem
}//end func makeLineItem

// Allow User to intervene using the UserInputCat form
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
        let returnVal = application.runModal(for: userInputWindow) // <=================  UserInputVC

        userInputWindow.close()                     // Return here from userInputWindow
        switch returnVal {
        case .abort:
             exit(101)

        case .OK:                                   // .OK - Make changes requested by user
            if usrFixVendor && gLearnMode {
                dictVendorCatLookup[lineItem.descKey] = usrCatItemReturned
                Stats.changedCatCount += 1
            } else {
                let transKey = lineItem.transText
                dictModifiedTrans[transKey] = usrCatItemReturned
            }

        //case .cancel:                             // .cancel - Do nothing

        case .continue:                             // .continuw - Continue app with no user input
            gUserInputMode =  false

        default:                                    // Except for .cancel, we should not be here
            if returnVal != .cancel {
                print("HandleCards#\(#line) Unknown return value \(returnVal)")
            }
        }//end switch

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
    for (key, value) in dictVendorCatLookup {
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
