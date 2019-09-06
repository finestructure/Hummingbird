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
    @IBOutlet weak var registerMenuItem: NSMenuItem!
    @IBOutlet weak var statsMenuItem: NSMenuItem!
    @IBOutlet weak var versionMenuItem: NSMenuItem!

    lazy var preferencesController: PreferencesController = {
        return PreferencesController(windowNibName: "HBPreferencesController")
    }()

    lazy var registrationController: RegistrationController = {
        return RegistrationController(windowNibName: "RegistrationController")
    }()

    lazy var statsController: StatsController = {
        return StatsController(nibName: "StatsController", bundle: nil)
    }()

    enum State {
        case launching
        case validatingLicense
        case unlicensed
        case activating
        case activated
        case deactivated
    }

    var currentState: State = .launching {
        didSet(oldValue) {
            print("Transition: \(oldValue) -> \(currentState)")
            enabledMenuItem.state = (Tracker.isActive ? .on : .off)

            switch (oldValue, currentState) {
            case (.launching, .validatingLicense):
                checkLicense()
            case (.validatingLicense, .activating):
                activate(showAlert: true, keepTrying: true)
            case (.validatingLicense, .unlicensed):
                Tracker.disable()
            case (.activating, .activated), (.deactivated, .activated):
                break
            case (.activating, .deactivated), (.activated, .deactivated):
                break
            default:
                fatalError("💣 Unhandled state transition: \(oldValue) -> \(currentState)")
            }
        }
    }
}


// App lifecycle
extension AppDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        precondition(currentState == .launching)

        if Date(forKey: .firstLaunched, defaults: defaults) == nil {
            try? Current.date().save(forKey: .firstLaunched, defaults: defaults)
        }

        statusMenu.delegate = self
        defaults.register(defaults: DefaultPreferences)

        if #available(OSX 10.14, *) { // set up notification actions
            Notifications.registerCategories()
            UNUserNotificationCenter.current().delegate = self
        }

        currentState = .validatingLicense
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
            enabledMenuItem.isHidden = (currentState == .unlicensed)
            registerMenuItem.isHidden = !enabledMenuItem.isHidden
        }
        statsController.updateView()
    }
}


// MARK:- State transitions
extension AppDelegate {

    func checkLicense() {
        let firstLaunched = Date(forKey: .firstLaunched, defaults: defaults) ?? Current.date()
        let license = License(forKey: .license, defaults: defaults)
        let licenseInfo = LicenseInfo(firstLaunched: firstLaunched, license: license)
        validate(licenseInfo) { status in
            switch status {
            case .validLicenseKey:
                print("OK: valid license")
                self.currentState = .activating
            case .inTrial:
                print("OK: in trial")
                self.currentState = .activating
            case .noLicenseKey:
                // TODO: show purchase dialog
                print("⚠️ no license")
                self.currentState = .unlicensed
            case .invalidLicenseKey:
                // TODO: show alert
                print("⚠️ invalid license")
                self.currentState = .unlicensed
            case .error(let error):
                // TODO: allow a number of errors but eventually lock (to prevent someone from blocking the network calls)
                print("⚠️ \(error)")
            }
        }
    }

    func activate(showAlert: Bool, keepTrying: Bool) {
        Tracker.enable()
        if Tracker.isActive {
            currentState = .activated
        } else {
            if showAlert {
                let alert = NSAlert()
                alert.messageText = "Accessibility permissions required"
                alert.informativeText = """
                Hummingbird requires Accessibility permissions in order to be able to move and resize windows for you.

                You can grant Accessibility permissions in "System Preferences" → "Security & Privacy" → "Privacy" → "Accessibility".

                Click "Help" for more information.

                """
                alert.addButton(withTitle: "Open System Preferences")
                alert.addButton(withTitle: "Help")
                switch alert.runModal() {
                case .alertFirstButtonReturn:
                    let url = URL.init(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane/")
                    NSWorkspace.shared.open(url)
                case .alertSecondButtonReturn:
                    let url = URL(string: "https://finestructure.co/hummingbird-accessibility")!
                    NSWorkspace.shared.open(url)
                default:
                    break
                }
            }
            if keepTrying {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.activate(showAlert: false, keepTrying: true)
                }
            } else {
                currentState = .deactivated
            }
        }
    }

    func deactivate() {
        Tracker.disable()
        currentState = .deactivated
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
        switch currentState {
        case .activated:
            deactivate()
        case .deactivated:
            activate(showAlert: true, keepTrying: false)
        default:
            break
        }
    }

    @IBAction func registerLicense(_ sender: Any) {
        NSApp.activate(ignoringOtherApps: true)
        registrationController.showWindow(sender)
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
            print("turn off")
        case .show?:
            print("show")
        case .none:
            print("no action")
        }
    }
}
