//
//  SpreadsheetVC.swift
//  Credit Cards
//
//  Created by George Bauer on 10/2/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Cocoa

var gLineItemArray   = [LineItem]()

class SpreadsheetVC: NSViewController, NSWindowDelegate {

    //  class TableVC: NSViewController, NSWindowDelegate {

    //MARK: Instance Variables
    let codeFile = "SpreadsheetVC"
    var tableDicts   = [[String : String]]()    // Array of Dictionaries
    var tableSumDict = [String : String]()      // Sumation Dictionary
    var totalCredit = 0.0
    var totalDebit  = 0.0
    var iSortBy     = ColID.cardType
    var iAscending  = true
    var colWidDict  = [String : CGFloat]()
    var filtDate1   = "2999-12-31"
    var filtDate2   = "0000-00-00"
    var filtDollar1 = 9999999.0
    var filtDollar2 = 0.0
    var filtCardTyp = ""
    var filtCategor = ""
    var filtVendor  = ""


    //MARK:- IBOutlets

    @IBOutlet weak var tableView:    NSTableView!
    @IBOutlet weak var tableViewSum: NSTableView!
    @IBOutlet weak var chkShowAll: NSButton!
    @IBOutlet weak var lblStatus:  NSTextField!


    @IBOutlet var txtDate1:     NSTextField!
    @IBOutlet var txtDate2:     NSTextField!
    @IBOutlet var txtDollar1:   NSTextField!
    @IBOutlet var txtDollar2:   NSTextField!
    @IBOutlet var txtCardType:  NSTextField!
    @IBOutlet var txtCategory:  NSTextField!
    @IBOutlet var txtVendor:       NSTextField!


    //MARK:- Lifecycle funcs

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        //tableView.delegate   = self       // Done in IB (ctl-Drag Table to VC Icon)
        //tableView.dataSource = self       // Done in IB
        getMinMax(lineItemArray: gLineItemArray)
        loadTable(lineItemArray: gLineItemArray)
        tableView.target = self
        tableView.doubleAction = #selector(tableViewDoubleClick(_:))

