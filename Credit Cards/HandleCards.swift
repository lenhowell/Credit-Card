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


//MARK:---- makeLineItem - 68-104 = 36-lines
// uses Global Vars: dictCategory(I/O), Stats(I/O)
internal func makeLineItem(fromTransFileLine: String, dictColNums: [String: Int], cardType: String, hasCatHeader: Bool, fileName: String, lineNum: Int) -> LineItem {

    var lineItem = LineItem(fromTransFileLine: fromTransFileLine, dictColNums: dictColNums, fileName: fileName, lineNum: lineNum)
    lineItem.cardType = cardType

    let descKey = makeDescKey(from: lineItem.desc, fileName: fileName)

    if !descKey.isEmpty {
        if let catItem = dictCategory[descKey] {
            lineItem.genCat = catItem.category      // Here if Lookup of KEY was successful
            lineItem.catSource = catItem.source
            Stats.successfulLookupCount += 1
            uniqueCategoryCounts[descKey, default: 0] += 1
        } else {
            let source = cardType                   // Here if NOT in Category Dictionary
            //print("          Did Not Find ",key)

            if hasCatHeader {
                let catItem = CategoryItem(category: lineItem.rawCat, source: source)
                let rawCat = catItem.category

                if rawCat.count >= 3 {
                    dictCategory[descKey] = catItem //Do Actual Insert
                    Stats.addedCatCount += 1
                    // print("Category that was inserted = Key==> \(key) Value ==> \(self.rawCat) Source ==> \(source)")
                } else {
                    Stats.descWithNoCat += 1
                    handleError(codeFile: "LineItems", codeLineNum: #line, type: .dataWarning, action: .printOnly, fileName: fileName, dataLineNum: lineNum, lineText: fromTransFileLine, errorMsg: "Raw Category too short to be legit: \"\(rawCat)\"")
                }
            } else {
                Stats.descWithNoCat += 1
            }
        }
    }//endif descKey not empty

    return lineItem
}//end func makeLineItem

//MARK:---- makeDictColNums - 108-126 = 18-lines

func makeDictColNums(headers: [String]) -> [String: Int] {
    var dictColNums = [String: Int]()
    for colNum in 0..<headers.count {
        let rawKey = headers[colNum].uppercased().trim.replacingOccurrences(of: "\"", with: "")
        let key: String
        if rawKey == "DATE" {
            key = "TRAN"
        } else if rawKey.hasPrefix("ORIG") && rawKey.hasSuffix("DESCRIPTION") { //
            key = "DESC"
        } else if rawKey.hasPrefix("MERCH") && rawKey.hasSuffix("CATEGORY") {   // Handle "Merchant Category"
            key = "CATE"
        } else {
            key = String(rawKey.replacingOccurrences(of: "\"", with: "").prefix(4))
        }
        dictColNums[key] = colNum
    }//next colNum

    return dictColNums
}
