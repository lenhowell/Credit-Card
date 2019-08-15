//
//  UserDefaults.swift
//  Credit Cards
//
//  Created by George Bauer on 8/14/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Foundation

public enum UDKey {
    static let transactionFolder = "CCTransactionFolder"
    static let categoryFolder    = "CCCategoryFolder"
    static let outputFolder      = "CCOoutputFolder"
}

func saveUserDefaults() {
    UserDefaults.standard.set("TEST", forKey: UDKey.transactionFolder)     //setObject
}
