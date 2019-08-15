//
//  Stats.swift
//  Credit Cards
//
//  Created by George Bauer on 8/12/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Foundation
// struct for handling counts
struct Stats {
    static var transFileCount        = 0    // Transaction files read
    static var junkFileCount         = 0    // Files in folder not read
    static var successfulLookupCount = 0    // Transactions where Cat found in CatFile.
    static var addedCatCount         = 0    // Catagories added by program from a Transaction.
    static var descWithNoCat         = 0    // Descs not in Catagory File & not added by Transaction

    static func clearAll() {
        transFileCount          = 0
        junkFileCount           = 0
        successfulLookupCount   = 0
        addedCatCount           = 0
        descWithNoCat           = 0
    }
}
