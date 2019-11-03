//
//  SummaryTableVC.swift
//  Credit Cards
//
//  Created by George Bauer on 10/7/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Cocoa

//MARK:- enums, structs, & globals

public enum SummaryColID {
    static let name     = "Name"
    static let count    = "Count"
    static let netDebit = "NetDebit"
    static let debit    = "Debit"
    static let credit   = "Credit"
}
public enum SummarizeBy {
    case none, groupCategory, subCategory, vendor, cardType, month, year
}
public enum TableCalledBy {
    case none, main, spreadsheet, summaryTable
}
public struct SortDirective {
    var column = ""
    var ascending = false
}
public struct TableParams {
    var filtDate1   = ""
    var filtDate2   = ""
    var filtDolStr1 = ""
    var filtDolStr2 = ""
    var filtCardTyp = ""
    var filtCategor = ""
    var filtVendor  = ""
    var calledBy    = TableCalledBy.main
    var summaryDepth = 0
    var summarizeBy = SummarizeBy.none
    var sortBy      = SortDirective(column: SpSheetColID.transDate, ascending: true)
}//end struct

public var gPassToNextTable = TableParams()     // Pass info from Spreadsheet or SummaryTable to next SummaryTable
public let kMaxDollar = 999_999_999.0

class SummaryTableVC: NSViewController, NSWindowDelegate {

    //MARK: Instance Variables
    let codeFile = "SummaryTableVC"
    var summarizeBy = SummarizeBy.groupCategory
    var tableDicts  = [[String : String]]()    // Array of Dictionaries
    var totalCount  = 0
    var totalCredit = 0.0
    var totalDebit  = 0.0
    var iSortBy     = SummaryColID.netDebit
    var iAscending  = false

    var filtDate1   = "0000-00-00"
    var filtDate2   = "2999-12-31"
    var filtDollarVal1 = 0.0
    var filtDollarVal2 = kMaxDollar
    var filtCardTyp = ""
    var filtCategor = ""
    var filtVendor  = ""
    var calledBy    = TableCalledBy.none

    var myTableParams = TableParams()

    //MARK:- IBOutlets

    @IBOutlet var radioGroupCategory: NSButton!
    @IBOutlet var radioSubCategory:   NSButton!
    @IBOutlet var radioVendor:        NSButton!
    @IBOutlet var radioCardType:      NSButton!
    @IBOutlet var radioYear:          NSButton!
    @IBOutlet var radioMonth:         NSButton!

    @IBOutlet var tableView:    NSTableView!
    @IBOutlet var btnFilter:    NSButton!
    @IBOutlet var btnClear:     NSButton!
    @IBOutlet var lblStatus:    NSTextField!

    @IBOutlet var txtCardType:  NSTextField!
    @IBOutlet var txtDate1:     NSTextField!
    @IBOutlet var txtDate2:     NSTextField!
    @IBOutlet var txtVendor:    NSTextField!
    @IBOutlet var txtCategory:  NSTextField!
    @IBOutlet var txtDollar1:   NSTextField!
    @IBOutlet var txtDollar2:   NSTextField!

    @IBOutlet var txtCountTotal:  NSTextField!
    @IBOutlet var txtNetTotal:    NSTextField!
    @IBOutlet var txtDebitTotal:  NSTextField!
    @IBOutlet var txtCreditTotal: NSTextField!

    //MARK:- Lifecycle funcs

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        // Set txtTransationFolder.delegate
        txtDate1.delegate    = self // Allow ViewController to see when txtDate1 changes.
        txtDate2.delegate    = self // Allow ViewController to see when txtDate2 changes.
        txtDollar1.delegate  = self // Allow ViewController to see when txtDollar1 changes.
        txtDollar2.delegate  = self // Allow ViewController to see when txtDollar2 changes.
        txtCardType.delegate = self // Allow ViewController to see when txtCardType changes.
        txtCategory.delegate = self // Allow ViewController to see when txtCategory changes.
        txtVendor.delegate   = self // Allow ViewController to see when txtVendor changes.

        tableView.target = self
        tableView.doubleAction = #selector(tableViewDoubleClick(_:))
        radioGroupCategory.state = .on
        loadTableSortDescriptors()
        myTableParams = loadStuffFromCaller(tableParams: gPassToNextTable)
        //FIXME: Both btnFilter & radioCatChange reload table
        btnFilter(self)
        radioCatChange(self)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window!.delegate = self
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        print("✅(codeFile)#\(#line) windowShouldClose")
        NSApplication.shared.stopModal()
        return true
    }

