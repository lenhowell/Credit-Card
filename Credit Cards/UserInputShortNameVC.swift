//
//  UserInputShortNameVC.swift
//  Credit Cards
//
//  Created by George Bauer on 9/21/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Cocoa

class UserInputShortNameVC: NSViewController, NSWindowDelegate {
    //TODO: CLEAN UP UI
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        // Set text field delegates
        txtPrefix.delegate = self         // Allow ViewController to see when txtPrefix changes.
        txtFullDescKey.delegate = self    // Allow ViewController to see when txtFullDescKey changes.

        txtPrefix.stringValue   = usrVendrShortName
        txtFullDescKey.stringValue = usrVendrLongName
        lblPrefixChars.stringValue = "\(txtPrefix.stringValue.count) letters"
        lblFullDescKeyChars.stringValue = "\(txtFullDescKey.stringValue.count) letters"

    }//end func

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window!.delegate = self
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        //print("✅ windowShouldClose")
        let application = NSApplication.shared
        application.stopModal()
        return true
    }
    
    @IBOutlet var lblPrefix:        NSTextField!
    @IBOutlet var lblFullDescKey:   NSTextField!
    @IBOutlet var txtPrefix:        NSTextField!
    @IBOutlet var txtFullDescKey:   NSTextField!
    @IBOutlet var lblPrefixChars:      NSTextField!
    @IBOutlet var lblFullDescKeyChars: NSTextField!


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
        usrVendrPrefix = txtPrefix.stringValue
        usrVendrFullDescKey = txtFullDescKey.stringValue
        NSApplication.shared.stopModal(withCode: .OK)
    }
    
}//end class

// Allow ViewController to see when a TextField changes.
extension UserInputShortNameVC: NSTextFieldDelegate {

    //---- controlTextDidChange - Called when a textField (with ViewController as its delegate) changes.
    func controlTextDidChange(_ obj: Notification) {
        guard let textView = obj.object as? NSTextField else {
            return      // Not a TextField
        }
        if txtPrefix.stringValue.count > usrVendrShortName.count {
            txtPrefix.stringValue = usrVendrShortName
        }
        if txtPrefix.stringValue.count < 4 {
            txtPrefix.stringValue = String(usrVendrShortName.prefix(4))
        }
        if txtPrefix.stringValue != usrVendrShortName.prefix(txtPrefix.stringValue.count) {
            txtPrefix.stringValue = String(usrVendrShortName.prefix(txtPrefix.stringValue.count))
        }
        if txtFullDescKey.stringValue.count > descKeyLength {
            txtFullDescKey.stringValue = String(txtFullDescKey.stringValue.prefix(descKeyLength))
        }
        lblPrefixChars.stringValue = "\(txtPrefix.stringValue.count) letters"
        lblFullDescKeyChars.stringValue = "\(txtFullDescKey.stringValue.count) letters"

    }//end func

}//end extension ViewController: NSTextFieldDelegate
