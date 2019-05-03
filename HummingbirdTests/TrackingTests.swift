//
//  TrackingTests.swift
//  HummingbirdTests
//
//  Created by Sven A. Schmidt on 02/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import XCTest


class TrackingTests: XCTestCase {

    func testModifiers() {
        XCTAssertEqual(Modifiers.shift.rawValue, CGEventFlags.maskShift.rawValue)
        XCTAssertEqual(Modifiers.control.rawValue, CGEventFlags.maskControl.rawValue)
        XCTAssertEqual(Modifiers.alt.rawValue, CGEventFlags.maskAlternate.rawValue)
        XCTAssertEqual(Modifiers.command.rawValue, CGEventFlags.maskCommand.rawValue)
        XCTAssertEqual(Modifiers.fn.rawValue, CGEventFlags.maskSecondaryFn.rawValue)

        let modifiers: Modifiers = [.fn, .control]
        XCTAssert(modifiers.exclusivelySet(in: [.maskSecondaryFn, .maskControl]))
        // ignore non-modifier raw values
        XCTAssert(modifiers.exclusivelySet(in: [.maskSecondaryFn, .maskControl, CGEventFlags.init(rawValue: 0x1)]))
        XCTAssert(modifiers.exclusivelySet(in: [.maskSecondaryFn, .maskControl, .maskAlphaShift]))
        XCTAssert(!modifiers.exclusivelySet(in: [.maskSecondaryFn]))
    }

    func testPrefs() {
        let bundleId = Bundle.main.bundleIdentifier!
        let suiteName = "\(bundleId).tests"
        let prefs = UserDefaults.init(suiteName: suiteName)!
        prefs.removePersistentDomain(forName: suiteName)

        let orig: Modifiers = [.fn, .control]

        // test read
        prefs.set(orig.rawValue, forKey: DefaultsKeys.moveModifiers.rawValue)
        XCTAssertEqual(readModifiers(key: .moveModifiers, defaults: prefs), orig)

        // test save
        saveModifiers(orig, key: .moveModifiers, defaults: prefs)
        guard let fetched = prefs.object(forKey: DefaultsKeys.moveModifiers.rawValue) as? UInt64 else {
            XCTFail()
            return
        }
        XCTAssertEqual(Modifiers(rawValue: fetched), orig)
    }

    func testToggleModifier() {
        let modifiers: Modifiers = [.fn, .control, .alt]
        XCTAssertEqual(modifiers.toggle(.control), [.fn, .alt])
        XCTAssertEqual(modifiers.toggle(.command), [.fn, .control, .alt, .command])
    }

}
