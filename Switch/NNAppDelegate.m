//
//  NNAppDelegate.m
//  Switch
//
//  Created by Scott Perry on 02/24/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNAppDelegate.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

#import "constants.h"
#import "NNApplication.h"
#import "NNHotKeyManager.h"
#import "NNHUDCollectionView.h"
#import "NNWindow+Private.h"
#import "NNWindowStore.h"
#import "NNWindowThumbnailView.h"


static NSTimeInterval kNNWindowDisplayDelay = 0.25;


@interface NNAppDelegate () <NNWindowStoreDelegate, NNHUDCollectionViewDataSource, NNHUDCollectionViewDelegate, NNHotKeyManagerDelegate>

#pragma mark State
@property (nonatomic, assign) BOOL active;
@property (nonatomic, assign) BOOL windowListLoaded;
@property (nonatomic, strong) NSTimer *displayTimer;
@property (nonatomic, assign) BOOL pendingSwitch;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, assign) BOOL adjustedIndex;

#pragma mark UI
@property (nonatomic, strong) NSWindow *appWindow;
@property (nonatomic, strong) NNHUDCollectionView *collectionView;
@property (nonatomic, assign) BOOL needsReset;

#pragma mark NNWindowStore and state
@property (nonatomic, strong) NSMutableArray *windows;
@property (nonatomic, strong) NNWindowStore *store;

#pragma mark NNHotKeyManager and state
@property (nonatomic, strong) NNHotKeyManager *keyManager;
@property (nonatomic, assign) BOOL incrementing;
@property (nonatomic, assign) BOOL decrementing;

@end


@implementation NNAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.windows = [NSMutableArray new];
    self.store = [[NNWindowStore alloc] initWithDelegate:self];
    
    
    self.keyManager = [NNHotKeyManager new];
    self.keyManager.delegate = self;
    
    [self createWindow];
    [self setUpReactions];
}

#pragma mark Internal

- (NNWindow *)selectedWindow;
{
    return self.selectedIndex < [self.windows count] ? [self.windows objectAtIndex:self.selectedIndex] : nil;
}

- (void)createWindow;
{
    NSRect windowRect;
    {
        NSScreen *mainScreen = [NSScreen mainScreen];
        windowRect = mainScreen.frame;
    }
    
    NSWindow *switcherWindow = [[NSWindow alloc] initWithContentRect:windowRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    {
        switcherWindow.movableByWindowBackground = NO;
        switcherWindow.hasShadow = NO;
        switcherWindow.opaque = NO;
        switcherWindow.backgroundColor = [NSColor clearColor];
        switcherWindow.level = NSPopUpMenuWindowLevel;
        switcherWindow.acceptsMouseMovedEvents = YES;
    }
    self.appWindow = switcherWindow;
    
    NNHUDCollectionView *collectionView = [[NNHUDCollectionView alloc] initWithFrame:NSMakeRect(self.appWindow.frame.size.width / 2.0, self.appWindow.frame.size.height / 2.0, 0.0, 0.0)];
    {
        collectionView.maxWidth = [NSScreen mainScreen].frame.size.width - (kNNScreenToWindowInset * 2.0);
        collectionView.maxCellSize = kNNMaxWindowThumbnailSize;
        collectionView.dataSource = self;
        collectionView.delegate = self;
    }
    self.collectionView = collectionView;
    [self.appWindow.contentView addSubview:self.collectionView];
}

- (void)setUpReactions;
{
    // Interface is only visible when Switch is active, the window list has loaded, and the display timer has timed out.
    [[[RACSignal
        combineLatest:@[RACAbleWithStart(self, windowListLoaded), RACAbleWithStart(self, displayTimer)]
        reduce:^(NSNumber *windowListLoaded, NSTimer *displayTimer) {
           return @(self.active && [windowListLoaded boolValue] && !displayTimer);
        }]
        distinctUntilChanged]
        subscribeNext:^(NSNumber *shouldDisplayInterface) {
            if ([shouldDisplayInterface boolValue]) {
                [[NSRunningApplication currentApplication] activateWithOptions:NSApplicationActivateIgnoringOtherApps];
                [self.appWindow orderFront:self];
                [self.store startUpdatingWindowContents];
            } else {
                [self.appWindow orderOut:self];
            }
        }];
    
    // Adjust the selected index by 1 if the first window's application is not already frontmost, but do this as late as possible.
    [[[RACSignal
        combineLatest:@[RACAbleWithStart(self, pendingSwitch), RACAbleWithStart(self, displayTimer)]
        reduce:^(NSNumber *pendingSwitch, NSTimer *displayTimer){
            return @([pendingSwitch boolValue] == YES || displayTimer == nil);
        }]
        distinctUntilChanged]
        subscribeNext:^(NSNumber *adjustIndex) {
            if (!self.adjustedIndex && [adjustIndex boolValue]) {
                if (self.selectedIndex == 1 && [self.windows count] > 1 && ![((NNWindow *)[self.windows objectAtIndex:0]).application isFrontMostApplication]) {
                    self.selectedIndex = 0;
                }
                self.adjustedIndex = YES;
            }
        }];
    
    // Clean up all that crazy state when the activation state changes.
    [[RACAble(self.active)
        distinctUntilChanged]
        subscribeNext:^(NSNumber *active) {
            if ([active boolValue]) {
                Check(![self.windows count]);
                Check(!self.displayTimer);

                self.displayTimer = [NSTimer scheduledTimerWithTimeInterval:kNNWindowDisplayDelay target:self selector:@selector(displayTimerFired:) userInfo:nil repeats:NO];
                self.adjustedIndex = NO;
                self.windowListLoaded = NO;
                self.selectedIndex = 0;
                
                [self.store startUpdatingWindowList];
            } else {
                Check(!self.pendingSwitch);
                
                [self.store stopUpdatingWindowList];
                [self.store stopUpdatingWindowContents];
                [self.displayTimer invalidate];
                self.displayTimer = nil;
                self.pendingSwitch = NO;
                [self.collectionView selectCellAtIndex:self.selectedIndex];
            }
        }];
    
    [[[RACSignal
        combineLatest:@[RACAbleWithStart(self, pendingSwitch), RACAbleWithStart(self, windowListLoaded)]]
        distinctUntilChanged]
        subscribeNext:^(id x) {
            RACTupleUnpack(NSNumber *pendingSwitch, NSNumber *windowListLoaded) = x;
            
            if ([pendingSwitch boolValue] && [windowListLoaded boolValue]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.pendingSwitch = NO;
                    
                    __block BOOL raiseSuccessful = YES;
                    NNWindow *selectedWindow = [self selectedWindow];
                    
                    dispatch_async(dispatch_get_global_queue(0, 0), ^{
                        if (selectedWindow) {
                            raiseSuccessful = [selectedWindow raise];
                        } else {
                            Check(self.selectedIndex == 0);
                            Log(@"No windows to raise! (Selection index: %lu)", self.selectedIndex);
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (raiseSuccessful) {
                                Check(self.active);
                                self.active = NO;
                            }
                        });
                    });
                });
            }
        }];
    
    [[RACAbleWithStart(self, selectedIndex)
        distinctUntilChanged]
        subscribeNext:^(id x) {
            NSUInteger index = [x unsignedIntegerValue];
            if (index == self.collectionView.selectedIndex) { return; }
            
            if (index < [self.windows count]) {
                [self.collectionView selectCellAtIndex:index];
            } else {
                [self.collectionView deselectCell];
            }
        }];
}

