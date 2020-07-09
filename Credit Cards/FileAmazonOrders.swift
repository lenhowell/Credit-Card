//
//  AmazonOrders.swift
//  Credit Cards
//
//  Created by George Bauer on 12/10/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Foundation

//MARK:- ReadAmazon
public struct AmazonItem {
    var orderNumber = ""
    var orderDate   = ""
    var order$      = 0.0
    var orderShipTo = ""
    var itemQuant   = 1
    var itemName    = ""
    var personTitle = ""
    var personName  = ""
    var itemSoldBy  = ""
    var item$       = 0.0
    var itemSerial  = ""
    var fileLineNum = 0
    
    init(orderNumber: String, orderDate: String, order$: Double, orderShipTo: String, fileLineNum: Int) {
        self.orderNumber = orderNumber
        self.orderDate   = orderDate
        self.order$      = order$
        self.orderShipTo = orderShipTo
        self.fileLineNum = fileLineNum
    }
}

// TODO: Fix returns, crosscheck files/year count.
func readAmazon(testData: String = "") -> [String: [AmazonItem]] {
    enum Expect: String { case none, ordersYear, year,
        orderPlaced, date, totalTitle, total$, shipToTitle, shipTo, orderNumber,
        itemName, item$, itemSerial
    }
    let codeFile = "AmazonOrders"
    // Find the Amazon Orders file
    let fileName: String
    let content:  String
    let allowAlert: Bool
    if testData.isEmpty {
        fileName = "Amazon Orders.txt"
        allowAlert = true
        let pathURL = FileIO.getPossibleParentFolder(myURL: gTransactionFolderURL)
        let fileURL = pathURL.appendingPathComponent(fileName)
        content = (try? String(contentsOf: fileURL)) ?? ""
        if content.isEmpty {
            let msg = "\(fileURL.path) does not exist."
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataWarning, action: .alert, fileName: fileName, dataLineNum: 0, lineText: "", errorMsg: msg)
            return [:]
        }
    } else {
        fileName = "TestData"
        allowAlert = false
        content  = testData
    }

    let ignores = ["Buy it again","View your","Get product","Share gift","Write a product",
                   "Archive order","Return","Order D","Ask Product", "Problem with or",
                   "Replacement ordered", "Your replacement","View ret",
                   "This is a gift","Condition:" , "===="]

    var amazonItemsByDate = [String: [AmazonItem]]()
    let lines = content.components(separatedBy: "\n").map {$0.trim}
    let linesCount = lines.count
    print("\n\(codeFile)#\(#line) read \(linesCount) lines from Amazon Orders.txt")

    var errorCount          = 0
    var warningCount        = 0
    var orderCount          = 0
    var orderCountTotal     = 0
    var itemCountTotal      = 0
    var orderCountExpected  = 0
    var yearExpected        = 0
    var expect              = Expect.ordersYear

    var orderNumber     = ""
    var orderDateRaw    = ""
    var orderDate       = ""
    var order$          = 0.0
    var orderShipTo     = ""

    var personTitle     = ""
    var personName      = ""


    func gotNewOrdersInYear(line: String) {
        yearExpected = 0
        let words = line.components(separatedBy: " ")
        orderCountExpected = Int(words[0]) ?? 0
        orderCount = 0
        if let yrStr = words.last {
            let yr = Int(yrStr) ?? 0
            if yr >= 1980 && yr < 2099 {
                yearExpected = yr
                expect = .orderPlaced
            } else {
                expect = .year
            }
        }
    }

    func newOrder() {
        orderCount += 1
        orderCountTotal += 1

        orderNumber     = ""
        orderDateRaw    = ""
        orderDate       = ""
        order$          = 0.0
        orderShipTo     = ""

        personTitle     = ""
        personName      = ""
        expect = .date
    }

    var amazonOrder = AmazonItem(orderNumber: "", orderDate: "", order$: 0.0, orderShipTo: "", fileLineNum: 0)
    var amazonItem  = amazonOrder
    var orderRemaining$ = 0.0
    for (idx, line) in lines.enumerated(){
        if line.hasPrefix("EOF-") { break }
        if idx == 3099 {
            // Debug Trap
        }
        if line.count < 4 { continue }
        var ignoreMe = false
        for ignore in ignores {
            if line.hasPrefix(ignore) {
                ignoreMe = true
                break
            }
        }
        if ignoreMe { continue }

        //print("\(codeFile)#\(#line) line#\(idx+1): \(line)")

        var abort = false
        let missing = expect.rawValue
        if expect != .ordersYear && line.contains("orders placed in" ) {
            if expect != .itemName { abort = true }
            expect = .ordersYear
        }
        if expect != .itemName && expect != .orderPlaced && line == "ORDER PLACED" {
            if expect != .itemName { abort = true }
            expect = .orderPlaced
        }
        if line.hasPrefix("ORDER #") {
            let tuple = line.splitAtFirst(char: "#")
            orderNumber = tuple.rgt.trim
            amazonOrder = AmazonItem(orderNumber: orderNumber, orderDate: orderDate, order$: order$, orderShipTo: orderShipTo, fileLineNum: idx+1)
            amazonItem  = amazonOrder
            if expect != .orderNumber {
                abort = true
                expect = .orderPlaced
            }
        }
        if abort {
            let name = amazonItem.itemName.count <= 1 ? "" : " for:\n\"\(amazonItem.itemName)\""
            let msg = "\(orderDateRaw) order\(name)\nunexpectedly ended without \(missing)"
            handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .alertAndDisplay, fileName: fileName, dataLineNum: idx+1, lineText: line, errorMsg: msg)
            errorCount += 1
        }

        switch expect {
        case .ordersYear:
            if line.contains("orders placed") { // Ignore stuff until "## orders placed in"
                yearExpected = 0
                let words = line.components(separatedBy: " ")
                orderCountExpected = Int(words[0]) ?? 0     // Expected Order count
                orderCount = 0
                if let yrStr = words.last {
                    let yr = Int(yrStr) ?? 0
                    if yr >= 1980 && yr < 2099 {
                        yearExpected = yr                   // covering what year?
                        expect = .orderPlaced
                    } else {
                        expect = .year                      // Year was missing: get from next line
                    }
                }
            }
        case .year:
            let yr = Int(line) ?? 0
            if yr >= 1980 && yr < 2099 {
                yearExpected = yr                           // Year from ordersYear
            } else {
                yearExpected = 0
            }
            expect = .orderPlaced

        case .orderPlaced:
            if line.hasPrefix("ORDER PLACED") {             // Start of new Order
                newOrder()
            }

        case .date:
            orderDateRaw = line.trim
            orderDate = makeDate(orderDateRaw)
            let yr = Int(line.suffix(4)) ?? 0
            if yr != yearExpected {
                errorCount += 1
                let msg = "AmazonOrders.txt line # \(idx+1)\nOrder Date not in \(yearExpected)\n\(orderDateRaw)"
                handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .alertAndDisplay, fileName: "", dataLineNum: 0, lineText: line, errorMsg: msg)
            }
            order$ = 0
            orderRemaining$ = 0
            expect = .totalTitle

        case .totalTitle:
            if line != "TOTAL" {
                errorCount += 1
                let msg = "AmazonOrders.txt line # \(idx+1)\nOrder \"TOTAL\" missing\n\(orderDateRaw)"
                handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .alertAndDisplay, fileName: "", dataLineNum: 0, lineText: line, errorMsg: msg)
            }
            expect = .total$

        case .total$:
            if line.hasPrefix("$") {
                if let amount = textToDbl(line) {
                    order$ = amount
                    orderRemaining$ = amount
                } else {
                    let msg = "AmazonOrders.txt line # \(idx+1)\nOrder total $-amount corrupt: \(line)\n\(orderDateRaw)"
                    handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .alertAndDisplay, fileName: "", dataLineNum: 0, lineText: line, errorMsg: msg)
                    errorCount += 1
                }
            }
            expect = .shipToTitle

        case .shipToTitle:
            expect = .shipTo

        case .shipTo:
            orderShipTo = line
            expect = .orderNumber

        case .orderNumber:
            expect = .itemName

            //--------- Items ---------

        case .itemName:                                 // Expecting $amount, got:
            if line.hasPrefix("ORDER PLACED") {                 // "ORDER PLACED"
                let sum = order$ - orderRemaining$
                let absRemaining = abs(orderRemaining$)
                let pctOff = absRemaining/sum
                if (orderRemaining$ > 10.0  || orderRemaining$ < -0.1) && pctOff > 0.07 {
                    let r$  = String(format: "%.2f",absRemaining)
                    let o$  = String(format: "%.2f",sum)
                    let pct = String(format: "%.1f", pctOff*100)
                    if orderRemaining$ > 0 {
                        print("⚠️ \(amazonItem.orderDate) Tax & Shipping of $\(r$) on $\(o$) = \(pct)%  line \(amazonItem.fileLineNum)")
                    } else {
                        print("⚠️ \(amazonItem.orderDate) Hidden Discount of at least $\(r$) on $\(o$) = \(pct)%  line \(amazonItem.fileLineNum)")
                    }
                    warningCount += 1
                }
                newOrder()

            } else if line.contains("orders placed"){           // Begin a new year
                gotNewOrdersInYear(line: line)

            } else if line.hasPrefix("See all") {               // "See all"
                let r$  = String(format: "%.2f",orderRemaining$)
                let o$  = String(format: "%.2f",order$)
                let pct = String(format: "%.1f", orderRemaining$/order$*100)//(orderRemaining$/order$*100)
                print("⛔️ \(amazonItem.orderDate) Not shown: $\(r$) on $\(o$) = \(pct)%  line \(amazonItem.fileLineNum)")
                print()
            } else if line.hasPrefix("Amount Serial") {         // "Amount Serial number(s)"
                expect = .itemSerial

            } else {
                amazonItem = amazonOrder
                amazonItem.itemQuant = 1
                amazonItem.itemName = line
                let comps = line.components(separatedBy: " of ")
                if comps.count >= 2  {
                    let qStr = comps[0].trim
                    if qStr.count < 4 {
                        if let quan = Int(qStr) {
                            amazonItem.itemQuant = quan
                            amazonItem.itemName = String(line.dropFirst(comps[0].count + 4))
                        }
                    }
                }
                itemCountTotal += 1
                expect = .item$     // Item Name
            }

        case .item$:                                     // Expecting $amount, got:
            if line.hasPrefix("Sold by:") {                     // "Sold by:"
                let (_, soldBy) = line.splitAtFirst(char: ":")
                amazonItem.itemSoldBy = soldBy.trim
            } else if line.hasPrefix("Lightning Deal") {        // "Lightning Deal"
                amazonItem.item$ = orderRemaining$
                orderRemaining$ = 0
                expect = .itemName
            } else if line.hasPrefix("Serial Numbers:") {       // "Serial Numbers:"
                if line.count > 15 {
                    let tuple = line.splitAtFirst(char: ":")
                    amazonItem.itemSerial = tuple.rgt.trim
                } else {
                    expect = .itemSerial
                }

            } else if line.hasPrefix("$") {                     // $amount
                var amtStr = line
                if amtStr.contains("\t") {
                    (amtStr, _) = amtStr.splitAtFirst(char: "\t")
                    amtStr = amtStr.trim
                }
                if let amount = textToDbl(amtStr) {
                    amazonItem.item$ = amount
                    orderRemaining$ -= amount * Double(amazonItem.itemQuant)
                } else {
                    let msg = "Order total $-amount corrupt: \(line)\n\(orderDateRaw) order for:\n\(amazonItem.itemName)\n"
                    handleError(codeFile: codeFile, codeLineNum: #line, type: .dataError, action: .alertAndDisplay, fileName: "fileName", dataLineNum: idx+1, lineText: line, errorMsg: msg)
                    errorCount += 1
                }
                amazonItem.fileLineNum = idx+1
                if let orderArray =  amazonItemsByDate[amazonItem.orderDate] {
                    var newOrderArray = orderArray
                    newOrderArray.append(amazonItem)
                    amazonItemsByDate[amazonItem.orderDate] = newOrderArray
                } else {
                    amazonItemsByDate[amazonItem.orderDate] = [amazonItem]
                }
                expect = .itemName
            } else {                                            // Author
                if !line.contains("(") {
                    amazonItem.personTitle = "Author"
                    amazonItem.personName = line
                } else {
                    var s1 = ""
                    (amazonItem.personName, s1) = line.splitAtFirst(char: "(")
                    amazonItem.personName = amazonItem.personName.trim
                    (amazonItem.personTitle, _) = s1.splitAtFirst(char: ")")
                }
            }

        case .itemSerial:
            amazonItem.itemSerial = line.trim
            if line.hasPrefix("$") {
                expect = .itemName
            } else {
                expect = .item$
            }

        default:
            errorCount += 1
            print("\(codeFile)#\(#line) line#\(idx+1): \(line)")
        }
