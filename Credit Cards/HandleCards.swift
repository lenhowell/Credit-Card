//
//  HandleCards.swift
//  Credit Cards
//
//  Created by George Bauer on 8/9/19.
//  Copyright © 2019-2021 George Bauer. All rights reserved.
//

import Cocoa    // needed to access NSStoryboard & NSWindowController for segue

//MARK: - Globals for UserInputVendorCatForm
// Parameters for UserInputVendorCatForm
var usrLineItem          = LineItem()
var usrCatItemFromVendor = CategoryItem()
var usrCatItemFromTran   = CategoryItem()
var usrCatItemPrefered   = CategoryItem()
var usrBatchMode         = true
// Returns from UserInputVendorCatForm
var usrModTranItemReturned  = ModifiedTransactionItem()
var usrFixVendor            = true
var usrIgnoreVendors        = [String: Int]()

//MARK: ---- handleCards - 25-195 = 170-lines
// Called by: ViewController
func handleCards(fileName: String, cardType: String, cardArray: [String], acct: Account?) {
    let cardArrayCount = cardArray.count
    //var lineItemArray = [LineItem]()                // Create Array variable(lineItemArray) Type lineItem.
    var lineNum = 0

    //MARK: Read Header
    // Derive a Dictionary of Column Numbers from header
    var headerLine = ""
    var headers = [String]()
    Stats.lineItemCount = cardArrayCount
    while lineNum < cardArrayCount {
        headerLine = cardArray[lineNum]
        lineNum += 1
        var csvTsv = FileIO.CsvTsv.tsv
        if fileName.lowercased().hasSuffix(".csv") {
            csvTsv = .csv
        }
        let comps = FileIO.parseDelimitedLine(headerLine, csvTsv: csvTsv)// headerLine.components(separatedBy: ",")
        if comps.count >= 3 && comps[0].count > 2  && comps[0].count < 30   && comps[1].count > 2  {
            headers = comps
            break
        }
    }

    if headers.isEmpty {
        handleError(codeFile: "HandleCards", codeLineNum: #line, type: .dataError, action: .alertAndDisplay,  fileName: fileName, dataLineNum: lineNum, lineText: "", errorMsg: "Headers not found.")
        return
    }

    let dictColNums = makeDictColNums(file: fileName, headers: headers)

    let hasCatHeader: Bool
    if dictColNums["CATE"] == nil {
        hasCatHeader = false
        let msg = "No \"Category\" in Headers"
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
        Stats.lineItemNumber = lineNum

        // ---------- Make the basic LineItem ----------
        let lineItem = makeLineItem(fromTransFileLine: tran, dictColNums: dictColNums, dictVendorShortNames: Glob.dictVendorShortNames, cardType: cardType, hasCatHeader: hasCatHeader, fileName: fileName, lineNum: lineNum, acct: acct)

        if !lineItem.desc.isEmpty || !lineItem.postDate.isEmpty || lineItem.debit != 0  || lineItem.credit != 0 {

            // Check for Duplicate of a Check-Number
            let chkNumStr = lineItem.chkNumber.trim
            if !chkNumStr.isEmpty {                        // This IS a Numbered Check
                let dateFromTran = lineItem.tranDate
                var dateToUse = dateFromTran
                if let idxFromDupe = Glob.dictCheckDupes[chkNumStr] {
                    // IS a Dupe
                    dateToUse = gotaDupe(lineItem: lineItem, idxFromDupe: idxFromDupe, fileName: fileName, lineNum: lineNum)

                } else {    // NOT a Dupe Chk#
                    Glob.dictCheckDupes[chkNumStr] = Glob.lineItemArray.count  // Record its position in array for Dupe check
                    let key2 = lineItem.postDate + "$" + String(format: "%.2f",lineItem.debit)
                    Glob.dictCheck2Dupes[key2] = Glob.lineItemArray.count   // Tofind dupe w/o Chk# in trans file
                    Glob.lineItemArray.append(lineItem)                 // Add new output Record
                }
                if Stats.firstDate > dateToUse { Stats.firstDate = dateToUse }
                if Stats.lastDate  < dateToUse { Stats.lastDate  = dateToUse }
                continue        // We're done here
            }

            let signatureNoVendr = lineItem.signature(ignoreVendr: true)
            if lineItem.desc == "CHECK" {
                // If we have an unmarked check (no # or payee) in CMA Transaction file,
                // ignore it and hope it's picked up in CheckML-20xx file. ????
                // ??????
                let dateStr = lineItem.postDate.isEmpty ? lineItem.tranDate: lineItem.postDate
                let key2 = dateStr + "$" + String(format: "%.2f",lineItem.debit)
                if let _ = Glob.dictCheck2Dupes[key2] {  // To find dupe w/o Chk# in trans file
                    Stats.duplicateCount += 1
                    continue
                }
                print("⛔️ HandleCards#\(#line)[\(fileName)] Unrecorded check \(lineItem.tranDate) \(lineItem.postDate) \(lineItem.descKey) \(lineItem.debit) \(lineItem.rawCat)")
                continue
            }
            
            // Check for Duplicate from another file
            let signature1 = lineItem.signature()                   // Signature using TranDate
            let signature2 = lineItem.signature(usePostDate: true)  // Signature using PostDate
            let signatureNoDate  = lineItem.signature(ignoreDate: true)
            var matchOpt = Glob.dictTranDupes[signature1]
            if matchOpt == nil { matchOpt = Glob.dictTranDupes[signature2] }

            // Special handling for Credits that might have differing dates
            if lineItem.rawCat.uppercased().contains("CREDIT") && lineItem.credit > 0 {
                print("🤔 HandleCards#\(#line) \(lineItem.tranDate) \(lineItem.postDate) \(lineItem.descKey) \(lineItem.credit) \(lineItem.rawCat)")
                let vendr   = lineItem.descKey.prefix(4)
                let credit  = String(format: "%.2f", lineItem.credit)
                let signature = vendr + "|" + credit
                if let dateFromDupe = Glob.dictCreditDupes[signature] {
                    let daysDif = dateDif(dateStr1: lineItem.tranDate, dateStr2: dateFromDupe)
                    if abs(daysDif) <= 4 {
                        print("🤔 HandleCards#\(#line) \(lineItem.tranDate) \(lineItem.postDate) \(lineItem.descKey) \(lineItem.credit) \(lineItem.rawCat)")
                    }
                } else {
                    Glob.dictCreditDupes[signature] = lineItem.tranDate
                    Glob.lineItemArray.append(lineItem)              // Add new output Record
                }
                continue    // Done with this transaction
            }

            // See if Match for Dates & $ only
            if matchOpt == nil {
                if let tuple = Glob.dictNoVendrDupes[signatureNoVendr] {
                    let idx  = tuple.0
                    let file = tuple.1
                    if file != fileName {
                        print("🔹 HandleCards#\(#line) \(lineItem.tranDate) \(lineItem.postDate) \(lineItem.descKey) \(lineItem.credit) \(lineItem.rawCat) - Dupe in \(file)")
                        print("  HandleCards#\(#line)     descKey \"\(lineItem.descKey)\" vs \"\(Glob.lineItemArray[idx].descKey)\" both $\(lineItem.debit), $\(lineItem.credit) on \(lineItem.tranDate)")
                        if lineItem.descKey.prefix(3) == Glob.lineItemArray[idx].descKey.prefix(3) {
                            matchOpt = tuple
                        } else {
                            //
                        }
                    }
                }
            }

            // See if Match for Vendr & approx dates (+/-2)
            if matchOpt == nil {
                if let tuple = Glob.dictNoDateDupes[signatureNoDate] {
                    let date1 = lineItem.tranDate
                    let date2 = Glob.lineItemArray[tuple.0].tranDate
                    let daysDif = dateDif(dateStr1: date1, dateStr2: date2)
                    let file = tuple.1
                    if abs(daysDif) <= 2 && file != fileName {
                        print("🔹 HandleCards#\(#line) \(date1) \(lineItem.postDate) \(lineItem.descKey) \(lineItem.credit) \(lineItem.rawCat) - Dupe in \(file)")
                        print("  HandleCards#\(#line)     Close dates \"\(lineItem.descKey)\" \(date1) vs \"\(Glob.lineItemArray[tuple.0].descKey)\" \(date2) both $\(lineItem.debit), $\(lineItem.credit)")
                        //matchOpt = tuple
                    }
                }
            }//end matchOpt == nil
            
            let matchFile = matchOpt?.1 ?? ""
            if matchOpt == nil || matchFile == fileName {
                // NOT a Dupe
                let tuple = (Glob.lineItemArray.count, fileName)
                Glob.dictTranDupes[signature1] = tuple        // mark for dupes check using TranDate
                Glob.dictTranDupes[signature2] = tuple        // mark for dupes check using PostDate
                if lineItem.debit != 0.0 || lineItem.credit != 0.0 {
                    Glob.dictNoVendrDupes[signatureNoVendr] = tuple
                    Glob.dictNoDateDupes[signatureNoDate] = tuple
                }

                Glob.lineItemArray.append(lineItem)              // Add new output Record
                if Stats.firstDate > lineItem.tranDate { Stats.firstDate = lineItem.tranDate }
                if Stats.lastDate  < lineItem.tranDate {
                    if !lineItem.tranDate.contains("?") {
                        Stats.lastDate  = lineItem.tranDate
                    }
                }

                if lineItem.genCat.hasPrefix("Uncat") {
                    let msg = "Got Uncategorized genCat"
                    handleError(codeFile: "HandleCards", codeLineNum: #line, type: .dataWarning, action: .display, fileName: fileName, dataLineNum: lineNum, lineText: tran, errorMsg: msg)
                    // debug trap
                }
            } else {    // IS a Dupe
                if let match = matchOpt {
                    let idxFromDupe = match.0
                    _ = gotaDupe(lineItem: lineItem, idxFromDupe: idxFromDupe, fileName: fileName, lineNum: lineNum)
                }
            }
        } else {
            // debug trap - empty line
        }
    }//end line-by-line loop

    return
}//end func handleCards

// Returns the TrasactionDate to use for min-max
internal func gotaDupe(lineItem: LineItem, idxFromDupe: Int, fileName: String, lineNum: Int) -> String {
    // IS a Dupe
    let lineItemFromDupe = Glob.lineItemArray[idxFromDupe]
    let dateFromDupe     = lineItemFromDupe.tranDate
    let dateFromTran     = lineItem.tranDate
    let chkNum           = lineItem.chkNumber
    var dateToUse = dateFromTran
    let msg: String
    /*
                Good        Bad
     postDate   yyyy-mm-dd  ""
     descKey    Payee       "PAYEE UNRECORDE"
     desc       Payee       "PAYEE UNRECORDE"
     rawCat     "Unknown"   "Checks"
     genCat     MyCategory  "Checks-?"
     */
    if lineItemFromDupe.postDate.count < 8 || lineItemFromDupe.desc.contains("UNREC") {
        Glob.lineItemArray[idxFromDupe] = lineItem  // Replace current lineItem with this one
    }
    
    if chkNum.isEmpty {
        msg = "Duplicate transaction (\(lineItem.descKey) $\(lineItem.debit)) of one from \(lineItemFromDupe.auditTrail)"
    } else {
        msg = "Duplicate chkNumber \(chkNum) with dates of \(dateFromTran) & \(dateFromDupe) "
    }
    // fileName: fileName, dataLineNum: lineNum, lineText: lineItem.transText,
    print("➡️ HandleCards#\(#line)[\(fileName)] \(msg)")
    Glob.lineItemArray[idxFromDupe].cardType = Glob.lineItemArray[idxFromDupe].cardType + "*"
    
    if lineItem.descKey != lineItemFromDupe.descKey ||  lineItem.genCat != lineItemFromDupe.genCat {
        if lineItem.descKey != lineItemFromDupe.descKey {
            print("😡 HandleCards#\(#line)[\(fileName)] desKey: \(lineItem.descKey) != \(lineItemFromDupe.descKey)")
        }
        if lineItem.genCat != lineItemFromDupe.genCat {
            print("😡 HandleCards#\(#line)[\(fileName)] genCat: \(lineItem.genCat) != \(lineItemFromDupe.genCat)")
        }
        if lineItemFromDupe.genCat == Const.unknown && lineItem.genCat != Const.unknown {
            Glob.lineItemArray[idxFromDupe].genCat  = lineItem.genCat
            Glob.lineItemArray[idxFromDupe].descKey = lineItem.descKey
        } else {
            //
        }
    }
    if dateFromTran < dateFromDupe {
        Glob.lineItemArray[idxFromDupe].tranDate = dateFromTran // Use older tranDate (newer one is probably a postDate)
    } else {
        dateToUse = dateFromDupe
    }
    Stats.duplicateCount += 1
    return dateToUse
}//end func gotaDupe

//MARK: makeLineItem 114-lines
// Called by: handleCards, readDeposits
//---- makeLineItem - Uses support files & possible user-input 247-361 = 114-lines
internal func makeLineItem(fromTransFileLine:   String,
                           dictColNums:         [String: Int],
                           dictVendorShortNames:[String: String],
                           cardType:            String,
                           hasCatHeader:        Bool,
                           fileName:            String,
                           lineNum:             Int,
                           acct:                Account?) -> LineItem {
    // Uses Globals: Glob.learnMode, Glob.userInputMode, Glob.dictModifiedTrans, gCatagories 
    // Modifies Gloabals: Glob.dictVendorCatLookup, Stats

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
    var lineItem = LineItem(fromTransFileLine: fromTransFileLine, dictColNums: dictColNums, fileName: fileName, lineNum: lineNum, signAmount: signAmount, acct: acct)

    // Add descKey & cardType
    lineItem.cardType = cardType
    if lineItem.rawCat.lowercased().contains("gifts") {
        // Debug Trap gifts
    }
    if isActivity {
        lineItem = extractTranFromActivity(lineItem: lineItem)
        if lineItem.rawCat.contains("ifts") {
            // Debug Trap gifts
        }
    }
    let descKey = DescriptionKey.makeDescKey(from: lineItem.desc, dictVendorShortNames: dictVendorShortNames, fileName: fileName)
    lineItem.descKey = descKey

    // Check for Modified Transaction
    let modTranKey = lineItem.signature()
    if let modTrans = Glob.dictModifiedTrans[modTranKey] {
        lineItem.genCat      = modTrans.catItem.category // Found transaction in MyModifiedTransactions.txt
        lineItem.catSource   = modTrans.catItem.source
        lineItem.memo        = modTrans.memo
        lineItem.modifiedKey = modTranKey
        Stats.userModTransUsed += 1
        if lineItem.rawCat.lowercased().contains("gifts") {
            // Debug Trap gifts
        }
        return lineItem                         // Use User-Modified .genCat & .catSource without looking further
    }
    if descKey.isEmpty { return lineItem }      // Missing descKey

    var catItemFromVendor = CategoryItem()
    var catItemPrefered   = CategoryItem()
    var isClearWinner     = false
    var catFromTran       = gCatagories.dictCatAliases[lineItem.rawCat.uppercased()] ?? lineItem.rawCat + "-?"
    var catItemFromTran   = CategoryItem(category: catFromTran, source: cardType)

    if lineItem.genCat.lowercased().contains("gifts")  {
        // Debug Trap gifts
    }
    
    if let catVend = Glob.dictVendorCatLookup[descKey] {
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

        if let catTran = gCatagories.dictCatAliases[catFromTran.uppercased()] {
            catFromTran = catTran
            isClearWinner = !catFromTran.hasSuffix("?") // if no "?", we have a winner
        } else {
            if lineItem.rawCat.isEmpty {
                lineItem.rawCat = Const.unknown
                lineItem.genCat = ""
            }
            print("😡 HandleCards#\(#line): Unknown Category: \"\(lineItem.rawCat)\" from \(descKey) (line#\(lineNum) in \(fileName))")
            isClearWinner = false
        }
        catItemFromTran = CategoryItem(category: catFromTran, source: cardType)
        catItemPrefered = catItemFromTran
        lineItem.genCat = catFromTran
        if Glob.learnMode {
            Glob.dictVendorCatLookup[descKey] = CategoryItem(category: catFromTran, source: cardType) //Do Actual Insert
            Stats.addedCatCount += 1
        } else {
            Stats.descWithNoCat += 1
        }
        // print("Category that was inserted = Key==> \(key) Value ==> \(self.rawCat) Source ==> \(source)")
    }//end if NOT found in Category-Lookup-by-Vendor Dictionary


    // if we're not ignoring this vendor
    if usrIgnoreVendors[lineItem.descKey] == nil {

        // if in User-Input-Mode && No Clear Winner
        if Glob.learnMode {
            if Glob.userInputMode && !isClearWinner {
                _ = showUserInputVendorCatForm(lineItem: lineItem, batchMode: true, catItemFromVendor: catItemFromVendor, catItemFromTran: catItemFromTran, catItemPrefered: catItemPrefered)
                // ...and we're back.
                catItemPrefered = usrModTranItemReturned.catItem
            } else if catItemPrefered.category != catItemFromVendor.category && isClearWinner {
                Glob.dictVendorCatLookup[descKey] = catItemPrefered  // Do Actual Insert into VendorCategoryLookup
                Stats.changedVendrCatCount += 1
            }
        }
    }

    return lineItem
}//end func makeLineItem

//MARK: showUserInputVendorCatForm

//---- showUserInputVendorCatForm - Allow User to intervene using the UserInputCat form.
// Inserts/changes Glob.dictVendorCatLookup or Glob.dictModifiedTrans
// Called by: makeLineItem, SpreadsheetVC
func showUserInputVendorCatForm(lineItem: LineItem,
                                batchMode:          Bool,
                                catItemFromVendor:  CategoryItem,
                                catItemFromTran:    CategoryItem,
                                catItemPrefered:    CategoryItem) -> ModifiedTransactionItem {
    usrLineItem          = lineItem
    usrBatchMode         = batchMode
    usrCatItemFromVendor = catItemFromVendor
    usrCatItemFromTran   = catItemFromTran
    usrCatItemPrefered   = catItemPrefered
    let catItemToRet     = CategoryItem(category: lineItem.genCat, source: lineItem.catSource)
    var modTranItemToReturn = ModifiedTransactionItem(catItem: catItemToRet, memo: lineItem.memo)
    let storyBoard          = NSStoryboard(name: "Main", bundle: nil)
    guard let userInputCatWindowController = storyBoard.instantiateController(withIdentifier: "UserInputCatWindowController") as? NSWindowController else {
        let msg = "Unable to open UserInputCatWindowController"
        handleError(codeFile: "HandleCards", codeLineNum: #line, type: .codeError, action: .alertAndDisplay, errorMsg: msg)
        return ModifiedTransactionItem()
    }
    if let userInputCatWindow = userInputCatWindowController.window {
        let userInputViewController = userInputCatWindow.contentViewController as! UserInputCatVC
        userInputViewController.myUserInitials = Glob.userInitials  // experiment
        let application = NSApplication.shared
        let returnVal = application.runModal(for: userInputCatWindow) // <=================  UserInputVC
        // ...and we're back.
        userInputCatWindow.close()                     // Return here from userInputWindow
        switch returnVal {
        case .abort:
             exit(101)

        case .OK:                                   // .OK - Make changes requested by user
            if usrFixVendor {                       // Fix VendorCategoryLookup value
                Glob.dictVendorCatLookup[lineItem.descKey] = usrModTranItemReturned.catItem
                Stats.changedVendrCatCount += 1
                if !batchMode {
                    writeVendorCategoriesToFile(url: Glob.url.vendorCatLookupFile, dictCat: Glob.dictVendorCatLookup)
                }
            } else {                                // New category for this transaction only.
                let transKey = lineItem.signature()
                Glob.dictModifiedTrans[transKey] = usrModTranItemReturned
                writeModTransTofile(url: Glob.url.myModifiedTrans, dictModTrans: Glob.dictModifiedTrans)
            }
            modTranItemToReturn = usrModTranItemReturned

        case .cancel:                               // .cancel - Do nothing
            break

        case .continue:                             // .continue - Continue app with no user input
            Glob.userInputMode =  false

        default:                                    // Except for .cancel, we should not be here
            print("⛔️ HandleCards#\(#line) Unknown return value \(returnVal)")
        }//end switch

    } else {
        let msg = "Could not open User-Input window."
        handleError(codeFile: "HandleCards", codeLineNum: #line, type: .codeError, action: .alertAndDisplay, errorMsg: msg)
    }//end if let
    return modTranItemToReturn
}//end func showUserInputVendorCatForm

//MARK: makeDictColNums

//---- makeDictColNums - Infer which columns have the relevant data based in the Header row.
// Called by: handleCards, readDeposits
// Returns dictColNums
public func makeDictColNums(file: String, headers: [String]) -> [String: Int] {
    // "Check Number", "Date Written", "Date Cleared", "Payee", "Amount"
    // ML settled-activity: "Trade Date","Settlement Date" "Description 2"
    var dictColNums = [String: Int]()
    for colNum in 0..<headers.count {
        let rawKey = headers[colNum].uppercased().trim.replacingOccurrences(of: "\"", with: "").trim
        let key: String
        if rawKey == "DATE" || rawKey.hasSuffix("WRITTEN") {
            key = "TRAN"                                    // TRANsaction Date <- "DATE...WRITTEN"
        } else if rawKey.hasSuffix("CLEARED") {
                key = "POST"                                // POSTed Date      <-  "DATE...CLEARED"

        } else if rawKey == "TRADE DATE" {
                key = "TRAN"                                // TRANsaction Date <- "TRADE DATE"     ML Activity
        } else if rawKey == "SETTLEMENT DATE" {
                key = "POST"                                // POSTED Date      <- "SETTLEMENT DATE" ML Activity

        } else if  rawKey == "PAYEE" || (rawKey.hasPrefix("ORIG") && rawKey.hasSuffix("DESCRIPTION")) { // "Original Description"
            key = "DESC"                                    // DESCription      <- "PAYEE" or "ORIG...DESCRIPTION"
        } else if (rawKey.hasPrefix("MERCH") && rawKey.hasSuffix("CATEGORY")) {   // "Merchant Category"
            key = "CATE"                                    // CATEgory         <- "MERCH...CATEGORY"
        } else if rawKey == "CHK#" {
                key = "NUMBER"                              // check NUMBER     <- "CHK#"
        } else if rawKey.hasSuffix("NUMBER") {
            key = "NUMBER"                                  // check NUMBER     <- "NUMBER"

        } else if rawKey == "CATAGORY" {
            key = "CATE"                                    // CATEgory         <- "CATEGORY" 2006
        } else if rawKey == "DESCRIPTION 1" {
            key = "CATE"                                    // CATEgory         <- "DESCRIPTION 1" ML Activity
        } else if rawKey == "DESCRIPTION 2" {
            key = "DESC"                                    // CATEgory         <- "DESCRIPTION 2" ML Activity

        } else if rawKey.contains("NOTE") { 
            key = "MEMO"                                    // MEMO             <- "NOTE"
        } else if rawKey.hasPrefix("ACCOUNT ") {
            switch rawKey.suffix(4) {
            case "NAME":
                key = "ACCNAME"                             // ACCNAME          `<- "ACCOUNT ...NAME"
            case "TION":
                key = "ACCREG"                              // ACCREG           `<- "ACCOUNT ...TION"
            default:
                key = "ACCNUM"                              // ACCNUM            `<- "ACCOUNT ..."
            }
        } else {
            key = String(rawKey.replacingOccurrences(of: "\"", with: "").prefix(4))
            if key != "TRAN" && key != "POST" && key != "DESC" && key != "AMOU" && key != "DEBI" && key != "CRED" && key != "CATE" && key != "MEMO" {
                print("😡 HandleCards#\(#line)[\(file)] unknown column type: \(rawKey)")
                //
            }
        }
        if dictColNums[key] == nil {
            dictColNums[key] = colNum
        } else {
            let msg = "Got Duplicate Columns for \(key)"
            handleError(codeFile: "HandleCards", codeLineNum: #line, type: .dataWarning, action: .display, errorMsg: msg)
            // Here when more than 1 rawKey points to same column
        }
    }//next colNum

    return dictColNums
}//end func

//---- findShorterDescKey - Does nothing yet
// Called by: makeLineItem
internal func findShorterDescKey(_ descKey: String) {
    let descKeyCount = descKey.count
    for (key, _) in Glob.dictVendorCatLookup {
        let keyCount = key.count
        if descKeyCount < keyCount && descKeyCount > 3 {
            if key.prefix(descKeyCount) == descKey {
                //print("😋 HandleCards#\(#line) Found \(descKey) (\(descKey.count)) as subset of \(key) (\(keyCount)) : \(value)")
                //
            }
        } else if descKeyCount > keyCount && keyCount > 3 {
            if descKey.prefix(keyCount) == key {
                //print("😋 HandleCards#\(#line) Found \(descKey) (\(descKey.count)) as superset of \(key) (\(keyCount)) : \(value)")
                //
            }
        }
    }//next key,value
}//end func

//---- pickTheBestCat - Returns (catItemPrefered, isClearWinner) tuple.
// Called by: makeLineItem
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
    if catItemTransa.category.lowercased().contains("gifts") {
        // Debug Trap gifts
    }
    return (catItemTransa, weak)
}

/*
 Cat => SubCat => Vendor => Spreadsheet
 */
