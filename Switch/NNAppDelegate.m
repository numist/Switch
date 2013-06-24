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
@property (nonatomic, assign) BOOL displayingInterface;
@property (nonatomic, assign) BOOL windowListLoaded;
@property (nonatomic, strong) NSTimer *displayTimer;
@property (nonatomic, assign) BOOL pendingSwitch;
@property (nonatomic, assign) NSUInteger selectedIndex;

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
    
    // Interface is only visible when Switch is active, the window list has loaded, and the display timer has timed out.
    [[RACSignal combineLatest:@[RACAbleWithStart(self, active), RACAbleWithStart(self, windowListLoaded), RACAbleWithStart(self, displayTimer)]
                       reduce:^(NSNumber *active, NSNumber *windowListLoaded, NSTimer *displayTimer) {
                           return @([active boolValue] && [windowListLoaded boolValue] && !displayTimer);
                       }]
        subscribeNext:^(NSNumber *shouldDisplayInterface) {
            // Dedup changes.
            if ([shouldDisplayInterface boolValue] == self.displayingInterface) {
                return;
            }
            
            if ([shouldDisplayInterface boolValue]) {
                [[NSRunningApplication currentApplication] activateWithOptions:NSApplicationActivateIgnoringOtherApps];
                [self.appWindow orderFront:self];
                [self.store startUpdatingWindowContents];
            } else {
                [self.appWindow orderOut:self];
            }
            self.displayingInterface = [shouldDisplayInterface boolValue];
        }];
    
    // Clean up all that crazy state when the activation state changes.
    [RACAble(self.active) subscribeNext:^(NSNumber *active) {
        if ([active boolValue]) {
            Check(![self.windows count]);
            Check(!self.displayTimer);

            [self.store startUpdatingWindowList];
            self.displayTimer = [NSTimer scheduledTimerWithTimeInterval:kNNWindowDisplayDelay target:self selector:@selector(displayTimerFired:) userInfo:nil repeats:NO];
        } else {
            Check(!self.pendingSwitch);
            
            [self.store stopUpdatingWindowList];
            [self.store stopUpdatingWindowContents];
            [self.displayTimer invalidate];
            self.displayTimer = nil;
            self.pendingSwitch = NO;
            self.windowListLoaded = NO;
            self.selectedIndex = 0;
            [self.collectionView selectCellAtIndex:self.selectedIndex];
        }
    }];
}

#pragma mark Internal

- (NNWindow *)selectedWindow;
{
    return self.selectedIndex < [self.windows count] ? [self.windows objectAtIndex:self.selectedIndex] : nil;
}

- (void)createWindow;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
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
            if (self.selectedIndex < NSNotFound) {
                [collectionView selectCellAtIndex:self.selectedIndex];
            }
        }
        self.collectionView = collectionView;
        [self.appWindow.contentView addSubview:self.collectionView];
    });
}

- (void)dismiss;
{
    if (self.active) {
        self.pendingSwitch = YES;
        
        if (self.windowListLoaded) {
            [self raise];
        }
    }
}

- (void)raise;
{
    self.pendingSwitch = NO;
    
    __block BOOL raiseSuccessful = YES;
    NNWindow *selectedWindow = [self selectedWindow];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (selectedWindow) {
            raiseSuccessful = [selectedWindow raise];
            Check(raiseSuccessful);
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
    NNWindowThumbnailView *result = [[NNWindowThumbnailView alloc] initWithFrame:NSZeroRect];
    result.applicationIcon = window.application.icon;
    result.windowThumbnail = window.image;
    return result;
}

#pragma mark NNHUDCollectionViewDelegate

- (void)HUDView:(NNHUDCollectionView *)view willSelectCellAtIndex:(NSUInteger)index;
{
    self.selectedIndex = index;
}

- (void)HUDView:(NNHUDCollectionView *)view activateCellAtIndex:(NSUInteger)index;
{
    if (index != self.selectedIndex) {
        self.selectedIndex = index;
    }
    
    [self dismiss];
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
    if (self.pendingSwitch) {
        // TODO(numist): raise the right thing.
        return;
    }
    
    // TODO(numist): due to timing issues, this should probably happen as late as possible--at the earlier of willDisplayInterface or willSwitch. During fast repeated invocations, this code is racing the system UI server bringing the correct application to the front.
    if ([self.windows count]) {
        if (!self.windowListLoaded) {
            if ([self.windows count] > 1 && [((NNWindow *)[self.windows objectAtIndex:0]).application isFrontMostApplication]) {
                self.selectedIndex = (self.selectedIndex + 1) % [self.windows count];
                [self.collectionView selectCellAtIndex:self.selectedIndex];
            }
        }

        [self.collectionView selectCellAtIndex:self.selectedIndex];
    }
    self.windowListLoaded = YES;
    
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
    [self dismiss];
}

- (void)hotKeyManagerBeginIncrementingSelection:(NNHotKeyManager *)manager;
{
    if (![self.windows count]) {
        return;
    }

    if (self.selectedIndex >= NSNotFound) {
        self.selectedIndex = 0;
        [self.collectionView selectCellAtIndex:self.selectedIndex];
    } else if (!self.incrementing || self.selectedIndex != [self.windows count] - 1) {
        self.selectedIndex = (self.selectedIndex + 1) % [self.windows count];
        [self.collectionView selectCellAtIndex:self.selectedIndex];
    }
    
    self.incrementing = YES;
}

- (void)hotKeyManagerEndIncrementingSelection:(NNHotKeyManager *)manager;
{
    self.incrementing = NO;
}

- (void)hotKeyManagerBeginDecrementingSelection:(NNHotKeyManager *)manager;
{
    if (![self.windows count]) {
        return;
    }
    
    if (self.selectedIndex >= NSNotFound) {
        self.selectedIndex = [self.windows count] - 1;
        [self.collectionView selectCellAtIndex:self.selectedIndex];
    } else if (!self.decrementing || self.selectedIndex != 0) {
        self.selectedIndex = self.selectedIndex == 0 ? [self.windows count] - 1 : self.selectedIndex - 1;
        [self.collectionView selectCellAtIndex:self.selectedIndex];
    }
    
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
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NNWindow *selectedWindow = [self selectedWindow];
        success = [selectedWindow close];
        
        // TODO(numist): this is potentially racy with window updates. Lock on the main thread for non-external code?
        if (success && self.selectedIndex == 0) {
            NNWindow *nextWindow = (self.selectedIndex + 1) < [self.windows count] ?[self.windows objectAtIndex:(self.selectedIndex + 1)] : nil;
            if (![nextWindow.application isEqual:selectedWindow]) {
                [nextWindow raise];
            }
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
