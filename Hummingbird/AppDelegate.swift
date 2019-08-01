//
//  AppDelegate.swift
//  Test
//
//  Created by Sven A. Schmidt on 02/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Cocoa
import UserNotifications


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    var statusItem: NSStatusItem!
    @IBOutlet weak var enabledMenuItem: NSMenuItem!
    @IBOutlet weak var statsMenuItem: NSMenuItem!
    @IBOutlet weak var versionMenuItem: NSMenuItem!

    lazy var preferencesController: PreferencesController = {
        return PreferencesController(windowNibName: "HBPreferencesController")
    }()

    lazy var statsController: StatsController = {
        return StatsController(nibName: "StatsController", bundle: nil)
    }()

}


// App lifecycle
extension AppDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusMenu.delegate = self
        defaults.register(defaults: DefaultPreferences)

        if #available(OSX 10.14, *) { // set up notification actions
            Notifications.registerCategories()
            UNUserNotificationCenter.current().delegate = self
        }

        activate(allowAlert: true)
    }

    func activate(allowAlert: Bool) {
        if !_activate(allowAlert: allowAlert) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.activate(allowAlert: false)
            }
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
        versionMenuItem.title = "Version: \(version)"
        statsMenuItem.view = statsController.view
        statsMenuItem.toolTip = "➝ distance moved\n⤢ aread resized"
        if _isDebugAssertConfiguration() {
            // enable in debug mode to enable notification triggering
            versionMenuItem.isEnabled = true
        }
    }

}


extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        do {
            let hidden = NSEvent.modifierFlags.intersection(.deviceIndependentFlagsMask) == .option
            versionMenuItem.isHidden = !hidden
        }
        statsController.updateView()
    }
}


// Helpers
extension AppDelegate {

    func isTrusted() -> Bool {
        let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        let options = [prompt: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    @discardableResult
    func _activate(allowAlert: Bool) -> Bool {
        Tracker.enable()
        enabledMenuItem.state = (Tracker.isActive ? .on : .off)
        Tracker.isActive ? print("activated") : print("Activation failed")
        if !Tracker.isActive && allowAlert {
            let alert = NSAlert()
            alert.messageText = "Accessibility permissions required"
            alert.informativeText = """
            Hummingbird requires Accessibility permissions in order to be able to move and resize windows for you.

            You can grant Accessibility permissions in "System Preferences" → "Security & Privacy" → "Privacy" → "Accessibility".

            Click "Help" for more information.
            
            """
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Help")
            let response = alert.runModal()
            if response == .alertSecondButtonReturn {
                let url = URL(string: "https://finestructure.co/hummingbird-accessibility")!
                NSWorkspace.shared.open(url)
            }
        }
        return Tracker.isActive
    }

    func disable() {
        Tracker.disable()
        enabledMenuItem.state = (Tracker.isActive ? .on : .off)
    }

    var version: String {
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let bundleVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "\(shortVersion) (\(bundleVersion))"
    }

}


// IBActions
extension AppDelegate {

    @IBAction func toggleEnabled(_ sender: Any) {
        if enabledMenuItem.state == .on {
            disable()
        } else {
            _activate(allowAlert: true)
        }
    }

    @IBAction func showPreferences(_ sender: Any) {
        preferencesController.window?.makeKeyAndOrderFront(sender)
    }

    @IBAction func versionClicked(_ sender: Any) {
        if #available(OSX 10.14, *) {
            if _isDebugAssertConfiguration() {
                Notifications.send(milestone: .exceededAverage)
            }
        }
    }

}


// UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    @available(OSX 10.14, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.action {
        case .turnOff?:
            print("turn off")
        case .show?:
            print("show")
        case .none:
            print("no action")
        }
    }
}
