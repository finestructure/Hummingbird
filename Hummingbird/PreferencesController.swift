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
    override func windowDidLoad() {
        let allFlags: [Flags] = [.alt, .command, .control, .fn, .shift]

        do {
            let moveFlags = readFlags(key: .moveFlags) ?? DefaultMoveModifiers
            let buttons = [moveAlt, moveCommand, moveControl, moveFn, moveShift]
            let buttonForFlag = Dictionary(uniqueKeysWithValues: zip(allFlags, buttons))
            for (flag, button) in buttonForFlag {
                button?.state = moveFlags.contains(flag) ? .on : .off
            }
        }

        do {
            let resizeFlags = readFlags(key: .resizeFlags) ?? DefaultResizeModifiers
            let buttons = [resizeAlt, resizeCommand, resizeControl, resizeFn, resizeShift]
            let buttonForFlag = Dictionary(uniqueKeysWithValues: zip(allFlags, buttons))
            for (flag, button) in buttonForFlag {
                button?.state = resizeFlags.contains(flag) ? .on : .off
            }
        }
    }

    @IBAction func modifierClicked(_ sender: NSButton) {
        let allFlags: [Flags] = [.alt, .command, .control, .fn, .shift]
        let moveButtons = [moveAlt, moveCommand, moveControl, moveFn, moveShift]
        let resizeButtons = [resizeAlt, resizeCommand, resizeControl, resizeFn, resizeShift]
        let flagForButton = Dictionary(uniqueKeysWithValues: zip(moveButtons + resizeButtons, allFlags + allFlags))
        if let flag = flagForButton[sender] {
            if moveButtons.contains(sender) {
                let flags = readFlags(key: .moveFlags) ?? DefaultMoveModifiers
                saveFlags(flags.toggle(flag), key: .moveFlags)
            } else if resizeButtons.contains(sender) {
                let flags = readFlags(key: .resizeFlags) ?? DefaultResizeModifiers
                saveFlags(flags.toggle(flag), key: .resizeFlags)
            }
        }
    }
    
}
