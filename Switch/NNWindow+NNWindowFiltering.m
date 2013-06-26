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
    array = [array filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        NNWindow *window = evaluatedObject;

        // Issue #2: Tweetbot composites multiple windows to make up its main window.
        if ([window.application.name isEqualToString:@"Tweetbot"] && ![window.name length]) {
            return NO;
        }
        
        return [window isValidWindow];
    }]];
    
    return array;
}

- (BOOL)isValidWindow;
{
    // I wish I'd written myself some documentation when I first wrote this because I don't *really* know what it means.
    if ([[self.windowDescription objectForKey:(__bridge NSString *)kCGWindowSharingState] longValue] == kCGWindowSharingNone) {
        NSLog(@"Window %@ isn't shared!", self);
        return NO;
    }
    
    // Only match windows at kCGNormalWindowLevel
    if ([[self.windowDescription objectForKey:(__bridge NSString *)kCGWindowLayer] longValue] != kCGNormalWindowLevel) {
        return NO;
    }
    
    // Windows that are menubar-size or smaller are probably invalid.
    if (self.cgBounds.size.width <= 24.0 || self.cgBounds.size.height <= 24.0) {
        return NO;
    }
    
    // Catches WindowServer and potentially other daemons.
    if (!self.application.name || [self.application.name length] == 0) {
        return NO;
    }
    
    // Last ditch catch-all: No system daemons!
    static NSSet *disallowedApps;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        disallowedApps = [NSSet setWithArray:@[@"SystemUIServer", @"NotificationCenter", @"Notification Center", @"Dock", @"WindowServer"]];
    });
    if ([disallowedApps containsObject:self.application.name]) {
        return NO;
    }
    
    return YES;
}

@end
