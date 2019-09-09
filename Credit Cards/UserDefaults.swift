//
//  UserDefaults.swift
//  Credit Cards
//
//  Created by George Bauer on 8/14/19.
//  Copyright © 2019 George Bauer. All rights reserved.
//

import Foundation

public enum UDKey {
    static let transactionFolder = "CCTransactionFolder"
    static let supportFolder     = "CCCategoryFolder"
    static let outputFolder      = "CCOoutputFolder"
    static let userInitials      = "CCUserInitials"
    static let userInputMode     = "CCUserInput"
    static let learningMode      = "CCLearningMode"
}

//func saveUserDefaults() {
//    UserDefaults.standard.set("TEST", forKey: UDKey.transactionFolder)     //setObject
//}
