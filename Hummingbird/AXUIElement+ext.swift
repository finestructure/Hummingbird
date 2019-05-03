//
//  Tracking.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 29/04/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Cocoa


extension AXUIElement {

    class func window(at position: CGPoint) -> AXUIElement? {
        var element: AXUIElement?
        var selected: AXUIElement?
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
                                selected = element
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
                            selected = (window as! AXUIElement)
                        default:
                            break
                        }
                    }
                }
            default:
                break
            }
        }

        return selected
    }


    var origin: CGPoint? {
        get {
            var pos = CGPoint.zero

            var ref: CFTypeRef?
            let success = withUnsafeMutablePointer(to: &ref) { refPtr -> Bool in
                switch AXUIElementCopyAttributeValue(self, NSAccessibility.Attribute.position as CFString, refPtr) {
                case .success:
                    guard let ref = refPtr.pointee else { break }
                    let success = withUnsafeMutablePointer(to: &pos) { ptr in
                        AXValueGetValue(ref as! AXValue, .cgPoint, ptr)
                    }
                    if !success {
                        print("ERROR: Could not decode position")
                    }
                    return success
                default:
                    break
                }
                return false
            }

            return success ? pos : nil
        }
        set {
            guard var newValue = newValue else { return }
            let success = withUnsafePointer(to: &newValue) { ptr -> Bool in
                if let position = AXValueCreate(.cgPoint, ptr) {
                    switch AXUIElementSetAttributeValue(self, NSAccessibility.Attribute.position as CFString, position) {
                    case .success:
                        return true
                    default:
                        return false
                    }
                }
                return false
            }
            if !success {
                print("ERROR: failed to set window origin")
            }
        }
    }


    var size: CGSize? {
        get {
            var size: CGSize = CGSize.zero

            var ref: CFTypeRef?
            let success = withUnsafeMutablePointer(to: &ref) { refPtr -> Bool in
                switch AXUIElementCopyAttributeValue(self, NSAccessibility.Attribute.size as CFString, refPtr) {
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
        set {
            guard var newValue = newValue else { return }
            let success = withUnsafePointer(to: &newValue) { ptr -> Bool in
                if let size = AXValueCreate(.cgSize, ptr) {
                    switch AXUIElementSetAttributeValue(self, NSAccessibility.Attribute.size as CFString, size) {
                    case .success:
                        return true
                    default:
                        return false
                    }
                }
                return false
            }
            if !success {
                print("ERROR: failed to set window size")
            }
        }
    }
    
}
