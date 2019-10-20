//
//  Stats.swift
//  Credit Cards
//
//  Created by George Bauer on 8/12/19.
//  Copyright © 2019 George Bauer. All rights reserved.
//

import Foundation
// struct for handling counts
struct Stats {
    static var transFileCount        = 0    // Transaction FILES read
    static var transFileNumber       = 0    // as in "File Number 2 of 10"
    static var origVendrCatCount     = 0    // Count when CategoryLookup.txt was read in.
    static var successfulLookupCount = 0    // Transactions where Cat found in VendorCategoryLookup.
    static var addedCatCount         = 0    // Catagories added by program from a Transaction.
    static var changedVendrCatCount  = 0    // Catagories overridden by program
    static var descWithNoCat         = 0    // Descs not in Catagory File & not added by Transaction
    static var userModTransUsed      = 0    // Number of User-Modified transactions used.
    static var processedCount        = 0    // Transactions processed
    static var duplicateCount        = 0    // Duplicate Transactions
    static var lineItemNumber        = 0
    static var lineItemCount         = 0


    static func clearAll() {
        transFileCount          = 0
        transFileNumber         = 0
        origVendrCatCount       = 0
        successfulLookupCount   = 0
        addedCatCount           = 0
        changedVendrCatCount    = 0
        descWithNoCat           = 0
        userModTransUsed        = 0
        processedCount          = 0
        duplicateCount          = 0
        lineItemNumber          = 0
        lineItemCount           = 0
    }
}
