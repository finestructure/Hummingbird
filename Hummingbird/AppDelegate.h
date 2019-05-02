#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet NSMenu *statusMenu;
    NSStatusItem * statusItem;
}

- (IBAction)toggleDisabled:(id)sender;
- (IBAction)showPreferences:(id)sender;

@property (weak) IBOutlet NSMenuItem *disabledMenu;

@end
