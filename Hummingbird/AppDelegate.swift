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
    @IBOutlet weak var accessibilityStatusMenuItem: NSMenuItem!
    @IBOutlet weak var registerMenuItem: NSMenuItem!
    @IBOutlet weak var sendCoffeeMenuItem: NSMenuItem!
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

    var stateMachine = AppStateMachine()
}


// App lifecycle
extension AppDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if Date(forKey: .firstLaunched, defaults: Current.defaults()) == nil {
            try? Current.date().save(forKey: .firstLaunched, defaults: Current.defaults())
        }

        statusMenu.delegate = self
        Current.defaults().register(defaults: DefaultPreferences)

        stateMachine.state = .validatingLicense
    }

    override func awakeFromNib() {
        if Current.defaults().bool(forKey: DefaultsKeys.showMenuIcon.rawValue) {
            addStatusItemToMenubar()
        } else {
            NSApp.activate(ignoringOtherApps: true)
            preferencesController.showWindow(nil)
            return
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
            accessibilityStatusMenuItem.isHidden = isTrusted(prompt: false)
        }
        do {
            registerMenuItem.isHidden = (stateMachine.state != .unregistered)
        }
        do {
            sendCoffeeMenuItem.isHidden = Current.featureFlags.commercial
        }
    }
}

// MARK:- Manage status item

extension AppDelegate {

    func addStatusItemToMenubar() {
        statusItem = {
            let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            statusItem.menu = statusMenu
            statusItem.button?.image = NSImage(named: "MenuIcon")
            return statusItem
        }()
        statusMenu.autoenablesItems = false
        versionMenuItem.title = "Version: \(appVersion())"
    }

    func removeStatusItemFromMenubar() {
        guard let statusItem = statusItem else { return }
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    func updateStatusItemVisibility() {
        Current.defaults().bool(forKey: DefaultsKeys.showMenuIcon.rawValue)
            ? addStatusItemToMenubar()
            : removeStatusItemFromMenubar()
    }

}


// MARK:- IBActions
extension AppDelegate {

    @IBAction func accessibilityStatusClicked(_ sender: Any) {
        showAccessibilityAlert()
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

    @IBAction func helpClicked(_ sender: Any) {
        NSWorkspace.shared.open(Links.hummingbirdHelp)
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


// MARK:- ShouldTermindateDelegate

extension AppDelegate: ShouldTermindateDelegate {
    func shouldTerminate() {
        NSApp.terminate(self)
    }
}


// MARK:- PresentPurchaseViewDelegate

extension AppDelegate: PresentPurchaseViewDelegate {
    func presentPurchaseView() {
        NSWorkspace.shared.open(Links.gumroadProductPage)
    }
}
