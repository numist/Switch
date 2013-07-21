//
//  NNWindowLevelWindowFilter.m
//  Switch
//
//  Created by Scott Perry on 07/18/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNWindowFilter.h"

#import "NNApplication.h"
#import "NNWindow+Private.h"
#import "NNWindow+NNWindowFiltering.h"


@interface NNWindowLevelWindowFilter : NNWindowFilter

@end


@implementation NNWindowLevelWindowFilter

- (NSString *)applicationName;
{
    return nil;
}

- (NSArray *)filterInvalidWindowsFromArray:(NSArray *)array;
{
    array = [array filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, __attribute__((unused)) NSDictionary *bindings) {
        NNWindow *window = evaluatedObject;
        
        NSDictionary *description = window.windowDescription;
        long level = [[description objectForKey:(__bridge NSString *)kCGWindowLayer] longValue];
        
        // Only match windows at kCGNormalWindowLevel
        if (level != kCGNormalWindowLevel) {
            
            // TODO(numist): Fix for #22 to allow Chrome Hangout floating windows to be visible in the interface.
//            // Except Google Chrome, which has a Hangout plugin that uses floating windows as standard interface windows.
//            if ([window.application.name isEqualToString:@"Google Chrome"]) {
//                // Filter out windows that aren't the expected level of active anchored Hangout windows (inactive Hangout windows are kCGStatusWindowLevel and notifications are kCGModalPanelWindowLevel)
//                if (level != kCGDockWindowLevel) {
//                    return NO;
//                }
//                
//                return YES;
//            }
            
            return NO;
        }
        
        return YES;
    }]];
    
    // TODO(numist): This hackiness is made necessary by #22 and is tracked by #25
//    NSMutableArray *list = [NSMutableArray arrayWithArray:array];
//    for (unsigned i = 0, j = 0; i < [list count] && j < [list count]; i++, j++) {
//        // Floating windows precede normal ones so this loop is done when it hits a normal level window
//        if ([[list[i] windowDescription][(__bridge NSString *)kCGWindowLayer] longValue] == kCGNormalWindowLevel) {
//            break;
//        }
//        
//        [list addObject:list[i]];
//        [list removeObjectAtIndex:i];
//        --i;
//    }
//    return list;
    return array;
}

@end
