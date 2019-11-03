//
//  SpreadsheetVC.swift
//  Credit Cards
//
//  Created by George Bauer on 10/2/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Cocoa

class SpreadsheetVC: NSViewController, NSWindowDelegate {

    //MARK: Instance Variables
    let codeFile    = "SpreadsheetVC"
    var filteredLineItemArray = [LineItem]()  // Filtered list of transactions - used in SummaryTableVC
    var tableDicts  = [[String : String]]()     // Array of Dictionaries
    var tableSumDict = [String : String]()      // Totals Dictionary
    var totalCredit = 0.0
    var totalDebit  = 0.0
    var iSortBy     = SpSheetColID.cardType
    var iAscending  = true
    var colWidDict  = [String : CGFloat]()

    var filtDate1   = ""
    var filtDate2   = ""
    var filtDollarVal1 = 0.0
    var filtDollarVal2 = kMaxDollar
    var filtCardTyp = ""
    var filtCategor = ""
    var filtVendor  = ""


    //MARK:- IBOutlets

    @IBOutlet var tableView:    NSTableView!
    @IBOutlet var tableViewSum: NSTableView!
    @IBOutlet var btnFilter:    NSButton!
    @IBOutlet var btnClear:     NSButton!
    @IBOutlet var btnSummary:   NSButton!
    @IBOutlet var lblStatus:    NSTextField!

    @IBOutlet var txtDate1:     NSTextField!
    @IBOutlet var txtDate2:     NSTextField!
    @IBOutlet var txtDollar1:   NSTextField!
    @IBOutlet var txtDollar2:   NSTextField!
    @IBOutlet var txtCardType:  NSTextField!
    @IBOutlet var txtCategory:  NSTextField!
    @IBOutlet var txtVendor:    NSTextField!


    //MARK:- Lifecycle funcs

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        //tableView.delegate   = self       // Done in IB (ctl-Drag Table to VC Icon)
        //tableView.dataSource = self       // Done in IB

        // Set txtTransationFolder.delegate
        txtDate1.delegate    = self // Allow ViewController to see when txtDate1 changes.
        txtDate2.delegate    = self // Allow ViewController to see when txtDate2 changes.
        txtDollar1.delegate  = self // Allow ViewController to see when txtDollar1 changes.
        txtDollar2.delegate  = self // Allow ViewController to see when txtDollar2 changes.
        txtCardType.delegate = self // Allow ViewController to see when txtCardType changes.
        txtCategory.delegate = self // Allow ViewController to see when txtCategory changes.
        txtVendor.delegate   = self // Allow ViewController to see when txtVendor changes.

        loadStuffFromCaller(summaryData: gPassToNextTable)
        loadTableDictsArray(lineItemArray: gLineItemArray)

        tableView.target = self
        tableView.doubleAction = #selector(tableViewDoubleClick(_:))

        loadTableSortDescriptors()
        syncColWidths()

