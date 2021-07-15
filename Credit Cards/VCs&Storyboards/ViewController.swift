//
//  ViewController.swift
//  Credit Cards
//
//  Created by 💪 Lenard Howell on 7/28/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Cocoa

//MARK:- Global Variables

var gUserInitials           = "User"    //  UD (UserInputVC) Initials used for "Category Source" when Cat changed by user.
var gLineItemArray          = [LineItem]()  // (used here, SpreadsheetVC, + 4 more) Entire list of transactions
var gTransFilename          = ""            // (UserInputVC.swift-viewDidLoad) Current Transaction Filename
var gMyCatNames             = [String]()    // (FileIO.loadMyCats, UserInputVC) Category Names (MyCategories.txt)
var gAccounts               = Accounts()

var gDictMyCatAliases       = [String: String]()        // (LineItems.init, HandleCards, etc) Hash of Category Synonyms
var gDictMyCatAliasArray    = [String: [String]]()      // (FileIO, UserInputCatVC) Synonyms for each cat name
var gDictVendorCatLookup    = [String: CategoryItem]()  // (here, HandleCards) Hash for Category Lookup (CategoryLookup.txt)
var gDictTranDupes          = [String: (Int, String)]() // (clr:main, use:handleCards) to find dupe transactions
var gDictNoVendrDupes       = [String: (Int, String)]() // (clr:main, use:handleCards)
var gDictNoDateDupes        = [String: (Int, String)]() // (clr:main, use:handleCards)
var gDictCheckDupes         = [String: Int]()           // (clr:main, use:handleCards) to find dupe checkNumbers
var gDictCreditDupes        = [String: String]()        // (clr:main, use:handleCards) dupe Visa Credits (inconsistant dates)
var gDictModifiedTrans      = [String: ModifiedTransactionItem]() // (load:here use:HandleCards) user-modified transactions
var gDictAmazonItemsByDate  = [String: [AmazonItem]]()  // (load:here NOTused)

var gMyCategoryHeader       = ""
var gIsUnitTesting          = false     // Not used
var gLearnMode              = true      // Used here & HandleCards.swift
var gUserInputMode          = true      // Used here & HandleCards.swift

var gDictVendorShortNames   = [String: String]()        // (VendorShortNames.txt) Hash for VendorShortNames Lookup

var gUrl                    = Url()

//MARK:- ViewController
class ViewController: NSViewController, NSWindowDelegate {
    
    //MARK:- Instance Variables
    
    // Constants
    let codeFile = "ViewController"   // for error logging
    let myFileNameOut           = "Combined-Creditcard-Master.txt" // Only used in outputTranactions
    let vendorCatLookupFilename = "VendorCategoryLookup.txt"
    let myCatsFilename          = "MyCategories.txt"
    let myModifiedTranFilename  = "MyModifiedTransactions.txt"

    let vendorShortNameFilename = "VendorShortNames.txt"

    // Variables
    var transFileURLs           = [URL]()
    var pathTransactionFolder   = "Downloads/Credit Card Trans"
    var pathSupportFolder       = "Desktop/CreditCard/xxx"
    var pathOutputFolder        = "Desktop/CreditCard"

    var outputFileURL           = FileManager.default.homeDirectoryForCurrentUser
    var gotItem: GotItem        = .empty

    //---- GotItem - Bitmap to record what required items are accounted for
    struct GotItem: OptionSet {
        let rawValue: Int
        static let empty        = GotItem([])
        static let dirSupport   = GotItem(rawValue: 1 << 0)     // bit 0 (=1) if got Support folder
        static let dirOutput    = GotItem(rawValue: 1 << 1)     // bit 1 (=2) if got Output folder
        static let dirTrans     = GotItem(rawValue: 1 << 2)     // bit 2 (=4) if got Transaction folder

        static let fileTransactions     = GotItem(rawValue: 1 << 3) // bit 3 if got at least 1 Transaction file
        static let fileVendorShortNames = GotItem(rawValue: 1 << 4) // bit 4 if got VendorShortNames file
        static let fileMyCategories     = GotItem(rawValue: 1 << 5)
        static let fileMyModifiedTrans  = GotItem(rawValue: 1 << 6)
        static let fileMyAccounts       = GotItem(rawValue: 1 << 7)

