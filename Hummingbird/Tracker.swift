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
    var metricsHistory = History<Metrics>(forKey: .history, defaults: Current.defaults())


    private init() throws {
        // don't enable tap for TEST or we'll trigger the permissions alert
        #if !TEST
        let res = try enableTap()
        self.eventTap = res.eventTap
        self.runLoopSource = res.runLoopSource
        NotificationCenter.default.addObserver(self, selector: #selector(updateModifiers), name: UserDefaults.didChangeNotification, object: Current.defaults())
        #endif
    }


    deinit {
        #if !TEST
        disableTap(eventTap: eventTap, runLoopSource: runLoopSource)
        NotificationCenter.default.removeObserver(self)
        #endif
    }


    public func readModifiers() {
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
            startTracking(at: event.location)
            absortEvent = true
        case (.idle, .resizing):
            startTracking(at: event.location)
            absortEvent = true

        // .moving -> X
        case (.moving, .idle):
            stopTracking()
        case (.moving, .moving):
            keepMoving(delta: event.mouseDelta)
        case (.moving, .resizing):
            break

        // .resizing -> X
        case (.resizing, .idle):
            stopTracking()
        case (.resizing, .moving):
            startTracking(at: event.location)
            absortEvent = true
        case (.resizing, .resizing):
            keepResizing(delta: event.mouseDelta)
        }

        currentState = nextState

        return absortEvent
    }


    private func startTracking(at location: CGPoint) {
        guard
            let trackedWindow = AXUIElement.window(at: location),
            let origin = trackedWindow.origin,
            let size = trackedWindow.size
        else { return }
        trackingInfo.time = CACurrentMediaTime()
        trackingInfo.origin = origin
        trackingInfo.window = trackedWindow
        trackingInfo.distanceMoved = 0
        trackingInfo.areaResized = 0
        trackingInfo.corner = .corner(for: location - origin, in: size)
    }


    private func stopTracking() {
        trackingInfo.time = 0
        metricsHistory.currentValue.distanceMoved += trackingInfo.distanceMoved
        metricsHistory.currentValue.areaResized += trackingInfo.areaResized
        if #available(OSX 10.14, *) {
            metricsHistory.checkMilestone(metricsHistory.currentValue).map(Notifications.send(milestone:))
        }
        do {
            try metricsHistory.save(forKey: .history, defaults: Current.defaults())
        } catch {
            log(.debug, "Error while saving preferences: \(error)")
        }
    }


    private func keepMoving(delta: Delta) {
        guard let window = trackingInfo.window else {
            log(.debug, "No window!")
            return
        }

        trackingInfo.distanceMoved += delta.magnitude
        trackingInfo.origin += delta

        guard (CACurrentMediaTime() - trackingInfo.time) > Tracker.moveFilterInterval else { return }

        window.origin = trackingInfo.origin
        trackingInfo.time = CACurrentMediaTime()
    }


    private func keepResizing(delta: Delta) {
        guard let window = trackingInfo.window else {
            log(.debug, "No window!")
            return
        }

        // TODO: remove history
        //        trackingInfo.distanceMoved += delta.magnitude
        //        trackingInfo.areaResized += areaDelta(a: trackingInfo.size, d: delta)
        trackingInfo.aggregateDelta += delta

        guard (CACurrentMediaTime() - trackingInfo.time) > Tracker.resizeFilterInterval else { return }

        guard let origin = window.origin,
              let size = window.size else { return }

        switch trackingInfo.corner {
            case .topLeft:
                window.origin = origin + trackingInfo.aggregateDelta
                window.size = size - trackingInfo.aggregateDelta
            case .topRight:
                window.origin = CGPoint(x: origin.x,
                                        y: origin.y + trackingInfo.aggregateDelta.dy)
                window.size = CGSize(width: size.width + trackingInfo.aggregateDelta.dx,
                                     height: size.height - trackingInfo.aggregateDelta.dy)
            case .bottomRight:
                window.size = size + trackingInfo.aggregateDelta
            case .bottomLeft:
                window.origin = CGPoint(x: origin.x + trackingInfo.aggregateDelta.dx,
                                        y: origin.y)
                window.size = CGSize(width: size.width - trackingInfo.aggregateDelta.dx,
                                     height: size.height + trackingInfo.aggregateDelta.dy)
        }
        trackingInfo.aggregateDelta = .zero

        trackingInfo.time = CACurrentMediaTime()
    }

    @objc private func updateModifiers() {
        moveModifiers = Modifiers<Move>(forKey: .moveModifiers, defaults: Current.defaults())
        resizeModifiers = Modifiers<Resize>(forKey: .resizeModifiers, defaults: Current.defaults())
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

    let absortEvent = tracker.handleEvent(event, type: type)

    return absortEvent ? nil : Unmanaged.passUnretained(event)
}
