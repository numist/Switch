//
//  NNSelectionBoxView.m
//  Switch
//
//  Created by Scott Perry on 03/02/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNSelectionBoxView.h"

#import "constants.h"
// TODO: this should be a subclass of NNRoundedRectView

@implementation NNSelectionBoxView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    CGRect drawRect = self.bounds;
    {
        CGFloat inset = 0.5;
        drawRect.origin.x += inset;
        drawRect.origin.y += inset;
        drawRect.size.width -= inset * 2;
        drawRect.size.height -= inset * 2;
    }
    CGFloat radius = windowRoundRectRadius - windowToSelectionInset;
    
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:drawRect xRadius:radius yRadius:radius];
    [path setLineWidth:3.0];
    [[[NSColor whiteColor] colorWithAlphaComponent:0.8] setStroke];
    [[[NSColor blackColor] colorWithAlphaComponent:0.3] setFill];
    [path fill];
    [path stroke];
}

@end