        loadTableSortDescriptors()
        syncColWidths()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window!.delegate = self
        reloadTable(sortBy: iSortBy, ascending: iAscending)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        print("✅ windowShouldClose")
        let application = NSApplication.shared
        application.stopModal()
        //dismiss(self) //does not work
        return true
    }

    //MARK:- IBActions

    @IBAction func btnFilter(_ sender: Any) {
        if setFilter() {
            loadTable(lineItemArray: gLineItemArray)
            tableView.reloadData()
            tableViewSum.reloadData()
        } else {
            let msg = "Error in Filter item"
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .alert, errorMsg: msg)
        }

    }

    // Not used
    @IBAction func chkShowAllChanged(_ sender: Any) {  // Handles chkShowAll.CheckedChanged
        loadTable(lineItemArray: gLineItemArray)
        reloadTable(sortBy: iSortBy, ascending: iAscending)
    }//end func

    //MARK:- Regular funcs

    //---- loadTableSortDescriptors - for column-based sort - Modifies tableView, colWidDict
    func loadTableSortDescriptors() {
        colWidDict.removeAll()
        for column in tableView.tableColumns {
            let key = column.identifier.rawValue
            let ascending: Bool
            ascending = (key == ColID.cardType) // ascending for cardType; descending for the rest.
            let sortDescriptor  = NSSortDescriptor(key: key,  ascending: ascending)
            column.sortDescriptorPrototype = sortDescriptor
            colWidDict[key] = column.width
        }
    }//end func

    //- not used --- syncColWidths - Make Summary Column widths = Main Column widths
    func syncColWidths() {
        for (idx, column) in tableView.tableColumns.enumerated() {
            tableViewSum.tableColumns[idx].width = column.width
        }
    }

    private func getMinMax(lineItemArray: [LineItem]) {
        for lineItem in lineItemArray {
            let dollar = lineItem.credit + lineItem.debit
            if dollar > 0.0 {
                if dollar < filtDollar1 { filtDollar1 = dollar }
                if dollar > filtDollar2 { filtDollar2 = dollar }
            }

            let date = makeYYYYMMDD(dateTxt: lineItem.tranDate)
            if date < filtDate1 { filtDate1 = date }
            if date > filtDate2 { filtDate2 = date }
        }//next
        txtDollar1.stringValue = String(format: "%.2f", filtDollar1)
        txtDollar2.stringValue = String(format: "%.2f", filtDollar2)
        txtDate1.stringValue = filtDate1
        txtDate2.stringValue = filtDate2
    }//end func

    //---- loadTable - Select stocks to be displayed & Create tableDicts array. Also fill "Totals" labels.
    private func loadTable(lineItemArray: [LineItem]) {  // 97-133 = 36-lines
        var sumLine = LineItem()
        tableDicts   = []
        tableSumDict.removeAll()
        if lineItemArray.isEmpty { return }

        // Column Totals
        totalCredit = 0
        totalDebit  = 0

        for lineItem in lineItemArray {
            if applyFilter(lineItem: lineItem) {
                let dict = makeRowDict(lineItem: lineItem)
                tableDicts.append(dict)
                totalCredit += lineItem.credit
                totalDebit  += lineItem.debit
            }
        }//next

        // Display Total and Averages

        sumLine.credit = totalCredit
        sumLine.debit  = totalDebit

        tableSumDict = makeRowDict(lineItem: sumLine)

    }//end func loadTable

    private func setFilter() -> Bool {
        filtDate1 = makeYYYYMMDD(dateTxt: txtDate1.stringValue)
        filtDate2 = makeYYYYMMDD(dateTxt: txtDate2.stringValue)
        filtDollar1 = Double(txtDollar1.stringValue) ?? -1
        filtDollar2 = Double(txtDollar2.stringValue) ?? -1
        if !filtDate1.hasPrefix("20") || !filtDate2.hasPrefix("20") { return false }
        if filtDollar1 < 0 || filtDollar2 < 0 { return false }
        return true
    }

    private func applyFilter(lineItem: LineItem) -> Bool {
        if lineItem.credit + lineItem.debit < filtDollar1 { return false }
        if lineItem.credit + lineItem.debit > filtDollar2 { return false }
        let tranDate = makeYYYYMMDD(dateTxt: lineItem.tranDate)
        if tranDate < filtDate1 { return false }
        if tranDate > filtDate2 { return false }
        if !lineItem.descKey.hasPrefix(txtVendor.stringValue.uppercased())          { return false }
        if !lineItem.cardType.hasPrefix(txtCardType.stringValue.uppercased())       { return false }
        if !lineItem.genCat.uppercased().hasPrefix(txtCategory.stringValue.uppercased()) { return false }
        return true
    }
    //---- makeRowDict - Create a dictionary entry for loadTable
    func makeRowDict(lineItem: LineItem) -> [String : String] { // 136-161 = 25-lines
        var dict = [String : String]()

        dict[ColID.cardType]    = lineItem.cardType
        dict[ColID.transDate]   = makeYYYYMMDD(dateTxt: lineItem.tranDate)
        dict[ColID.descKey]     = lineItem.descKey
        dict[ColID.fullDesc]    = lineItem.desc
        dict[ColID.debit]       = formatCell(lineItem.debit,  formatType: .Dollar,  digits: 2)
        dict[ColID.credit]      = formatCell(lineItem.credit, formatType: .Dollar,  digits: 2)
        dict[ColID.category]    = lineItem.genCat
        dict[ColID.rawCat]      = lineItem.rawCat
        dict[ColID.catSource]   = lineItem.catSource
        dict[ColID.file_LineNum] = lineItem.auditTrail
        return dict
    }// end func

    //---- reloadTable - reloads the table for tableDicts, sorted by ColID
    private func reloadTable(sortBy: String, ascending: Bool) {
        tableDicts.sort { compare(lft: $0[sortBy]!, rgt: $1[sortBy]!, ascending: ascending) }
        tableView.reloadData()
        tableViewSum.reloadData()   // Not always needed
        iSortBy    = sortBy         // Remember Sort order
        iAscending = ascending
    }

    //---- compare - compares 2 strings either numerically or case-insensitive.
    private func compare(lft: String, rgt: String, ascending: Bool) -> Bool {
        let lStripped = sortStr(lft)
        let rStripped = sortStr(rgt)
        if Double(lStripped) == nil || Double(rStripped) == nil {
            if ascending  && lft < rgt { return true }
            if !ascending && lft > rgt { return true }
            return false
        }
        let lVal = Double(lStripped) ?? 0
        let rVal = Double(rStripped) ?? 0
        if ascending  && lVal < rVal { return true }
        if !ascending && lVal > rVal { return true }
        return false
    }

    //---- sortStr - returns a string that is sortable, either numerically or case-insensitive.
    private func sortStr(_ str: String) -> String {
        var txt = str
        txt = txt.replacingOccurrences(of: "$", with: "")
        txt = txt.replacingOccurrences(of: "%", with: "")
        txt = txt.replacingOccurrences(of: ",", with: "").trim
        if txt.hasPrefix("(") && txt.hasSuffix(")") { txt = "-" + String(txt.dropFirst().dropLast()) }
        return txt.uppercased()
    }

    //---- updateCompanyNameLabel - Update lblStatus with selected TransDate Name
    func updateCompanyNameLabel() {
        let text: String
        let itemsSelected = tableView.selectedRowIndexes.count

        switch itemsSelected {
        case 0:
            text = "No Selection"
        case 1:
            let stockDict = tableDicts[tableView.selectedRowIndexes.first!]
            let symbTxt = stockDict[ColID.cardType]  ?? "Missing cardType"
            let nameTxt = stockDict[ColID.transDate] ?? "Missing TransDate Name"
            text = "\(symbTxt)   \(nameTxt)"
        default:
            text = "Multiple Selections"
        }//end switch

        //lblStatus.stringValue = text
    }//end func

    public enum FormatType {
        case None, Number, Percent, Dollar, NoDollar, Comma
    }
    //---- formatCell -
    public func formatCell(_ value: Double,formatType: FormatType, digits: Int,
                           onlyIf: Bool = true, emptyCell: String = "") -> String {
        if !onlyIf { return emptyCell }
        var format = ""
        switch formatType {
        case .Number:                                       // -1234.5
            format = "%.\(digits)f"   // "%.2f%" -> "#.00"
            return String(format: format, value)
        case .Percent:                                      // -123.4%
            format = "%.\(digits)f%%" // "%.1f%%" -> "#.0%"
            return String(format: format, value*100)
        case .Dollar:                                       // ($1,234.5)
            if value == 0 { return "" }
            let formatter = NumberFormatter()
            formatter.numberStyle  = .currencyAccounting
            formatter.maximumFractionDigits = digits
            return formatter.string(for: value) ?? "?Dollar?"
        case .NoDollar:                                     // (1,234.5)
            let formatter = NumberFormatter()
            formatter.numberStyle  = .currencyAccounting
            formatter.maximumFractionDigits = digits
            let str = formatter.string(for: value) ?? "$?Dollar?"
            let str2 = String(str.dropFirst())
            return str2
        case .Comma:                                        // -1,234.5
            let formatter = NumberFormatter()
            formatter.numberStyle  = .decimal
            formatter.maximumFractionDigits = digits
            return formatter.string(for: value) ?? "?Comma?"
        default:
            return "\(value)"                               // -1234.567
        }

    }//end func

}//end class