- (NNWindowThumbnailView *)cellForWindow:(NNWindow *)window;
{
    // Cache collection view cells as associated objects on the window model objects.
    NNWindowThumbnailView *result = objc_getAssociatedObject(window, (__bridge const void *)[NNWindowThumbnailView class]);
    if (!result) {
        result = [[NNWindowThumbnailView alloc] initWithFrame:NSZeroRect];
        result.applicationIcon = window.application.icon;
        result.windowThumbnail = window.image;
        objc_setAssociatedObject(window, (__bridge const void *)[NNWindowThumbnailView class], result, OBJC_ASSOCIATION_RETAIN);
    }
    
    return result;
}

#pragma mark - Notifications/Timers

- (void)displayTimerFired:(NSTimer *)timer;
{
    if (![timer isEqual:self.displayTimer]) {
        return;
    }
    
    self.displayTimer = nil;
}

#pragma mark - NNHUDCollectionViewDataSource

- (NSUInteger)HUDViewNumberOfCells:(NNHUDCollectionView *)view;
{
    return [self.windows count];
}

- (NSView *)HUDView:(NNHUDCollectionView *)view viewForCellAtIndex:(NSUInteger)index;
{
    NNWindow *window = [self.windows objectAtIndex:index];
    BailUnless(window, [[NSView alloc] initWithFrame:NSZeroRect]);

    return [self cellForWindow:window];
}

#pragma mark NNHUDCollectionViewDelegate

- (void)HUDView:(NNHUDCollectionView *)view willSelectCellAtIndex:(NSUInteger)index;
{
    self.selectedIndex = index;
}

- (void)HUDView:(NNHUDCollectionView *)view activateCellAtIndex:(NSUInteger)index;
{
    BailUnless(self.active,);

    if (index != self.selectedIndex) {
        self.selectedIndex = index;
    }
    
    self.pendingSwitch = YES;
}

#pragma mark NNWindowStoreDelegate

- (void)storeWillChangeContent:(NNWindowStore *)store;
{
    self.needsReset = NO;
}

