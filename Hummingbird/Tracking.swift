//
//  Tracking.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 29/04/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Cocoa


func getWindow(at position: CGPoint) -> AXUIElement? {
    var element: AXUIElement?
    var clickedWindow: AXUIElement?
    let systemwideElement = AXUIElementCreateSystemWide()

    withUnsafeMutablePointer(to: &element) { elementPtr in
        switch AXUIElementCopyElementAtPosition(systemwideElement, Float(position.x), Float(position.y), elementPtr) {
        case .success:
            guard let element = elementPtr.pointee else { break }
            do {
                var role: CFTypeRef?
                withUnsafeMutablePointer(to: &role) { rolePtr in
                    switch AXUIElementCopyAttributeValue(element, NSAccessibility.Attribute.role as CFString, rolePtr) {
                    case .success:
                        guard let role = rolePtr.pointee else { break }
                        if (role as! NSAccessibility.Role) == NSAccessibility.Role.window {
                            clickedWindow = element
                        }
                    default:
                        break
                    }
                }
            }
            do {
                var window: CFTypeRef?
                withUnsafeMutablePointer(to: &window) { windowPtr in
                    switch AXUIElementCopyAttributeValue(element, NSAccessibility.Attribute.window as CFString, windowPtr) {
                    case .success:
                        guard let window = windowPtr.pointee else { break }
                        clickedWindow = (window as! AXUIElement)
                    default:
                        break
                    }
                }
            }
        default:
            break
        }
    }

    return clickedWindow
}


func getTopLeft(window: AXUIElement) -> CGPoint {
    var topLeft = CGPoint.zero

    var ref: CFTypeRef?
    withUnsafeMutablePointer(to: &ref) { refPtr in
        switch AXUIElementCopyAttributeValue(window, NSAccessibility.Attribute.position as CFString, refPtr) {
        case .success:
            guard let ref = refPtr.pointee else { break }
            let success = withUnsafeMutablePointer(to: &topLeft) { ptr in
                AXValueGetValue(ref as! AXValue, .cgPoint, ptr)
            }
            if !success {
                print("ERROR: Could not decode position")
            }
        default:
            break
        }
    }

    return topLeft

}


func newPosition(event: CGEvent, from position: CGPoint) -> CGPoint {
    let dx = CGFloat(event.getDoubleValueField(.mouseEventDeltaX))
    let dy = CGFloat(event.getDoubleValueField(.mouseEventDeltaY))
    return CGPoint(x: position.x + dx, y: position.y + dy)
}


func newSize(event: CGEvent, from size: CGSize) -> CGSize {
    let dx = CGFloat(event.getDoubleValueField(.mouseEventDeltaX))
    let dy = CGFloat(event.getDoubleValueField(.mouseEventDeltaY))
    return CGSize(width: size.width + dx, height: size.height + dy)
}


struct Tracking {
    let time: CFTimeInterval
    let window: AXUIElement
    let position: CGPoint
}


func _startTracking(event: CGEvent) -> Tracking? {
    let time = CACurrentMediaTime()

    guard let clickedWindow = getWindow(at: event.location) else { return nil }
    let topLeft = getTopLeft(window: clickedWindow)

    return Tracking(time: time, window: clickedWindow, position: topLeft)
}


func setTopLeft(position: CGPoint, window: AXUIElement) -> Bool {
    var pos = position
    let res = withUnsafePointer(to: &pos) { posPtr -> Bool in
        if let position = AXValueCreate(.cgPoint, posPtr) {
            switch AXUIElementSetAttributeValue(window, NSAccessibility.Attribute.position as CFString, position) {
            case .success:
                return true
            default:
                return false
            }
        }
        return false
    }
    return res
}


func getSize(window: AXUIElement) -> CGSize? {
    var size: CGSize = CGSize.zero

    var ref: CFTypeRef?
    let success = withUnsafeMutablePointer(to: &ref) { refPtr -> Bool in
        switch AXUIElementCopyAttributeValue(window, NSAccessibility.Attribute.size as CFString, refPtr) {
        case .success:
            guard let ref = refPtr.pointee else { break }
            let success = withUnsafeMutablePointer(to: &size) { sizePtr in
                AXValueGetValue(ref as! AXValue, .cgSize, sizePtr)
            }
            if !success {
                print("ERROR: Could not decode size")
            }
            return success
        default:
            break
        }
        return false
    }

    return success ? size : nil
}


