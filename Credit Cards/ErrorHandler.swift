//
//  ErrorHandler.swift
//  Credit Cards
//
//  Created by George Bauer on 8/8/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Foundation

public enum ErrAction {
    case printOnly, display, alert, alertAndDisplay
}
public enum ErrType {
    case codeFatal, dataFatal, codeError, dataError, codeWarning, dataWarning
}

//---- handleError - Must remain in ViewController because it sets lblErrMsg.stringValue
func handleError(codeFile: String, codeLineNum: Int, type: ErrType, action: ErrAction, fileName: String = "", dataLineNum: Int = 0, lineText: String = "", errorMsg: String) {
    let numberText = dataLineNum==0 ? "" : " Line#\(dataLineNum) "
    print("\n😡 Error \(codeFile)#\(codeLineNum) \(fileName) \(numberText) \"\(lineText)\"\n😡😡 \(errorMsg)")

    //lblErrMsg.stringValue = fileName + " " + errorMsg

    let errMsg = fileName + " " + errorMsg
    print("ErrMsg: \"\(errMsg)\" sent by ErrorHandler to NotificationCenter")
    //Note: it is preferable to define your notification names as static strings that belong
    //to a class or struct or other global form, so that you don't make a typo and introduce bugs.
    NotificationCenter.default.post(name: NSNotification.Name("ErrorPosted"), object: nil, userInfo: ["ErrMsg": errMsg])

    //TODO: Append to Error File
}

