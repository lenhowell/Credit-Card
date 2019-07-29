//
//  ViewController.swift
//  Credit Cards
//
//  Created by Lenard Howell on 7/28/19.
//  Copyright © 2019 Lenard Howell. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    var myCrdType = ""
    var myFileName = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func btnStart(_ sender: Any) {
        main()
        
    }
    @IBOutlet weak var txtDteRng: NSTextField!
    
    @IBOutlet weak var txtCrdType: NSTextField!

    @IBOutlet weak var lblErrMsg: NSTextField!
    func main(){
        lblErrMsg.stringValue = ""
        let mytxtDteRng = txtDteRng.stringValue
        let strMM = mytxtDteRng.suffix(2)
        let strYY = mytxtDteRng.prefix(2)
        let numMM = Int(strMM) ?? 0
        let numYY = Int(strYY) ?? 0
        var fileContents = ""

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
        let myFileName =  "\(myCrdType)-20\(strYY)-\(strMM).csv"

        
        
        if let downloadsPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            
            let fileURL = downloadsPath.appendingPathComponent(myFileName)
            
 
            //— reading —    // macOSRoman is more forgiving than utf8
            do {
                fileContents = try String(contentsOf: fileURL, encoding: .macOSRoman)
            } catch {
                lblErrMsg.stringValue = "File Does NOT Exist, \(fileURL.path)!!!!"
                return
            }
        } else {
            lblErrMsg.stringValue = "Directory Path to Target File Does Not Exist!!!!"

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
    
    func hndleC1v(crdArray: [String]) {
        print(crdArray[0])
        print(crdArray[1])
        print(crdArray[2])
       print()
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
    
}//end class

//— writing —
//            do    { try text.write(to: fileURL, atomically: false, encoding: .utf8)}
//            catch { /* error handling here */ }

