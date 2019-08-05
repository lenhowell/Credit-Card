//
//  ViewController.swift
//  Credit Cards
//
//  Created by Lenard Howell on 7/28/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSWindowDelegate {
    
    //MARK:- Instance Variables
    
    var dictCategory = [String: CategoryItem]() //String: is the Key 2nd String is the value
    var myFileNameOut = "Combined-Creditcard-Master.csv"
    let descLength = 8
    var countWithCat = 0
    let suppressionList = "& \";"
    var desktopPathUrl = URL(fileURLWithPath: "")
    
    //MARK:- Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        loadCategories() // Build Categories Dictionary
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    //FIXME: windowShouldClose never called.
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApplication.shared.terminate(self)
        return true
    }

    //MARK:- @IBActions
    
    @IBAction func btnStart(_ sender: Any) {
        main()
    }
    
    //MARK:- @IBOutlets
    
    @IBOutlet weak var txtDteRng: NSTextField!
    @IBOutlet weak var txtCrdType: NSTextField!
    @IBOutlet weak var lblErrMsg: NSTextField!
    @IBOutlet weak var lblResults: NSTextField!
    
    //MARK:- Main Program
    
    func main(){
        lblErrMsg.stringValue = ""
        var fileContents = ""                       // Where All Transactions in a File go
        var lineItemArray = [LineItem]()
        var fileCount = 0
        var junkFileCount = 0
        guard let downloadsPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            // Here if Path to Input File is NOT valid, Put Out Error Message and Exit Program
            lblErrMsg.stringValue = "Directory Path to Target File Does Not Exist!!!!"
            return
        }
        
        // We are here if Path is Valid
        let dir = downloadsPath.appendingPathComponent("Credit Card Trans") // Append FileName To Path
        let fileURLs = getContentsOf(dirURL: dir)
        
        for fileURL in fileURLs {
            let fileName = fileURL.lastPathComponent
            let cardType = fileName.prefix(3).uppercased()
            //— reading —    // macOSRoman is more forgiving than utf8
            // If File exists/Readable is checked in the "DO" Loop
            do {
                fileContents = try String(contentsOf: fileURL, encoding: .macOSRoman)
                // File Exists if we are here and Entire file is now in "fileContents" variable
            } catch {
                // Here if file does NOT exists/Readable. Put out an Error Message and Exit Program
                lblErrMsg.stringValue = "File Does NOT Exist, \(fileURL.path)!!!!"
                continue
            }
            
            let cardArray = fileContents.components(separatedBy: "\n")
            
            // Check which Credit Card Transactions we are currently processing
            switch cardType {
            case "C1V":
                lineItemArray += handleCards(fileName: fileName, cardArray: cardArray)
                fileCount += 1
            case "C1R":
                lineItemArray += handleCards(fileName: fileName, cardArray: cardArray)
                fileCount += 1
            case "DIS":
                lineItemArray += handleCards(fileName: fileName, cardArray: cardArray)
                fileCount += 1
            case "CIT":
                lineItemArray += handleCards(fileName: fileName, cardArray: cardArray)
                fileCount += 1
            default:
                junkFileCount += 1
            }
        }//loop
        
        outputTranactions(lineItemArray: lineItemArray)
        print (dictCategory)
        writeCategoriesToBundle(dictCat: dictCategory)
        lblResults.stringValue = "\(fileCount) Files Processed.\n\(junkFileCount) NOT Recognized as a Credit Card Transaction\n \(lineItemArray.count) CREDIT CARD Transactions PROCESSED.\n \(countWithCat) Were Assigned a category."
        

    }// End of func Main
    
    
    //MARK:- Support Functions
    

    func badDate() {
        lblErrMsg.stringValue = "Date must be in YYMM Format, \(txtDteRng.stringValue ) is Wrong!!"
    }
    
    func loadCategories()
    {     // Check "Bundle" to see if "CategoryLookup.txt" Entry exists.
        guard let filePath = Bundle.main.path(forResource: "CategoryLookup", ofType: "txt") else {
            return              // Not in the "Bundle", EXIT Program
        }
        let fileCategoriesURL =  URL(fileURLWithPath: filePath)
        // Get data in "CategoryLookup" if there is any. If NIL set to Empty.
        //let contentof = (try? String(contentsOfFile: filePathCategories)) ?? ""
        let contentof = (try? String(contentsOf: fileCategoriesURL)) ?? ""
        let lines = contentof.components(separatedBy: "\n") // Create var lines containing Entry for each line.
        
        // For each line in "CategoryLookup"
        for line in lines
        {
            if line == ""{
                continue
            }
            // Create an Array of ech line components the seperator being a ","
            let categoryArray = line.components(separatedBy: ",")
            
            // Create a var "description" containing the first "descLength" charcters of column 0 after having compressed out spaces. This will be the KEY into the CategoryLookup Table/Dictionary.
//            let description = String(categoryArray[0].replacingOccurrences(of: " ", with: "").uppercased().prefix(descLength))

            let description = String(categoryArray[0].replacingOccurrences(of: "["+suppressionList+"]", with: "", options: .regularExpression, range: nil).uppercased().prefix(descLength))

            let category = categoryArray[1].trimmingCharacters(in: .whitespaces) //drop leading and trailing white space
            let source = categoryArray[2].trim.replacingOccurrences(of: "\"", with: "")
            let categoryItem = CategoryItem(category: category, source: source)
            dictCategory[description] = categoryItem

        }
        print(dictCategory)
    }
    //MARK:- copyStringToClipBoard
    public func copyStringToClipBoard(textToCopy: String) {
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(textToCopy, forType: NSPasteboard.PasteboardType.string)
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
    }
    
    // Write Output File
    func outputTranactions(lineItemArray: [LineItem]) {
        
        var outPutStr = "Card Type\tTranDate\tDesc\tDebit\tCredit\tCategory\tRaw Category\tCategory Source\n"
        for xX in lineItemArray {
            let text = "\(xX.cardType)\t\(xX.tranDate)\t\(xX.desc)\t\(xX.debit)\t\(xX.credit)\t\(xX.genCat)\t\(xX.rawCat)\t\(xX.catSource)\n"
            outPutStr += text
        }
        
        // Verify that the PATh to "Desktop" and the
        if let desktopPathUrl = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            let fileUrl = desktopPathUrl.appendingPathComponent(myFileNameOut)
            
            // Copy Entire Output File To Clipboard. This will be used to INSERT INTO EXCEL
            copyStringToClipBoard(textToCopy: outPutStr)
            
            // Write to Output File
            do    {
                try outPutStr.write(to: fileUrl, atomically: false, encoding: .utf8)
            } catch {
                lblErrMsg.stringValue = "Write Failed!!!! \(fileUrl.path)"
            }
            
 //           print()
        } else {
            lblErrMsg.stringValue = "Directory Path or Output File Does Not Exist!!!!"
        }

    }//end func
    
    
    func recordCorruptedData(fileName: String, lineNum: Int, lineText: String, errorText: String) {
        //TODO: Append to Error File
    }
    
    
    func handleCards(fileName: String, cardArray: [String]) -> [LineItem]{
        let cardType = String(fileName.prefix(3).uppercased())
        let transactions = cardArray.dropFirst()         // Drop "first" Line from Input Stream(Headers)
        var lineItemArray = [LineItem]()                // Create Array variable(lineItemArray) Type lineItem.
        
        // Derive a Dictionary of Column Numbers from header
        let headers = cardArray[0].components(separatedBy: ",")
        let expectedColumnCount = headers.count
        var dictColNums = [String: Int]()
        for colNum in 0..<expectedColumnCount {
            let rawKey = headers[colNum].uppercased().trim
            let key: String
            if rawKey == "DATE" {
                 key = "TRAN"
            } else {
                key = String(rawKey.prefix(4))
            }
            dictColNums[key] = colNum
        }//next colNum
        
        var lineNum = 1
        for tran in transactions {
            lineNum += 1
            if tran.trim.isEmpty { continue }
            var transaction = tran
            // Parse transaction, replacing all "," within quotes with a ";"
            var inQuote = false
            var tranArray = Array(tran)     // Create an Array of Individual characters in current transaction.
            
            for (i,char) in tranArray.enumerated() {
                if char == "\"" {
                    inQuote = !inQuote      // Flip the switch indicating a quote was found.
                }
                if inQuote && char == "," {
                    tranArray[i] = ";"      // Comma within a quoted string found, replace with a ";".
                }
            }
            transaction = String(tranArray).uppercased()    // Covert the Parsed "Array" Item Back to a string
            transaction = transaction.replacingOccurrences(of: "\"", with: "")
            transaction = transaction.replacingOccurrences(of: "\r", with: "")
            let columns = transaction.components(separatedBy: ",")  // Isolate columns within this transaction
            if columns.count != expectedColumnCount {
                let msg = "\(columns.count) in transaction; should be \(expectedColumnCount)"
                recordCorruptedData(fileName: fileName, lineNum: lineNum, lineText: tran, errorText: msg)
            }
            var lineitem = LineItem()
            // Building the Output record
            lineitem.tranDate = columns[dictColNums["TRAN"]!]
            if let colNum = dictColNums["POST"] {
                lineitem.postDate = columns[colNum]
            }
            if let colNum = dictColNums["DESC"] {
                lineitem.desc = columns[colNum].replacingOccurrences(of: "\"", with: "")
            }
            if let colNum = dictColNums["CARD"] {
                lineitem.cardNum = columns[colNum]
            }
            if let colNum = dictColNums["CATE"] {
                lineitem.rawCat = columns[colNum]
            }
            if let colNum = dictColNums["AMOU"] {
                let amount = Double(columns[colNum].trim) ?? 0
                if amount < 0 {
                    lineitem.credit = -amount
                } else {
                    lineitem.debit = amount
                }
            }
            lineitem.cardType = cardType
            lineitem.genCat = ""                          // Initialze the Generated Category
            var key = lineitem.desc.uppercased()
            //            key = key.replacingOccurrences(of: "\"", with: "")    // Remove Single Quotes from Key
            //            key = key.replacingOccurrences(of:  " ", with: "")    // Compress key
            //            key = key.replacing Occurrences(of:  ";", with: "")    // Remove semi-colons from Key
            key = key.replacingOccurrences(of: "["+suppressionList+"]", with: "", options: .regularExpression, range: nil)
            key = String(key.prefix(descLength))    // Truncate
            if let catItem = dictCategory[key] {      // Here if Lookup of KEY was successfull
                lineitem.genCat = catItem.category
                lineitem.catSource = catItem.source
                countWithCat += 1
//                print("Found ", mykey)
            } else {
                let source = "PG"
                if cardType == "DIS"{
                    print("          Did Not Find ",key)
                    let catItem = CategoryItem(category: lineitem.rawCat, source: source)
                    dictCategory[key] = catItem
                    print("Category that was inserted = Key==> \(key) Value ==> \(lineitem.rawCat) Source ==> \(source)")
                    //                outPutStr += text
                }
            }
            lineItemArray.append(lineitem)          // Add new output Record to be output
            //            print(lineitem)
        }// End of FOR loop
        return lineItemArray

    }// End Func handleCards
    
    func writeCategoriesToBundle(dictCat: [String: CategoryItem]) {
        var text = ""
        let myFileNameOut =  "CategoryLookup.txt"

        if let desktopPathUrl = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
        let fileCategoriesURLout = desktopPathUrl.appendingPathComponent(myFileNameOut)

        for catItem in dictCat {
            text += "\(catItem.key), \(catItem.value.category),  \(catItem.value.source)\n"
        }
        
        //— writing —
        do    { try text.write(to: fileCategoriesURLout, atomically: false, encoding: .utf8) }
        catch {
            /* error handling here */
            print()
        }
            print("\n😀 Successful write to: \(fileCategoriesURLout.path)")
        }

    }
    
}//end class



