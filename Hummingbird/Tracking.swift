//
//  Tracking.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 29/04/2019.
//  Copyright © 2019 Daniel Marcotte. All rights reserved.
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
    var pos: CFTypeRef?
    withUnsafeMutablePointer(to: &pos) { posPtr in
        switch AXUIElementCopyAttributeValue(window, NSAccessibility.Attribute.position as CFString, posPtr) {
        case .success:
            guard let pos = posPtr.pointee else { break }
            let success = withUnsafeMutablePointer(to: &topLeft) { topLeftPtr in
                AXValueGetValue(pos as! AXValue, .cgPoint, topLeftPtr)
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


struct Tracking {
    let time: CFTimeInterval
    let window: AXUIElement
    let position: CGPoint
}


func startTracking(event: CGEvent) -> Tracking? {
    let time = CACurrentMediaTime()

    guard let clickedWindow = getWindow(at: event.location) else { return nil }
    let topLeft = getTopLeft(window: clickedWindow)

    return Tracking(time: time, window: clickedWindow, position: topLeft)
}


func keepMoving(event: CGEvent, tracking: Tracking) -> Tracking? {
    let dx = CGFloat(event.getDoubleValueField(.mouseEventDeltaX))
    let dy = CGFloat(event.getDoubleValueField(.mouseEventDeltaY))

    let topLeft = tracking.position
    var newPos = CGPoint(x: topLeft.x + dx, y: topLeft.y + dy)

    let kMoveFilterInterval = 0.01
    guard (CACurrentMediaTime() - tracking.time) < kMoveFilterInterval else { return nil }

    var newTracking: Tracking? = nil

    withUnsafePointer(to: &newPos) { newPosPtr in
        if let position = AXValueCreate(.cgPoint, newPosPtr) {
            AXUIElementSetAttributeValue(tracking.window, NSAccessibility.Attribute.position as CFString, position)
            newTracking = Tracking(time: CACurrentMediaTime(), window: tracking.window, position: position as! CGPoint)
        }
    }

    return newTracking
}
