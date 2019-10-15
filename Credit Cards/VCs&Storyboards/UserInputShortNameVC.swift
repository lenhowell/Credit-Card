//
//  UserInputShortNameVC.swift
//  Credit Cards
//
//  Created by George Bauer on 9/21/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Cocoa

class UserInputShortNameVC: NSViewController, NSWindowDelegate {
    let codeFile = "UserInputShortNameVC"

    //MARK:- Overrides & Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        // Set text field delegates
        txtPrefix.delegate = self         // Allow ViewController to see when txtPrefix changes.
        txtFullDescKey.delegate = self    // Allow ViewController to see when txtFullDescKey changes.

        txtPrefix.stringValue   = String(usrVendrShortName.prefix(descKeyLength)).uppercased()
        txtFullDescKey.stringValue = String(usrVendrLongName.prefix(descKeyLength)).uppercased()
        lblPrefixChars.stringValue = "\(txtPrefix.stringValue.count) letters"
        lblFullDescKeyChars.stringValue = "\(txtFullDescKey.stringValue.count) letters"
    }//end func

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window!.delegate = self
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        //print("✅(codeFile)#\(#line) windowShouldClose")
        let application = NSApplication.shared
        application.stopModal()
        return true
    }
    
    //MARK:- @IBOutlets
    @IBOutlet var lblPrefix:        NSTextField!
    @IBOutlet var lblFullDescKey:   NSTextField!
    @IBOutlet var txtPrefix:        NSTextField!
    @IBOutlet var txtFullDescKey:   NSTextField!
    @IBOutlet var lblPrefixChars:      NSTextField!
    @IBOutlet var lblFullDescKeyChars: NSTextField!

    //MARK:- @IBActions

    @IBAction func btnAbort(_ sender: Any) {
        let answer = GBox.alert("Do you want to save the results so far", style: .yesNo)
        if answer == .yes {
            NSApplication.shared.stopModal(withCode: .stop)
        } else {
            NSApplication.shared.stopModal(withCode: .abort)
        }
    }

    @IBAction func btnCancel(_ sender: Any) {
        NSApplication.shared.stopModal(withCode: .cancel)
    }

    @IBAction func btnOK(_ sender: Any) {
        let prefixCount = txtPrefix.stringValue.count
        if prefixCount < 4 || prefixCount > descKeyLength {
            let msg = "The common prefix must be between 4 and \(prefixCount) characters"
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataWarning, action: .alert, errorMsg: msg)
            return
        }

        let descKey = makeDescKey(from: txtFullDescKey.stringValue, dictVendorShortNames: [:], fileName: "")
        if txtFullDescKey.stringValue != descKey {
            let msg = "\(txtFullDescKey.stringValue) is not acceptable.\nSubstituting \(descKey)."
            txtFullDescKey.stringValue = descKey
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataWarning, action: .alert, errorMsg: msg)
            return
        }

        usrVendrPrefix = txtPrefix.stringValue
        usrVendrFullDescKey = txtFullDescKey.stringValue
        NSApplication.shared.stopModal(withCode: .OK)
    }
    
}//end class

//MARK: NSTextFieldDelegate
// Allow ViewController to see when a TextField changes.
extension UserInputShortNameVC: NSTextFieldDelegate {

    //---- controlTextDidChange - Called when a textField (with ViewController as its delegate) changes.
    func controlTextDidChange(_ obj: Notification) {
        guard let textView = obj.object as? NSTextField else {
            return      // Not a TextField
        }
        let prefixU = String(txtPrefix.stringValue.prefix(descKeyLength)).uppercased()
        if txtPrefix.stringValue != prefixU {
            txtPrefix.stringValue = prefixU
        }

        let descKey = String(txtFullDescKey.stringValue.prefix(descKeyLength)).uppercased()
        if txtFullDescKey.stringValue != descKey {
            txtFullDescKey.stringValue = descKey
        }

        lblPrefixChars.stringValue = "\(txtPrefix.stringValue.count) letters"
        lblFullDescKeyChars.stringValue = "\(txtFullDescKey.stringValue.count) letters"

    }//end func

}//end extension ViewController: NSTextFieldDelegate
