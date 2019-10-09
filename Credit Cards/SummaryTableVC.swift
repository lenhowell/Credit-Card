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
        case none, category, vendor, cardType, month
    }

    var summarizeBy = SummarizeBy.category
    let codeFile    = "SummaryTableVC"
    var tableDicts   = [[String : String]]()    // Array of Dictionaries
    var totalCredit = 0.0
    var totalDebit  = 0.0
    //var iSortBy     = ColID.cardType
    var iAscending  = true

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        radioCategory.state = .on
        loadTable(lineItemArray: gFilteredLineItemArray, summarizeBy : .category)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window!.delegate = self
        //reloadTable(sortBy: iSortBy, ascending: iAscending)
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
    @IBOutlet var tableView:    NSTableView!
    
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
        //updateAfterCatChange(sortBy: sortBy)
    }

    //MARK:- Regular funcs

    //---- loadTable - Select stocks to be displayed & Create tableDicts array. Also fill "Totals" labels.
    private func loadTable(lineItemArray: [LineItem], summarizeBy : SummarizeBy) {  // 97-133 = 36-lines
        let sortedLineItemArray = lineItemArray.sorted(by:{$0.genCat < $1.genCat})
        tableDicts  = []
        if lineItemArray.isEmpty { return }

        // Column Totals
        totalCredit = 0
        totalDebit  = 0

        var namedCount  = 0
        var namedCredit = 0.0
        var namedDebit  = 0.0
        var oldName = ""
        for lineItem in sortedLineItemArray {
            if lineItem.genCat == oldName {
                namedCount  += 1
                namedDebit  += lineItem.debit
                namedCredit += lineItem.credit
            } else {
                let name = oldName
                oldName = lineItem.genCat
                let strCredit = formatCell(namedCredit, formatType: .Dollar,  digits: 2)
                let strDebit  = formatCell(namedDebit,  formatType: .Dollar,  digits: 2)
                let dict = [ColID.name: name, ColID.count: String(namedCount), ColID.debit: strDebit, ColID.credit: strCredit]
                namedCount  = 0
                namedCredit = 0.0
                namedDebit  = 0.0
                tableDicts.append(dict)
                totalCredit += lineItem.credit
                totalDebit  += lineItem.debit
            }
        }//next
        //tableDicts = tableDicts.sorted(by: { $0[ColID.debit]! > $1[ColID.debit]! })
        let sortBy = ColID.debit
        tableDicts.sort { compareTextNum(lft: $0[sortBy]!, rgt: $1[sortBy]!, ascending: false) }

        tableView.reloadData()
    }//end func loadTable


//---- makeRowDict - Create a dictionary entry for loadTable
func makeRowDicts(lineItem: LineItem) -> [String : String] { // 136-161 = 25-lines
    var dict = [String : String]()
    dict[ColID.name]    = lineItem.genCat

    return dict
}// end func

}//end class

//              Name        ID          Width   Col#    Totals
fileprivate enum ColID: CaseIterable {
    static let name     = "Name"
    static let count    = "Count"
    static let debit    = "Debit"
    static let credit   = "Credit"
}


//MARK:- NSTableViewDataSource

extension SummaryTableVC: NSTableViewDataSource {

    //---- numberOfRows -
    func numberOfRows(in tableView: NSTableView) -> Int {
        print("tableDicts.count = \(tableDicts.count)")
        return tableDicts.count
    }

//    //---- tableView sortDescriptorsDidChange - Column SORT
//    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
//            guard let sortDescriptor = tableView.sortDescriptors.first else { return }
//            //print("⬆️\(sortDescriptor.key!) \(sortDescriptor.ascending)")
//            reloadTable(sortBy: sortDescriptor.key!, ascending: sortDescriptor.ascending)
//    }

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
