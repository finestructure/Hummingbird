//
//  HummingbirdTests.swift
//  HummingbirdTests
//
//  Created by Sven A. Schmidt on 02/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import XCTest


class HummingbirdTests: XCTestCase {

    func testAreaDelta() {
        do {
            let a = CGSize(width: 2, height: 2)
            let delta = CGPoint(x: 2, y: 1)
            XCTAssertEqual(areaDelta(a: a, d: delta), 8.0)
        }
        do {
            let a = CGSize(width: 2, height: 2)
            let delta = CGPoint(x: 2, y: -1)
            XCTAssertEqual(areaDelta(a: a, d: delta), 4.0)
        }
    }

    func testFloatInterpolation() {
        XCTAssertEqual("\(scaled: 0)", "0.0")
        XCTAssertEqual("\(scaled: 1.2345)", "1.2")
        XCTAssertEqual("\(scaled: 1.25)", "1.3")
        XCTAssertEqual("\(scaled: 1234.5)", "1.2k")
        XCTAssertEqual("\(scaled: 1254.5)", "1.3k")
        XCTAssertEqual("\(scaled: 1234567.8)", "1.2M")
        XCTAssertEqual("\(scaled: 1954567.8)", "2.0M")
    }

    func testMetricsInterpolation() {
        do {
            let m = Metrics(distanceMoved: 42, areaResized: 99)
            XCTAssertEqual("\(m)", "Distance: 42.0, Area: 99.0")
        }
        do {
            let m = Metrics(distanceMoved: 35307.18776075068, areaResized: 14870743)
            XCTAssertEqual("\(m)", "Distance: 35.3k, Area: 14.9M")
        }
    }

}