        static let userInitials         = GotItem(rawValue: 1 << 9)

        static let allDirs: GotItem     = [.dirSupport, .dirOutput, .dirTrans]
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

        // NSComboBoxDelegate Does not work!
        cboFiles.hasVerticalScroller = true
        self.cboFiles.delegate = self

        // ------ Get UserDefaults -----
        if let folder = UserDefaults.standard.string(forKey: UDKey.supportFolder) {     // Support Folder
            pathSupportFolder = folder
            if !folder.isEmpty && FileIO.folderExists(atPath: folder, isPartialPath: true) {
                gotItem = [gotItem, .dirSupport]
            }
        }
        if let folder = UserDefaults.standard.string(forKey: UDKey.outputFolder) {      // Output Folder
            pathOutputFolder = folder
            if !folder.isEmpty && FileIO.folderExists(atPath: folder, isPartialPath: true) {
                gotItem = [gotItem, .dirOutput]
            }
        }
        if let folder = UserDefaults.standard.string(forKey: UDKey.transactionFolder) { // Transactions Folder
            pathTransactionFolder = folder
            if !folder.isEmpty && FileIO.folderExists(atPath: folder, isPartialPath: true) {
                gotItem = [gotItem, .dirTrans]
            }
        }
        gUserInitials = UserDefaults.standard.string(forKey: UDKey.userInitials) ?? ""  // Users Initials
        if !gUserInitials.isEmpty {
            gotItem = [gotItem, .userInitials]
        }

        // Disable Spreadsheet button until Transactions are read-in
        setButtons(btnDefault: .start, needsRecalc: true, transFolderOK: true)
        //btnSpreadsheet.isEnabled = false

        // Start off with Learn-mode and user-intervension-mode off
        gLearnMode            = false
        gUserInputMode        = false
        chkLearningMode.state = gLearnMode     ? .on : .off
        chkUserInput.state    = gUserInputMode ? .on : .off

        // Get List of Transaction Files
        gotNewTranactionFolder()

        // Read Support files ("CategoryLookup.txt", "VendorShortNames.txt", "MyCategories.txt")
        txtOutputFolder.stringValue     = pathOutputFolder
        txtSupportFolder.stringValue    = pathSupportFolder
        txtTransationFolder.stringValue = pathTransactionFolder
        verifyFolders(gotItem: &gotItem)
        if gotItem.contains(GotItem.dirSupport) {
            readSupportFiles()
            let shortCatFilePath = FileIO.removeUserFromPath(gUrl.vendorCatLookupFile.path)
            lblResults.stringValue = "Category Lookup File \"\(shortCatFilePath)\" loaded with \(Stats.origVendrCatCount) items.\n"
        } else {
            lblResults.stringValue = "You will need to create a folder to hold support files before you can proceed."
        }
        let errMsg = makeMissingItemsMsg(got: gotItem)
        if !errMsg.isEmpty { handleError(codeFile: codeFile, codeLineNum: #line, type: .dataWarning, action: .display,
                                         fileName: "", dataLineNum: 0, lineText: "", errorMsg: errMsg) }

    }//end func viewDidLoad
    
    override func viewDidAppear() {
        self.view.window?.delegate = self
    }

