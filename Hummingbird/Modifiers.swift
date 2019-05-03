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

    private static var allArray: [Modifiers] = [.shift, .fn, .control, .alt, .command]
    static var all: Modifiers = Modifiers(allArray)

    func exclusivelySet(in eventFlags: CGEventFlags) -> Bool {
        return self.intersection(.all) == Modifiers(rawValue: eventFlags.rawValue).intersection(.all)
    }
}


extension Modifiers {
    func toggle(_ modifier: Modifiers) -> Modifiers {
        if self.contains(modifier) {
            return self.subtracting(modifier)
        } else {
            return self.union(modifier)
        }
    }
}


extension Modifiers: UserDefaultable {
    init?(key: DefaultsKeys, defaults: UserDefaults) {
        guard let value = defaults.object(forKey: key.rawValue) as? UInt64 else { return nil }
        self = Modifiers(rawValue: value)
    }

    func save(key: DefaultsKeys, defaults: UserDefaults) {
        defaults.set(self.rawValue, forKey: key.rawValue)
    }
}


extension Modifiers: CustomStringConvertible {
    var description: String {
        func str(_ modifier: Modifiers) -> String {
            switch modifier {
            case .shift:
                return "shift"
            case .control:
                return "control"
            case .alt:
                return "alt"
            case .command:
                return "command"
            case .fn:
                return "fn"
            default:
                return "?"
            }
        }
        let res = Modifiers.allArray.compactMap { m in
            return self.contains(m) ? str(m) : nil
        }
        return res.joined(separator: " ")
    }
}
