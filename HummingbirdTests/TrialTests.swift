//
//  TrialTests.swift
//  HummingbirdTests
//
//  Created by Sven A. Schmidt on 04/08/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import XCTest


class TrialTests: XCTestCase {

    func test_noKey_inTrial() throws {
        let firstLaunched = Date()
        for d in 0..<7 {
            let currentDate = day(offset: d)
            let td = TrialData(firstLaunched: firstLaunched, currentDate: currentDate, licenseKey: nil)

            let expectation = self.expectation(description: #function)
            try validate(td) { status in
                XCTAssertEqual(status, .inTrial, "failed for day: \(d)")
                expectation.fulfill()
            }
            waitForExpectations(timeout: 1)
        }
    }

    func test_noKey_expired() throws {
        let firstLaunched = Date()
        let td = TrialData(firstLaunched: firstLaunched, currentDate: day(offset: 8), licenseKey: nil)

        let expectation = self.expectation(description: #function)
        try validate(td) { status in
            XCTAssertEqual(status, .noLicenseKey)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func test_licenseKey_valid() throws {
        let now = Date()
        let td = TrialData(firstLaunched: now, currentDate: now, licenseKey: "302C73F3-DB2C43BC-B2EA4E25-4C9158B4")

        let expectation = self.expectation(description: #function)
        try validate(td) { status in
            XCTAssertEqual(status, .validLicenseKey)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 60)
    }

    func test_licenseKey_invalid() throws {
        let now = Date()
        let td = TrialData(firstLaunched: now, currentDate: now, licenseKey: "foo")

        let expectation = self.expectation(description: #function)
        try validate(td) { status in
            XCTAssertEqual(status, .invalidLicenseKey)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 60)
    }
}
