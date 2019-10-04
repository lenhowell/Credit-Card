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
var gUserInitials           = "User"    // (UserInputVC.swift-2) Initials used for "Category Source" when Cat is changes by user.
var gTransFilename          = ""                // (UserInputVC.swift-viewDidLoad) Current Transaction Filename
var gMyCatNames             = [String]()            // (loadMyCats, UserInputVC.swift-viewDidLoad) Array of Category Names (MyCategories.txt)
var dictMyCatAliases        = [String: String]()        // (LineItems.init, etc) Hash of Category Synonyms
var dictVendorCatLookup     = [String: CategoryItem]()  // (HandleCards.swift-3) Hash for Category Lookup (CategoryLookup.txt)
var dictTranDupes           = [String: String]()        // (handleCards) Hash for finding duplicate transactions
var dictModifiedTrans       = [String: CategoryItem]()  // (MyModifiedTransactions.txt) Hash for user-modified transactions
var uniqueCategoryCounts    = [String: Int]()           // Hash for Unique Category Counts
var gMyCategoryContent      = ""
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
    let codeFile    = "ViewController"

    // Variables
    var dictVendorShortNames    = [String: String]()        // (VendorShortNames.txt) Hash for VendorShortNames Lookup
    var transFileURLs           = [URL]()
    var pathTransactionDir      = "Downloads/Credit Card Trans"
    var pathSupportDir          = "Desktop/CreditCard/xxx"
    var pathOutputDir           = "Desktop/CreditCard"

    var transactionDirURL       = FileManager.default.homeDirectoryForCurrentUser
    var vendorCatLookupFileURL  = FileManager.default.homeDirectoryForCurrentUser
    var vendorShortNamesFileURL = FileManager.default.homeDirectoryForCurrentUser
    var myCatsFileURL           = FileManager.default.homeDirectoryForCurrentUser
    var myModifiedTransURL      = FileManager.default.homeDirectoryForCurrentUser
    var outputFileURL           = FileManager.default.homeDirectoryForCurrentUser
    var gotItem: GotItem        = .empty

    struct GotItem: OptionSet {
        let rawValue: Int
        static let empty        = GotItem(rawValue: 0)
        static let dirSupport   = GotItem(rawValue: 1 << 0)
        static let dirOutput    = GotItem(rawValue: 1 << 1)
        static let dirTrans     = GotItem(rawValue: 1 << 2)

        static let fileTransactions     = GotItem(rawValue: 1 << 3)
        static let fileVendorShortNames = GotItem(rawValue: 1 << 4)
        static let fileMyCategories     = GotItem(rawValue: 1 << 5)
        static let fileMyModifiedTrans  = GotItem(rawValue: 1 << 6)
        // "VendorShortNames.txt" "MyCategories.txt" "MyModifiedTransactions"

        static let userInitials = GotItem(rawValue: 1 << 9)

        static let allDirs: GotItem = [.dirSupport, .dirOutput, .dirTrans]
        static let requiredElements: GotItem = [.allDirs, .fileTransactions, .fileMyCategories, .userInitials]
    }
    //MARK:- Overrides & Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Create NotificationCenter Observer to listen for post from handleError
        NotificationCenter.default.addObserver( self,
                                                selector: #selector(self.errorPostedFromNotification(_:)),
                                                name:     NSNotification.Name(NotificationName.errPosted),
                                                object:   nil
        )

        // Set txtTransationFolder.delegate
        txtTransationFolder.delegate = self         // Allow ViewController to see when txtTransationFolder changes.


        // Get UserDefaults
        if let dir = UserDefaults.standard.string(forKey: UDKey.supportFolder) {
            pathSupportDir = dir
            if !dir.isEmpty && folderExists(atPath: dir, isPartialPath: true) {
                gotItem = [gotItem, .dirSupport]
            }
        }
        if let dir = UserDefaults.standard.string(forKey: UDKey.outputFolder) {
            pathOutputDir = dir
            if !dir.isEmpty && folderExists(atPath: dir, isPartialPath: true) {
                gotItem = [gotItem, .dirOutput]
            }
        }
        if let dir = UserDefaults.standard.string(forKey: UDKey.transactionFolder) {
            pathTransactionDir = dir
            if !dir.isEmpty && folderExists(atPath: dir, isPartialPath: true) {
                gotItem = [gotItem, .dirTrans]
            }
        }

        gLearnMode          = UserDefaults.standard.bool(forKey: UDKey.learningMode)
        gUserInputMode      = UserDefaults.standard.bool(forKey: UDKey.userInputMode)

        gUserInitials       = UserDefaults.standard.string(forKey: UDKey.userInitials) ?? ""
        if !gUserInitials.isEmpty {
            gotItem = [gotItem, .userInitials]
        }

        // Get List of Transaction Files
        gotNewTranactionFolder()

        // Read Support files ("CategoryLookup.txt", "VendorShortNames.txt", "MyCategories.txt")
        txtOutputFolder.stringValue     = pathOutputDir
        txtSupportFolder.stringValue    = pathSupportDir
        txtTransationFolder.stringValue = pathTransactionDir
        verifyFolders()
        let errMsg = makeMissingItemsMsg(got: gotItem)
        if !errMsg.isEmpty { handleError(codeFile: codeFile, codeLineNum: #line, type: .dataWarning, action: .display, fileName: "", dataLineNum: 0, lineText: "", errorMsg: errMsg) }
        if gotItem.contains(GotItem.dirSupport) {
            readSupportFiles()
            let shortCatFilePath = removeUserFromPath(vendorCatLookupFileURL.path)
            lblResults.stringValue = "Category Lookup File \"\(shortCatFilePath)\" loaded with \(Stats.origVendrCatCount) items.\n"
        } else {
            lblResults.stringValue = "You will need to create a folder to hold support files before you can proceed."
        }

        chkLearningMode.state = gLearnMode     ? .on : .off
        chkUserInput.state    = gUserInputMode ? .on : .off

    }//end func viewDidLoad
    
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
        guard let msg = notification.userInfo?[NotificationKey.errMsg] as? String else { return }
        lblErrMsg.stringValue = msg
        //print ("ErrMsg: \"\(msg)\" received from ErrorHandler via NotificationCenter")
    }

    //MARK:- @IBOutlets
    
    @IBOutlet var txtTransationFolder: NSTextField!
    @IBOutlet var txtSupportFolder:    NSTextField!
    @IBOutlet var txtOutputFolder:     NSTextField!
    @IBOutlet weak var lblErrMsg:   NSTextField!
    @IBOutlet weak var lblResults:  NSTextField!
    @IBOutlet weak var lblRunTime:  NSTextField!
    @IBOutlet var lblTranFileCount: NSTextField!
    @IBOutlet weak var btnStart:    NSButton!
    @IBOutlet var chkLearningMode:  NSButton!
    @IBOutlet var chkUserInput:     NSButton!
    @IBOutlet var cboFiles:     NSComboBox!

    //MARK:- @IBActions

    @IBAction func btnStartClick(_ sender: Any) {
        main()
    }

    @IBAction func btnFindTruncatedDescs(_ sender: Any) {
        let vendorNameDescs = Array(dictVendorCatLookup.keys)
        let doWrite = findTruncatedDescs(vendorNameDescs: vendorNameDescs, dictShortNames: &dictVendorShortNames)
        if doWrite {
            writeVendorShortNames(url: vendorShortNamesFileURL, dictVendorShortNames: dictVendorShortNames)
        }
    }

    @IBAction func chkLearningModeClick(_ sender: Any) {
        gLearnMode = chkLearningMode.state == .on
        print("learnMode = \(gLearnMode)")
    }
    @IBAction func chkUserInputClick(_ sender: Any) {
        gUserInputMode = chkUserInput.state == .on
        print("UserInputMode = \(gUserInputMode)")
    }

    @IBAction func btnShowTable(_ sender: Any) {
        let storyBoard = NSStoryboard(name: "Spreadsheet", bundle: nil)
        let tableWindowController = storyBoard.instantiateController(withIdentifier: "SpreadsheetWindowController") as! NSWindowController
        if let tableWindow = tableWindowController.window {
            //let tableVC = tableWindow.contentViewController as! TableVC
            //gLineItemArray = lineItemArray
            let application = NSApplication.shared
            application.runModal(for: tableWindow)

            tableWindow.close()
        }//end if let
    }//end func


    // MARK:- IBActions - MenuBar

    @IBAction func mnuResetUserDefaults(_ sender: Any) {
        let response = GBox.alert("Are you sure you want to reset all User Defaults?", style: .yesNo)
        if response == .yes {
            resetUserDefaults()
        }
    }

    @IBAction func mnuChangeUserInitials(_ sender: Any) {
        var isValid = false
        let minChars = 2
        let maxChars = 8
        var prompt = "Enter your initials (\(minChars)-\(maxChars) letters)"
        repeat {
            let response = GBox.inputBox(prompt: prompt, defaultText: gUserInitials, maxChars: maxChars)
            let name = response.trim
            let len = name.count
            if name.isEmpty {
                let msg = "Your initials were not changed from \(gUserInitials)."
                handleError(codeFile: "", codeLineNum: #line, type: .note, action: .alertAndDisplay, errorMsg: msg)
                isValid = true
            }
            if len >= minChars && len <= maxChars && !name.contains(" ") {
                gUserInitials = name
                gotItem = gotItem.union(GotItem.userInitials)
                UserDefaults.standard.set(gUserInitials,      forKey: UDKey.userInitials)
                let msg = "Your initials have been changed to \(gUserInitials)."
                handleError(codeFile: "", codeLineNum: #line, type: .note, action: .alertAndDisplay, errorMsg: msg)
                isValid = true
            }
            prompt = "Only letters and digits allowed"
            if len < minChars { prompt = "Initials must have at least \(minChars) letters"  }
            if len > maxChars { prompt = "Initials must have no more than  \(maxChars) letters"  }
            prompt += ". Try again."
        } while !isValid
    }


    //MARK:- Main Program
    
    func main() {
        verifyFolders()
        if !gotItem.contains(GotItem.allDirs) {
            let errMsg = makeMissingItemsMsg(got: gotItem)
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataWarning, action: .alertAndDisplay, fileName: "", dataLineNum: 0, lineText: "", errorMsg: errMsg)
            return
        }

        lblRunTime.stringValue = ""
        let startTime = CFAbsoluteTimeGetCurrent()

        var errTxt = ""

        pathTransactionDir = txtTransationFolder.stringValue
        (transactionDirURL, errTxt)  = makeFileURL(pathFileDir: pathTransactionDir, fileName: "")
        if !errTxt.isEmpty {
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .alertAndDisplay, errorMsg: "Transaction" + errTxt)
            return
        }

        (outputFileURL, errTxt)  = makeFileURL(pathFileDir: pathOutputDir, fileName: myFileNameOut)
        if !errTxt.isEmpty {
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .alertAndDisplay, errorMsg: "Output" + errTxt)
            return
        }

        pathOutputDir  = txtOutputFolder.stringValue
        pathSupportDir = txtSupportFolder.stringValue

        readSupportFiles()
        verifyFolders()
        let errMsg = makeMissingItemsMsg(got: gotItem)
        if !gotItem.contains(GotItem.requiredElements) {
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataWarning, action: .alertAndDisplay, fileName: "", dataLineNum: 0, lineText: "", errorMsg: errMsg)
            return
        }

        // Save UserDefaults
        UserDefaults.standard.set(pathTransactionDir, forKey: UDKey.transactionFolder)
        UserDefaults.standard.set(pathSupportDir,     forKey: UDKey.supportFolder)
        UserDefaults.standard.set(pathOutputDir,      forKey: UDKey.outputFolder)
        UserDefaults.standard.set(gUserInitials,      forKey: UDKey.userInitials)
        UserDefaults.standard.set(gUserInputMode,     forKey: UDKey.userInputMode)
        UserDefaults.standard.set(gLearnMode,         forKey: UDKey.learningMode)

        Stats.clearAll()
        dictVendorCatLookup = loadVendorCategories(url: vendorCatLookupFileURL) // Re-read Categories Dictionary
        Stats.origVendrCatCount = dictVendorCatLookup.count

        var fileContents    = ""                        // Where All Transactions in a File go
        dictTranDupes = [:]
        lblErrMsg.stringValue = ""
        
        if !FileManager.default.fileExists(atPath: transactionDirURL.path) {
            handleError(codeFile: codeFile, codeLineNum: #line, type: .codeError, action: .alertAndDisplay,  fileName: transactionDirURL.path, dataLineNum: 0, lineText: "", errorMsg: "Directory does not exist")
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
            if cardType.count >= 2 &&  cardType.count <= 8  {
                gLineItemArray += handleCards(fileName: fileName, cardType: cardType, cardArray: cardArray, dictVendorShortNames: &dictVendorShortNames)
                chkUserInput.state = gUserInputMode ? .on : .off
                Stats.transFileCount += 1
            } else {
                Stats.junkFileCount += 1
            }
        }//next fileURL

        outputTranactions(outputFileURL: outputFileURL, lineItemArray: gLineItemArray)

        print("\n--- Description-Key algorithms ---")
        for (key, val) in dictDescKeyAlgorithm.sorted(by: <) {
            print("\(key.PadRight(40))\(val)")
        }

        let uniqueCategoryCountsSorted = uniqueCategoryCounts.sorted(by: <)
        print("\n\(uniqueCategoryCounts.count) uniqueCategoryCountsSorted by description (vendor)")
        print (uniqueCategoryCountsSorted)
        print("\n\(uniqueCategoryCounts.count) uniqueCategoryCounts.sorted by count")
        print (uniqueCategoryCounts.sorted {$0.value > $1.value})
        if Stats.addedCatCount > 0 || Stats.changedVendrCatCount > 0 {
            if gLearnMode {
                writeVendorCategoriesToFile(url: vendorCatLookupFileURL, dictCat: dictVendorCatLookup)
            }
        }
        writeModTransTofile(url: myModifiedTransURL, dictModTrans: dictModifiedTrans)

        var statString = ""

        let shortCatFilePath = removeUserFromPath(vendorCatLookupFileURL.path)
        statString += "Category File \"\(shortCatFilePath)\" loaded with \(Stats.origVendrCatCount) items.\n"

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
        statString += "\n \(gLineItemArray.count + Stats.duplicateCount) CREDIT CARD Transactions PROCESSED."
        statString += "\n Of These:"
        statString += "\n(a)\(String(Stats.duplicateCount).rightJust(5)       ) were duplicates.                  ←"
        statString += "\n(b)\(String(Stats.successfulLookupCount).rightJust(5)) were found in Category File.      ←"
        statString += "\n(c)\(String(Stats.addedCatCount).rightJust(5)        ) were inserted into Category File. ←"
        statString += "\n(d)\(String(Stats.changedVendrCatCount).rightJust(5)      ) were changed in Category File.    ←"
        statString += "\n(e)\(String(Stats.descWithNoCat).rightJust(5)        ) still with no Category assigned.  ←"
        lblResults.stringValue = statString
        
        let endTime   = CFAbsoluteTimeGetCurrent()
        let runtime = endTime - startTime
        print(String(format: "Runtime %5.02f sec", runtime))
        lblRunTime.stringValue = String(format: "Runtime %5.02f sec", runtime)
        print()

    }// End of func main

    //MARK: Support funcs

    private func makeMissingItemsMsg(got: GotItem ) -> String {
        if got.contains(GotItem.requiredElements) { return "" }
        var msg = "Missing Items:"
        if !got.contains(GotItem.userInitials)  { msg += " User Initials," }

        if !got.contains(GotItem.dirSupport)    {
            msg += " Support Folder,"
        } else if !got.contains(GotItem.fileMyCategories) {
            msg += " MyCategories File,"
        }

        if !got.contains(GotItem.dirTrans)      {
            msg += " Transaction Folder,"
        } else if !got.contains(GotItem.fileTransactions) {
            msg += " Transaction Files,"
        }

        if !got.contains(GotItem.dirOutput)     { msg += " Output Folder," }

        msg = String(msg.dropLast())
        return msg
    }
    
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
        let supportPath = txtSupportFolder.stringValue.trim
        if supportPath.isEmpty || !folderExists(atPath: supportPath, isPartialPath: true) {
            //return "Support folder: \"\(txtSupportFolder.stringValue)\" doesn't exist."
            gotItem = gotItem.subtracting(GotItem.dirSupport)
        } else {
            gotItem = gotItem.union(GotItem.dirSupport)
        }
        pathSupportDir = supportPath

        let outputPath = txtOutputFolder.stringValue.trim
        if outputPath.isEmpty || !folderExists(atPath: outputPath, isPartialPath: true) {
            //return "Output folder: \"\(txtOutputFolder.stringValue)\" doesn't exist."
            gotItem = gotItem.subtracting(GotItem.dirOutput)
            } else {
                gotItem = gotItem.union(GotItem.dirOutput)
            }
        pathOutputDir  = outputPath

        let transPath = txtTransationFolder.stringValue.trim
        if transPath.isEmpty || !folderExists(atPath: transPath, isPartialPath: true) {
            gotItem = gotItem.subtracting(GotItem.dirTrans)
        } else {
            gotItem = gotItem.union(GotItem.dirTrans)
        }
        pathTransactionDir = transPath
        return ""
    }

    func readSupportFiles() {
        var errTxt = ""

        // "CategoryLookup.txt"
        (vendorCatLookupFileURL, errTxt)  = makeFileURL(pathFileDir: pathSupportDir, fileName: VendorCatLookupFilename)
        if !errTxt.isEmpty {
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .display, errorMsg: "Category" + errTxt)
        }
        dictVendorCatLookup = loadVendorCategories(url: vendorCatLookupFileURL)       // Build Categories Dictionary
        Stats.origVendrCatCount = dictVendorCatLookup.count

        // "VendorShortNames.txt"
        (vendorShortNamesFileURL, errTxt)  = makeFileURL(pathFileDir: pathSupportDir, fileName: vendorShortNameFilename)
        if !errTxt.isEmpty {
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .display, errorMsg: "VendorShortNames " + errTxt)
        }
        dictVendorShortNames = loadVendorShortNames(url: vendorShortNamesFileURL)        // Build VendorShortNames Dictionary
        if dictVendorShortNames.count > 0 {
            gotItem = [gotItem, .fileVendorShortNames]
        }
        // "MyCategories.txt"
        (myCatsFileURL, errTxt)  = makeFileURL(pathFileDir: pathSupportDir, fileName: myCatsFilename)
        if !errTxt.isEmpty {
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .display, errorMsg: "MyCategories " + errTxt)
        }
        dictMyCatAliases = loadMyCats(myCatsFileURL: myCatsFileURL)
        if dictMyCatAliases.count > 0 {
            gotItem = [gotItem, .fileMyCategories]
        } else {
            let path = Bundle.main.path(forResource: "MyCategories", ofType: "txt")!
            let bundleCatsFileURL = URL(fileURLWithPath: path)
            dictMyCatAliases = loadMyCats(myCatsFileURL: bundleCatsFileURL)
            writeMyCats(url: myCatsFileURL)
            let msg = "A starter \"MyCategories.txt\" was placed in your support-files folder"
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataWarning, action: .display, errorMsg: msg)
        }


        // "MyModifiedTransactions"
        (myModifiedTransURL, errTxt)  = makeFileURL(pathFileDir: pathSupportDir, fileName: myModifiedTranFilename)
        if !errTxt.isEmpty {
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .display, errorMsg: "MyModifiedTransactions " + errTxt)
        }
        dictModifiedTrans = loadMyModifiedTrans(myModifiedTranURL: myModifiedTransURL)
        if dictModifiedTrans.count > 0 {gotItem = [gotItem, .fileMyModifiedTrans]}
    }//end func

    //---- resetUserDefaults - Reset all User Defaults to provide a clean startup
    //TODO: resetUserDefaults - Allow user to delete support files
    func resetUserDefaults() {
        if let appDomain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: appDomain)
            let msg = "User Defaults reset. Restart program to enter setup mode."
            _ = GBox.inputBox(prompt: msg, defaultText: "", maxChars: 0)
            NSApplication.shared.terminate(self)
        } else {
            let msg = "Could not reset User Defaults!"
            handleError(codeFile: codeFile, codeLineNum: #line, type: .codeError, action: .alertAndDisplay, errorMsg: msg)
        }
    }

    func gotNewTranactionFolder() {
        var errText = ""
        (transactionDirURL, errText)  = makeFileURL(pathFileDir: pathTransactionDir, fileName: "")
        if errText.isEmpty {             // Transaction Folder Exists
            btnStart.isEnabled = true
            transFileURLs = getTransFileList(transDirURL: transactionDirURL)
            if transFileURLs.count > 0 {
                gotItem = gotItem.union(GotItem.fileTransactions)
            }
            loadComboBoxFiles(fileURLs: transFileURLs)
            cboFiles.isHidden = false
            lblTranFileCount.stringValue = "\(transFileURLs.count) Transaction \("file".pluralize(transFileURLs.count))"
            lblErrMsg.stringValue = ""
            print("Trans Folder set to: \"\(pathTransactionDir)\"")

        } else {                        // Error getting Transaction Folder
            btnStart.isEnabled = false
            transFileURLs = []
            loadComboBoxFiles(fileURLs: transFileURLs)
            cboFiles.isHidden = true
            lblTranFileCount.stringValue = "----"
            lblErrMsg.stringValue = errText
            gotItem = gotItem.subtracting(GotItem.fileTransactions)
        }
    }//end func

}//end class ViewController

// Allow ViewController to see when a TextField changes.
extension ViewController: NSTextFieldDelegate {

    //---- controlTextDidChange - Called when a textField (with ViewController as its delegate) changes.
    func controlTextDidChange(_ obj: Notification) {
        guard let textView = obj.object as? NSTextField else {
            return
        }
        if pathTransactionDir != txtTransationFolder.stringValue {
            pathTransactionDir = txtTransationFolder.stringValue
            gotNewTranactionFolder()
        }
    }

}//end extension ViewController: NSTextFieldDelegate
