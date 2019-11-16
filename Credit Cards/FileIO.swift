//
//  FileIO.swift
//  Credit Cards
//
//  Created by Lenard Howell on 8/9/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Foundation

// Used by MyModifiedTransactions & VendorCategoryLookup
public struct CategoryItem: Equatable {
    var category    = ""
    var source      = ""  // Source of Category (including "$" for "LOCKED", "*" for ModTrans )
}

// Used by MyModifiedTransactions
public struct ModifiedTransactionItem: Equatable {
    var catItem = CategoryItem()
    var memo    = ""
}
//MARK:- FileIO struct

public struct FileIO {

    static func folderExists(atPath: String, isPartialPath: Bool = false) -> Bool {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        var exists = false
        if isPartialPath {
            let homeURL = fileManager.homeDirectoryForCurrentUser
            let dirURL = homeURL.appendingPathComponent(atPath)
            exists = fileManager.fileExists(atPath: dirURL.path, isDirectory: &isDirectory) && isDirectory.boolValue
        } else {
            exists = fileManager.fileExists(atPath: atPath, isDirectory: &isDirectory) && isDirectory.boolValue
        }
        return exists
    }//end func

    // Creates FileURL from FolderPath & FilePath or returns an error message
    static func makeFileURL(pathFileDir: String, fileName: String) -> (URL, String) {
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
        return (dirURL, "Folder \"\(dirURL.path)\" does NOT exist!")
    }

