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


// replicates (in essence) that AppDelegate.applicationDidFinishLaunching is doing
func applicationDidFinishLaunching(_ stateMachine: AppStateMachine) {
    XCTAssertEqual(stateMachine.state, .launching)
    XCTAssert(!Tracker.isActive)
    stateMachine.state = .validatingLicense
}


func testUserDefaults(firstLaunched: Date?, license: License?) throws -> UserDefaults {
    let def = testUserDefaults()
    if let firstLaunched = firstLaunched {
        try firstLaunched.save(forKey: .firstLaunched, defaults: def)
    }
    if let license = license {
        try license.save(forKey: .license, defaults: def)
    }
    return def
}


class AppStateMachineTests: XCTestCase {

    override func tearDown() {
        Tracker.disable()
    }

    func test_opensource() throws {  // opensource version
        // setup
        Current.featureFlags = FeatureFlags(commercial: false)
        Current.date = { ReferenceDate }
        let defaults = testUserDefaults()
        let firstLaunched = day(offset: -60, from: ReferenceDate)  // far out of trial period
        try firstLaunched.save(forKey: .firstLaunched, defaults: defaults)

        // MUT
        let sm = AppStateMachine()
        applicationDidFinishLaunching(sm)

        // assert
        _ = expectation(for: trackerIsActive, evaluatedWith: nil)
        waitForExpectations(timeout: 2)
        XCTAssert(Tracker.isActive)
    }

    func test_commercial_1() throws {  // commercial, unregistered, in trial period
        // setup
        Current.featureFlags = FeatureFlags(commercial: true)
        Current.date = { ReferenceDate }
        let defaults = try testUserDefaults(firstLaunched: day(offset: -7, from: ReferenceDate), license: nil)
        Current.defaults = { defaults }

        // MUT
        let sm = AppStateMachine()
        applicationDidFinishLaunching(sm)

        // assert
        _ = expectation(for: trackerIsActive, evaluatedWith: nil)
        waitForExpectations(timeout: 2)
        XCTAssert(Tracker.isActive)
    }

    func test_commercial_2() throws {  // commercial, unregistered, after trial period
        // setup
        Current.featureFlags = FeatureFlags(commercial: true)
        Current.date = { ReferenceDate }
        let defaults = try testUserDefaults(firstLaunched: day(offset: -15, from: ReferenceDate), license: nil)
        Current.defaults = { defaults }

        // MUT
        let sm = AppStateMachine()
        applicationDidFinishLaunching(sm)

        // assert
        _ = expectation(for: trackerIsActive, evaluatedWith: nil)
        waitForExpectations(timeout: 2)
        XCTAssert(!Tracker.isActive)
        // TODO: test alert
    }

}
