#import "AppDelegate.h"
#import "HBMoveResize.h"
#import "HBPreferences.h"
#import "HBHelper.h"
#import "HBPreferencesController.h"
#import "Hummingbird-Swift.h"


@implementation AppDelegate {
    HBPreferencesController *_prefs;
}

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
    NSImage *icon = [NSImage imageNamed:@"MenuIcon"];
    NSImage *altIcon = [NSImage imageNamed:@"MenuIconHighlight"];
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:statusMenu];
    [statusItem setImage:icon];
    [statusItem setAlternateImage:altIcon];
    [statusItem setHighlightMode:YES];
    [statusMenu setAutoenablesItems:NO];
    [[statusMenu itemAtIndex:0] setEnabled:NO];
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
    if (_prefs == nil) {
        _prefs = [[HBPreferencesController alloc] initWithWindowNibName:@"HBPreferencesController"];
        _prefs.prefs = [HBSTracking preferences];
    }
    [_prefs.window makeKeyAndOrderFront:sender];
}

@end
