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

    var ref: CFTypeRef?
    withUnsafeMutablePointer(to: &ref) { refPtr in
        switch AXUIElementCopyAttributeValue(window, NSAccessibility.Attribute.position as CFString, refPtr) {
        case .success:
            guard let ref = refPtr.pointee else { break }
            let success = withUnsafeMutablePointer(to: &topLeft) { ptr in
                AXValueGetValue(ref as! AXValue, .cgSize, ptr)
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


func newSize(window: AXUIElement) -> CGSize? {
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


@objc public class HBSTracking: NSObject {

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
        guard let size = newSize(window: moveResize.window) else { return false }

        // TODO: remove hard-coded resize direction (right bottom)
        let resizeSection = ResizeSection.init(xResizeDirection: ResizeDirectionX(rawValue: 0), yResizeDirection: ResizeSectionY(rawValue: 1))
        moveResize.resizeSection = resizeSection
        moveResize.wndSize = size
        return true
    }

}
