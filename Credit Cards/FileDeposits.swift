//
//  FileDeposits.swift
//  Credit Cards
//
//  Created by George Bauer on 12/15/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Foundation

//MARK:- Read Deposits
func readDeposits(testData: String = "") {
    // Find the Deposit file
    let pathURL = FileIO.getPossibleParentFolder(myURL: gUrl.transactionFolder)
    let fileURL = pathURL.appendingPathComponent("DEPOSITcsv.csv")
    let content = (try? String(contentsOf: fileURL)) ?? ""
    if content.isEmpty {
        let msg = "\(fileURL.path) does not exist."
        handleError(codeFile: "FileIO", codeLineNum: #line, type: .dataWarning, action: .alert, fileName: "DEPOSIT.csv", dataLineNum: 0, lineText: "", errorMsg: msg)
        return
    }

    let lines   = content.components(separatedBy: "\n").map {$0.trim}
    let headers = lines[0].components(separatedBy: ",")
    let acct    = Account(code: "DEPOS", name: "DEPOSIT", type: .deposit, amount: .credit)
    let dictColNums = makeDictColNums(headers: headers)
    var firstDate   = Stats.firstDate
    var lastDate    = Stats.lastDate

    // Optimize Dates for calandar years
    (firstDate, lastDate) = optimizeDatesForDeposits(firstDate: firstDate, lastDate: lastDate)

    var calcSum     = 0.0
    var postDate    = ""
    var got1        = false
    var errorCount  = 0
    var checkCount  = 0
    var depositCount = 0
    for (idx, line) in lines.enumerated() {
        if line.hasPrefix(",,,,") {
            continue                            // Blank line
        }

        // Ignore
        let items = FileIO.parseDelimitedLine(line, csvTsv: .csv)
        if items[0].hasSuffix("Missing") {
            continue
        }

        let chkDate = FileIO.convertToYYYYMMDD(dateTxt: items[1])
        if line.hasPrefix("Deposit") {          // "Deposit mm/dd/yy" or "Deposit, mm/dd/yy"
            if items[0] == "Deposit" && chkDate != "?" {
                postDate = chkDate
            } else {
                let tuple = items[0].splitAtFirst(char: " ")
                postDate = FileIO.convertToYYYYMMDD(dateTxt: tuple.1)
            }
            if postDate == "?" {
                print("😡 FileDeposits#\(#line) Deposit.csv line \(idx+1) Bad Date: \"\(items[1])\",  \(line)")//(idx+1,desc,chkDate,credit)
                errorCount += 1
            }
            calcSum = 0.0
            got1 = true
            continue
        }

        if !got1 { continue }                       // Waiting for 1st Deposit


        let valStr = items[3]
        let optVal = textToDbl(valStr)

        // "Total" line
        if items[0].isEmpty && !valStr.isEmpty {        // Total $
            depositCount += 1
            if let total = optVal {
                if abs(calcSum - total) > 0.004 {
                    print("⛔️ FileDeposits#\(#line) Deposit.csv line \(idx+1)  \(calcSum) != \(total)")
                    errorCount += 1
                }
            } else {
                print("😡 FileDeposits#\(#line) Deposit.csv line \(idx+1) \(valStr)")//(idx+1,desc,chkDate,credit)
                errorCount += 1
            }
            continue
        }

        //print("FileDeposits#\(#line)  Deposit.csv line \(idx+1)  \(items)")
        let desc = items[0]
        if chkDate == "2008-08-08" {
            // Debug Trap
        }
        if let credit = optVal {
            // ------ Here to record this Deposit LineItem ------
            //print("🤪 FileDeposits#\(#line) Deposit.csv line \(idx+1) \(desc) \(chkDate) \(credit)")//(idx+1,desc,chkDate,credit)
            if chkDate == "?" && credit != 0 {
                print("😡 FileDeposits#\(#line) Deposit.csv line \(idx+1) Bad Date: \"\(items[1])\",  \(line)")//(idx+1,desc,chkDate,credit)
                errorCount += 1
            }
            var lineItem = makeLineItem(fromTransFileLine: line, dictColNums: dictColNums, dictVendorShortNames: gDictVendorShortNames, cardType: "DEPOSIT", hasCatHeader: true, fileName: "DepositCsv.csv", lineNum: idx+1, acct: acct)
            lineItem.postDate = postDate

            if lineItem.tranDate >= firstDate && lineItem.tranDate <= lastDate {
                gLineItemArray.append(lineItem)
                if lineItem.descKey.contains("WINAN") {
                    //print("")     //Debug Trap
                }
            }
            calcSum += credit
            checkCount += 1

        } else {    // Bad $-Value
            print("😡 FileDeposits#\(#line) Bad $-Amount: Deposit.csv line \(idx+1) \(desc) \(chkDate) \(valStr)")//(idx+1,desc,chkDate,credit)
            errorCount += 1
        }
    }//next line

    if errorCount == 0 {
        print("🤪 FileDeposits#\(#line) Deposit.csv sucessfully read \(lines.count) lines, \(checkCount) checks, \(depositCount) deposits")
    } else {
        print("😡 FileDeposits#\(#line) Deposit.csv read \(lines.count) lines, \(depositCount) deposits with \(errorCount) errors.")
    }
}//end func readDeposits

internal func optimizeDatesForDeposits(firstDate: String, lastDate: String) -> (String, String) {
    // Optimize Dates for calandar years
    var firstDate = firstDate
    var lastDate = lastDate
    let ymd1  = firstDate.components(separatedBy: "-")
    let ymd2  = lastDate.components(separatedBy: "-")
    let mo1 = ymd1[1]
    let mo2 = ymd2[1]
    let yr1 = Int(ymd1[0]) ?? 0
    let yr2 = Int(ymd2[0]) ?? 0
    if (yr1 == yr2) && mo1 == "01" && mo2 == "12" {
        firstDate = "\(yr2)-01-01"
        lastDate  = "\(yr2)-12-31"
    } else if (yr2-yr1 > 0) && (mo2 == "12" && (mo1 == "11" || mo1 == "12")) {
        firstDate = "\(yr1+1)-01-01"
        lastDate  = "\(yr2)-12-31"
    } else {
        firstDate = "\(yr1)-\(mo1)-01"
    }
    lastDate = "\(yr2)-\(mo2)-31"
    return (firstDate, lastDate)

}
