//
//  NNSwitcherViewController.m
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

#import "NNSwitcherViewController.h"

#import "constants.h"
#import "NNHUDView.h"
#import "NNSelectionBoxView.h"
#import "NNWindowThumbnailView.h"
#import "NNWindowData.h"
#import "NNApplication.h"


@interface NNSwitcherViewController ()

@property (nonatomic, weak) NNSwitcher *switcher;

@property (nonatomic, strong) NSMutableDictionary *deadWindows;
@property (nonatomic, strong) NSMutableDictionary *thumbViews;
@property (nonatomic, assign) BOOL firstUpdate;
@property (nonatomic, weak) NSAnimation *currentAnimation;

@end


@implementation NNSwitcherViewController

- (id)initWithSwitcher:(NNSwitcher *)switcher;
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;

    _switcher = switcher;
    _firstUpdate = YES;
    
    return self;
}

- (void)loadView;
{
    self.view = [[NNHUDView alloc] initWithFrame:NSZeroRect];
}

- (void)updateViewsWithWindowList:(NSArray *)windows;
{
    CGFloat thumbSize = maxWindowThumbnailSize;
    NSScreen *mainScreen = [NSScreen mainScreen];
    NSUInteger numWindows = [windows count];
    CGFloat requiredPaddings = windowToItemInset + numWindows * (itemToThumbInset + itemToThumbInset) + windowToItemInset;
    CGFloat maxTheoreticalWindowWidth = requiredPaddings + thumbSize * numWindows;
    CGFloat maxAllowedWindowWidth = mainScreen.frame.size.width - (screenToSwitcherWindowInset * 2.0);
    
    if (maxTheoreticalWindowWidth > maxAllowedWindowWidth) {
        thumbSize = floor((maxAllowedWindowWidth - requiredPaddings) / numWindows);
    }
    
    NSRect windowFrame;
    {
        windowFrame.size.width = MIN(maxAllowedWindowWidth, maxTheoreticalWindowWidth);
        windowFrame.size.height = windowToThumbInset + thumbSize + windowToThumbInset;
        windowFrame.origin.x = floor((mainScreen.frame.size.width - windowFrame.size.width) / 2.0);
        windowFrame.origin.y = floor((mainScreen.frame.size.height - windowFrame.size.height) / 2.0);
    }

    if (self.firstUpdate) {
        self.firstUpdate = NO;
        [self.view.window setFrame:windowFrame display:YES animate:NO];
        self.thumbViews = [NSMutableDictionary dictionaryWithCapacity:numWindows];
        self.deadWindows = [NSMutableDictionary new];
        
        for (NSUInteger i = 0; i < numWindows; i++) {
            NNWindowData *window = [windows objectAtIndex:i];
            NNWindowThumbnailView *thumbView = [self createThumbViewForWindow:window];
            thumbView.frame = [self finalFrameForThumbnailViewAtIndex:i thumbSize:thumbSize];
        }
    } else {
        // Create views for newly-arrived windows
        NSMutableDictionary *newWindows = [NSMutableDictionary new];
        for (NSUInteger i = 0; i < numWindows; i++) {
            NNWindowData *window = [windows objectAtIndex:i];
            NNWindowThumbnailView *thumbView = [self.thumbViews objectForKey:window];
            if (!thumbView) {
                thumbView = [self createThumbViewForWindow:window];
                thumbView.frame = [self initialFrameForThumbnailViewAtIndex:i thumbSize:thumbSize];
                [newWindows setObject:thumbView forKey:window];
            }
        }
        
        // Mark views for removal
        for (NNWindowData *window in [self.thumbViews copy]) {
            if (![windows containsObject:window]) {
                [self.deadWindows setObject:[self.thumbViews objectForKey:window] forKey:window];
            }
        }
        
        NSMutableArray *animations = [NSMutableArray new];
        {
            NSDictionary *(^animationForWindow)(NNWindowData *) = ^(NNWindowData *window) {
                NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:3];
                NSUInteger index = [windows indexOfObject:window];
                NNWindowThumbnailView *view = [self.thumbViews objectForKey:window];
                
                [result setObject:view forKey:NSViewAnimationTargetKey];
                //[result setObject:[NSValue valueWithRect:view.frame] forKey:NSViewAnimationStartFrameKey];
                if (index == NSNotFound) {
                    [result setObject:[NSValue valueWithRect:[self collapseFrame:view.frame]] forKey:NSViewAnimationEndFrameKey];
                    [result setObject:NSViewAnimationFadeOutEffect forKey:NSViewAnimationEffectKey];
                } else {
                    [result setObject:[NSValue valueWithRect:[self finalFrameForThumbnailViewAtIndex:index thumbSize:thumbSize]] forKey:NSViewAnimationEndFrameKey];
                }
                
                return result;
            };
            
            // Animations for new and pre-existent windows
            for (NNWindowData *window in windows) {
                [animations addObject:animationForWindow(window)];
            }
            
            // Animations for ex-windows
            for (NNWindowData *window in self.deadWindows) {
                [animations addObject:animationForWindow(window)];
            }
            
            // Animation for the NSWindow
            [animations addObject:@{
                NSViewAnimationTargetKey: self.view.window,
                NSViewAnimationStartFrameKey: [NSValue valueWithRect:self.view.window.frame],
                NSViewAnimationEndFrameKey: [NSValue valueWithRect:windowFrame]
            }];
        }

        NSViewAnimation *theAnim;
        theAnim = [[NSViewAnimation alloc] initWithViewAnimations:animations];
        [theAnim setDuration:0.2];
        [theAnim setAnimationCurve:NSAnimationEaseIn];
        theAnim.delegate = (id<NSAnimationDelegate>)self;
        
        NSAnimation *currentAnimation = self.currentAnimation;
        if (currentAnimation) {
            [currentAnimation stopAnimation];
        }
        self.currentAnimation = theAnim;
        [theAnim startAnimation];
    }
}

