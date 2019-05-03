//
//  Shim.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 02/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Cocoa


class TrackingInfo {
    var time: CFTimeInterval
    var window: AXUIElement?
    var origin: CGPoint
    var size: CGSize

    init() {
        self.time = 0
        self.window = nil
        self.origin = CGPoint.zero
        self.size = CGSize.zero
    }
}


class HBSTracking {

    static var tracker: HBSTracking? = nil

    static func enable() {
        tracker = .init()
    }

    static func disable() {
        tracker = nil
    }


    let trackingInfo: TrackingInfo
    let eventTap: CFMachPort
    let runLoopSource: CFRunLoopSource?

    init() {
        let res = enableTap()
        self.eventTap = res.eventTap
        self.runLoopSource = res.runLoopSource
        trackingInfo = TrackingInfo()
    }


    deinit {
        disableTap(eventTap: eventTap, runLoopSource: runLoopSource)
    }


    func startTracking(event: CGEvent) {
        if let tracking = _startTracking(event: event) {
            trackingInfo.time = tracking.time
            trackingInfo.origin = tracking.position
            trackingInfo.window = tracking.window
        }
    }

    func stopTracking() {
        trackingInfo.time = 0
    }

    func keepMoving(event: CGEvent) {
        guard let window = trackingInfo.window else {
            print("No window!")
            return
        }

        trackingInfo.origin = newPosition(event: event, from: trackingInfo.origin)

        let kMoveFilterInterval = 0.01
        guard (CACurrentMediaTime() - trackingInfo.time) > kMoveFilterInterval else { return }

        if setTopLeft(position: trackingInfo.origin, window: window) {
            trackingInfo.time = CACurrentMediaTime()
        }
    }

    @discardableResult
    func determineResizeParams(event: CGEvent) -> Bool {
        guard let window = trackingInfo.window, let size = getSize(window: window) else { return false }
        trackingInfo.size = size
        return true
    }

    func keepResizing(event: CGEvent) {
        guard let window = trackingInfo.window else {
            print("No window!")
            return
        }

        trackingInfo.origin = newPosition(event: event, from: trackingInfo.origin)
        trackingInfo.size = newSize(event: event, from: trackingInfo.size)

        let kMoveFilterInterval = 0.01
        guard (CACurrentMediaTime() - trackingInfo.time) > kMoveFilterInterval else { return }

        if setSize(trackingInfo.size, window: window) {
            trackingInfo.time = CACurrentMediaTime()
        }
    }

}


func enableTap() -> (eventTap: CFMachPort, runLoopSource: CFRunLoopSource?) {
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


func disableTap(eventTap: CFMachPort, runLoopSource: CFRunLoopSource?) {
    print("Disabling event tap")
    CGEvent.tapEnable(tap: eventTap, enable: false)
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes);
}
