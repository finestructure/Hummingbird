//
//  Shim.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 02/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Cocoa


@objc public class HBSTracking: NSObject {

    static var prefs: HBPreferencesController? = nil

    @objc class func startTracking(event: CGEvent, moveResize: HBMoveResize) {
        if let tracking = _startTracking(event: event) {
            moveResize.tracking = tracking.time
            moveResize.wndPosition = tracking.position
            moveResize.window = tracking.window
        }
    }

    @objc class func stopTracking(moveResize: HBMoveResize) {
        moveResize.tracking = 0
    }

    @objc class func keepMoving(event: CGEvent, moveResize: HBMoveResize) {
        guard moveResize.window != nil else {
            print("No window!")
            return
        }
        moveResize.wndPosition = newPosition(event: event, from: moveResize.wndPosition)

        let kMoveFilterInterval = 0.01
        guard (CACurrentMediaTime() - moveResize.tracking) > kMoveFilterInterval else { return }

        if setTopLeft(position: moveResize.wndPosition, window: moveResize.window) {
            moveResize.tracking = CACurrentMediaTime()
        }
    }

    @discardableResult
    @objc class func determineResizeParams(event: CGEvent, moveResize: HBMoveResize) -> Bool {
        guard let size = getSize(window: moveResize.window) else { return false }

        // TODO: remove hard-coded resize direction (right bottom)
        let resizeSection = ResizeSection.init(xResizeDirection: ResizeDirectionX(rawValue: 0), yResizeDirection: ResizeSectionY(rawValue: 1))
        moveResize.resizeSection = resizeSection
        moveResize.wndSize = size
        return true
    }

    @objc class func keepResizing(event: CGEvent, moveResize: HBMoveResize) {
        guard moveResize.window != nil else {
            print("No window!")
            return
        }
        moveResize.wndPosition = newPosition(event: event, from: moveResize.wndPosition)
        moveResize.wndSize = newSize(event: event, from: moveResize.wndSize)

        let kMoveFilterInterval = 0.01
        guard (CACurrentMediaTime() - moveResize.tracking) > kMoveFilterInterval else { return }

        if setSize(moveResize.wndSize, window: moveResize.window) {
            moveResize.tracking = CACurrentMediaTime()
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
        moveResize.eventTap = eventTap
        moveResize.runLoopSource = runLoopSource
    }

    @objc class func disable(moveResize: HBMoveResize) {
        CGEvent.tapEnable(tap: moveResize.eventTap, enable: false)
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), moveResize.runLoopSource, .commonModes);
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
            prefs = HBPreferencesController(windowNibName: "HBPreferencesController")
            prefs?.prefs = HBPreferences(userDefaults: UserDefaults(suiteName: "userPrefs"))
        }
        prefs?.window?.makeKeyAndOrderFront(sender)
    }

}


