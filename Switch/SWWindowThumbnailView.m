//
//  SWWindowThumbnailView.m
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

#import "SWWindowThumbnailView.h"

#import <Foundation/NSGeometry.h>
#import <QuartzCore/QuartzCore.h>

#import "SWApplication.h"
#import "SWWindowContentsService.h"
#import "SWWindowGroup.h"
#import "SWWindowListService.h"


@interface SWWindowThumbnailView () <SWWindowListSubscriber, SWWindowContentsSubscriber>

@property (nonatomic, strong, readonly) NSOrderedSet *windowIDList;
@property (nonatomic, strong, readonly) NSMutableDictionary *windowFrames;
@property (nonatomic, assign) BOOL valid;


@property (nonatomic, strong) SWWindowGroup *windowGroup;
@property (nonatomic, strong, readonly) RACSignal *thumbnailSignal;

@property (nonatomic, strong) NSImage *icon;

@property (nonatomic, strong) CALayer *thumbnailLayer;
@property (nonatomic, strong) CALayer *iconLayer;

@end


@implementation SWWindowThumbnailView

#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame window:(SWWindow *)windowGroup;
{
    if (!(self = [super initWithFrame:frame])) { return nil; }
    
    //
    // Data initialization
    //
    if (!Check([windowGroup isKindOfClass:[SWWindowGroup class]])) {
        return nil;
    }
    _windowGroup = CLASS_CAST(SWWindowGroup, windowGroup);
    
    NSMutableOrderedSet *windowIDList = [NSMutableOrderedSet new];
    NSMutableDictionary *windowFrames = [NSMutableDictionary new];
    for (SWWindow *window in _windowGroup.windows) {
        [windowIDList addObject:@(window.windowID)];
        [windowFrames setObject:[NSValue valueWithRect:window.frame] forKey:@(window.windowID)];
    }
    _windowIDList = windowIDList;
    _windowFrames = windowFrames;
    
    _valid = YES;
    
    //
    // View initialization
    //
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self setWantsLayer:YES];
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
    [self _createLayers];
    
    for (SWWindow *window in _windowGroup.windows) {
        NSImage *content = [[SWWindowContentsService sharedService] contentForWindow:window];
        if (content) {
            [self _sublayerForWindow:window].contents = content;
        }
    }
    
    NSImage *icon;
    {
        icon = windowGroup.application.icon;

        // This is necessary or the CALayer may draw a low resolution representation when a higher resolution is needed, and it's better to be too high-resolution than too low.
        NSSize imageSize = icon.size;
        CGFloat scale = kNNMaxApplicationIconSize / MAX(imageSize.width, imageSize.height);
        icon.size = NSMakeSize(round(imageSize.width * scale), round(imageSize.height * scale));
    }

    _icon = icon;
    _iconLayer.contents = icon;
    
    //
    // Configuration initialization
    //
    
    // Disable implicit animation on frame changes.
    ((id<NSAnimatablePropertyContainer>)self.animator).animations = @{@"frame" : [NSNull null]};

    [self setNeedsLayout:YES];
    
    [[NNServiceManager sharedManager] addSubscriber:self forService:[SWWindowContentsService class]];
    
    return self;
}

#pragma mark - NSView

- (void)layout;
{
    [super layout];
    
    self.thumbnailLayer.frame = self.bounds;
    
    NSSize thumbSize = self.thumbnailLayer.bounds.size;
    CGRect windowGroupFrame = self.windowGroup.frame;
    
    CGFloat scale = MIN(thumbSize.width / windowGroupFrame.size.width, thumbSize.height / windowGroupFrame.size.height);
    
    CGFloat scaledXOffset = (thumbSize.width - (windowGroupFrame.size.width * scale)) / 2.0;
    CGFloat scaledYOffset = (thumbSize.height - (windowGroupFrame.size.height * scale)) / 2.0;
    
    for (NSUInteger i = 0; i < self.windowGroup.windows.count; i++) {
        SWWindow *window = self.windowGroup.windows[i];
        CALayer *layer = [self _sublayerForWindow:window];
        CGRect frame = window.frame;
        
        // Move the frame's origin to be anchored at the "bottom left" of the windowFrame.
        frame.origin.x -= windowGroupFrame.origin.x;
        frame.origin.y -= windowGroupFrame.origin.y;
        
        // Scale the frame into the layer's space.
        frame.origin.x *= scale;
        frame.origin.y *= scale;
        frame.size.width *= scale;
        frame.size.height *= scale;
        
        // Center the group within the thumbnail frame.
        frame.origin.x += scaledXOffset;
        frame.origin.y += scaledYOffset;
        
        layer.frame = frame;
    }
    
    [self _updateIconLayout];
}

