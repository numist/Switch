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
#import "NNDelegateProxy.h"
#import "NNObjectSerializer.h"
#import "NNSwitcherViewController.h"
#import "NNWindowStore.h"


@interface NNSwitcher () {
    id<NNSwitcherDelegate> delegateProxy;
}

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
    store.delegate = [NNObjectSerializer serializedObjectForObject:self];
    [store startUpdatingWindowList];
    _store = store;
    _index = 0;
    
    __weak NNSwitcher *this = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayBeforePresentingSwitcherWindow * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        this.shouldShowWindow = YES;
        [this createSwitcherWindowIfNeeded];
    });
    
    return [NNObjectSerializer serializedObjectForObject:self];
}

- (void)dealloc;
{
    // TODO: set the active window to the currently-indexed window.
}

generateDelegateAccessors(self->delegateProxy, NNSwitcherDelegate)

@synthesize index = _index;

- (void)setIndex:(unsigned int)index;
{
    _index = index;
    
    // TODO: make sure updating the windows array modifies the index appropriately!
    if ([self.windows count]) {
            [self.delegate switcher:[NNObjectSerializer serializedObjectForObject:self] didUpdateIndex:self.index];
    }
}

- (unsigned)index;
{
    if ([self.windows count]) {
        return _index % [self.windows count];
    } else {
        return _index;
    }
}

#pragma mark Internal

- (void)createSwitcherWindowIfNeeded;
{
    if (!self.shouldShowWindow || !self.windows || self.switcherWindow) {
        // Not needed.
        return;
    }
    
    // Showtime! Start updating graphics assets.
    [self.store startUpdatingWindowContents];
    
    NSRect windowRect;
    {
        NSScreen *mainScreen = [NSScreen mainScreen];
        windowRect.size.width = kNNWindowToThumbInset + kNNMaxWindowThumbnailSize + kNNWindowToThumbInset;
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
    
    NNSwitcherViewController *controller = [NNSwitcherViewController new];
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
}

#pragma mark NNWindowStoreDelegate

- (oneway void)windowStoreDidUpdateWindowList:(NNWindowStore *)store;
{
    NNWindowData *selectedWindow = [self.windows count] > self.index ? [self.windows objectAtIndex:self.index] : nil;
    self.windows = store.windows;
    
    [self createSwitcherWindowIfNeeded];

    [self.delegate switcher:[NNObjectSerializer serializedObjectForObject:self] didUpdateWindowList:self.windows];
    
    NSUInteger newIndex = [self.windows indexOfObject:selectedWindow];
    if (selectedWindow) {
        if (![self.windows containsObject:selectedWindow]) {
            // Window destroyed
            self.index = MIN(self.index, [self.windows count] - 1);
        } else if (self.index != newIndex) {
            // Window moved
            self.index = newIndex;
        }
    }
}

- (oneway void)windowStore:(NNWindowStore *)store contentsOfWindowDidChange:(NNWindowData *)window;
{
    [self.delegate switcher:[NNObjectSerializer serializedObjectForObject:self] contentsOfWindowDidChange:window];
}

@end
