//
//  SummaryTableVC.swift
//  Credit Cards
//
//  Created by George Bauer on 10/7/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Cocoa

class SummaryTableVC: NSViewController, NSWindowDelegate {

    enum SummarizeBy {
        case none, category, subCategory, vendor, cardType, month, quarter
    }

    var summarizeBy = SummarizeBy.category
    let codeFile    = "SummaryTableVC"
    var tableDicts  = [[String : String]]()    // Array of Dictionaries
    var iSortBy     = ColID.debit
    var totalCredit = 0.0
    var totalDebit  = 0.0
    var iAscending  = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        radioCategory.state = .on
        loadTableSortDescriptors()
        loadTable(lineItemArray: gFilteredLineItemArray, summarizeBy : .category)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window!.delegate = self
        reloadTable(sortBy: iSortBy, ascending: iAscending)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        print("✅ windowShouldClose")
        NSApplication.shared.stopModal()
        return true
    }

    //MARK:- IBOutlets

    @IBOutlet var radioCategory:    NSButton!
    @IBOutlet var radioVendor:      NSButton!
    @IBOutlet var radioCardType:    NSButton!
    @IBOutlet var radioMonth:       NSButton!
    @IBOutlet var tableView:     NSTableView!
    
    //MARK:- IBActions

    @IBAction func radioCatChange(_ sender: Any) {
        if radioCategory.state == .on {
            summarizeBy = .category

        } else if radioVendor.state == .on {
            summarizeBy = .vendor

        } else if radioCardType.state == .on {
            summarizeBy = .cardType

        } else if radioMonth.state == .on {
            summarizeBy = .month

        } else {
            summarizeBy = .none
        }
        loadTable(lineItemArray: gFilteredLineItemArray, summarizeBy : summarizeBy)
    }

    //MARK:- Regular funcs

    //---- loadTableSortDescriptors - for column-based sort - Modifies tableView, colWidDict
    private func loadTableSortDescriptors() {
        for column in tableView.tableColumns {
            let key = column.identifier.rawValue
            let ascending: Bool
            ascending = (key == ColID.name) // ascending for cardType; descending for the rest.
            let sortDescriptor  = NSSortDescriptor(key: key,  ascending: ascending)
            column.sortDescriptorPrototype = sortDescriptor
        }
    }//end func

    //---- loadTable - Select stocks to be displayed & Create tableDicts array. Also fill "Totals" labels.
    private func loadTable(lineItemArray: [LineItem], summarizeBy : SummarizeBy) {  // 88-127 = 39-lines

        let sortedLineItemArray = lineItemArray.sorted(by: { compareST(lft: $0, rgt: $1, summarizeBy: summarizeBy) })  //**

        tableDicts  = []
        if lineItemArray.isEmpty { return }

        // Column Totals
        totalCredit = 0
        totalDebit  = 0

        var namedCount  = 0
        var namedCredit = 0.0
        var namedDebit  = 0.0
        var oldName = ""
        for i in 0..<sortedLineItemArray.count {
            let lineItem = sortedLineItemArray[i]
            let newName = summarizeName(lineItem: lineItem, summarizeBy: summarizeBy) //**
            if newName == oldName {         // Still working on oldName
                namedCount  += 1            //      so add to totals
                namedDebit  += lineItem.debit
                namedCredit += lineItem.credit
            } else {
                appendToTableDicts(name: oldName, count: namedCount, credit: namedCredit, debit: namedDebit)
                namedCount  = 1
                namedCredit = lineItem.credit
                namedDebit  = lineItem.debit
                oldName     = newName
            }
            totalCredit += lineItem.credit
            totalDebit  += lineItem.debit
        }//next
        appendToTableDicts(name: oldName, count: namedCount, credit: namedCredit, debit: namedDebit)

        //tableDicts = tableDicts.sorted(by: { $0[ColID.debit]! > $1[ColID.debit]! })
        let sortBy = iSortBy
        tableDicts.sort { compareTextNum(lft: $0[sortBy]!, rgt: $1[sortBy]!, ascending: false) }

        tableView.reloadData()
    }//end func loadTable

    //**
    func compareST(lft: LineItem, rgt: LineItem, summarizeBy: SummarizeBy) -> Bool {
        switch summarizeBy {
        case .category:
            return lft.genCat   < rgt.genCat
        case .cardType:
            return lft.cardType < rgt.cardType
        case .vendor:
            return lft.descKey  < rgt.descKey
        case .month:
            return makeYYYYMMDD(dateTxt: lft.tranDate)  < makeYYYYMMDD(dateTxt: rgt.tranDate)
        default:
            return false
        }
    }

    func summarizeName(lineItem: LineItem, summarizeBy: SummarizeBy) -> String {
        switch summarizeBy {
        case .category:
            return lineItem.genCat
        case .cardType:
            return lineItem.cardType
        case .vendor:
            return lineItem.descKey
        case .month:
            return String(makeYYYYMMDD(dateTxt: lineItem.tranDate).prefix(7))
        default:
            return "?name?"
        }
    }

    //---- reloadTable - reloads the table for tableDicts, sorted by ColID
    private func reloadTable(sortBy: String, ascending: Bool) {
        tableDicts.sort { compareTextNum(lft: $0[sortBy]!, rgt: $1[sortBy]!, ascending: ascending) }
        tableView.reloadData()
        iSortBy    = sortBy         // Remember Sort order
        iAscending = ascending
    }

    //---- makeRowDict - Create a dictionary entry for loadTable & appends to tableDicts
    private func appendToTableDicts(name: String, count: Int, credit: Double, debit: Double) {
        if !name.isEmpty {
            let strCredit = formatCell(credit, formatType: .Dollar,  digits: 2)
            let strDebit  = formatCell(debit,  formatType: .Dollar,  digits: 2)
            let dict      = [ColID.name: name, ColID.count: String(count), ColID.debit: strDebit, ColID.credit: strCredit]
            tableDicts.append(dict)
        }
    }// end func

    fileprivate enum ColID: CaseIterable {
        static let name     = "Name"
        static let count    = "Count"
        static let debit    = "Debit"
        static let credit   = "Credit"
    }

}//end class

//MARK:- NSTableViewDataSource

extension SummaryTableVC: NSTableViewDataSource {

    //---- numberOfRows -
    func numberOfRows(in tableView: NSTableView) -> Int {
        print("tableDicts.count = \(tableDicts.count)")
        return tableDicts.count
    }

    //---- tableView sortDescriptorsDidChange - Column SORT
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        guard let sortDescriptor = tableView.sortDescriptors.first else { return }
        //print("⬆️\(sortDescriptor.key!) \(sortDescriptor.ascending)")
        reloadTable(sortBy: sortDescriptor.key!, ascending: sortDescriptor.ascending)
    }

}//end extension

//MARK:- NSTableViewDelegate

extension SummaryTableVC: NSTableViewDelegate {

    //---- tableView viewFor - Creates each Cell when called by tableView
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        let dict = tableDicts[row]
        //var image: NSImage?

        guard let colID = tableColumn?.identifier.rawValue else { print("⛔️ Table Column nil"); return nil }
        guard let text = dict[colID] else {
            print("⛔️ \(codeFile)#\(#line) No Value found for \(colID)")
            return nil
        }
        let cellIdentifier = colID

        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            //cell.imageView?.image = image ?? nil
            return cell
        }
        return nil
    }//end func

}//end extension
