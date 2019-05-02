//
//  TrackingTests.swift
//  HummingbirdTests
//
//  Created by Sven A. Schmidt on 02/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import XCTest


class TrackingTests: XCTestCase {

    func testFlags() {
        XCTAssertEqual(Flags.shift.rawValue, CGEventFlags.maskShift.rawValue)
        XCTAssertEqual(Flags.control.rawValue, CGEventFlags.maskControl.rawValue)
        XCTAssertEqual(Flags.alt.rawValue, CGEventFlags.maskAlternate.rawValue)
        XCTAssertEqual(Flags.command.rawValue, CGEventFlags.maskCommand.rawValue)
        XCTAssertEqual(Flags.fn.rawValue, CGEventFlags.maskSecondaryFn.rawValue)

        let flags: Flags = [.fn, .control]
        XCTAssert(flags.exclusivelySet(in: [.maskSecondaryFn, .maskControl]))
        // ignore non-modifier raw values
        XCTAssert(flags.exclusivelySet(in: [.maskSecondaryFn, .maskControl, CGEventFlags.init(rawValue: 0x1)]))
        XCTAssert(flags.exclusivelySet(in: [.maskSecondaryFn, .maskControl, .maskAlphaShift]))
        XCTAssert(!flags.exclusivelySet(in: [.maskSecondaryFn]))
    }

    func testPrefs() {
        let uuid = UUID().uuidString
//        let bundle = Bundle(for: TrackingTests.Type)
        let defName = "co.finestructure.Hummingbird"
    }

}
