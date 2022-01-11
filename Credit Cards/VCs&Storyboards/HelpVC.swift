//
//  HelpVC.swift
//  Credit Cards
//
//  Created by George Bauer on 1/11/22.
//  Copyright © 2022 Lenard Howell. All rights reserved.
//

import Cocoa

class HelpVC: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }


    func mnuHelpShowHelp(_ sender: Any) {
        GBox.alert("Transaction files are in:\n\"Download/Credit Card Tran/...\"\nCARDTYPE-20xx...\nAmazon Orders.txt\nDEPOSITcsv.csv\n\nSupport files are in:\n\"Desktop/CreditCard\"\nMyAccounts.txt\nMyCatagories.txt\nMyModifiedTransactions.txt\nVendorCategoryLookup.txt\nVendorShortNames.txt", title: "Help")
    }

}
