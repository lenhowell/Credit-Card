//
//  ViewController.swift
//  Credit Cards
//
//  Created by Lenard Howell on 7/28/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    //MARK:- Instance Variables
    
    var dictCatagory = [String: String]() //String: is the Key 2nd String is the value
    var myCrdType = ""
    var myFileName = ""
    let descLength = 8
    var countWithCat = 0
    
    //MARK:- Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        loadCatagories() // Build Catagories Dictionary
        txtCrdType.stringValue = "C1V"
        txtDteRng.stringValue  = "1905"
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
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
        //        let mytxtDteRng = txtDteRng.stringValue     // Input Data Year & Data Month
        //        let strMM = mytxtDteRng.suffix(2)           // Data Month
        //        let strYY = mytxtDteRng.prefix(2)           // Data Year
        //
        //        let numMM = Int(strMM) ?? 0                 // Numeric Equivalent of Month
        //        let numYY = Int(strYY) ?? 0                 // Numeric Equivqalent of Year
        //
        //        // Verify that 4 characters were entered
        //        if mytxtDteRng.count != 4 {
        //            badDate()
        //            return
        //        }
        //        // Verify that year is between 1 and 46(Ha! Ha!)
        //        if numYY < 1 || numYY > 46 {
        //            badDate()
        //            return
        //        }
        //
        //        // Verify tht Month is between 1 and 12)
        //        if numMM < 1 || numMM > 12 {
        //            badDate()
        //            return
        //        }
        
        //  Check If "Downloads" Directory Exists
        
        guard let downloadsPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            // Here if Path to Input File is NOT valid, Put Out Error Message and Exit Program
            lblErrMsg.stringValue = "Directory Path to Target File Does Not Exist!!!!"
            return
        }
        
        // We are here if Path is Valid
        let dir = downloadsPath.appendingPathComponent("Credit Card Trans") // Append Subdirectory To Path
        
        
        
        let fileURLs = getContentsOf(dirURL: dir)
        
        for fileURL in fileURLs {
            
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
            
            myCrdType = txtCrdType.stringValue.uppercased()         // Uppercase Card Type
            myFileName =  ""//""
            // Check which Credit Card Transactions we are currently processing
            switch myCrdType {
            case "C1V":
                lineItemArray += hndleC1v(crdArray: cardArray)
                fileCount += 1
            case "C1R":
                hndleC1r(crdArray: cardArray)
                fileCount += 1
            case "DIS":
                hndleDis(crdArray: cardArray)
                fileCount += 1
            case "CIT":
                hndleCit(crdArray: cardArray)
                fileCount += 1
            default:
                junkFileCount += 1
            }
        }//loop
        
        outputTranactions(lineItemArray: lineItemArray)
        
        lblResults.stringValue = "\(lineItemArray.count) transactions.\n \(countWithCat) given a catagory."
        

    }// End of func Main
    
    
    //MARK:- Support Functions
    
    // This Function Handles Transactions to Capital One Venture Credit Card
    
    func hndleC1v(crdArray: [String]) -> [LineItem]
    {
        let transactions = crdArray.dropFirst()         // Drop "first" Line from Input Stream(Headers)
        var lineItemArray = [LineItem]()                // Create Array variable(lineItemArray) Type lineItem.
        
        for tran in transactions{
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
            
            let columns = transaction.components(separatedBy: ",")  // Isolate columns within this transaction
            var lineitem = LineItem()
            // Building the Output record
            lineitem.tranDate = columns[0]
            lineitem.postDate = columns[1]
            lineitem.cardNum  = columns[2]
            lineitem.desc     = columns[3]
            lineitem.rawCat   = columns[4]
            lineitem.debit  = Double(columns[5]) ?? 0
            lineitem.credit = Double(columns[6]) ?? 0
            lineitem.cardType = "C1V"
            lineitem.genCat = ""                          // Initialze the Generated Category
            
            var key = String(lineitem.desc.uppercased().replacingOccurrences(of: " ", with: "").prefix(descLength)) // uppercase and compress Description
            key = key.replacingOccurrences(of: ";", with: "") // ffectively Removeing commas from Key
            if let value = dictCatagory[key] {            // Here if Lookup of KEY was successfull
                lineitem.genCat = value
                countWithCat += 1
            }
            lineItemArray.append(lineitem)          // Add new output Record to be output
            print(lineitem)
        }// End of FOR loop
        return lineItemArray
    }
    
    func hndleC1r(crdArray: [String]) {
    }
    
    func hndleDis(crdArray: [String]) {
    }
    
    func hndleCit(crdArray: [String]) {
    }
    
    func badDate() {
        lblErrMsg.stringValue = "Date must be in YYMM Format, \(txtDteRng.stringValue ) is Wrong!!"
    }
    func loadCatagories()
    {     // Check "Bundle" to see if "CatagoryLookup.txt" Entry exists.
        guard let catagories = Bundle.main.path(forResource: "CatagoryLookup", ofType: "txt") else {
            return              // Not in the "Bundle", EXIT Program
        }
        
        // Get data in "CatagoryLookup" if there is any. If NIL set to Empty.
        let contentof = (try? String(contentsOfFile: catagories)) ?? ""
        let lines = contentof.components(separatedBy: "\n") // Create var lines containing Entry for each line.
        
        // For each line in "CatagoryLookup"
        for line in lines
        {
            if line == ""{
                continue
            }
            // Create an Array of ech line components the seperator being a ","
            let catagoryArray = line.components(separatedBy: ",")
            
            // Create a var "description" containing the first "descLength" charcters of column 0 after having compressed out spaces. This will be the KEY into the CatagoryLookup Table/Dictionary.
            let description = String(catagoryArray[0].replacingOccurrences(of: " ", with: "").uppercased().prefix(descLength))
            let catagory = catagoryArray[1].trimmingCharacters(in: .whitespaces) //drop leading and trailing white space
            dictCatagory[description] = catagory
        }
        print(dictCatagory)
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
        
        var outPutStr = "Card Type\tTranDate\tDesc\tDebit\tCredit\tCatagory\tRaw Catagory\n"
        for xX in lineItemArray {
            let text = "\(xX.cardType)\t\(xX.tranDate)\t\(xX.desc)\t\(xX.debit)\t\(xX.credit)\t\(xX.genCat)\t\(xX.rawCat)\n"
            outPutStr += text
        }
        
        // Verify that the PATh to "Desktop" and the
        if let desktopPathUrl = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            let myFileNameOut =  String(myFileName.dropLast(4)+"-Out.csv")  // Drop ".csv" and Append "-Out.csv"
            let fileUrl = desktopPathUrl.appendingPathComponent(myFileNameOut)
            
            // Copy Entire Output File To Clipboard. This will be used to INSERT INTO EXCEL
            copyStringToClipBoard(textToCopy: outPutStr)
            
            // Write to Output File
            do    {
                try outPutStr.write(to: fileUrl, atomically: false, encoding: .utf8)
            } catch {
                lblErrMsg.stringValue = "Write Failed!!!! \(fileUrl.path)"
            }
            
            print()
        } else {
            lblErrMsg.stringValue = "Directory Path or Output File Does Not Exist!!!!"
        }

    }
}//end class



