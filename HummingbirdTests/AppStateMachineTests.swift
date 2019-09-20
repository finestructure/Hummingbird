//
//  AppStateMachineTests.swift
//  HummingbirdTests
//
//  Created by Sven A. Schmidt on 20/09/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import XCTest


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
        let app = TestAppDelegate()
        app.applicationDidFinishLaunching()

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
        let app = TestAppDelegate()
        app.applicationDidFinishLaunching()

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
        let app = TestAppDelegate()
        app.trialExpiredAlertResponse = .alertThirdButtonReturn  // Click on "Quit"
        app.applicationDidFinishLaunching()

        // assert
        _ = expectation(for: trackerIsNotActive, evaluatedWith: nil)
        waitForExpectations(timeout: 2)
        XCTAssert(!Tracker.isActive)
        XCTAssert(app.trialExpiredAlertShown)
        XCTAssert(app.didTerminate)
    }

    func test_commercial_3() throws { // commercial, show registration dialog
        // setup
        Current.featureFlags = FeatureFlags(commercial: true)
        Current.date = { ReferenceDate }
        let defaults = try testUserDefaults(firstLaunched: day(offset: -15, from: ReferenceDate), license: nil)
        Current.defaults = { defaults }

        // MUT
        let app = TestAppDelegate()
        app.trialExpiredAlertResponse = .alertSecondButtonReturn  // Click on "Register"
        app.applicationDidFinishLaunching()

        // assert
        _ = expectation(for: trackerIsNotActive, evaluatedWith: nil)
        waitForExpectations(timeout: 2)
        XCTAssert(!Tracker.isActive)
        XCTAssert(app.trialExpiredAlertShown)
        XCTAssert(app.registrationControllerShown)
    }
}


// MARK:- Helpers


let trackerIsActive = NSPredicate { (_, _) in
    Tracker.isActive
}


let trackerIsNotActive = NSPredicate { (_, _) in
    !Tracker.isActive
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


class TestAppDelegate {
    var stateMachine = AppStateMachine()

    var transitions = [(from: AppStateMachine.State, to: AppStateMachine.State)]()
    var registrationControllerShown = false
    var trialExpiredAlertShown = false
    var trialExpiredAlertResponse: NSApplication.ModalResponse = .OK
    var didTerminate = false

    // replicates (in essence) that AppDelegate.applicationDidFinishLaunching is doing
    func applicationDidFinishLaunching() {
        stateMachine.delegate = self
        XCTAssertEqual(stateMachine.state, .launching)
        XCTAssert(!Tracker.isActive)
        stateMachine.state = .validatingLicense
    }
}

extension TestAppDelegate: DidTransitionDelegate {
    func didTransition(from: AppStateMachine.State, to: AppStateMachine.State) {
        transitions.append((from, to))
    }
}

extension TestAppDelegate: ShowRegistrationControllerDelegate {
    func showRegistrationController() {
        registrationControllerShown = true
    }
}

extension TestAppDelegate: ShowTrialExpiredAlertDelegate {
    func showTrialExpiredAlert(completion: (NSApplication.ModalResponse) -> ()) {
        trialExpiredAlertShown = true
        completion(trialExpiredAlertResponse)
    }
}

extension TestAppDelegate: ShouldTermindateDelegate {
    func shouldTerminate() {
        didTerminate = true
    }
}
