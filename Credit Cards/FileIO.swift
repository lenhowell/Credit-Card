//
//  FileIO.swift
//  Credit Cards
//
//  Created by Lenard Howell on 8/9/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Foundation

public struct CategoryItem: Equatable {
    var category    = ""
    var source      = ""  // Source of Category (including "$" for "LOCKED" )
}

//MARK:- General Purpose

func folderExists(atPath: String, isPartialPath: Bool = false) -> Bool {
    let fileManager = FileManager.default
    var isDirectory: ObjCBool = false

    if isPartialPath {
        let homeURL = fileManager.homeDirectoryForCurrentUser
        let dirURL = homeURL.appendingPathComponent(atPath)
        return fileManager.fileExists(atPath: dirURL.path, isDirectory: &isDirectory) && isDirectory.boolValue
    } else {
        return fileManager.fileExists(atPath: atPath, isDirectory: &isDirectory) && isDirectory.boolValue
    }
    
}//end func

// Creates FileURL from FolderPath & FilePath or returns an error message
func makeFileURL(pathFileDir: String, fileName: String) -> (URL, String) {
    let fileManager = FileManager.default
    let homeURL = fileManager.homeDirectoryForCurrentUser
    let dirURL = homeURL.appendingPathComponent(pathFileDir)

    var isDirectory: ObjCBool = false
    if fileManager.fileExists(atPath: dirURL.path, isDirectory: &isDirectory) && isDirectory.boolValue {
        //print("😀 \(#line) \"\(dirURL.path)\" exists")
        let fileURL = dirURL.appendingPathComponent(fileName)
        return (fileURL, "")
    }
    //print("⛔️ \(#line) \(dirURL.path) does NOT exist!")
    return (dirURL, " Folder \"\(dirURL.path)\" does NOT exist!")
}

