//
//  AppDelegate.swift
//  Test
//
//  Created by Sven A. Schmidt on 02/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    var statusItem: NSStatusItem!
    @IBOutlet weak var disabledMenuItem: NSMenuItem!

    lazy var preferencesController: PreferencesController = {
        return PreferencesController(windowNibName: "HBPreferencesController")
    }()

}


// App lifecycle
extension AppDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        UserDefaults.standard.register(defaults: DefaultPreferences)

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        if AXIsProcessTrustedWithOptions(options) {
            enable()
        } else {
            disabledMenuItem.state = .on
        }
    }

    override func awakeFromNib() {
        statusItem = {
            let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            statusItem.menu = statusMenu
            statusItem.image = NSImage(named: "MenuIcon")
            statusItem.alternateImage = NSImage(named: "MenuIconHighlight")
            statusItem.highlightMode = true
            return statusItem
        }()
        statusMenu.autoenablesItems = false
        statusMenu.item(at: 0)?.isEnabled = false
    }

}


// Helpers
extension AppDelegate {

    func enable() {
        disabledMenuItem.state = .off
        HBSTracking.enable()
    }

    func disable() {
        disabledMenuItem.state = .on
        HBSTracking.disable()
    }

}


// IBActions
extension AppDelegate {

    @IBAction func toggleDisabled(_ sender: Any) {
        if disabledMenuItem.state == .off {
            disable()
        } else {
            enable()
        }
    }

    @IBAction func showPreferences(_ sender: Any) {
        preferencesController.window?.makeKeyAndOrderFront(sender)
    }

}

