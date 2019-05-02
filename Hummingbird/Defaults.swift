//
//  Defaults.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 08/04/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Foundation


enum DefaultsKeys: String {
    case moveFlags = "MoveModifiers"
    case resizeFlags = "ResizeModifiers"
}


let DefaultMoveModifiers: Flags = [.fn, .control]
let DefaultResizeModifiers: Flags = [.fn, .control, .alt]


let DefaultPreferences = [
    DefaultsKeys.moveFlags.rawValue: DefaultMoveModifiers.rawValue,
    DefaultsKeys.resizeFlags.rawValue: DefaultResizeModifiers.rawValue,
]


func saveFlags(_ value: Flags, key: DefaultsKeys, defaults: UserDefaults = .standard) {
    defaults.set(value.rawValue, forKey: key.rawValue)
}


func readFlags(key: DefaultsKeys, defaults: UserDefaults = .standard) -> Flags? {
    guard let value = defaults.object(forKey: key.rawValue) as? UInt64 else { return nil }
    return Flags(rawValue: value)
}


extension Flags {

    func toggle(_ flag: Flags) -> Flags {
        if self.contains(flag) {
            return self.subtracting(flag)
        } else {
            return self.union(flag)
        }
    }

}