    // Not used
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
            //print(representedObject.debugDescription)
        }
    }

    // Terminate program if this window closes
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

    @IBOutlet weak var btnStart:        NSButton!
    @IBOutlet weak var btnSpreadsheet:  NSButton!
    @IBOutlet weak var btnSummary:      NSButton!
    @IBOutlet var chkLearningMode:      NSButton!
    @IBOutlet var chkUserInput:         NSButton!
    @IBOutlet var chkDeposit:           NSButton!

    @IBOutlet var radioActivityNormal:  NSButton!
    @IBOutlet var radioActivityOnly:   NSButton!
    @IBOutlet var radioActivityNot: NSButton!
    @IBOutlet var cboFiles:     NSComboBox!

    //MARK:- @IBActions

    @IBAction func btnStartClick(_ sender: Any) {
        main()
    }

    @IBAction func btnFindTruncatedDescs(_ sender: Any) {
        let vendorNameDescs = Array(gDictVendorCatLookup.keys)
        let doWrite = findTruncatedDescs(vendorNameDescs: vendorNameDescs)
        if doWrite {
            writeVendorShortNames(url: gUrl.vendorShortNamesFile, dictVendorShortNames: gDictVendorShortNames)
        }
    }

    @IBAction func btnSpreadsheet(_ sender: Any) {
        gPassToNextTable = TableParams()
        let storyBoard = NSStoryboard(name: "Spreadsheet", bundle: nil)
        guard let tableWindowController = storyBoard.instantiateController(withIdentifier: "SpreadsheetWindowController") as? NSWindowController else {
            let msg = "Error tyying to open Spreadsheet Window"
            handleError(codeFile: codeFile, codeLineNum: #line, type: .codeError, action: .alertAndDisplay, errorMsg: msg)
            return
        }
        if let tableWindow = tableWindowController.window {
            let application = NSApplication.shared
            application.runModal(for: tableWindow)

            tableWindow.close()
        }//end if let
    }//end func

    @IBAction func btnSummaryClick(_ sender: Any) {
        //handleError(codeFile: codeFile, codeLineNum: #line, type: .codeWarning, action: .alert, errorMsg: "This Button not yet implemented.")
        gPassToNextTable = TableParams()
        gPassToNextTable.calledBy = TableCalledBy.main
        gPassToNextTable.summarizeBy = SummarizeBy.groupCategory
        gPassToNextTable.sortBy = SortDirective(column: SummaryColID.netCredit, ascending: true)

        let storyBoard = NSStoryboard(name: "SummaryTable", bundle: nil)
        guard let summaryWindowController = storyBoard.instantiateController(withIdentifier: "SummaryWindowController") as? NSWindowController else {
            let msg = "Unable to open SummaryTable Window"
            handleError(codeFile: codeFile, codeLineNum: #line, type: .codeError, action: .alertAndDisplay, errorMsg: msg)
            return
        }
        if let summaryWindow = summaryWindowController.window {
            //let summaryTableVC = storyBoard.instantiateController(withIdentifier: "SummaryTableVC") as! SummaryTableVC
            print("😋 \(codeFile)#\(#line) btnSummaries", gPassToNextTable)
            let application = NSApplication.shared
            _ = application.runModal(for: summaryWindow) // <=================  UserInputVC

            summaryWindow.close()                     // Return here from userInputWindow
        }
    }

    @IBAction func chkLearningModeClick(_ sender: Any) {
        gLearnMode = chkLearningMode.state == .on
        print("😋 \(codeFile)#\(#line) learnMode = \(gLearnMode)")
    }
    @IBAction func chkUserInputClick(_ sender: Any) {
        gUserInputMode = chkUserInput.state == .on
        print("😋 \(codeFile)#\(#line) UserInputMode = \(gUserInputMode)")
    }

    @IBAction func chkDepositsClick(_ sender: Any) {

    }

@IBAction func radioActivity(_ sender: Any) {

    }

    // MARK:- IBActions - MenuBar

    @IBAction func mnuResetUserDefaults(_ sender: Any) {
        var didSomething = 0
        let response = GBox.alert("Are you sure you want to reset all User Defaults?", style: .yesNo)
        if response == .yes {
            if resetUserDefaults() {
                didSomething += 1
            } else {
                let msg = "Could not reset User Defaults!"
                handleError(codeFile: codeFile, codeLineNum: #line, type: .codeError, action: .alertAndDisplay, errorMsg: msg)
            }

        }
        if gotItem.contains(.dirSupport) {
            var msg = ""
            msg = "custom categories & aliases."
            if deleteSupportFile(url: gUrl.myCatsFile, fileName: myCatsFilename, msg: msg) {
                didSomething += 1
            }
            msg = "vendor default categories."
            if deleteSupportFile(url: gUrl.vendorCatLookupFile, fileName: vendorCatLookupFilename, msg: msg) {
                didSomething += 1
            }
            msg = "custom vendor names."
            if deleteSupportFile(url: gUrl.vendorShortNamesFile, fileName: vendorShortNameFilename, msg: msg) {
                didSomething += 1
            }
            msg = "mods to your transaction files."
            if deleteSupportFile(url: gUrl.myModifiedTrans, fileName: myModifiedTranFilename, msg: msg) {
                didSomething += 1
            }
        }

        if didSomething > 0 {
            let msg = "User Defaults reset. Restart program to enter setup mode."
            GBox.alert(msg)
            NSApplication.shared.terminate(self)
        }
    }//end func

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

    @IBAction func mnuReadAmazon(_ sender: Any) {
        gDictAmazonItemsByDate = readAmazon()
    }
    
    @IBAction func mnuHelpSearchForHelpOn_Click(_ sender: Any) {    // Handles mnuHelpSearchForHelpOn.Click
        MsgBox("Unable to display Help Contents. There is no Help associated with this project.")
    }

    @IBAction func mnuHelpContents_Click(_ sender: Any) {           // Handles mnuHelpContents.Click
        MsgBox("Unable to display Help Contents. There is no Help associated with this project.")
    }


    //MARK:- Main Program 155-lines
    
    func main() {   // 311-466 = 155-lines
        verifyFolders(gotItem: &gotItem)
        if !gotItem.contains(GotItem.allDirs) {
            let errMsg = makeMissingItemsMsg(got: gotItem)
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataWarning, action: .alertAndDisplay, fileName: "", dataLineNum: 0, lineText: "", errorMsg: errMsg)
            return
        }

        lblRunTime.stringValue = ""
        let startTime = CFAbsoluteTimeGetCurrent()

        var errTxt = ""

        pathTransactionFolder = txtTransationFolder.stringValue
        (gUrl.transactionFolder, errTxt)  = FileIO.makeFileURL(pathFileDir: pathTransactionFolder, fileName: "")
        if !errTxt.isEmpty {
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .alertAndDisplay, errorMsg: "Transaction" + errTxt)
            return
        }

        (outputFileURL, errTxt)  = FileIO.makeFileURL(pathFileDir: pathOutputFolder, fileName: myFileNameOut)
        if !errTxt.isEmpty {
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .alertAndDisplay, errorMsg: "Output" + errTxt)
            return
        }

        pathOutputFolder  = txtOutputFolder.stringValue
        pathSupportFolder = txtSupportFolder.stringValue

        readSupportFiles()
        verifyFolders(gotItem: &gotItem)
        let errMsg = makeMissingItemsMsg(got: gotItem)
        if !gotItem.contains(GotItem.requiredElements) {
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataWarning, action: .alertAndDisplay, fileName: "", dataLineNum: 0, lineText: "", errorMsg: errMsg)
            return
        }

        // Save UserDefaults
        UserDefaults.standard.set(pathTransactionFolder, forKey: UDKey.transactionFolder)
        UserDefaults.standard.set(pathSupportFolder,     forKey: UDKey.supportFolder)
        UserDefaults.standard.set(pathOutputFolder,      forKey: UDKey.outputFolder)
        UserDefaults.standard.set(gUserInitials,      forKey: UDKey.userInitials)
        UserDefaults.standard.set(gUserInputMode,     forKey: UDKey.userInputMode)
        UserDefaults.standard.set(gLearnMode,         forKey: UDKey.learningMode)

        Stats.clearAll()        // Clear the Stats
        gLineItemArray = []     // Clear the global gLineItemArray
        usrIgnoreVendors = [String: Int]()  // Clear the "Ignore-Vendor" list
        gDictVendorCatLookup = loadVendorCategories(url: gUrl.vendorCatLookupFile) // Re-read Categories Dictionary
        Stats.origVendrCatCount = gDictVendorCatLookup.count

        var fileContents    = ""                        // Where All Transactions in a File go
        gDictTranDupes      = [:]
        gDictCheckDupes     = [:]
        gDictCreditDupes    = [:]
        gDictNoVendrDupes   = [:]
        gDictNoDateDupes    = [:]

        lblErrMsg.stringValue = ""
        
        if !FileManager.default.fileExists(atPath: gUrl.transactionFolder.path) {
            let msg = "Folder does not exist"
            handleError(codeFile: codeFile, codeLineNum: #line, type: .codeError, action: .alertAndDisplay,  fileName: gUrl.transactionFolder.path, dataLineNum: 0, lineText: "", errorMsg: msg)
        }

        let filesToProcessURLs: [URL]
        let shown = cboFiles.stringValue.trim
        if shown == "-all-" {
            filesToProcessURLs = transFileURLs
        } else {
            let nameWithExt = shown
            let fileURL = gUrl.transactionFolder.appendingPathComponent(nameWithExt)
            filesToProcessURLs = [fileURL]
        }
        Stats.transFileCount = filesToProcessURLs.count
        if Stats.transFileCount == 0 {
            let msg = "No files in the form of Card-2018-12 found,\nwhere Card is 2-8 characters.\nand the extension is .csv, .tsv, or .dnl"
            GBox.alert(msg)
            return
        }

        //MARK: Loop through Files
        for (fileNum, fileURL) in filesToProcessURLs.enumerated() {
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
            if cardType.count >= 2 &&  cardType.count <= Const.maxCardTypeLen  {
                Stats.transFileNumber = fileNum + 1
                handleCards(fileName: fileName, cardType: cardType, cardArray: cardArray, acct: gAccounts.dict[cardType])
                chkUserInput.state = gUserInputMode ? .on : .off
            } else {
                //Stats.junkFileCount += 1
            }
        }//next fileURL

        if chkDeposit.state == .on {
            readDeposits()
        }

        setButtons(btnDefault: .spreadsheet, needsRecalc: false, transFolderOK: true)

        outputTranactions(outputFileURL: outputFileURL, lineItemArray: gLineItemArray)

        print("\n😋 --- Description-Key algorithms ---")
        for (key, val) in gDictDescKeyAlgorithm.sorted(by: <) {
            print("  \(key.PadRight(40))\(val)")
        }

        if Stats.addedCatCount > 0 || Stats.changedVendrCatCount > 0 {
            if gLearnMode {
                writeVendorCategoriesToFile(url: gUrl.vendorCatLookupFile, dictCat: gDictVendorCatLookup)
            }
        }
        //writeModTransTofile(url: gUrl.myModifiedTrans, dictModTrans: gDictModifiedTrans)

        var statString = ""

        let shortCatFilePath = FileIO.removeUserFromPath(gUrl.vendorCatLookupFile.path)
        statString += "Category File \"\(shortCatFilePath)\" loaded with \(Stats.origVendrCatCount) items.\n"

        if filesToProcessURLs.count == 1 {
            let shortTransFilePath = FileIO.removeUserFromPath(filesToProcessURLs[0].path)
            statString += "\(Stats.transFileCount) File named \"\(shortTransFilePath)/\" Processed."
        } else {
            let shortTransFilePath = FileIO.removeUserFromPath(gUrl.transactionFolder.path)
            statString += "\(Stats.transFileCount) Files from \"\(shortTransFilePath)/\" Processed."
        }

        statString += "\n \(gLineItemArray.count + Stats.duplicateCount) CREDIT CARD Transactions PROCESSED."
        statString += "\n Of These:"
        statString += "\n(a)\(String(Stats.duplicateCount).rightJust(5)       ) were duplicates.                  ←"
        statString += "\n(b)\(String(Stats.successfulLookupCount).rightJust(5)) were found in Category File.      ←"
        statString += "\n(c)\(String(Stats.addedCatCount).rightJust(5)        ) were inserted into Category File. ←"
        statString += "\n(d)\(String(Stats.changedVendrCatCount).rightJust(5) ) were changed in Category File.    ←"
        statString += "\n(e)\(String(Stats.userModTransUsed).rightJust(5)     ) were found in ModifiedTrans File. ←"
        statString += "\n(f)\(String(Stats.descWithNoCat).rightJust(5)        ) still with no Category assigned.  ←"
        lblResults.stringValue = statString
        
        let endTime   = CFAbsoluteTimeGetCurrent()
        let runtime = endTime - startTime
        print(String(format: "Runtime %5.02f sec", runtime))
        lblRunTime.stringValue = String(format: "Runtime %5.02f sec", runtime)
        print()

    }// End of func main

    //MARK: Support funcs

    enum Button { case start,spreadsheet,summary }
    private func setButtons(btnDefault: Button, needsRecalc: Bool, transFolderOK: Bool) {

        btnStart.keyEquivalent       = ""
        btnSpreadsheet.keyEquivalent = ""
        btnSummary.keyEquivalent     = ""

        if !transFolderOK {
            btnStart.isEnabled       = false
            btnSpreadsheet.isEnabled = false
            btnSummary.isEnabled     = false
            return
        }
        btnStart.isEnabled           = true

        if needsRecalc {
            btnStart.keyEquivalent   = "\r"
            btnSpreadsheet.isEnabled = false
            btnSummary.isEnabled     = false
            return
        }
        btnSpreadsheet.isEnabled     = true
        btnSummary.isEnabled         = true

        switch btnDefault {
        case .spreadsheet:
            btnSpreadsheet.keyEquivalent = "\r"
        case .summary:
            btnSummary.keyEquivalent     = "\r"
        default:
            btnStart.keyEquivalent       = "\r"
        }
    }

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

        msg = String(msg.dropLast())    // Drop the trailing comma
        return msg
    }
    
    //------ loadComboBoxFiles - Read Trk filenames and load ComboBoxFiles with Recent, Not-done, & Outdated files
    private func loadComboBoxFiles(fileURLs: [URL]) {          // 555-637 = 82 lines
        let fileNames = fileURLs.map { $0.lastPathComponent }
        cboFiles.removeAllItems()
        cboFiles.stringValue = "-all-"
        cboFiles.addItem(withObjectValue: "-all-")
        cboFiles.addItems(withObjectValues: fileNames)
        //NSComboBoxDelegate Does not work!
        //cboFiles.scrollItemAtIndexToVisible(cboFiles.numberOfItems-1) Does not work
        print("🤣 \(codeFile)#\(#line): cboFiles has \(cboFiles.numberOfItems) items.")
    }//end func loadComboBoxFiles


    // Reads Support & Output folder names from textViews, & verifies they exist in gotItem
    func verifyFolders(gotItem: inout GotItem) {

        let supportPath = txtSupportFolder.stringValue.trim
        if supportPath.isEmpty || !FileIO.folderExists(atPath: supportPath, isPartialPath: true) {
            print("🤣 \(codeFile)#\(#line): Support folder: \"\(txtSupportFolder.stringValue)\" doesn't exist.")
            gotItem = gotItem.subtracting(GotItem.dirSupport)
        } else {
            gotItem = gotItem.union(GotItem.dirSupport)
        }
        pathSupportFolder = supportPath

        let outputPath = txtOutputFolder.stringValue.trim
        if outputPath.isEmpty || !FileIO.folderExists(atPath: outputPath, isPartialPath: true) {
            print("😡  \(codeFile)#\(#line): Output folder: \"\(txtOutputFolder.stringValue)\" doesn't exist.")
            gotItem = gotItem.subtracting(GotItem.dirOutput)
            } else {
                gotItem = gotItem.union(GotItem.dirOutput)
            }
        pathOutputFolder  = outputPath

        let transPath = txtTransationFolder.stringValue.trim
        if transPath.isEmpty || !FileIO.folderExists(atPath: transPath, isPartialPath: true) {
            print("😡  \(codeFile)#\(#line): Output folder: \"\(txtTransationFolder.stringValue)\" doesn't exist.")
            gotItem = gotItem.subtracting(GotItem.dirTrans)
        } else {
            gotItem = gotItem.union(GotItem.dirTrans)
        }
        pathTransactionFolder = transPath
    }

    func readSupportFiles() {
        var errTxt = ""

        // --------- "CategoryLookup.txt" -----------
        (gUrl.vendorCatLookupFile, errTxt)  = FileIO.makeFileURL(pathFileDir: pathSupportFolder, fileName: vendorCatLookupFilename)
        if !errTxt.isEmpty {
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .display, errorMsg: "Category" + errTxt)
        }
        gDictVendorCatLookup = loadVendorCategories(url: gUrl.vendorCatLookupFile)       // Build Categories Dictionary
        Stats.origVendrCatCount = gDictVendorCatLookup.count

        // -------- "VendorShortNames.txt" ----------
        (gUrl.vendorShortNamesFile, errTxt)  = FileIO.makeFileURL(pathFileDir: pathSupportFolder, fileName: vendorShortNameFilename)
        if !errTxt.isEmpty {
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .display, errorMsg: "VendorShortNames " + errTxt)
        }
        gDictVendorShortNames = loadVendorShortNames(url: gUrl.vendorShortNamesFile)        // Build VendorShortNames Dictionary
        if gDictVendorShortNames.count > 0 {
            gotItem = [gotItem, .fileVendorShortNames]
        } else {
            guard let path = Bundle.main.path(forResource: "VendorShortNames", ofType: "txt") else {
                let msg = "Missing starter file - VendorShortNames.txt"
                handleError(codeFile: codeFile, codeLineNum: #line, type: .codeError, action: .alertAndDisplay, errorMsg: msg)
                return
            }
            let bundleCatsFileURL = URL(fileURLWithPath: path)
            gDictVendorShortNames = loadVendorShortNames(url: bundleCatsFileURL)
            writeVendorShortNames(url: gUrl.vendorShortNamesFile, dictVendorShortNames: gDictVendorShortNames) // Save Starter file
            let msg = "A starter \"VendorShortNames.txt\" was placed in your support-files folder"
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataWarning, action: .display, errorMsg: msg)
        }

        // ---------- "MyCategories.txt" ------------
        (gUrl.myCatsFile, errTxt)  = FileIO.makeFileURL(pathFileDir: pathSupportFolder, fileName: myCatsFilename)
        if !errTxt.isEmpty {
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .display, errorMsg: "MyCategories " + errTxt)
        }
        gDictMyCatAliases = loadMyCats(myCatsFileURL: gUrl.myCatsFile)
        if gDictMyCatAliases.count > 0 {
            gotItem = [gotItem, .fileMyCategories]

        } else {
            guard let path = Bundle.main.path(forResource: "MyCategories", ofType: "txt") else {
                let msg = "Missing starter file - MyCategories.txt"
                handleError(codeFile: codeFile, codeLineNum: #line, type: .codeError, action: .alertAndDisplay, errorMsg: msg)
                return
            }
            let bundleCatsFileURL = URL(fileURLWithPath: path)
            gDictMyCatAliases = loadMyCats(myCatsFileURL: bundleCatsFileURL)
            writeMyCats(url: gUrl.myCatsFile)    // Save Starter file
            let msg = "A starter \"MyCategories.txt\" was placed in your support-files folder"
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataWarning, action: .display, errorMsg: msg)
        }

        // ---------- "MyAccounts.txt" ------------
        (gUrl.myAccounts, errTxt)  = FileIO.makeFileURL(pathFileDir: pathSupportFolder, fileName: Accounts.filename)
        if !errTxt.isEmpty {
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .display, errorMsg: "MyCategories " + errTxt)
        }
        gAccounts = Accounts(url: gUrl.myAccounts)
        if gAccounts.dict.count > 0 {
            gotItem = [gotItem, .fileMyAccounts]

        } else {
            guard let path = Bundle.main.path(forResource: "MyAccounts", ofType: "txt") else {
                let msg = "Missing starter file - MyAccounts.txt"
                handleError(codeFile: codeFile, codeLineNum: #line, type: .codeError, action: .alertAndDisplay, errorMsg: msg)
                return
            }
            let bundleAccountsFileURL = URL(fileURLWithPath: path)
            gAccounts = Accounts(url: bundleAccountsFileURL)
            gAccounts.url = gUrl.myAccounts
            gAccounts.writeToFile() //= writeMyCats(url: gUrl.myCatsFile)    // Save Starter file
            let msg = "A starter \"MyAccounts.txt\" was placed in your support-files folder"
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataWarning, action: .display, errorMsg: msg)
        }


        // -------- "MyModifiedTransactions" ----------
        (gUrl.myModifiedTrans, errTxt)  = FileIO.makeFileURL(pathFileDir: pathSupportFolder, fileName: myModifiedTranFilename)
        if !errTxt.isEmpty {
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .display, errorMsg: "MyModifiedTransactions " + errTxt)
        }
        gDictModifiedTrans = loadMyModifiedTrans(myModifiedTranURL: gUrl.myModifiedTrans)
        if gDictModifiedTrans.count > 0 {gotItem = [gotItem, .fileMyModifiedTrans]}
    }//end func

    //---- resetUserDefaults - Reset all User Defaults to provide a clean startup
    func resetUserDefaults() -> Bool {
        if let appDomain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: appDomain)
            return true
        } else {
            return false
        }
    }

    //---- gotNewTranactionFolder - Try to load the Combo-Box with FileNames
    func gotNewTranactionFolder() {
        var errText = ""
        (gUrl.transactionFolder, errText)  = FileIO.makeFileURL(pathFileDir: pathTransactionFolder, fileName: "")
        if errText.isEmpty {             // Transaction Folder Exists
            setButtons(btnDefault: .start, needsRecalc: true, transFolderOK: true)  // btnStart.isEnabled = true etc
            transFileURLs = FileIO.getTransFileList(transDirURL: gUrl.transactionFolder)
            if transFileURLs.count > 0 {
                gotItem = gotItem.union(GotItem.fileTransactions) // Mark Transaction-Files accounted for
            }
            loadComboBoxFiles(fileURLs: transFileURLs)
            cboFiles.isHidden = false
            lblTranFileCount.stringValue = "\(transFileURLs.count) Transaction \("file".pluralize(transFileURLs.count))"
            lblErrMsg.stringValue = ""
            print("😋 \(codeFile)#\(#line) Trans Folder set to: \"\(pathTransactionFolder)\"")

        } else {                        // Error getting Transaction Folder
            setButtons(btnDefault: .start, needsRecalc: true, transFolderOK: false) // btnStart.isEnabled = false etc
            transFileURLs = []
            loadComboBoxFiles(fileURLs: transFileURLs)
            cboFiles.isHidden = true
            lblTranFileCount.stringValue = "----"
            lblErrMsg.stringValue = errText
            gotItem = gotItem.subtracting(GotItem.fileTransactions) // Mark as not there
        }
        //setButtons(btnDefault: .start, needsRecalc: true, transFolderOK: true)
        //cboFiles.scrollItemAtIndexToVisible(cboFiles.numberOfItems-1) Does not work

    }//end func

}//end class ViewController


