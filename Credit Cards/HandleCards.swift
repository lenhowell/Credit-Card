//
//  HandleCards.swift
//  Credit Cards
//
//  Created by Lenard Howell on 8/9/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Foundation

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
            lineItemArray.append(lineItem)          // Add new output Record to be output
        }
    }//end line-by-line loop

    return lineItemArray
}//end func handleCards


//MARK:---- makeLineItem - 68-108 = 40-lines
// uses Global Vars: dictCatLookupByVendor(I/O), Stats(I/O)
internal func makeLineItem(fromTransFileLine: String, dictColNums: [String: Int], cardType: String, hasCatHeader: Bool, fileName: String, lineNum: Int) -> LineItem {

    var lineItem = LineItem(fromTransFileLine: fromTransFileLine, dictColNums: dictColNums, fileName: fileName, lineNum: lineNum)
    lineItem.cardType = cardType

    let descKey = makeDescKey(from: lineItem.desc, fileName: fileName)
    lineItem.descKey = descKey

    if !descKey.isEmpty {
        if let vendorCatItem = dictCatLookupByVendor[descKey] {
            lineItem.genCat = vendorCatItem.category            // Here if Lookup of KEY was successful
            lineItem.catSource = vendorCatItem.source

            let catFromLineItem = dictMyCatAliases[lineItem.rawCat] ?? "?" + lineItem.rawCat
            let catItemFromTran = CategoryItem(category: catFromLineItem, source: cardType)
            //TODO: Implement Learning mode
            //TODO: Recognize "LOCKED" Vendors
            if vendorCatItem.category != catFromLineItem {
                let chosenCat = pickTheBestCat(catItem1: vendorCatItem, catItem2: catItemFromTran)
                lineItem.genCat = chosenCat.category
                lineItem.catSource = chosenCat.source
                print("\(#line) Cat for \(descKey) = \(vendorCatItem.category);  TransCat = \(catFromLineItem)  Chose: \(chosenCat.category)")
                if learnMode && chosenCat != vendorCatItem {
                    dictCatLookupByVendor[descKey] = chosenCat //Do Actual Insert
                    Stats.changedCatCount += 1
                }
                //
            }
            Stats.successfulLookupCount += 1
            uniqueCategoryCounts[descKey, default: 0] += 1

        } else {                   // Here if NOT found in Category-Lookup-by-Vendor Dictionary
            let source = cardType
            // If Transaction-Line has a Category, put it in the Vendor file.

            if hasCatHeader {
                if lineItem.rawCat.count >= 3 {
                    let myCatFromTran  = dictMyCatAliases[lineItem.rawCat] ?? "?" + lineItem.rawCat

                    if dictMyCatAliases[myCatFromTran] == nil {
                        print("HandleCards#\(#line): Unknown Category: \"\(myCatFromTran)\" from \(descKey)")
                        //
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
    }//endif descKey not empty

    return lineItem
}//end func makeLineItem

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
//---- pickTheBestCat - All else being equal, catItem1 is returned
internal func pickTheBestCat(catItem1: CategoryItem, catItem2: CategoryItem) -> CategoryItem {
    let cat1 = catItem1.category
    let cat2 = catItem2.category
    if cat1 == cat2                                 { return catItem1 } // Both the same.
    if cat1.isEmpty || cat1 == "?"                  { return catItem2 } // cat1 missing
    if cat2.isEmpty || cat2 == "?"                  { return catItem1 } // cat2 missing
    if cat1.hasPrefix("?") && !cat2.hasPrefix("?")  { return catItem2 } // use the cat with no "?"
    if cat2.hasPrefix("?") && !cat1.hasPrefix("?")  { return catItem1 } //      "
    if cat2.contains("Unkno")                       { return catItem1 } // "Unknown"
    if cat1.contains("Unkno")                       { return catItem2 } //      "
    if cat2.contains("Merch")                       { return catItem1 } // "Merchandise" is weak
    if cat1.contains("Merch")                       { return catItem2 } //      "
    return catItem1
}
