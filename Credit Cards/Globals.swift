//
//  Globals.swift
//  Credit Cards
//
//  Created by George Bauer on 11/9/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Foundation

public struct Const {
    // Global Constants
    static let maxCardTypeLen = 10
    static let descKeyLength  = 24
    static let maxDollar = 999_999_999.0
    static let unknown = "Unknown"
}//end struct

//not used yet
public struct Url {
    var vendorShortNamesFile = FileManager.default.homeDirectoryForCurrentUser
    var myAccounts           = FileManager.default.homeDirectoryForCurrentUser
    var myCatsFile           = FileManager.default.homeDirectoryForCurrentUser
    var myModifiedTrans      = FileManager.default.homeDirectoryForCurrentUser
    var vendorCatLookupFile  = FileManager.default.homeDirectoryForCurrentUser
    var transactionFolder    = FileManager.default.homeDirectoryForCurrentUser
}
