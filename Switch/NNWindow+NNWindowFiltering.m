//
//  NNWindow+NNWindowFiltering.m
//  Switch
//
//  Created by Scott Perry on 06/25/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNWindow+Private.h"

#import "NNApplication.h"


// No corresponding implementation, everything in this interface is declared/implemented in the class extension!
@interface NNWindow (NNPrivateAccessors)

@property (nonatomic, strong, readonly) NSDictionary *windowDescription;

@end


@implementation NNWindow (NNWindowFiltering)

+ (NSArray *)filterValidWindowsFromArray:(NSArray *)array;
{
    return [array filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        NNWindow *window = evaluatedObject;
        
        // Only match windows at kCGNormalWindowLevel
        BailUnless([[window.windowDescription objectForKey:(__bridge NSString *)kCGWindowLayer] longValue] == kCGNormalWindowLevel, NO);
        
        // Issue #2: Tweetbot composites multiple windows to make up its main window.
        BailUnless(![window.application.name isEqualToString:@"Tweetbot"] || [window.name length], NO);
        
        // It's useful to know if/when/why a window is not accessible by Switch. For now, these windows/applications are not supported.
        if ([[window.windowDescription objectForKey:(__bridge NSString *)kCGWindowSharingState] longValue] == kCGWindowSharingNone) {
            DebugBreak();
            return NO;
        }
        
        return YES;
    }]];
}

@end
