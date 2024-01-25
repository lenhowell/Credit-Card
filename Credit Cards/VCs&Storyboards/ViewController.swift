//
//  ViewController.swift
//  Credit Cards
//
//  Created by 💪 George Bauer on 7/28/19.
//  Copyright © 2019-2021 George Bauer. All rights reserved.
//

import Cocoa

//TODO:
// Debug Trap: 2019-"xxxxxx9454 Wikipedia Giftxxx-xxx9454" 2016-"xx7880 COLONIAL MALL"
// Allow 2020 to read 2021 checks & ignore 2019 checks in 2020 folder
// "Print", or at least allow copy/paste in summary & spreadsheet
// ErrorHandler:    Append Error message to Error-Log File
// FileIO:          Tell user about non-qualified filenames & show rules.
// FileIO:          If url is not a file, append default filename 1
// FileIO:          If url is not a file, append default filename 2
// FileAmazonOrders: Fix returns, crosscheck files/year count.
// DescriptionKey:  Eliminate use of firstIntIndexOf()
// LineItems:       Allow LineItem.init to throw errors
// VendorShortNames: Change to use segue & eliminate globals 1
// VendorShortNames: Change to use segue & eliminate globals 2
// TableFilter:     Handle filtering as an object
// Credit_Cards_UnitTests: The following Unit-Tests need assertions
// DescriptionKey#199 "PAYPAL *CHIRP"  -  Remove "PAYPAL *" & Lookup Name


//MARK: - ViewController
class ViewController: NSViewController, NSWindowDelegate {
    
    //MARK: - Instance Variables
    
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
    var gotItems: GotItem        = .empty    // all zeros

    //---- GotItem - Bitmap to record what required items are accounted for
    struct GotItem: OptionSet {
        let rawValue: Int

        static let empty                = GotItem([])
        static let dirSupport           = GotItem(rawValue: 1 << 0) // bit 0  (1) got Support folder
        static let dirOutput            = GotItem(rawValue: 1 << 1) // bit 1  (2) got Output folder
        static let dirTrans             = GotItem(rawValue: 1 << 2) // bit 2  (4) got Transaction folder
        static let fileTransactions     = GotItem(rawValue: 1 << 3) // bit 3  (8) got at least 1 Transaction file
        static let fileVendorShortNames = GotItem(rawValue: 1 << 4) // bit 4 (16) got VendorShortNames file
        static let fileMyCategories     = GotItem(rawValue: 1 << 5) // bit 5 (32) got MyCategories file
        static let fileMyModifiedTrans  = GotItem(rawValue: 1 << 6) // bit 6 (64) got MyModifiedTrans file
        static let fileMyAccounts       = GotItem(rawValue: 1 << 7) // bit7 (128) got MyAccounts file

        static let userInitials         = GotItem(rawValue: 1 << 9) // bit9 (512) got userInitials

        static let allDirs: GotItem     = [.dirSupport, .dirOutput, .dirTrans]  // got all required folders
        static let requiredElements: GotItem = [.allDirs, .fileTransactions, .fileMyCategories, .userInitials]
    }//end struct GotItem

