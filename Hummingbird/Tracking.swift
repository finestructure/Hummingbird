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


func newPosition(event: CGEvent, from position: CGPoint) -> CGPoint {
    let dx = CGFloat(event.getDoubleValueField(.mouseEventDeltaX))
    let dy = CGFloat(event.getDoubleValueField(.mouseEventDeltaY))

    let topLeft = position
    return CGPoint(x: topLeft.x + dx, y: topLeft.y + dy)
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
    var res = false
    var pos = position
    withUnsafePointer(to: &pos) { posPtr in
        if let position = AXValueCreate(.cgPoint, posPtr) {
            AXUIElementSetAttributeValue(window, NSAccessibility.Attribute.position as CFString, position)
            res = true
        }
    }
    return res
}


@objc public class HBSTracking: NSObject {

    @objc class func startTracking(event: CGEvent, moveResize: HBMoveResize) {
        if let tracking = _startTracking(event: event) {
            moveResize.tracking = tracking.time
            moveResize.wndPosition = tracking.position
            moveResize.window = tracking.window
        }
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

}
