//
//  HistoryTests.swift
//  HummingbirdTests
//
//  Created by Sven A. Schmidt on 08/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import XCTest


let ReferenceDate = Date(timeIntervalSince1970: 1234567890)  // 2009-02-13 23:31:30 +0000

func day(offset: Int, from date: Date = Current.date()) -> Date {
    return Calendar.current.date(byAdding: .day, value: offset, to: date)!
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

    func test_depth() {
        defer { Current.date = { Date() } }

        let days = [ReferenceDate] + (1...3).map { day(offset: $0, from: ReferenceDate) }

        var h = History<Metrics>(depth: DateComponents(day: -1))

        do {
            Current.date = { days[0] }
            XCTAssertEqual(Date.now, days[0])
            h[.now] = Metrics(distanceMoved: 1, areaResized: 0)
            XCTAssertEqual(h.history, [days[0].truncated(): Metrics(distanceMoved: 1, areaResized: 0)])
        }

        do {
            Current.date = { days[1] }
            XCTAssertEqual(Date.now, days[1])
            h[.now] = Metrics(distanceMoved: 2, areaResized: 0)
            XCTAssertEqual(
                h.history,
                [
                    days[0].truncated(): Metrics(distanceMoved: 1, areaResized: 0),
                    days[1].truncated(): Metrics(distanceMoved: 2, areaResized: 0)
                ]
            )
        }

        do {
            Current.date = { days[2] }
            XCTAssertEqual(Date.now, days[2])
            h[.now] = Metrics(distanceMoved: 3, areaResized: 0)
            XCTAssertEqual(
                h.history,
                [
                    days[1].truncated(): Metrics(distanceMoved: 2, areaResized: 0),
                    days[2].truncated(): Metrics(distanceMoved: 3, areaResized: 0)
                ]
            )
        }

        do {
            Current.date = { days[3] }
            XCTAssertEqual(Date.now, days[3])
            h[.now] = Metrics(distanceMoved: 4, areaResized: 0)
            XCTAssertEqual(
                h.history,
                [
                    days[2].truncated(): Metrics(distanceMoved: 3, areaResized: 0),
                    days[3].truncated(): Metrics(distanceMoved: 4, areaResized: 0)
                ]
            )
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
        defer { Current.date = { Date() } }

        let prefs = testUserDefaults()
        prefs.register(defaults: [DefaultsKeys.history.rawValue: History<Metrics>.defaultValue])
        var orig = History<Metrics>(depth: DateComponents(day: -7))
        for i in 0...10 {
            let date = day(offset: i, from: ReferenceDate)
            Current.date = { date }
            orig.currentValue = Metrics(distanceMoved: CGFloat(i), areaResized: CGFloat(2*i))
        }

        // test reading registered defaults
        XCTAssertEqual(History<Metrics>(forKey: .history, defaults: prefs), History<Metrics>(depth: DateComponents(day: -1000)))

        // test save
        try orig.save(forKey: .history, defaults: prefs)

        // test read
        let loaded = History<Metrics>(forKey: .history, defaults: prefs)
        XCTAssertEqual(loaded, orig)
        XCTAssertEqual(loaded.total, orig.total)
        XCTAssertEqual(loaded.average, orig.average)
    }

    func test_aggregates() {
        var h = History<Metrics>(depth: DateComponents(day: -7))
        for i in 0...7 {
            h[day(offset: -i)] = Metrics(distanceMoved: CGFloat(i), areaResized: CGFloat(2*i))
        }

        XCTAssertEqual(h.max { $0.1.distanceMoved < $1.1.distanceMoved }?.1.distanceMoved, 7)
        XCTAssertEqual(h.max { $0.1.areaResized < $1.1.areaResized }?.1.areaResized, 14)

        XCTAssertEqual(h.total, Metrics(distanceMoved: 28, areaResized: 56))

        XCTAssertEqual(h.average, Metrics(distanceMoved: 3.5, areaResized: 7.0))
    }

    func test_keepAggregates() {
        defer { Current.date = { Date() } }

        // ensure aggregates are kept around even if values are pushed off the history
        var h = History<Metrics>(depth: DateComponents(day: -3))
        for i in 0...10 {
            let date = day(offset: i, from: ReferenceDate)
            Current.date = { date }
            h.currentValue = Metrics(distanceMoved: CGFloat(i), areaResized: CGFloat(2*i))
        }
        XCTAssertEqual(
            h.history.dict,
            [
                day(offset: 10, from: ReferenceDate).truncated(): Metrics(distanceMoved: 10, areaResized: 20),
                day(offset: 9, from: ReferenceDate).truncated(): Metrics(distanceMoved: 9, areaResized: 18),
                day(offset: 8, from: ReferenceDate).truncated(): Metrics(distanceMoved: 8, areaResized: 16),
                day(offset: 7, from: ReferenceDate).truncated(): Metrics(distanceMoved: 7, areaResized: 14),
            ]
        )

        XCTAssertEqual(h.total, Metrics(distanceMoved: 55, areaResized: 110))
        XCTAssertEqual(h.average, Metrics(distanceMoved: 5, areaResized: 10))
    }

    func test_performance_insert() {
        let prefs = testUserDefaults()
        prefs.register(defaults: [DefaultsKeys.history.rawValue: History<Metrics>.defaultValue])
        let depth = 4000
        var orig = History<Metrics>(depth: DateComponents(day: -depth))
        self.measure {
            for i in 0...depth {
                let date = day(offset: -i)
                orig[date] = Metrics(distanceMoved: CGFloat(i), areaResized: CGFloat(2*i))
            }
        }
        XCTAssertEqual(orig.count, depth+1)
    }

    func test_performance_save() {
        let prefs = testUserDefaults()
        prefs.register(defaults: [DefaultsKeys.history.rawValue: History<Metrics>.defaultValue])
        let depth = 4000
        var orig = History<Metrics>(depth: DateComponents(day: -depth))
        for i in 0...depth {
            let date = day(offset: -i)
            orig[date] = Metrics(distanceMoved: CGFloat(i), areaResized: CGFloat(2*i))
        }

        XCTAssertEqual(orig.count, depth+1)

        self.measure {
            XCTAssertNotNil(try? orig.save(forKey: .history, defaults: prefs))
        }
    }

    func test_performance_load() {
        let prefs = testUserDefaults()
        prefs.register(defaults: [DefaultsKeys.history.rawValue: History<Metrics>.defaultValue])
        let depth = 4000
        var orig = History<Metrics>(depth: DateComponents(day: -depth))
        for i in 0...depth {
            let date = day(offset: -i)
            orig[date] = Metrics(distanceMoved: CGFloat(i), areaResized: CGFloat(2*i))
        }

        XCTAssertEqual(orig.count, depth+1)

        XCTAssertNotNil(try? orig.save(forKey: .history, defaults: prefs))

        self.measure {
            let _ = History<Metrics>(forKey: .history, defaults: prefs)
        }

        let loaded = History<Metrics>(forKey: .history, defaults: prefs)
        XCTAssertEqual(loaded, orig)
    }

    func test_milestone_reached_average() {
        defer { Current.date = { Date() } }

        var hist = History<Metrics>(depth: DateComponents(day: -10))
        XCTAssert(hist.isAverageMilestone(Metrics(distanceMoved: 1, areaResized: 0)))

        hist.currentValue = Metrics(distanceMoved: 1, areaResized: 0)
        XCTAssertEqual(hist.average, Metrics(distanceMoved: 1, areaResized: 0))

        XCTAssertFalse(hist.isAverageMilestone(Metrics(distanceMoved: 0.5, areaResized: 0)))
        XCTAssert(hist.isAverageMilestone(Metrics(distanceMoved: 1.5, areaResized: 0)))

        Current.date = { day(offset: 1, from: ReferenceDate) }
        hist.currentValue = Metrics(distanceMoved: 2, areaResized: 1)
        XCTAssertEqual(hist.average, Metrics(distanceMoved: 1.5, areaResized: 0.5))

        XCTAssertFalse(hist.isAverageMilestone(Metrics(distanceMoved: 1.5, areaResized: 0)))
        XCTAssert(hist.isAverageMilestone(Metrics(distanceMoved: 1.5, areaResized: 1)))
    }
}
