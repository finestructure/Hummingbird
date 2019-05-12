//
//  HistoryTests.swift
//  HummingbirdTests
//
//  Created by Sven A. Schmidt on 08/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import XCTest


func day(offset: Int) -> Date {
    return Calendar.current.date(byAdding: .day, value: offset, to: Date())!
}

let yesterday = day(offset: -1)


class HistoryTests: XCTestCase {

    func test_basics() {
        let m0 = Metrics(distanceMoved: 1, areaResized: 2)
        let m1 = Metrics(distanceMoved: 3, areaResized: 4)
        var h = History<Metrics>(depth: DateComponents(day: -7))
        h[.now] = m0
        XCTAssertEqual(h.count, 1)
        XCTAssertEqual(h[.now], m0)
        XCTAssertEqual(h[yesterday], nil)
        h[.now] = m1
        XCTAssertEqual(h.count, 1)
        XCTAssertEqual(h[.now], m1)
    }

    func test_modifyNested() {
        do {  // currentValue
            var h = History<Metrics>(depth: DateComponents(day: -7))
            h.currentValue.distanceMoved += 1
            XCTAssertEqual(h.currentValue.distanceMoved, 1)
            h.currentValue.distanceMoved += 1
            XCTAssertEqual(h.currentValue.distanceMoved, 2)
        }
        do {  // subscript
            let m0 = Metrics(distanceMoved: 1, areaResized: 2)
            var h = History<Metrics>(depth: DateComponents(day: -7))
            h[.now] = m0
            XCTAssertEqual(h[.now]?.distanceMoved, 1)
            h[.now]?.distanceMoved += 1
            XCTAssertEqual(h[.now]?.distanceMoved, 2)
        }
    }

    func test_iterator() {
        var h = History<Metrics>(depth: DateComponents(day: -7))
        for i in 0..<10 {
            h[day(offset: -i)] = Metrics(distanceMoved: CGFloat(i), areaResized: CGFloat(2*i))
        }
        XCTAssertEqual(h.count, 8)
        let avgDist = h.reduce(0) { $0 + $1.value.distanceMoved } / CGFloat(h.count)
        XCTAssertEqual(avgDist, 3.5)
    }

    func test_Defaultable() throws {
        let prefs = testUserDefaults()
        prefs.register(defaults: [DefaultsKeys.history.rawValue: History<Metrics>.defaultValue])
        var orig = History<Metrics>(depth: DateComponents(day: -7))
        for i in 0..<10 {
            orig[day(offset: -i)] = Metrics(distanceMoved: CGFloat(i), areaResized: CGFloat(2*i))
        }

        // test reading registered defaults
        XCTAssertEqual(History<Metrics>(forKey: .history, defaults: prefs), DefaultHistory)

        // test save
        try orig.save(forKey: .history, defaults: prefs)

        // test read
        XCTAssertEqual(History<Metrics>(forKey: .history, defaults: prefs), orig)
    }
    
}
