//
//  Catagories_UnitTests.swift
//  Credit Cards UnitTests
//
//  Created by George Bauer on 8/27/21.
//  Copyright © 2021 Lenard Howell. All rights reserved.
//

import XCTest
@testable import Credit_Cards

class Catagories_UnitTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }


    func test_CatagoriesInit() {
        let fileManager = FileManager.default
        let userURL = fileManager.homeDirectoryForCurrentUser
        let testURL = userURL.appendingPathComponent("Desktop/CreditCard/Test/MyCatagories.txt")
        if fileManager.fileExists(atPath: testURL.path) { try! fileManager.removeItem(at: testURL) }
        
        // Read Starter File
        var catagories = Catagories(myCatsFileURL: testURL)
        print("✅ \(catagories.catNames.count) catNames,  \(catagories.dictCatAliases.count) dictCatAliases,  \(catagories.dictCatAliasArray.count) dictCatAliasArray items")
        XCTAssertEqual(catagories.catNames.count, 127)
        XCTAssertEqual(catagories.dictCatAliases.count, 170)
        XCTAssertEqual(catagories.dictCatAliasArray.count, 127)
        //print("➡️\(catagories.dictCatAliasArray)⬅️")
        print("😺 dictCatAliases[Auto-?]=\(String(describing: catagories.dictCatAliases["Auto-?"]))   dictCatAliasArray[Auto-?]=\(String(describing: catagories.dictCatAliasArray["Auto-?"]))")
        if let removedValue = catagories.dictCatAliasArray.removeValue(forKey: "Auto-?") {
            print("🥵 The removed catagory array for Auto-? is \(removedValue).")
        }
        catagories.dictCatAliasArray.removeValue(forKey: "Auto-?")
        XCTAssertEqual(catagories.dictCatAliasArray.count, 126)
        catagories.writeMyCats(url: testURL)
        catagories.dictCatAliasArray = [:]
        catagories.dictCatAliases = [:]
        catagories.catNames = []
        catagories = Catagories(myCatsFileURL: testURL)
        XCTAssertEqual(catagories.catNames.count, 126)
        XCTAssertEqual(catagories.dictCatAliases.count, 166)
        XCTAssertEqual(catagories.dictCatAliasArray.count, 126)
        //print("➡️\(catagories.dictCatAliasArray)⬅️")
        if let removedValue = catagories.dictCatAliasArray.removeValue(forKey: "Auto-?") {
            print("🥵 The removed catagory name is \(removedValue).")
        } else {
            print("🤡 The catagory was already remove.")
        }
        print("✅ \(catagories.catNames.count) catNames,  \(catagories.dictCatAliases.count) dictCatAliases,  \(catagories.dictCatAliasArray.count) dictCatAliasArray items")

    }
}
