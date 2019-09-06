//
//  UserInputVC.swift
//  Credit Cards
//
//  Created by George Bauer on 9/5/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Cocoa

class UserInputVC: NSViewController, NSWindowDelegate {
//    weak var delegate: UserInputVcDelegate?          //delegate <— (2)
    var t        = LineItem()
    var catItemFromVendor = CategoryItem()
    var catItemFromTran = CategoryItem()
    var catItemPrefered = CategoryItem()
    var textPassed      = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        t = usrLineItem
        lblLineItem.stringValue     = "\(t.cardType) \(t.tranDate)  \(t.descKey)   \(t.desc)   \(t.debit)"

        lblcatFromTran.stringValue   = usrCatItemFromTran.category
        lblcatFromVendor.stringValue = usrCatItemFromVendor.category
        lblcatPrefered.stringValue   = usrCatItemPrefered.category
        lblProcessed.stringValue     = String(Stats.processedCount)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window!.delegate = self
    }

    @IBOutlet var chkContinueUserInput: NSButton!
    @IBOutlet var lblLineItem:      NSTextField!
    @IBOutlet var lblcatFromTran:   NSTextField!
    @IBOutlet var lblcatPrefered:   NSTextField!
    @IBOutlet var lblcatFromVendor: NSTextField!
    @IBOutlet var lblProcessed:     NSTextField!


    @IBAction func radioCatChange(_ sender: Any) {

    }

    @IBAction func btnOK(_ sender: Any) {
        NSApplication.shared.stopModal(withCode: .OK)
    }

    @IBAction func btnCancel(_ sender: Any) {
        NSApplication.shared.stopModal(withCode: .cancel)
    }
    @IBAction func chkContinueUserInputClick(_ sender: Any) {
        userIntervention = chkContinueUserInput.state == .on
        print("userIntervention = \(userIntervention)")
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


}
