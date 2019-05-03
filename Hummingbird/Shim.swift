//
//  Shim.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 02/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Cocoa


@objc public class HBSTracking: NSObject {

    static var prefs: PreferencesController? = nil

    @objc class func startTracking(event: CGEvent, moveResize: HBMoveResize) {
        guard let appData = appData else {
            print("🔴 appData must not be nil")
            return
        }

        if let tracking = _startTracking(event: event) {
            appData.time = tracking.time
            moveResize.wndPosition = tracking.position
            appData.window = tracking.window
        }
    }

    @objc class func stopTracking(moveResize: HBMoveResize) {
        guard let appData = appData else {
            print("🔴 appData must not be nil")
            return
        }
        appData.time = 0
    }

    @objc class func keepMoving(event: CGEvent, moveResize: HBMoveResize) {
        guard let appData = appData else {
            print("🔴 appData must not be nil")
            return
        }
        guard let window = appData.window else {
            print("No window!")
            return
        }

        moveResize.wndPosition = newPosition(event: event, from: moveResize.wndPosition)

        let kMoveFilterInterval = 0.01
        guard (CACurrentMediaTime() - appData.time) > kMoveFilterInterval else { return }

        if setTopLeft(position: moveResize.wndPosition, window: window) {
            appData.time = CACurrentMediaTime()
        }
    }

    @discardableResult
    @objc class func determineResizeParams(event: CGEvent, moveResize: HBMoveResize) -> Bool {
        guard let appData = appData else {
            print("🔴 appData must not be nil")
            return false
        }

        guard let window = appData.window, let size = getSize(window: window) else { return false }

        moveResize.wndSize = size
        return true
    }

    @objc class func keepResizing(event: CGEvent, moveResize: HBMoveResize) {
        guard let appData = appData else {
            print("🔴 appData must not be nil")
            return
        }
        guard let window = appData.window else {
            print("No window!")
            return
        }

        moveResize.wndPosition = newPosition(event: event, from: moveResize.wndPosition)
        moveResize.wndSize = newSize(event: event, from: moveResize.wndSize)

        let kMoveFilterInterval = 0.01
        guard (CACurrentMediaTime() - appData.time) > kMoveFilterInterval else { return }

        if setSize(moveResize.wndSize, window: window) {
            appData.time = CACurrentMediaTime()
        }
    }

    @objc class func enable(moveResize: HBMoveResize) {
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

    @objc class func disable(moveResize: HBMoveResize) {
        guard let appData = appData else {
            print("🔴 appData must not be nil")
            return
        }
        CGEvent.tapEnable(tap: appData.eventTap, enable: false)
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), appData.runLoopSource, .commonModes);
    }

    @objc class func checkAXIsProcessTrusted() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    @objc class func configure(menu: NSMenu) -> NSStatusItem {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.menu = menu
        statusItem.image = NSImage(named: "MenuIcon")
        statusItem.alternateImage = NSImage(named: "MenuIconHighlight")
        statusItem.highlightMode = true
        menu.autoenablesItems = false
        menu.item(at: 0)?.isEnabled = false
        return statusItem
    }

    @objc class func showPreferences(sender: Any) {
        if prefs == nil {
            prefs = PreferencesController(windowNibName: "HBPreferencesController")
        }
        prefs?.window?.makeKeyAndOrderFront(sender)
    }

}


