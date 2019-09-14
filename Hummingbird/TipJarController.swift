//
//  TipJarController.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 01/08/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Cocoa


class TipJarController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
    @IBAction func smallCoffeeButtonClicked(_ sender: Any) {
        NSWorkspace.shared.open(Links.gumroadTip(size: .small))
    }

    @IBAction func mediumCoffeeButtonClicked(_ sender: Any) {
        NSWorkspace.shared.open(Links.gumroadTip(size: .medium))
    }

    @IBAction func largeCoffeeButtonClicked(_ sender: Any) {
        NSWorkspace.shared.open(Links.gumroadTip(size: .large))
    }
}
