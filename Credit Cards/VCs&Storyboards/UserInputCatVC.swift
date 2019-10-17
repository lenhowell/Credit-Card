//
//  UserInputCatVC.swift
//  Credit Cards
//
//  Created by George Bauer on 9/5/19.
//  Copyright © 2019 George Bauer. All rights reserved.
//

import Cocoa

class UserInputCatVC: NSViewController, NSWindowDelegate {

    //MARK:- Instance Variables
//    weak var delegate: UserInputVcDelegate?          //delegate <— (2)
    let codeFile    = "UserInputCatVC"
    var catItemFromVendor = CategoryItem()
    var catItemFromTran   = CategoryItem()
    var catItemPrefered   = CategoryItem()
    var catItemCurrent    = CategoryItem()
    var textPassed        = ""
    var unlockedSource    = ""

    //MARK:- Overrides & Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        chkLockIn.state       = .off
        chkQuestionMark.state = .off

        lblFile.stringValue = gTransFilename
        let lineItem = usrLineItem
        let amt = lineItem.debit - lineItem.credit
        let strDebit = String(format:"%.2f", amt)
        let desc = lineItem.desc.PadRight(40, truncate: true, useEllipsis: true, fillChr: " ")
        lblLineItem.stringValue      = "\(lineItem.tranDate)  \"\(lineItem.descKey)\"   $\(strDebit)"
        lblDesc.stringValue          = "              \(desc)"
        lblcatFromTran.stringValue   = usrCatItemFromTran.category
        lblcatFromVendor.stringValue = usrCatItemFromVendor.category
        lblcatPrefered.stringValue   = usrCatItemPrefered.category
        lblProcessed.stringValue     = String(Stats.processedCount)
        btnAbort.isHidden            = !usrBatchMode
        btnIgnore.isHidden           = !usrBatchMode
        lblIgnore.isHidden           = !usrBatchMode
        btnCancel.title              = usrBatchMode ? "Pass" : "Cancel"

