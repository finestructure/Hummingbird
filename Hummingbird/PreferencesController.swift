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


    // TODO: do this in the equivalent of viewWillAppear
    // https://stackoverflow.com/a/25981832/1444152
    override func windowDidLoad() {
        let allModifiers: [Modifiers] = [.alt, .command, .control, .fn, .shift]

        do {
            let modifiers = readModifiers(key: .moveModifiers) ?? DefaultMoveModifiers
            let buttons = [moveAlt, moveCommand, moveControl, moveFn, moveShift]
            let buttonForModifier = Dictionary(uniqueKeysWithValues: zip(allModifiers, buttons))
            for (modifier, button) in buttonForModifier {
                button?.state = modifiers.contains(modifier) ? .on : .off
            }
        }

        do {
            let modifiers = readModifiers(key: .resizeModifiers) ?? DefaultResizeModifiers
            let buttons = [resizeAlt, resizeCommand, resizeControl, resizeFn, resizeShift]
            let buttonForModifier = Dictionary(uniqueKeysWithValues: zip(allModifiers, buttons))
            for (modifier, button) in buttonForModifier {
                button?.state = modifiers.contains(modifier) ? .on : .off
            }
        }
    }

    @IBAction func modifierClicked(_ sender: NSButton) {
        let allModifiers: [Modifiers] = [.alt, .command, .control, .fn, .shift]
        let moveButtons = [moveAlt, moveCommand, moveControl, moveFn, moveShift]
        let resizeButtons = [resizeAlt, resizeCommand, resizeControl, resizeFn, resizeShift]
        let modifierForButton = Dictionary(uniqueKeysWithValues: zip(moveButtons + resizeButtons, allModifiers + allModifiers))
        if let modifier = modifierForButton[sender] {
            if moveButtons.contains(sender) {
                let modifiers = readModifiers(key: .moveModifiers) ?? DefaultMoveModifiers
                saveModifiers(modifiers.toggle(modifier), key: .moveModifiers)
            } else if resizeButtons.contains(sender) {
                let modifiers = readModifiers(key: .resizeModifiers) ?? DefaultResizeModifiers
                saveModifiers(modifiers.toggle(modifier), key: .resizeModifiers)
            }
        }
    }
    
}
