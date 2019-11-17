//
//  HandleActivity.swift
//  Credit Cards
//
//  Created by George Bauer on 11/2/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Foundation

//MARK:extractTranFromActivity
func extractTranFromActivity(lineItem: LineItem) -> LineItem {  // 12-201 = 189-lines
    var lineItem = lineItem
    // TRAN, DESC, CATE, AMOU
    // ????     "1/3/17,  DIVD REINV: PIMCO INCOME FUND CL C AGENT REINV AMOUNT   $343.88,   Securities Trades,   0.00"
    // CHECK    "1/3/17,  Pre Authdebit DukeEnergy-FL,                                       Utilities,        -156.50"
    // CHECK    "1/13/17, Withdrawal TR TO ML   81217K22,                                    Transfers,       -4400.00"
    // CHECK    "1/11/17, CHECK 3601 PAYEE UNRECORDE,                                        Checks,         -36094.00"
    // CREDCARD "1/4/17,  SXM*SIRIUSXM.COM/ACCT Visa Deferred,                               Other Expenses,    -61.99"
    // CREDCARD "1/12/17, BRIGHT HOUSE NETWORKS Visa Deferred,                               Other Expenses,    -59.21"
    // DIV      "1/9/17,  CDIV: DAF S AND P 500 TRUST 2 HOLDING 5x6398.0000 PAY DATE 01/09,  Other Income,      624.84"
    // DIV      "1/11/17, DIVIDEND: DISNEY (WALT) CO COM STK HOLDING 600.0000 PAY DATE 01/,  Investment Income, 468.00"
    // DIV      "1/13/17, RPT FGN DIV: MEDTRONIC PLC SHS HOLDING 600.0000 PAY DATE 01/13/2,  Investment Income, 258.00"
    // TRANSFER "1/11/17,Funds Transfer WIRE TRF IN Dxxxxxxx1148 ORG=/xxxx9647 TRUFFLE HO,   Transfers,       65789.00"
    // DEPOSIT  "1/18/17,Direct Deposit SSA  TREAS 310,                                      Transfers,        1458.80"

    /*
          0              1                  2               3                  4                    5          6        7            8
     "Trade Date","Settlement Date","Pending/Settled","Account Nickname","Account Registration","Account #","Type","Description 1 ","Description 2","Symbol/CUSIP #","Quantity","Price ($)","Amount ($)"
          0              1       2               3           4         5                6                   7            8
     "3/29/2019","3/29/2019","Settled","GEORGE'S CMA PLUS","CMAM","812-43946","DividendAndInterest","Foreign Dividend","BP PLC SPON ADR HOLDING 2069.0000 PAY DATE 03/29/2019","BP","--","--","1,272.44"
     "3/29/2019","3/29/2019","Settled","GEORGE'S CMA PLUS","CMAM","812-43946","Other","Depository Bank (ADR) Fee","BP PLC SPON ADR PAYDATE 03/29/19 DEPOSITORY BANK SVCE FEE","BP","--","--","(10.35)"
     "3/29/2019","3/29/2019","Settled","GEORGE'S CMA PLUS","CMAM","812-43946","DividendAndInterest","Dividend","PUB SVC ENTERPRISE GRP HOLDING 800.0000 PAY DATE 03/29/2019","PEG","--","--","376.00"
     "3/29/2019","3/29/2019","Settled","GEORGE'S CMA PLUS","CMAM","812-43946","DividendAndInterest","Bank Interest","PREFERRED DEPOSIT FROM 02/28 THRU 03/28","99861VDM0","--","--","85.00"
     "3/28/2019","3/28/2019","Settled","GEORGE'S CMA PLUS","CMAM","812-43946","Other","Depository Bank (ADR) Fee","SASOL LTD SPONSORED ADR DEPOSITORY BANK SVCE FEE","SSL","--","--","(10.00)"
     "3/28/2019","3/28/2019","Settled","GEORGE'S CMA PLUS","CMAM","812-43946","Other","Foreign Tax Withholding","SASOL LTD SPONSORED ADR PAY DATE 03/28/2019","SSL","--","--","(40.79)"
     "3/28/2019","3/28/2019","Settled","GEORGE'S CMA PLUS","CMAM","812-43946","FundTransfers","Withdrawal","WELLS FARGO BANK EVE MANBECK FARM ACCOUNT","--","--","--","(4,000.00)"
     "3/25/2019","3/25/2019","Settled","GEORGE'S CMA PLUS","CMAM","812-43946","Checking","Check 3723","CENTRAL FL FIRSTPLACE 000003723","--","--","--","(85.00)"
     "3/25/2019","3/25/2019","Settled","GEORGE'S CMA PLUS","CMAM","812-43946","DividendAndInterest","Interest","ADVISORS DISCIPLINED TR 532 TAX EXEMPT MUN PORT INTERMEDIATE SER14 HOLDING 35.0000 PAY DATE 03/25/2019","TEMPI14","--","--","60.55"
     "3/22/2019","3/22/2019","Settled","GEORGE'S CMA PLUS","CMAM","812-43946","Other","Pre-Authorized Withdrawal","BANK OF AMERICA","--","--","--","(2,169.18)"
     "3/20/2019","3/20/2019","Settled","GEORGE'S CMA PLUS","CMAM","812-43946","FundReceipts","Direct Deposit","SSA TREAS 310","--","--","--","1,520.60"
     "3/19/2019","3/19/2019","Settled","GEORGE'S CMA PLUS","CMAM","812-43946","FundReceipts","Direct Deposit","PALAC","--","--","--","8,313.01"
     "3/19/2019","3/19/2019","Settled","GEORGE'S CMA PLUS","CMAM","812-43946","Checking","Check 3721","BARBARA BAUER 000003721","--","--","--","(10,000.00)"
     "3/18/2019","3/18/2019","Settled","GEORGE'S CMA PLUS","CMAM","812-43946","Other","Pre-Authorized Withdrawal","DukeEnergy-FL","--","--","--","(21.56)"
     */

    var known = false
    var ignore = false
    let des = lineItem.desc.uppercased()
    let colinSplit = des.splitAtFirst(char: ":")

    if des.hasPrefix("DIVD REINV") || des.hasPrefix("EXCHANGE:") || des.hasPrefix("REINVESTMENT SHARE")  {
        if lineItem.debit == 0.0 && lineItem.credit == 0.0 {
            ignore = true
        } else {
            print("😡 HandleActivity#\(#line) Ignore with $ ",lineItem.transText)
        }
        known = true
    }

    // WIRE TRF  " TRUFFLE HO"
    if des.hasPrefix("WIRE") || des.contains("WIRE TR") {
        print("HandleActivity#\(#line) Wire Transfer = \(lineItem.desc)")
        let words = des.components(separatedBy: " ")
        var newDes = ""
        var count = 0
        for word in words.reversed() {
            count += 1
            if count >= 3 || count >= words.count - 1 || word.range(of: "[^A-Za-z]", options: .regularExpression) != nil {
                break
            }
            newDes = word + " " + newDes
        }
        newDes = newDes.trim
        if !newDes.isEmpty {
            lineItem.desc = newDes
        }
        known = true
    } else if des.hasSuffix("VISA DEFERRED")                       { //ML DEBITCARD "SXM*SIRIUSXM.COM/ACCT VISA DEFERRED"
        lineItem.cardType = "MLVISA"
        let items = des.components(separatedBy: " VISA D")
        lineItem.desc = items[0]
        known = true                                          //             "BRIGHT HOUSE NETWORKS VISA DEFERRED"

    } else if des.hasPrefix("REINVESTMENT PROGRAM ")        { // "REINVESTMENT PROGRAM LORD ABBETT INTERMED TAX FREE FD A"
        lineItem.desc = String(des.dropFirst(21))
        known = true

    } else if des.hasPrefix("REINVESTMENT ")                 { // "REINVESTMENT LORD ABBETT INTERMED TAX FREE FD A"
        lineItem.desc = String(des.dropFirst(13))
        known = true

    } else if des.hasPrefix("PRE-AUTHORIZED WITHDRAWA")     { // "PRE-AUTHORIZED WITHDRAWA UNITEDHEALTHCARE"
        let comps = des.components(separatedBy: " ")
        let slice = comps[2...]
        lineItem.desc = slice.joined(separator: " ")
        lineItem.cardType = "CHECKML"
        known = true                                          // "PRE-AUTHORIZED WITHDRAWA DUKEENERGY-FL"

    } else if des.hasPrefix("PRE AUTHDEBIT")                { // CHECKML "PRE AUTHDEBIT DUKEENERGY-FL"
        lineItem.desc = String(des.dropFirst(14))
        known = true

    } else if des.hasPrefix("CHECK ")                       { // CHECKML    "CHECK 3601 PAYEE UNRECORDE"
        lineItem.cardType = "CHECKML"
        let items = des.components(separatedBy: " ")
        if items.count >= 2 {
            lineItem.chkNumber = items[1]
            let comps = des.components(separatedBy: " "+items[1]+" ")
            if comps.count >= 2 {
                lineItem.desc = comps[1]
            } else if items[0] == "CHECK" {
                lineItem.chkNumber = items[1]
            }
        }
        //print("😀 Check ",fromTransFileLine)                //            "CHECK 3633 CHARLES HOWARD"
        known = true
    } else if des.hasPrefix("WITHDRAWAL ")                  { // CHECKML    "WITHDRAWAL TR TO ML   81217K22"
        lineItem.desc = String(des.dropFirst(11))
        lineItem.rawCat = "Gift"
        known = true                                          //            "WITHDRAWAL WELLS FARGO BANK"

    } else if colinSplit.lft.contains("DIV")                { // "CDIV:", "DIVIDEND:", "LIQUIDATING DIVIDEND:", "FOREIGN DIVIDEND:"
        known = true
        lineItem.desc = colinSplit.rgt
        lineItem.rawCat = "Income-Dividend"
//    des.hasPrefix("CDIV:")                    { // "CDIV: DAF S AND P 500 TRUST 2 HOLDING 5X6398.0000 PAY DATE 01/09"
//    des.hasPrefix("DIVIDEND:")                { // "DIVIDEND: DISNEY (WALT) CO COM STK HOLDING 600.0000 PAY DATE 01/"
//    des.hasPrefix("LIQUIDATING DIVIDEND:")    { // "LIQUIDATING DIVIDEND: DAF S AND P 500 TRUST 2 HOLDING 5X6398.972"
//    des.hasPrefix("FOREIGN DIVIDEND:")        { // "FOREIGN DIVIDEND: SASOL LTD  SPONSORED ADR HOLDING 500.0000 PAY"
//    des.hasPrefix("RPT FGN DIV:")             { // "RPT FGN DIV: MEDTRONIC PLC SHS HOLDING 600.0000 PAY DATE 01/13/2"

    } else if !colinSplit.rgt.isEmpty && colinSplit.lft.contains("INTEREST")                { // "INTEREST:",
        known = true
        lineItem.desc = colinSplit.rgt
        lineItem.rawCat = "Income-Interest"
//    des.hasPrefix("BOND INTEREST:")           { // "BOND INTEREST: ADVISORS DISCIPLINED TR 532 TAX EXEMPT MUN PORT I"
//    des.hasPrefix("BANK INTEREST:")           { // "BANK INTEREST: ML BANK DEPOSIT PROGRAM"
//    des.hasPrefix("INTEREST:")                { // "INTEREST: ADVISORS DISCIPLINED TR 532 TAX EXEMPT MUN PORT INTERM"


    } else if des.hasPrefix("PURCHASE:")                    {   // "PURCHASE: CD BANK WEST SAN FRANCISCO; CA 01.050% DEC XX 2017 WHE"
        known = true
        lineItem.desc = colinSplit.rgt
    } else if des.hasPrefix("SALE:")                        {   // "SALE: LORD ABBETT SHORT DURATION INCOME FD A EXCHANGE SELL FRAC"
        known = true
        lineItem.desc = colinSplit.rgt
    } else if des.hasPrefix("REDEMPTION:")                  {   // "REDEMPTION: CD BANK WEST SAN FRANCISCO; CA 01.050% DEC XX 2017 P"
        known = true
        lineItem.desc = colinSplit.rgt

    } else if des.hasPrefix("FOREIGN TAX WITHHOLDING:")     {   // "FOREIGN TAX WITHHOLDING: SASOL LTD  SPONSORED ADR NON-RECLAIMABL"
        known = true
        lineItem.desc = colinSplit.rgt
        lineItem.rawCat = "Tax-Foreign"

    } else if des.hasPrefix("DEPOSITORY BANK (ADR) FEE:")   {   // "DEPOSITORY BANK (ADR) FEE: SASOL LTD  SPONSORED ADR DEPOSITORY B"
        known = true

    } else if des.hasPrefix("CASH IN LIEU OF SHARES:")      {   // "CASH IN LIEU OF SHARES: ENBRIDGE INC         COM FORM 1099-B SUB"
        known = true

    } else if des.hasPrefix("PRINCIPAL PAYMENT:")           {   // "PRINCIPAL PAYMENT: ADVISORS DISCIPLINED TR 532 TAX EXEMPT MUN PO"
        known = true

    } else if des.hasPrefix("FUNDS TRANSFER WIRE TRF IN")   {   // FUNDS TRANSFER WIRE TRF IN DXXXXXXX1148 ORG=/XXXX9647 TRUFFLE HO
        known = true

    } else if des.hasPrefix("WIRE TRANSFER IN WIRE TRF IN") {   // DXXXXXXX0510 ORG=/XXXX9647 TRUFFLE HO
        known = true                                        // "WIRE TRANSFER IN WIRE TRF IN DXXXXXXX8663 ORG=/XXXXX8420 COAST TIT"

    } else if des.hasPrefix("WIRE TRANSFER OUT WIRE TRF OUT"){  // "WIRE TRANSFER OUT WIRE TRF OUTPXXXXXXX2527"
        known = true

    } else if des.hasPrefix("DIRECT DEPOSIT ")              {   // "DIRECT DEPOSIT SSA  TREAS 310"
        lineItem.desc = String(des.dropFirst(15))
        lineItem.rawCat = "Income"
        known = true
        if !lineItem.desc.hasPrefix("SSA") {
            print("HandleCards#\(#line) \(lineItem.transText)")
            // Debug Trap - Non-SSA Direct-Deposit
        }

    } else if des.hasPrefix("OVERDRAFT") && des.hasSuffix("LOAN") { // "OVERDRAFT LOAN EXTEND OVERDRAFT LOAN"
        known = true
        lineItem.desc = "OVERDRAFT LOAN"
        lineItem.rawCat = "loans"
//    des.hasPrefix("OVERDRAFT LOAN EXTEND OVERDRAFT LOAN") { // "OVERDRAFT LOAN EXTEND OVERDRAFT LOAN"
//    des.hasPrefix("OVERDRAFT REPAYMENT REPAY OVERDRAFT LOAN") { // "OVERDRAFT LOAN EXTEND OVERDRAFT LOAN"
    }

    if !known {
        print("😡 Unknown: ", des, "   ", lineItem.debit, lineItem.credit)
        //
    }
    if !ignore && lineItem.debit == 0.0 && lineItem.credit == 0.0 {
        print("😡 Zero Amount: ",lineItem.transText)
        //
    }
    return lineItem
}//end func extractTranFromActivity
