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


    private let trackingInfo = TrackingInfo()

    #if !TEST  // cannot populate these ivars when testing
    private let eventTap: CFMachPort
    private let runLoopSource: CFRunLoopSource?
    #endif

    private var currentState: State = .idle
    private var moveModifiers = Modifiers<Move>(forKey: .moveModifiers, defaults: Current.defaults())
    private var resizeModifiers = Modifiers<Resize>(forKey: .resizeModifiers, defaults: Current.defaults())


    private init() throws {
        // don't enable tap for TEST or we'll trigger the permissions alert
        #if !TEST
        let res = try enableTap()
        self.eventTap = res.eventTap
        self.runLoopSource = res.runLoopSource
        NotificationCenter.default.addObserver(self, selector: #selector(readModifiers), name: UserDefaults.didChangeNotification, object: Current.defaults())
        #endif
    }


    deinit {
        #if !TEST
        disableTap(eventTap: eventTap, runLoopSource: runLoopSource)
        NotificationCenter.default.removeObserver(self)
        #endif
    }


    @objc func readModifiers() {
        moveModifiers = Modifiers<Move>(forKey: .moveModifiers, defaults: Current.defaults())
        resizeModifiers = Modifiers<Resize>(forKey: .resizeModifiers, defaults: Current.defaults())
    }


    public func handleEvent(_ event: CGEvent, type: CGEventType) -> Bool {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            // need to re-enable our eventTap (We got disabled. Usually happens on a slow resizing app)
            log(.debug, "Re-enabling")
            #if !TEST
            CGEvent.tapEnable(tap: eventTap, enable: true)
            #endif
            return false
        }

        if moveModifiers.isEmpty && resizeModifiers.isEmpty { return false }

        var absortEvent = false
        let nextState = state(for: event.flags)

        switch (currentState, nextState) {
            // .idle -> X
            case (.idle, .idle):
                // event is not for us
                break
            case (.idle, .moving),
                 (.idle, .resizing):
                startTracking(at: event.location)
                absortEvent = true

            // .moving -> X
            case (.moving, .moving):
                move(delta: event.mouseDelta)
            case (.moving, .idle),
                 (.moving, .resizing):
                break

            // .resizing -> X
            case (.resizing, .idle):
                break
            case (.resizing, .moving):
                startTracking(at: event.location)
                absortEvent = true
            case (.resizing, .resizing):
                resize(delta: event.mouseDelta)
        }

        currentState = nextState

        return absortEvent
    }


    private func state(for modifiers: CGEventFlags) -> State {
        if moveModifiers.exclusivelySet(in: modifiers) {
            return .moving
        }
        if resizeModifiers.exclusivelySet(in: modifiers) {
            return .resizing
        }
        return .idle
    }


    private func startTracking(at location: CGPoint) {
        guard
            let trackedWindow = AXUIElement.window(at: location),
            let origin = trackedWindow.origin,
            let size = trackedWindow.size
        else { return }
        trackingInfo.time = CACurrentMediaTime()
        trackingInfo.window = trackedWindow
        trackingInfo.origin = origin
        trackingInfo.size = size
        if Current.defaults().bool(forKey: DefaultsKeys.resizeFromNearestCorner.rawValue) {
            trackingInfo.corner = .corner(for: location - origin, in: size)
        } else {
            trackingInfo.corner = .bottomRight
        }
    }


    private func move(delta: Delta) {
        guard let window = trackingInfo.window else {
            log(.debug, "No window!")
            return
        }

        trackingInfo.origin += delta

        guard (CACurrentMediaTime() - trackingInfo.time) > Tracker.moveFilterInterval else { return }

        window.origin = trackingInfo.origin
        trackingInfo.time = CACurrentMediaTime()
    }


    private func resize(delta: Delta) {
        guard let window = trackingInfo.window else {
            log(.debug, "No window!")
            return
        }

        switch trackingInfo.corner {
            case .topLeft:
                trackingInfo.origin += delta
                trackingInfo.size -= delta
            case .topRight:
                trackingInfo.origin += Delta(dx: 0, dy: delta.dy)
                trackingInfo.size += Delta(dx: delta.dx, dy: -delta.dy)
            case .bottomRight:
                trackingInfo.size += delta
            case .bottomLeft:
                trackingInfo.origin += Delta(dx: delta.dx, dy: 0)
                trackingInfo.size += Delta(dx: -delta.dx, dy: delta.dy)
        }

        guard (CACurrentMediaTime() - trackingInfo.time) > Tracker.resizeFilterInterval else { return }

        switch trackingInfo.corner {
            case .topLeft, .topRight, .bottomLeft:
                window.origin = trackingInfo.origin
                window.size = trackingInfo.size
            case .bottomRight:
                window.size = trackingInfo.size
        }

        trackingInfo.time = CACurrentMediaTime()
    }

}


extension Tracker {
    enum Error: Swift.Error {
        case tapCreateFailed
    }
}


private func enableTap() throws -> (eventTap: CFMachPort, runLoopSource: CFRunLoopSource?)  {
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
        throw Tracker.Error.tapCreateFailed
    }

    let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: eventTap, enable: true)

    return (eventTap: eventTap, runLoopSource: runLoopSource)
}


private func disableTap(eventTap: CFMachPort, runLoopSource: CFRunLoopSource?) {
    log(.debug, "Disabling event tap")
    CGEvent.tapEnable(tap: eventTap, enable: false)
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes);
}


private func myCGEventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {

    guard let tracker = Tracker.shared else {
        log(.debug, "🔴 tracker must not be nil")
        return Unmanaged.passUnretained(event)
    }

    let absorbEvent = tracker.handleEvent(event, type: type)

    return absorbEvent ? nil : Unmanaged.passUnretained(event)
}