        loadComboBoxCats()
        catItemCurrent = usrCatItemPrefered
        updateAfterCatChange(newCatItem: catItemCurrent)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window!.delegate = self
    }

    //---- viewWillDisappear - Set gCityNum to positive value. Send changed-flags back to delegate in main ViewController
    override func viewWillDisappear() {
        //        if gHasUnSavedChanges {
        //            let buttonNumber = dialog2or3(text: "There are Unsaved Changes", subText: "Do you want to close anyway?",  btnTxt1: "Close without Saving",
        //                                          btnTxt2: "Save Changes")
        //            if buttonNumber == 2 {                      // Save Changes
        //                let success = saveCurrentSelections()
        //                if success { gHasUnSavedChanges = false }
        //            }
        //        }
        //        let changesWereMade = false
        //        let hasUnSavedChanges = false
        //        delegate?.userInputDone(changesWereMade: changesWereMade, unSavedChanges: hasUnSavedChanges) //delegate <— (3)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        print("✅(codeFile)#\(#line) windowShouldClose")
        let application = NSApplication.shared
        application.stopModal()
        return true
    }


    //MARK:- @IBOutlets
    @IBOutlet var lblFile:          NSTextField!
    @IBOutlet var lblLineItem:      NSTextField!
    @IBOutlet var lblDesc:          NSTextField!
    @IBOutlet var lblcatFromTran:   NSTextField!
    @IBOutlet var lblcatPrefered:   NSTextField!
    @IBOutlet var lblcatFromVendor: NSTextField!
    @IBOutlet var lblProcessed:     NSTextField!
    @IBOutlet var cboCats: NSComboBox!
    @IBOutlet var radioCatFromTran:     NSButton!
    @IBOutlet var radioCatFromVendor:   NSButton!
    @IBOutlet var radioCatPrefered:     NSButton!
    @IBOutlet var chkQuestionMark:      NSButton!
    @IBOutlet var chkLockIn:            NSButton!
    @IBOutlet var radioFileTransac:     NSButton!
    @IBOutlet var radioFileVendor:      NSButton!
    @IBOutlet var btnAbort:             NSButton!
    @IBOutlet var btnIgnore:            NSButton!
    @IBOutlet var btnCancel:            NSButton!
    @IBOutlet var lblIgnore:         NSTextField!


    //MARK:- @IBActions
    
    @IBAction func radioCatChange(_ sender: Any) {
        if radioCatPrefered.state == .on {
            catItemCurrent = usrCatItemPrefered

        } else if radioCatFromVendor.state == .on {
            catItemCurrent = usrCatItemFromVendor

        } else if radioCatFromTran.state == .on {
            catItemCurrent = usrCatItemFromTran
        }
        updateAfterCatChange(newCatItem: catItemCurrent)
    }

    @IBAction func cboCatsChange(_ sender: Any) {
        print("(codeFile)#\(#line) cboCatsChange \(cboCats.stringValue)")
        catItemCurrent.category = cboCats.stringValue
        catItemCurrent.source = gUserInitials
        updateAfterCatChange(newCatItem: catItemCurrent)
    }

    @IBAction func chkLockInClick(_ sender: Any) {

    }

    @IBAction func chkQuestionMarkClick(_ sender: Any) {
        let myCat = catItemCurrent.category
        if chkQuestionMark.state == .on {
            if !myCat.hasSuffix("?") {
                catItemCurrent.category = myCat + "-?"
            }
        } else {
            if myCat.hasSuffix("-?") {
                catItemCurrent.category = String(myCat.dropLast(2))
            } else if myCat.hasSuffix("?") {
                catItemCurrent.category = String(myCat.dropLast())
            }
        }
        updateAfterCatChange(newCatItem: catItemCurrent)
    }

    @IBAction func radioFileChange(_ sender: Any) {
        if radioFileTransac.state == .on {
            chkLockIn.isHidden = true
            chkQuestionMark.isHidden = true
        } else {
            chkLockIn.isHidden = false
            chkQuestionMark.isHidden = false
        }
    }//end func

    @IBAction func btnAddShortName(_ sender: Any) {
        let returnVal = showUserInputShortNameForm(shortName: usrLineItem.desc, longName: usrLineItem.descKey) //$$$
        if returnVal == .OK {           // OK: Add (prefix,descKey) to list
            gDictVendorShortNames[usrVendrPrefix] = usrVendrFullDescKey //move to showUserInputShortNameForm?
            writeVendorShortNames(url: gVendorShortNamesFileURL, dictVendorShortNames: gDictVendorShortNames)
        }
    }

    @IBAction func btnAddCategory(_ sender: Any) {
        let newCat = cboCats.stringValue.trim
        if gDictMyCatAliases[newCat] == nil {
            //TODO: Check for count etc.
            let response = GBox.alert("\(cboCats.stringValue) is not recognized.\nDo you want to add it to the list?", style: .yesNo)
            if response == .yes {
               addCategory(newCat)
            }
            return
        } else {
            _ = GBox.alert("\(cboCats.stringValue) is already recognized.\nType the new category into the ComboBox", style: .information)
        }
        return

    }

    @IBAction func btnOK(_ sender: Any) {
        // Categories are found in MyCategories.txt, MyModifiedTransactions.txt, VendorCategoryLookup.txt
        // Adding a category should only affect MyCategories.txt
        // Internal:
        //      gDictMyCatAliases:  [String: String]     alias: catName
        //      gMyCatNames: [String]                   catName
        //      gDictMyCatAliasArray: [String: [String]] catName: aliasArray
        // Must call writeMyCats()
        let newCat = cboCats.stringValue.trim
        if gDictMyCatAliases[newCat] == nil {
            //TODO: Check for count etc.
            let response = GBox.alert("\(cboCats.stringValue) is not recognized.\nDo you want to add it to the list?", style: .yesNo)
            if response == .yes {
               addCategory(newCat)
            }
            return
        }
        usrFixVendor = (radioFileVendor.state == .on)
        usrCatItemReturned = catItemCurrent
        if radioFileVendor.state == .on {
            if chkLockIn.state == .on {
                usrCatItemReturned.source = "$" + gUserInitials
            }
        } else {
            usrCatItemReturned.source = "*" + gUserInitials
        }
        print("(codeFile)#\(#line) return \(usrCatItemReturned.category) \(usrCatItemReturned.source)")
        NSApplication.shared.stopModal(withCode: .OK)
    }//end func

    @IBAction func btnIgnoreVendorClick(_ sender: Any) {
        usrIgnoreVendors[usrLineItem.descKey] = 101
        NSApplication.shared.stopModal(withCode: .cancel)
    }

    @IBAction func btnCancel(_ sender: Any) {
        NSApplication.shared.stopModal(withCode: .cancel)
    }

    @IBAction func btnAbortClick(_ sender: Any) {
        let answer = GBox.alert("Do you want to save the results so far", style: .yesNo)
        if answer == .yes {
            NSApplication.shared.stopModal(withCode: .continue)
        } else {
            NSApplication.shared.stopModal(withCode: .abort)
        }
    }

    //MARK: funcs

    //
    func addCategory(_ newCat: String) {
        gDictMyCatAliases[newCat] = newCat
        gDictMyCatAliasArray[newCat] = []
        gMyCatNames.append(newCat)
        gMyCatNames.sort()
        loadComboBoxCats()
        writeMyCats(url: gMyCatsFileURL)
    }

    // Sets ComboBox-String and chkQuestionMark.state
    private func updateAfterCatChange(newCatItem: CategoryItem) {
        let newCat = newCatItem.category
        cboCats.stringValue = newCat
        chkQuestionMark.state = (newCat.hasSuffix("?")) ? .on : .off
    }//end func

    //------ loadComboBoxCats - load ComboBoxCatss with myCategories
    private func loadComboBoxCats() {
        cboCats.removeAllItems()
        cboCats.addItems(withObjectValues: gMyCatNames)
        //print("🤣(codeFile)#\(#line) cboCats has \(cboCats.numberOfItems) items.")
    }//end func loadComboBoxFiles


}//end class
