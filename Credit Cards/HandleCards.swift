//
//  HandleCards.swift
//  Credit Cards
//
//  Created by Lenard Howell on 8/9/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Foundation

//---- handleCards -
// uses Global Vars: dictCategory(I/O), Stats(I/O)
func handleCards(fileName: String, cardType: String, cardArray: [String]) -> [LineItem] {
    let cardArrayCount = cardArray.count
    var lineItemArray = [LineItem]()                // Create Array variable(lineItemArray) Type lineItem.

    //MARK: Read Header
    // Derive a Dictionary of Column Numbers from header
    var lineNum = 0
    var headerLine = ""
    var headers = [String]()
    while lineNum < cardArrayCount {
        headerLine = cardArray[lineNum]
        let components = headerLine.components(separatedBy: ",")
        lineNum += 1
        if components.count > 2  {
            headers = components
            //print (lineNum, cardArray[lineNum])
            break
        }
    }
    if headers.isEmpty {
        handleError(codeFile: "HandleCards", codeLineNum: #line, type: .dataError, action: .alertAndDisplay,  fileName: fileName, dataLineNum: lineNum, lineText: "", errorMsg: "Headers not found.")
        return lineItemArray
    }
    let expectedColumnCount = headers.count
    var dictColNums = [String: Int]()
    for colNum in 0..<expectedColumnCount {
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

    let hasCatHeader: Bool
    if dictColNums["CATE"] == nil {
        hasCatHeader = false
        let msg = "No \"Catagory\" in Headers"
        handleError(codeFile: "HandleCards", codeLineNum: #line, type: .dataWarning, action: .display, fileName: fileName, dataLineNum: lineNum, lineText: headerLine, errorMsg: msg)
    } else {
        hasCatHeader = true
    }

    //MARK: Read Transactions
    // Read Transctions
    while lineNum < cardArrayCount {
        let tran = cardArray[lineNum]
        lineNum += 1
        if tran.trim.isEmpty { continue }
        var transaction = tran
        // Parse transaction, replacing all "," within quotes with a ";"
        var inQuote = false
        var tranArray = Array(tran)     // Create an Array of Individual characters in current transaction.
        
        for (i,char) in tranArray.enumerated() {
            if char == "\"" {
                inQuote = !inQuote      // Flip the switch indicating a quote was found.
            }
            if inQuote && char == "," {
                tranArray[i] = ";"      // Comma within a quoted string found, replace with a ";".
            }
        }
        transaction = String(tranArray) //.uppercased()    // Covert the Parsed "Array" Item Back to a string
        transaction = transaction.replacingOccurrences(of: "\"", with: "")
        transaction = transaction.replacingOccurrences(of: "\r", with: "")
        let columns = transaction.components(separatedBy: ",")  // Isolate columns within this transaction
        if columns.count != expectedColumnCount {
            let msg = "\(columns.count) in transaction; should be \(expectedColumnCount)"
            handleError(codeFile: "HandleCards", codeLineNum: #line, type: .dataError, action: .display,  fileName: fileName, dataLineNum: lineNum, lineText: tran, errorMsg: msg)
        }
        var lineItem = LineItem()
        // Building the lineitem record
        lineItem.tranDate = columns[dictColNums["TRAN"]!]
        if let colNum = dictColNums["POST"] {
            lineItem.postDate = columns[colNum]
        }
        if let colNum = dictColNums["DESC"] {
            lineItem.desc = columns[colNum].replacingOccurrences(of: "\"", with: "")
            if lineItem.desc.trim.isEmpty {
                print("HandleCards #\(#line) - Empty Description\n\(transaction)")
            }
        }
        if let colNum = dictColNums["CARD"] {
            lineItem.cardNum = columns[colNum]
        }
        if let colNum = dictColNums["CATE"] {
            lineItem.rawCat = columns[colNum]
        }
        if let colNum = dictColNums["AMOU"] {
            let amount = Double(columns[colNum].trim) ?? 0
            if amount < 0 {
                lineItem.credit = -amount
            } else {
                lineItem.debit = amount
            }
        }
        if let colNum = dictColNums["CRED"] {
            lineItem.credit = Double(columns[colNum].trim) ?? 0
        }
        if let colNum = dictColNums["DEBI"] {
            lineItem.debit = Double(columns[colNum].trim) ?? 0
        }

        lineItem.cardType = cardType
        lineItem.genCat = ""                            // Initialze the Generated Category
        var descKey = lineItem.desc
        descKey = makeDescKey(from: descKey, fileName: fileName)

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
                        // print("Category that was inserted = Key==> \(key) Value ==> \(lineItem.rawCat) Source ==> \(source)")
                    } else {
                        Stats.descWithNoCat += 1
                        handleError(codeFile: "HandleCards", codeLineNum: #line, type: .dataWarning, action: .printOnly, fileName: fileName, dataLineNum: lineNum, lineText: tran, errorMsg: "Raw Category too short to be legit: \"\(rawCat)\"")
                    }
                } else {
                    Stats.descWithNoCat += 1
                }
            }
            lineItemArray.append(lineItem)          // Add new output Record to be output
        }
    }// End of FOR loop

    return lineItemArray
}//end func handleCards
