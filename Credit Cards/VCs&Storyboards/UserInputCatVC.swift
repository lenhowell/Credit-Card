//
//  UserInputCatVC.swift
//  Credit Cards
//
//  Created by George Bauer on 9/5/19.
//  Copyright © 2019-2021 George Bauer. All rights reserved.
//

import Cocoa

class UserInputCatVC: NSViewController, NSWindowDelegate {

    //MARK:- Instance Variables
//    weak var delegate: UserInputVcDelegate?          //delegate <— (2)
    let codeFile = "UserInputCatVC"     // for error logging
    var catItemFromVendor = CategoryItem()
    var catItemFromTran   = CategoryItem()
    var catItemPrefered   = CategoryItem()
    var catItemCurrent    = CategoryItem()
    var unlockedSource    = ""
    var passMe          = ""    // Not used

    //MARK:- Overrides & Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        chkLockIn.state       = .off
        chkQuestionMark.state = .off

        lblFile.stringValue = gTransFilename + "    " + usrLineItem.chkNumber
        let lineItem        = usrLineItem
        let amt             = lineItem.debit - lineItem.credit
        let strDebit        = String(format:"%.2f", amt)
        let desc            = lineItem.desc.PadRight(60, truncate: true, useEllipsis: true, fillChr: " ")
        lblLineItem.stringValue = "\(lineItem.tranDate)  \"\(lineItem.descKey)\"   $\(strDebit)"
        lblDesc.stringValue     = "              \(desc)"
        txtMemo.stringValue     = lineItem.memo
        lblcatFromTran.stringValue   = usrCatItemFromTran.category
        lblcatFromVendor.stringValue = usrCatItemFromVendor.category
        lblcatPrefered.stringValue   = usrCatItemPrefered.category

        if usrBatchMode {
            lblProcessed.stringValue = "\(Stats.lineItemNumber) of \(Stats.lineItemCount),   file \(Stats.transFileNumber) of \(Stats.transFileCount)"
            radioFileVendor.state    = .on   // Default to setting VendorCat in batch mode
        } else {
            lblProcessed.stringValue = ""
            if !usrLineItem.modifiedKey.isEmpty{
                lblProcessed.stringValue = "This is a user-modidified transaction"
            }
            radioFileTransac.state   = .on   // Default to modifying Transaction otherwise
        }
        configureUI()

        btnAbort.isHidden   = !usrBatchMode
        btnIgnore.isHidden  = !usrBatchMode
        lblIgnore.isHidden  = !usrBatchMode
        btnCancel.title     = usrBatchMode ? "Pass" : "Cancel"

