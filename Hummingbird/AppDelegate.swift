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
    @IBOutlet weak var enabledMenuItem: NSMenuItem!

    lazy var preferencesController: PreferencesController = {
        return PreferencesController(windowNibName: "HBPreferencesController")
    }()

}


// App lifecycle
extension AppDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        defaults.register(defaults: DefaultPreferences)

        let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        let options = [prompt: true] as CFDictionary
        if AXIsProcessTrustedWithOptions(options) {
            print("trusted")
            enable()
        } else {
            print("trust check FAILED")
            enabledMenuItem.state = .off
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
    }

}


// Helpers
extension AppDelegate {

    func enable() {
        Tracker.enable()
        enabledMenuItem.state = (Tracker.isActive ? .on : .off)
        if !Tracker.isActive {
            let alert = NSAlert()
            alert.messageText = "Failed to activate"
            alert.informativeText = """
            An error occurred while activating the mechanism to track mouse events.
            
            This can happen when the application has not been granted Accessibility access in "System Preferences" → "Security & Privacy" → "Privacy" → "Accessibility".
            """
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    func disable() {
        Tracker.disable()
        enabledMenuItem.state = (Tracker.isActive ? .on : .off)
    }

}


// IBActions
extension AppDelegate {

    @IBAction func toggleEnabled(_ sender: Any) {
        if enabledMenuItem.state == .on {
            disable()
        } else {
            enable()
        }
    }

    @IBAction func showPreferences(_ sender: Any) {
        preferencesController.window?.makeKeyAndOrderFront(sender)
    }

}

