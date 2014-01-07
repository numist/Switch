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

#import <Foundation/NSGeometry.h>
#import <QuartzCore/QuartzCore.h>
#import <ReactiveCocoa/EXTScope.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

#import "SWApplication.h"
#import "SWWindowGroup.h"
#import "SWWindowListService.h"
#import "SWWindowContentsService.h"


@interface NNWindowThumbnailView () <SWWindowListSubscriber, SWWindowContentsSubscriber>

@property (nonatomic, strong, readonly) NSOrderedSet *windowIDList;
@property (nonatomic, strong, readonly) NSMutableDictionary *windowFrames;
@property (nonatomic, assign) BOOL valid;


@property (nonatomic, weak, readonly) SWWindowGroup *modelWindow;
@property (nonatomic, strong, readonly) RACSignal *thumbnailSignal;

@property (nonatomic, strong) NSImage *icon;

@property (nonatomic, strong) CALayer *thumbnailLayer;
@property (nonatomic, strong) CALayer *iconLayer;

@end


@implementation NNWindowThumbnailView

- (id)initWithFrame:(NSRect)frame windowGroup:(SWWindowGroup *)window;
{
    if (!(self = [super initWithFrame:frame])) { return nil; }
    
    _modelWindow = window;
    
    [self setWantsLayer:YES];
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
    [self _createLayers];
    
    // Disable implicit animation on frame changes.
    ((id<NSAnimatablePropertyContainer>)self.animator).animations = @{@"frame" : [NSNull null]};
    
    NSImage *icon;
    {
        icon = window.application.icon;

        // This is necessary or the CALayer may draw a low resolution representation when a higher resolution is needed, and it's better to be too high-resolution than too low.
        NSSize imageSize = icon.size;
        CGFloat scale = kNNMaxApplicationIconSize / MAX(imageSize.width, imageSize.height);
        icon.size = NSMakeSize(round(imageSize.width * scale), round(imageSize.height * scale));
    }

    _icon = icon;
    _iconLayer.contents = icon;
    
    #pragma message "create a sublayer for each of the window ids in the group's window IDs, fill their contents with SWWindowContentsService cached contents, if available"

    [self setNeedsLayout:YES];
    
    return self;
}

- (void)layout;
{
//    NSRect thumbFrame = self.bounds;
//    CGFloat thumbSize = thumbFrame.size.width;

    #pragma message "This is going to have to recompute a frame space from the window frames and map that to the view's bounds, and then update the frames of each of the thumbnails in thumbnailLayer.subLayers accordingly"
    
    [self _updateIconLayout];
}

#pragma mark NNWindowThumbnailView

- (void)setActive:(BOOL)active;
{
    if (!self.valid) {
        return;
    }
    
    CGFloat opacity = active ? 1.0 : 0.5;
    
    CABasicAnimation *animation = [CABasicAnimation animation];
    animation.fromValue = @(((CALayer *)self.layer.presentationLayer).opacity);
    animation.toValue = @(opacity);
    animation.duration = 0.15;
    [self.layer addAnimation:animation forKey:@"opacity"];
    self.layer.opacity = opacity;
}

- (void)setValid:(BOOL)valid;
{
    if (!Check(_valid != valid)) {
        return;
    }
    
    // Punting on this for now, it's copy-pasta from setActive.
    CGFloat opacity = valid ? 1.0 : 0.5;
    
    CABasicAnimation *animation = [CABasicAnimation animation];
    animation.fromValue = @(((CALayer *)self.layer.presentationLayer).opacity);
    animation.toValue = @(opacity);
    animation.duration = 0.15;
    [self.layer addAnimation:animation forKey:@"opacity"];
    self.layer.opacity = opacity;
}

#pragma mark SWWindowListSubscriber

- (oneway void)windowListService:(SWWindowListService *)service updatedList:(NSOrderedSet *)windows;
{
    #pragma message "Check the window list to make sure that a window group with the same wid list as self.windowIDList exists in the set. Enable/Disable red state (self.valid) as appropriate."
}

#pragma mark SWWindowContentsSubscriber

- (oneway void)windowContentService:(SWWindowContentsService *)windowService updatedContent:(NSImage *)content forWindow:(SWWindow *)window;
{
    if (!self.valid) {
        return;
    }
    
    CGWindowID windowID = window.windowID;
    if (![self.windowIDList containsObject:@(windowID)]) {
        return;
    }
    
    if (![[self.windowFrames objectForKey:@(windowID)] isEqualToValue:[NSValue valueWithRect:window.frame]]) {
        [self setNeedsLayout:YES];
    }
    
    NSUInteger layerIndex = [self.windowIDList indexOfObject:@(windowID)];
    ((CALayer *)self.thumbnailLayer.sublayers[layerIndex]).contents = content;
}

#pragma mark Internal

- (void)_createLayers;
{
    CALayer *(^newLayer)() = ^{
        CALayer *result = [CALayer layer];
        result.magnificationFilter = kCAFilterTrilinear;
        result.minificationFilter = kCAFilterTrilinear;
        result.contentsGravity = kCAGravityResizeAspect;
        result.actions = @{@"contents" : [NSNull null]};
        return result;
    };
    
    self.thumbnailLayer = newLayer();
    self.thumbnailLayer.zPosition = 1.0;
    [self.layer addSublayer:self.thumbnailLayer];
    
    self.iconLayer = newLayer();
    self.iconLayer.zPosition = 2.0;
    [self.layer addSublayer:self.iconLayer];
}

- (void)_updateIconLayout;
{
    NSRect thumbFrame = self.bounds;
    CGFloat thumbSize = thumbFrame.size.width;

    // imageSize is a lie, but it does give the correct aspect ratio. It's always been a square anecdotally, but you can't be too careful!
    NSSize imageSize = self.icon.size;
    
    CGFloat iconSize = thumbSize * kNNMaxApplicationIconSize / kNNMaxWindowThumbnailSize;
    CGFloat scale = iconSize / MAX(imageSize.width, imageSize.height);
    
    // make the size fit correctly
    imageSize = NSMakeSize(MIN(round(imageSize.width * scale), iconSize), MIN(round(imageSize.height * scale), iconSize));
    
    self.iconLayer.frame = (NSRect){
        .size = imageSize,
        .origin.x = thumbFrame.origin.x + (thumbFrame.size.width - imageSize.width),
        .origin.y = thumbFrame.origin.y
    };
}

@end
