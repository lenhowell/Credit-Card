//
//  ErrorHandler.swift
//  Credit Cards
//
//  Created by George Bauer on 8/8/19.
//  Copyright © 2019 George Bauer. All rights reserved.
//

// TODO: Append Error message to Error-Log File

import Cocoa

public var allowAlerts = true

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
/*
 //ErrorHandler from PortfolioSummary
 //MARK:- Globals

 public var gAllowAlerts = false
 private var gSuppressErrAlerts = [String]()      //Only used in errorHandlerAlert
 public var gErrorCount   = 0
 public var gWarningCount = 0
 public var gErrRecords   = [ErrorRecord]()

 //MARK:- enums & structs

 public enum ErrType {
     case none
     case paramWarn
     case warning
     case paramErr
     case error
     case info
 }



 // not yet used
 public struct ErrorRecord {
     var type: ErrType = .none
     var file = ""
     var function = ""
     var line = 0
     var msg = ""
 }

 // not yet used
 public struct DebugOption {
     var showParamWarn = DebugAction.none
     var showParamErr  =  DebugAction.none
     var traceProgramFlow = DebugAction.none
     var showLoadVals = DebugAction.none
     var traceASymbol = false
     var symbolToTrace = ""
 }

 //MARK:- Regular funcs

 //---- errorHandler --- see ViewContoller todo
 /// Handles errors by sending to log & optionally calling an NSAlert
 ///
 /// - Parameters:
 ///   - type: .error, .warning, or .info
 ///   - file: #file to report which swift file called
 ///   - function: #function to report which function called
 ///   - line: line number of caller
 ///   - msg: message to be displayed
 ///   - emoji: optionally override standard emojis ⛔️, ⚠️, or 🔹
 ///   - showAlert: optionally override showing NSAlert for .error only.
 public func errorHandler(type: ErrType, file: String, function: String, line: Int,
                          msg: String, emoji: String = "", showAlert: Bool? = nil) {
     //errorHandler(type: .warning, file: #file, function: #function, line: #line, msg: msg)
     //errType: Step=1 Warning=2, Error=3, Info=9
     //funcName is the name of the calling func
     //errLabel is a unique ID to allow suppression of this particular error being repeated

     let funcName = getFuncName(function)    // Strip param from function name

     let fileComps = file.components(separatedBy: "/")
     let fileNameFull = fileComps.last!
     let comps2 = fileNameFull.components(separatedBy: ".")
     let fileName = comps2[0]

     var icon = emoji
     var errTypeName: String = ""
     let errRecord = ErrorRecord(type: type, file: fileNameFull, function: funcName, line: line, msg: msg)
     switch type {
     case .error:
         errTypeName = "Error "
         if emoji.isEmpty { icon = "⛔️" }
         gErrorCount += 1
         gErrRecords.append(errRecord)
     case .warning:
         errTypeName = "Warning "
         if emoji.isEmpty { icon = "⚠️" }
         gWarningCount += 1
         gErrRecords.append(errRecord)
     case .info:
         errTypeName = ""
         if emoji.isEmpty { icon = "🔹" }
     default:
         errTypeName = ""
         if emoji.isEmpty { icon = "?" }
     }//end switch
     let prefix = "\(icon) \(errTypeName)"
     //    var Title: String = errTypeName + ": " + ErrLabel + " from " + funcName

     print("\(prefix)\(fileName) line \(line): \(funcName): \(msg)")

     let showAlertNow: Bool
     if let showAlert = showAlert {
         showAlertNow = showAlert
     } else if type == .error {
         showAlertNow = true
     } else if type == .warning && debugLevel >= 3 {
         showAlertNow =  true
     } else {
         showAlertNow = false
     }

     if showAlertNow && gAllowAlerts {
         errorHandlerAlert(type: type, fileName: fileNameFull, funcName: funcName, line: line, msg: msg, title: prefix)
     }
     return
 }//end func errorHandler

 private func errorHandlerAlert(type: ErrType, fileName: String, funcName: String, line: Int,
                        msg: String, title: String = "") {
     let suppressionName = "\(fileName)\(line)"
     if gSuppressErrAlerts.contains(suppressionName) { return }
     let alert = NSAlert()
     alert.alertStyle = .warning
     alert.alertStyle = .critical
     alert.alertStyle = .informational

 //    alert.addButton(withTitle: "First")
 //    alert.addButton(withTitle: "Second")
 //    alert.addButton(withTitle: "Third")            // Third  | Second | First

     alert.messageText = "\(title)\n\(msg)"
     alert.informativeText = "from \(fileName) line \(line)\n in \(funcName)"

     alert.showsSuppressionButton = true

     alert.runModal()
     if alert.suppressionButton?.state == .on {
         print("🤬🤬🤬🤬 Suppress Error Alerts for \"\(suppressionName)\" 🤬🤬🤬🤬")
         gSuppressErrAlerts.append(suppressionName)
     }
 }

 //---- getFuncName - Get func Name (without params) from #function
 public func getFuncName(_ function: String) -> String {
     let funcComps = function.components(separatedBy: "(")
     let funcName = funcComps[0] + "()"
     return funcName
 }

 */