//MARK:- IBActions

    @IBAction func btnFilter(_ sender: Any) {
        if setFilter() {
            btnFilter.keyEquivalent = ""
            loadTableDictsArray(lineItemArray: gLineItemArray, summarizeBy : summarizeBy)
            //tableView.reloadData()
            //tableViewSum.reloadData()
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
            loadTableDictsArray(lineItemArray: gLineItemArray, summarizeBy : summarizeBy)
            //tableView.reloadData()
            //tableViewSum.reloadData()
            btnClear.isEnabled = false
        }
    }

    @IBAction func radioCatChange(_ sender: Any) {
        if radioSubCategory.state == .on {
            summarizeBy = .subCategory
        } else if radioGroupCategory.state == .on {
            summarizeBy = .groupCategory
        } else if radioVendor.state == .on {
            summarizeBy = .vendor
        } else if radioCardType.state == .on {
            summarizeBy = .cardType
        } else if radioYear.state == .on {
            summarizeBy = .year
        } else if radioMonth.state == .on {
            summarizeBy = .month
        } else {
            summarizeBy = .none
        }
        loadTableDictsArray(lineItemArray: gLineItemArray, summarizeBy : summarizeBy)
    }

    //MARK:- Regular funcs

    private func loadStuffFromCaller(tableParams: TableParams) -> TableParams {
        print("loadStuffFromCaller", tableParams)
        switch tableParams.summarizeBy {
        case .cardType:
            radioCardType.state = .on
        case .groupCategory:
            radioGroupCategory.state = .on
        case .month:
            radioMonth.state = .on
        case .subCategory:
            radioSubCategory.state = .on
        case .vendor:
            radioVendor.state = .on
        case .year:
            radioYear.state = .on
        default:
            break
        }
        calledBy                = tableParams.calledBy
        iSortBy                 = tableParams.sortBy.column
        iAscending              = tableParams.sortBy.ascending
        txtVendor.stringValue   = tableParams.filtVendor
        txtCategory.stringValue = tableParams.filtCategor
        txtCardType.stringValue = tableParams.filtCardTyp
        txtDate1.stringValue    = tableParams.filtDate1
        txtDate2.stringValue    = tableParams.filtDate2
        txtDollar1.stringValue  = tableParams.filtDolStr1
        txtDollar2.stringValue  = tableParams.filtDolStr2
        //loadTableDictsArray(lineItemArray: filteredLineItemArray, summarizeBy : summarizeBy)
        return tableParams
    }

    //---- loadTableSortDescriptors - for column-based sort - Modifies tableView, colWidDict
    private func loadTableSortDescriptors() {
        for column in tableView.tableColumns {
            let key = column.identifier.rawValue
            let ascending: Bool
            ascending = (key == SummaryColID.name) // ascending for cardType; descending for the rest.
            let sortDescriptor  = NSSortDescriptor(key: key,  ascending: ascending)
            column.sortDescriptorPrototype = sortDescriptor
        }
    }//end func

    //---- loadTableDictsArray - Select stocks to be displayed & Create tableDicts array. Also fill "Totals" labels.
    private func loadTableDictsArray(lineItemArray: [LineItem], summarizeBy : SummarizeBy) {  // 227-287 = 50-lines

        var filteredLineItemArray = [LineItem]()  // Filtered list of transactions
        for lineItem in lineItemArray {
            if applyFilter(lineItem: lineItem) {
                filteredLineItemArray.append(lineItem)
                totalCredit += lineItem.credit
                totalDebit  += lineItem.debit
            }
        }//next

        //TODO: Change Summary Title based on filter
        //self.view.window?.title = "Change title here!!!"

        let sortedLineItemArray = filteredLineItemArray.sorted(by: { compareST(lft: $0, rgt: $1, summarizeBy: summarizeBy) })  //**

        if sortedLineItemArray.isEmpty { return }
        tableDicts  = []

        // Column Totals
        totalCount  = 0
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
                appendToTableDicts(name: oldName, count: namedCount, credit: namedCredit, debit: namedDebit, idx: i)
                namedCount  = 1
                namedCredit = lineItem.credit
                namedDebit  = lineItem.debit
                oldName     = newName
            }
            totalCount  += 1
            totalCredit += lineItem.credit
            totalDebit  += lineItem.debit
        }//next
        appendToTableDicts(name: oldName, count: namedCount, credit: namedCredit, debit: namedDebit)

        //tableDicts = tableDicts.sorted(by: { $0[SpSheetColID.debit]! > $1[SpSheetColID.debit]! })
        let sortBy = iSortBy
        tableDicts.sort { compareTextNum(lft: $0[sortBy]!, rgt: $1[sortBy]!, ascending: false) }
        tableView.reloadData()
        txtCountTotal.stringValue   = String(totalCount)

        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        txtCreditTotal.stringValue  = currencyFormatter.string(from: NSNumber(value: totalCredit)) ?? "??"
        txtDebitTotal.stringValue   = currencyFormatter.string(from: NSNumber(value: totalDebit)) ?? "??"
        txtNetTotal.stringValue     = currencyFormatter.string(from: NSNumber(value: totalDebit-totalCredit)) ?? "??"
    }//end func loadTableDictsArray

    //**
    func compareST(lft: LineItem, rgt: LineItem, summarizeBy: SummarizeBy) -> Bool {
        switch summarizeBy {
        case .groupCategory:
            let group1 = lft.genCat.splitAtFirst(char: "-").0
            let group2 = rgt.genCat.splitAtFirst(char: "-").0
            return       group1 < group2
        case .subCategory:
            return lft.genCat   < rgt.genCat
        case .cardType:
            return lft.cardType < rgt.cardType
        case .vendor:
            return lft.descKey  < rgt.descKey
        case .year:
            return makeYYYYMMDD(dateTxt: lft.tranDate)  < makeYYYYMMDD(dateTxt: rgt.tranDate)
        case .month:
            return makeYYYYMMDD(dateTxt: lft.tranDate)  < makeYYYYMMDD(dateTxt: rgt.tranDate)
        default:
            return false
        }
    }

    func summarizeName(lineItem: LineItem, summarizeBy: SummarizeBy) -> String {
        switch summarizeBy {
        case .groupCategory:
            return lineItem.genCat.splitAtFirst(char: "-").lft
        case .subCategory:
            return lineItem.genCat
        case .cardType:
            return lineItem.cardType
        case .vendor:
            return lineItem.descKey
        case .year:
            return String(makeYYYYMMDD(dateTxt: lineItem.tranDate).prefix(4))
        case .month:
            return String(makeYYYYMMDD(dateTxt: lineItem.tranDate).prefix(7))
        default:
            return "?name?"
        }
    }

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
        if txt.count == 6 && txt[4] == "-" {            // Insert leading zero in yyyy-m
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

    //TODO: Move to TableFilter.swift
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

    //---- reloadTableSorted - reloads the table for tableDicts, sorted by SpSheetColID
    private func reloadTableSorted(sortBy: String, ascending: Bool) {
        tableDicts.sort { compareTextNum(lft: $0[sortBy]!, rgt: $1[sortBy]!, ascending: ascending) }
        tableView.reloadData()
        iSortBy    = sortBy         // Remember Sort order
        iAscending = ascending
    }

    //---- makeRowDict - Create a dictionary entry for loadTable & appends to tableDicts
    private func appendToTableDicts(name: String, count: Int, credit: Double, debit: Double, idx: Int = -1) {
        if !name.isEmpty {
            let strCredit    = formatCell(credit, formatType: .dollar,  digits: 2)
            let strDebit     = formatCell(debit,  formatType: .dollar,  digits: 2)
            let strNetDebit  = formatCell(debit-credit, formatType: .dollar,  digits: 2, doReplaceZero: false)
            var dict      = [SummaryColID.name: name, SummaryColID.count: String(count), SummaryColID.netDebit: strNetDebit, SummaryColID.debit: strDebit, SummaryColID.credit: strCredit]
            dict["idx"] = String(idx)
            tableDicts.append(dict)
        }
    }// end func

}//end class

