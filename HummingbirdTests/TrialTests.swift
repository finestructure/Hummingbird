//
//  TrialTests.swift
//  HummingbirdTests
//
//  Created by Sven A. Schmidt on 04/08/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import XCTest


extension Status: Equatable {
    static func == (lhs: Status, rhs: Status) -> Bool {
        switch (lhs, rhs) {
        case (.inTrial, .inTrial), (.noLicenseKey, .noLicenseKey), (.invalidLicenseKey, .invalidLicenseKey), (.validLicenseKey, .validLicenseKey):
            return true
        case let (.error(e1), .error(e2)):
            return e1.localizedDescription == e2.localizedDescription
        default:
            return false
        }
    }
}


func response(statusCode: Int) -> DataTaskHandler {
    return { request, completion in
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)
        completion(nil, response, nil)
        return URLSessionDataTask()
    }
}


class TrialTests: XCTestCase {

    override func setUp() {
        Current.gumroad.dataTask = response(statusCode: 200)
    }

    func test_noKey_inTrial() throws {
        let now = Date()
        for d in 0..<7 {
            Current.date = { day(offset: d, from: now) }
            let td = TrialData(firstLaunched: now, licenseKey: nil)

            let expectation = self.expectation(description: #function)
            validate(td) { status in
                XCTAssertEqual(status, .inTrial, "failed for day: \(d)")
                expectation.fulfill()
            }
            waitForExpectations(timeout: 1)
        }
    }

    func test_noKey_expired() throws {
        let now = Date()
        Current.date = { day(offset: 8, from: now) }
        let td = TrialData(firstLaunched: now, licenseKey: nil)

        let expectation = self.expectation(description: #function)
        validate(td) { status in
            XCTAssertEqual(status, .noLicenseKey)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func test_licenseKey_valid() throws {
        let now = Date()
        Current.date = { now }
        Current.gumroad.dataTask = { request, completion in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)
            completion(nil, response, nil)
            return URLSessionDataTask()
        }
        let td = TrialData(firstLaunched: now, licenseKey: "ignored")

        let expectation = self.expectation(description: #function)
        validate(td) { status in
            XCTAssertEqual(status, .validLicenseKey)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 60)
    }

    func test_licenseKey_valid_invalid() throws {
        let now = Date()
        Current.gumroad.dataTask = response(statusCode: 404)
        let td = TrialData(firstLaunched: now, licenseKey: "ignored")

        let expectation = self.expectation(description: #function)
        validate(td) { status in
            XCTAssertEqual(status, .invalidLicenseKey)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 60)
    }

}
