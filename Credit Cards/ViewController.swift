//
//  ViewController.swift
//  Credit Cards
//
//  Created by Lenard Howell on 7/28/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    //MARK:- Instance Variables
    
    var getCatagory = [String: String]() //String: is the Key 2nd String is the value
    var myCrdType = ""
    var myFileName = ""
    let descLength = 8
    
    //MARK:- Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        loadCatagories() // Build Catagories Dictionary
        txtCrdType.stringValue = "C1V"
        txtDteRng.stringValue  = "1905"
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    //MARK:- @IBActions
    
    @IBAction func btnStart(_ sender: Any) {
        main()
    }
    
    //MARK:- @IBOutlets
    
    @IBOutlet weak var txtDteRng: NSTextField!
    @IBOutlet weak var txtCrdType: NSTextField!
    @IBOutlet weak var lblErrMsg: NSTextField!
    @IBOutlet weak var lblResults: NSTextField!
    
    //MARK:- Main Program
    
    func main(){
        lblErrMsg.stringValue = ""
        var fileContents = ""
        
        let mytxtDteRng = txtDteRng.stringValue
        let strMM = mytxtDteRng.suffix(2)
        let strYY = mytxtDteRng.prefix(2)
        
        let numMM = Int(strMM) ?? 0
        let numYY = Int(strYY) ?? 0

        if mytxtDteRng.count != 4 {
            badDate()
            return
        }
        
        if numYY < 1 || numYY > 46 {
            badDate()
            return
        }
        if numMM < 1 || numMM > 12 {
            badDate()
            return
        }
        myCrdType = txtCrdType.stringValue.uppercased()
        myFileName =  "\(myCrdType)-20\(strYY)-\(strMM).csv"

        if let downloadsPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            
            let dir = downloadsPath.appendingPathComponent("Credit Card Trans")
            let fileURL = dir.appendingPathComponent(myFileName)
            
            //— reading —    // macOSRoman is more forgiving than utf8
            do {
                fileContents = try String(contentsOf: fileURL, encoding: .macOSRoman)
            } catch {
                lblErrMsg.stringValue = "File Does NOT Exist, \(fileURL.path)!!!!"
                return
            }
        } else {
            lblErrMsg.stringValue = "Directory Path to Target File Does Not Exist!!!!"
            return
        }

        let crdArray = fileContents.components(separatedBy: "\n")
        switch myCrdType {
        case "C1V":
            hndleC1v(crdArray: crdArray)
        case "C1R":
            hndleC1r(crdArray: crdArray)
        case "DIS":
            hndleDis(crdArray: crdArray)
        case "CIT":
            hndleCit(crdArray: crdArray)
        default:
            lblErrMsg.stringValue = "Unknown Credit Card Type!!!! \(txtCrdType.stringValue)"
        }
    }//end func Main
  
    
    //MARK:- Support Functions
    
    func hndleC1v(crdArray: [String])
    {
        let transactions = crdArray.dropFirst()
        var lineItemArray = [LineItem]()
        
        var countWithCat = 0
        for tran in transactions{
            if tran.trim.isEmpty { continue }
            var transaction = tran
            if tran != tran.uppercased() {
                print()
            }
            //Add comma discriminator
            var inQuote = false
            var tranArray = Array(tran)
            for (i,char) in tranArray.enumerated() {
                if char == "\"" {
                    inQuote = !inQuote
                }
                if inQuote && char == "," {
                    tranArray[i] = ";"
                }
            }
            transaction = String(tranArray).uppercased()
          
            let columns = transaction.components(separatedBy: ",")
            var lineitem = LineItem()
            lineitem.tranDate = columns[0]
            lineitem.postDate = columns[1]
            lineitem.cardNum  = columns[2]
            lineitem.desc     = columns[3]
            lineitem.rawCat   = columns[4]
            lineitem.amount   = Double(columns[5]) ?? 0
  //          let debit  = Double(columns[5]) ?? 0
  //          let credit = Double(columns[6]) ?? 0
  //          lineitem.amount = credit-debit
            lineitem.cardType = "C1V"
            lineitem.genCat = ""
            
            // if lineitem.desc.uppercased().contains("PALM BEACH TAN") {lineitem.genCat = "Tanning"}
            // Creting The Key for Dictionary
            var key = String(lineitem.desc.uppercased().replacingOccurrences(of: " ", with: "").prefix(descLength)) // uppercase and compress Description
                key = key.replacingOccurrences(of: ";", with: "") // Remove commas from Key
           if let value = getCatagory[key] {
                lineitem.genCat = value
                countWithCat += 1
            }
            lineItemArray.append(lineitem)
            print(lineitem)
        }// End of FOR loop
        
        lblResults.stringValue = "\(lineItemArray.count) transactions.\n \(countWithCat) given a catagory."
        
        
        var outPutStr = "Card Type\tTranDate\tDesc\tAmount\tCatagory\tRaw Catagory\n"
        for xX in lineItemArray {
            let text = "\(xX.cardType)\t\(xX.tranDate)\t\(xX.desc)\t\(xX.amount)\t\(xX.genCat)\t\(xX.rawCat)\n"
            outPutStr += text
        }
        
        if let desktopPathUrl = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            let myFileNameOut =  String(myFileName.dropLast(4)+"-Out.csv")
            let fileUrl = desktopPathUrl.appendingPathComponent(myFileNameOut)

            copyStringToClipBoard(textToCopy: outPutStr)
            do    {
                try outPutStr.write(to: fileUrl, atomically: false, encoding: .utf8)
            } catch {
                lblErrMsg.stringValue = "Write Failed!!!! \(fileUrl.path)"
            }

            print()
        } else {
            lblErrMsg.stringValue = "Directory Path to Output File Does Not Exist!!!!"
        }
    }
    
    func hndleC1r(crdArray: [String]) {
    }
    
    func hndleDis(crdArray: [String]) {
    }
    
    func hndleCit(crdArray: [String]) {
    }
    
    func badDate() {
        lblErrMsg.stringValue = "Date must be in YYMM Format, \(txtDteRng.stringValue ) is Wrong!!"
    }
    func loadCatagories() {
        guard let catagories = Bundle.main.path(forResource: "CatagoryLookup", ofType: "txt") else {
            return
        }
        let contentof = (try? String(contentsOfFile: catagories)) ?? ""
        let lines = contentof.components(separatedBy: "\n")
        for line in lines{
            if line == "" {
                continue
            }
            let catagoryArray = line.components(separatedBy: ",")
            let description = String(catagoryArray[0].replacingOccurrences(of: " ", with: "").uppercased().prefix(descLength))
            let catagory = catagoryArray[1].trimmingCharacters(in: .whitespaces) //drop leading and trailing white space
            getCatagory[description] = catagory
        }
        print(getCatagory)
    }
    //MARK:- copyStringToClipBoard
    public func copyStringToClipBoard(textToCopy: String) {
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(textToCopy, forType: NSPasteboard.PasteboardType.string)
    }

}//end class



