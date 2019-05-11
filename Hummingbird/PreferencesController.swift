//
//  PreferencesController.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 02/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Cocoa

class PreferencesController: NSWindowController {

    @IBOutlet weak var moveAlt: NSButton!
    @IBOutlet weak var moveCommand: NSButton!
    @IBOutlet weak var moveControl: NSButton!
    @IBOutlet weak var moveFn: NSButton!
    @IBOutlet weak var moveShift: NSButton!

    @IBOutlet weak var resizeAlt: NSButton!
    @IBOutlet weak var resizeCommand: NSButton!
    @IBOutlet weak var resizeControl: NSButton!
    @IBOutlet weak var resizeFn: NSButton!
    @IBOutlet weak var resizeShift: NSButton!


    @IBAction func modifierClicked(_ sender: NSButton) {
        let moveButtons = [moveAlt, moveCommand, moveControl, moveFn, moveShift]
        let moveModifiers: [Modifiers<Move>] = [.alt, .command, .control, .fn, .shift]
        let resizeButtons = [resizeAlt, resizeCommand, resizeControl, resizeFn, resizeShift]
        let resizeModifiers: [Modifiers<Resize>] = [.alt, .command, .control, .fn, .shift]
        let modifierForButton = Dictionary(
            uniqueKeysWithValues: zip(moveButtons + resizeButtons,
                                      moveModifiers.map { $0.rawValue } + resizeModifiers.map { $0.rawValue } )
        )
        if let modifier = modifierForButton[sender] {
            if moveButtons.contains(sender) {
                let modifiers = Modifiers<Move>(forKey: .moveModifiers)
                let m = Modifiers<Move>(rawValue: modifier)
                try? modifiers.toggle(m).save(forKey: .moveModifiers)
            } else if resizeButtons.contains(sender) {
                let modifiers = Modifiers<Resize>(forKey: .resizeModifiers)
                let m = Modifiers<Resize>(rawValue: modifier)
                try? modifiers.toggle(m).save(forKey: .resizeModifiers)
            }
        }
    }
    
}

extension PreferencesController: NSWindowDelegate {

    func windowDidChangeOcclusionState(_ notification: Notification) {
        do {
            let prefs = Modifiers<Move>(forKey: .moveModifiers)
            let buttons = [moveAlt, moveCommand, moveControl, moveFn, moveShift]
            let allModifiers: [Modifiers<Move>] = [.alt, .command, .control, .fn, .shift]
            let buttonForModifier = Dictionary(uniqueKeysWithValues: zip(allModifiers, buttons))
            for (modifier, button) in buttonForModifier {
                button?.state = prefs.contains(modifier) ? .on : .off
            }
        }

        do {
            let prefs = Modifiers<Resize>(forKey: .resizeModifiers)
            let buttons = [resizeAlt, resizeCommand, resizeControl, resizeFn, resizeShift]
            let allModifiers: [Modifiers<Resize>] = [.alt, .command, .control, .fn, .shift]
            let buttonForModifier = Dictionary(uniqueKeysWithValues: zip(allModifiers, buttons))
            for (modifier, button) in buttonForModifier {
                button?.state = prefs.contains(modifier) ? .on : .off
            }
        }
    }

}
