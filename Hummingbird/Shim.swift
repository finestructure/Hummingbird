//
//  Shim.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 02/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Cocoa


@objc public class HBSTracking: NSObject {

    @objc class func startTracking(event: CGEvent) {
        guard let appData = appData else {
            print("🔴 appData must not be nil")
            return
        }

        if let tracking = _startTracking(event: event) {
            appData.time = tracking.time
            appData.origin = tracking.position
            appData.window = tracking.window
        }
    }

    @objc class func stopTracking() {
        guard let appData = appData else {
            print("🔴 appData must not be nil")
            return
        }
        appData.time = 0
    }

    @objc class func keepMoving(event: CGEvent) {
        guard let appData = appData else {
            print("🔴 appData must not be nil")
            return
        }
        guard let window = appData.window else {
            print("No window!")
            return
        }

        appData.origin = newPosition(event: event, from: appData.origin)

        let kMoveFilterInterval = 0.01
        guard (CACurrentMediaTime() - appData.time) > kMoveFilterInterval else { return }

        if setTopLeft(position: appData.origin, window: window) {
            appData.time = CACurrentMediaTime()
        }
    }

    @discardableResult
    @objc class func determineResizeParams(event: CGEvent) -> Bool {
        guard let appData = appData else {
            print("🔴 appData must not be nil")
            return false
        }

        guard let window = appData.window, let size = getSize(window: window) else { return false }

        appData.size = size
        return true
    }

    @objc class func keepResizing(event: CGEvent) {
        guard let appData = appData else {
            print("🔴 appData must not be nil")
            return
        }
        guard let window = appData.window else {
            print("No window!")
            return
        }

        appData.origin = newPosition(event: event, from: appData.origin)
        appData.size = newSize(event: event, from: appData.size)

        let kMoveFilterInterval = 0.01
        guard (CACurrentMediaTime() - appData.time) > kMoveFilterInterval else { return }

        if setSize(appData.size, window: window) {
            appData.time = CACurrentMediaTime()
        }
    }

    @objc class func enable() {
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

        appData = AppData(eventTap: eventTap, runLoopSource: runLoopSource)
    }

    @objc class func disable() {
        guard let appData = appData else {
            print("🔴 appData must not be nil")
            return
        }
        CGEvent.tapEnable(tap: appData.eventTap, enable: false)
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), appData.runLoopSource, .commonModes);
    }

}


