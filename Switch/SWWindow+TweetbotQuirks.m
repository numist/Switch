//
//  SWWindow+TweetBotQuirks.m
//  Switch
//
//  Created by Scott Perry on 01/11/14.
//  Copyright © 2014 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWWindow+TweetbotQuirks.h"


@implementation SWWindow (TweetbotQuirks)

- (BOOL)tweetbot_isRelatedToLowerWindow:(SWWindow *)window;
{
    // Tweetbot, which *does* name its main window, has spurious decorator windows, but does not name its popup windows ಠ_ಠ

    /**
     * Catch the table view section header window. It:
     * • has no name.
     * • floats over a window that has a name (in practice, the main window).
     * • is fully enclosed by the window it decorates.
     * • has a height of < 33 points (in practice, 30).
     */
    if (!self.name.length && self.frame.size.height < 33.0 && [self enclosedByWindow:window]) {
        return YES;
    }

    /**
     * Catch any shadowing windows. They:
     * • have no name
     * • shadow a window that has a name (in practice, the main window).
     * • are positioned (nearly) centered underneath the shadowed window, within (20, 20) points center to center.
     * • extend beyond the edges of the shadowed window on all sides
     * • do not exceed the height or width of the shadowed window by more than 100 points (in practice, (90, 85)).
     *
     * These rules should be sufficient to reduce the likelihood of false positives to an acceptable level.
     */
    if (![window.name length]) {
        NNVec2 c2cOffset = [window offsetOfCenterToCenterOfWindow:self];
        NNVec2 absC2COffset = (NNVec2){ .x = fabs(c2cOffset.x), .y = fabs(c2cOffset.y) };
        NSSize sizeDifference = [window sizeDifferenceFromWindow:self];
        
        // Windows have center origins that are within (20, 20) points of each other.
        BOOL centered = absC2COffset.x < 20.0 && absC2COffset.y < 20.0;
        
        // Window fully encloses the window it shadows.
        BOOL enclosing = [self enclosedByWindow:window];
        
        // Window to the rear has dimensions larger than the window it shadows, not exceeding (100, 100) points.
        BOOL saneSize = sizeDifference.width < 100.0
        && sizeDifference.height < 100.0;
        
        if (centered && enclosing && saneSize) {
            return YES;
        }
    }
    
    return NO;
}

@end