#pragma mark NSAnimationDelegate

- (void)animationDidEnd:(NSAnimation *)animation;
{
    for (NNWindowData *window in self.deadWindows) {
        [self destroyThumbViewForWindow:window];
    }
    [self.deadWindows removeAllObjects];
}

#pragma mark NNSwitcherDelegate

- (void)switcher:(NNSwitcher *)switcher didUpdateIndex:(unsigned int)index;
{
    // TODO: update selected thingy
}

- (void)switcher:(NNSwitcher *)switcher didUpdateWindowList:(NSArray *)windows;
{
    [self updateViewsWithWindowList:windows];
}

- (void)switcher:(NNSwitcher *)switcher contentsOfWindowDidChange:(NNWindowData *)window;
{
    [[self.thumbViews objectForKey:window] setWindowThumbnail:window.image];
}

#pragma mark Internal

- (NNWindowThumbnailView *)createThumbViewForWindow:(NNWindowData *)window;
{
    NNWindowThumbnailView *result = [[NNWindowThumbnailView alloc] initWithFrame:NSZeroRect];
    result.applicationIcon = window.application.icon;
    result.windowThumbnail = window.image;
    [self.thumbViews setObject:result forKey:window];
    [self.view addSubview:result];
    return result;
}

- (void)destroyThumbViewForWindow:(NNWindowData *)window;
{
    [[self.thumbViews objectForKey:window] removeFromSuperview];
    [self.thumbViews removeObjectForKey:window];
}

- (NSRect)collapseFrame:(NSRect)frame;
{
    NSRect result = frame;
    {
        result.origin.y += result.size.height / 2.0;
        result.size = NSZeroSize;
    }
    return result;
}

- (NSRect)initialFrameForThumbnailViewAtIndex:(NSUInteger)index thumbSize:(CGFloat)thumbSize;
{
    return [self collapseFrame:[self finalFrameForThumbnailViewAtIndex:index thumbSize:thumbSize]];
}

- (NSRect)finalFrameForThumbnailViewAtIndex:(NSUInteger)index thumbSize:(CGFloat)thumbSize;
{
    NSRect result;
    {
        result.origin.x = windowToItemInset + index * itemSize(thumbSize) + itemToThumbInset;
        result.origin.y = windowToThumbInset;
        result.size.width = thumbSize;
        result.size.height = thumbSize;
    }
    return result;
}

@end