// Allow ViewController to see when a TextField changes (includes ComboBox).
extension ViewController: NSTextFieldDelegate, NSComboBoxDelegate {

    //---- controlTextDidChange - Called when a textField (with ViewController as its delegate) changes.
    func controlTextDidChange(_ obj: Notification) {
        if let textView = obj.object as? NSTextField {
            if pathTransactionFolder != txtTransationFolder.stringValue {
                pathTransactionFolder = txtTransationFolder.stringValue
                gotNewTranactionFolder()
            }
        }
        // This only works if user types
        if let _ = obj.object as? NSComboBox {
            setButtons(btnDefault: .start, needsRecalc: true, transFolderOK: true)
            print("🔷 \(codeFile)#\(#line) comboBox Text Did Change")
        }
    }

    func comboBoxSelectionDidChange(_ obj: Notification) { //NSNotification.Name
        setButtons(btnDefault: .start, needsRecalc: true, transFolderOK: true)
        print("🔷 \(codeFile)#\(#line) comboBox Selection Did Change")
    }
    func comboBoxWillPopUp(_ obj: Notification) { //NSNotification.Name
        print("🔷 \(codeFile)#\(#line) comboBox Will PopUp")
    }

}//end extension ViewController: NSTextFieldDelegate

// NSComboBoxDelegate
//extension ViewController: NSComboBoxDelegate {
//    func controlTextDidChange(_ obj: Notification) {
//        guard let cbo = obj.object as? NSComboBox else {
//            return
//        }
//
//    }
//    // Does not work!
//    func willPopUpNotification(_ obj: Notification) { //NSNotification.Name
//        print("😂 \(obj)")
//    }
//}

