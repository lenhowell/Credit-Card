//
//  LineItems.swift
//  Credit Cards
//
//  Created by George Bauer on 7/29/19.
//  Copyright © 2019-2021 George Bauer. All rights reserved.
//

import Foundation

//FIXIT: tranDate should be of type Date, for comparing
public struct LineItem: Equatable, Hashable {
    static let codeFile = "LineItems"   // for error logging
    var cardType    = ""    // Identifies the Credit-Card account
    var tranDate    = ""    // Transaction-Date String
    var postDate    = ""    // Post-Date String
    var chkNumber   = ""    // Check Number
    var descKey     = ""    // Generated Key for this desc. (vendor)
    var desc        = ""    // Description (Vendor)
    var debit       = 0.0   // Debit (payments to vendors, etc.)
    var credit      = 0.0   // Credit (Credit-Card payments, refunds, etc.)
    var rawCat      = ""    // Category from Transaction
    var genCat      = ""    // Generated Category
    var catSource   = ""    // Source of Generated Category (including "$" for "LOCKED", "*" for Modified)
    var transText   = ""    // Original Transaction Line from file
    var memo        = ""    // Check Memo or Note added when modified
    var auditTrail  = ""    // Original FileName, Line#
    var modifiedKey = ""    // Key to Glob.dictModifiedTrans entry

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


    // Equatable - Ignore Category-info & truncate desc
    static public func == (lhs: LineItem, rhs: LineItem) -> Bool {
        return lhs.cardType == rhs.cardType &&
            lhs.tranDate    == rhs.tranDate &&
            lhs.chkNumber    == rhs.chkNumber &&
            lhs.desc.prefix(8) == rhs.desc.prefix(8)  &&
            lhs.debit       == rhs.debit &&
            lhs.credit      == rhs.credit
    }

    // Hashable - Ignore Category-info & truncate desc
    public func hash(into hasher: inout Hasher) {
        hasher.combine(cardType)
        hasher.combine(tranDate)
        hasher.combine(chkNumber)
        hasher.combine(desc.prefix(8))
        hasher.combine(debit)
        hasher.combine(credit)
    }

}//end struct LineItem

extension LineItem {

    //MARK: - init - 84-207 = 123-lines
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
            let msg = "\(columnCount) column(s) in transaction; should be \(expectedColumnCount)"
            handleError(codeFile: "LineItems", codeLineNum: #line, type: .dataError, action: .display,  fileName: fileName, dataLineNum: lineNum, lineText: fromTransFileLine, errorMsg: msg)
        }

        // Building the lineitem record
        if let colNum = dictColNums["TRAN"] {           // TRANSACTION DATE
            if colNum < columnCount {
                self.tranDate = FileIO.convertToYYYYMMDD(dateTxt: columns[colNum]) // = columns[colNum]
            }
        }

        if let colNum = dictColNums["POST"] {           // POST DATE
            if colNum < columnCount {
                self.postDate = FileIO.convertToYYYYMMDD(dateTxt: columns[colNum]) // = columns[colNum]
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

        if let colNum = dictColNums["MEMO"] {           // MEMO
            if colNum < columnCount {
                self.memo = columns[colNum]
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
                if assignedCat.trim.isEmpty { assignedCat = Const.unknown }
                let myCat = gCatagories.dictCatAliases[assignedCat.uppercased()] ?? "" 
                //self.rawCat = myCat
                self.rawCat = assignedCat //%%%%%%%
                self.genCat = myCat

            }
        } else {
            self.rawCat = Const.unknown
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
                    handleError(codeFile: LineItem.codeFile, codeLineNum: #line, type: .dataError, action: .alertAndDisplay, errorMsg: msg)
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


    init(type: String, tranDate: String, postDate: String, desc: String, amount: Double, memo: String, auditTrail: String) {
        cardType        = type
        self.tranDate   = FileIO.convertToYYYYMMDD(dateTxt: tranDate)   // TRANSACTION DATE
        self.postDate   = FileIO.convertToYYYYMMDD(dateTxt: postDate)   // POST DATE
        self.desc       = desc                                          // DESC
        if amount > 0.0 {
            self.credit = amount                                        // CREDIT
        } else {
            self.debit  = amount                                        // DEBIT
        }
        self.memo       = memo                                          // MEMO
        self.auditTrail = auditTrail                                    // AUDIT TRAIL
    }

}//end extension
