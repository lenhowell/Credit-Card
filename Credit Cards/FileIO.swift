//
//  FileIO.swift
//  Credit Cards
//
//  Created by Lenard Howell on 8/9/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Foundation

func loadCategories(workingFolderUrl: URL, fileName: String) -> [String: CategoryItem]  {
    var dictCategory            = [String: CategoryItem]()
    let startTime = CFAbsoluteTimeGetCurrent()
//    let myFileName =  "CategoryLookup.txt"
    
    let fileCategoriesURL = workingFolderUrl.appendingPathComponent(fileName)
    
    // Get data in "CategoryLookup" if there is any. If NIL set to Empty.
    //let contentof = (try? String(contentsOfFile: filePathCategories)) ?? ""
    let contentof = (try? String(contentsOf: fileCategoriesURL)) ?? ""
    let lines = contentof.components(separatedBy: "\n") // Create var lines containing Entry for each line.
    
    // For each line in "CategoryLookup"
    var lineNum = 0
    for line in lines {
        lineNum += 1
        if line == "" {
            continue
        }
        // Create an Array of line components the seperator being a ","
        let categoryArray = line.components(separatedBy: ",")
        if categoryArray.count != 3 {
            handleError(codeFile: "ViewController", codeLineNum: #line, fileName: fileName, dataLineNum: lineNum, lineText: line, errorMsg: "Expected 2 commas per line")
            continue
        }
        // Create a var "description" containing the first "descKeyLength" charcters of column 0 after having compressed out spaces. This will be the KEY into the CategoryLookup Table/Dictionary.
        //            let description = String(categoryArray[0].replacingOccurrences(of: " ", with: "").uppercased().prefix(descKeyLength))
        
        let description = String(categoryArray[0].replacingOccurrences(of: "["+descKeysuppressionList+"]", with: "", options: .regularExpression, range: nil).uppercased().prefix(descKeyLength))
        
        let category = categoryArray[1].trimmingCharacters(in: .whitespaces) //drop leading and trailing white space
        let source = categoryArray[2].trim.replacingOccurrences(of: "\"", with: "")
        let categoryItem = CategoryItem(category: category, source: source)
        dictCategory[description] = categoryItem
        
    }
    print("\(dictCategory.count) Items Read into Category dictionary")
    
    let endTime   = CFAbsoluteTimeGetCurrent()
    print(endTime-startTime, " sec")
    print()
    return dictCategory
}//end func loadCategories


//---- writeCategoriesToFile - uses workingFolderUrl(I), handleError(F)
func writeCategoriesToFile(workingFolderUrl: URL, fileName: String, dictCat: [String: CategoryItem]) {
    var text = ""
    let myFileName =  "CategoryLookup.txt"
    
    let fileCategoriesURLout = workingFolderUrl.appendingPathComponent(myFileName)
    
    for catItem in dictCat {
        text += "\(catItem.key), \(catItem.value.category),  \(catItem.value.source)\n"
    }
    
    //— writing —
    do {
        try text.write(to: fileCategoriesURLout, atomically: false, encoding: .utf8)
        print("\n😀 Successfully wrote \(dictCat.count) items to: \(fileCategoriesURLout.path)")
    } catch {
        let msg = "Could not write new CategoryLookup file."
        handleError(codeFile: "ViewController", codeLineNum: #line, fileName: myFileName, errorMsg: msg)
    }
}//end func writeCategoriesToFile

//---- outputTranactions - uses: handleError(F), workingFolderUrl(I)
func outputTranactions(workingFolderUrl: URL, fileName: String, lineItemArray: [LineItem]) {
    
    var outPutStr = "Card Type\tTranDate\tDesc\tDebit\tCredit\tCategory\tRaw Category\tCategory Source\n"
    for xX in lineItemArray {
        let text = "\(xX.cardType)\t\(xX.tranDate)\t\(xX.desc)\t\(xX.debit)\t\(xX.credit)\t\(xX.genCat)\t\(xX.rawCat)\t\(xX.catSource)\n"
        outPutStr += text
    }
    
    let fileUrl = workingFolderUrl.appendingPathComponent(fileName)
    
    // Copy Entire Output File To Clipboard. This will be used to INSERT INTO EXCEL
    copyStringToClipBoard(textToCopy: outPutStr)
    
    // Write to Output File
    do {
        try outPutStr.write(to: fileUrl, atomically: false, encoding: .utf8)
    } catch {
        handleError(codeFile: "ViewController", codeLineNum: #line, fileName: fileUrl.path, errorMsg: "Write Failed!!!! \(fileUrl.path)")
    }
 
}//end func outputTranactions
