//
//  Defaults.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 08/04/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Foundation


enum DefaultsKeys: String {
    case moveModifiers = "MoveModifiers"
    case resizeModifiers = "ResizeModifiers"
}


let DefaultMoveModifiers: Modifiers = [.fn, .control]
let DefaultResizeModifiers: Modifiers = [.fn, .control, .alt]


let DefaultPreferences = [
    DefaultsKeys.moveModifiers.rawValue: DefaultMoveModifiers.rawValue,
    DefaultsKeys.resizeModifiers.rawValue: DefaultResizeModifiers.rawValue,
]


func saveModifiers(_ value: Modifiers, key: DefaultsKeys, defaults: UserDefaults = .standard) {
    defaults.set(value.rawValue, forKey: key.rawValue)
}


func readModifiers(key: DefaultsKeys, defaults: UserDefaults = .standard) -> Modifiers? {
    guard let value = defaults.object(forKey: key.rawValue) as? UInt64 else { return nil }
    return Modifiers(rawValue: value)
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
