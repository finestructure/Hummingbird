//
//  AppDelegate.swift
//  Test
//
//  Created by Sven A. Schmidt on 02/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Cocoa
import os
import UserNotifications


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    var statusItem: NSStatusItem!
    @IBOutlet weak var enabledMenuItem: NSMenuItem!
    @IBOutlet weak var registerMenuItem: NSMenuItem!
    @IBOutlet weak var sendCoffeeMenuItem: NSMenuItem!
    @IBOutlet weak var statsMenuItem: NSMenuItem!
    @IBOutlet weak var versionMenuItem: NSMenuItem!

    lazy var tipJarController: TipJarController = {
        return TipJarController(windowNibName: "TipJarController")
    }()

    lazy var preferencesController: PreferencesController = {
        let c = PreferencesController(windowNibName: "PreferencesController")
        c.delegate = self
        return c
    }()

    lazy var registrationController: RegistrationController = {
        let c = RegistrationController(windowNibName: "RegistrationController")
        c.delegate = self
        return c
    }()

    lazy var statsController: StatsController = {
        return StatsController(nibName: "StatsController", bundle: nil)
    }()

    var stateMachine = AppStateMachine()
}


// App lifecycle
extension AppDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        stateMachine.delegate = self

        if Date(forKey: .firstLaunched, defaults: Current.defaults()) == nil {
            try? Current.date().save(forKey: .firstLaunched, defaults: Current.defaults())
        }

        statusMenu.delegate = self
        Current.defaults().register(defaults: DefaultPreferences)

        if #available(OSX 10.14, *) { // set up notification actions
            Notifications.registerCategories()
            UNUserNotificationCenter.current().delegate = self
        }

        stateMachine.state = .validatingLicense
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
        do {
            enabledMenuItem.isHidden = (stateMachine.state == .unregistered)
            registerMenuItem.isHidden = !enabledMenuItem.isHidden
        }
        do {
            sendCoffeeMenuItem.isHidden = Current.featureFlags.commercial
        }
        statsController.updateView()
    }
}


// MARK:- Helpers
extension AppDelegate {

    func isTrusted() -> Bool {
        let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        let options = [prompt: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    var version: String {
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let bundleVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "\(shortVersion) (\(bundleVersion))"
    }

}


// MARK:- IBActions
extension AppDelegate {

    @IBAction func toggleEnabled(_ sender: Any) {
        stateMachine.toggleEnabled()
    }

    @IBAction func registerLicense(_ sender: Any) {
        NSApp.activate(ignoringOtherApps: true)
        registrationController.showWindow(sender)
    }

    @IBAction func showTipJar(_ sender: Any) {
        NSApp.activate(ignoringOtherApps: true)
        tipJarController.showWindow(sender)
    }

    @IBAction func showPreferences(_ sender: Any) {
        NSApp.activate(ignoringOtherApps: true)
        preferencesController.showWindow(sender)
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
            log(.debug, "turn off")
        case .show?:
            log(.debug, "show")
        case .none:
            log(.debug, "no action")
        }
    }
}


// MARK:- RegistrationControllerDelegate

extension AppDelegate: RegistrationControllerDelegate {
    func didSubmit(license: LicenseCheck) {
        switch license {
        case .valid(let license):
            do {
                try license.save(forKey: .license, defaults: Current.defaults())
                try Current.date().save(forKey: .dateRegistered, defaults: Current.defaults())
            } catch {
                let alert = NSAlert()
                alert.alertStyle = .critical
                alert.messageText = "Error saving license key"
                alert.informativeText = error.localizedDescription
                alert.runModal()
            }
            self.stateMachine.state = .activating
        case .invalid:
            self.stateMachine.state = .unregistered
        case .error(let error):
            // TODO: allow a number of errors but eventually lock (to prevent someone from blocking the network calls)
            log(.debug, "⚠️ \(error)")
            // leave state unchanged for now
        }
    }
}


// MARK:- ShowTipJarControllerDelegate

extension AppDelegate: ShowTipJarControllerDelegate {
    func showTipJarController() {
        tipJarController.showWindow(self)
    }
}


// MARK:- ShowRegistrationControllerDelegate

extension AppDelegate: ShowRegistrationControllerDelegate {
    func showRegistrationController() {
        registrationController.showWindow(self)
    }
}


// MARK:- DidTransitionDelegate

extension AppDelegate: DidTransitionDelegate {
    func didTransition(from: AppStateMachine.State, to: AppStateMachine.State) {
        enabledMenuItem.state = (Tracker.isActive ? .on : .off)
    }
}


// MARK:- ShowTrialExpiredAlertDelegate

extension AppDelegate: ShowTrialExpiredAlertDelegate {
    func showTrialExpiredAlert(completion: (NSApplication.ModalResponse) -> ()) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "Trial expired"
        alert.informativeText = """
        Your trial period has expired 😞.

        Please support the development of Hummingbird by purchasing a license!
        """
        alert.addButton(withTitle: "Purchase")
        alert.addButton(withTitle: "Register")
        alert.addButton(withTitle: "Quit")
        let result = alert.runModal()
        completion(result)
    }
}
