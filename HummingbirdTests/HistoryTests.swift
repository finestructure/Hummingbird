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

let today = day(offset: 0)
let yesterday = day(offset: -1)


class HistoryTests: XCTestCase {

    func testHistory() {
        let m0 = Metrics(distanceMoved: 1, areaResized: 2)
        let m1 = Metrics(distanceMoved: 3, areaResized: 4)
        var h = History<Metrics>(depth: DateComponents(day: -7))
        h[today] = m0
        XCTAssertEqual(h.count, 1)
        XCTAssertEqual(h[today], m0)
        XCTAssertEqual(h[yesterday], nil)
        h[today] = m1
        XCTAssertEqual(h.count, 1)
        XCTAssertEqual(h[today], m1)
    }

    func testHistoryIterator() {
        var h = History<Metrics>(depth: DateComponents(day: -7))
        for i in 0..<10 {
            h[day(offset: -i)] = Metrics(distanceMoved: CGFloat(i), areaResized: CGFloat(2*i))
        }
        XCTAssertEqual(h.count, 8)
        let avgDist = h.reduce(0) { $0 + $1.value.distanceMoved } / CGFloat(h.count)
        XCTAssertEqual(avgDist, 3.5)
    }

    func testHistoryPrefs() throws {
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
