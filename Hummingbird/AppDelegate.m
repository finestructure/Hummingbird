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


CGEventRef myCGEventCallback(CGEventTapProxy __unused proxy, CGEventType type, CGEventRef event, void *refcon) {
    static State state = idle;

    AppDelegate *ourDelegate = (__bridge AppDelegate*)refcon;

    int moveKeyModifierFlags = [ourDelegate moveModifierFlags];
    int resizeKeyModifierFlags = [ourDelegate resizeModifierFlags];

    if (moveKeyModifierFlags == 0 && resizeKeyModifierFlags == 0) {
        // No modifier keys set. Disable behaviour.
        return event;
    }
    
    HBMoveResize* moveResize = [HBMoveResize instance];

    if ((type == kCGEventTapDisabledByTimeout || type == kCGEventTapDisabledByUserInput)) {
        // need to re-enable our eventTap (We got disabled.  Usually happens on a slow resizing app)
        CGEventTapEnable([moveResize eventTap], true);
        NSLog(@"Re-enabling...");
        return event;
    }
    
    CGEventFlags flags = CGEventGetFlags(event);

    bool moveModifiersDown = (flags & (moveKeyModifierFlags)) == (moveKeyModifierFlags);
    bool resizeModifiersDown = (flags & (resizeKeyModifierFlags)) == (resizeKeyModifierFlags);

    int ignoredKeysMask = (kCGEventFlagMaskShift | kCGEventFlagMaskCommand | kCGEventFlagMaskAlphaShift | kCGEventFlagMaskAlternate | kCGEventFlagMaskControl | kCGEventFlagMaskSecondaryFn) ^ (moveKeyModifierFlags | resizeKeyModifierFlags);
    
    if (flags & ignoredKeysMask) {
        // also ignore this event if we've got extra modifiers (i.e. holding down Cmd+Ctrl+Alt should not invoke our action)
        return event;
    }

    State nextState = idle;
    if (moveModifiersDown && resizeModifiersDown) {
        // if one mask is the super set of the other we want to disable the narrower mask
        // otherwise it may steal the event from the other mode
        if (compareMasks(moveKeyModifierFlags, resizeKeyModifierFlags) == wider) {
            nextState = moving;
        } else if (compareMasks(moveKeyModifierFlags, resizeKeyModifierFlags) == smaller) {
            nextState = resizing;
        }
    } else if (moveModifiersDown) {
        nextState = moving;
    } else if (resizeModifiersDown) {
        nextState = resizing;
    }

    bool absorbEvent = false;

    switch (state) {
        case idle:
            switch (nextState) {
                case idle:
                    // event is not for us - just stay idle
                    break;

                case moving:
                    // NSLog(@"idle -> moving");
                    [HBSTracking startTrackingWithEvent:event moveResize:moveResize];
                    absorbEvent = true;
                    break;

                case resizing:
                    // NSLog(@"idle -> moving/resizing");
                    [HBSTracking startTrackingWithEvent:event moveResize:moveResize];
                    [HBSTracking determineResizeParamsWithEvent:event moveResize:moveResize];
                    absorbEvent = true;
                    break;

                default:
                    // invalid transition
                    assert(false);
                    break;
            }
            break;

        case moving:
            switch (nextState) {
                case moving:
                    // NSLog(@"moving");
                    [HBSTracking keepMovingWithEvent:event moveResize:moveResize];
                    break;

                case idle:
                    // NSLog(@"moving -> idle");
                    [HBSTracking stopTrackingWithMoveResize:moveResize];
                    break;

                case resizing:
                    // NSLog(@"moving -> resizing");
                    absorbEvent = [HBSTracking determineResizeParamsWithEvent:event moveResize:moveResize];
                    break;

                default:
                    // invalid transition
                    assert(false);
                    break;
            }
            break;

        case resizing:
            switch (nextState) {
                case resizing:
                    // NSLog(@"resizing");
                    [HBSTracking keepResizingWithEvent:event moveResize:moveResize];
                    break;

                case idle:
                    // NSLog(@"resizing -> idle");
                    [HBSTracking stopTrackingWithMoveResize:moveResize];
                    break;

                case moving:
                    // NSLog(@"resizing -> moving");
                    [HBSTracking startTrackingWithEvent:event moveResize:moveResize];
                    absorbEvent = true;
                    break;

                default:
                    break;
            }
            break;

        default:
            // invalid transition
            assert(false);
            break;
    }
    state = nextState;


    // absorb event if necessary
    if (absorbEvent) {
        return NULL;
    } else {
        return event;
    }
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
