//
//  FileIO_UnitTests.swift
//  Credit Cards UnitTests
//
//  Created by George Bauer on 10/22/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import XCTest
@testable import Credit_Cards

class FileIO__UnitTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFolderExists() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        var result = false
        var path = "Desktop"
        result = FileIO.folderExists(atPath: path, isPartialPath: true)
        XCTAssertEqual(result, true)
        path = "/Desktop"
        result = FileIO.folderExists(atPath: path, isPartialPath: true)
        XCTAssertEqual(result, true)
        path = "/Desktop/"
        result = FileIO.folderExists(atPath: path, isPartialPath: true)
        XCTAssertEqual(result, true)
        path = "/Users/georgebauer/Desktop"
        result = FileIO.folderExists(atPath: path, isPartialPath: false)
        XCTAssertEqual(result, true)
    }

    func test_makeBackupFilePath() {
        var result = ""
        var url = URL(fileURLWithPath: "/aaa/bbb/ccc.ext")
        result = FileIO.makeBackupFilePath(url: url, multiple: false, addonName: "Bak")
        XCTAssertEqual(result, "/aaa/bbb/cccBak.ext")
        url = URL(fileURLWithPath: "/aaa/ccc.ext")
        result = FileIO.makeBackupFilePath(url: url, multiple: true, addonName: "Bak")
        XCTAssertEqual(result, "/aaa/cccBak.ext")
        url = URL(fileURLWithPath: "/aaa/ccc")
        result = FileIO.makeBackupFilePath(url: url, multiple: true, addonName: "Bak")
        XCTAssertEqual(result, "/aaa/cccBak")    }

    func test_qualifyTransFileName() {
        var result = false
        var url = URL(fileURLWithPath: "/aaa/ccc-2012.ext")
        result = FileIO.qualifyTransFileName(url: url)
        XCTAssertEqual(result,false)                // wrong extension
        url = URL(fileURLWithPath: "/aaa/ccc.csv")
        result = FileIO.qualifyTransFileName(url: url)
        XCTAssertEqual(result, false)               // no hyphen
        url = URL(fileURLWithPath: "/aaa/c-2012.csv")
        result = FileIO.qualifyTransFileName(url: url)
        XCTAssertEqual(result,false)                // cardType too short
        url = URL(fileURLWithPath: "/aaa/c2345678901-2012.csv")
        result = FileIO.qualifyTransFileName(url: url)
        XCTAssertEqual(result,false)                // cardType too long
        url = URL(fileURLWithPath: "/aaa/ccc-2019-13.csv")
        result = FileIO.qualifyTransFileName(url: url)
        XCTAssertEqual(result,false)                 // Card-Year-Mon

        url = URL(fileURLWithPath: "/aaa/ccc-2012.csv")
        result = FileIO.qualifyTransFileName(url: url)
        XCTAssertEqual(result,true)                 // Card-Year
        url = URL(fileURLWithPath: "/aaa/ccc-2019-12.csv")
        result = FileIO.qualifyTransFileName(url: url)
        XCTAssertEqual(result,true)                 // Card-Year-Mon
        url = URL(fileURLWithPath: "/aaa/ccc-2012-01-24.csv")
        result = FileIO.qualifyTransFileName(url: url)
        XCTAssertEqual(result,true)                 // Card-Year-Mon-NumberOfMons
        url = URL(fileURLWithPath: "/aaa/ccc-2012-01-anything.csv")
        result = FileIO.qualifyTransFileName(url: url)
        XCTAssertEqual(result,true)                 // Card-Year-Mon-anything
    }//end func

    func test_makeFileURL() {
        var url = FileManager.default.homeDirectoryForCurrentUser
        var msg = ""
        (url, msg) = FileIO.makeFileURL(pathFileDir: "xxx", fileName: "xxx")
        XCTAssertEqual(msg, "Folder \"/Users/georgebauer/xxx\" does NOT exist!")
    }

    func test_VendorShortNames() {
        let content = """
// ShortName (prefix),  Full Description Key

If desc has this prefix,DescKey
Missing comma
"2nd entry" ,           Number 2
3rd entry ,            "Number 3"
prefix,prefix
"""
        let vendorShortNames = VendorShortNames(content: content)
        XCTAssertEqual(vendorShortNames.dict.count, 4)
        XCTAssertEqual(vendorShortNames.dict["If desc has this prefix"], "DescKey")
        XCTAssertEqual(vendorShortNames.dict["2nd entry"], "Number 2")
        XCTAssertEqual(vendorShortNames.dict["3rd entry"], "Number 3")
        XCTAssertEqual(vendorShortNames.dict["prefix"], "prefix")
    }//end func

    func test_parseCommaDelimitedLine() {
        var line = ""
        var result: [String] = []
        line = "abc, \" def \", \"de,f\" "
        result = FileIO.parseCommaDelimitedLine(line)
        XCTAssertEqual(result[0], "abc")
        XCTAssertEqual(result[1], "def")
        XCTAssertEqual(result[2], "de;f")
    }

}//end class
