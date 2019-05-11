//
//  HummingbirdTests.swift
//  HummingbirdTests
//
//  Created by Sven A. Schmidt on 02/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import XCTest


class HummingbirdTests: XCTestCase {

    func testFloatInterpolation() {
        XCTAssertEqual("\(scaled: 0)", "0.0")
        XCTAssertEqual("\(scaled: 1.2345)", "1.2")
        XCTAssertEqual("\(scaled: 1.25)", "1.3")
        XCTAssertEqual("\(scaled: 1234.5)", "1.2k")
        XCTAssertEqual("\(scaled: 1254.5)", "1.3k")
        XCTAssertEqual("\(scaled: 1234567.8)", "1.2M")
        XCTAssertEqual("\(scaled: 1954567.8)", "2.0M")
    }

}