//------ getContentsOf(directoryURL:)
///Get URLs for Contents Of DirectoryURL
/// - Parameter dirURL: DirectoryURL (URL)
/// - Returns:  Array of URLs
func getContentsOf(dirURL: URL) -> [URL] {
    do {
        let urls = try FileManager.default.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: [], options:  [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
        return urls
    } catch {
        return []
    }
}//end func

public func removeUserFromPath(_ fullPath: String) -> String {
    var path = fullPath
    if path.contains("/Users/") {
        let comps = path.components(separatedBy: "/Users/")
        if comps.count > 1 {
            path = comps[1]
            let idxSlash = path.firstIntIndexOf("/")
            if idxSlash >= 0 && idxSlash < path.count-1 {
                path = String(path.dropFirst(idxSlash+1))
            }
        }
    }
    return path
}

public func saveBackupFile(url: URL, multiple: Bool = false, addonName: String = "BU") {
    // Create a FileManager instance
    let fileManager = FileManager.default
    // Rename the existing file to "CategoryLookup yyyy-MM-dd HHmm.txt"
    let oldNameWithExt = url.lastPathComponent
    let nameComps = oldNameWithExt.components(separatedBy: ".")
    let oldName = nameComps[0]
    let ext: String
    if nameComps.count >= 2 {
        ext = "." + nameComps[1]
    } else {
        ext = ""
    }
    var adder = addonName
    if multiple {
        //for multiple backups, use the creation dates instead of "BU" in the names
        let fileAttributes = FileAttributes.getFileInfo(url: url)
        let modDate = fileAttributes.modificationDate
        adder = modDate?.toString("yyyy-MM-dd HHmm") ?? addonName
    }

    let newName = oldName + adder + ext
    let newPath = url.deletingLastPathComponent().path + "/" + newName

    if fileManager.fileExists(atPath: newPath) {
        // Delete newFile if it already exists
        do {
            try fileManager.removeItem(atPath: newPath)
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
    }//end if new file already exists

    do {
        // Rename oldFile to newFile
        try fileManager.moveItem(atPath: url.path, toPath: newPath)
    } catch {
        // print("Error: \(error.localizedDescription)")
    }

}//end func saveBackupFile

//---- deleteSupportFile -
func deleteSupportFile(url: URL, fileName: String, msg: String) -> Bool {
    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: url.path) {
        let response = GBox.alert("Do you want to delete \(fileName)?\nYou will loose any\n\(msg)", style: .yesNo)
        if response == .yes {
            if url.path.hasSuffix("\(fileName)") {
                //fileManager.removeItem(at: url)
                saveBackupFile(url: url, addonName: "-Deleted")
                return true
            }
        }
    }
    return false
}


//MARK: FileAttributes struct
//????? incorporate both getFileInfo() funcs into struct as inits
public struct FileAttributes: Equatable {
    let url:              URL?
    var name                    = "????"
    var creationDate:     Date?
    var modificationDate: Date?
    var size                    = 0
    var isDir                   = false

    //------ getFileInfo - returns attributes of fileName (file or folder) as a FileAttributes struct
    ///Get file info for a file path
    /// - Parameter str: file path
    /// - Returns:  FileAttributes instance
    static func getFileInfo(_ str: String) -> FileAttributes {
        let url = URL(fileURLWithPath: str)
        return getFileInfo(url: url)
    }

    //------ getFileInfo - returns attributes of url (file or folder) as a FileAttributes struct
    ///Get file info for a URL
    /// - Parameter url: file URL
    /// - Returns:  FileAttributes instance
    static func getFileInfo(url: URL?) -> FileAttributes {
        if let url = url {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let name             = url.lastPathComponent
                let creationDate     = attributes[FileAttributeKey(rawValue: "NSFileCreationDate")]     as? Date
                let modificationDate = attributes[FileAttributeKey(rawValue: "NSFileModificationDate")] as? Date
                let size             = attributes[FileAttributeKey(rawValue: "NSFileSize")]             as? Int ?? 0
                let fileType         = attributes[FileAttributeKey(rawValue: "NSFileType")] as? String
                let isDir            = (fileType?.contains("Dir")) ?? false
                return FileAttributes(url: url, name: name, creationDate: creationDate, modificationDate: modificationDate, size: size, isDir: isDir)
            } catch {   // FileManager error
                return FileAttributes(url: nil, name: "???", creationDate: nil, modificationDate: nil, size: 0, isDir: false)
            }
        } else {   // url = nil
            return FileAttributes(url: nil, name: "???", creationDate: nil, modificationDate: nil, size: 0, isDir: false)
        }
    }//end func getFileInfo

}// end struct FileAttributes


//MARK:- My Catagories

func loadMyCats(myCatsFileURL: URL) -> [String: String]  {
    gMyCatNames = []
    gDictMyCatAliasArray = [String: [String]]()
    var dictMyCats = [String: String]()
    var contentof = ""
    do {
        contentof = (try String(contentsOf: myCatsFileURL))
    } catch {
        print(myCatsFileURL.path)
        print(error.localizedDescription)
        //
    }
    let lines = contentof.components(separatedBy: "\n") // Create var lines containing Entry for each line.
    var lineNum = 0
    gMyCategoryHeader = ""
    var inHeader = true
    for line in lines {
        lineNum += 1
        // Capture header & ignore blanks
        let linetrim = line.trim
        if linetrim.isEmpty || linetrim.hasPrefix("//") || linetrim.hasPrefix("My Name") {
            if inHeader {
                gMyCategoryHeader += line + "\n"
                if linetrim.isEmpty || linetrim.hasPrefix("My Name") {
                    inHeader = false
                }
            }
            continue
        }

        // Create an Array of line components the seperator being a ","
        let myCatsArray = line.components(separatedBy: ",")
        let myCat = myCatsArray[0].trim.removeEnclosingQuotes()
        var aliases = [String]()
         gMyCatNames.append(myCat)

        for myCatAliasRaw in myCatsArray {
            let myCatAlias = myCatAliasRaw.trim.removeEnclosingQuotes()

            if myCatAlias.count >= 3 {
                if myCatAlias != myCat {
                    aliases.append(myCatAlias)
                }
                dictMyCats[myCatAlias] = myCat
            }
        }
        gDictMyCatAliasArray[myCat] = aliases
    }//next line
    gMyCatNames.sort()
    return dictMyCats
}//end func loadMyCats

