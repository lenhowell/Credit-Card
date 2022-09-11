//
//  Catagories.swift
//  Credit Cards
//
//  Created by George Bauer on 8/26/21.
//  Copyright © 2021 George Bauer. All rights reserved.
//

import Foundation

//MARK: - My Catagories
public var gCatagories = Catagories()   // Used: VC, UserInputVC, HandleCards, LineItems

public struct Catagories {
    var catNames          = [String]()
    var dictCatAliases    = [String: String]()
    var dictCatAliasArray = [String: [String]]()
    var codeFile = "Catagories"
    
    init() { }
    
    init(myCatsFileURL: URL) {  //was loadMyCats
        var inputURL = myCatsFileURL
        let attr = FileAttributes.getFileInfo(url: inputURL)

        if attr.size < 500 {    // No MyCategories.txt
            guard let path = Bundle.main.path(forResource: "MyCategories", ofType: "txt") else {
                let msg = "Missing starter file - MyCategories.txt"
                handleError(codeFile: codeFile, codeLineNum: #line, type: .codeError, action: .alertAndDisplay, errorMsg: msg)
                return
            }
            inputURL = URL(fileURLWithPath: path)
        }

        // Read contents
        var contentof = ""
        do {
            contentof = (try String(contentsOf: inputURL))
        } catch {
            print("⛔️",myCatsFileURL.path)
            print("Catagories#\(#line) \(error.localizedDescription)")
            //
        }
        let lines = contentof.components(separatedBy: "\n") // Create var lines containing Entry for each line.
        var lineNum = 0
        Glob.myCategoryHeader = ""
        var inHeader = true
        for line in lines {
            lineNum += 1
            // Capture header & ignore blanks
            let linetrim = line.trim
            if linetrim.isEmpty || linetrim.hasPrefix("//") || linetrim.hasPrefix("My Name") {
                if inHeader {
                    Glob.myCategoryHeader += line + "\n"
                    if linetrim.isEmpty || linetrim.hasPrefix("My Name") {
                        inHeader = false
                    }
                }
                continue
            }
            
            // Create an Array of line components the seperator being a ","
            let myCatsArray = line.components(separatedBy: ",")
            let myCat       = myCatsArray[0].trim.removeEnclosingQuotes()
            var aliases     = [String]()
            catNames.append(myCat)
            
            for myCatAliasRaw in myCatsArray {
                let myCatAlias = myCatAliasRaw.trim.removeEnclosingQuotes()
                if myCatAlias.count >= 3 {
                    if myCatAlias != myCat {
                        aliases.append(myCatAlias)
                    }
                    dictCatAliases[myCatAlias.uppercased()] = myCat
                }
            }
            dictCatAliasArray[myCat] = aliases
        }//next line
        catNames.sort()
        
        if inputURL != myCatsFileURL {
            writeMyCats(url: myCatsFileURL)    // Save Starter file
            let msg = "A starter \"MyCategories.txt\" was placed in your support-files folder"
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataWarning, action: .display, errorMsg: msg)
        }
    }//end func init(myCatsFileURL:)
    
    
    //---- writeMyCats - uses Global gDictMyCatAliasArray
    func writeMyCats(url: URL) {
        FileIO.saveBackupFile(url: url)
        
        var text = Glob.myCategoryHeader
        text += "My Name,               alias1,        alias2,    ...\n"
        var prevCat = ""
        for (cat, array) in dictCatAliasArray.sorted(by: {$0.key < $1.key} ) {
            if  cat.splitAtFirst(char: "-").lft != prevCat.splitAtFirst(char: "-").lft {
                text += "\n"
            }
            prevCat = cat
            text += cat
            var spaceCount = max(24 - cat.count, 0)
            for alias in array {
                text += "," + String(repeating: " ", count: spaceCount) + alias
                spaceCount = 4
            }
            text += "\n"
        }
        
        //— writing —
        do {
            try text.write(to: url, atomically: false, encoding: .utf8)
            print("\n😀 Catagories#\(#line) Successfully wrote new MyCategories to: \(url.path)")
        } catch {
            let msg = "Could not write new MyCategories file."
            handleError(codeFile: "Catagories", codeLineNum: #line, type: .codeError, action: .alertAndDisplay, fileName: url.lastPathComponent, errorMsg: msg)
        }
        
    }//end func
    
}//end struct Catagories
