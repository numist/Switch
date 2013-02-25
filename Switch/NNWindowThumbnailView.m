//
//  NNWindowThumbnailView.m
//  Switch
//
//  Created by Scott Perry on 02/21/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNWindowThumbnailView.h"

#import "NNApplication.h"
#import "NNWindowData.h"

@implementation NNWindowThumbnailView

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
    NSRect drawFrame = self.bounds;
    CGFloat thumbSize = drawFrame.size.width;
    
    // Draw the window
    {
        NSImage *windowImage = [self.windowData image];
        
        NSSize imageSize = windowImage.size;
        CGFloat scale = thumbSize / MAX(imageSize.width, imageSize.height);
        
        // make the size fit correctly
        imageSize.width = MIN(round(imageSize.width * scale), thumbSize);
        imageSize.height = MIN(round(imageSize.height * scale), thumbSize);
        [windowImage setSize:imageSize];
        
        NSRect imageRect;
        imageRect.origin = NSZeroPoint;
        imageRect.size = imageSize;
        
        NSRect thumbFrame = drawFrame;
        thumbFrame.size = imageRect.size;
        thumbFrame.origin.x += (drawFrame.size.width - imageRect.size.width) / 2.0;
        thumbFrame.origin.y += (drawFrame.size.height - imageRect.size.height) / 2.0;
        
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [windowImage drawInRect:thumbFrame fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0];
    }
    
    // Draw the application icon
    {
        NSImage *applicationIcon = [self.windowData.application icon];
        // imageSize is a LIE, but it does give the correct aspect ratio (empirically it's always been a square, but you can't be too careful!)
        NSSize imageSize = applicationIcon.size;
        
        CGFloat iconSize = thumbSize / 2.0;
        CGFloat scale = iconSize / MAX(imageSize.width, imageSize.height);
        
        // make the size fit correctly
        imageSize.width = MIN(round(imageSize.width * scale), iconSize);
        imageSize.height = MIN(round(imageSize.height * scale), iconSize);
        [applicationIcon setSize:imageSize];
        
        NSRect imageRect;
        imageRect.origin = NSZeroPoint;
        imageRect.size = imageSize;
        
        NSRect iconFrame = drawFrame;
        iconFrame.size = imageRect.size;
        iconFrame.origin.x += drawFrame.size.width - imageRect.size.width;
        
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [applicationIcon drawInRect:iconFrame fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0];
    }
}

@end
