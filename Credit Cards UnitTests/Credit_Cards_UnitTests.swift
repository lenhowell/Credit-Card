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


//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