#pragma mark - SWWindowThumbnailView

- (void)setActive:(BOOL)active;
{
    if (!self.valid) {
        return;
    }
    
    float opacity = active ? 1.0 : 0.5;
    
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
    float opacity = valid ? 1.0 : 0.5;
    
    CABasicAnimation *animation = [CABasicAnimation animation];
    animation.fromValue = @(((CALayer *)self.layer.presentationLayer).opacity);
    animation.toValue = @(opacity);
    animation.duration = 0.15;
    [self.layer addAnimation:animation forKey:@"opacity"];
    self.layer.opacity = opacity;
}

#pragma mark - SWWindowListSubscriber

- (oneway void)windowListService:(SWWindowListService *)service updatedList:(NSOrderedSet *)windows;
{
    BOOL thisWindowExists = NO;
    for (SWWindowGroup *windowGroup in windows) {
        // Make a window ID list to represent this window group.
        NSMutableOrderedSet *windowIDList = [NSMutableOrderedSet new];
        for (SWWindow *window in windowGroup.windows) {
            [windowIDList addObject:@(window.windowID)];
        }

        if ([windowIDList isEqual:self.windowIDList]) {
            thisWindowExists = YES;
            
            for (SWWindow *window in windowGroup.windows) {
                NSValue *oldBoxedRect = self.windowFrames[@(window.windowID)];
                NSValue *newBoxedRect = [NSValue valueWithRect:window.frame];
                
                if (![newBoxedRect isEqualToValue:oldBoxedRect]) {
                    self.windowFrames[@(window.windowID)] = newBoxedRect;
                    [self setNeedsLayout:YES];
                    
                }
            }
            
            self.windowGroup = windowGroup;
            
            break;
        }
    }
    
    self.valid = thisWindowExists;
}

#pragma mark - SWWindowContentsSubscriber

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
    
    [self _sublayerForWindow:window].contents = content;
}

#pragma mark - Internal

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
    
    for (sw_unused SWWindow *window in self.windowGroup.windows) {
        [self.thumbnailLayer addSublayer:newLayer()];
    }
    
    self.iconLayer = newLayer();
    self.iconLayer.zPosition = 2.0;
    [self.layer addSublayer:self.iconLayer];
}

- (void)_updateIconLayout;
{
    CGRect thumbFrame = self.bounds;
    CGFloat thumbSize = thumbFrame.size.width;

    // imageSize is a lie, but it does give the correct aspect ratio. It's always been a square anecdotally, but you can't be too careful!
    NSSize imageSize = self.icon.size;
    
    CGFloat iconSize = thumbSize * kNNMaxApplicationIconSize / kNNMaxWindowThumbnailSize;
    CGFloat scale = iconSize / MAX(imageSize.width, imageSize.height);
    
    // make the size fit correctly
    imageSize = NSMakeSize(MIN(round(imageSize.width * scale), iconSize), MIN(round(imageSize.height * scale), iconSize));
    
    self.iconLayer.frame = (CGRect){
        .size = imageSize,
        .origin.x = thumbFrame.origin.x + (thumbFrame.size.width - imageSize.width),
        .origin.y = thumbFrame.origin.y
    };
}

- (CALayer *)_sublayerForWindow:(SWWindow *)window;
{
    NSUInteger windowCount = self.windowGroup.windows.count;
    
    NSUInteger index = [self.windowGroup.windows indexOfObject:window];
    
    // It's possible that we're racing a window list update. If we lost, find the window in the list by windowID instead of failing right away.
    if (index > self.thumbnailLayer.sublayers.count) {
        for (SWWindow *storedWindow in self.windowGroup.windows) {
            if (storedWindow.windowID == window.windowID) {
                index = [self.windowGroup.windows indexOfObject:storedWindow];
                break;
            }
        }
    }

    // Sublayers are in reverse order as windows.
    index = windowCount - (index + 1);
    
    if (!Check(index < self.thumbnailLayer.sublayers.count)) {
        return nil;
    }
    
    return self.thumbnailLayer.sublayers[index];
}

@end
