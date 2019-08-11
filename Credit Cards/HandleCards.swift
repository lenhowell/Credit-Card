//
//  HandleCards.swift
//  Credit Cards
//
//  Created by Lenard Howell on 8/9/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Foundation

//---- handleCards -
// uses Global Vars: descKeyLength(const), descKeysuppressionList(const)
//                   dictCategory(I/O), successfulLookupCount(I/O), addedCatCount(I/O)
func handleCards(fileName: String, cardArray: [String]) -> [LineItem] {
    let cardType = String(fileName.prefix(3).uppercased())
    var lineItemArray = [LineItem]()                // Create Array variable(lineItemArray) Type lineItem.
    let cardArrayCount = cardArray.count
    
    // Derive a Dictionary of Column Numbers from header
    var lineNum = 0
    var headers = [String]()
    while lineNum < cardArrayCount {
        let components = cardArray[lineNum].components(separatedBy: ",")
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
        transaction = String(tranArray).uppercased()    // Covert the Parsed "Array" Item Back to a string
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
                print("\(#line)\n\(transaction)")
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

        //            print("Description is \(lineItem.desc)\n")
        //        if lineItem.desc.uppercased().contains("STOP & SHOP")
        //            {
        //                print("Key Word SHELL found in \(lineItem.desc.uppercased())")
        //            }
        lineItem.cardType = cardType
        lineItem.genCat = ""                          // Initialze the Generated Category
        var key = lineItem.desc.uppercased()
        //            key = key.replacingOccurrences(of: "\"", with: "")    // Remove Single Quotes from Key
        //            key = key.replacingOccurrences(of:  " ", with: "")    // Compress key
        //            key = key.replacing Occurrences(of:  ";", with: "")    // Remove semi-colons from Key
        key = key.replacingOccurrences(of: "["+descKeysuppressionList+"]", with: "", options: .regularExpression, range: nil)
        key = String(key.prefix(descKeyLength))    // Truncate
        if !key.isEmpty {
            if let catItem = dictCategory[key] {      // Here if Lookup of KEY was successfull
                lineItem.genCat = catItem.category
                lineItem.catSource = catItem.source
                successfulLookupCount += 1
                uniqueCategoryCounts[key, default: 0] += 1
            } else {    //Here if Lookup in Category Dictionary NOT Successfull
                let source = cardType
                print("          Did Not Find ",key)
                let catItem = CategoryItem(category: lineItem.rawCat, source: source)
                let rawCat = catItem.category
                if rawCat.count >= 3 {
                    dictCategory[key] = catItem //Do Actual Insert
                    addedCatCount += 1
                    print("Category that was inserted = Key==> \(key) Value ==> \(lineItem.rawCat) Source ==> \(source)")
                    
                } else {
                    handleError(codeFile: "HandleCards", codeLineNum: #line, type: .dataWarning, action: .printOnly, fileName: fileName, dataLineNum: lineNum, lineText: tran, errorMsg: "Category too short to be legit.")
                }
            }
            lineItemArray.append(lineItem)          // Add new output Record to be output
        }
    }// End of FOR loop
    return lineItemArray
}//end func handleCards
