//
//  NNWindow+NNWindowFiltering.m
//  Switch
//
//  Created by Scott Perry on 06/25/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNWindow+NNWindowFiltering.h"

#import "NNApplication.h"


typedef NSPoint NNVec2;


static NSString *kNNApplicationNameTweetbot = @"Tweetbot";
static NSString *kNNApplicationNamePowerbox = @"com.apple.security.pboxd";
static NSString *kNNApplicationNameGitHub = @"GitHub";


// No corresponding implementation, everything in this interface is declared/implemented in the class extension!
@interface NNWindow (NNPrivateAccessors)

@property (nonatomic, strong, readonly) NSDictionary *windowDescription;

@end


@implementation NNWindow (NNWindowFiltering)

+ (NSArray *)filterValidWindowsFromArray:(NSArray *)array;
{
    array = [self removeInvalidTweetbotWindowsFromArray:array];
    
    return [array filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, __attribute__((unused)) NSDictionary *bindings) {
        NNWindow *window = evaluatedObject;
        
        NSString *windowName = window.name;
        NSString *applicationName = window.application.name;
        
        // Tweetbot is handled by removeInvalidTweetbotWindowsFromArray:
        if ([applicationName isEqualToString:kNNApplicationNameTweetbot]) {
            return YES;
        }
        
        // Issue #10: Powerbox names its sheets, which are not valid (they do not respond to AXRaise)
        if ([applicationName isEqualToString:kNNApplicationNamePowerbox]) {
            return NO;
        }
        
        // Issues #2, #8, #9: Most applications name their valid windows and leave the invalid ones blank.
        if (![windowName length]) {
            // Except GitHub for Mac, which does not name its main window.
            if ([applicationName isEqualToString:kNNApplicationNameGitHub]) {
                return YES;
            }
            
            return NO;
        }
        
        return YES;
    }]];
}

+ (NSArray *)removeInvalidTweetbotWindowsFromArray:(NSArray *)immutableArray;
{
    // Tweetbot, which *does* name its main window, has spurious decorator windows, but does not name its popup windows ಠ_ಠ
    NSMutableArray *array = [immutableArray mutableCopy];
    
    for (NSUInteger i = 0; i < [array count]; ++i) {
        NNWindow *window = array[i];
        
        if (![window.application.name isEqualToString:kNNApplicationNameTweetbot]) { continue; }
        
        /* Catch the table view section header window. It:
         * • has no name.
         * • floats over a window that has a name (in practice, the main window).
         * • is fully enclosed by the window it decorates.
         * • has a height of < 33 points (in practice, 30).
         */
        if (![window.name length] && window.cgBounds.size.height < 33.0) {
            NNWindow *mainWindow = [window nextNamedSiblingFromCollection:array];
            
            if ([window enclosedByWindow:mainWindow]) {
                [array removeObjectAtIndex:i--];
                continue;
            }
        }
        
        /*
         * Catch any shadowing windows. They:
         * • have no name
         * • shadow a window that has a name (in practice, the main window).
         * • are positioned (nearly) centered underneath the shadowed window, within (20, 20) points center to center.
         * • extend beyond the edges of the shadowed window on all sides
         * • do not exceed the height or width of the shadowed window by more than 100 points (in practice, (90, 85)).
         *
         * These rules should be sufficient to reduce the likelihood of false positives to an acceptable level.
         */
        if (i > 0 && ![window.name length]) {
            NNWindow *mainWindow = [window previousNamedSiblingFromCollection:array];

            if (mainWindow) {
                NNVec2 c2cOffset = [window offsetOfCenterToCenterOfWindow:mainWindow];
                NNVec2 absC2COffset = (NNVec2){ .x = fabs(c2cOffset.x), .y = fabs(c2cOffset.y) };
                NSSize sizeDifference = [window sizeDifferenceFromWindow:mainWindow];
                
                // Windows have center origins that are within (20, 20) points of each other.
                BOOL centered = absC2COffset.x < 20.0 && absC2COffset.y < 20.0;
                
                // Window fully encloses the window it shadows.
                BOOL enclosing = [mainWindow enclosedByWindow:window];
                
                // Window to the rear has dimensions larger than the window it shadows, not exceeding (100, 100) points.
                BOOL saneSize = sizeDifference.width < 100.0
                             && sizeDifference.height < 100.0;
                
                if (centered && enclosing && saneSize) {
                    [array removeObjectAtIndex:i--];
                    continue;
                }
            }
        }
    }
    
    return array;
}

- (NNVec2)offsetOfCenterToCenterOfWindow:(NNWindow *)window;
{
    NSRect selfBounds = self.cgBounds;
    NSRect windowBounds = window.cgBounds;
    
    return (NNVec2){
        .x = ((windowBounds.origin.x + (windowBounds.size.width / 2.0)) - (selfBounds.origin.x + (selfBounds.size.width / 2.0))),
        .y = ((windowBounds.origin.y + (windowBounds.size.height / 2.0)) - (selfBounds.origin.y + (selfBounds.size.height / 2.0)))
    };
}

- (NSSize)sizeDifferenceFromWindow:(NNWindow *)window;
{
    NSRect selfBounds = self.cgBounds;
    NSRect windowBounds = window.cgBounds;

    return (NSSize){
        .width = selfBounds.size.width - windowBounds.size.width,
        .height = selfBounds.size.height - windowBounds.size.height
    };
}

- (BOOL)enclosedByWindow:(NNWindow *)window;
{
    NNVec2 c2cOffset = [self offsetOfCenterToCenterOfWindow:window];
    NNVec2 absC2COffset = (NNVec2){ .x = fabs(c2cOffset.x), .y = fabs(c2cOffset.y) };
    NSSize sizeDifference = [window sizeDifferenceFromWindow:self];

    return sizeDifference.width > absC2COffset.x * 2.0 && sizeDifference.height > absC2COffset.y * 2.0;
}

- (NNWindow *)nextNamedSiblingFromCollection:(NSArray *)array;
{
    NSUInteger s = [array indexOfObject:self];
    if (s > [array count]) {
        Check(s == NSNotFound);
        return nil;
    }
    
    for (NSUInteger i = s + 1; i < [array count]; ++i) {
        NNWindow *result = array[i];
        
        if (![result.application.name isEqualToString:self.application.name]) {
            return nil;
        }
        
        if ([result.name length]) {
            return result;
        }
    }
    
    return nil;
}

- (NNWindow *)previousNamedSiblingFromCollection:(NSArray *)array;
{
    NSUInteger s = [array indexOfObject:self];
    if (s > [array count]) {
        Check(s == NSNotFound);
        return nil;
    }
    
    for (NSInteger i = (NSInteger)s - 1; i >= 0; --i) {
        NNWindow *result = array[(NSUInteger)i];
        
        if (![result.application.name isEqualToString:self.application.name]) {
            return nil;
        }
        
        if ([result.name length]) {
            return result;
        }
    }
    
    return nil;
}

@end
