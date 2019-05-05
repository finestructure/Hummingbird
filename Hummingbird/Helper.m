//
//  Helper.m
//  Hummingbird
//
//  Created by Sven A. Schmidt on 05/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

#import <Cocoa/Cocoa.h>


AXUIElementRef getWindow(CGEventRef event) {
    CGPoint mouseLocation = CGEventGetLocation(event);

    AXUIElementRef _systemWideElement;
    AXUIElementRef _clickedWindow = NULL;
    _systemWideElement = AXUIElementCreateSystemWide();

    AXUIElementRef _element;
    if ((AXUIElementCopyElementAtPosition(_systemWideElement, (float) mouseLocation.x, (float) mouseLocation.y, &_element) == kAXErrorSuccess) && _element) {
        CFTypeRef _role;
        if (AXUIElementCopyAttributeValue(_element, (__bridge CFStringRef)NSAccessibilityRoleAttribute, &_role) == kAXErrorSuccess) {
            if ([(__bridge NSString *)_role isEqualToString:NSAccessibilityWindowRole]) {
                _clickedWindow = _element;
                NSLog(@"role (objc)");
            }
            if (_role != NULL) CFRelease(_role);
        }
        CFTypeRef _window;
        if (AXUIElementCopyAttributeValue(_element, (__bridge CFStringRef)NSAccessibilityWindowAttribute, &_window) == kAXErrorSuccess) {
            if (_element != NULL) CFRelease(_element);
            _clickedWindow = (AXUIElementRef)_window;
            NSLog(@"role (objc)");
        }
    }
    CFRelease(_systemWideElement);

    //    if (_clickedWindow != nil) CFRelease(_clickedWindow);
    return _clickedWindow;
}
