//
//  Modifiers.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 03/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Foundation


struct Modifiers: OptionSet, Hashable {
    let rawValue: UInt64

    static let shift  = Modifiers(rawValue: CGEventFlags.maskShift.rawValue)
    static let control  = Modifiers(rawValue: CGEventFlags.maskControl.rawValue)
    static let alt  = Modifiers(rawValue: CGEventFlags.maskAlternate.rawValue)
    static let command  = Modifiers(rawValue: CGEventFlags.maskCommand.rawValue)
    static let fn  = Modifiers(rawValue: CGEventFlags.maskSecondaryFn.rawValue)

    static var all: Modifiers = [.shift, .control, .alt, .command, .fn]

    func exclusivelySet(in eventFlags: CGEventFlags) -> Bool {
        return self.intersection(.all) == Modifiers(rawValue: eventFlags.rawValue).intersection(.all)
    }
}
