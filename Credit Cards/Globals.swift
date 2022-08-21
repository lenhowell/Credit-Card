//
//  Globals.swift
//  Credit Cards
//
//  Created by George Bauer on 11/9/19.
//  Copyright © 2019-2021 George Bauer. All rights reserved.
//

import Foundation


public struct Const {
    // Global Constants
    static let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    static let appBuild   = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")            as? String ?? "0"
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

public struct Glob {
    static var userInitials           = "User"         // UD (UserInputVC) Initials used for "Category Source" when Cat changed by user
    static var lineItemArray          = [LineItem]()   // (used VC, SpreadsheetVC, + 4 more) Entire list of transactions
    static var transFilename          = ""             // (UserInputVC.swift-viewDidLoad) Current Transaction Filename
    static var accounts               = Accounts()

    static var dictVendorCatLookup    = [String: CategoryItem]()   // (VC, HandleCards) for Category Lookup(CategoryLookup.txt)
    static var dictTranDupes          = [String: (idx: Int, file: String)]() // (clr:main, use:handleCards) to find dupe transactions
    static var dictNoVendrDupes       = [String: (Int, String)]()  // (clr:main, use:handleCards)
    static var dictNoDateDupes        = [String: (Int, String)]()  // (clr:main, use:handleCards)
    static var dictCheckDupes         = [String: Int]()            // (clr:main, use:handleCards) to find dupe checkNumbers
    static var dictCheck2Dupes        = [String: Int]()            // (clr:main, use:handleCards) to find dupe checkNumbers
    static var dictCreditDupes        = [String: String]()         // (clr:main, use:handleCards) dupe Visa Credits (inconsistant dates)
    static var dictModifiedTrans      = [String: ModifiedTransactionItem]() // (load:VC use:HandleCards) user-modified transactions
    static var dictAmazonItemsByDate  = [String: [AmazonItem]]()   // (load:VC NOTused)

    static var myCategoryHeader       = ""
    static var isUnitTesting          = false      // Not used
    static var learnMode              = true       // Used VC & HandleCards.swift
    static var userInputMode          = true       // Used VC & HandleCards.swift

    static var dictVendorShortNames   = [String: String]()     // (VendorShortNames.txt) Hash for VendorShortNames Lookup

    static var url                    = Url()
}
