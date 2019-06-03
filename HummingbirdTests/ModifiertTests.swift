//
//  ModifiertTests.swift
//  HummingbirdTests
//
//  Created by Sven A. Schmidt on 11/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import XCTest


class ModifierTests: XCTestCase {

    func test_staticVars() {
        XCTAssertEqual(Modifiers<Move>.shift.rawValue, CGEventFlags.maskShift.rawValue)
        XCTAssertEqual(Modifiers<Move>.control.rawValue, CGEventFlags.maskControl.rawValue)
        XCTAssertEqual(Modifiers<Move>.alt.rawValue, CGEventFlags.maskAlternate.rawValue)
        XCTAssertEqual(Modifiers<Move>.command.rawValue, CGEventFlags.maskCommand.rawValue)
        XCTAssertEqual(Modifiers<Move>.fn.rawValue, CGEventFlags.maskSecondaryFn.rawValue)
    }

    func test_exclusivelySet() {
        let modifiers: Modifiers<Move> = [.fn, .control]
        XCTAssert(modifiers.exclusivelySet(in: [.maskSecondaryFn, .maskControl]))
        // ignore non-modifier raw values
        XCTAssert(modifiers.exclusivelySet(in: [.maskSecondaryFn, .maskControl, .init(rawValue: 0x1)]))
        XCTAssert(modifiers.exclusivelySet(in: [.maskSecondaryFn, .maskControl, .maskAlphaShift]))
        XCTAssert(!modifiers.exclusivelySet(in: [.maskSecondaryFn]))

        do {
            let mods: Modifiers<Move> = [.shift]
            XCTAssert(mods.exclusivelySet(in: [.maskShift, .init(rawValue: 0x22)]))
        }
    }

    func test_Defaultable() throws {
        let prefs = testUserDefaults()
        let orig: Modifiers<Move> = [.fn, .control]

        // test read
        prefs.set(orig.rawValue, forKey: DefaultsKeys.moveModifiers.rawValue)
        XCTAssertEqual(Modifiers<Move>(forKey: .moveModifiers, defaults: prefs), orig)

        // test save
        try orig.save(forKey: .moveModifiers, defaults: prefs)
        guard let fetched = prefs.object(forKey: DefaultsKeys.moveModifiers.rawValue) as? UInt64 else {
            XCTFail()
            return
        }
        XCTAssertEqual(Modifiers(rawValue: fetched), orig)
    }

    func test_isEmpty() {
        do {
            let m: Modifiers<Move> = []
            XCTAssert(m.isEmpty)
        }
        do {
            let m: Modifiers<Move> = [.fn, .control]
            XCTAssert(!m.isEmpty)
        }
    }

    func test_toggle() {
        let modifiers: Modifiers<Move> = [.fn, .control, .alt]
        XCTAssertEqual(modifiers.toggle(.control), [.fn, .alt])
        XCTAssertEqual(modifiers.toggle(.command), [.fn, .control, .alt, .command])
    }

    func test_CustomStringConvertible() {
        XCTAssertEqual("\(Modifiers<Move>([.fn, .control]))", "fn control")
    }

}
