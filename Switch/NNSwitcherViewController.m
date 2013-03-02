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
#import "NNRoundedRectView.h"
#import "NNWindowThumbnailView.h"
#import "NNWindowData.h"
#import "NNApplication.h"

@interface NNSwitcherViewController ()

@property (nonatomic, weak) NNSwitcher *switcher;

@property (nonatomic, strong) NSMutableDictionary *thumbViews;
@property (nonatomic, assign) BOOL firstUpdate;

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
    NSLog(@"View loaded");
    self.view = [[NNRoundedRectView alloc] initWithFrame:NSZeroRect];
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
        
        for (unsigned i = 0; i < numWindows; i++) {
            NNWindowData *window = [windows objectAtIndex:i];
            NNWindowThumbnailView *thumbView = [self createThumbViewForWindow:window];
            thumbView.frame = [self frameForThumbnailViewAtIndex:i thumbSize:thumbSize];
        }
    } else {
        // TODO: Only do this if necessary
        [self.view.window setFrame:windowFrame display:YES animate:YES];
        
        // Iterating over a copy because destroyThumbViewForWindow: mutates the thumbViews dictionary
        for (NNWindowData *window in [self.thumbViews copy]) {
            if (![windows containsObject:window]) {
                // TODO: animations
                [self destroyThumbViewForWindow:window];
            }
        }
        
        for (unsigned i = 0; i < numWindows; i++) {
            NNWindowData *window = [windows objectAtIndex:i];
            
            NNWindowThumbnailView *thumbView = [self.thumbViews objectForKey:window];
            if (!thumbView) {
                // TODO: Should set the thumbView's frame to vertically-centered origin of it's indexes frame, size zero to animate in
                thumbView = [self createThumbViewForWindow:window];
            }
            
            // TODO: animations
            thumbView.frame = [self frameForThumbnailViewAtIndex:i thumbSize:thumbSize];
        }
    }
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

- (NSRect)frameForThumbnailViewAtIndex:(unsigned)index thumbSize:(CGFloat)thumbSize;
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
