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

// Global Variables
var gUserInitials           = "GWB"                 // Initials used for "Category Source" when Cat is changes by user.
var gTransFilename          = ""                    // Current Transaction Filename
var gMyCatNames             = [String]()            // Array of Category Names
var dictMyCatAliases        = [String: String]()        // Hash of Category Synonyms
var dictCatLookupByVendor   = [String: CategoryItem]()  // Hash for Category Lookup
var dictDescKeyWords        = [String: DescKeyWord]()   // Hash for Description KeyWord Lookup
var dictTransactions        = [LineItem: String]()      // Hash for finding duplicate transactions
var dictModifiedTrans       = [String: CategoryItem]()  // Hash for user-modified transactions
var uniqueCategoryCounts    = [String: Int]()           // Hash for Unique Category Counts
var gIsUnitTesting   = false
var gLearnMode       = true
var gUserInputMode   = true

//MARK:- ViewController
class ViewController: NSViewController, NSWindowDelegate {
    
    //MARK:- Instance Variables
    
    // Constants
    let myFileNameOut           = "Combined-Creditcard-Master.txt" // Only used in outputTranactions
    let catLookupFilename       = "CategoryLookup.txt"
    let descKeyWordFilename     = "DescriptionKeyWords.txt"
    let myCatsFilename          = "MyCategories.txt"
    let myModifiedTranFilename  = "MyModifiedTransactions.txt"

    // Variables
    var transFileURLs       = [URL]()
    var pathTransactionDir  = "Downloads/Credit Card Trans"
    var pathSupportDir      = "Desktop/Credit Card Files"
    var pathOutputDir       = "Desktop/Credit Card Files"

    var transactionDirURL   = FileManager.default.homeDirectoryForCurrentUser
    var catLookupFileURL    = FileManager.default.homeDirectoryForCurrentUser
    var descKeyWordFileURL  = FileManager.default.homeDirectoryForCurrentUser
    var myCatsFileURL       = FileManager.default.homeDirectoryForCurrentUser
    var myModifiedTransURL  = FileManager.default.homeDirectoryForCurrentUser
    var outputFileURL       = FileManager.default.homeDirectoryForCurrentUser

    //MARK:- Overrides & Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Create NotificationCenter Observer to listen for post from handleError
        NotificationCenter.default.addObserver( self,
                                                selector: #selector(self.errorPostedFromNotification(_:)),
                                                name:     NSNotification.Name(notificationName.errPosted),
                                                object:   nil
        )

        // Get folder UserDefaults
        if let dir = UserDefaults.standard.string(forKey: UDKey.supportFolder) {
            if !dir.isEmpty { pathSupportDir = dir }
        }
        pathOutputDir       = UserDefaults.standard.string(forKey: UDKey.outputFolder) ?? pathOutputDir
        pathTransactionDir  = UserDefaults.standard.string(forKey: UDKey.transactionFolder) ?? pathTransactionDir

        //TODO: Allow User to chang his initials.
        gUserInitials = UserDefaults.standard.string(forKey: UDKey.userInitials) ?? ""
        if gUserInitials.isEmpty {
            let homeURL = FileManager.default.homeDirectoryForCurrentUser
            gUserInitials = homeURL.lastPathComponent.prefix(3).uppercased()
        }

        if !gIsUnitTesting {
            gLearnMode = UserDefaults.standard.bool(forKey: UDKey.learningMode)
            gUserInputMode = UserDefaults.standard.bool(forKey: UDKey.userInputMode)
        }

        // Get List of Transaction Files
        var errTxt = ""
        (transactionDirURL, errTxt)  = makeFileURL(pathFileDir: pathTransactionDir, fileName: "")
        if errTxt.isEmpty {
            transFileURLs = getTransFileList(transDirURL: transactionDirURL)
            cboFiles.isHidden = false
            loadComboBoxFiles(fileURLs: transFileURLs)
            lblTranFileCount.stringValue = "\(transFileURLs.count) Transaction \("file".pluralize(transFileURLs.count))"
            lblErrMsg.stringValue = ""
        } else {
            transFileURLs = []
            cboFiles.isHidden = true
            loadComboBoxFiles(fileURLs: transFileURLs)
            lblTranFileCount.stringValue = "---"
            lblErrMsg.stringValue = "Transaction" + errTxt
        }

