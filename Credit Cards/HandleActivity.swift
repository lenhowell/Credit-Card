//
//  HandleActivity.swift
//  Credit Cards
//
//  Created by George Bauer on 11/2/19.
//  Copyright © 2019 George Bauer. All rights reserved.
//

import Foundation

// Specialized routine OMLY for Merrill Lynch Activity download
//MARK: - extractTranFromActivity
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

     MLCMA-2013 Activity
     "expand/collapse column header" ," Trade Date " ," Settlement Date " ," Type" ," Description" ," Symbol/  CUSIP  " ," Quantity" ," Price ($) " ," Amount ($)" ," "
     ""     ,"" ,"12/18/2013" ,"" ,"DDS SSA  TREAS 310"                                    ,""      ,"" ,"" ,  "1,494.40" ,""
     "show" ,"" ,"12/16/2013" ,"" ,"Dividend DUKE ENERGY CORP NEW HOLDING 200.00..."       ,"DUK"   ,"" ,"" ,    "156.00" ,""
     ""     ,"" ,"12/16/2013" ,"" ,"Pre Authdebit ProgressEngyFl"                          ,""      ,"" ,"" ,   "(18.75)" ,""
     ""     ,"" ,"12/13/2013" ,"" ,"Check3474 ORLANDO APOPKA A 3474"                       ,""      ,"" ,"" ,  "(285.00)" ,""
     ""     ,"" ,"12/13/2013" ,"" ,"Funds Transfer TR TO ML   81217K22"                    ,""      ,"" ,"" ,"(4,400.00)" ,""
     "show" ,"" ,"12/12/2013" ,"" ,"Lg Tm Cap Gain PIMCO INCOME FUND CL C PAY DATE 12/..." ,"PONCX" ,"" ,"" ,   "100.50"  ,""
     ""     ,"" ,"12/12/2013" ,"" ,"Reinvestment PIMCO INCOME FUND CL C"                   ,"PONCX" ,"" ,"" ,  "(100.50)" ,""
     "show" ,"" ,"12/12/2013" ,"" ,"Sh Tm Cap Gain PIMCO INCOME FUND CL C PAY DATE 12/..." ,"PONCX" ,"" ,"" ,    "15.36"  ,""
     "show" ,"" ,"12/27/2013" ,"" ,"Divd Reinv DAF S AND P 500 TRUST 2 PRINCIPAL Q..."     ,"ESP002","735" ,"" ,"0.00" ,""
     "show" ,"11/26/2013" ,"12/26/2013" ,"" ,"Deferred CINEMARK THEATRES 284 ORLANDO FL En..." ,"" ,"" ,"" ,"(10.25)" ,""
     "show" ,"11/30/2013" ,"12/26/2013" ,"" ,"Deferred TEXAS ROADHOUSE 2285 OCOEE FL Resta..." ,"" ,"" ,"" ,"(15.00)" ,""

     MLCMA-2019 ExportData
     Status,Date,Original Description,Split Type,Category,Currency,Amount,User Description,Memo,Classification,Account Name,Simple Description
     posted,12/31/2019, Reinvestment Program PIMCO INCOME FUND CL C,,Securities Trades,USD,-389.46, , ,Personal,Merrill Lynch MyMerrill - Investments - CMAM-GEORGE'S CMA PLUS,
     posted,12/31/2019, Reinvestment Program LORD ABBETT INTERMED TAX FREE FD A,,Securities Trades,USD,-272.34, , ,Personal,Merrill Lynch MyMerrill - Investments - CMAM-GEORGE'S CMA PLUS,
     posted,12/31/2019, Reinvestment Program LORD ABBETT SHORT DURATION T/F FD CL A,,Securities Trades,USD,-790.22, , ,Personal,Merrill Lynch MyMerrill - Investments - CMAM-GEORGE'S CMA PLUS,
     posted,12/31/2019, CHECK 3757 FARMERS PRIOR GAS CLUB,,Transfers,USD,-158.00, , ,Personal,Merrill Lynch MyMerrill - Investments - CMAM-GEORGE'S CMA PLUS,
     posted,12/31/2019, BANK INTEREST: ML BANK DEPOSIT PROGRAM,,Investment Income,USD,"1,054.00", , ,Personal,Merrill Lynch MyMerrill - Investments - CMAM-GEORGE'S CMA PLUS,
     posted,12/31/2019, BANK INTEREST: ML BANK DEPOSIT PROGRAM FROM 11/29 THRU 12/31,,Investment Income,USD,1.49, , ,Personal,Merrill Lynch MyMerrill - Investments - CMAM-GEORGE'S CMA PLUS,
     posted,12/31/2019, DIVIDEND: PIMCO INCOME FUND CL C PAY DATE 12/31/2019,,Investment Income,USD,389.46, , ,Personal,Merrill Lynch MyMerrill - Investments - CMAM-GEORGE'S CMA PLUS,
     posted,12/31/2019, DIVIDEND: LORD ABBETT INTERMED TAX FREE FD A PAY DATE 12/31/2019,,Investment Income,USD,272.34, , ,Personal,Merrill Lynch MyMerrill - Investments - CMAM-GEORGE'S CMA PLUS,
     posted,12/31/2019, DIVIDEND: LORD ABBETT SHORT DURATION T/F FD CL A PAY DATE 12/31/,,Investment Income,USD,790.22, , ,Personal,Merrill Lynch MyMerrill - Investments - CMAM-GEORGE'S CMA PLUS,
     posted,12/31/2019, DIVIDEND: PUB SVC ENTERPRISE GRP HOLDING 800.0000 PAY DATE 12/31,,Investment Income,USD,376.00, , ,Personal,Merrill Lynch MyMerrill - Investments - CMAM-GEORGE'S CMA PLUS,
     posted,12/30/2019, Amazon.com*NQ5ZZ2HU3     Amzn.com/billWA,,General Merchandise,USD,-19.93, , ,Personal,Bank of America - Credit Card - Bank of America Premium Rewards Visa Sig, Amazon
     posted,12/30/2019, SPECTRUM                 xxx-xxx-7328 FL,,Other Expenses,USD,-237.33, , ,Personal,Bank of America - Credit Card - Bank of America Premium Rewards Visa Sig, Spectrum
     posted,12/30/2019, Pre-Authorized Withdrawa DukeEnergy-FL GEORGE W BAUER,,Utilities,USD,-195.60, , ,Personal,Merrill Lynch MyMerrill - Investments - CMAM-GEORGE'S CMA PLUS, Duke Energy Corporation
     posted,12/28/2019, PILOT_x0280              BLOOMSBURY   NJ,,Gasoline/Fuel,USD,-27.01, , ,Personal,Bank of America - Credit Card - Bank of America Premium Rewards Visa Sig, PILOT_x0280 BLOOMSBURY NJ
     posted,12/28/2019, BLUE MOUNTAIN FMLY RSTR  SHARTLESVILLEPA,,Travel,USD,-35.00, , ,Personal,Bank of America - Credit Card - Bank of America Premium Rewards Visa Sig, Blue Mountain
     posted,12/28/2019, APPLE.COM/US             xxx-xxx-2775 CA,,Electronics,USD,-99.00, , ,Personal,Bank of America - Credit Card - Bank of America Premium Rewards Visa Sig, Apple
     posted,12/27/2019, Interest Earned,,Interest,USD,2.74, , ,Personal,Bank of America - Bank - Money Market Savings, Interest Income
     posted,12/27/2019, Amazon.com*3Y5SL8BO3     Amzn.com/billWA,,General Merchandise,USD,-19.13, , ,Personal,Bank of America - Credit Card - Bank of America Premium Rewards Visa Sig, Amazon

     */

    var known = false
    var ignore = false

    if lineItem.desc.uppercased().contains("DUKE") {
        print("👺HandleActivity#\(#line) \(lineItem.desc) \(lineItem.debit)")
        // Debug Trap
    }

    if lineItem.rawCat == Const.unknown {
        let oldDesc = lineItem.desc
        if oldDesc.hasPrefix("Check") {
            let words = lineItem.desc.components(separatedBy: " ")
            if let lastWord = words.last {
                let descWords = words.dropFirst().dropLast()   // "Check3519 STEVE BRYAN 3519" -> "STEVE BRYAN"
                lineItem.desc = descWords.joined(separator: " ")
                var chkNum = lastWord.suffix(5)
                if chkNum.hasPrefix("0") { chkNum = chkNum.suffix(4) }
                lineItem.chkNumber = String(chkNum)
            }

        } else if oldDesc.hasPrefix("Deferred") {
            lineItem.desc = String(oldDesc.dropFirst(8).trim)
        } else {
            var cat = ""
            var skip = 0

            let words = lineItem.desc.components(separatedBy: " ")

            if words[0].range(of: #"[a-z]"#, options: .regularExpression) != nil {
                cat = words[0]
                if words.count > 1 {
                    skip = 1
                    if words[1].range(of: #"[a-z]"#, options: .regularExpression) != nil {
                        cat = cat + " " + words[1]
                        skip = 2
                    }
                    let descWords = words.dropFirst(skip)
                    if !cat.isEmpty {
                        lineItem.rawCat = cat
                    }
                    lineItem.desc = descWords.joined(separator: " ")
                }
            }
            //print("😈😈 HandleActivity#\(#line) desc: \"\(oldDesc)\" -> \"\(lineItem.desc)\"")
            //print("😈 HandleActivity#\(#line) rawCat: \"Unknown\" -> \"\(lineItem.rawCat)\"")
        }
    }// Unknown rawCat

    let des = lineItem.desc.uppercased()
    let colinSplit = des.splitAtFirst(char: ":")
    if lineItem.tranDate == "?" {
        lineItem.tranDate = lineItem.postDate
    }

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
        var idxOrg = -999
        var orgName1 = ""
        var orgName2 = ""
        for (idx, word) in words.enumerated() {
            if word.hasPrefix("ORG=") {
                idxOrg = idx + 1
            }
            if idx == idxOrg {
                orgName1 = word
            }
            if idx == idxOrg+1 {
                orgName2 = word
            }
        }
        let orgName = (orgName1 + " " + orgName2).trim
        if !orgName.isEmpty {
            lineItem.desc = orgName
        }
        known = true
    } else if des.hasSuffix("VISA DEFERRED")            { //ML DEBITCARD "SXM*SIRIUSXM.COM/ACCT VISA DEFERRED"
        lineItem.cardType = "MLVISA"
        let items = des.components(separatedBy: " VISA D")
        lineItem.desc = items[0]
        known = true                                    // "BRIGHT HOUSE NETWORKS VISA DEFERRED"

    } else if des.hasPrefix("REINVESTMENT PROGRAM ")    { // "REINVESTMENT PROGRAM LORD ABBETT INTERMED TAX FREE FD A"
        lineItem.desc = String(des.dropFirst(21))
        known = true

    } else if des.hasPrefix("REINVESTMENT ")            { // "REINVESTMENT LORD ABBETT INTERMED TAX FREE FD A"
        lineItem.desc = String(des.dropFirst(13))
        known = true

    } else if des.hasPrefix("PRE-AUTHORIZED WITHDRAWA") { // "PRE-AUTHORIZED WITHDRAWA UNITEDHEALTHCARE"
        let comps = des.components(separatedBy: " ")
        let slice = comps[2...]
        lineItem.desc = slice.joined(separator: " ")
        lineItem.cardType = "CHECKML"
        known = true                                    // "PRE-AUTHORIZED WITHDRAWA DUKEENERGY-FL"

    } else if des.hasPrefix("PRE AUTHDEBIT")            { // CHECKML "PRE AUTHDEBIT DUKEENERGY-FL"
        lineItem.desc = String(des.dropFirst(14))
        known = true

    } else if des.hasPrefix("CHECK ")                   { // CHECKML    "CHECK 3601 PAYEE UNRECORDE"
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
        //print("😀 Check ",fromTransFileLine)          //  "CHECK 3633 CHARLES HOWARD"
        known = true
    } else if des.hasPrefix("WITHDRAWAL ")              { // CHECKML    "WITHDRAWAL TR TO ML   81217K22"
        lineItem.desc = String(des.dropFirst(11))
        lineItem.rawCat = "Gift"
        known = true                                    //            "WITHDRAWAL WELLS FARGO BANK"

    } else if !colinSplit.rgt.isEmpty && colinSplit.lft.contains("DIV") { // "CDIV:", "DIVIDEND:", "LIQUIDATING DIVIDEND:", "FOREIGN DIVIDEND:"
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


    } else if des.hasPrefix("PURCHASE:")                { // "PURCHASE: CD BANK WEST SAN FRANCISCO; CA 01.050% DEC XX 2017 WHE"
        known = true
        lineItem.desc = colinSplit.rgt
    } else if des.hasPrefix("SALE:")                    { // "SALE: LORD ABBETT SHORT DURATION INCOME FD A EXCHANGE SELL FRAC"
        known = true
        lineItem.desc = colinSplit.rgt
    } else if des.hasPrefix("REDEMPTION:")              { // "REDEMPTION: CD BANK WEST SAN FRANCISCO; CA 01.050% DEC XX 2017 P"
        known = true
        lineItem.desc = colinSplit.rgt

    } else if des.hasPrefix("FOREIGN TAX WITHHOLDING:") { // "FOREIGN TAX WITHHOLDING: SASOL LTD  SPONSORED ADR NON-RECLAIMABL"
        known = true
        lineItem.desc = colinSplit.rgt
        lineItem.rawCat = "Tax-Foreign"

    } else if des.hasPrefix("DEPOSITORY BANK (ADR) FEE:") { // "DEPOSITORY BANK (ADR) FEE: SASOL LTD  SPONSORED ADR DEPOSITORY B"
        known = true

    } else if des.hasPrefix("CASH IN LIEU OF SHARES:")      { // "CASH IN LIEU OF SHARES: ENBRIDGE INC         COM FORM 1099-B SUB"
        known = true

    } else if des.hasPrefix("PRINCIPAL PAYMENT:")           { // "PRINCIPAL PAYMENT: ADVISORS DISCIPLINED TR 532 TAX EXEMPT MUN PO"
        known = true

    } else if des.hasPrefix("FUNDS TRANSFER WIRE TRF IN")   { // FUNDS TRANSFER WIRE TRF IN DXXXXXXX1148 ORG=/XXXX9647 TRUFFLE HO
        known = true

    } else if des.hasPrefix("WIRE TRANSFER IN WIRE TRF IN") { // DXXXXXXX0510 ORG=/XXXX9647 TRUFFLE HO
        known = true                                        // "WIRE TRANSFER IN WIRE TRF IN DXXXXXXX8663 ORG=/XXXXX8420 COAST TIT"

    } else if des.hasPrefix("WIRE TRANSFER OUT WIRE TRF OUT"){ // "WIRE TRANSFER OUT WIRE TRF OUTPXXXXXXX2527"
        known = true

    } else if des.hasPrefix("DIRECT DEPOSIT ")              { // "DIRECT DEPOSIT SSA  TREAS 310"
        lineItem.desc = String(des.dropFirst(15))
        lineItem.rawCat = "Income"
        known = true
        if !lineItem.desc.hasPrefix("SSA") {
            print("❓HandleActivity#\(#line) Non-SSA Direct Deposit on \(lineItem.tranDate) from \(lineItem.desc) for $\(lineItem.credit)")
            // Debug Trap - Non-SSA Direct-Deposit
        }

    } else if des.contains("OVERDRAFT") && des.hasSuffix("LOAN") { // "OVERDRAFT LOAN EXTEND OVERDRAFT LOAN"
        known = true
        lineItem.desc = "OVERDRAFT LOAN"
        lineItem.rawCat = "loans"
//    des.hasPrefix("OVERDRAFT LOAN EXTEND OVERDRAFT LOAN") { // "OVERDRAFT LOAN EXTEND OVERDRAFT LOAN"
//    des.hasPrefix("OVERDRAFT REPAYMENT REPAY OVERDRAFT LOAN") { // "OVERDRAFT LOAN EXTEND OVERDRAFT LOAN"
    }

    if !known {
        //print("😡 HandleActivity#\(#line) Unknown desc: \"\(des)\"  ", lineItem.debit, lineItem.credit)
        //
    }
    if !ignore && lineItem.debit == 0.0 && lineItem.credit == 0.0 {
        print("😡 HandleActivity#\(#line) Zero Amount: ",lineItem.transText)
        //
    }
    return lineItem
}//end func extractTranFromActivity
