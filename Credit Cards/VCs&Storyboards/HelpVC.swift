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
        showHelp()
    }

    @IBOutlet var txvHelp: NSTextView!

    func showHelp() {

        //Not Used
        txvHelp.string =
"""
Transaction files are in: \"Downloads/Credit Card Tran/...\"
    CARDTYPE-20xx...
    Amazon Orders.txt
    DEPOSITcsv.csv

Support files for <NAME> are in: "Desktop/CreditCard/<NAME>/..."
    MyAccounts.txt
    MyCatagories.txt
    MyModifiedTransactions.txt
    VendorCategoryLookup.txt
    VendorShortNames.txt
"""

        // load RTFD-file
        guard let url = Bundle.main.url(forResource: "CreditCardHelp", withExtension: "rtf") else {
            txvHelp.string = "CreditCardHelp.rtf not found"
            return
        }
        let options = [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.rtf]

        do {
            let rtfString = try NSMutableAttributedString(url: url, options: options, documentAttributes: nil)
            txvHelp.textStorage?.setAttributedString(rtfString)
        } catch let err {
            txvHelp.string = "Error CreditCardHelp.rtf \(err.localizedDescription)"
        }//end try/catch

    }//end func showHelp

}//end class HelpVC
