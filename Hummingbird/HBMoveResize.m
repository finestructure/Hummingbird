#import "HBMoveResize.h"

@implementation HBMoveResize


+ (HBMoveResize*)instance {
    static HBMoveResize *instance = nil;

    if (instance == nil) {
        instance = [[HBMoveResize alloc] init];
    }

    return instance;
}

@end
