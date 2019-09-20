//
//  AppStateMachineTests.swift
//  HummingbirdTests
//
//  Created by Sven A. Schmidt on 20/09/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import XCTest


let trackerIsActive = NSPredicate { (_, _) in
    Tracker.isActive
}


class AppStateMachineTests: XCTestCase {

    override func tearDown() {
        Tracker.disable()
    }

    func test_opensource() {  // opensource version
        // setup
        Current.featureFlags = FeatureFlags(commercial: false)

        let sm = AppStateMachine()
        XCTAssertEqual(sm.state, .launching)
        XCTAssert(!Tracker.isActive)
        sm.state = .validatingLicense

        _ = expectation(for: trackerIsActive, evaluatedWith: nil)
        waitForExpectations(timeout: 2)
        XCTAssert(Tracker.isActive)
    }

    func test_commercial_1() throws {  // commercial, unregistered, in trial period
        // setup
        Current.featureFlags = FeatureFlags(commercial: true)
        Current.date = { ReferenceDate }
        let defaults = testUserDefaults()
        let firstLaunched = day(offset: -5, from: ReferenceDate)
        try firstLaunched.save(forKey: .firstLaunched, defaults: defaults)

        let sm = AppStateMachine()
        XCTAssertEqual(sm.state, .launching)
        XCTAssert(!Tracker.isActive)
        sm.state = .validatingLicense

        _ = expectation(for: trackerIsActive, evaluatedWith: nil)
        waitForExpectations(timeout: 2)
        XCTAssert(Tracker.isActive)
    }

}
