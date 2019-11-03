//
//  TableFilter.swift
//  Credit Cards
//
//  Created by George Bauer on 11/2/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Foundation

//TODO: Handle filtering in TableFilter
public struct TableFilter {

    var cardType    = ""
    var vendor      = ""
    var category    = ""
    var date1       = ""
    var date2       = ""
    var dollarVal1  = 0.0
    var dollarVal2  = 0.0

    //---- setFilter - Setup the filters based on the textView entries
//    private func setFilter() -> Bool {
//        filtDate1 = getFilterDate(txtField: txtDate1, isMin: true)
//        let date1Count = txtDate1.stringValue.trim.count
//        if date1Count >= 4 && date1Count <= 7 && txtDate2.stringValue.trim.isEmpty {
//            txtDate2.stringValue = txtDate1.stringValue.trim
//        }
//        filtDate2 = getFilterDate(txtField: txtDate2, isMin: false)
//
//        if txtDollar1.stringValue.trim.isEmpty {
//            filtDollarVal1 = 0.0
//        } else {
//            filtDollarVal1 = Double(txtDollar1.stringValue) ?? -1
//        }
//        if txtDollar2.stringValue.trim.isEmpty {
//            filtDollarVal2 = kMaxDollar
//        } else {
//            filtDollarVal2 = Double(txtDollar2.stringValue) ?? -1
//        }
//        if filtDollarVal1 < 0 || filtDollarVal2 < 0 { return false }
//        return true
//    }

    private func getFilterDate(txtField: String, isMin: Bool) -> String {
        var txt = txtField.trim
        if txt.count == 6 && txt[4] == "-" {
            txt = txt.prefix(4) + "-0" + txt.suffix(1)
            return txt
        }
        if isMin {
            if txt.isEmpty {
                return "2000-01-01"
                } else if txt.count == 4 {
                    txt += "-01-01"
            } else if txt.count == 7 && txt[4] == "-"  {
                txt += "-01"
            }

        } else {
            if txt.isEmpty {
                return "2100-12-31"
            } else if txt.count == 4 {
                txt += "-12-31"
            } else if txt.count == 7 && txt[4] == "-"  {
                txt += "-31"
            }

        }
        return makeYYYYMMDD(dateTxt: txt)

    }//end func


    //---- TableFilter.apply - Returns true if lineItem meets all the filter criteria
     func apply(lineItem: LineItem) -> Bool {
        if lineItem.credit + lineItem.debit < dollarVal1 { return false }
        if lineItem.credit + lineItem.debit > dollarVal2 { return false }

        if !date1.isEmpty {
            let tranDate = makeYYYYMMDD(dateTxt: lineItem.tranDate)
            if tranDate < date1 { return false }
            if tranDate > date2 { return false }
        }
        if !lineItem.descKey.hasPrefix(vendor.uppercased())          { return false }
        if !lineItem.cardType.hasPrefix(cardType.uppercased())       { return false }
        if !lineItem.genCat.uppercased().hasPrefix(category.uppercased()) { return false }
        return true
    }


}//end struct TableFilter