//MARK:- NSTextFieldDelegate
// Allow SpreadsheetVC to see when a TextField changes.
extension SummaryTableVC: NSTextFieldDelegate {

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
        reloadTableSorted(sortBy: sortDescriptor.key!, ascending: sortDescriptor.ascending)
    }

}//end extension

//MARK:- NSTableViewDelegate

extension SummaryTableVC: NSTableViewDelegate {

    //---- tableView viewFor - Creates each Cell when called by tableView
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        let dict = tableDicts[row]
        //var image: NSImage?

        guard let colID = tableColumn?.identifier.rawValue else {
            print("⛔️ Table Column nil")
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
        return nil
    }//end func

    //---- tableViewDoubleClick - Detected doubleClick: showUserInputVendorCatForm
    //viewDidLoad has tableView.target = self
    // & tableView.doubleAction = #selector(tableViewDoubleClick(_:))
    @objc func tableViewDoubleClick(_ sender:AnyObject) {
        prepareCall()
    }//end func

    func prepareCall() {
        guard tableView.selectedRow >= 0 else   { return }  // Bail if Bogus row#
        let rowDict = tableDicts[tableView.selectedRow]
        let idxStr = rowDict["idx"] ?? ""
        let idx = Int(idxStr) ?? -1
        print("DoubleClicked on Row # \(tableView.selectedRow).  idx = \(idx)")

        var filterDate1     = txtDate1.stringValue.trim
        var filterDate2     = txtDate2.stringValue.trim
        var filterCategory  = txtCategory.stringValue.trim
        var filterVendor    = txtVendor.stringValue.trim
        var filterCardType  = txtCardType.stringValue.trim

        // Pick the next summarizeBy & filter based in row clicked
        var summarizeNew = summarizeBy
        var doNothing = true
        switch summarizeBy {
        case .groupCategory:        // .groupCategory   => .subCategory
            filterCategory  = rowDict[SummaryColID.name]!
            summarizeNew = .subCategory
            doNothing = false
        case .subCategory:          // .subCategory     => .vendor
            filterCategory  = rowDict[SummaryColID.name]!
            summarizeNew = .vendor
            doNothing = false
        case .vendor:               //  .vendor         => .subCategory
            filterVendor  = rowDict[SummaryColID.name]!
            summarizeNew = .subCategory
            doNothing = false
        case .cardType:             //  .cardType       => .groupCategory
            filterCardType  = rowDict[SummaryColID.name]!
            summarizeNew = .groupCategory
            doNothing = false
        case .month, .year:         //  .month, year    => .groupCategory
            filterDate1  = rowDict[SummaryColID.name]!
            filterDate2  = rowDict[SummaryColID.name]!
            summarizeNew = .groupCategory
            doNothing = false
        default:
            break
        }
        if doNothing { return }

        gPassToNextTable = TableParams(filtDate1: filterDate1,
                                     filtDate2:   filterDate2,
                                     filtDolStr1: txtDollar1.stringValue,
                                     filtDolStr2: txtDollar2.stringValue,
                                     filtCardTyp: filterCardType,
                                     filtCategor: filterCategory,
                                     filtVendor:  filterVendor,
                                     calledBy:    TableCalledBy.summaryTable,
                                     summaryDepth: myTableParams.summaryDepth+1,
                                     summarizeBy: summarizeNew,
                                     sortBy: SortDirective(column: SummaryColID.netDebit, ascending: false))

        if myTableParams.summaryDepth < 2 {
            callNextSummary()
        } else {
            callSpreadsheet()
        }
    }//end func prepareCall

