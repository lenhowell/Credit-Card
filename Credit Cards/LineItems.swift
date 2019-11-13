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
    var catSource = ""      // Source of Generated Category (including "$" for "LOCKED", "*" for Modified)
    var transText = ""      // Original Transaction Line from file
    var memo      = ""
    var auditTrail = ""     // Original FileName, Line#

    init() {
    }

    //MARK:- init - 34-129 = 95-lines
    //TODO: Allow LineItem.init to throw errors
    // Create a LineItem from a Transaction-File line
    init(fromTransFileLine: String, dictColNums: [String: Int], fileName: String, lineNum: Int, signAmount: Double) {
        let expectedColumnCount = dictColNums.count

        self.transText = fromTransFileLine.trim // TRANSACTION TEXT
        var csvTsv = FileIO.CsvTsv.tsv
        if fileName.lowercased().hasSuffix(".csv") {
            csvTsv = .csv
        }
        // Parse transaction, replacing all "," within quotes with a ";"
        let columns = FileIO.parseDelimitedLine(fromTransFileLine, csvTsv: csvTsv)

        let columnCount = columns.count
        if columnCount != expectedColumnCount {
            let msg = "\(columnCount) in transaction; should be \(expectedColumnCount)"
            handleError(codeFile: "LineItems", codeLineNum: #line, type: .dataError, action: .display,  fileName: fileName, dataLineNum: lineNum, lineText: fromTransFileLine, errorMsg: msg)
        }

        // Building the lineitem record
        if let colNum = dictColNums["TRAN"] {           // TRANSACTION DATE
            if colNum < columnCount {
                self.tranDate = convertToYYYYMMDD(dateTxt: columns[colNum]) // = columns[colNum]
            }
        }

        if let colNum = dictColNums["POST"] {           // POST DATE
            if colNum < columnCount {
                self.postDate = convertToYYYYMMDD(dateTxt: columns[colNum]) // = columns[colNum]
            }
        }

        if let colNum = dictColNums["DESC"] {           // DESCRIPTION
            if colNum < columnCount {
                self.desc = columns[colNum].replacingOccurrences(of: "\"", with: "")
                if self.desc.isEmpty {
                    print("LineItems #\(#line) - Empty Description\n\(fromTransFileLine)")
                }
            }
        }
        if let colNum = dictColNums["CARD"] {           // CARD NUMBER
            if colNum < columnCount {
                self.idNumber = columns[colNum]
            }
        }

        if let colNum = dictColNums["NUMBER"] {         // CHECK NUMBER
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

        if let colNum = dictColNums["CATE"] {           // CATEGORY
            if colNum < columnCount {
                let assignedCat =  columns[colNum]
                let myCat = gDictMyCatAliases[assignedCat] ?? assignedCat
                //self.rawCat = myCat
                self.rawCat = assignedCat //%%%%%%%
                self.genCat = myCat

            }
        }
        //TODO: Detect & report corrupt $values rather than silently setting to $0
        if let colNum = dictColNums["AMOU"] {           // AMOUNT
            if colNum < columnCount {
                var amt = columns[colNum].replacingOccurrences(of: ";", with: "") //"0" is for empty fields
                if amt.hasPrefix("(") && amt.hasSuffix(")") {
                    amt = "-\(amt.dropFirst().dropLast())"
                }
                let amount = Double(amt) ?? 0

                if amount*signAmount < 0 {
                    self.credit = abs(amount)
                } else {
                    self.debit = abs(amount)
                }
            }
        }
        if let colNum = dictColNums["CRED"] {           // CREDIT
            if colNum < columnCount {
                let amt = columns[colNum].replacingOccurrences(of: ";", with: "")
                self.credit = abs(Double(amt) ?? 0)
            }
        }
        if let colNum = dictColNums["DEBI"] {           // DEBIT
            if colNum < columnCount {
                let amt = columns[colNum].replacingOccurrences(of: ";", with: "").trim
                self.debit = abs(Double(amt) ?? 0)
            }
        }

        self.auditTrail = "\(fileName)#\(lineNum)"     // AUDIT TRAIL
    }//end init

    //---- signature - Unique identifier for detecting Transaction dupes & user-modified versions.
    func signature() -> String {
        // CardType + Date + ID# + 1st4ofDesc + credit + debit
        //let (cleanName, _) = self.auditTrail.splitAtFirst(char: "#")
        //let useName = cleanName.replacingOccurrences(of: "-", with: "")
        let dateStr = self.tranDate                                 // convertToYYYYMMDD(dateTxt: self.tranDate)
        let vendr   = self.descKey.prefix(4)
        let credit  = String(format: "%.2f", self.credit)
        let debit   = String(format: "%.2f", self.debit)
        let sig = "\(self.cardType)|\(dateStr)|\(self.idNumber)|\(vendr)|\(credit)|\(debit)"
        return sig
    }

    //---- convertToYYYYMMDD - Convert date from Transaction from m/d/y to YYYY-MM-DD or "?"
    func convertToYYYYMMDD(dateTxt: String) -> String {
        var dateStr = ""
        let da = dateTxt
        if da.contains("/") {
            let parts = da.components(separatedBy: "/")
            if parts.count != 3 {
                return "?"
            }
            var yy = parts[2].trim
            if yy.count <= 2 { yy = "20" + yy }
            var mm = parts[0].trim
            if mm.count < 2 { mm = "0" + mm }
            var dd = parts[1].trim
            if dd.count < 2 { dd = "0" + dd }
            dateStr = "\(yy)-\(mm)-\(dd)"
        } else if da.contains("-") {
            dateStr = da
        } else {
            return "?"
        }
        return dateStr
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
