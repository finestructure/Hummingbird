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


func myCGEventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {

    guard let tracker = HBSTracking.tracker else {
        print("🔴 tracker must not be nil")
        return Unmanaged.passRetained(event)
    }

    let absortEvent = tracker.handleEvent(event, type: type)

    return absortEvent ? nil : Unmanaged.passRetained(event)
}

