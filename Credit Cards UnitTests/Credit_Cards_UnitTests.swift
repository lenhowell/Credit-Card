//
//  Credit_Cards_UnitTests.swift
//  Credit Cards UnitTests
//
//  Created by George Bauer on 8/17/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import XCTest
@testable import Credit_Cards

class Credit_Cards_UnitTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        isUnitTesting = true
        allowAlerts = false
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        isUnitTesting = false
        allowAlerts = true
    }

    // MARK:- Freefuncs.swift
    func testPasteboard() {
        // This is an example of a functional test case.
        let text = "This is test #13"
        copyStringToClipBoard(textToCopy: text)
        let result = getStringFromClipBoard()
        XCTAssertEqual(text, result)
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testDateExtensions() {
        let date = Date.distantFuture
        let dc = date.getComponents()
        XCTAssertEqual(dc.year, 4000)
        XCTAssertEqual(dc.month, 12)
        XCTAssertEqual(dc.day, 31)
        let str = date.toString("yyyy-MM-dd HH-mm-ss")
        XCTAssertEqual(str, "4000-12-31 19-00-00")
    }

    func testMakeLineItemAndDictColNums() {

        var headerLine = ""
        var headers: [String]
        var dictColNums = [String: Int]()

        headerLine = "Transaction Date,Posted Date,Card No.,Description,Category,Debit,Credit"
        headers = headerLine.components(separatedBy: ",")
        dictColNums = makeDictColNums(headers: headers)
        XCTAssertEqual(dictColNums["TRAN"], 0)
        XCTAssertEqual(dictColNums["DESC"], 3)
        XCTAssertEqual(dictColNums["CATE"], 4)
        XCTAssertEqual(dictColNums["DEBI"], 5)
        XCTAssertEqual(dictColNums["CRED"], 6)

        var tran = ""
        var lineItem = LineItem()

        tran = "2018-08-25,2018-08-27,8772,LA FITNESS,Exterm,31.85,"
        lineItem = makeLineItem(fromTransFileLine: tran, dictColNums: dictColNums, cardType: "TEst", hasCatHeader: true, fileName: "fileName", lineNum: 666)
        XCTAssertEqual(lineItem.cardType, "TEst")
        XCTAssertEqual(lineItem.debit, 31.85)
        XCTAssertEqual(lineItem.rawCat, "Exterm")
        //XCTAssertEqual(lineItem.genCat, "Entertainment")

        tran = "2018-08-25,2018-08-27,8772,LX FITNESS,Cat inserted for LX FITNESS,,31.85"
        lineItem = makeLineItem(fromTransFileLine: tran, dictColNums: dictColNums, cardType: "TEst", hasCatHeader: true, fileName: "fileName", lineNum: 666)
        XCTAssertEqual(lineItem.cardType, "TEst")
        XCTAssertEqual(lineItem.credit, 31.85)
        XCTAssertEqual(lineItem.rawCat, "Cat inserted for LX FITNESS")
        XCTAssertEqual(lineItem.genCat, "")

        // Bad Line - Run AFTER creating "Cat inserted for LX FITNESS" above
        tran = "2018-08-25,2018-08-27,8772,LX FITNESS,This is a TEST,31.85"
        lineItem = makeLineItem(fromTransFileLine: tran, dictColNums: dictColNums, cardType: "TEst", hasCatHeader: true, fileName: "fileName", lineNum: 666)
        XCTAssertEqual(lineItem.cardType, "TEst")
        XCTAssertEqual(lineItem.credit, 0)
        XCTAssertEqual(lineItem.debit, 31.85)
        XCTAssertEqual(lineItem.rawCat, "This is a TEST")
        XCTAssertEqual(lineItem.genCat, "Cat inserted for LX FITNESS")

    }


    func testHandleCards() {
        var lineItemArray = [LineItem]()
        
        // Generates Alert - Move to UITests
        let contentGarbage = "\nGarbage\nGarbage\nGarbage\n"
        let cardArrayGarbage = contentGarbage.components(separatedBy: "\n")
        lineItemArray = handleCards(fileName: "fileName", cardType: "cardType", cardArray: cardArrayGarbage)
        XCTAssertEqual(lineItemArray.isEmpty, true)

        let cardArrayC1R = [
            "Transaction Date,Posted Date,Card No.,Description,Category,Debit,Credit",
            "2018-08-11,2018-08-18,8772,MORRISSEYS FRONT PORCH,Dining,12.14,",
        ]
        lineItemArray = handleCards(fileName: "fileName", cardType: "cardType", cardArray: cardArrayC1R)
        XCTAssertEqual(lineItemArray.count, 1)
        XCTAssertEqual(lineItemArray[0].tranDate, "2018-08-11")
        XCTAssertEqual(lineItemArray[0].postDate, "2018-08-18")
        XCTAssertEqual(lineItemArray[0].cardNum, "8772")
        XCTAssertEqual(lineItemArray[0].desc, "MORRISSEYS FRONT PORCH")
        XCTAssertEqual(lineItemArray[0].debit, 12.14)
        XCTAssertEqual(lineItemArray[0].credit, 0.00)
        XCTAssertEqual(lineItemArray[0].rawCat, "Dining")


        let contentLHDC =
    """
    Trans. Date,Post Date,Description,Amount,Category
    04/04/2018,04/04/2018,"BONEFISH 7027 BOYNTON BEACHFL00422R",32.56,"Restaurants"
    04/30/2018,04/30/2018,"PHONE PAYMENT - THANK YOU",-32.56,"Payments and Credits"
    """
        let cardArrayLHDC = contentLHDC.components(separatedBy: "\n")
        lineItemArray = handleCards(fileName: "fileName", cardType: "cardType", cardArray: cardArrayLHDC)
        XCTAssertEqual(lineItemArray.count, 2)
        XCTAssertEqual(lineItemArray[0].tranDate, "04/04/2018")
        XCTAssertEqual(lineItemArray[0].postDate, "04/04/2018")
        XCTAssertEqual(lineItemArray[0].cardNum, "")
        //XCTAssertEqual(lineItemArray[0].desc, "BONEFISH 7027 BOYNTON BEACHFL00422R")
        XCTAssertEqual(lineItemArray[0].debit, 32.56)
        XCTAssertEqual(lineItemArray[0].credit, 0.00)
        XCTAssertEqual(lineItemArray[0].rawCat, "Restaurants")

        //XCTAssertEqual(lineItemArray[1].desc, "BONEFISH 7027 BOYNTON BEACHFL00422R")
        XCTAssertEqual(lineItemArray[1].debit, 0.00)
        XCTAssertEqual(lineItemArray[1].credit, 32.56)
        XCTAssertEqual(lineItemArray[1].rawCat, "Payments and Credits")


        //TODO: The following Unit-Tests need assertions

        //FIXME:- NEGATIVE CREDIT
        //Uses "Date" in header & no "Description" & Negative "Credit"
        let contentLHCT =
    """
    Status,Date,Description,Debit,Credit
    Cleared,08/08/2019,"PAY BY PHONE ACH PAYMENT",,-99.00
    Cleared,08/07/2019,"BEACH COVE RESORT F&B N MYRTLE BCH SC",27.59,
    """
        let cardArrayLHCT = contentLHCT.components(separatedBy: "\n")
        lineItemArray = handleCards(fileName: "fileName", cardType: "cardType", cardArray: cardArrayLHCT)
        XCTAssertEqual(lineItemArray.count, 2)


        // Test Missing Desc ann comma embedded in quotes, positive "Credit"
        let contentLHC1V =
    """
    Transaction Date,Posted Date,Card No.,Description,Category,Debit,Credit
    8/10/19,8/10/19,8772,CAPITAL ONE AUTOPAY PYMT,Payment/Credit,,42
    8/9/19,8/10/19,8772,CRACKER BARREL #194 N MYR,Dining,26.73,
    9/1/19,9/3/19,8772,"CRACKER,BARREL",Dining,9.01,
    9/2/19,9/3/19,8772,,Dining,9.02,
    """
        let cardArrayLHC1V = contentLHC1V.components(separatedBy: "\n")
        lineItemArray = handleCards(fileName: "fileName", cardType: "cardType", cardArray: cardArrayLHC1V)
        XCTAssertEqual(lineItemArray.count, 4)


        //Uses "Original Description" in header
        let contentGBBA =
    """
    Status,Date,Original Description,Split Type,Category,Currency,Amount,User Description,Memo,Classification,Account Name,Simple Description
    posted,3/27/18,7-ELEVEN x2766           SANFORD      FL,,Gasoline/Fuel,USD,-29.00, , ,Personal,Bank of America - Credit Card - Bank of America Premium Rewards Visa Sig,7-Eleven
    posted,9/14/18,A&M PIZZA                LEBANON      PA,,Restaurants/Dining,USD,-22.00, , ,Personal,Bank of America - Credit Card - Bank of America Premium Rewards Visa Sig,A&M PIZZA                LEBANON      PA
    """
        let cardArrayGBBA = contentGBBA.components(separatedBy: "\n")
        lineItemArray = handleCards(fileName: "fileName", cardType: "cardType", cardArray: cardArrayGBBA)
        XCTAssertEqual(lineItemArray.count, 2)


        let contentGBML =
    """
    "2018 VISA SIGNATURE TRANSACTION SUMMARY for GEORGE'S CMA PLUS CMAM 812-43946"

    "Transaction Date","Description","Location","Amount","Merchant Category"
    "01/04/2018","SXM*SIRIUSXM.COM/ACCT","888-635-5144  NY","67.62","Entertainment/Recreation"
    "01/12/2018","BRIGHT HOUSE NETWORKS","317-972-9700  FL","79.21","Entertainment/Recreation"
    "01/15/2018","VZWRLSS*APOCC VISE","800-922-0204  FL","147.32","Other/Unclassified"
    """
        let cardArrayGBML = contentGBML.components(separatedBy: "\n")
        lineItemArray = handleCards(fileName: "fileName", cardType: "cardType", cardArray: cardArrayGBML)
        XCTAssertEqual(lineItemArray.count, 3)

    }//end func testHandleCards


    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
