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
    var idNumber = ""       // Card Number (last 4) or Check Number
    var descKey  = ""       // Generated Key for this desc. (vendor)
    var desc     = ""       // Description (Vendor)
    var debit    = 0.0      // Debit (payments to vendors, etc.)
    var credit   = 0.0      // Credit (Credit-Card payments, refunds, etc.)
    var rawCat   = ""       // Category from Tansaction
    var genCat   = ""       // Generated Category
    var catSource = ""      // Source of Generated Category (including "$" for "LOCKED")
    var transText = ""      // Original Transaction Line from file
    var memo      = ""
    var auditTrail = ""     // Original FileName, Line#

    init() {
    }

    //MARK:- init - 33-121 = 88-lines
    //TODO: Allow LineItem.init to throw errors
    // Create a LineItem from a Transaction-File line
    init(fromTransFileLine: String, dictColNums: [String: Int], fileName: String, lineNum: Int) {
        let expectedColumnCount = dictColNums.count

        //TODO: Make debitSign a property of CreditCardType
        let debitSign: Double
        if fileName.hasPrefix("BA") || fileName.hasPrefix("MLCMA") {
            debitSign = -1
        }
        else {
            debitSign = 1
        }

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
                self.idNumber = columns[colNum]
            }
        }

        if let colNum = dictColNums["NUMBER"] { // CHECK NUMBER
            if colNum < columnCount {
                var num = columns[colNum]
                num = num.replacingOccurrences(of: "[*#,$]", with: "", options: .regularExpression, range: nil).trim
                num = String(num.suffix(6))
                if num == "0" || num == "00" || (num.prefix(3) == "000" && num.suffix(3) == "000") {
                    num = ""
                } else {
                    //num = num
                }
                self.idNumber = num
            }
        }

        if let colNum = dictColNums["CATE"] {   // CATEGORY
            if colNum < columnCount {
                let assignedCat =  columns[colNum]
                let myCat = gDictMyCatAliases[assignedCat] ?? assignedCat
                self.rawCat = myCat
            }
        }
        //TODO: Detect & report corrupt $values rather than silently setting to $0
        if let colNum = dictColNums["AMOU"] {   // AMOUNT
            if colNum < columnCount {
                let amt = columns[colNum].replacingOccurrences(of: ";", with: "") //"0" is for empty fields
                let amount = Double(amt) ?? 0
                if amount*debitSign < 0 {
                    self.credit = abs(amount)
                } else {
                    self.debit = abs(amount)
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

        let (cleanName, _) = fileName.splitAtFirst(char: ".")
        self.auditTrail = "\(cleanName)#\(lineNum)"
    }//end init

    func signature() -> String {
        //let (cleanName, _) = self.auditTrail.splitAtFirst(char: "#")
        //let useName = cleanName.replacingOccurrences(of: "-", with: "")
        let dateStr = makeYYYYMMDD(dateTxt: self.tranDate)
        let vendr   = self.descKey.prefix(4)
        let credit  =  String(format: "%.2f", self.credit)
        let debit   =  String(format: "%.2f", self.debit)
        let sig = "\(self.cardType)|\(dateStr)|\(self.idNumber)|\(vendr)|\(credit)|\(debit)"
        return sig
    }

    // Equatable - Ignore Category-info & truncate desc & auditTrail
    static public func == (lhs: LineItem, rhs: LineItem) -> Bool {
        return lhs.cardType == rhs.cardType &&
            lhs.tranDate    == rhs.tranDate &&
            lhs.idNumber    == rhs.idNumber &&
            lhs.desc.prefix(8) == rhs.desc.prefix(8)  &&
            lhs.debit       == rhs.debit &&
            lhs.credit      == rhs.credit
    }

    // Hashable - Ignore Category-info & truncate desc & auditTrail
    public func hash(into hasher: inout Hasher) {
        hasher.combine(cardType)
        hasher.combine(tranDate)
        hasher.combine(idNumber)
        hasher.combine(desc.prefix(8))
        hasher.combine(debit)
        hasher.combine(credit)
    }

}//end struct LineItem
