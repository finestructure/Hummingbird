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
    case history
}


let DefaultMoveModifiers: Modifiers = [.fn, .control]
let DefaultResizeModifiers: Modifiers = [.fn, .control, .alt]
let DefaultHistory = History<Metrics>(depth: DateComponents(day: -30))


let DefaultPreferences = [
    DefaultsKeys.moveModifiers.rawValue: DefaultMoveModifiers.rawValue,
    DefaultsKeys.resizeModifiers.rawValue: DefaultResizeModifiers.rawValue,
    DefaultsKeys.distanceMoved.rawValue: 0 as Any,
    DefaultsKeys.areaResized.rawValue: 0 as Any
]


protocol Defaultable {
    static var defaultValue: Any { get }
    init?(forKey: DefaultsKeys, defaults: UserDefaults)
    func save(forKey: DefaultsKeys, defaults: UserDefaults) throws
}


extension Defaultable {
    init?(forKey key: DefaultsKeys) { self.init(forKey: key, defaults: defaults) }

    func save(forKey key: DefaultsKeys) throws {
        try save(forKey: key, defaults: defaults)
    }
}