func setSize(_ size: CGSize, window: AXUIElement) -> Bool {
    var _size = size
    let res = withUnsafePointer(to: &_size) { ptr -> Bool in
        if let size = AXValueCreate(.cgSize, ptr) {
            switch AXUIElementSetAttributeValue(window, NSAccessibility.Attribute.size as CFString, size) {
            case .success:
                return true
            default:
                return false
            }
        }
        return false
    }
    return res
}


struct Flags: OptionSet, Hashable {
    let rawValue: UInt64

    static let shift  = Flags(rawValue: CGEventFlags.maskShift.rawValue)
    static let control  = Flags(rawValue: CGEventFlags.maskControl.rawValue)
    static let alt  = Flags(rawValue: CGEventFlags.maskAlternate.rawValue)
    static let command  = Flags(rawValue: CGEventFlags.maskCommand.rawValue)
    static let fn  = Flags(rawValue: CGEventFlags.maskSecondaryFn.rawValue)

    static var all: Flags = [.shift, .control, .alt, .command, .fn]

    func exclusivelySet(in eventFlags: CGEventFlags) -> Bool {
        return self.intersection(.all) == Flags(rawValue: eventFlags.rawValue).intersection(.all)
    }
}


enum State: Int {
    case idle
    case moving
    case resizing
}


var currentState: State = .idle


class AppData {
    var time: CFTimeInterval
    var window: AXUIElement?
    var origin: CGPoint
    var size: CGSize
    let eventTap: CFMachPort
    let runLoopSource: CFRunLoopSource?

    init(eventTap: CFMachPort, runLoopSource: CFRunLoopSource?) {
        self.time = 0
        self.window = nil
        self.origin = CGPoint.zero
        self.size = CGSize.zero
        self.eventTap = eventTap
        self.runLoopSource = runLoopSource
    }
}


var appData: AppData? = nil


func myCGEventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {

    // TODO: read from prefs
    let moveFlags: Flags = [.fn, .control]
    let resizeFlags: Flags = [.fn, .control, .alt]

    if moveFlags.isEmpty && resizeFlags.isEmpty {
        return Unmanaged.passRetained(event)
    }

    let moveResize = HBMoveResize.instance() as! HBMoveResize
    guard let appData = appData else {
        print("🔴 appData must not be nil")
        return Unmanaged.passRetained(event)
    }

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        // need to re-enable our eventTap (We got disabled.  Usually happens on a slow resizing app)
        CGEvent.tapEnable(tap: appData.eventTap, enable: true)
        print("Re-enabling")
        return Unmanaged.passRetained(event)
    }

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
        HBSTracking.startTracking(event: event, moveResize: moveResize)
        absortEvent = true
    case (.idle, .resizing):
        HBSTracking.startTracking(event: event, moveResize: moveResize)
        HBSTracking.determineResizeParams(event: event, moveResize: moveResize)
        absortEvent = true

    // .moving -> X
    case (.moving, .idle):
        HBSTracking.stopTracking(moveResize: moveResize)
    case (.moving, .moving):
        HBSTracking.keepMoving(event: event, moveResize: moveResize)
    case (.moving, .resizing):
        absortEvent = HBSTracking.determineResizeParams(event: event, moveResize: moveResize)

    // .resizing -> X
    case (.resizing, .idle):
        HBSTracking.stopTracking(moveResize: moveResize)
    case (.resizing, .moving):
        HBSTracking.startTracking(event: event, moveResize: moveResize)
        absortEvent = true
    case (.resizing, .resizing):
        HBSTracking.keepResizing(event: event, moveResize: moveResize)
    }

    currentState = nextState

    return absortEvent ? nil : Unmanaged.passRetained(event)
}

