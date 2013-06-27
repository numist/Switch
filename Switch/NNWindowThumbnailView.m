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

#import <QuartzCore/QuartzCore.h>
#import <ReactiveCocoa/EXTScope.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

#import "constants.h"
#import "NNApplication.h"
#import "NNWindow.h"


@interface NNWindowThumbnailView ()

@property (nonatomic, weak, readonly) NNWindow *modelWindow;
@property (nonatomic, strong, readonly) RACSignal *thumbnailSignal;

@property (nonatomic, strong) NSImage *thumbnail;
@property (nonatomic, strong) NSImage *icon;

@property (nonatomic, strong) CALayer *thumbnailLayer;
@property (nonatomic, strong) CALayer *iconLayer;

@end


@implementation NNWindowThumbnailView

- (id)initWithFrame:(NSRect)frame window:(NNWindow *)window;
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    _modelWindow = window;
    
    [self setWantsLayer:YES];
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
    [self createLayers];
    
    _icon = _modelWindow.application.icon;
    _iconLayer.contents = _icon;
    _thumbnail = _modelWindow.image;
    _thumbnailLayer.contents = _thumbnail;
    
    return self;
}

- (void)layout;
{
    NSRect thumbFrame = self.bounds;
    CGFloat thumbSize = thumbFrame.size.width;

    {
        NSSize imageSize = self.thumbnail.size;
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
        NSSize imageSize = self.icon.size;
        
        CGFloat iconSize = thumbSize * kNNMaxApplicationIconSize / kNNMaxWindowThumbnailSize;
        CGFloat scale = iconSize / MAX(imageSize.width, imageSize.height);
        
        // make the size fit correctly
        imageSize.width = MIN(round(imageSize.width * scale), iconSize);
        imageSize.height = MIN(round(imageSize.height * scale), iconSize);
        
        self.icon.size = imageSize;
        
        self.iconLayer.frame = (NSRect){
            .size = imageSize,
            .origin.x = thumbFrame.origin.x + (thumbFrame.size.width - imageSize.width),
            .origin.y = thumbFrame.origin.y
        };
    }
}

#pragma mark NNWindowThumbnailView

- (void)setThumbnail:(NSImage *)image;
{
    self.thumbnailLayer.contents = image;
    
    if (!SIZES_EQUAL(self.thumbnail.size, image.size)) {
        [self setNeedsLayout:YES];
    }
    
	_thumbnail = image;
}

- (void)setActive:(BOOL)active;
{
    CGFloat opacity = active ? 1.0 : 0.5;
    
    CABasicAnimation *animation = [CABasicAnimation animation];
    animation.fromValue = @(((CALayer *)self.layer.presentationLayer).opacity);
    animation.toValue = @(opacity);
    animation.duration = 0.15;
    [self.layer addAnimation:animation forKey:@"opacity"];
    self.layer.opacity = opacity;
}

#pragma mark Internal

- (void)createLayers;
{
    CALayer *(^newLayer)() = ^{
        CALayer *result = [CALayer layer];
        result.magnificationFilter = kCAFilterTrilinear;
        result.minificationFilter = kCAFilterTrilinear;
        result.contentsGravity = kCAGravityResizeAspect;
        return result;
    };
    
    self.thumbnailLayer = newLayer();
    self.thumbnailLayer.zPosition = 1.0;
    [self.layer addSublayer:self.thumbnailLayer];
    
    self.iconLayer = newLayer();
    self.iconLayer.zPosition = 2.0;
    [self.layer addSublayer:self.iconLayer];
}

@end
