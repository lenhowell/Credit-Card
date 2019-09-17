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
var gUserInitials           = "GWB"     // (UserInputVC.swift-2) Initials used for "Category Source" when Cat is changes by user.
var gTransFilename          = ""                // (UserInputVC.swift-viewDidLoad) Current Transaction Filename
var gMyCatNames             = [String]()            // (loadMyCats, UserInputVC.swift-viewDidLoad) Array of Category Names (MyCategories.txt)
var dictMyCatAliases        = [String: String]()        // (LineItems.init, etc) Hash of Category Synonyms
var dictVendorCatLookup     = [String: CategoryItem]()  // (HandleCards.swift-3) Hash for Category Lookup (CategoryLookup.txt)
var dictTranDupes           = [LineItem: String]()      // (handleCards) Hash for finding duplicate transactions
var dictModifiedTrans       = [String: CategoryItem]()  // (MyModifiedTransactions.txt) Hash for user-modified transactions
var uniqueCategoryCounts    = [String: Int]()           // Hash for Unique Category Counts
var gIsUnitTesting   = false
var gLearnMode       = true
var gUserInputMode   = true

//MARK:- ViewController
class ViewController: NSViewController, NSWindowDelegate {
    
    //MARK:- Instance Variables
    
    // Constants
    let myFileNameOut           = "Combined-Creditcard-Master.txt" // Only used in outputTranactions
    let VendorCatLookupFilename = "VendorCategoryLookup.txt"
    let vendorShortNameFilename = "VendorShortNames.txt"
    let myCatsFilename          = "MyCategories.txt"
    let myModifiedTranFilename  = "MyModifiedTransactions.txt"

    // Variables
    var dictVendorShortNames    = [String: String]()        // Hash for VendorShortNames Lookup (VendorShortNames.txt)
    var transFileURLs           = [URL]()
    var pathTransactionDir      = "Downloads/Credit Card Trans"
    var pathSupportDir          = "Desktop/Credit Card Files"
    var pathOutputDir           = "Desktop/Credit Card Files"

    var transactionDirURL       = FileManager.default.homeDirectoryForCurrentUser
    var VendorCatLookupFileURL  = FileManager.default.homeDirectoryForCurrentUser
    var vendorShortNamesFileURL = FileManager.default.homeDirectoryForCurrentUser
    var myCatsFileURL           = FileManager.default.homeDirectoryForCurrentUser
    var myModifiedTransURL      = FileManager.default.homeDirectoryForCurrentUser
    var outputFileURL           = FileManager.default.homeDirectoryForCurrentUser

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

        //TODO: Allow User to change his initials.
        gUserInitials = UserDefaults.standard.string(forKey: UDKey.userInitials) ?? ""
        if gUserInitials.isEmpty {
            let homeURL = FileManager.default.homeDirectoryForCurrentUser
            gUserInitials = homeURL.lastPathComponent.prefix(3).uppercased()
        }

        gLearnMode = UserDefaults.standard.bool(forKey: UDKey.learningMode)
        gUserInputMode = UserDefaults.standard.bool(forKey: UDKey.userInputMode)

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

