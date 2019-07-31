//
//  Modifiers.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 03/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Foundation


protocol Kind {
    static var defaultRawValue: UInt64 { get }
}


enum Move: Kind {
    static var defaultRawValue: UInt64 {
        return CGEventFlags([.maskSecondaryFn, .maskControl]).rawValue
    }
}


enum Resize: Kind {
    static var defaultRawValue: UInt64 {
        return CGEventFlags([.maskSecondaryFn, .maskControl, .maskAlternate]).rawValue
    }
}


struct Modifiers<K: Kind>: OptionSet, Hashable {
    let rawValue: UInt64

    static var shift: Modifiers { return Modifiers(rawValue: CGEventFlags.maskShift.rawValue) }
    static var control: Modifiers { return Modifiers(rawValue: CGEventFlags.maskControl.rawValue) }
    static var alt: Modifiers { return Modifiers(rawValue: CGEventFlags.maskAlternate.rawValue) }
    static var command: Modifiers { return Modifiers(rawValue: CGEventFlags.maskCommand.rawValue) }
    static var fn: Modifiers { return Modifiers(rawValue: CGEventFlags.maskSecondaryFn.rawValue) }

    private static var allArray: [Modifiers] { return [.shift, .fn, .control, .alt, .command] }
    private static var all: Modifiers { return Modifiers(allArray) }

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


extension Modifiers: Defaultable {
    static var defaultValue: Any { return K.defaultRawValue }
    init(forKey key: DefaultsKeys, defaults: UserDefaults) {
        let value = defaults.object(forKey: key.rawValue) as? UInt64 ?? K.defaultRawValue
        self = Modifiers(rawValue: value)
    }
    func save(forKey key: DefaultsKeys, defaults: UserDefaults) throws {
        defaults.set(rawValue, forKey: key.rawValue)
    }
}
