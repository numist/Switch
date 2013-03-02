//
//  NNSwitcher.m
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

#import "NNSwitcher.h"

#import "constants.h"
#import "NNSwitcherViewController.h"


@interface NNSwitcher ()

@property (nonatomic, strong) NNWindowStore *store;
@property (nonatomic, strong) NSArray *windows;

@property (nonatomic, assign) BOOL shouldShowWindow;
@property (nonatomic, strong) NSWindow *switcherWindow;
@property (nonatomic, strong) NNSwitcherViewController *switcherWindowController;

@end


@implementation NNSwitcher

- (instancetype)init;
{
    self = [super init];
    if (!self) return nil;
    
    NNWindowStore *store = [NNWindowStore new];
    store.delegate = self;
    [store startUpdatingWindowList];
    _store = store;
    _index = 0;
    
    __weak NNSwitcher *this = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayBeforePresentingSwitcherWindow * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        this.shouldShowWindow = YES;
        [self.store startUpdatingWindowContents];
        [this createSwitcherWindowIfNeeded];
    });
    
    return self;
}

- (void)dealloc;
{
    // set the active window to the currently-indexed window.
}

- (void)setIndex:(unsigned int)index;
{
    _index = index;
    
    // TODO: constrain to number of windows—add concurrency and make sure updating the windows array modifies the index appropriately!
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate switcher:self didUpdateIndex:index];
    });
}

#pragma mark Internal

- (void)createSwitcherWindowIfNeeded;
{
    if (!self.shouldShowWindow || !self.windows || self.switcherWindow) {
        // Not needed.
        return;
    }
    
    NSRect windowRect;
    {
        NSScreen *mainScreen = [NSScreen mainScreen];
        windowRect.size.width = windowToThumbInset + maxWindowThumbnailSize + windowToThumbInset;
        windowRect.size.height = windowRect.size.width;
        windowRect.origin.x = floor((mainScreen.frame.size.width - windowRect.size.width) / 2.0);
        windowRect.origin.y = floor((mainScreen.frame.size.height - windowRect.size.height) / 2.0);
    }
    
    NSWindow *switcherWindow = [[NSWindow alloc] initWithContentRect:windowRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    {
        switcherWindow.movableByWindowBackground = NO;
        switcherWindow.hasShadow = NO;
        switcherWindow.opaque = NO;
        switcherWindow.backgroundColor = [NSColor clearColor];
        switcherWindow.level = NSPopUpMenuWindowLevel;
    }
    
    NNSwitcherViewController *controller = [[NNSwitcherViewController alloc] initWithSwitcher:self];
    {
        NSView *contentView = [controller view];
        contentView.frame = ((NSView *)switcherWindow.contentView).bounds;
        [switcherWindow.contentView addSubview:contentView];
        [controller updateViewsWithWindowList:self.windows];
    }
    
    [switcherWindow makeKeyAndOrderFront:nil];
    self.delegate = controller;
    self.switcherWindowController = controller;
    self.switcherWindow = switcherWindow;
    NSLog(@"Created new switcher window and controller");
}

#pragma mark NNWindowStoreDelegate

- (void)windowStoreDidUpdateWindowList:(NNWindowStore *)store;
{
    [self createSwitcherWindowIfNeeded];
    
    self.windows = store.windows;
    [self.delegate switcher:self didUpdateWindowList:self.windows];
}

- (void)windowStore:(NNWindowStore *)store contentsOfWindowDidChange:(NNWindowData *)window;
{
    [self.delegate switcher:self contentsOfWindowDidChange:window];
}

@end
