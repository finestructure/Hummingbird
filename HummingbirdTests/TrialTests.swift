//
//  TrialTests.swift
//  HummingbirdTests
//
//  Created by Sven A. Schmidt on 04/08/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import XCTest


class TrialTests: XCTestCase {

    func test_noKey_inTrial() {
        let firstLaunched = Date()
        for d in 0..<7 {
            let currentDate = day(offset: d)
            let td = TrialData(firstLaunched: firstLaunched, currentDate: currentDate, licenseKey: nil)

            let expectation = self.expectation(description: #function)
            validate(td) { status in
                XCTAssertEqual(status, .inTrial, "failed for day: \(d)")
                expectation.fulfill()
            }
            waitForExpectations(timeout: 1)
        }
    }

    func test_noKey_expired() {
        let firstLaunched = Date()
        let td = TrialData(firstLaunched: firstLaunched, currentDate: day(offset: 8), licenseKey: nil)

        let expectation = self.expectation(description: #function)
        validate(td) { status in
            XCTAssertEqual(status, .noLicenseKey)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

}
