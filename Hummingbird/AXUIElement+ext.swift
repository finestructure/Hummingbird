//
//  AXUIElement+ext.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 03/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Cocoa


extension AXError: LocalizedError {
    public var errorDescription: String? {
        switch self {
            case .success:
                return "no error"
            case .failure:
                return "failure"
            case .illegalArgument:
                return "illegalArgument"
            case .invalidUIElement:
                return "invalidUIElement"
            case .invalidUIElementObserver:
                return "invalidUIElementObserver"
            case .cannotComplete:
                return "cannotComplete"
            case .attributeUnsupported:
                return "attributeUnsupported"
            case .actionUnsupported:
                return "actionUnsupported"
            case .notificationUnsupported:
                return "notificationUnsupported"
            case .notImplemented:
                return "notImplemented"
            case .notificationAlreadyRegistered:
                return "notificationAlreadyRegistered"
            case .notificationNotRegistered:
                return "notificationNotRegistered"
            case .apiDisabled:
                return "apiDisabled"
            case .noValue:
                return "noValue"
            case .parameterizedAttributeUnsupported:
                return "parameterizedAttributeUnsupported"
            case .notEnoughPrecision:
                return "notEnoughPrecision"
            default:
                return "unknown error"
        }
    }
}


extension AXUIElement {
    func copy(attribute: NSAccessibility.Attribute, to value: UnsafeMutablePointer<CFTypeRef?>) -> AXError {
        let result = AXUIElementCopyAttributeValue(self, attribute as CFString, value)
        if result != .success {
            log(.debug, "ERROR: failed to get attribute value (\(result.localizedDescription))")
        }
        return result
    }

    func copy(at position: CGPoint, to element: UnsafeMutablePointer<AXUIElement?>) -> AXError {
        let result = AXUIElementCopyElementAtPosition(self, Float(position.x), Float(position.y), element)
        if result != .success {
            log(.debug, "ERROR: failed to get element at position \(position) (\(result.localizedDescription))")
        }
        return result
    }
}


extension AXUIElement {
    func set(attribute: NSAccessibility.Attribute, from value: AXValue) -> AXError {
        let result = AXUIElementSetAttributeValue(self, attribute as CFString, value)
        if result != .success {
            log(.debug, "ERROR: failed to set attribute \(attribute) to value (\(value)) (\(result.localizedDescription))")
        }
        return result
    }
}


extension AXUIElement {

    class func window(at position: CGPoint) -> AXUIElement? {
        var element: AXUIElement?
        var selected: AXUIElement?
        let systemwideElement = AXUIElementCreateSystemWide()

        withUnsafeMutablePointer(to: &element) { elementPtr in
            if .success == systemwideElement.copy(at: position, to: elementPtr) {
                guard let element = elementPtr.pointee else { return }
                do {
                    var role: CFTypeRef?
                    withUnsafeMutablePointer(to: &role) { rolePtr in
                        if
                            .success == element.copy(attribute: .role, to: rolePtr),
                            let r = rolePtr.pointee as? NSAccessibility.Role,
                            r == .window {
                            selected = element
                        }
                    }
                }
                do {
                    var window: CFTypeRef?
                    withUnsafeMutablePointer(to: &window) { windowPtr in
                        if .success == element.copy(attribute: .window, to: windowPtr) {
                            selected = (windowPtr.pointee as! AXUIElement)
                        }
                    }
                }
            }
        }

        return selected
    }


    var origin: CGPoint? {
        get {
            var pos = CGPoint.zero

            var ref: CFTypeRef?
            let success = withUnsafeMutablePointer(to: &ref) { refPtr -> Bool in
                if .success == copy(attribute: .position, to: refPtr) {
                    guard let ref = refPtr.pointee else { return false }
                    let success = withUnsafeMutablePointer(to: &pos) { ptr in
                        AXValueGetValue(ref as! AXValue, .cgPoint, ptr)
                    }
                    if !success {
                        log(.debug, "ERROR: Could not decode position")
                    }
                    return success
                } else {
                    return false
                }
            }

            return success ? pos : nil
        }
        set {
            guard var newValue = newValue else { return }
            let success = withUnsafePointer(to: &newValue) { ptr -> Bool in
                if let position = AXValueCreate(.cgPoint, ptr) {
                    return set(attribute: .position, from: position) == .success
                }
                return false
            }
            if !success {
                log(.debug, "ERROR: failed to set window origin")
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
                        log(.debug, "ERROR: Could not decode size")
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
                log(.debug, "ERROR: failed to set window size")
            }
        }
    }

}
