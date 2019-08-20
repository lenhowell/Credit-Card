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
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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
        let str = date.ToString("yyyy-MM-dd hh-mm-ss")
        XCTAssertEqual(str, "4000-12-31 07-00-00")
    }



    let cardArray = [
        "Transaction Date,Posted Date,Card No.,Description,Category,Debit,Credit",
        "2018-08-25,2018-08-27,8772,LA FITNESS,Entertainment,31.85,",
        "2018-08-19,2018-08-20,8772,BB *SHRINERS HOSPITALS,Other Services,19.00,",
        "2018-08-11,2018-08-18,8772,MORRISSEYS FRONT PORCH,Dining,12.14,",
    ]
     


    func testHandleCards() {
        let headerLine = "Transaction Date,Posted Date,Card No.,Description,Category,Debit,Credit"
        let headers = headerLine.components(separatedBy: ",")
        let dictColNums = makeDictColNums(headers: headers)
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
        XCTAssertEqual(lineItem.genCat, "Entertainment")

        tran = "2018-08-25,2018-08-27,8772,LX FITNESS,This is a TEST,,31.85"
        lineItem = makeLineItem(fromTransFileLine: tran, dictColNums: dictColNums, cardType: "TEst", hasCatHeader: true, fileName: "fileName", lineNum: 666)
        XCTAssertEqual(lineItem.cardType, "TEst")
        XCTAssertEqual(lineItem.credit, 31.85)
        XCTAssertEqual(lineItem.rawCat, "This is a TEST")
        XCTAssertEqual(lineItem.genCat, "")

        let lineItemArray = handleCards(fileName: "fileName", cardType: "cardType", cardArray: cardArray)
        XCTAssertEqual(lineItemArray.count, 3)
    }


    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