        // Read Support files ("CategoryLookup.txt", "VendorShortNames.txt", "MyCategories.txt")
        txtOutputFolder.stringValue     = pathOutputDir
        txtSupportFolder.stringValue    = pathSupportDir
        txtTransationFolder.stringValue = pathTransactionDir
        let errMsg = verifyFolders()
        if !errMsg.isEmpty { handleError(codeFile: "ViewController", codeLineNum: #line, type: .dataWarning, action: .display, fileName: "", dataLineNum: 0, lineText: "", errorMsg: errMsg) }
        readSupportFiles()

        let shortCatFilePath = removeUserFromPath(VendorCatLookupFileURL.path)
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

    @IBAction func btnFindTruncatedDescs(_ sender: Any) {
        findTruncatedDescs()
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
        dictVendorCatLookup = loadVendorCategories(url: VendorCatLookupFileURL) // Re-read Categories Dictionary
        Stats.origCatCount = dictVendorCatLookup.count

        var fileContents    = ""                        // Where All Transactions in a File go
        var lineItemArray   = [LineItem]()
        dictTranDupes = [:]
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
                lineItemArray += handleCards(fileName: fileName, cardType: cardType, cardArray: cardArray, dictVendorShortNames: dictVendorShortNames)
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
            if gLearnMode {
                writeCategoriesToFile(url: VendorCatLookupFileURL, dictCat: dictVendorCatLookup)
            }
        }
        writeModTransTofile(url: myModifiedTransURL, dictModTrans: dictModifiedTrans)

        var statString = ""

        let shortCatFilePath = removeUserFromPath(VendorCatLookupFileURL.path)
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
        (VendorCatLookupFileURL, errTxt)  = makeFileURL(pathFileDir: pathSupportDir, fileName: VendorCatLookupFilename)
        if !errTxt.isEmpty {
            handleError(codeFile: "ViewController", codeLineNum: #line, type: .dataError, action: .display, errorMsg: "Category" + errTxt)
        }
        dictVendorCatLookup = loadVendorCategories(url: VendorCatLookupFileURL)       // Build Categories Dictionary
        Stats.origCatCount = dictVendorCatLookup.count

        // "VendorShortNames.txt"
        (vendorShortNamesFileURL, errTxt)  = makeFileURL(pathFileDir: pathSupportDir, fileName: vendorShortNameFilename)
        if !errTxt.isEmpty {
            handleError(codeFile: "ViewController", codeLineNum: #line, type: .dataError, action: .display, errorMsg: "VendorShortNames " + errTxt)
        }
        dictVendorShortNames = vendorShortNames(url: vendorShortNamesFileURL)        // Build VendorShortNames Dictionary

        // "MyCategories.txt"
        (myCatsFileURL, errTxt)  = makeFileURL(pathFileDir: pathSupportDir, fileName: myCatsFilename)
        if !errTxt.isEmpty {
            handleError(codeFile: "ViewController", codeLineNum: #line, type: .dataError, action: .display, errorMsg: "MyCategories " + errTxt)
        }
        dictMyCatAliases = loadMyCats(myCatsFileURL: myCatsFileURL)

        // "MyModifiedTransactions"
        (myModifiedTransURL, errTxt)  = makeFileURL(pathFileDir: pathSupportDir, fileName: myModifiedTranFilename)
        if !errTxt.isEmpty {
            handleError(codeFile: "ViewController", codeLineNum: #line, type: .dataError, action: .display, errorMsg: "MyModifiedTransactions " + errTxt)
        }
        dictModifiedTrans = loadMyModifiedTrans(myModifiedTranURL: myModifiedTransURL)

    }//end func

    func findTruncatedDescs() {
        let VendorCatLookupSortedByLength = Array(dictVendorCatLookup.keys).sorted(by: {$0.count > $1.count})
        guard let maxLen = VendorCatLookupSortedByLength.first?.count else {
            return
        }
        for (idx, desc) in VendorCatLookupSortedByLength.enumerated() {
            let currentLen = desc.count
            if desc.uppercased().hasPrefix("SPRINT") {
                //
            }
            if currentLen < maxLen {
                for i in 0..<idx-1 {
                    let descLong = VendorCatLookupSortedByLength[i]

                    if descLong.prefix(currentLen) == desc {
                        let truncLong = descLong.dropFirst(currentLen)
                        if currentLen > 9 || truncLong.hasPrefix(" ") {
                            print("Possible dupe \(desc) (\(currentLen)) is part of \(descLong) (\(descLong.count))")
                            //
                        } else {
                            print("Too short for a dupe \(desc) (\(currentLen)) is part of \(descLong) (\(descLong.count))")
                        }
                    } else  if desc.prefix(6) == descLong.prefix(6) {
                        print("Not a dupe, but same at 9 \(desc) (\(currentLen)) is part of \(descLong) (\(descLong.count))")
                        //
                    }
                }//next i
            }//endif
        }//next desc


    }

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
