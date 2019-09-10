//
//  UserInputVC.swift
//  Credit Cards
//
//  Created by George Bauer on 9/5/19.
//  Copyright © 2019 George Bauer. All rights reserved.
//

import Cocoa

class UserInputVC: NSViewController, NSWindowDelegate {
//    weak var delegate: UserInputVcDelegate?          //delegate <— (2)
    var t        = LineItem()
    var catItemFromVendor = CategoryItem()
    var catItemFromTran   = CategoryItem()
    var catItemPrefered   = CategoryItem()
    var catItemCurrent    = CategoryItem()
    var textPassed     = ""
    var unlockedSource = ""
    //TODO: Blank out "$" & "?" checkboxes if user is not changing CategoryLookup
    //TODO: Add "Ignore this vendor for now"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        chkIgnoreVendor.state = .off
        chkLockIn.state       = .off
        chkQuestionMark.state = .off
        chkContinueUserInput.state = .on
        
        lblFile.stringValue = gTransFilename
        t = usrLineItem
        let amt = t.debit - t.credit
        let strDebit = String(format:"%.2f", amt)
        let desc = t.desc.PadRight(40, truncate: true, useEllipsis: true, fillChr: " ")
        lblLineItem.stringValue      = "\(t.tranDate)  \"\(t.descKey)\"   $\(strDebit)"
        lblDesc.stringValue          = "              \(desc)"
        lblcatFromTran.stringValue   = usrCatItemFromTran.category
        lblcatFromVendor.stringValue = usrCatItemFromVendor.category
        lblcatPrefered.stringValue   = usrCatItemPrefered.category
        lblProcessed.stringValue     = String(Stats.processedCount)

        loadComboBoxCats()
        catItemCurrent = usrCatItemPrefered
        updateAfterCatChange(newCatItem: catItemCurrent)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window!.delegate = self
    }

    @IBOutlet var lblFile:          NSTextField!
    @IBOutlet var lblLineItem:      NSTextField!
    @IBOutlet var lblDesc:          NSTextField!
    @IBOutlet var lblcatFromTran:   NSTextField!
    @IBOutlet var lblcatPrefered:   NSTextField!
    @IBOutlet var lblcatFromVendor: NSTextField!
    @IBOutlet var lblProcessed:     NSTextField!
    @IBOutlet var cboCats: NSComboBox!
    @IBOutlet var chkContinueUserInput: NSButton!
    @IBOutlet var radioCatFromTran:     NSButton!
    @IBOutlet var radioCatFromVendor:   NSButton!
    @IBOutlet var radioCatPrefered:     NSButton!
    @IBOutlet var chkQuestionMark:      NSButton!
    @IBOutlet var chkLockIn:            NSButton!
    @IBOutlet var chkIgnoreVendor:      NSButton!
    @IBOutlet var radioFileTransac:     NSButton!
    @IBOutlet var radioFileVendor:      NSButton!
    

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
        print("cboCatsChange \(cboCats.stringValue)")
        catItemCurrent.category = cboCats.stringValue
        catItemCurrent.source = gUserInitials
        updateAfterCatChange(newCatItem: catItemCurrent)
    }

    @IBAction func chkLockInClick(_ sender: Any) {

    }

    @IBAction func chkQuestionMarkClick(_ sender: Any) {
        let myCat = catItemCurrent.category
        if chkQuestionMark.state == .on {
            if !myCat.hasPrefix("?") {
                catItemCurrent.category = "?" + myCat
            }
        } else {
            if myCat.hasPrefix("?") {
                catItemCurrent.category = String(myCat.dropFirst())
            }
        }
        updateAfterCatChange(newCatItem: catItemCurrent)
    }

    @IBAction func radioFileChange(_ sender: Any) {

    }

    @IBAction func btnOK(_ sender: Any) {
        if chkIgnoreVendor.state == .on { usrIgnoreVendors[usrLineItem.descKey] = 101 }
        usrFixVendor = (radioFileVendor.state == .on)
        usrCatItemReturned = catItemCurrent
        if chkLockIn.state == .on {
            usrCatItemReturned.source = "$" + gUserInitials
        }
        print("return \(usrCatItemReturned.category) \(usrCatItemReturned.source)")
        NSApplication.shared.stopModal(withCode: .OK)
    }

    @IBAction func btnCancel(_ sender: Any) {
        if chkIgnoreVendor.state == .on { usrIgnoreVendors[usrLineItem.descKey] = 101 }
        NSApplication.shared.stopModal(withCode: .cancel)
    }

    @IBAction func btnAbortClick(_ sender: Any) {
        NSApplication.shared.stopModal(withCode: .abort)
    }

    @IBAction func chkContinueUserInputClick(_ sender: Any) {
        gUserInputMode = chkContinueUserInput.state == .on
        print("userIntervention = \(gUserInputMode)")
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
        print("✅ windowShouldClose")
        let application = NSApplication.shared
        application.stopModal()
        //dismiss(self) //does not work
        return true
    }

    func updateAfterCatChange(newCatItem: CategoryItem) {
        let newCat = newCatItem.category
        cboCats.stringValue = newCat
        chkQuestionMark.state = (newCat.hasPrefix("?")) ? .on : .off
    }//end func

    //------ loadComboBoxCats - load ComboBoxCatss with myCategories
    private func loadComboBoxCats() {
        cboCats.removeAllItems()
        cboCats.addItems(withObjectValues: gMyCatNames)
        //print("🤣cboCats has \(cboCats.numberOfItems) items.")
    }//end func loadComboBoxFiles


}//end class