        btnClear.isEnabled = false
    }//end func viewDidLoad

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window!.delegate = self
        reloadTableSorted(sortBy: iSortBy, ascending: iAscending)
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
            btnFilter.keyEquivalent = ""
            loadTableDictsArray(lineItemArray: gLineItemArray)
            reloadTableSorted(sortBy: iSortBy, ascending: iAscending)
            tableViewSum.reloadData()
        } else {
            let msg = "Error in Filter item"
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .alert, errorMsg: msg)
        }
    }

    @IBAction func btnClear(_ sender: Any) {
        txtDate1.stringValue    = ""
        txtDate2.stringValue    = ""
        txtDollar1.stringValue  = ""
        txtDollar2.stringValue  = ""
        txtCardType.stringValue = ""
        txtCategory.stringValue = ""
        txtVendor.stringValue   = ""
        if setFilter() {
            loadTableDictsArray(lineItemArray: gLineItemArray)
            reloadTableSorted(sortBy: iSortBy, ascending: iAscending)
            tableViewSum.reloadData()
            btnClear.isEnabled = false
        }
    }

    @IBAction func btnSummaries(_ sender: Any) {
        gPassToNextTable = TableParams(filtDate1: txtDate1.stringValue,
                                       filtDate2: txtDate2.stringValue,
                                       filtDolStr1: txtDollar1.stringValue,
                                       filtDolStr2: txtDollar2.stringValue,
                                       filtCardTyp: txtCardType.stringValue,
                                       filtCategor: txtCategory.stringValue,
                                       filtVendor: txtVendor.stringValue,
                                       calledBy: TableCalledBy.spreadsheet,
                                       summarizeBy: SummarizeBy.groupCategory,
                                       sortBy: SortDirective(column: SummaryColID.netDebit, ascending: false))

        let storyBoard = NSStoryboard(name: "SummaryTable", bundle: nil)
        let summaryWindowController = storyBoard.instantiateController(withIdentifier: "SummaryWindowController") as! NSWindowController
        if let summaryWindow = summaryWindowController.window {
            //let summaryTableVC = storyBoard.instantiateController(withIdentifier: "SummaryTableVC") as! SummaryTableVC
            print("btnSummaries", gPassToNextTable)
            let application = NSApplication.shared
            _ = application.runModal(for: summaryWindow) // <=================  UserInputVC

            summaryWindow.close()                     // Return here from userInputWindow
        }
    }

    // Not used
    @IBAction func chkShowAllChanged(_ sender: Any) {  // Handles chkShowAll.CheckedChanged
        loadTableDictsArray(lineItemArray: gLineItemArray)
        reloadTableSorted(sortBy: iSortBy, ascending: iAscending)
    }//end func

    //MARK:- Regular funcs

    private func loadStuffFromCaller(summaryData: TableParams) {
        print("loadStuffFromCaller", summaryData)
        //calledBy                = summaryData.calledBy
        if summaryData.calledBy == .main {
            btnSummary.isHidden = false
        } else {
            btnSummary.isHidden = true
        }
        iSortBy                 = summaryData.sortBy.column
        iAscending              = summaryData.sortBy.ascending
        txtVendor.stringValue   = summaryData.filtVendor
        txtCategory.stringValue = summaryData.filtCategor
        txtCardType.stringValue = summaryData.filtCardTyp
        txtDate1.stringValue    = summaryData.filtDate1
        txtDate2.stringValue    = summaryData.filtDate2
        txtDollar1.stringValue  = summaryData.filtDolStr1
        txtDollar2.stringValue  = summaryData.filtDolStr2


        //loadTableDictsArray(lineItemArray: filteredLineItemArray, summarizeBy : summarizeBy)
    }


    //---- loadTableSortDescriptors - for column-based sort - Modifies tableView, colWidDict: called by viewDidLoad
    internal func loadTableSortDescriptors() {
        colWidDict.removeAll()
        for column in tableView.tableColumns {
            let key = column.identifier.rawValue
            let ascending: Bool
            ascending = (key == SpSheetColID.cardType) // ascending for cardType; descending for the rest.
            let sortDescriptor  = NSSortDescriptor(key: key,  ascending: ascending)
            print("⬆️ sortDescriptor key: \(sortDescriptor.key!)   ascending: \(sortDescriptor.ascending)")
            column.sortDescriptorPrototype = sortDescriptor
            colWidDict[key] = column.width
        }
    }//end func

    //---- syncColWidths - Make Summary Column widths = Main Column widths: called by viewDidLoad
    private func syncColWidths() {
        for (idx, column) in tableView.tableColumns.enumerated() {
            tableViewSum.tableColumns[idx].width = column.width
        }
    }

    //---- getMinMax - Sets filtDollarX, txtDollarX, filtDateX, txtDateX: called by viewDidLoad
    private func getMinMax(lineItemArray: [LineItem]) {
        for lineItem in lineItemArray {
            let dollar = lineItem.credit + lineItem.debit

            if dollar < filtDollarVal1 { filtDollarVal1 = dollar }
            if dollar > filtDollarVal2 { filtDollarVal2 = dollar }

            let date = makeYYYYMMDD(dateTxt: lineItem.tranDate)
            if date < filtDate1 { filtDate1 = date }
            if date > filtDate2 { filtDate2 = date }
        }//next
        if filtDollarVal1 > 0.001 {
            txtDollar1.stringValue = String(format: "%.2f", filtDollarVal1)
        } else {
            txtDollar1.stringValue = ""
        }
        if filtDollarVal2 < kMaxDollar {
            txtDollar2.stringValue = String(format: "%.2f", filtDollarVal2)
        } else {
            txtDollar2.stringValue = ""
        }
        txtDate1.stringValue = filtDate1
        txtDate2.stringValue = filtDate2
    }//end func

    // is responsible for instance-vbl "filteredLineItemArray"
    //---- loadTableDictsArray - Select stocks to be displayed & Create tableDicts array. Also fill "Totals" labels.
    private func loadTableDictsArray(lineItemArray: [LineItem]) {  // 229-269 = 40-lines
        var sumLine = LineItem()
        tableDicts  = []
        filteredLineItemArray = []
        tableSumDict.removeAll()
        if lineItemArray.isEmpty { return }

        // Column Totals
        totalCredit = 0
        totalDebit  = 0

        for (idx,lineItem) in lineItemArray.enumerated() {
            if applyFilter(lineItem: lineItem) {
                filteredLineItemArray.append(lineItem)
                let dict = makeRowDict(lineItem: lineItem, idx: idx)

                tableDicts.append(dict)
                totalCredit += lineItem.credit
                totalDebit  += lineItem.debit
            } else {
                // debug trap filtered-out lineItem
            }
        }//next

        let totCount = lineItemArray.count
        let filteredCount = filteredLineItemArray.count
        if totCount == filteredCount {
            self.view.window?.title = "Transaction Spreadsheet - \(totCount) rows"
        } else {
            self.view.window?.title = "Transaction Spreadsheet - filtered (\(filteredCount) of \(totCount))"
        }

        // Display Total and Averages

        sumLine.descKey = "\(tableDicts.count) transactions"
        sumLine.credit = totalCredit
        sumLine.debit  = totalDebit

        tableSumDict = makeRowDict(lineItem: sumLine)

    }//end func loadTableDictsArray

    //---- setFilter - Setup the filters based on the textView entries
    private func setFilter() -> Bool {
        filtDate1 = getFilterDate(txtField: txtDate1, isMin: true)
        let date1Count = txtDate1.stringValue.trim.count
        if date1Count >= 4 && date1Count <= 7 && txtDate2.stringValue.trim.isEmpty {
            txtDate2.stringValue = txtDate1.stringValue.trim
        }
        filtDate2 = getFilterDate(txtField: txtDate2, isMin: false)

        if txtDollar1.stringValue.trim.isEmpty {
            filtDollarVal1 = 0.0
        } else {
            filtDollarVal1 = Double(txtDollar1.stringValue) ?? -1
        }
        if txtDollar2.stringValue.trim.isEmpty {
            filtDollarVal2 = kMaxDollar
        } else {
            filtDollarVal2 = Double(txtDollar2.stringValue) ?? -1
        }
        if filtDollarVal1 < 0 || filtDollarVal2 < 0 { return false }
        return true
    }

    private func getFilterDate(txtField: NSTextField, isMin: Bool) -> String {
        var txt = txtField.stringValue.trim
        if txt.count == 6 && txt[4] == "-" {
            txt = txt.prefix(4) + "-0" + txt.suffix(1)
            txtField.stringValue = txt
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

    //---- applyFilter - Returns true if lineItem meets all the filter criteria
    private func applyFilter(lineItem: LineItem) -> Bool {
        if lineItem.credit + lineItem.debit < filtDollarVal1 { return false }
        if lineItem.credit + lineItem.debit > filtDollarVal2 { return false }

        if !filtDate1.isEmpty {
            let tranDate = makeYYYYMMDD(dateTxt: lineItem.tranDate)
            if tranDate < filtDate1 { return false }
            if tranDate > filtDate2 { return false }
        }
        if !lineItem.descKey.hasPrefix(txtVendor.stringValue.uppercased())          { return false }
        if !lineItem.cardType.hasPrefix(txtCardType.stringValue.uppercased())       { return false }
        if !lineItem.genCat.uppercased().hasPrefix(txtCategory.stringValue.uppercased()) { return false }
        return true
    }

    //---- makeRowDict - Create a dictionary entry for loadTableDictsArray
    func makeRowDict(lineItem: LineItem, idx: Int = -1) -> [String : String] {
        var dict = [String : String]()

        dict[SpSheetColID.cardType]    = lineItem.cardType
        dict[SpSheetColID.transDate]   = makeYYYYMMDD(dateTxt: lineItem.tranDate)
        dict[SpSheetColID.descKey]     = lineItem.descKey
        dict[SpSheetColID.fullDesc]    = lineItem.desc
        dict[SpSheetColID.idNumber]    = lineItem.idNumber
        dict[SpSheetColID.debit]       = formatCell(lineItem.debit,  formatType: .dollar,  digits: 2)
        dict[SpSheetColID.credit]      = formatCell(lineItem.credit, formatType: .dollar,  digits: 2)
        dict[SpSheetColID.category]    = lineItem.genCat
        dict[SpSheetColID.rawCat]      = lineItem.rawCat
        dict[SpSheetColID.catSource]   = lineItem.catSource
        dict[SpSheetColID.file_LineNum] = lineItem.auditTrail
        dict["idx"] = String(idx)
        return dict
    }// end func

    //---- reloadTableSorted - reloads the table for tableDicts, sorting by SpSheetColID
    private func reloadTableSorted(sortBy: String, ascending: Bool) {
        tableDicts.sort { compareTextNum(lft: $0[sortBy]!, rgt: $1[sortBy]!, ascending: ascending) }
        tableView.reloadData()
        tableViewSum.reloadData()   // Not always needed
        iSortBy    = sortBy         // Remember Sort order
        iAscending = ascending
    }

}//end class

//              Name        ID          Width   Col#    Totals
public enum SpSheetColID: CaseIterable {
    static let cardType     = "CardType"            // 60    0      -
    static let idNumber     = "Number"
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

//MARK:- NSTextFieldDelegate
// Allow SpreadsheetVC to see when a TextField changes.
extension SpreadsheetVC: NSTextFieldDelegate {

    //---- controlTextDidChange - Called when a textField (with SpreadsheetVC as its delegate) changes.
    func controlTextDidChange(_ obj: Notification) {
        guard let textView = obj.object as? NSTextField else {
            return
        }
        //print("\(codeFile)#\(#line) \(textView.stringValue)")
        btnFilter.keyEquivalent = "\r"
        let allEmpty = txtDate1.stringValue.isEmpty &&
        txtDate2.stringValue.isEmpty &&
        txtDollar1.stringValue.isEmpty &&
        txtDollar2.stringValue.isEmpty &&
        txtCardType.stringValue.isEmpty &&
        txtCategory.stringValue.isEmpty &&
        txtVendor.stringValue.isEmpty
        btnClear.isEnabled = !allEmpty
    }

}//end extension ViewController: NSTextFieldDelegate

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
            print("⬆️ sortDescriptor key: \(sortDescriptor.key!)   ascending: \(sortDescriptor.ascending)")
            reloadTableSorted(sortBy: sortDescriptor.key!, ascending: sortDescriptor.ascending)
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

            guard let colID = tableColumn?.identifier.rawValue else {
                print("⛔️ \(codeFile)#\(#line) Table Column nil")
                return nil
            }
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
        }//tableView

        // Summary (Totals) table
        if tableView == self.tableViewSum {
            guard let colID = tableColumn?.identifier.rawValue else {
                print("⛔️ \(codeFile)#\(#line) Table Column nil")
                return nil
            }
            guard let text = tableSumDict[colID] else {
                print("⛔️ \(codeFile)#\(#line) No Value found for \(colID)")
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


    //---- tableViewSelectionDidChange -  When user selects a row, show data in status bar
    func tableViewSelectionDidChange(_ notification: Notification){
        if tableView == self.tableView {
            if tableView.selectedRow < 0 {
                lblStatus.stringValue = ""
                return
            }
            let iRow = tableView.selectedRow
            let dict = tableDicts[iRow]
            var id = dict[SpSheetColID.idNumber] ?? ""
            if !id.isEmpty { id = "  #" + id + "  " }
            let fileAndLine = (dict[SpSheetColID.file_LineNum] ?? "").replacingOccurrences(of: "#", with: "line#")
            lblStatus.stringValue = "\(iRow+1) \(id)   desc:\"\(dict[SpSheetColID.fullDesc] ?? "")\"     orig.cat:\"\(dict[SpSheetColID.rawCat] ?? "")\"       file:\(fileAndLine)"
            //updateCompanyNameLabel()
        }//tableView
    }

    //---- tableViewColumnDidMove - When user moves a column, also move the "totals" column.
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

    //---- tableViewColumnDidResize - When user resizes a column, also resize the "totals" column.
    func tableViewColumnDidResize(_ notification: Notification) {
        //notification.debugDescription
        if notification.object as? NSTableView == self.tableView {
            let column = notification.userInfo!["NSTableColumn"] as! NSTableColumn
            let id = column.identifier
            let idx = tableView.column(withIdentifier: id)
            //print("↔️ tableViewColumnDidResize Col#\(idx): \(id.rawValue) to a width of \(column.width)")
            tableViewSum.tableColumns[idx].width = column.width
        }//tableView
    }

    //---- tableViewDoubleClick - Detected doubleClick: showUserInputVendorCatForm
    //viewDidLoad has tableView.target = self
    // & tableView.doubleAction = #selector(tableViewDoubleClick(_:))
    @objc func tableViewDoubleClick(_ sender:AnyObject) {
        // 1
        guard tableView.selectedRow >= 0 else { return }
        let rowDict = tableDicts[tableView.selectedRow]
        let idxStr = rowDict["idx"] ?? ""
        let idx = Int(idxStr) ?? -1
        print("DoubleClicked on Row # \(tableView.selectedRow).  idx = \(idx)")
        let lineItem = gLineItemArray[idx]
        print("\(lineItem.tranDate) \(lineItem.descKey) \(lineItem.debit)")
        let catItemFromVendor = CategoryItem(category: lineItem.genCat, source: lineItem.catSource)
        let catItemFromTran   = CategoryItem(category: lineItem.rawCat, source: lineItem.catSource)

        let catItem = showUserInputVendorCatForm(lineItem: lineItem, batchMode: false, catItemFromVendor: catItemFromVendor, catItemFromTran: catItemFromTran, catItemPrefered: catItemFromVendor)
        // ...and we're back.

        gLineItemArray[idx].genCat    = catItem.category
        gLineItemArray[idx].catSource = catItem.source

        loadTableDictsArray(lineItemArray: gLineItemArray)
        reloadTableSorted(sortBy: iSortBy, ascending: iAscending)
    }//end func

}//end extension