//              Name        ID          Width   Col#    Totals
fileprivate enum ColID: CaseIterable {
    static let cardType     = "CardType"            // 60    0      -
    static let transDate    = "TransDate"           // --   --
    static let descKey      = "DescKey"             // 60    1
    static let fullDesc     = "Full Description"    // 70    2
    static let debit        = "Debit"               // 60    3
    static let credit       = "Credit"              // 60    4
    static let category     = "Category"            // 70    5
    static let rawCat       = "Raw Category"        // 60    6
    static let catSource    = "Category Source"     // 60    7
    static let file_LineNum = "File/LineNumber"     // 90    8
}

//MARK:- NSTableViewDataSource

extension SpreadsheetVC: NSTableViewDataSource {

    //---- numberOfRows -
    func numberOfRows(in tableView: NSTableView) -> Int {
        print("tableDicts.count = \(tableDicts.count)")
        if tableView == self.tableView {
            return tableDicts.count
        }
        if tableView == self.tableViewSum {
            return 1
        }
        return 0
    }

    //---- tableView sortDescriptorsDidChange - Column SORT
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        if tableView == self.tableView {
            guard let sortDescriptor = tableView.sortDescriptors.first else { return }
            //print("⬆️\(sortDescriptor.key!) \(sortDescriptor.ascending)")
            reloadTable(sortBy: sortDescriptor.key!, ascending: sortDescriptor.ascending)
        }
    }

}//end extension

