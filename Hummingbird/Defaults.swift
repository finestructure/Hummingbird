//
//  Defaults.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 08/04/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Foundation


let defaults = UserDefaults(suiteName: "co.finestructure.Hummingbird.prefs") ?? .standard


enum DefaultsKeys: String {
    case moveModifiers
    case resizeModifiers
    case distanceMoved
    case areaResized
}


let DefaultMoveModifiers: Modifiers = [.fn, .control]
let DefaultResizeModifiers: Modifiers = [.fn, .control, .alt]


let DefaultPreferences = [
    DefaultsKeys.moveModifiers.rawValue: DefaultMoveModifiers.rawValue,
    DefaultsKeys.resizeModifiers.rawValue: DefaultResizeModifiers.rawValue,
    DefaultsKeys.distanceMoved.rawValue: 0 as Any,
    DefaultsKeys.areaResized.rawValue: 0 as Any
]
