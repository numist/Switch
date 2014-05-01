//
//  NSScreen+SWAdditions.m
//  Switch
//
//  Created by Scott Perry on 04/29/14.
//  Copyright © 2014 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NSScreen+SWAdditions.h"


@implementation NSScreen (SWAdditions)

+ (CGFloat)sw_totalScreenHeight;
{
    return [[[NSScreen screens] nn_reduce:^id(id accumulator, id item) {
        if (!accumulator) { accumulator = @(0.0); }
        CGRect screenFrame = [item sw_absoluteFrame];
        CGFloat screenHeight = screenFrame.origin.y + screenFrame.size.height;
        if ([accumulator floatValue] < screenFrame.origin.y + screenFrame.size.height) {
            accumulator = @(screenHeight);
        }
        return accumulator;
    }] floatValue];
}

- (CGRect)sw_absoluteFrame;
{
    CGPoint offset = CGPointZero;
    for (NSScreen *screen in [NSScreen screens]) {
        if (screen.frame.origin.x < offset.x) {
            offset.x = screen.frame.origin.x;
        }
        if (screen.frame.origin.y < offset.y) {
            offset.y = screen.frame.origin.y;
        }
    }
    
    CGRect result = self.frame;
    result.origin.x -= offset.x;
    result.origin.y -= offset.y;
    return result;
}

@end
