//
//  LineItems.swift
//  Credit Cards
//
//  Created by Lenard Howell on 7/29/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Foundation

//FIXIT: tranDate should be of type Date, for comparing
public struct LineItem: Equatable, Hashable {
    var cardType = ""       // Identifies the Credit-Card account
    var tranDate = ""       // Transaction-Date String
    var postDate = ""       // Post-Date String
    var cardNum  = ""       // Card Number (last 4)
    var descKey  = ""       // Generated Key for this desc. (vendor)
    var desc     = ""       // Description (Vendor)
    var debit    = 0.0      // Debit (payments to vendors, etc.)
    var credit   = 0.0      // Credit (Credit-Card payments, refunds, etc.)
    var rawCat   = ""       // Category from Tansaction
    var genCat   = ""       // Generated Category
    var catSource = ""      // Source of Generated Category (including "$" for "LOCKED")
    var transText = ""      // Original Transaction Line from file

    init() {
    }

    //MARK:- init - 29-105 = 76-lines
    //  fileName & lineNum only needed for err handling
    //TODO: Allow LineItem.init to throw errors
    // Create a LineItem from a Transaction-File line
    init(fromTransFileLine: String, dictColNums: [String: Int], fileName: String, lineNum: Int) {
        let expectedColumnCount = dictColNums.count

        var transaction = fromTransFileLine.trim
        self.transText = transaction

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
        let columns = transaction.components(separatedBy: ",").map{$0.trim}  // Isolate columns within this transaction
        let columnCount = columns.count
        if columnCount != expectedColumnCount {
            let msg = "\(columnCount) in transaction; should be \(expectedColumnCount)"
            handleError(codeFile: "LineItems", codeLineNum: #line, type: .dataError, action: .display,  fileName: fileName, dataLineNum: lineNum, lineText: fromTransFileLine, errorMsg: msg)
        }
        // Building the lineitem record
        if let colNum = dictColNums["TRAN"] {   // TRANACTION DATE
            if colNum < columnCount {
                self.tranDate = columns[colNum]
            }
        }
        if let colNum = dictColNums["POST"] {   // POST DATE
            if colNum < columnCount {
                self.postDate = columns[colNum]
            }
        }
        if let colNum = dictColNums["DESC"] {   // DESCRIPTION
            if colNum < columnCount {
                self.desc = columns[colNum].replacingOccurrences(of: "\"", with: "")
                if self.desc.isEmpty {
                    print("LineItems #\(#line) - Empty Description\n\(transaction)")
                }
            }
        }
        if let colNum = dictColNums["CARD"] {   // CARD NUMBER
            if colNum < columnCount {
                self.cardNum = columns[colNum]
            }
        }
        if let colNum = dictColNums["CATE"] {   // CATEGORY
            if colNum < columnCount {
                let assignedCat =  columns[colNum]
                let myCat = dictMyCatAliases[assignedCat] ?? assignedCat
                self.rawCat = myCat
            }
        }
        //TODO: Detect & report corrupt $values rather than crashing
        if let colNum = dictColNums["AMOU"] {   // AMOUNT
            if colNum < columnCount {
                let amt = columns[colNum].replacingOccurrences(of: ";", with: "") //"0" is for empty fields
                let amount = Double(amt) ?? 0
                if amount < 0 {
                    self.credit = -amount
                } else {
                    self.debit = amount
                }
            }
        }
        if let colNum = dictColNums["CRED"] {   // CREDIT
            if colNum < columnCount {
                let amt = columns[colNum].replacingOccurrences(of: ";", with: "")
                self.credit = abs(Double(amt) ?? 0)
            }
        }
        if let colNum = dictColNums["DEBI"] {   // DEBIT
            if colNum < columnCount {
                let amt = columns[colNum].replacingOccurrences(of: ";", with: "").trim
                self.debit = abs(Double(amt) ?? 0)
            }
        }
    }//end init


    // Equatable - Ignore Category-info & truncate desc
    static public func == (lhs: LineItem, rhs: LineItem) -> Bool {
        return lhs.cardType == rhs.cardType &&
            lhs.tranDate    == rhs.tranDate &&
            lhs.cardNum     == rhs.cardNum &&
            lhs.desc.prefix(8) == rhs.desc.prefix(8)  &&
            lhs.debit       == rhs.debit &&
            lhs.credit      == rhs.credit
    }

    // Hashable - Ignore Category-info & truncate desc
    public func hash(into hasher: inout Hasher) {
        hasher.combine(cardType)
        hasher.combine(tranDate)
        hasher.combine(cardNum)
        hasher.combine(desc.prefix(8))
        hasher.combine(debit)
        hasher.combine(credit)
    }

}//end struct LineItem
