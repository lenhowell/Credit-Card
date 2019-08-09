//
//  ViewController.swift
//  Credit Cards
//
//  Created by Lenard Howell on 7/28/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

//TODO: Show Alert and/or terminate program on certain errors. (handleError)

import Cocoa

//MARK:- Global Variables

// Constants
let suppressionList = "& \";'`.#*-"                     //Const used in: loadCategories, handleCards
let descLength      = 8                                 //Const used in: loadCategories, handleCards

//MARK:- ViewController
class ViewController: NSViewController, NSWindowDelegate {
    
    //MARK:- Instance Variables
    
    // Constants
    let myFileNameOut    = "Combined-Creditcard-Master.csv" // Only used in outputTranactions
    let catagoryFilename = "CategoryLookup.txt"

    // Variables
    var dictCategory            = [String: CategoryItem]()  // Hash For Category Lookup
    var uniqueCategoryCounts    = [String: Int]()           // Hash For Unique Category Counts
    var containsDictionary      = [String: String]()        // String: is the Key - Generted Category
    var succesfullLookupCount   = 0                         // Used in: main, handleCards
    var addedCatCount           = 0                         // Number of Catagories added by program.
    var workingFolderUrl        = URL(fileURLWithPath: "")
    
    //MARK:- Overrides & Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Create NotificationCenter Observer to listen for post from handleError
        NotificationCenter.default.addObserver( self,
                                                selector: #selector(self.errorPostedFromNotification(_:)),
                                                name:     NSNotification.Name(rawValue: "ErrorPosted"),
                                                object:   nil
        )
    }
    
    override func viewDidAppear() {

        self.view.window?.delegate = self

        guard let desktopUrl = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            let msg = "⛔️ Could not find Working Folder!! (Desktop)"
            print("\n\(msg)\n")
            lblErrMsg.stringValue = msg
            btnStart.isEnabled = false
            return
        }
        workingFolderUrl = desktopUrl
        dictCategory = loadCategories(workingFolderUrl: workingFolderUrl, fileName: catagoryFilename) // Build Categories Dictionary
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApplication.shared.terminate(self)
        return true
    }

    //MARK:- @IBActions
    
    @IBAction func btnStartClick(_ sender: Any) {
        main()
    }
    
    //MARK:- @IBOutlets
    
    @IBOutlet weak var lblErrMsg:  NSTextField!
    @IBOutlet weak var lblResults: NSTextField!
    @IBOutlet weak var btnStart:   NSButton!

    //MARK:- Main Program
    
    func main() {
        var fileContents    = ""                        // Where All Transactions in a File go
        var lineItemArray   = [LineItem]()
        var fileCount       = 0
        var junkFileCount   = 0
        succesfullLookupCount        = 0
        addedCatCount       = 0
        lblErrMsg.stringValue = ""
        
        guard let downloadsPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            // Here if Path to Input File is NOT valid, Put Out Error Message and Exit Program
            lblErrMsg.stringValue = "Directory Path to Target File Does Not Exist!!!!"
            return
        }
        
        // We are here if Path is Valid
        let dir = downloadsPath.appendingPathComponent("Credit Card Trans") // Append FileName To Path
        if !FileManager.default.fileExists(atPath: dir.path) {
            handleError(codeFile: "ViewController", codeLineNum: #line, fileName: dir.path, dataLineNum: 0, lineText: "", errorMsg: "Directory does not exist")
        }
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
            case "C1V", "C1R", "DIS", "CIT":
                lineItemArray += handleCards(fileName: fileName, cardArray: cardArray)
                fileCount += 1
            default:
                junkFileCount += 1
            }
        }//next fileURL
        
        outputTranactions(workingFolderUrl: workingFolderUrl, fileName: myFileNameOut, lineItemArray: lineItemArray)
        let uniqueCategoryCountsSorted = uniqueCategoryCounts.sorted(by: <)
        print("\nuniqueCategoryCountsSorted by key")
        print (uniqueCategoryCountsSorted)
        print("\nuniqueCategoryCounts.sorted by value")
        print (uniqueCategoryCounts.sorted {$0.value > $1.value})

        writeCategoriesToFile(workingFolderUrl: workingFolderUrl, fileName: catagoryFilename, dictCat: dictCategory)
        lblResults.stringValue = "\(fileCount) Files Processed.\n\(junkFileCount) NOT Recognized as a Credit Card Transaction\n \(lineItemArray.count) CREDIT CARD Transactions PROCESSED.\n Of These:\n   (a) \(succesfullLookupCount) were found in Category File.\n  (b) \(addedCatCount) were inserted into Category File."
        
    }// End of func main
    
    
    //MARK:- Support Functions
    
    //---- handleCards - uses Instance Vars: dictCategory(I/O), succesfullLookupCount(I/O), addedCatCount(I/O), descLength(const), suppressionList(const)
    func handleCards(fileName: String, cardArray: [String]) -> [LineItem] {
        let cardType = String(fileName.prefix(3).uppercased())
        var lineItemArray = [LineItem]()                // Create Array variable(lineItemArray) Type lineItem.
        let cardArrayCount = cardArray.count
        
        // Derive a Dictionary of Column Numbers from header
        var lineNum = 0
        var headers = [String]()
        while lineNum < cardArrayCount {
            let components = cardArray[lineNum].components(separatedBy: ",")
            lineNum += 1
            if components.count > 2  {
                headers = components
                //print (lineNum, cardArray[lineNum])
                break
            }
        }
        if headers.isEmpty {
            handleError(codeFile: "ViewController", codeLineNum: #line, fileName: fileName, dataLineNum: lineNum, lineText: "", errorMsg: "Headers not found.")
            return lineItemArray
        }
        let expectedColumnCount = headers.count
        var dictColNums = [String: Int]()
        for colNum in 0..<expectedColumnCount {
            let rawKey = headers[colNum].uppercased().trim.replacingOccurrences(of: "\"", with: "")
            let key: String
            if rawKey == "DATE" {
                key = "TRAN"
            } else if rawKey.hasPrefix("ORIG") && rawKey.hasSuffix("DESCRIPTION") { // 
                key = "DESC"
            } else if rawKey.hasPrefix("MERCH") && rawKey.hasSuffix("CATEGORY") {   // Handle "Merchant Category"
                key = "CATE"
            } else {
                key = String(rawKey.replacingOccurrences(of: "\"", with: "").prefix(4))
            }
            dictColNums[key] = colNum
        }//next colNum
        
        while lineNum < cardArrayCount {
            let tran = cardArray[lineNum]
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
                handleError(codeFile: "ViewController", codeLineNum: #line, fileName: fileName, dataLineNum: lineNum, lineText: tran, errorMsg: msg)
            }
            var lineItem = LineItem()
            // Building the lineitem record
            lineItem.tranDate = columns[dictColNums["TRAN"]!]
            if let colNum = dictColNums["POST"] {
                lineItem.postDate = columns[colNum]
            }
            if let colNum = dictColNums["DESC"] {
                lineItem.desc = columns[colNum].replacingOccurrences(of: "\"", with: "")
                if lineItem.desc.trim.isEmpty {
                    print("\(#line)\n\(transaction)")
                }
            }
            if let colNum = dictColNums["CARD"] {
                lineItem.cardNum = columns[colNum]
            }
            if let colNum = dictColNums["CATE"] {
                lineItem.rawCat = columns[colNum]
            }
            if let colNum = dictColNums["AMOU"] {
                let amount = Double(columns[colNum].trim) ?? 0
                if amount < 0 {
                    lineItem.credit = -amount
                } else {
                    lineItem.debit = amount
                }
            }
//            print("Description is \(lineItem.desc)\n")
//        if lineItem.desc.uppercased().contains("STOP & SHOP")
//            {
//                print("Key Word SHELL found in \(lineItem.desc.uppercased())")
//            }
            lineItem.cardType = cardType
            lineItem.genCat = ""                          // Initialze the Generated Category
            var key = lineItem.desc.uppercased()
            //            key = key.replacingOccurrences(of: "\"", with: "")    // Remove Single Quotes from Key
            //            key = key.replacingOccurrences(of:  " ", with: "")    // Compress key
            //            key = key.replacing Occurrences(of:  ";", with: "")    // Remove semi-colons from Key
            key = key.replacingOccurrences(of: "["+suppressionList+"]", with: "", options: .regularExpression, range: nil)
            key = String(key.prefix(descLength))    // Truncate
            if !key.isEmpty {
                if let catItem = dictCategory[key] {      // Here if Lookup of KEY was successfull
                    lineItem.genCat = catItem.category
                    lineItem.catSource = catItem.source
                    succesfullLookupCount += 1
                    uniqueCategoryCounts[key, default: 0] += 1
                } else {    //Here if Lookup in Category Dictionary NOT Successfull
                    let source = cardType
                        print("          Did Not Find ",key)
                        let catItem = CategoryItem(category: lineItem.rawCat, source: source)
                        let rawCat = catItem.category
                        if rawCat.count >= 3 {
                            dictCategory[key] = catItem //Do Actual Insert
                            addedCatCount += 1
                            print("Category that was inserted = Key==> \(key) Value ==> \(lineItem.rawCat) Source ==> \(source)")
                            
                        } else {
                            handleError(codeFile: "ViewController", codeLineNum: #line, fileName: fileName, dataLineNum: lineNum, lineText: tran, errorMsg: "Category too short to be legit.")
                        }
               }
                lineItemArray.append(lineItem)          // Add new output Record to be output
            }
        }// End of FOR loop
        return lineItemArray
    }//end func handleCards

    
    // Called by NotificationCenter Observer getting post from handleError. Sets lblErrMsg
    @objc func errorPostedFromNotification(_ notification: Notification) {
        guard let msg = notification.userInfo?["ErrMsg"] as? String else { return }
        lblErrMsg.stringValue = msg
        print ("ErrMsg: \"\(msg)\" received from ErrorHandler via NotificationCenter")
    }

}//end class ViewController
