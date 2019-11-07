//
//  TableFilter_UnitTests.swift
//  Credit Cards UnitTests
//
//  Created by George Bauer on 11/5/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import XCTest
@testable import Credit_Cards

class TableFilter_UnitTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_formatDate() {
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        var result = ""
        result = TableFilter.formatDateField(txtField: "")
        XCTAssertEqual(result, "")
        result = TableFilter.formatDateField(txtField: "9?17")
        XCTAssertEqual(result, "9?17")
        result = TableFilter.formatDateField(txtField: "9/17")
        XCTAssertEqual(result, "2017-09")
        result = TableFilter.formatDateField(txtField: "9/3/17")
        XCTAssertEqual(result, "2017-09-03")
        result = TableFilter.formatDateField(txtField: "2017")
        XCTAssertEqual(result, "2017")
        result = TableFilter.formatDateField(txtField: "3000")
        XCTAssertEqual(result, "?3000?")
        result = TableFilter.formatDateField(txtField: "1899")
        XCTAssertEqual(result, "?1899?")
        result = TableFilter.formatDateField(txtField: "20x7")
        XCTAssertEqual(result, "?20x7?")

        result = TableFilter.formatDateField(txtField: "2017-13")
        XCTAssertEqual(result, "?2017-13?")
        result = TableFilter.formatDateField(txtField: "2017-0")
        XCTAssertEqual(result, "?2017-0?")
        result = TableFilter.formatDateField(txtField: "2017-1")
        XCTAssertEqual(result, "2017-01")
        result = TableFilter.formatDateField(txtField: "3000-1")
        XCTAssertEqual(result, "?3000-1?")
        result = TableFilter.formatDateField(txtField: "20x7-1")
        XCTAssertEqual(result, "?20x7-1?")
        result = TableFilter.formatDateField(txtField: "2017-1-2")
        XCTAssertEqual(result, "2017-01-02")
        result = TableFilter.formatDateField(txtField: "2017-1-x")
        XCTAssertEqual(result, "?2017-1-x?")
        result = TableFilter.formatDateField(txtField: "2017-1-2x")
        XCTAssertEqual(result, "?2017-1-2x?")
        result = TableFilter.formatDateField(txtField: "2017-1-32")
        XCTAssertEqual(result, "?2017-1-32?")
    }//end func

    func test_decodeFormattedDate() {
        var result = ""
        result = TableFilter.decodeFormattedDate(txtDate: "", isMin: true)
        XCTAssertEqual(result, "1900-01-01")
        result = TableFilter.decodeFormattedDate(txtDate: "1935", isMin: true)
        XCTAssertEqual(result, "1935-01-01")
        result = TableFilter.decodeFormattedDate(txtDate: "3000", isMin: false)
        XCTAssertEqual(result, "3000-12-31")
        result = TableFilter.decodeFormattedDate(txtDate: "1935-05", isMin: true)
        XCTAssertEqual(result, "1935-05-01")
        result = TableFilter.decodeFormattedDate(txtDate: "1935-05", isMin: false)
        XCTAssertEqual(result, "1935-05-31")
        result = TableFilter.decodeFormattedDate(txtDate: "1935-05-06", isMin: false)
        XCTAssertEqual(result, "1935-05-06")
    }

    func test_getDateRange() {
        var result = TableFilter.getDateRange(txtfld1: "1999", txtfld2: "") // (date1: String, txt1: String, date2: String, txt2: String)
        XCTAssertEqual(result.txt1, "1999")
        XCTAssertEqual(result.date1, "1999-01-01")
        XCTAssertEqual(result.txt2, "")
        XCTAssertEqual(result.date2, "1999-12-31")

        result = TableFilter.getDateRange(txtfld1: "1999-07", txtfld2: "") // (date1: String, txt1: String, date2: String, txt2: String)
        XCTAssertEqual(result.txt1, "1999-07")
        XCTAssertEqual(result.date1, "1999-07-01")
        XCTAssertEqual(result.txt2, "")
        XCTAssertEqual(result.date2, "1999-07-31")
    }
}
