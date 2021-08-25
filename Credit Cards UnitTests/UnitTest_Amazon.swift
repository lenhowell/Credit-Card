//
//  UnitTest_Amazon.swift
//  Credit Cards UnitTests
//
//  Created by George Bauer on 12/9/19.
//  Copyright © 2019-2021 George Bauer. All rights reserved.
//

import XCTest
@testable import Credit_Cards

class UnitTest_Amazon: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        allowAlerts = false
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        allowAlerts = true
    }

    func test_Data1() {
        let dictAmazon1 = readAmazon(testData: testData1)
        let itemArray1 = dictAmazon1["2001-05-10"]!
        XCTAssertEqual(itemArray1.count, 2)
        XCTAssertEqual(itemArray1[0].orderDate, "2001-05-10")
        XCTAssertEqual(itemArray1[0].order$, 39.79, accuracy: 0.001)
        XCTAssertEqual(itemArray1[0].orderShipTo, "George Bauer")
        for item in itemArray1 {
            XCTAssertEqual(item.orderDate, "2001-05-10")
            XCTAssertEqual(item.order$, 39.79, accuracy: 0.001)
            XCTAssertEqual(item.orderShipTo, "George Bauer")
            XCTAssertEqual(item.orderNumber, "104-1330955-3583120")
            XCTAssertEqual(item.personTitle, "Author", "\(item.item$)")
            XCTAssertTrue(item.itemSoldBy.hasPrefix("Amazon"))
            if item.itemName.hasPrefix("Why God") {
                XCTAssertEqual(item.item$, 19.96, accuracy: 0.001)

            } else if item.itemName.hasPrefix("How the") {
                XCTAssertEqual(item.item$, 14.36, accuracy: 0.001)

            } else {
                XCTAssertTrue(false)
            }
        }

/*
         2 of Dock Connector to USB 2.0 Cable for iPod and iPhone (White)
         Sold by: SF Planet
         $0.42
         */

        let itemArray2 = dictAmazon1["2001-08-09"]!
        XCTAssertEqual(itemArray2.count, 2)
        for (idx, item) in itemArray2.enumerated() {
            XCTAssertEqual(item.orderDate, "2001-08-09")
            if idx == 0 {
                XCTAssertEqual(item.order$, 6.80, accuracy: 0.001)
                XCTAssertEqual(item.orderShipTo, "Barbara Bauer")
                XCTAssertEqual(item.orderNumber, "102-7801913-5250636")
                XCTAssertEqual(item.itemQuant, 2)
                XCTAssertTrue(item.itemName.hasPrefix("Dock"))
                XCTAssertEqual(item.personTitle, "", "\(item.item$)")
                XCTAssertEqual(item.itemSoldBy, "SF Planet")
            } else {
                XCTAssertEqual(item.order$, 13.95, accuracy: 0.001)
                XCTAssertEqual(item.orderShipTo, "Barbara Manbeck")
                XCTAssertEqual(item.orderNumber, "102-7801913-5250637")
                XCTAssertEqual(item.itemQuant, 1)
                XCTAssertTrue(item.itemName.hasPrefix("Alaska:"))
                XCTAssertEqual(item.personTitle, "Actor", "\(item.item$)")
                XCTAssertEqual(item.personName, "Charlton Heston", "\(item.item$)")
                XCTAssertTrue(item.itemSoldBy.hasPrefix("Amazon"))

            }
        }

    }

    let testData1 = #"""
3 orders placed in  2001

ORDER PLACED
May 10, 2001
TOTAL
$39.79
SHIP TO
George Bauer

ORDER # 104-1330955-3583120

Why God Won't Go Away : Brain Science and the Biology of Belief
Andrew Newberg M.D., et al
Sold by: Amazon.com Services, Inc
$19.96

How the Mind Works
Steven Pinker
Sold by: Amazon.com Services, Inc
$14.36

ORDER PLACED
January 18, 2001
TOTAL
$46.48
SHIP TO
George Bauer

ORDER # 107-1564814-2691752

Bowes & Church's Food Values of Portions Commonly Used
Jean A. T., Ph.D. Pennington
Sold by: Amazon.com Services, Inc
$42.00

ORDER PLACED
August 9, 2001
TOTAL
$6.80
SHIP TO
Barbara Bauer
ORDER # 102-7801913-5250636

2 of Dock Connector to USB 2.0 Cable for iPod and iPhone (White)
Sold by: SF Planet
$0.42

ORDER PLACED
August 9, 2001
TOTAL
$13.95
SHIP TO
Barbara Manbeck
ORDER # 102-7801913-5250637

Alaska: Spirit of the Wild (IMAX) [Blu-ray]
Charlton Heston (Actor), George Casey (Director)
Sold by: Amazon.com Services, Inc
$13.95

"""#
}
