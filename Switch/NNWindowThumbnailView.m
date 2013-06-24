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

#import "constants.h"


@interface NNWindowThumbnailView ()

@property (nonatomic, strong) CALayer *thumbnailLayer;
@property (nonatomic, strong) CALayer *iconLayer;

@end


@implementation NNWindowThumbnailView

- (id)initWithFrame:(NSRect)frame;
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    [self setWantsLayer:YES];
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
    
    return self;
}

- (void)layout;
{
    [self createLayersIfNeeded];
    
    NSRect thumbFrame = self.bounds;
    CGFloat thumbSize = thumbFrame.size.width;

    {
        NSSize imageSize = self.windowThumbnail.size;
        CGFloat scale = thumbSize / MAX(imageSize.width, imageSize.height);
        
        // make the size fit correctly
        imageSize.width = MIN(round(imageSize.width * scale), thumbSize);
        imageSize.height = MIN(round(imageSize.height * scale), thumbSize);
        
        self.thumbnailLayer.frame = (NSRect){
            .size = imageSize,
            .origin.x = thumbFrame.origin.x + (thumbFrame.size.width - imageSize.width) / 2.0,
            .origin.y = thumbFrame.origin.y + (thumbFrame.size.height - imageSize.height) / 2.0
        };
    }
    
    {
        // imageSize is a lie, but it does give the correct aspect ratio. It's always been a square anecdotally, but you can't be too careful!
        NSSize imageSize = self.applicationIcon.size;
        
        CGFloat iconSize = thumbSize * kNNMaxApplicationIconSize / kNNMaxWindowThumbnailSize;
        CGFloat scale = iconSize / MAX(imageSize.width, imageSize.height);
        
        // make the size fit correctly
        imageSize.width = MIN(round(imageSize.width * scale), iconSize);
        imageSize.height = MIN(round(imageSize.height * scale), iconSize);
        
        self.applicationIcon.size = imageSize;
        
        self.iconLayer.frame = (NSRect){
            .size = imageSize,
            .origin.x = thumbFrame.origin.x + (thumbFrame.size.width - imageSize.width),
            .origin.y = thumbFrame.origin.y
        };
    }
}

- (void)setWindowThumbnail:(NSImage *)windowThumbnail;
{
    if (!SIZES_EQUAL(windowThumbnail.size, _windowThumbnail.size)) {
        [self setNeedsLayout:YES];
    }
    
    _windowThumbnail = windowThumbnail;
    self.thumbnailLayer.contents = windowThumbnail;
}

- (void)setApplicationIcon:(NSImage *)applicationIcon;
{
    _applicationIcon = applicationIcon;
    self.iconLayer.contents = applicationIcon;
}

#pragma mark Internal

- (void)createLayersIfNeeded;
{
    CALayer *(^newLayer)() = ^{
        CALayer *result = [CALayer layer];
        result.magnificationFilter = kCAFilterTrilinear;
        result.minificationFilter = kCAFilterTrilinear;
        result.contentsGravity = kCAGravityResizeAspect;
        return result;
    };
    
    if (!self.thumbnailLayer) {
        self.thumbnailLayer = newLayer();
        if (self.windowThumbnail) {
            self.thumbnailLayer.contents = self.windowThumbnail;
        }
        self.iconLayer.zPosition = 1.0;
        [self.layer addSublayer:self.thumbnailLayer];
    }
    
    if (!self.iconLayer) {
        self.iconLayer = newLayer();
        if (self.applicationIcon) {
            self.iconLayer.contents = self.applicationIcon;
        }
        self.iconLayer.zPosition = 2.0;
        [self.layer addSublayer:self.iconLayer];
    }
}

@end
