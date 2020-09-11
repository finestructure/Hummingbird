//
//  Functions.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 05/10/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Cocoa


func showAccessibilityAlert() {
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
        NSWorkspace.shared.open(Links.hummingbirdAccessibility)
    default:
        break
    }
}


func isTrusted(prompt: Bool) -> Bool {
    let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
    let options = [prompt: prompt] as CFDictionary
    return AXIsProcessTrustedWithOptions(options)
}


func appVersion(short: Bool = false) -> String {
    let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    if short {
        return shortVersion
    } else {
        let bundleVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "\(shortVersion) (\(bundleVersion))"
    }
}
