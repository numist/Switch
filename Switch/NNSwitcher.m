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
#import "despatch.h"
#import "NNSwitcherViewController.h"
#import "NNWindowStore.h"


@interface NNSwitcher ()

@property (nonatomic, strong, readonly) dispatch_queue_t lock;
@property (nonatomic, assign) BOOL shouldShowWindow;
@property (nonatomic, strong) NNWindowStore *store;
@property (nonatomic, strong) NSWindow *switcherWindow;
@property (nonatomic, strong) NNSwitcherViewController *switcherWindowController;
@property (nonatomic, strong) NSArray *windows;

@end


@implementation NNSwitcher

- (instancetype)init;
{
    self = [super init];
    if (!self) return nil;
    
    _lock = despatch_lock_create([[NSString stringWithFormat:@"%@ <%p>", [self class], self] UTF8String]);

    NNWindowStore *store = [[NNWindowStore alloc] initWithDelegate:self];
    [store startUpdatingWindowList];
    _store = store;
    _index = 0;
    _windows = [NSMutableArray new];
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayBeforePresentingSwitcherWindow * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        __strong __typeof__(self) self = weakSelf;
        self.shouldShowWindow = YES;
        [self createSwitcherWindowIfNeeded];
    });
    
    return self;
}

- (void)dealloc;
{
    // TODO: set the active window to the currently-indexed window.
}

@synthesize index = _index;

- (void)setIndex:(unsigned int)index;
{
    _index = index;
    
    // TODO: make sure updating the windows array modifies the index appropriately!
    if ([self.windows count]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate switcher:self didUpdateIndex:self.index];
        });
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
    
    [switcherWindow orderFront:self];
    self.delegate = controller;
    self.switcherWindowController = controller;
    self.switcherWindow = switcherWindow;
}

#pragma mark NNWindowStoreDelegate

- (void)store:(NNWindowStore *)store didChangeWindow:(NNWindow *)window atIndex:(NSUInteger)index forChangeType:(NNWindowStoreChangeType)type newIndex:(NSUInteger)newIndex;
{
    despatch_lock_assert(dispatch_get_main_queue());

    NSMutableArray *windows = (NSMutableArray *)self.windows;
    
    switch (type) {
        case NNWindowStoreChangeInsert:
            [windows insertObject:window atIndex:newIndex];
            break;
            
        case NNWindowStoreChangeMove:
            [windows removeObjectAtIndex:index];
            [windows insertObject:window atIndex:newIndex];
            
            if (self.index == index) {
                self.index = newIndex;
            }
            break;
            
        case NNWindowStoreChangeDelete:
            [windows removeObjectAtIndex:index];
            
            // TODO(numist): What happens when there are zero windows! :o
            if (self.index == index) {
                self.index = MIN(index - 1, [windows count] - 1);
            }
            break;
            
        case NNWindowStoreChangeUpdate:
            [self.delegate switcher:self contentsOfWindowDidChange:window];
            break;
    }
}

- (void)storeDidChangeContent:(NNWindowStore *)store;
{
    [self createSwitcherWindowIfNeeded];

    // TODO: don't be passing self.windows into here!
    NSArray *windows = [self.windows copy];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate switcher:self didUpdateWindowList:windows];
    });
}

@end
