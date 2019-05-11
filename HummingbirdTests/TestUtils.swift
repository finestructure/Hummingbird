//
//  TestUtils.swift
//  HummingbirdTests
//
//  Created by Sven A. Schmidt on 09/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Foundation


func testUserDefaults() -> UserDefaults {
    let bundleId = Bundle.main.bundleIdentifier!
    let suiteName = "\(bundleId).tests"
    let prefs = UserDefaults(suiteName: suiteName)!
    prefs.removePersistentDomain(forName: suiteName)
    return prefs
}