//MARK:- NSTableViewDelegate

extension SpreadsheetVC: NSTableViewDelegate {

    //---- tableView viewFor - Creates each Cell when called by tableView
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        // Main table
        if tableView == self.tableView {
            let dict = tableDicts[row]
            //var image: NSImage?

            guard let colID = tableColumn?.identifier.rawValue else { print("⛔️ Table Column nil"); return nil }
            guard let text = dict[colID] else {
                print("⛔️ No Value found for \(colID)")
                return nil
            }
            let cellIdentifier = colID

            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
                cell.textField?.stringValue = text
                //cell.imageView?.image = image ?? nil
                return cell
            }
        }//tableView

        // Summary (Totals) table
        if tableView == self.tableViewSum {
            guard let colID = tableColumn?.identifier.rawValue else { print("⛔️ Table Column nil"); return nil }
            guard let text = tableSumDict[colID] else {
                print("⛔️ No Value found for \(colID)")
                return nil
            }
            let cellIdentifier = colID
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
                cell.textField?.stringValue = text
                return cell
            }
        }//tableViewSum

        return nil
    }//end func


    //---- tableViewSelectionDidChange -
    func tableViewSelectionDidChange(_ notification: Notification){
        if tableView == self.tableView {
            updateCompanyNameLabel()
        }//tableView
    }

    func tableViewColumnDidMove(_ notification: Notification) {
        if notification.object as? NSTableView == self.tableView {
            print("tableViewColumnDidMove")
            guard let oldIdx = notification.userInfo!["NSOldColumn"] as? Int else { return }
            guard let newIdx = notification.userInfo!["NSNewColumn"] as? Int else { return }
            //let column = tableView.tableColumns[newIdx]
            //let title = column.title
            print("Moved \(tableView.tableColumns[newIdx].title) from pos#\(oldIdx) to pos#\(newIdx)")
            tableViewSum.moveColumn(oldIdx, toColumn: newIdx)
        }//tableView
    }

    //---- tableViewColumnDidResize - When user resizes a column, also resize the totals column.
    func tableViewColumnDidResize(_ notification: Notification) {
        //notification.debugDescription
        if notification.object as? NSTableView == self.tableView {
            let column = notification.userInfo!["NSTableColumn"] as! NSTableColumn
            let id = column.identifier
            let idx = tableView.column(withIdentifier: id)
            print("↔️ tableViewColumnDidResize Col#\(idx): \(id.rawValue) to a width of \(column.width)")
            tableViewSum.tableColumns[idx].width = column.width
        }//tableView
    }

    //---- tableViewDoubleClick - Detected doubleClick
    //viewDidLoad has tableView.target = self
    // & tableView.doubleAction = #selector(tableViewDoubleClick(_:))
    @objc func tableViewDoubleClick(_ sender:AnyObject) {
        // 1
        guard tableView.selectedRow >= 0 else { return }
        print("DoubleClicked on Row # \(tableView.selectedRow)")
    }//end func

}//end extension