    //MARK: - Overrides & Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Create NotificationCenter Observer to listen for post from handleError
        NotificationCenter.default.addObserver(
            self,
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
                gotItems = [gotItems, .dirSupport]  // Add dirSupport-bit to gotItems
            }
        }
        if let folder = UserDefaults.standard.string(forKey: UDKey.outputFolder) {      // Output Folder
            pathOutputFolder = folder
            if !folder.isEmpty && FileIO.folderExists(atPath: folder, isPartialPath: true) {
                gotItems = [gotItems, .dirOutput]   // Add dirOutput-bit to gotItems
            }
        }
        if let folder = UserDefaults.standard.string(forKey: UDKey.transactionFolder) { // Transactions Folder
            pathTransactionFolder = folder
            if !folder.isEmpty && FileIO.folderExists(atPath: folder, isPartialPath: true) {
                gotItems = [gotItems, .dirTrans]    // Add dirTrans-bit to gotItems
            }
        }
        Glob.userInitials = UserDefaults.standard.string(forKey: UDKey.userInitials) ?? ""  // Users Initials
        if !Glob.userInitials.isEmpty {
            gotItems = [gotItems, .userInitials]    // Add userInitials-bit to gotItems
        }

        // Disable Spreadsheet button until Transactions are read-in
        setButtons(btnDefault: .start, needsRecalc: true, transFolderOK: true)
        //btnSpreadsheet.isEnabled = false

        // Start off with Learn-mode and user-intervension-mode off
        Glob.learnMode            = false
        Glob.userInputMode        = false
        chkLearningMode.state = Glob.learnMode     ? .on : .off
        chkUserInput.state    = Glob.userInputMode ? .on : .off

        // Get List of Transaction Files
        gotNewTranactionFolder()

        // Read Support files ("CategoryLookup.txt", "VendorShortNames.txt", "MyCategories.txt")
        txtOutputFolder.stringValue     = pathOutputFolder
        txtSupportFolder.stringValue    = pathSupportFolder
        txtTransationFolder.stringValue = pathTransactionFolder
        verifyFolders(gotItem: &gotItems)
        if gotItems.contains(GotItem.dirSupport) {
            readSupportFiles()
            let shortCatFilePath = FileIO.removeUserFromPath(Glob.url.vendorCatLookupFile.path)
            lblResults.stringValue = "Category Lookup File \"\(shortCatFilePath)\" loaded with \(Stats.origVendrCatCount) items.\n"
        } else {
            lblResults.stringValue = "You will need to create a folder to hold support files before you can proceed."
        }
        let errMsg = makeMissingItemsMsg(got: gotItems)
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
        print("😋 \(codeFile)#\(#line) Terminate app when Main Window closed.")
        NSApplication.shared.terminate(self)
        return true
    }

    //MARK: - Notification Center functions

    // Called by NotificationCenter Observer getting post from handleError. Sets lblErrMsg
    @objc func errorPostedFromNotification(_ notification: Notification) {
        guard let msg = notification.userInfo?[NotificationKey.errMsg] as? String else { return }
        lblErrMsg.stringValue = msg
        //print ("ErrMsg: \"\(msg)\" received from ErrorHandler via NotificationCenter")
    }

    //MARK: - @IBOutlets
    
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

    //MARK: - @IBActions

    @IBAction func btnStartClick(_ sender: Any) {
        main()
    }

    @IBAction func btnFindTruncatedDescs(_ sender: Any) {
        let vendorNameDescs = Array(Glob.dictVendorCatLookup.keys)
        let doWrite = findTruncatedDescs(vendorNameDescs: vendorNameDescs)
        if doWrite {
            writeVendorShortNames(url: Glob.url.vendorShortNamesFile, dictVendorShortNames: Glob.dictVendorShortNames)
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
        Glob.learnMode = chkLearningMode.state == .on
        print("😋 \(codeFile)#\(#line) learnMode = \(Glob.learnMode)")
    }
    @IBAction func chkUserInputClick(_ sender: Any) {
        Glob.userInputMode = chkUserInput.state == .on
        print("😋 \(codeFile)#\(#line) UserInputMode = \(Glob.userInputMode)")
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
        if gotItems.contains(.dirSupport) {
            var msg = ""
            msg = "custom categories & aliases."
            if FileIO.deleteSupportFile(url: Glob.url.myCatsFile, fileName: myCatsFilename, msg: msg) {
                didSomething += 1
            }
            msg = "vendor default categories."
            if FileIO.deleteSupportFile(url: Glob.url.vendorCatLookupFile, fileName: vendorCatLookupFilename, msg: msg) {
                didSomething += 1
            }
            msg = "custom vendor names."
            if FileIO.deleteSupportFile(url: Glob.url.vendorShortNamesFile, fileName: vendorShortNameFilename, msg: msg) {
                didSomething += 1
            }
            msg = "mods to your transaction files."
            if FileIO.deleteSupportFile(url: Glob.url.myModifiedTrans, fileName: myModifiedTranFilename, msg: msg) {
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
            let response = GBox.inputBox(prompt: prompt, defaultText: Glob.userInitials, maxChars: maxChars)
            let name = response.trim
            let len = name.count
            if name.isEmpty {
                let msg = "Your initials were not changed from \(Glob.userInitials)."
                handleError(codeFile: "", codeLineNum: #line, type: .note, action: .alertAndDisplay, errorMsg: msg)
                isValid = true
            }
            if len >= minChars && len <= maxChars && !name.contains(" ") {
                Glob.userInitials = name
                gotItems = gotItems.union(GotItem.userInitials)
                UserDefaults.standard.set(Glob.userInitials,      forKey: UDKey.userInitials)
                let msg = "Your initials have been changed to \(Glob.userInitials)."
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
        Glob.dictAmazonItemsByDate = readAmazon()
    }
    
    @IBAction func mnuHelpSearchForHelpOn_Click(_ sender: Any) {    // Handles mnuHelpSearchForHelpOn.Click
        GBox.alert("Unable to display Help Contents. There is no Help associated with this project.")
    }

    @IBAction func mnuHelpContents_Click(_ sender: Any) {           // Handles mnuHelpContents.Click
        GBox.alert("Unable to display Help Contents. There is no Help associated with this project.")
    }


    //MARK: - Main Program 155-lines
    
    func main() {   // 311-466 = 155-lines
        verifyFolders(gotItem: &gotItems)
        if !gotItems.contains(GotItem.allDirs) {
            let errMsg = makeMissingItemsMsg(got: gotItems)
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataWarning, action: .alertAndDisplay, fileName: "", dataLineNum: 0, lineText: "", errorMsg: errMsg)
            return
        }

        lblRunTime.stringValue = ""
        let startTime = CFAbsoluteTimeGetCurrent()

        var errTxt = ""

        pathTransactionFolder = txtTransationFolder.stringValue
        (Glob.url.transactionFolder, errTxt)  = FileIO.makeFileURL(pathFileDir: pathTransactionFolder, fileName: "")
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
        verifyFolders(gotItem: &gotItems)
        let errMsg = makeMissingItemsMsg(got: gotItems)
        if !gotItems.contains(GotItem.requiredElements) {
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataWarning, action: .alertAndDisplay, fileName: "", dataLineNum: 0, lineText: "", errorMsg: errMsg)
            return
        }

        // Save UserDefaults
        UserDefaults.standard.set(pathTransactionFolder, forKey: UDKey.transactionFolder)
        UserDefaults.standard.set(pathSupportFolder,     forKey: UDKey.supportFolder)
        UserDefaults.standard.set(pathOutputFolder,      forKey: UDKey.outputFolder)
        UserDefaults.standard.set(Glob.userInitials,      forKey: UDKey.userInitials)
        UserDefaults.standard.set(Glob.userInputMode,     forKey: UDKey.userInputMode)
        UserDefaults.standard.set(Glob.learnMode,         forKey: UDKey.learningMode)

        Stats.clearAll()        // Clear the Stats
        Glob.lineItemArray = []     // Clear the global Glob.lineItemArray
        usrIgnoreVendors = [String: Int]()  // Clear the "Ignore-Vendor" list
        Glob.dictVendorCatLookup = loadVendorCategories(url: Glob.url.vendorCatLookupFile) // Re-read Categories Dictionary
        Stats.origVendrCatCount = Glob.dictVendorCatLookup.count

        var fileContents    = ""                        // Where All Transactions in a File go
        Glob.dictTranDupes      = [:]
        Glob.dictCheckDupes     = [:]
        Glob.dictCreditDupes    = [:]
        Glob.dictNoVendrDupes   = [:]
        Glob.dictNoDateDupes    = [:]

        lblErrMsg.stringValue = ""
        
        if !FileManager.default.fileExists(atPath: Glob.url.transactionFolder.path) {
            let msg = "Folder does not exist"
            handleError(codeFile: codeFile, codeLineNum: #line, type: .codeError, action: .alertAndDisplay,  fileName: Glob.url.transactionFolder.path, dataLineNum: 0, lineText: "", errorMsg: msg)
        }

        let filesToProcessURLs: [URL]
        let shown = cboFiles.stringValue.trim
        if shown == "-all-" {
            filesToProcessURLs = transFileURLs
        } else {
            let nameWithExt = shown
            let fileURL = Glob.url.transactionFolder.appendingPathComponent(nameWithExt)
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
            Glob.transFilename  = fileURL.lastPathComponent
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
                handleCards(fileName: fileName, cardType: cardType, cardArray: cardArray, acct: Glob.accounts.dict[cardType])
                chkUserInput.state = Glob.userInputMode ? .on : .off
            } else {
                //Stats.junkFileCount += 1
            }
        }//next fileURL

        if chkDeposit.state == .on {
            readDeposits()
        }

        setButtons(btnDefault: .summary, needsRecalc: false, transFolderOK: true)

        outputTranactions(outputFileURL: outputFileURL, lineItemArray: Glob.lineItemArray)

        print("\n😋 --- Description-Key algorithms --- VC#\(#line)")
        for (key, val) in DescriptionKey.dictDescKeyAlgorithmCnts.sorted(by: <) {
            print("  \(key.PadRight(40))\(val)")
        }

        if Stats.addedCatCount > 0 || Stats.changedVendrCatCount > 0 {
            if Glob.learnMode {
                writeVendorCategoriesToFile(url: Glob.url.vendorCatLookupFile, dictCat: Glob.dictVendorCatLookup)
            }
        }
        //writeModTransTofile(url: Glob.url.myModifiedTrans, dictModTrans: Glob.dictModifiedTrans)

        var statString = ""

        let shortCatFilePath = FileIO.removeUserFromPath(Glob.url.vendorCatLookupFile.path)
        statString += "Category File \"\(shortCatFilePath)\" loaded with \(Stats.origVendrCatCount) items.\n"

        if filesToProcessURLs.count == 1 {
            let shortTransFilePath = FileIO.removeUserFromPath(filesToProcessURLs[0].path)
            statString += "\(Stats.transFileCount) File named \"\(shortTransFilePath)/\" Processed."
        } else {
            let shortTransFilePath = FileIO.removeUserFromPath(Glob.url.transactionFolder.path)
            statString += "\(Stats.transFileCount) Files from \"\(shortTransFilePath)/\" Processed."
        }

        statString += "\n \(Glob.lineItemArray.count + Stats.duplicateCount) CREDIT CARD Transactions PROCESSED."
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
        print("⏰ VC#\(#line)", String(format: "Runtime %5.02f sec", runtime))
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


    // Reads Support & Output folder names from textViews, & verifies they exist in gotItems
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

    func readSupportFiles() {   //640-713 = 73-lines
        var errTxt = ""

        // --------- "CategoryLookup.txt" -----------
        (Glob.url.vendorCatLookupFile, errTxt)  = FileIO.makeFileURL(pathFileDir: pathSupportFolder, fileName: vendorCatLookupFilename)
        if !errTxt.isEmpty {
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .display, errorMsg: "Category" + errTxt)
        }
        Glob.dictVendorCatLookup = loadVendorCategories(url: Glob.url.vendorCatLookupFile)       // Build Categories Dictionary
        Stats.origVendrCatCount = Glob.dictVendorCatLookup.count

        // -------- "VendorShortNames.txt" ----------
        (Glob.url.vendorShortNamesFile, errTxt)  = FileIO.makeFileURL(pathFileDir: pathSupportFolder, fileName: vendorShortNameFilename)
        if !errTxt.isEmpty {
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .display, errorMsg: "VendorShortNames " + errTxt)
        }
        Glob.dictVendorShortNames = loadVendorShortNames(url: Glob.url.vendorShortNamesFile)        // Build VendorShortNames Dictionary
        if Glob.dictVendorShortNames.count > 0 {
            // Found VendorShortNames.txt in support-files folder
            gotItems = [gotItems, .fileVendorShortNames]  // Add fileVendorShortNames-bit to gotItems
        } else {
            // Not found
            guard let path = Bundle.main.path(forResource: "VendorShortNames", ofType: "txt") else {
                let msg = "Missing starter file - VendorShortNames.txt"
                handleError(codeFile: codeFile, codeLineNum: #line, type: .codeError, action: .alertAndDisplay, errorMsg: msg)
                return  // Can't even find starter file
            }
            // starter file found, so use IT.
            let bundleCatsFileURL = URL(fileURLWithPath: path)
            Glob.dictVendorShortNames = loadVendorShortNames(url: bundleCatsFileURL)
            writeVendorShortNames(url: Glob.url.vendorShortNamesFile, dictVendorShortNames: Glob.dictVendorShortNames) // Save Starter file
            let msg = "A starter \"VendorShortNames.txt\" was placed in your support-files folder"
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataWarning, action: .display, errorMsg: msg)
        }

        // ---------- "MyCategories.txt" ------------
        (Glob.url.myCatsFile, errTxt)  = FileIO.makeFileURL(pathFileDir: pathSupportFolder, fileName: myCatsFilename)
        if !errTxt.isEmpty {
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .display, errorMsg: "MyCategories " + errTxt)
        }
        gCatagories = Catagories(myCatsFileURL: Glob.url.myCatsFile)
        if gCatagories.dictCatAliases.count > 5 {
            gotItems = [gotItems, .fileMyCategories]  // Add fileMyCategories-bit to gotItems
        }

        // ---------- "MyAccounts.txt" ------------
        (Glob.url.myAccounts, errTxt)  = FileIO.makeFileURL(pathFileDir: pathSupportFolder, fileName: Accounts.filename)
        if !errTxt.isEmpty {
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .display, errorMsg: "MyCategories " + errTxt)
        }
        Glob.accounts = Accounts(url: Glob.url.myAccounts)
        if Glob.accounts.dict.count > 0 {
            gotItems = [gotItems, .fileMyAccounts]  // Add fileMyAccounts-bit to gotItems

        } else {
            guard let path = Bundle.main.path(forResource: "MyAccounts", ofType: "txt") else {
                let msg = "Missing starter file - MyAccounts.txt"
                handleError(codeFile: codeFile, codeLineNum: #line, type: .codeError, action: .alertAndDisplay, errorMsg: msg)
                return
            }
            let bundleAccountsFileURL = URL(fileURLWithPath: path)
            Glob.accounts = Accounts(url: bundleAccountsFileURL)
            Glob.accounts.url = Glob.url.myAccounts
            Glob.accounts.writeToFile()    // Save Starter file
            let msg = "A starter \"MyAccounts.txt\" was placed in your support-files folder"
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataWarning, action: .display, errorMsg: msg)
        }


        // -------- "MyModifiedTransactions" ----------
        (Glob.url.myModifiedTrans, errTxt)  = FileIO.makeFileURL(pathFileDir: pathSupportFolder, fileName: myModifiedTranFilename)
        if !errTxt.isEmpty {
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .display, errorMsg: "MyModifiedTransactions " + errTxt)
        }
        Glob.dictModifiedTrans = loadMyModifiedTrans(myModifiedTranURL: Glob.url.myModifiedTrans)
        if Glob.dictModifiedTrans.count > 0 {
            gotItems = [gotItems, .fileMyModifiedTrans]  // Add fileMyModifiedTrans-bit to gotItems
        }
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
        (Glob.url.transactionFolder, errText)  = FileIO.makeFileURL(pathFileDir: pathTransactionFolder, fileName: "")
        if errText.isEmpty {             // Transaction Folder Exists
            setButtons(btnDefault: .start, needsRecalc: true, transFolderOK: true)  // btnStart.isEnabled = true etc
            transFileURLs = FileIO.getTransFileList(transDirURL: Glob.url.transactionFolder)
            if transFileURLs.count > 0 {
                gotItems = gotItems.union(GotItem.fileTransactions) // Mark Transaction-Files accounted for
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
            gotItems = gotItems.subtracting(GotItem.fileTransactions) // Mark as not there
        }
        //setButtons(btnDefault: .start, needsRecalc: true, transFolderOK: true)
        //cboFiles.scrollItemAtIndexToVisible(cboFiles.numberOfItems-1) Does not work

    }//end func

}//end class ViewController


// Allow ViewController to see when a TextField changes (includes ComboBox).
extension ViewController: NSTextFieldDelegate, NSComboBoxDelegate {

    //---- controlTextDidChange - Called when a textField (with ViewController as its delegate) changes.
    func controlTextDidChange(_ obj: Notification) {
        if let _ = obj.object as? NSTextField {
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

