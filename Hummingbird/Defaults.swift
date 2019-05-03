//
//  Defaults.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 08/04/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Foundation


protocol UserDefaultable {
    init?(key: DefaultsKeys, defaults: UserDefaults)
    func save(key: DefaultsKeys, defaults: UserDefaults)
}


extension UserDefaultable {
    init?(key: DefaultsKeys) {
        self.init(key: key, defaults: .standard)
    }

    func save(key: DefaultsKeys) {
        save(key: key, defaults: .standard)
    }
}


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
