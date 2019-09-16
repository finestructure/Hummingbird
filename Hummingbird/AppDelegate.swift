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


struct FeatureFlags {
    static let commercial = false
}


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


    var stateMachine: StateMachine<AppDelegate>!
}


// App lifecycle
extension AppDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        stateMachine = StateMachine<AppDelegate>(initialState: .launching, delegate: self)

        precondition(stateMachine.state == .launching)

        if Date(forKey: .firstLaunched, defaults: defaults) == nil {
            try? Current.date().save(forKey: .firstLaunched, defaults: defaults)
        }

        statusMenu.delegate = self
        defaults.register(defaults: DefaultPreferences)

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
            sendCoffeeMenuItem.isHidden = FeatureFlags.commercial
        }
        statsController.updateView()
    }
}


// MARK:- State Machine

extension AppDelegate: StateMachineDelegate {
    enum State: TransitionDelegate {
        case launching
        case validatingLicense
        case unregistered
        case activating
        case activated
        case deactivated

        func shouldTransition(from: AppDelegate.State, to: AppDelegate.State) -> Decision<AppDelegate.State> {
            log(.debug, "Transition: \(from) -> \(to)")

            switch (from, to) {
                case (.launching, .validatingLicense):
                    return .continue
                case (.activated, .activating):
                    // license check succeeded while already active (i.e. when in trial)
                    return .continue
                case (.validatingLicense, .activating),  (.unregistered, .activating):
                    return .continue
                case (.validatingLicense, .deactivated):
                    // validating error
                    return .continue
                case (.validatingLicense, .unregistered):
                    return .continue
                case (.activating, .activated), (.deactivated, .activated):
                    return .continue
                case (.activating, .deactivated), (.activated, .deactivated):
                    return .continue
                case (.unregistered, .unregistered):
                    // license check failed while already unregistered
                    return .continue
                case (.activated, .unregistered):
                    // license check failed while on trial
                    return .continue
                case (.deactivated, .activating):
                    return .continue
                case (.deactivated, .deactivated):
                    // activation error (lack of permissions)
                    return .continue
                default:
                    assertionFailure("💣 Unhandled state transition: \(from) -> \(to)")
                    return .abort
            }

        }
    }

    func didTransition(from: AppDelegate.State, to: AppDelegate.State) {
        enabledMenuItem.state = (Tracker.isActive ? .on : .off)

        switch (from, to) {
            case (.launching, .validatingLicense):
                checkLicense()
            case (.validatingLicense, .activating),  (.unregistered, .activating):
                activate(showAlert: true, keepTrying: true)
            case (.validatingLicense, .unregistered):
                Tracker.disable()
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
                switch alert.runModal() {
                    case .alertFirstButtonReturn:
                        presentPurchaseView()
                    case .alertSecondButtonReturn:
                        registrationController.showWindow(self)
                    default:
                        NSApp.terminate(self)
                }
            default:
                break
        }
    }
}


// MARK:- State transitions
extension AppDelegate {

    func checkLicense() {
        // Yes, it is really that simple to circumvent the license check. But if you can build it from source
        // it's free of charge anyway. Although it'd be great if you'd send a coffee!
        if FeatureFlags.commercial {
            let firstLaunched = Date(forKey: .firstLaunched, defaults: defaults) ?? Current.date()
            let license = License(forKey: .license, defaults: defaults)
            let licenseInfo = LicenseInfo(firstLaunched: firstLaunched, license: license)
            validate(licenseInfo) { status in
                switch status {
                    case .validLicenseKey:
                        log(.debug, "OK: valid license")
                        self.stateMachine.state = .activating
                    case .inTrial:
                        log(.debug, "OK: in trial")
                        self.stateMachine.state = .activating
                    case .noLicenseKey:
                        log(.debug, "⚠️ no license")
                        self.stateMachine.state = .unregistered
                    case .invalidLicenseKey:
                        log(.debug, "⚠️ invalid license")
                        self.stateMachine.state = .unregistered
                    case .error(let error):
                        // TODO: allow a number of errors but eventually lock (to prevent someone from blocking the network calls)
                        log(.debug, "⚠️ \(error)")
                        // We're graceful here to avoid nagging folks with a license who are offline.
                        // Yes, you can block the app from connecting but if you can figure that out you can probably also build
                        // and run the free app. Please support indie software :)
                        self.stateMachine.state = .activating
                }
            }
        } else {
            log(.debug, "Open source version")
            stateMachine.state = .activating
        }
    }

    func activate(showAlert: Bool, keepTrying: Bool) {
        Tracker.enable()
        if Tracker.isActive {
            stateMachine.state = .activated
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
                    NSWorkspace.shared.open(Links.securitySystemPreferences)
                case .alertSecondButtonReturn:
                    NSWorkspace.shared.open(Links.accessibilityHelp)
                default:
                    break
                }
            }
            if keepTrying {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.activate(showAlert: false, keepTrying: true)
                }
            } else {
                stateMachine.state = .deactivated
            }
        }
    }

    func deactivate() {
        Tracker.disable()
        stateMachine.state = .deactivated
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
        switch stateMachine.state {
            case .activated:
                deactivate()
            case .deactivated:
                checkLicense()
            default:
                break
        }
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
                try license.save(forKey: .license, defaults: defaults)
                try Current.date().save(forKey: .dateRegistered, defaults: defaults)
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
        }
    }
}


// MARK:- PreferencesControllerDelegate

extension AppDelegate: PreferencesControllerDelegate {
    func didRequestRegistrationController() {
        registrationController.showWindow(self)
    }

    func didRequestTipJarController() {
        tipJarController.showWindow(self)
    }
}
