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
    var cardType    = ""    // Identifies the Credit-Card account
    var tranDate    = ""    // Transaction-Date String
    var postDate    = ""    // Post-Date String
    var chkNumber   = ""    // Check Number
    var descKey     = ""    // Generated Key for this desc. (vendor)
    var desc        = ""    // Description (Vendor)
    var debit       = 0.0   // Debit (payments to vendors, etc.)
    var credit      = 0.0   // Credit (Credit-Card payments, refunds, etc.)
    var rawCat      = ""    // Category from Tansaction
    var genCat      = ""    // Generated Category
    var catSource   = ""    // Source of Generated Category (including "$" for "LOCKED", "*" for Modified)
    var transText   = ""    // Original Transaction Line from file
    var memo        = ""    // Check Memo or Note added when modified
    var auditTrail  = ""    // Original FileName, Line#
    let codeFile = "LineItems"
    init() {
    }

    //MARK:- init - 34-135 = 101-lines
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
                //self.chkNumber = columns[colNum]
            }
        }

        if let colNum = dictColNums["NUMBER"] {         // CHECK NUMBER
            if colNum < columnCount {
                var numStr = columns[colNum]
                numStr = numStr.replacingOccurrences(of: "[*#,$]", with: "", options: .regularExpression, range: nil).trim
                if !numStr.isEmpty {
                    if let num = Int(numStr) {
                        if num != 0 { self.chkNumber = "\(num)" }
                    } else{
                        //
                    }
                }
            }
        }

        if let colNum = dictColNums["CATE"] {           // CATEGORY
            if colNum < columnCount {
                var assignedCat =  columns[colNum]
                if assignedCat.hasPrefix("Check ") {
                    let (_, chkNum) = assignedCat.splitAtFirst(char: " ")
                    if chkNum == "3704" {
                        print("LineItems #\(#line) - \(assignedCat)\n\(fromTransFileLine)")
                        //
                    }
                    self.chkNumber = chkNum
                    assignedCat = ""
                }
                if assignedCat.trim.isEmpty { assignedCat = "Unknown" }
                let myCat = gDictMyCatAliases[assignedCat.uppercased()] ?? ""
                //self.rawCat = myCat
                self.rawCat = assignedCat //%%%%%%%
                self.genCat = myCat

            }
        } else {
            self.rawCat = "Unknown"
        }

        if let colNum = dictColNums["AMOU"] {           // AMOUNT
            if colNum < columnCount {
                var amtStr = columns[colNum].replacingOccurrences(of: ";", with: "") //"0" is for empty fields
                if amtStr.hasPrefix("(") && amtStr.hasSuffix(")") {
                    amtStr = "-\(amtStr.dropFirst().dropLast())"
                }

                var amount = 0.0
                if let amt = textToDbl(amtStr) {
                    amount = amt
                } else {
                    let msg = "Bad value for Amount \"\(amtStr)\""
                    handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .alertAndDisplay, errorMsg: msg)
                }

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
    func signature(usePostDate: Bool = false, ignoreVendr: Bool = false, ignoreDate: Bool = false) -> String {
        // CardType + Date + ID# + 1st4ofDesc + credit + debit
        //let (cleanName, _) = self.auditTrail.splitAtFirst(char: "#")
        //let useName = cleanName.replacingOccurrences(of: "-", with: "")
        var dateStr = self.tranDate
        if usePostDate { dateStr = self.postDate }

        let vendr   = self.descKey.prefix(4)
        let credit  = String(format: "%.2f", self.credit)
        let debit   = String(format: "%.2f", self.debit)
        let chkNum = self.chkNumber.trim
        var sig = ""
        if chkNum.isEmpty {
            if ignoreVendr {
                sig = "\(dateStr)|\(credit)|\(debit)"
            } else if ignoreDate {
                sig = "\(vendr)|\(credit)|\(debit)"
            } else {
                sig = "\(dateStr)|\(vendr)|\(credit)|\(debit)"
            }
        } else {
            sig = "\(chkNum)|\(vendr)|\(credit)|\(debit)"
        }
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
            lhs.chkNumber    == rhs.chkNumber &&
            lhs.desc.prefix(8) == rhs.desc.prefix(8)  &&
            lhs.debit       == rhs.debit &&
            lhs.credit      == rhs.credit
    }

    // Hashable - Ignore Category-info & truncate desc & auditTrail
    public func hash(into hasher: inout Hasher) {
        hasher.combine(cardType)
        hasher.combine(tranDate)
        hasher.combine(chkNumber)
        hasher.combine(desc.prefix(8))
        hasher.combine(debit)
        hasher.combine(credit)
    }

}//end struct LineItem
