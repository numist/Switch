//
//  NNRoundedRectView.m
//  Switch
//
//  Created by Scott Perry on 03/01/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNRoundedRectView.h"


@implementation NNRoundedRectView

- (void)drawRect:(NSRect)dirtyRect;
{
    NSRect drawRect = self.bounds;
    if (self.border) {
        const CGFloat drawingInset = self.border / 2.0;
        drawRect.origin.x += drawingInset;
        drawRect.origin.y += drawingInset;
        drawRect.size.width -= self.border;
        drawRect.size.height -= self.border;
    }
    
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:drawRect xRadius:self.radius yRadius:self.radius];

    [[[NSColor blackColor] colorWithAlphaComponent:0.3] setFill];
    [path fill];

    if (self.border > 0.0) {
        [path setLineWidth:self.border];
        [[[NSColor whiteColor] colorWithAlphaComponent:0.8] setStroke];
        [path stroke];
    }
}

@end
