#import "HBMoveResize.h"

@implementation HBMoveResize

@synthesize wndPosition = _wndPosition;
@synthesize wndSize = _wndSize;

+ (HBMoveResize*)instance {
    static HBMoveResize *instance = nil;

    if (instance == nil) {
        instance = [[HBMoveResize alloc] init];
    }

    return instance;
}

@end
