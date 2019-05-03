#import "HBMoveResize.h"

@implementation HBMoveResize

@synthesize tracking = _tracking;
@synthesize wndPosition = _wndPosition;
@synthesize wndSize = _wndSize;

+ (HBMoveResize*)instance {
    static HBMoveResize *instance = nil;

    if (instance == nil) {
        instance = [[HBMoveResize alloc] init];
    }

    return instance;
}

- init {
    _window = nil;
    _runLoopSource = nil;
    return self;
}

- (AXUIElementRef)window {
    return _window;
}

- (void)setWindow:(AXUIElementRef)window {
    if (_window != nil) CFRelease(_window);
    if (window != nil) CFRetain(window);
    _window = window;
}

- (void)dealloc {
    if (_window != nil) CFRelease(_window);
}

@end
