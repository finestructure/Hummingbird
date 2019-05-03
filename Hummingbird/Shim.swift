//
//  Shim.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 02/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Cocoa


class HBSTracking {

    // constants to throttle moving and resizing
    static let moveFilterInterval = 0.01
    static let resizeFilterInterval = 0.02

    static var tracker: HBSTracking? = nil

    static func enable() {
        tracker = .init()
    }

    static func disable() {
        tracker = nil
    }


    private let trackingInfo: TrackingInfo
    private let eventTap: CFMachPort
    private let runLoopSource: CFRunLoopSource?
    private var currentState: State = .idle

    private init() {
        let res = enableTap()
        self.eventTap = res.eventTap
        self.runLoopSource = res.runLoopSource
        trackingInfo = TrackingInfo()
    }


    deinit {
        disableTap(eventTap: eventTap, runLoopSource: runLoopSource)
    }


    public func handleEvent(_ event: CGEvent, type: CGEventType) -> Bool {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            // need to re-enable our eventTap (We got disabled. Usually happens on a slow resizing app)
            print("Re-enabling")
            CGEvent.tapEnable(tap: eventTap, enable: true)
            return false
        }

        // TODO: read from prefs
        let moveFlags: Flags = [.fn, .control]
        let resizeFlags: Flags = [.fn, .control, .alt]

        if moveFlags.isEmpty && resizeFlags.isEmpty { return false }

        let eventFlags = event.flags
        let move = moveFlags.exclusivelySet(in: eventFlags)
        let resize = resizeFlags.exclusivelySet(in: eventFlags)

        let nextState: State
        switch (move, resize) {
        case (true, false):
            nextState = .moving
        case (false, true):
            nextState = .resizing
        case (true, true):
            // unreachable unless both options are identical, in which case we default to .moving
            nextState = .moving
        case (false, false):
            // event is not for us
            nextState = .idle
        }

        var absortEvent = false

        switch (currentState, nextState) {
        // .idle -> X
        case (.idle, .idle):
            // event is not for us
            break
        case (.idle, .moving):
            startTracking(event: event)
            absortEvent = true
        case (.idle, .resizing):
            startTracking(event: event)
            determineResizeParams(event: event)
            absortEvent = true

        // .moving -> X
        case (.moving, .idle):
            stopTracking()
        case (.moving, .moving):
            keepMoving(event: event)
        case (.moving, .resizing):
            absortEvent = determineResizeParams(event: event)

        // .resizing -> X
        case (.resizing, .idle):
            stopTracking()
        case (.resizing, .moving):
            startTracking(event: event)
            absortEvent = true
        case (.resizing, .resizing):
            keepResizing(event: event)
        }

        currentState = nextState

        return absortEvent
    }


    private func startTracking(event: CGEvent) {
        if let tracking = _startTracking(event: event) {
            trackingInfo.time = tracking.time
            trackingInfo.origin = tracking.position
            trackingInfo.window = tracking.window
        }
    }


    private func stopTracking() {
        trackingInfo.time = 0
    }


    private func keepMoving(event: CGEvent) {
        guard let window = trackingInfo.window else {
            print("No window!")
            return
        }

        trackingInfo.origin = newPosition(event: event, from: trackingInfo.origin)

        guard (CACurrentMediaTime() - trackingInfo.time) > HBSTracking.moveFilterInterval else { return }

        if setTopLeft(position: trackingInfo.origin, window: window) {
            trackingInfo.time = CACurrentMediaTime()
        }
    }


    @discardableResult
    private func determineResizeParams(event: CGEvent) -> Bool {
        guard let window = trackingInfo.window, let size = getSize(window: window) else { return false }
        trackingInfo.size = size
        return true
    }


    private func keepResizing(event: CGEvent) {
        guard let window = trackingInfo.window else {
            print("No window!")
            return
        }

        trackingInfo.origin = newPosition(event: event, from: trackingInfo.origin)
        trackingInfo.size = newSize(event: event, from: trackingInfo.size)

        guard (CACurrentMediaTime() - trackingInfo.time) > HBSTracking.resizeFilterInterval else { return }

        if setSize(trackingInfo.size, window: window) {
            trackingInfo.time = CACurrentMediaTime()
        }
    }

}


private func enableTap() -> (eventTap: CFMachPort, runLoopSource: CFRunLoopSource?) {
    print("Enabling event tap")

    // https://stackoverflow.com/a/31898592/1444152

    let eventMask = (1 << CGEventType.mouseMoved.rawValue)
    guard let eventTap = CGEvent.tapCreate(
        tap: .cghidEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: CGEventMask(eventMask),
        callback: myCGEventCallback,
        userInfo: nil
        ) else {
            print("failed to create event tap")
            exit(1)
    }

    let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: eventTap, enable: true)

    return (eventTap: eventTap, runLoopSource: runLoopSource)
}


private func disableTap(eventTap: CFMachPort, runLoopSource: CFRunLoopSource?) {
    print("Disabling event tap")
    CGEvent.tapEnable(tap: eventTap, enable: false)
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes);
}
