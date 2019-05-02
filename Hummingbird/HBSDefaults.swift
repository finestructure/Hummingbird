//
//  HBSDefaults.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 08/04/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Foundation


struct DefaultsKeys {
    static let moveFlags = "HoverMoveModifierFlags"
    static let resizeFlags = "HoverResizeModifierFlags"
}


public class HBSDefaults: NSObject {
    @objc public var moveFlags = Set<String>()
    @objc public var resizeFlags = Set<String>()

    @objc public init(defaults: UserDefaults) {
        super.init()
        do {
            if let flags = defaults.string(forKey: DefaultsKeys.moveFlags) {
                moveFlags = Set(flags.split(separator: ",").map(String.init))
            }
        }
        do {
            if let flags = defaults.string(forKey: DefaultsKeys.resizeFlags) {
                resizeFlags = Set(flags.split(separator: ",").map(String.init))
            }
        }
    }

}
