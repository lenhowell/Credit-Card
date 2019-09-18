//
//  Alerts.swift
//  AnalyseSwiftCode
//
//  Created by George Bauer on 6/12/19.
//  Copyright © 2019 George Bauer. All rights reserved.
//

import Cocoa

public enum AlertStyle {
    case information
    case okCancel
    case yesNo
}
public enum AlertResult {
    case none
    case yes
    case no
    case ok
    case cancel
}

public class GBox {

    // string, title
    static public func alert(_ str: String, title: String = "") {
        print("Alert: ", str)
        DispatchQueue.main.async {
            let alert = NSAlert()
            if !title.isEmpty { alert.messageText = title }
            alert.informativeText = str
            alert.runModal()
        }
        return
    }

    // string, style -> result
    static public func alert(_ str: String, style: AlertStyle) -> AlertResult {

        if style == .information {
            alert(str)
            return .none
        }

        if style == .okCancel {
            let response = alertOKCancel(question: str, text: "")
            if response {
                return .ok
            }
            return .cancel
        }

        if style == .yesNo {
            let response = alertYesNo(question: str, text: "")
            if response {
                return .yes
            }
            return .no
        }

        return .none                            // Unknown Style
    }

    //---- alertOKCancel - OKCancel dialog box. Returns true if OK
    static private func alertOKCancel(question: String, text: String) -> Bool {
        let alert = NSAlert()
        alert.messageText       = question
        alert.informativeText   = text
        alert.alertStyle        = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }

    //---- alertYesNo - YesNo dialog box. Returns true? if Yes
    static private func alertYesNo(question: String, text: String) -> Bool {
        let alert = NSAlert()
        alert.messageText       = question
        alert.informativeText   = text
        alert.alertStyle        = .warning
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        return alert.runModal() == .alertFirstButtonReturn
    }


    //func showSimpleAlertWithMessage(message: String!) {
    //
    //    let alertController = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.Alert)
    //    let cancel = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
    //
    //    alertController.addAction(cancel)
    //
    //    if self.presentedViewController == nil {
    //        self.presentViewController(alertController, animated: true, completion: nil)
    //    }
    //}


    //TODO: InputBox options: DefaultText="", maxChars=24
    //---- InputBox - returns text
    static func inputBox(prompt: String, defaultText: String = "", maxChars: Int = 24) -> String {
        let alert = NSAlert()
        alert.messageText = prompt
        alert.addButton(withTitle: "Ok")
        alert.addButton(withTitle: "Cancel")
        let frameWidth = CGFloat(14 * maxChars)
        let txtInput = NSTextField(frame: NSMakeRect(0, 0, frameWidth, 30))
        txtInput.stringValue = ""
        txtInput.font = NSFont.systemFont(ofSize: 16)
        txtInput.stringValue = defaultText
        alert.accessoryView = txtInput
        //alert.accessoryView?.window!.makeFirstResponder(input)
        //self.view.window!.makeFirstResponder(input)               //????? How do I make "txtInput" the FirstResponder
        //input.becomeFirstResponder()
        let button: NSApplication.ModalResponse = alert.runModal()
        alert.buttons[0].setAccessibilityLabel("InputBox OK")

        //input.becomeFirstResponder()
        if button == .alertFirstButtonReturn {
            let str = txtInput.stringValue
            return str
        }
        return ""                               // anything else
    }
}//end class

