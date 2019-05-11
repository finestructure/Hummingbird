//
//  Tracker.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 02/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Cocoa


class Tracker {

    // constants to throttle moving and resizing
    static let moveFilterInterval = 0.01
    static let resizeFilterInterval = 0.02

    static var shared: Tracker? = nil

    static func enable() {
        shared = try? .init()
    }

    static func disable() {
        shared = nil
    }

    static var isActive: Bool {
        return shared != nil
    }


    private let trackingInfo: TrackingInfo
    private let eventTap: CFMachPort
    private let runLoopSource: CFRunLoopSource?
    private var currentState: State = .idle
    var metricsHistory = History<Metrics>(forKey: .history, defaults: defaults)

    private init() throws {
        let res = try enableTap()
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

        let moveModifiers = Modifiers<Move>(forKey: .moveModifiers, defaults: defaults)
        let resizeModifiers = Modifiers<Resize>(forKey: .resizeModifiers, defaults: defaults)

        if moveModifiers.isEmpty && resizeModifiers.isEmpty { return false }

        let eventModifiers = event.flags
        let move = moveModifiers.exclusivelySet(in: eventModifiers)
        let resize = resizeModifiers.exclusivelySet(in: eventModifiers)

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
        guard let clickedWindow = AXUIElement.window(at: event.location) else { return }
        trackingInfo.time = CACurrentMediaTime()
        trackingInfo.origin = clickedWindow.origin ?? CGPoint.zero
        trackingInfo.window = clickedWindow
    }


    private func stopTracking() {
        trackingInfo.time = 0
        try? metricsHistory.save(forKey: .history, defaults: defaults)
    }


    private func keepMoving(event: CGEvent) {
        guard let window = trackingInfo.window else {
            print("No window!")
            return
        }

        let delta = event.mouseDelta
        metricsHistory[.now]?.distanceMoved += delta.magnitude
        trackingInfo.origin += delta

        guard (CACurrentMediaTime() - trackingInfo.time) > Tracker.moveFilterInterval else { return }

        window.origin = trackingInfo.origin
        trackingInfo.time = CACurrentMediaTime()
    }


    @discardableResult
    private func determineResizeParams(event: CGEvent) -> Bool {
        guard let window = trackingInfo.window, let size = window.size else { return false }
        trackingInfo.size = size
        return true
    }


    private func keepResizing(event: CGEvent) {
        guard let window = trackingInfo.window else {
            print("No window!")
            return
        }

        let delta = event.mouseDelta
        metricsHistory[.now]?.distanceMoved += delta.magnitude
        metricsHistory[.now]?.areaResized += areaDelta(a: trackingInfo.size, d: delta)
        trackingInfo.origin += delta
        trackingInfo.size += delta

        guard (CACurrentMediaTime() - trackingInfo.time) > Tracker.resizeFilterInterval else { return }

        window.size = trackingInfo.size
        trackingInfo.time = CACurrentMediaTime()
    }

}


extension Tracker {

    enum Error: Swift.Error {
        case tapCreateFailed
    }

}


private func enableTap() throws -> (eventTap: CFMachPort, runLoopSource: CFRunLoopSource?)  {
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
            throw Tracker.Error.tapCreateFailed
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


private func myCGEventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {

    guard let tracker = Tracker.shared else {
        print("🔴 tracker must not be nil")
        return Unmanaged.passRetained(event)
    }

    let absortEvent = tracker.handleEvent(event, type: type)

    return absortEvent ? nil : Unmanaged.passRetained(event)
}
