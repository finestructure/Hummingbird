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


void keepMoving(CGEventRef event, HBMoveResize* moveResize) {
    [HBSTracking keepMovingWithEvent:event moveResize:moveResize];
}


void keepResizing(CGEventRef event, HBMoveResize* moveResize) {
    AXUIElementRef _clickedWindow = [moveResize window];
    struct ResizeSection resizeSection = [moveResize resizeSection];
    int deltaX = (int) CGEventGetDoubleValueField(event, kCGMouseEventDeltaX);
    int deltaY = (int) CGEventGetDoubleValueField(event, kCGMouseEventDeltaY);

    NSPoint cTopLeft = [moveResize wndPosition];
    NSSize wndSize = [moveResize wndSize];

    wndSize.width += deltaX;
    wndSize.height += deltaY;

    [moveResize setWndPosition:cTopLeft];
    [moveResize setWndSize:wndSize];

    // actually applying the change is expensive, so only do it every kResizeFilterInterval events
    if (CACurrentMediaTime() - [moveResize tracking] > kResizeFilterInterval) {
        // only make a call to update the position if we need to
        if (resizeSection.xResizeDirection == left || resizeSection.yResizeDirection == bottom) {
            CFTypeRef _position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&cTopLeft));
            AXUIElementSetAttributeValue(_clickedWindow, (__bridge CFStringRef)NSAccessibilityPositionAttribute, (CFTypeRef *)_position);
            CFRelease(_position);
        }

        CFTypeRef _size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&wndSize));
        AXUIElementSetAttributeValue((AXUIElementRef)_clickedWindow, (__bridge CFStringRef)NSAccessibilitySizeAttribute, (CFTypeRef *)_size);
        CFRelease(_size);
        [moveResize setTracking:CACurrentMediaTime()];
    }
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
                    keepMoving(event, moveResize);
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
                    keepResizing(event, moveResize);
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

- (void)enableRunLoopSource:(HBMoveResize*)moveResize {
    CFRunLoopAddSource(CFRunLoopGetCurrent(), [moveResize runLoopSource], kCFRunLoopCommonModes);
    CGEventTapEnable([moveResize eventTap], true);
}

- (void)disableRunLoopSource:(HBMoveResize*)moveResize {
    CGEventTapEnable([moveResize eventTap], false);
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), [moveResize runLoopSource], kCFRunLoopCommonModes);
}

- (void)enable {
    [_disabledMenu setState:NO];

    CGEventMask eventMask = CGEventMaskBit( kCGEventMouseMoved );

    CFMachPortRef eventTap = CGEventTapCreate(kCGHIDEventTap,
                                              kCGHeadInsertEventTap,
                                              kCGEventTapOptionDefault,
                                              eventMask,
                                              myCGEventCallback,
                                              (__bridge void * _Nullable)self);

    if (!eventTap) {
        NSLog(@"Couldn't create event tap!");
        exit(1);
    }

    CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);


    HBMoveResize *moveResize = [HBMoveResize instance];
    [moveResize setEventTap:eventTap];
    [moveResize setRunLoopSource:runLoopSource];
    [self enableRunLoopSource:moveResize];

    CFRelease(runLoopSource);
}

- (void)disable {
    [_disabledMenu setState:YES];
    HBMoveResize* moveResize = [HBMoveResize instance];
    [self disableRunLoopSource:moveResize];
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
