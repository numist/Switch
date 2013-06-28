//
//  NNWindow+NNWindowFiltering.m
//  Switch
//
//  Created by Scott Perry on 06/25/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNWindow+NNWindowFiltering.h"

#import "NNApplication.h"


static NSString *kNNApplicationNamePowerbox = @"com.apple.security.pboxd";
static NSString *kNNApplicationNameGitHub = @"GitHub";


// No corresponding implementation, everything in this interface is declared/implemented in the class extension!
@interface NNWindow (NNPrivateAccessors)

@property (nonatomic, strong, readonly) NSDictionary *windowDescription;

@end


@implementation NNWindow (NNWindowFiltering)

+ (NSArray *)filterValidWindowsFromArray:(NSArray *)array;
{
    return [array filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, __attribute__((unused)) NSDictionary *bindings) {
        NNWindow *window = evaluatedObject;
        
        NSString *windowName = window.name;
        NSString *applicationName = window.application.name;
        
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

@end