        // Read Support files ("CategoryLookup.txt", "DescriptionKeyWords.txt", "MyCategories.txt")
        txtOutputFolder.stringValue     = pathOutputDir
        txtSupportFolder.stringValue    = pathSupportDir
        txtTransationFolder.stringValue = pathTransactionDir
        let errMsg = verifyFolders()
        if !errMsg.isEmpty { handleError(codeFile: "ViewController", codeLineNum: #line, type: .dataWarning, action: .display, fileName: "", dataLineNum: 0, lineText: "", errorMsg: errMsg) }
        readSupportFiles()

        let shortCatFilePath = removeUserFromPath(catLookupFileURL.path)
        lblResults.stringValue = "Category Lookup File \"\(shortCatFilePath)\" loaded with \(Stats.origCatCount) items.\n"

        chkLearningMode.state = gLearnMode     ? .on : .off
        chkUserInput.state    = gUserInputMode ? .on : .off

        // Set txtTransationFolder.delegate
        txtTransationFolder.delegate = self         // Allow ViewController to see when txtTransationFolder changes.
    }
    
    override func viewDidAppear() {
        self.view.window?.delegate = self
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

    //MARK:- Notification Center functions

    // Called by NotificationCenter Observer getting post from handleError. Sets lblErrMsg
    @objc func errorPostedFromNotification(_ notification: Notification) {
        guard let msg = notification.userInfo?[notificationKey.errMsg] as? String else { return }
        lblErrMsg.stringValue = msg
        //print ("ErrMsg: \"\(msg)\" received from ErrorHandler via NotificationCenter")
    }

    //MARK:- @IBOutlets
    
    @IBOutlet weak var lblErrMsg:   NSTextField!
    @IBOutlet weak var lblResults:  NSTextField!
    @IBOutlet weak var lblRunTime:  NSTextField!
    @IBOutlet var lblTranFileCount: NSTextField!
    @IBOutlet var txtTransationFolder: NSTextField!
    @IBOutlet var txtSupportFolder:    NSTextField!
    @IBOutlet var txtOutputFolder:     NSTextField!
    @IBOutlet weak var btnStart: NSButton!
    @IBOutlet var cboFiles: NSComboBox!
    @IBOutlet var chkLearningMode: NSButton!
    @IBOutlet var chkUserInput: NSButton!

    //MARK:- @IBActions

    @IBAction func btnStartClick(_ sender: Any) {
        main()
    }

    @IBAction func chkLearningModeClick(_ sender: Any) {
        gLearnMode = chkLearningMode.state == .on
        print("learnMode = \(gLearnMode)")
    }
    @IBAction func chkUserInputClick(_ sender: Any) {
        gUserInputMode = chkUserInput.state == .on
        print("UserInputMode = \(gUserInputMode)")
    }
    
    //MARK:- Main Program
    
    func main() {
        let errMsg = verifyFolders()
        if !errMsg.isEmpty {
            handleError(codeFile: "ViewController", codeLineNum: #line, type: .dataWarning, action: .alertAndDisplay, fileName: "", dataLineNum: 0, lineText: "", errorMsg: errMsg)
            return
        }

        lblRunTime.stringValue = ""
        let startTime = CFAbsoluteTimeGetCurrent()

        var errTxt = ""

        pathTransactionDir = txtTransationFolder.stringValue
        (transactionDirURL, errTxt)  = makeFileURL(pathFileDir: pathTransactionDir, fileName: "")
        if !errTxt.isEmpty {
            handleError(codeFile: "ViewController", codeLineNum: #line, type: .dataError, action: .alertAndDisplay, errorMsg: "Transaction" + errTxt)
            return
        }


        (outputFileURL, errTxt)  = makeFileURL(pathFileDir: pathOutputDir, fileName: myFileNameOut)
        if !errTxt.isEmpty {
            handleError(codeFile: "ViewController", codeLineNum: #line, type: .dataError, action: .alertAndDisplay, errorMsg: "Output" + errTxt)
            return
        }

        pathOutputDir  = txtOutputFolder.stringValue
        pathSupportDir = txtSupportFolder.stringValue

        readSupportFiles()

        // Save UserDefaults
        UserDefaults.standard.set(pathTransactionDir, forKey: UDKey.transactionFolder)
        UserDefaults.standard.set(pathSupportDir,     forKey: UDKey.supportFolder)
        UserDefaults.standard.set(pathOutputDir,      forKey: UDKey.outputFolder)
        UserDefaults.standard.set(gUserInitials,      forKey: UDKey.userInitials)
        UserDefaults.standard.set(gUserInputMode,     forKey: UDKey.userInputMode)
        UserDefaults.standard.set(gLearnMode,         forKey: UDKey.learningMode)

        Stats.clearAll()
        dictCatLookupByVendor = loadCategories(url: catLookupFileURL) // Re-read Categories Dictionary
        Stats.origCatCount = dictCatLookupByVendor.count

        var fileContents    = ""                        // Where All Transactions in a File go
        var lineItemArray   = [LineItem]()
        dictTransactions = [:]
        lblErrMsg.stringValue = ""
        
        if !FileManager.default.fileExists(atPath: transactionDirURL.path) {
            handleError(codeFile: "ViewController", codeLineNum: #line, type: .codeError, action: .alertAndDisplay,  fileName: transactionDirURL.path, dataLineNum: 0, lineText: "", errorMsg: "Directory does not exist")
        }

        let filesToProcessURLs: [URL]
        let shown = cboFiles.stringValue.trim
        if shown == "-all-" {
            filesToProcessURLs = transFileURLs
        } else {
            let nameWithExt = shown + ".csv"
            let fileURL = transactionDirURL.appendingPathComponent(nameWithExt)
            filesToProcessURLs = [fileURL]
        }

        for fileURL in filesToProcessURLs {
            let fileName    = fileURL.lastPathComponent
            gTransFilename  = fileURL.lastPathComponent
            let nameComps   = fileName.components(separatedBy: "-")
            let cardType    = nameComps[0].uppercased()
            let fileAttributes = FileAttributes.getFileInfo(url: fileURL)
            if fileAttributes.isDir { continue }

            // FileExists/isReadable is checked in the "do/catch" block
            do {
                //— reading —    // macOSRoman is more forgiving than utf8
                fileContents = try String(contentsOf: fileURL, encoding: .macOSRoman)
                // File Exists if we are here and Entire file is now in "fileContents" variable
            } catch {
                // Here if file does NOT exist or is unreadable. Put out an Error Message and Continue
                lblErrMsg.stringValue = "File Does NOT Exist, \(fileURL.path)!!!!"
                continue    // try the next file
            }
            
            let cardArray = fileContents.components(separatedBy: "\n")
            
            // Check which Credit Card Transactions we are currently processing
            switch cardType {
            case "C1V", "C1R", "DIS", "CIT", "BACT", "BAPR", "ML":
                lineItemArray += handleCards(fileName: fileName, cardType: cardType, cardArray: cardArray)
                chkUserInput.state = gUserInputMode ? .on : .off
                Stats.transFileCount += 1
            default:
                Stats.junkFileCount += 1
            }
        }//next fileURL

        outputTranactions(outputFileURL: outputFileURL, lineItemArray: lineItemArray)

        print("\n--- Description-Key algorithms ---")
        for (key, val) in dictDescKeyAlgorithm.sorted(by: <) {
            print("\(key.PadRight(40))\(val)")
        }

        let uniqueCategoryCountsSorted = uniqueCategoryCounts.sorted(by: <)
        print("\n\(uniqueCategoryCounts.count) uniqueCategoryCountsSorted by description (vendor)")
        print (uniqueCategoryCountsSorted)
        print("\n\(uniqueCategoryCounts.count) uniqueCategoryCounts.sorted by count")
        print (uniqueCategoryCounts.sorted {$0.value > $1.value})
        if Stats.addedCatCount > 0 || Stats.changedCatCount > 0 {
            writeCategoriesToFile(url: catLookupFileURL, dictCat: dictCatLookupByVendor)
        }
        writeModTransTofile(url: myModifiedTransURL, dictModTrans: dictModifiedTrans)

        var statString = ""

        let shortCatFilePath = removeUserFromPath(catLookupFileURL.path)
        statString += "Category File \"\(shortCatFilePath)\" loaded with \(Stats.origCatCount) items.\n"

        if filesToProcessURLs.count == 1 {
            let shortTransFilePath = removeUserFromPath(filesToProcessURLs[0].path)
            statString += "\(Stats.transFileCount) File named \"\(shortTransFilePath)/\" Processed."
        } else {
            let shortTransFilePath = removeUserFromPath(transactionDirURL.path)
            statString += "\(Stats.transFileCount) Files from \"\(shortTransFilePath)/\" Processed."
        }

        if Stats.junkFileCount > 0 {
            statString += "\n\(Stats.junkFileCount) NOT Recognized as a Credit Card Transaction"
        }
        statString += "\n \(lineItemArray.count) CREDIT CARD Transactions PROCESSED."
        statString += "\n Of These:"
        statString += "\n(a)\(String(Stats.successfulLookupCount).rightJust(5)) were found in Category File.      ←"
        statString += "\n(b)\(String(Stats.addedCatCount).rightJust(5)        ) were inserted into Category File. ←"
        statString += "\n(b)\(String(Stats.changedCatCount).rightJust(5)      ) were changed in Category File.    ←"
        statString += "\n(c)\(String(Stats.descWithNoCat).rightJust(5)        ) still with no Category assigned.  ←"
        lblResults.stringValue = statString
        
        let endTime   = CFAbsoluteTimeGetCurrent()
        let runtime = endTime - startTime
        print(String(format: "Runtime %5.02f sec", runtime))
        lblRunTime.stringValue = String(format: "Runtime %5.02f sec", runtime)
        print()

    }// End of func main

    //MARK: Support funcs

    //------ loadComboBoxFiles - Read Trk filenames and load ComboBoxFiles with Recent, Not-done, & Outdated files
    private func loadComboBoxFiles(fileURLs: [URL]) {          // 555-637 = 82 lines
        let fileNames = fileURLs.map { $0.deletingPathExtension().lastPathComponent }
        cboFiles.removeAllItems()
        cboFiles.stringValue = "-all-"
        cboFiles.addItem(withObjectValue: "-all-")
        cboFiles.addItems(withObjectValues: fileNames)

        print("ViewController#\(#line): 🤣cboFiles has \(cboFiles.numberOfItems) items.")
    }//end func loadComboBoxFiles


    // Reads Support & Output folder names from textViews, & verifies they exist
    func verifyFolders() -> String {
        if !folderExists(atPath: txtSupportFolder.stringValue, isPartialPath: true) {
            return "Support folder: \"\(txtSupportFolder.stringValue)\" doesn't exist."
        }
        pathSupportDir = txtSupportFolder.stringValue

        if !folderExists(atPath: txtOutputFolder.stringValue, isPartialPath: true) {
            return "Output folder: \"\(txtOutputFolder.stringValue)\" doesn't exist."
        }
        pathOutputDir  = txtOutputFolder.stringValue

        return ""
    }

    func readSupportFiles() {
        var errTxt = ""

        // "CategoryLookup.txt"
        (catLookupFileURL, errTxt)  = makeFileURL(pathFileDir: pathSupportDir, fileName: catLookupFilename)
        if !errTxt.isEmpty {
            handleError(codeFile: "ViewController", codeLineNum: #line, type: .dataError, action: .display, errorMsg: "Category" + errTxt)
        }
        dictCatLookupByVendor = loadCategories(url: catLookupFileURL)       // Build Categories Dictionary
        Stats.origCatCount = dictCatLookupByVendor.count

        // "DescriptionKeyWords.txt"
        (descKeyWordFileURL, errTxt)  = makeFileURL(pathFileDir: pathSupportDir, fileName: descKeyWordFilename)
        if !errTxt.isEmpty {
            handleError(codeFile: "ViewController", codeLineNum: #line, type: .dataError, action: .display, errorMsg: "descKeyWord" + errTxt)
        }
        dictDescKeyWords = loadDescKeyWords(url: descKeyWordFileURL)        // Build Desc-KeyWord Dictionary

        // "MyCategories.txt"
        (myCatsFileURL, errTxt)  = makeFileURL(pathFileDir: pathSupportDir, fileName: myCatsFilename)
        if !errTxt.isEmpty {
            handleError(codeFile: "ViewController", codeLineNum: #line, type: .dataError, action: .display, errorMsg: "MyCategories" + errTxt)
        }
        dictMyCatAliases = loadMyCats(myCatsFileURL: myCatsFileURL)

        // "MyModifiedTransactions"
        (myModifiedTransURL, errTxt)  = makeFileURL(pathFileDir: pathSupportDir, fileName: myModifiedTranFilename)
        if !errTxt.isEmpty {
            handleError(codeFile: "ViewController", codeLineNum: #line, type: .dataError, action: .display, errorMsg: "MyModifiedTransactions" + errTxt)
        }
        dictModifiedTrans = loadMyModifiedTrans(myModifiedTranURL: myModifiedTransURL)

    }//end func

}//end class ViewController

// Allow ViewController to see when a TextField changes.
extension ViewController: NSTextFieldDelegate {

    //---- controlTextDidChange - Called when a textField (with ViewController as its delegate) changes.
    func controlTextDidChange(_ obj: Notification) {
        guard let textView = obj.object as? NSTextField else {
            return
        }
        var errText = ""
        pathTransactionDir = txtTransationFolder.stringValue
        (transactionDirURL, errText) = makeFileURL(pathFileDir: pathTransactionDir, fileName: "")
        if errText.isEmpty {
            btnStart.isEnabled = true
            transFileURLs = getTransFileList(transDirURL: transactionDirURL)
            loadComboBoxFiles(fileURLs: transFileURLs)
            cboFiles.isHidden = false
            lblTranFileCount.stringValue = "\(transFileURLs.count) Transaction \("file".pluralize(transFileURLs.count))"
            lblErrMsg.stringValue = ""
            print("Trans Folder changed to: \"\(textView.stringValue)\"")

        } else {
            btnStart.isEnabled = false
            transFileURLs = []
            loadComboBoxFiles(fileURLs: transFileURLs)
            cboFiles.isHidden = true
            lblTranFileCount.stringValue = "----"
            lblErrMsg.stringValue = errText
        }
    }

}//end extension ViewController: NSTextFieldDelegate
