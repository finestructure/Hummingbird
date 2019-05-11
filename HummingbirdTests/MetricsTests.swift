//
//  MetricsTests.swift
//  HummingbirdTests
//
//  Created by Sven A. Schmidt on 11/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import XCTest


class MetricsTests: XCTestCase {

    func test_appendInterpolation() {
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
