//
//  TipJarController.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 01/08/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Cocoa


enum Tip: String {
    case small
    case medium
    case large

    var url: URL {
        return URL(string: "https://gum.co/hb-tip-\(rawValue)?wanted=true")!
    }
}


class TipJarController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
    @IBAction func smallCoffeeButtonClicked(_ sender: Any) {
        purchase(tip: .small)
    }

    @IBAction func mediumCoffeeButtonClicked(_ sender: Any) {
        purchase(tip: .medium)
    }

    @IBAction func largeCoffeeButtonClicked(_ sender: Any) {
        purchase(tip: .large)
    }

    func purchase(tip: Tip) {
        NSWorkspace.shared.open(tip.url)
    }
}
