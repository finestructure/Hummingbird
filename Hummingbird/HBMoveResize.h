#import <Foundation/Foundation.h>

@interface HBMoveResize : NSObject {
    CFMachPortRef _eventTap;
    CFRunLoopSourceRef _runLoopSource;
    AXUIElementRef _window;
    CFTimeInterval _tracking;
    NSPoint _wndPosition;
    NSSize _wndSize;
}

+ (id) instance;

@property AXUIElementRef window;
@property CFTimeInterval tracking;
@property NSPoint wndPosition;
@property NSSize wndSize;

@end
