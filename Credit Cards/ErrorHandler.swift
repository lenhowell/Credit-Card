//
//  ErrorHandler.swift
//  Credit Cards
//
//  Created by George Bauer on 8/8/19.
//  Copyright © 2019-2021 George Bauer. All rights reserved.
//

// TODO: Append Error message to Error-Log File

import Cocoa

public var allowAlerts = true       //?? Global

public enum NotificationName {
    static let errPosted = "ErrorPosted"
}
public enum NotificationKey {
    static let errMsg = "ErrMsg"
}

public enum ErrAction {
    case printOnly, display, alert, alertAndDisplay
}
public enum ErrType {
    case codeFatal, dataFatal, codeError, dataError, codeWarning, dataWarning, note
}

//---- handleError - Must remain in ViewController because it sets lblErrMsg.stringValue - ?? Global
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
        text += "\"\(lineText)\""
        print("\(text)")
    }
    print()

    var errMsg = errorMsg
    if !fileName.isEmpty {
        var fileInfo = "\(fileName)\n"
        if dataLineNum > 0 {
            fileInfo = "\(fileName) line# \(dataLineNum)\n"
        }
        errMsg = fileInfo + errMsg
    }
    //let errMsg = "\(fileInfo) \(errorMsg)"
    //print("ErrMsg: \"\(errMsg)\" sent by ErrorHandler to NotificationCenter")
    //Note: it is preferable to define your notification names as static strings in an enum or struct to avoid typos.

    // Allow viewController to see error, to maybe show in a lable
    NotificationCenter.default.post(name: NSNotification.Name(NotificationName.errPosted), object: nil, userInfo: [NotificationKey.errMsg: errMsg])

    if allowAlerts {
        if action == .alert || action == .alertAndDisplay {
           // _ = GBox.alert(errMsg, style: .information)
            errorHandlerAlert(type: type, codeFile: codeFile, funcName: "", codeLineNum: codeLineNum,
                              fileName: fileName, dataLineNum: dataLineNum, lineText: lineText, msg: errMsg)
        }
    }
}//end func handleError

private var gSuppressErrAlerts = [String]()      //Only used in errorHandlerAlert

private func errorHandlerAlert(type: ErrType, codeFile: String, funcName: String, codeLineNum: Int,
                       fileName: String = "", dataLineNum: Int = 0, lineText: String = "", msg: String) {
    let suppressionName = "\(codeFile)\(codeLineNum)"
    if gSuppressErrAlerts.contains(suppressionName) { return }

    let title: String
    let alert = NSAlert()
    switch type {
    case .codeError:
        alert.alertStyle = .critical
        title = "Error"
    case .dataError:
        alert.alertStyle = .critical
        title = "Data Error"
    case .note:
        alert.alertStyle = .informational
        title = "Note"
    default:
        alert.alertStyle = .warning
        title = "Warning"
    }

    alert.messageText = "\(codeFile) \(title) \(codeLineNum)"
    alert.informativeText = "\(msg)"

    alert.showsSuppressionButton = true

    alert.runModal()
    if alert.suppressionButton?.state == .on {
        //print("🤬🤬🤬🤬 Suppress Error Alerts for \"\(suppressionName)\" 🤬🤬🤬🤬")
        gSuppressErrAlerts.append(suppressionName)
    }
}
