#import "AppDelegate.h"
#import "HBMoveResize.h"
#import "HBPreferences.h"
#import "HBHelper.h"
#import "HBPreferencesController.h"
#import "Hummingbird-Swift.h"


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if ([HBSTracking checkAXIsProcessTrusted]) {
        [self enable];
    } else {
        // don't have permission to do our thing right now... AXIsProcessTrustedWithOptions prompted the user to fix
        [_disabledMenu setState: YES];
    }
}

-(void)awakeFromNib{
    statusItem = [HBSTracking configureWithMenu: statusMenu];
}

- (void)enable {
    [_disabledMenu setState:NO];
    [HBSTracking enableWithMoveResize:[HBMoveResize instance]];
}

- (void)disable {
    [_disabledMenu setState:YES];
    [HBSTracking disableWithMoveResize:[HBMoveResize instance]];
}

- (IBAction)toggleDisabled:(id)sender {
    if ([_disabledMenu state] == 0) {
        // We are enabled. Disable...
        [self disable];
    }
    else {
        // We are disabled. Enable.
        [self enable];
    }
}

- (IBAction)showPreferences:(id)sender {
    [HBSTracking showPreferencesWithSender: sender];
}

@end