//
    }//next line
    if errorCount + warningCount == 0 {
        print("\(codeFile)#\(#line) 🤪 Amazon Orders.txt sucessfully read \(linesCount) lines, \(orderCountTotal) orders, \(itemCountTotal) items")
    } else {
        print("\(codeFile)#\(#line) 😡 Amazon Orders.txt read \(linesCount) lines, \(orderCountTotal) orders, \(itemCountTotal) items, with \(warningCount) warnings, \(errorCount) errors.")
    }
    return amazonItemsByDate
}//end func readAmazon

func makeDate(_ dateStr: String) -> String {
    // April 24, 2017 => 2017-04-24
    let comps = dateStr.trim.components(separatedBy: " ")
    if comps.count != 3 {
        return "0000-00-00"
    }
    let yr = comps[2]
    var da = String(comps[1].dropLast())
    if da.count < 2 {
        da = "0" + da
    }
    let mo: String
    switch comps[0] {
    case "January":
        mo = "01"
    case "February":
        mo = "02"
    case "March":
        mo = "03"
    case "April":
        mo = "04"
    case "May":
        mo = "05"
    case "June":
        mo = "06"
    case "July":
        mo = "07"
    case "August":
        mo = "08"
    case "September":
        mo = "09"
    case "October":
        mo = "10"
    case "November":
        mo = "11"
    case "December":
        mo = "12"
    default:
        mo = "00"
    }
    return "\(yr)-\(mo)-\(da)"
}
