//
//  NNObviousSheetsWindowFilter.m
//  Switch
//
//  Created by Scott Perry on 06/28/13.
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


@interface NNObviousSheetsWindowFilter : NNWindowFilter

@end


@implementation NNObviousSheetsWindowFilter

- (NSString *)applicationName;
{
    return nil;
}

- (NSOrderedSet *)filterInvalidWindowsFromSet:(NSOrderedSet *)windows;
{
    NSMutableOrderedSet *mutableWindows = [windows mutableCopy];
    
    for (NSUInteger i = 1; i < [mutableWindows count]; ++i) {
        // Avoid potential index out of bounds caused by `i -= 2;` below.
        if (i == 0) { continue; }
        NNWindow *prevSibling = mutableWindows[(i - 1)];
        NNWindow *sheet = mutableWindows[i];
        
        /*
         * Match obvious non-Powerbox sheets, which are two adjacent windows matched by:
         * • The fore window has an alpha < 1 (in practice, ~0.85).
         * • Neither window is named.
         * • The fore window is short (in practice, a height of 10 points).
         *     - Title bars tend to be about 24 points tall, so any smaller value should have an acceptable false positive rate.
         */
        if (![sheet.name length] && ![prevSibling.name length]) {
            BOOL isTranslucent = [[prevSibling.windowDescription objectForKey:(__bridge NSString*)kCGWindowAlpha] doubleValue] < 1.0;
            BOOL isShort = prevSibling.cgBounds.size.height < 16.0;
            
            if (isTranslucent && isShort) {
                [mutableWindows removeObjectAtIndex:i];
                [mutableWindows removeObjectAtIndex:i - 1];
                i -= 2;
                continue;
            }
        }
    }
    
    return mutableWindows;
}

@end
