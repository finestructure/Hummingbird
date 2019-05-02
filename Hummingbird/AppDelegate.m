#import "AppDelegate.h"
#import "HBMoveResize.h"
#import "HBPreferences.h"
#import "HBHelper.h"
#import "HBPreferencesController.h"
#import "Hummingbird-Swift.h"

typedef enum : NSUInteger {
    idle = 0,
    moving,
    resizing
} State;


@implementation AppDelegate {
    HBPreferences *preferences;
    HBPreferencesController *_prefs;
}

- (id) init  {
    self = [super init];
    if (self) {
        NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"userPrefs"];
        preferences = [[HBPreferences alloc] initWithUserDefaults:userDefaults];
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    const void * keys[] = { kAXTrustedCheckOptionPrompt };
    const void * values[] = { kCFBooleanTrue };

    CFDictionaryRef options = CFDictionaryCreate(
            kCFAllocatorDefault,
            keys,
            values,
            sizeof(keys) / sizeof(*keys),
            &kCFCopyStringDictionaryKeyCallBacks,
            &kCFTypeDictionaryValueCallBacks);

    if (!AXIsProcessTrustedWithOptions(options)) {
        // don't have permission to do our thing right now... AXIsProcessTrustedWithOptions prompted the user to fix
        [_disabledMenu setState:YES];
    } else {
        [self enable];
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
        _prefs.prefs = preferences;
    }
    [_prefs.window makeKeyAndOrderFront:sender];
}

- (int)moveModifierFlags {
    return [preferences modifierFlagsForFlagSet:hoverMoveFlags];
}

- (int)resizeModifierFlags {
    return [preferences modifierFlagsForFlagSet:hoverResizeFlags];
}

@end
