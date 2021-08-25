//
//  TableFilter.swift
//  Credit Cards
//
//  Created by George Bauer on 11/2/19.
//  Copyright © 2019-2021 George Bauer. All rights reserved.
//

import Foundation

//TODO: Handle filtering as an object
public struct TableFilter {

    var cardType    = ""
    var vendor      = ""
    var category    = ""
    var date1       = ""
    var date2       = ""
    var dollarVal1  = 0.0
    var dollarVal2  = 0.0

    static func getDateRange(txtfld1: String, txtfld2: String) -> (date1: String, txt1: String, date2: String, txt2: String, errMsg: String) {
        var errMsg = ""
        let txt1 = formatDateField(txtField: txtfld1)
        var txt2 = formatDateField(txtField: txtfld2)
        var date1 = "1900-01-01"
        var date2 = "2999-12-31"
        if txt1.contains("?") {
            errMsg = "Error in Filter Date"
        }
        if errMsg.isEmpty {
            if txt2.contains("?") { errMsg = "Error in Filter Date" }
            if txt1.isEmpty {
                txt2 = ""
            } else {
                date1 = decodeFormattedDate(txtDate: txt1, isMin: true)
                if txt2.isEmpty {
                    date2 = decodeFormattedDate(txtDate: txt1, isMin: false)
                } else {
                    date2 = decodeFormattedDate(txtDate: txt2, isMin: false)
                }
            }
        }
        if date1 > date2 {
            errMsg = "The 2nd date can't be earlier than the 1st date."
        }
        return(date1,txt1,date2,txt2,errMsg)
    }

    //---- formatDateField - Returns a properly formatted Date.stringValue
    static func formatDateField(txtField: String) -> String {
        var dateStr = ""
        let da = txtField.trim

        if da.isEmpty || da.contains("?") {
            return da                       // Go back where you came from
        }

        if da.count == 4 {            // YYYY
            if let val = Int(da) {
                if val >= 1900 && val <= 2999 {
                    return da
                } else {
                    return "?" + da + "?"
                }
            }
        }

        let parts: [String]
        var yyyy = "????"
        var mm = "??"
        var dd = "??"

        if da.contains("/") {
            parts = da.components(separatedBy: "/") //
            mm = parts[0].trim
            if parts.count >= 3 {
                yyyy = parts[2].trim                // mm/dd/yyyy
                dd = parts[1].trim
            } else {
                yyyy = parts[1].trim                // mm/yyyy
            }
        } else if da.contains("-") {
            parts = da.components(separatedBy: "-")
            yyyy = parts[0].trim
            mm   = parts[1].trim
            if parts.count >= 3  {
                dd = parts[2]
            }
            dateStr = da
        } else {
            return "?" + da + "?"
        }
        if yyyy.count <= 2 { yyyy = "20" + yyyy }   // "17" -> "2017"
        if mm.count < 2 { mm = "0" + mm }           //  "5" -> "05"
        if dd.count < 2 { dd = "0" + dd }           //  "5" -> "05"

        var isOK = true

        if let year = Int(yyyy) {
            if year < 1929 || year > 2999 { isOK = false }  // Year out-of-range
        } else {
            isOK = false                                    // Year corrupt
        }

        if let mon = Int(mm) {
            if mon < 1 || mon > 12 { isOK = false }         // Month out-of-range
        } else {
            isOK = false                                    // Month corrupt
        }

        if dd == "??" {
            dateStr = "\(yyyy)-\(mm)"                       // YYYY-MM
        } else {
            if let day = Int(dd) {
                if day < 1 || day > 31 { isOK = false }     // Day out-of-range
            } else {
                isOK = false                                // Day corrupt
            }
            dateStr = "\(yyyy)-\(mm)-\(dd)"                 // YYYY-MM-DD
        }
        if !isOK { dateStr = "?" + da + "?" }               // "?OriginalText?"
        return dateStr
    }

    // Decode formatted date (YYYY, YYYY-MM, YYYY-MM-DD) - Returns "" if txtDate.isEmpty
    static func decodeFormattedDate(txtDate: String, isMin: Bool) -> String {
        var txt = txtDate.trim
        if txt.isEmpty {
            return "1900-01-01"
        }

        if txt.count == 10 && txt[4] == "-" && txt[7] == "-" {    // YYYY-MM-DD
            return txt
        } else if txt.count == 7 && txt[4] == "-" {    // YYYY-MM
            if isMin {
                txt += "-01"
            } else {
                txt += "-31"
            }
        } else if txt.count == 4 {                  // YYYY
            if isMin {
                txt += "-01-01"
            } else {
                txt += "-12-31"
            }
        } else {
            txt = "?"
        }
        return txt

    }//end func


    //---- TableFilter.apply - Returns true if lineItem meets all the filter criteria
     func apply(lineItem: LineItem) -> Bool {
        if lineItem.credit + lineItem.debit < dollarVal1                { return false }
        if lineItem.credit + lineItem.debit > dollarVal2                { return false }

        if !date1.isEmpty {
            if lineItem.tranDate < date1                                { return false }
            if lineItem.tranDate > date2                                { return false }
        }
        if !lineItem.descKey.hasPrefix(vendor.uppercased())             { return false }
        if !lineItem.cardType.hasPrefix(cardType.uppercased())          { return false }
        if !lineItem.genCat.uppercased().hasPrefix(category.uppercased()) { return false }
        return true
    }


}//end struct TableFilter
