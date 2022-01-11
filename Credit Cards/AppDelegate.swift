//
//  AppDelegate.swift
//  Credit Cards
//
//  Created by George Bauer on 7/28/19.
//  Copyright © 2019-2021 George Bauer. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func mnuHelpAbout_Click(_ sender: Any) {              // Handles mnuHelpAbout.Click
        GBox.alert("Credit Cards Version \(Const.appVersion)\nBuild \(Const.appBuild)\nTransaction files are in:\n\"Download/Credit Card Tran\"\nSupport files are in:\n\"Desktop/CreditCard\"",title: "About Credit Cards")//, "About Garmitrk")
    }

}//end class AppDelegate


