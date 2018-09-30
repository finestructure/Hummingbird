//
//  EMRPreferencesController.m
//  easy-move-resize
//
//  Created by Sven A. Schmidt on 13/06/2018.
//  Copyright © 2018 Daniel Marcotte. All rights reserved.
//

#import "EMRPreferencesController.h"

@interface EMRPreferencesController ()

@end

@implementation EMRPreferencesController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    if (_prefs) {
        {
            NSSet* flags = [_prefs getFlagStringSetForFlagSet:hoverMoveFlags];
            NSDictionary *keyButtonMap = @{
                                           ALT_KEY: _altHoverMoveButton,
                                           CMD_KEY: _commandHoverMoveButton,
                                           CTRL_KEY: _controlHoverMoveButton,
                                           FN_KEY: _fnHoverMoveButton,
                                           SHIFT_KEY: _shiftHoverMoveButton
                                           };
            for (NSString *key in keyButtonMap) {
                NSButton *button = keyButtonMap[key];
                button.state = [flags containsObject:key] ? NSOnState : NSOffState;
            }
        }

        {
            NSSet* flags = [_prefs getFlagStringSetForFlagSet:hoverResizeFlags];
            NSDictionary *keyButtonMap = @{
                                           ALT_KEY: _altHoverResizeButton,
                                           CMD_KEY: _commandHoverResizeButton,
                                           CTRL_KEY: _controlHoverResizeButton,
                                           FN_KEY: _fnHoverResizeButton,
                                           SHIFT_KEY: _shiftHoverResizeButton
                                           };
            for (NSString *key in keyButtonMap) {
                NSButton *button = keyButtonMap[key];
                button.state = [flags containsObject:key] ? NSOnState : NSOffState;
            }
        }

    }
}

- (IBAction)modifierClicked:(NSButton *)sender {
    bool enabled = sender.state == NSOnState;

    NSSet *hoverMoveControls = [NSSet setWithObjects:_altHoverMoveButton, _commandHoverMoveButton, _controlHoverMoveButton, _fnHoverMoveButton, _shiftHoverMoveButton, nil];
    NSSet *hoverResizeControls = [NSSet setWithObjects:_altHoverResizeButton, _commandHoverResizeButton, _controlHoverResizeButton, _fnHoverResizeButton, _shiftHoverResizeButton, nil];

    if ([hoverMoveControls containsObject:sender]) {
        [_prefs setModifierKey:sender.title enabled:enabled flagSet:hoverMoveFlags];
    } else if ([hoverResizeControls containsObject:sender]) {
        [_prefs setModifierKey:sender.title enabled:enabled flagSet:hoverResizeFlags];
    }
}

@end
