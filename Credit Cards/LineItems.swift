//
//  LineItems.swift
//  Credit Cards
//
//  Created by Lenard Howell on 7/29/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Foundation
public struct LineItem {
    var cardType = ""
    var tranDate = ""
    var postDate = ""
    var cardNum  = ""
    var desc     = ""
    var debit    = 0.0
    var credit   = 0.0
    var genCat   = ""       // Generated Category
    var rawCat   = ""
    var catSource = ""

    init() {
    }

    //MARK:- init - 28-83 = 55-lines
    //  fileName: String, lineNum: Int only needed for err handling
    //TODO: Allow LineItem.init to throw errors
    init(fromTransFileLine: String, dictColNums: [String: Int], fileName: String, lineNum: Int) {
        let expectedColumnCount = dictColNums.count

        var transaction = fromTransFileLine
        // Parse transaction, replacing all "," within quotes with a ";"
        var inQuote = false
        var tranArray = Array(fromTransFileLine)     // Create an Array of Individual characters in current transaction.

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
        let columnCount = columns.count
        if columnCount != expectedColumnCount {
            let msg = "\(columnCount) in transaction; should be \(expectedColumnCount)"
            handleError(codeFile: "LineItems", codeLineNum: #line, type: .dataError, action: .display,  fileName: fileName, dataLineNum: lineNum, lineText: fromTransFileLine, errorMsg: msg)
        }
        // Building the lineitem record
        if let colNum = dictColNums["TRAN"] {
            if colNum < columnCount {
                self.tranDate = columns[colNum]
            }
        }
        if let colNum = dictColNums["POST"] {
            if colNum < columnCount {
                self.postDate = columns[colNum]
            }
        }
        if let colNum = dictColNums["DESC"] {
            if colNum < columnCount {
                self.desc = columns[colNum].replacingOccurrences(of: "\"", with: "")
                if self.desc.trim.isEmpty {
                    print("LineItems #\(#line) - Empty Description\n\(transaction)")
                }
            }
        }
        if let colNum = dictColNums["CARD"] {
            if colNum < columnCount {
                self.cardNum = columns[colNum]
            }
        }
        if let colNum = dictColNums["CATE"] {
            if colNum < columnCount {
                self.rawCat = columns[colNum]
            }
        }
        if let colNum = dictColNums["AMOU"] {
            if colNum < columnCount {
                let amount = Double(columns[colNum].trim) ?? 0
                if amount < 0 {
                    self.credit = -amount
                } else {
                    self.debit = amount
                }
            }
        }
        if let colNum = dictColNums["CRED"] {
            if colNum < columnCount {
                self.credit = Double(columns[colNum].trim) ?? 0
            }
            
        }
        if let colNum = dictColNums["DEBI"] {
            if colNum < columnCount {
                self.debit = Double(columns[colNum].trim) ?? 0
            }
            
        }
    }//end init

}//end class LineItem