- (void)store:(NNWindowStore *)store didChangeWindow:(NNWindow *)window atIndex:(NSUInteger)index forChangeType:(NNWindowStoreChangeType)type newIndex:(NSUInteger)newIndex;
{
    switch (type) {
        case NNWindowStoreChangeInsert:
            [self.windows insertObject:window atIndex:newIndex];
            self.needsReset = YES;
            break;
            
        case NNWindowStoreChangeMove:
            [self.windows removeObjectAtIndex:index];
            [self.windows insertObject:window atIndex:newIndex];
            self.needsReset = YES;
            break;
            
        case NNWindowStoreChangeDelete:
            [self.windows removeObjectAtIndex:index];
            
            // Update the selected index so it doesn't go out of bounds (default value is zero).
            if (index == self.selectedIndex && index >= [self.windows count]) {
                self.selectedIndex = [self.windows count] ? [self.windows count] - 1 : 0;
                [self.collectionView selectCellAtIndex:self.selectedIndex];
            }
            self.needsReset = YES;
            break;
            
        case NNWindowStoreChangeWindowContent: {
            NNWindowThumbnailView *thumb = (NNWindowThumbnailView *)[self.collectionView cellForIndex:index];
            [thumb setWindowThumbnail:window.image];
            break;
        }
    }
}

- (void)storeDidChangeContent:(NNWindowStore *)store;
{
    self.windowListLoaded = YES;
    
    if ([self.windows count]) {
        if (self.selectedIndex >= [self.windows count]) {
            self.selectedIndex = [self.windows count] - 1;
        }
        [self.collectionView selectCellAtIndex:self.selectedIndex];
    } else {
        [self.collectionView deselectCell];
    }
    
    if (self.needsReset) {
        [self.collectionView reloadData];
    }
}

#pragma mark NNHotKeyManagerDelegate

- (void)hotKeyManagerInvoked:(NNHotKeyManager *)manager;
{
    // If the interface is not being shown, bring it up.
    if (!self.active) {
        self.active = YES;
    }
}

- (void)hotKeyManagerDismissed:(NNHotKeyManager *)manager;
{
    if (self.active) {
        self.pendingSwitch = YES;
    }
}

- (void)hotKeyManagerBeginIncrementingSelection:(NNHotKeyManager *)manager;
{
    NSUInteger newIndex = self.selectedIndex;
    
    if (newIndex >= NSNotFound) {
        newIndex = 0;
    } else if (!self.incrementing || self.selectedIndex <= [self.windows count] - 1) {
        newIndex += 1;
    }
    
    if (self.windowListLoaded) {
        if (!self.incrementing) {
            newIndex %= [self.windows count];
        } else if (newIndex >= [self.windows count]) {
            newIndex = [self.windows count] - 1;
        }
    }
    
    self.selectedIndex = newIndex;
    
    self.incrementing = YES;
}

- (void)hotKeyManagerEndIncrementingSelection:(NNHotKeyManager *)manager;
{
    self.incrementing = NO;
}

- (void)hotKeyManagerBeginDecrementingSelection:(NNHotKeyManager *)manager;
{
    NSInteger newIndex = self.selectedIndex;
    
    if (newIndex >= NSNotFound) {
        newIndex = [self.windows count] - 1;
    } else if (!self.decrementing || newIndex != 0) {
        newIndex -= 1;
    }
    
    if (self.windowListLoaded) {
        if (!self.decrementing) {
            while (newIndex < 0) { newIndex += [self.windows count]; }
        } else if (newIndex < 0) {
            newIndex = 0;
        }
    }
    
    self.selectedIndex = newIndex;
    
    self.decrementing = YES;
}

- (void)hotKeyManagerEndDecrementingSelection:(NNHotKeyManager *)manager;
{
    self.decrementing = NO;
}

- (void)hotKeyManagerClosedWindow:(NNHotKeyManager *)manager;
{
    // TODO(numist): grey out thumbnail for selectedWindow
    
    __block BOOL success;
    NNWindow *selectedWindow = [self selectedWindow];
    NNWindow *nextWindow = nil;
    // If the first and second window belong to different applications, and the first application has another visible window, closing the first window will activate the first application's next window, changing the window order. This is fixed by tracking the next window (if it belongs to a different application) and raising it. This only matters when closing the frontmost window.
    if (self.selectedIndex == 0 && (self.selectedIndex + 1) < [self.windows count] && ![nextWindow.application isEqual:selectedWindow]) {
        nextWindow = [self.windows objectAtIndex:(self.selectedIndex + 1)];
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if ((success = [selectedWindow close])) {
            [nextWindow raise];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!success) {
                // TODO(numist): ungrey out thumbnail for selectedWindow
            }
        });
    });
}

- (void)hotKeyManagerClosedApplication:(NNHotKeyManager *)manager;
{
    Log(@"Close Application: %@", [self selectedWindow].application);
}

@end
