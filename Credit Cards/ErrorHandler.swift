//
//  ErrorHandler.swift
//  Credit Cards
//
//  Created by George Bauer on 8/8/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

// TODO: Append Error message to Error File
// TODO: Show Alert if  ErrAction == .alert or .alertAndDisplay
// TODO: Terminate app if ErrType == .codeFatal or .dataFatal

import Foundation

public var allowAlerts = true

public enum notificationName {
    static let errPosted = "ErrorPosted"
}
public enum notificationKey {
    static let errMsg = "ErrMsg"
}

public enum ErrAction {
    case printOnly, display, alert, alertAndDisplay
}
public enum ErrType {
    case codeFatal, dataFatal, codeError, dataError, codeWarning, dataWarning, note
}

//---- handleError - Must remain in ViewController because it sets lblErrMsg.stringValue
func handleError(codeFile: String, codeLineNum: Int, type: ErrType, action: ErrAction, fileName: String = "", dataLineNum: Int = 0, lineText: String = "", errorMsg: String) {
    let numberText = dataLineNum==0 ? "" : " Line#\(dataLineNum) "

    let icon: String
    if type == .codeWarning || type == .dataWarning {
        icon = "⚠️ Warning"
    } else if type == .note {
        icon = "➡️ Note"
    } else {
        icon = "⛔️ Error"
    }

    print("\n\(icon) @\(codeFile)#\(codeLineNum): \(errorMsg)")
    if !fileName.isEmpty {
        var text = "      \(fileName) \(numberText): "
        if lineText.count > 120 { text += "\n      "}
        text += "\(lineText)\""
        print("\(text)")
    }
    print()

    let errMsg = fileName + " " + errorMsg
    //print("ErrMsg: \"\(errMsg)\" sent by ErrorHandler to NotificationCenter")
    //Note: it is preferable to define your notification names as static strings in an enum or struct to avoid typos.

    NotificationCenter.default.post(name: NSNotification.Name(notificationName.errPosted), object: nil, userInfo: [notificationKey.errMsg: errMsg])

    if allowAlerts {
        if action == .alert || action == .alertAndDisplay {
            _ = GBox.alert(errMsg, style: .information)
        }
    }
}

