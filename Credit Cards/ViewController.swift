//
//  ViewController.swift
//  Credit Cards
//
//  Created by 💪 Lenard Howell on 7/28/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

// TODO: Check for overlaps & gaps in card transaction file list.

import Cocoa

//MARK:- Global Variables

// Global Constants
let descKeysuppressionList = "& \";'`.#*-"      //Const used in: loadCategories, handleCards
let descKeyLength          = 8                  //Const used in: loadCategories, handleCards

// Global Variables
var dictCategory            = [String: CategoryItem]()  // Hash For Category Lookup
var uniqueCategoryCounts    = [String: Int]()           // Hash For Unique Category Counts

//MARK:- ViewController
class ViewController: NSViewController, NSWindowDelegate {
    
    //MARK:- Instance Variables
    
    // Constants
    let myFileNameOut    = "Combined-Creditcard-Master.csv" // Only used in outputTranactions
    let catagoryFilename = "CategoryLookup.txt"

    // Variables
    var containsDictionary      = [String: String]()        // String: is the Key - Generated Category
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
        Stats.clearAll()
        var fileContents    = ""                        // Where All Transactions in a File go
        var lineItemArray   = [LineItem]()
        lblErrMsg.stringValue = ""
        
        guard let downloadsPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            // Here if Path to Input File is NOT valid, Put Out Error Message and Exit Program
            lblErrMsg.stringValue = "Directory Path to Target File Does Not Exist!!!!"
            return
        }

        // We are here if Path is Valid
        let dir = downloadsPath.appendingPathComponent("Credit Card Trans") // Append FileName To Path
        if !FileManager.default.fileExists(atPath: dir.path) {
            handleError(codeFile: "ViewController", codeLineNum: #line, type: .codeError, action: .alertAndDisplay,  fileName: dir.path, dataLineNum: 0, lineText: "", errorMsg: "Directory does not exist")
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
                Stats.transFileCount += 1
            default:
                Stats.junkFileCount += 1
            }
        }//next fileURL
        
        outputTranactions(workingFolderUrl: workingFolderUrl, fileName: myFileNameOut, lineItemArray: lineItemArray)
        let uniqueCategoryCountsSorted = uniqueCategoryCounts.sorted(by: <)
        print("\nuniqueCategoryCountsSorted by key")
        print (uniqueCategoryCountsSorted)
        print("\nuniqueCategoryCounts.sorted by value")
        print (uniqueCategoryCounts.sorted {$0.value > $1.value})

        writeCategoriesToFile(workingFolderUrl: workingFolderUrl, fileName: catagoryFilename, dictCat: dictCategory)
        var statString = ""
        statString += "\(Stats.transFileCount) Files Processed."
        statString += "\n\(Stats.junkFileCount) NOT Recognized as a Credit Card Transaction"
        statString += "\n \(lineItemArray.count) CREDIT CARD Transactions PROCESSED."
        statString += "\n Of These:"
        statString += "\n(a) \(Stats.successfulLookupCount) were found in Category File."
        statString += "\n      (b) \(Stats.addedCatCount) were inserted into Category File."
        statString += "\n     (c) \(Stats.descWithNoCat) still have no Catagory assigned."
        lblResults.stringValue = statString
        
    }// End of func main
    
    
    //MARK:- Support Functions
    
    // Called by NotificationCenter Observer getting post from handleError. Sets lblErrMsg
    @objc func errorPostedFromNotification(_ notification: Notification) {
        guard let msg = notification.userInfo?["ErrMsg"] as? String else { return }
        lblErrMsg.stringValue = msg
        //print ("ErrMsg: \"\(msg)\" received from ErrorHandler via NotificationCenter")
    }

}//end class ViewController
