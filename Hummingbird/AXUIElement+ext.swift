//
//  AXUIElement+ext.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 03/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Cocoa


extension AXUIElement {

    class func window(at position: CGPoint) -> AXUIElement? {
        var element: AXUIElement?
        var selected: AXUIElement?
        let systemwideElement = AXUIElementCreateSystemWide()

        withUnsafeMutablePointer(to: &element) { elementPtr in
            let res = AXUIElementCopyElementAtPosition(systemwideElement, Float(position.x), Float(position.y), elementPtr)
            if .success == res {
                guard let element = elementPtr.pointee else { return }
                do {
                    var role: CFTypeRef?
                    withUnsafeMutablePointer(to: &role) { rolePtr in
                        if
                            .success == AXUIElementCopyAttributeValue(element, NSAccessibility.Attribute.role as CFString, rolePtr),
                            let r = rolePtr.pointee as? NSAccessibility.Role,
                            r == .window {
                            selected = element
                            print("role")
                        }
                    }
                }
                do {
                    var window: CFTypeRef?
                    withUnsafeMutablePointer(to: &window) { windowPtr in
                        if .success == AXUIElementCopyAttributeValue(element, NSAccessibility.Attribute.window as CFString, windowPtr) {
                            selected = (windowPtr.pointee as! AXUIElement)
                            print("window")
                        }
                    }
                }
            } else {
                print("AXUIElementCopyElementAtPosition failed")
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
                        AXValueGetValue(ref as! AXValue, AXValueType.cgPoint(), ptr)
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
                if let position = AXValueCreate(AXValueType.cgPoint(), ptr) {
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
                        AXValueGetValue(ref as! AXValue, AXValueType.cgSize(), sizePtr)
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
                if let size = AXValueCreate(AXValueType.cgSize(), ptr) {
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


extension AXValueType {
    // AXValueType.cgPoint, .cgSize are 10.11+ only, we want this to compile on 10.9 as well
    static func cgPoint() -> AXValueType { return AXValueType(rawValue: kAXValueCGPointType)! }
    static func cgSize() -> AXValueType { return AXValueType(rawValue: kAXValueCGSizeType)! }
}