    static func removeUserFromPath(_ fullPath: String) -> String {
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

    static func saveBackupFile(url: URL, multiple: Bool = false, addonName: String = "BU") {
        // Rename the existing file to "CategoryLookup yyyy-MM-dd HHmm.txt"
        let newPath = FileIO.makeBackupFilePath(url: url, multiple: multiple, addonName: addonName)
        // -----------------------------------------------------------------

        // Create a FileManager instance
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: newPath) {    //**
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

    static func makeBackupFilePath(url: URL, multiple: Bool, addonName: String) -> String {
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
        return newPath
    }//end func makeBackupFilePath

    static func getTransFileList(transDirURL: URL) -> [URL] {
        print("\nFileIO.getTransFileList#\(#line)")
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: transDirURL, includingPropertiesForKeys: [], options:  [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
            let transURLs = fileURLs.filter{ qualifyTransFileName(url: $0) }

            print("\(transURLs.count) Transaction Files found.")
            for url in transURLs {
                print(url.path)
            }
            print()
            return transURLs
        } catch {
            print(error.localizedDescription)
        }
        return []
    }//end func

    //TODO: Tell user about non-qualified filenames & show rules.
    static func qualifyTransFileName(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        if ext != "csv" && ext != "tsv" && ext != "dnl"     { return false }    // not .csv,.tsv,.dnl
        let fullName = url.deletingPathExtension().lastPathComponent
        let tuple = fullName.splitAtFirst(char: " ")
        let name = tuple.lft
        let parts = name.components(separatedBy: "-")
        let partsCount = parts.count
        if partsCount < 2                                   { return false }    // no "-"
        let card = parts[0]
        if card.count < 2 || card.count > Const.maxCardTypeLen    { return false }    // card <2 chars
        guard let year = Int(parts[1]) else                 { return false }
        if year < 1980 || year > 2099                       { return false }
        if partsCount >= 3 {
            guard let month = Int(parts[2]) else            { return false }
            if month < 1 || month > 12                      { return false }
        }
        return true
    }

    public enum CsvTsv {
        case csv, tsv
    }
    //---- parseDelimitedLine - Parse line, replacing all "," within quotes with a ";"
    // Caution: removes leading & trailing spaces, even if enclosed in quotes
    static func parseDelimitedLine(_ line: String, csvTsv: CsvTsv) -> [String] {
        if csvTsv == .tsv {
            let columns = line.components(separatedBy: "\t").map{$0.trim}  // Isolate columns within this transaction
            return columns
        }

        var modLine = line
        if line.contains("\"") {
            var inQuote = false
            var charArray = Array(line)     // Create an Array of Individual characters in current transaction.

            for (i,char) in charArray.enumerated() {
                if char == "\"" {
                    inQuote = !inQuote      // Flip the switch indicating a quote was found.
                }
                if inQuote && char == "," {
                    charArray[i] = ";"      // Comma within a quoted string found, replace with a ";".
                }
            }
            modLine = String(charArray) //.uppercased()    // Covert the Parsed "Array" Item Back to a string
        }
        modLine = modLine.replacingOccurrences(of: "\"", with: "")
        modLine = modLine.replacingOccurrences(of: "\r", with: "")

        let columns = modLine.components(separatedBy: ",").map{$0.trim}  // Isolate columns within this transaction
        return columns
    }//end func parseDelimitedLine

}//end struct FileIO

//---- deleteSupportFile -
func deleteSupportFile(url: URL, fileName: String, msg: String) -> Bool {
    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: url.path) {
        let response = GBox.alert("Do you want to delete \(fileName)?\nYou will loose any\n\(msg)", style: .yesNo)
        if response == .yes {
            if url.path.hasSuffix("\(fileName)") {
                //fileManager.removeItem(at: url)
                FileIO.saveBackupFile(url: url, addonName: "-Deleted")
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
            let myCatAlias = myCatAliasRaw.trim.removeEnclosingQuotes().uppercased()

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

//---- writeMyCats - 
func writeMyCats(url: URL) {
    FileIO.saveBackupFile(url: url)

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

func loadMyModifiedTrans(myModifiedTranURL: URL) -> [String: ModifiedTransactionItem]  {
    //let dictColNums = ["TRAN":0, "DESC":1, "DEBI":2, "CRED":3, "CATE":4] "NUMBER","POST","CARD","AMOU"
    //let fileName = myModifiedTranURL.lastPathComponent
    var dictTrans = [String: ModifiedTransactionItem]()
    let contentof = (try? String(contentsOf: myModifiedTranURL)) ?? ""
    let lines = contentof.components(separatedBy: "\n") // Create var lines containing Entry for each line.
    var lineNum = 0
    for line in lines {
        lineNum += 1
        if line.trim.isEmpty || line.hasPrefix("//") {
            continue
        }
        let comps = line.components(separatedBy: "\t").map{$0.trim}
        if comps.count < 3 {
            handleError(codeFile: "FileIO", codeLineNum: #line, type: .dataError, action: .alertAndDisplay, fileName: myModifiedTranURL.lastPathComponent, dataLineNum: lineNum, lineText: line, errorMsg: "missing <tab>(s)")
            continue
        }
        let genCat      = comps[0]
        let catSource   = comps[1]
        let key         = comps[2]
        var memo = ""
        if comps.count > 3 {
            memo = comps[3]
        }
        let catItem = CategoryItem(category: genCat, source: catSource)
        dictTrans[key] = ModifiedTransactionItem(catItem: catItem, memo: memo)
    }//next line

    return dictTrans
}//end func loadMyModifiedTrans

//TODO: writeModTransTofile - only write if changed
func writeModTransTofile(url: URL, dictModTrans: [String: ModifiedTransactionItem]) {
    FileIO.saveBackupFile(url: url)
    var text = "// Machine-generated file\n"
    text += "//Category     <tab> Source <tab> (Type|Date|Num|Credit|Debit)\n"
    for (key, modTranItem) in dictModTrans.sorted(by: {$0.key < $1.key}) {
        let cat = modTranItem.catItem.category.PadRight(20)
        text += "\(cat)\t\(modTranItem.catItem.source)\t\(key)\t\(modTranItem.memo)\n"
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
            let msg = "expected a comma in \(url.lastPathComponent) line# \(lineNum)\n\(line)"
            handleError(codeFile: "FileIO", codeLineNum: #line, type: .dataError, action: .alertAndDisplay, fileName: url.lastPathComponent, dataLineNum: lineNum, lineText: line, errorMsg: msg)
            continue
        }
        let shortName = vendorShortNameArray[0].trim.removeEnclosingQuotes()
        let fullDescKey = vendorShortNameArray[1].trim.removeEnclosingQuotes()
        dictVendorShortNames[shortName] = fullDescKey
    }
    return dictVendorShortNames
}//end func loadVendorShortNames

func writeVendorShortNames(url: URL, dictVendorShortNames: [String: String]) {
    FileIO.saveBackupFile(url: url)
    var text = "// Machine-generated, user-editable file\n"
    text += "// ShortName (prefix),   Full Description Key\n"
    for (shortName, fullDescKey) in dictVendorShortNames.sorted(by: {$0.key < $1.key}) {
        let shortNameInQuotes = "\"\(shortName)\""
        text += "\(shortNameInQuotes.PadRight(Const.descKeyLength, truncate: false)), \(fullDescKey)\n"
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

// MARK:- VendorShortNames OO struct

public struct VendorShortNames {
    var filename = "VendorShortNames.txt"
    var dict     = [String: String]()        // Hash for VendorShortNames Lookup
    var url: URL?

    init(lines: [String], silentMode: Bool = false) {
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
                var action: ErrAction = .alertAndDisplay
                if silentMode { action = .display }
                let msg = "expected a comma in \(filename) line# \(lineNum)\n\(line)"
                handleError(codeFile: "FileIO", codeLineNum: #line, type: .dataError, action: action, fileName: url?.lastPathComponent ?? "?", dataLineNum: lineNum, lineText: line, errorMsg: msg)
                continue
            }
            let shortName = vendorShortNameArray[0].trim.removeEnclosingQuotes()
            let fullDescKey = vendorShortNameArray[1].trim.removeEnclosingQuotes()
            self.dict[shortName] = fullDescKey
        }
    }//end init

    init(content: String, silentMode: Bool = false) {
        let lines = content.components(separatedBy: "\n") // Create var lines containing Entry for each line.
        self.init(lines: lines, silentMode: silentMode)
    }

    init(url: URL, silentMode: Bool = false) {
        //TODO: If url is not a file, append default filename
        let content = (try? String(contentsOf: url)) ?? ""
        self.init(content: content, silentMode: silentMode)
        self.url = url
        self.filename = url.lastPathComponent
    }//end init

    func writeToFile(urlOverride: URL? = nil) {
        var urlOpt = urlOverride
        if urlOpt == nil {
            urlOpt = self.url
        }
        guard let url = url else {
            let msg = "Could not write new MyModifiesTransactions file."
            handleError(codeFile: "FileIO", codeLineNum: #line, type: .codeError, action: .alertAndDisplay, fileName: "-missing URL-", errorMsg: msg)
            return
        }
        FileIO.saveBackupFile(url: url)
        var text = "// Machine-generated, user-editable file\n"
        text += "// ShortName (prefix),   Full Description Key\n"
        for (shortName, fullDescKey) in self.dict.sorted(by: {$0.key < $1.key}) {
            let shortNameInQuotes = "\"\(shortName)\""
            text += "\(shortNameInQuotes.PadRight(Const.descKeyLength, truncate: false)), \(fullDescKey)\n"
        }
        //— writing —
        do {
            try text.write(to: url, atomically: false, encoding: .utf8)
            print("\n😀 Successfully wrote \(self.dict.count) transactions to: \(url.path)")
        } catch {
            let msg = "Could not write new MyModifiesTransactions file."
            handleError(codeFile: "FileIO", codeLineNum: #line, type: .codeError, action: .alertAndDisplay, fileName: url.lastPathComponent, errorMsg: msg)
        }
    }//end method

}//end struct

// MARK:- Accounts

public struct Account {
    public enum AmountDefault: String {case debit,credit }
    public enum AcctType: String { case creditCard, debitCard, check, activity }

    public var code = ""
    public var name = ""
    public var type: AcctType        = .creditCard
    public var amount: AmountDefault = .debit
    public var lineForFile: String {
        return "\(code.PadRight(10)), \(amount.rawValue.PadRight(10)), \(type.rawValue.PadRight(11)), \"\(name)\""
        //SAMPLE    , Debit     , CreditCard , "Sample Credit Card"
    }

    init?(fromCsvLine line: String) {
        // Create an Array of line components the seperator being a ","
        let items = line.components(separatedBy: ",")
        if items.count < 3 {
            return nil
        }
        code = items[0].trim.removeEnclosingQuotes()

        let strAmount = items[1].trim.removeEnclosingQuotes().uppercased()
        if strAmount.isEmpty || strAmount.hasPrefix("DEB") {
            amount = .debit
        } else if strAmount.hasPrefix("CRED") {
            amount = .credit
        } else {
            return nil
        }

        let strType = items[2].trim.removeEnclosingQuotes().uppercased().prefix(5)
        switch strType {
        case "CREDI":
            type = .creditCard
        case "DEBIT":
            type = .debitCard
        case "CHECK":
            type = .check
        case "ACTIV", "MIXED":
            type = .activity
        default:
            return nil
        }
        if items.count < 4 { return }
        let strName = items[3].trim.removeEnclosingQuotes()
        name = strName
    }
}


public struct Accounts {

    static var filename = "MyAccounts.txt"
    var dict     = [String: Account]()        // Hash for VendorShortNames Lookup
    var url: URL?

    init(lines: [String]) {
        dict = [:]
        var lineNum = 0
        for line in lines {
            lineNum += 1
            if line.trim.isEmpty || line.hasPrefix("//") {
                continue
            }

            if let account = Account(fromCsvLine: line) {
                dict[account.code] = account
            } else {
                let msg = "Bad data"
                handleError(codeFile: "FileIO", codeLineNum: #line, type: .dataError, action: .alertAndDisplay, fileName: Accounts.filename, dataLineNum: lineNum, lineText: line, errorMsg: msg)
            }
        }
    }//end init from String array

    init() {
        self.init(content: "")
    }

    init(content: String) {
        let lines = content.components(separatedBy: "\n") // Create var lines containing Entry for each line.
        self.init(lines: lines)
    }

    init(url: URL) {
        //TODO: If url is not a file, append default filename
        let content = (try? String(contentsOf: url)) ?? ""
        self.init(content: content)
        self.url = url
        Accounts.filename = url.lastPathComponent
    }//end init from URL

    func writeToFile(urlOverride: URL? = nil) {
        var urlOpt = urlOverride
        if urlOpt == nil {
            urlOpt = self.url
        }
        guard let url = url else {
            let msg = "Could not write new MyModifiesTransactions file."
            handleError(codeFile: "FileIO", codeLineNum: #line, type: .codeError, action: .alertAndDisplay, fileName: "-missing URL-", errorMsg: msg)
            return
        }
        FileIO.saveBackupFile(url: url)
        var text = "// Machine-generated, user-editable file\n"
        text += "//Code    , Amount    , Type       , Name\n"
        for (_, value) in self.dict.sorted(by: {$0.key < $1.key}) {
            text += "\(value.lineForFile)\n"
        }
        text += "\n"
        text += "// Each line must have 3-4 comma-separated entries:\n"
        text += "// Code:   Prefix (up to \"-\", 10-letters max) of Transaction fileName\n"
        text += "// Amount: if Transaction file has \"Amount\", is a positive value \"Debit\" or \"Credit\"?\n"
        text += "// Type:   CreditCard, DebitCard, Activity, or Check\n"
        text += "// Name:   optional Name of the account (or card)\n"
        //— writing —
        do {
            try text.write(to: url, atomically: false, encoding: .utf8)
            print("\n😀 Successfully wrote \(self.dict.count) transactions to: \(url.path)")
        } catch {
            let msg = "Could not write new MyModifiesTransactions file."
            handleError(codeFile: "FileIO", codeLineNum: #line, type: .codeError, action: .alertAndDisplay, fileName: url.lastPathComponent, errorMsg: msg)
        }
    }//end method

}//end struct Accounts

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
            let msg = "Expected 2 commas per line at line# \(lineNum)\n\(line)"
            handleError(codeFile: "FileIO", codeLineNum: #line, type: .dataError, action: .display, fileName: url.lastPathComponent, dataLineNum: lineNum, lineText: line, errorMsg: msg)
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

    FileIO.saveBackupFile(url: url)

    var text = "// Description keys are up to \(Const.descKeyLength) chars long.\n"
    text += "// Apostrophies are removed, and other extraneous punctuation changed to spaces.\n"
    text += "// Prefix of \"SQ *\" or any other \"???*\" is removed if result > 9 chars.\n"
    text += "// When a double-space is found, the rest is truncated.\n"
    text += "// When a phone number or \"xxx...\" or other multi-digit number is reached the rest is truncated.\n"
    text += "\n// Description Key        Category              Source\n"
    var prevCat = ""
    print("\n Different Descs that start with the same 15-chars")
    for catItem in dictCat.sorted(by: {$0.key < $1.key}) {
        text += "\(catItem.key.PadRight(Const.descKeyLength)), \(catItem.value.category.PadRight(26)),  \(catItem.value.source)\n"

        let first10 = String(catItem.key.prefix(15))
        if first10 == prevCat.prefix(15) {
            print("😡 \"\(prevCat)\" (\(prevCat.count)-chars)     \"\(catItem.key)\" (\(catItem.key.count)-chars)")
        }
        prevCat = catItem.key
    }
    
    //— writing —
    do {
        try text.write(to: url, atomically: false, encoding: .utf8)
        print("\n😀 Successfully wrote \(dictCat.count) items, using \(Const.descKeyLength) keys, to: \(url.path)")
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

//MARK:- New File Formats
/*
VendorProfile - Combined VendorCatagoryLookup & VendorShortNames
DescKey
    fullName=xxx
    isTemplate   = false
    templateName = ""       //Vendor templates (ServiceStations, Stocks, Wire, etc)
    DateAdded    = Datexxx
    DateModify   = Dateyyy
    Addedby      = initxxx
    ModifyBy     = initYYY
    alias        = xxx   // (prefix)
    ...
    category     = Categoryxxx    // Array of equals?
    ...
    catFrom$     = Categoryxxx, >=$xxx, <=$yyy     //based $Amount being between $Val1 & $Val2
    ...
    CatFromRawCat = Categoryxxx, RewCat, =/prefix/contains/suffix   //based on RawCat = xxx
    ...


 */


struct VendorProfile {
    var descKey     = ""           // key
    var fullName    = ""
    var isTemplate  = false
    var templateName = ""
    var dateAdded   = Date.distantPast
    var dateModifid = Date.distantPast
    var addedBy     = ""
    var modifiedBy  = ""
    var aliases     = [String]()   // keys  //CompareTypes?
    var category    = ""    // Array of equals?
    var catsFromRaw = [CatFromRawCat]()
    var catsFromAmt = [CatFromAmountDebit]()
}
enum CompareType {
    case equal, prefix, contains, suffix
}
struct CatFromRawCat {
    var genCat = ""
    var rawCat = ""
    var compareType = CompareType.equal
}
struct CatFromAmountDebit {
    var genCat      = ""
    var greaterThan = 0.00
    var lessThan    = 0.00
}