//---- writeMyCats - Used only when a starter verion from bundle is read in
func writeMyCats(url: URL) {
    saveBackupFile(url: url)

    var text = gMyCategoryHeader
    text += "My Name,               alias1,        alias2,    ...\n"
    var prevCat = ""
    for (cat, array) in gDictMyCatAliasArray.sorted(by: {$0.key < $1.key} ) {
        if  cat.splitAtFirst(char: "-").lft != prevCat.splitAtFirst(char: "-").lft {
            text += "\n"
        }
        prevCat = cat
        text += cat
        var spaceCount = 22 - cat.count
        for alias in array {
            text += "," + String(repeating: " ", count: spaceCount) + alias
            spaceCount = 4
        }
        text += "\n"
    }

    //— writing —
    do {
        try text.write(to: url, atomically: false, encoding: .utf8)
        print("\n😀 Successfully wrote new MyCategories to: \(url.path)")
    } catch {
        let msg = "Could not write new MyCategories file."
        handleError(codeFile: "FileIO", codeLineNum: #line, type: .codeError, action: .alertAndDisplay, fileName: url.lastPathComponent, errorMsg: msg)
    }

}//end func


//MARK:- My Modified Transactions

func loadMyModifiedTrans(myModifiedTranURL: URL) -> [String: CategoryItem]  {
    //let dictColNums = ["TRAN":0, "DESC":1, "DEBI":2, "CRED":3, "CATE":4]
    //let fileName = myModifiedTranURL.lastPathComponent
    var dictTrans = [String: CategoryItem]()
    let contentof = (try? String(contentsOf: myModifiedTranURL)) ?? ""
    let lines = contentof.components(separatedBy: "\n") // Create var lines containing Entry for each line.
    var lineNum = 0
    for line in lines {
        lineNum += 1
        if line.trim.isEmpty || line.hasPrefix("//") {
            continue
        }
        //TODO: MyModifiedTrans - Check for out-of-bounds
        let comps = line.components(separatedBy: "\t").map{$0.trim}
        let genCat = comps[0]
        let catSource = comps[1]
        let key = comps[2]
        let catItem = CategoryItem(category: genCat, source: catSource)
        dictTrans[key] = catItem
    }//next line

    return dictTrans
}//end func loadMyModifiedTrans

//TODO: writeModTransTofile - only write if changed
func writeModTransTofile(url: URL, dictModTrans: [String: CategoryItem]) {
    saveBackupFile(url: url)
    var text = "// Machine-generated file\n"
    text += "//Category     <tab> Source <tab> (Type|Date|Num|Credit|Debit)\n"
    for (key, catItem) in dictModTrans.sorted(by: {$0.key < $1.key}) {
        let cat = catItem.category.PadRight(20)
        text += cat + "\t" + catItem.source + "\t" + key + "\n"
    }
    //— writing —
    do {
        try text.write(to: url, atomically: false, encoding: .utf8)
        print("\n😀 Successfully wrote \(dictModTrans.count) transactions to: \(url.path)")
    } catch {
        let msg = "Could not write new MyModifiesTransactions file."
        handleError(codeFile: "FileIO", codeLineNum: #line, type: .codeError, action: .alertAndDisplay, fileName: url.lastPathComponent, errorMsg: msg)
    }
}//end func

//MARK:- Vendor Short Names

func loadVendorShortNames(url: URL) -> [String: String]  {
    var dictVendorShortNames = [String: String]()
    let contentof = (try? String(contentsOf: url)) ?? ""
    let lines = contentof.components(separatedBy: "\n") // Create var lines containing Entry for each line.
    var lineNum = 0
    for line in lines {
        lineNum += 1
        if line.trim.isEmpty || line.hasPrefix("//") {
            continue
        }
        //let line = line.replacingOccurrences(of: "\"", with: "")

        // Create an Array of line components the seperator being a ","
        let vendorShortNameArray = line.components(separatedBy: ",")
        if vendorShortNameArray.count < 2 {
            handleError(codeFile: "FileIO", codeLineNum: #line, type: .dataError, action: .alertAndDisplay, fileName: url.lastPathComponent, dataLineNum: lineNum, lineText: line, errorMsg: "expected a comma")
            continue
        }
        let shortName = vendorShortNameArray[0].trim.removeEnclosingQuotes()
        let fullDescKey = vendorShortNameArray[1].trim.removeEnclosingQuotes()
        dictVendorShortNames[shortName] = fullDescKey
    }
    return dictVendorShortNames
}//end func loadVendorShortNames

func writeVendorShortNames(url: URL, dictVendorShortNames: [String: String]) {
    saveBackupFile(url: url)
    var text = "// Machine-generated, user-editable file\n"
    text += "// ShortName (prefix),   Full Description Key\n"
    for (shortName, fullDescKey) in dictVendorShortNames.sorted(by: {$0.key < $1.key}) {
        let shortNameInQuotes = "\"\(shortName)\""
        text += "\(shortNameInQuotes.PadRight(descKeyLength, truncate: false)), \(fullDescKey)\n"
    }
    //— writing —
    do {
        try text.write(to: url, atomically: false, encoding: .utf8)
        print("\n😀 Successfully wrote \(dictVendorShortNames.count) transactions to: \(url.path)")
    } catch {
        let msg = "Could not write new MyModifiesTransactions file."
        handleError(codeFile: "FileIO", codeLineNum: #line, type: .codeError, action: .alertAndDisplay, fileName: url.lastPathComponent, errorMsg: msg)
    }
}//end func

public struct VendorShortNames {
    let filename = "VendorShortNames.txt"
    var dict     = [String: String]()        // Hash for VendorShortNames Lookup
    var url      = FileManager.default.homeDirectoryForCurrentUser
}

//MARK:- Vendor Category Lookup

func loadVendorCategories(url: URL) -> [String: CategoryItem]  {
    var dictCat   = [String: CategoryItem]()

    // Get data in "CategoryLookup" if there is any. If NIL set to Empty.
    //let contentof = (try? String(contentsOfFile: filePathCategories)) ?? ""
    let contentof = (try? String(contentsOf: url)) ?? ""
    let lines = contentof.components(separatedBy: "\n") // Create var lines containing Entry for each line.
    
    // For each line in "CategoryLookup"
    var lineNum = 0
    for line in lines {
        lineNum += 1
        if line == "" || line.hasPrefix("//") {
            continue
        }
        // Create an Array of line components the seperator being a ","
        let categoryArray = line.components(separatedBy: ",")
        if categoryArray.count != 3 {
            handleError(codeFile: "FileIO", codeLineNum: #line, type: .dataError, action: .display, fileName: url.lastPathComponent, dataLineNum: lineNum, lineText: line, errorMsg: "Expected 2 commas per line")
            continue
        }
        let descKey  = categoryArray[0].trimmingCharacters(in: .whitespaces)  // make-DescKey(from: categoryArray[0])
        let category = categoryArray[1].trimmingCharacters(in: .whitespaces)  //drop leading and trailing white space
        let source   = categoryArray[2].trim.replacingOccurrences(of: "\"", with: "")
        let categoryItem = CategoryItem(category: category, source: source)
        dictCat[descKey] = categoryItem
    }
    print("\(dictCat.count) Items Read into Category dictionary from: \(url.path)")
    return dictCat
}//end func loadVendorCategories


//---- writeVendorCategoriesToFile - uses workingFolderUrl(I), handleError(F)
func writeVendorCategoriesToFile(url: URL, dictCat: [String: CategoryItem]) {

    saveBackupFile(url: url)

    var text = "// Description keys are up to \(descKeyLength) chars long.\n"
    text += "// Apostrophies are removed, and other extraneous punctuation changed to spaces.\n"
    text += "// Prefix of \"SQ *\" or any other \"???*\" is removed if result > 9 chars.\n"
    text += "// When a double-space is found, the rest is truncated.\n"
    text += "// When a phone number or \"xxx...\" or other multi-digit number is reached the rest is truncated.\n"
    text += "\n// Description Key        Category              Source\n"
    var prevCat = ""
    print("\n Different Descs that start with the same 15-chars")
    for catItem in dictCat.sorted(by: {$0.key < $1.key}) {
        text += "\(catItem.key.PadRight(descKeyLength)), \(catItem.value.category.PadRight(26)),  \(catItem.value.source)\n"

        let first10 = String(catItem.key.prefix(15))
        if first10 == prevCat.prefix(15) {
            print("😡 \"\(prevCat)\" (\(prevCat.count)-chars)     \"\(catItem.key)\" (\(catItem.key.count)-chars)")
        }
        prevCat = catItem.key
    }
    
    //— writing —
    do {
        try text.write(to: url, atomically: false, encoding: .utf8)
        print("\n😀 Successfully wrote \(dictCat.count) items, using \(descKeyLength) keys, to: \(url.path)")
    } catch {
        let msg = "Could not write new CategoryLookup file."
        handleError(codeFile: "FileIO", codeLineNum: #line, type: .codeError, action: .alertAndDisplay, fileName: url.lastPathComponent, errorMsg: msg)
    }
}//end func writeVendorCategoriesToFile

//MARK:- Transaction Files

//---- outputTranactions - uses: handleError(F), workingFolderUrl(I)
func outputTranactions(outputFileURL: URL, lineItemArray: [LineItem]) {
    
    var outPutStr = "Card Type\tTranDate\tDescKey\tDesc\tDebit\tCredit\tCategory\tRaw Category\tCategory Source\tFile LineNum\n"
    for xX in lineItemArray {
        let text = "\(xX.cardType)\t\(xX.tranDate)\t\(xX.descKey)\t\(xX.desc)\t\(xX.debit)\t\(xX.credit)\t\(xX.genCat)\t\(xX.rawCat)\t\(xX.catSource)\t\(xX.auditTrail)\n"
        outPutStr += text
    }
    
    // Copy Entire Output File To Clipboard. This will be used to INSERT INTO EXCEL
    copyStringToClipBoard(textToCopy: outPutStr)
    
    // Write to Output File
    do {
        try outPutStr.write(to: outputFileURL, atomically: false, encoding: .utf8)
    } catch {
        handleError(codeFile: "FileIO", codeLineNum: #line, type: .dataError, action: .alertAndDisplay, fileName: outputFileURL.lastPathComponent, errorMsg: "Write Failed!!!! \(outputFileURL.path)")
    }
 
}//end func outputTranactions

public func getTransFileList(transDirURL: URL) -> [URL] {
    print("\nFileIO.getTransFileList#\(#line)")
    do {
        let fileURLs = try FileManager.default.contentsOfDirectory(at: transDirURL, includingPropertiesForKeys: [], options:  [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
        let csvURLs = fileURLs.filter{ $0.pathExtension.lowercased() == "csv" }
        let transURLs = csvURLs.filter{ $0.lastPathComponent.components(separatedBy: "-")[0].count <= maxCardTypeLen }
        print("\(transURLs.count) Transaction Files found.")
        for url in transURLs {
            print(url.path)
        }
        print()
        return transURLs
    } catch {
        print(error)
    }
    return []
}//end func