    func callNextSummary() {
        let storyBoard = NSStoryboard(name: "SummaryTable", bundle: nil)
        let summaryWindowController = storyBoard.instantiateController(withIdentifier: "SummaryWindowController") as! NSWindowController
        if let summaryWindow = summaryWindowController.window {
            //let summaryTableVC = storyBoard.instantiateController(withIdentifier: "SummaryTableVC") as! SummaryTableVC
            let application = NSApplication.shared
            _ = application.runModal(for: summaryWindow) // <=================  UserInputVC

            summaryWindow.close()                     // Return here from userInputWindow
        }
    }//end func callNextSummary

    func callSpreadsheet() {
        gPassToNextTable.sortBy = SortDirective(column: SpSheetColID.transDate, ascending: true)

        let storyBoard = NSStoryboard(name: "Spreadsheet", bundle: nil)
        let tableWindowController = storyBoard.instantiateController(withIdentifier: "SpreadsheetWindowController") as! NSWindowController
        if let tableWindow = tableWindowController.window {
            //let tableVC = tableWindow.contentViewController as! TableVC
            //gLineItemArray = lineItemArray
            let application = NSApplication.shared
            application.runModal(for: tableWindow)

            tableWindow.close()
        }//end if let

    }//end func callSpreadsheet

}//end extension
