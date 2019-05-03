#import <Foundation/Foundation.h>

@interface HBMoveResize : NSObject {
    NSPoint _wndPosition;
    NSSize _wndSize;
}

+ (id) instance;

@property NSPoint wndPosition;
@property NSSize wndSize;

@end