        loadComboBoxCats()
        catItemCurrent      = usrCatItemPrefered
        updateAfterCatChange(newCatItem: catItemCurrent)
        cboCats.delegate = self as NSComboBoxDelegate
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.delegate = self    // needed for windowShouldClose
    }

    //---- windowShouldClose - requires NSWindowDelegate
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
    @IBOutlet var txtMemo:          NSTextField!
    @IBOutlet var lblcatFromTran:   NSTextField!
    @IBOutlet var lblcatPrefered:   NSTextField!
    @IBOutlet var lblcatFromVendor: NSTextField!
    @IBOutlet var lblProcessed:     NSTextField!
    @IBOutlet var cboCats:      NSComboBox!
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
        print("\(codeFile)#\(#line) cboCatsChange \(cboCats.stringValue)")
        catItemCurrent.category = cboCats.stringValue
        catItemCurrent.source = gUserInitials
        updateAfterCatChange(newCatItem: catItemCurrent)
    }

    @IBAction func chkLockInClick(_ sender: Any) {

    }

    //FIXME: When user types-in Category, catItemCurrent.category != cboCats.stringValue
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
        if radioFileVendor.state == .on {
            if !usrLineItem.modifiedKey.isEmpty {
                let msg = "This is a modified transaction.\nIt will not be affected by Vendor category\nProceed anyway?"
                let response = GBox.alert(msg, style: .okCancel)
                if response == .cancel {
                    radioFileTransac.state = .on
                }

            }
        }
        configureUI()
    }

    @IBAction func btnAddShortName(_ sender: Any) {
        let returnVal = showUserInputShortNameForm(shortName: usrLineItem.desc.trim, longName: usrLineItem.descKey) //$$$
        if returnVal == .OK {           // OK: Add (prefix,descKey) to list
            gDictVendorShortNames[usrVendrPrefix] = usrVendrFullDescKey //move to showUserInputShortNameForm?
            writeVendorShortNames(url: gUrl.vendorShortNamesFile, dictVendorShortNames: gDictVendorShortNames)
        }
    }

    @IBAction func btnAddCategory(_ sender: Any) {
        let newCat = cboCats.stringValue.trim
        if gDictMyCatAliases[newCat] == nil {
            let response = GBox.alert("Add \(cboCats.stringValue) to category list?", style: .yesNo)
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
        if gDictMyCatAliases[newCat.uppercased()] == nil {
            let response = GBox.alert("\(cboCats.stringValue) is not recognized.\nDo you want to add it to the list?", style: .yesNo)
            if response == .yes {
               addCategory(newCat)
            }
            return
        }
        catItemCurrent.category = newCat
        usrFixVendor = (radioFileVendor.state == .on)
        if usrFixVendor && (!usrLineItem.modifiedKey.isEmpty) {
            let msg = "This is a modified transaction.\nIt will not be affected by Vendor category\nProceed anyway?"
            let response = GBox.alert(msg, style: .okCancel)
            if response == .cancel { return }
        }
        var modKey = ""
        if !usrFixVendor {
            modKey = usrLineItem.signature()
        }
        usrModTranItemReturned = ModifiedTransactionItem(catItem: catItemCurrent, memo: txtMemo.stringValue.trim, key: modKey)
        if radioFileVendor.state == .on {       // Change vendor cat
            if chkLockIn.state == .on { //LockIn
                usrModTranItemReturned.catItem.source = "$" + gUserInitials
            }
        } else {                                // Modify this transaction
            usrModTranItemReturned.catItem.source = "*" + gUserInitials
        }
        print("\(codeFile)#\(#line) return \(usrModTranItemReturned.catItem.category) \(usrModTranItemReturned.catItem.source)")
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

    //---- configureUI - Configure the UI based on VendorCat vs. Transaction
    private func configureUI() {
        if radioFileTransac.state == .on {
            chkLockIn.isHidden = true
            chkQuestionMark.isHidden = true
            txtMemo.isHidden = false
        } else {
            chkLockIn.isHidden = false
            chkQuestionMark.isHidden = false
            txtMemo.isHidden = true
        }
    }//end func

    //---- addCategory - Add a new user-input category to MyCategories
    func addCategory(_ newCat: String) {
        gDictMyCatAliases[newCat.uppercased()] = newCat
        gDictMyCatAliasArray[newCat] = []
        gMyCatNames.append(newCat)
        gMyCatNames.sort()
        loadComboBoxCats()
        writeMyCats(url: gUrl.myCatsFile)
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

//MARK: NSTextFieldDelegate, NSComboBoxDelegate
// Allow UserInputCatViewController to see when a TextField or ComboBox changes.
extension UserInputCatVC: NSTextFieldDelegate, NSComboBoxDelegate {

    //---- controlTextDidChange - Called when a textField (with ViewController as its delegate) changes.
    func controlTextDidChange(_ obj: Notification) {
        guard let cbo = obj.object as? NSComboBox else {
            return      // Not a ComboBox
        }
        chkQuestionMark.state = cboCats.stringValue.hasSuffix("?") ? .on : .off
        cbo.removeAllItems()
        let cboStr = cbo.stringValue.lowercased()
        //let smallList = gMyCatNames.filter{$0.lowercased().hasPrefix(cboStr)}
        //print(gMyCatNames.count, smallList.count)
        cboCats.addItems(withObjectValues: gMyCatNames.filter{$0.lowercased().contains(cboStr)})

    }//end func

    // Case-Insensitive auto-complete
    func comboBox(_ comboBox: NSComboBox, completedString partialString: String) -> String? {
        if comboBox == cboCats {
            for idx in 0..<gMyCatNames.count {
                let testItem = gMyCatNames[idx] as String
                if (testItem.commonPrefix(with: partialString, options: .caseInsensitive).count) == partialString.count {
                    return testItem
                }
            }
        }
        return ""
    }

}//end extension ViewController: NSTextFieldDelegate, NSComboBoxDelegate
