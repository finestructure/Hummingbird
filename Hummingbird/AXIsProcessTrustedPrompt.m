//
//  AXIsProcessTrustedPrompt.m
//  Hummingbird
//
//  Created by Sven A. Schmidt on 04/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

#import <Foundation/Foundation.h>


BOOL axiProcessTrusted() {
    const void * keys[] = { kAXTrustedCheckOptionPrompt };
    const void * values[] = { kCFBooleanTrue };

    CFDictionaryRef options = CFDictionaryCreate(
                                                 kCFAllocatorDefault,
                                                 keys,
                                                 values,
                                                 sizeof(keys) / sizeof(*keys),
                                                 &kCFCopyStringDictionaryKeyCallBacks,
                                                 &kCFTypeDictionaryValueCallBacks);

    if (AXIsProcessTrustedWithOptions(options)) {
        return YES;
    } else {
        // don't have permission to do our thing right now... AXIsProcessTrustedWithOptions prompted the user to fix
        return NO;
    }
}
