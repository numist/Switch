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

#import "constants.h"
#import "NNApplication.h"
#import "NNHotKeyManager.h"
#import "NNHUDCollectionView.h"
#import "NNWindow+Private.h"
#import "NNWindowStore.h"
#import "NNWindowThumbnailView.h"


@interface NNAppDelegate () <NNWindowStoreDelegate, NNHUDCollectionViewDataSource, NNHotKeyManagerDelegate>

#pragma mark State
@property (nonatomic, assign) NSUInteger selectedIndex;
@property (nonatomic, weak) NNWindow *selectedWindow;

#pragma mark UI
@property (nonatomic, strong) NSWindow *appWindow;
@property (nonatomic, strong) NNHUDCollectionView *collectionView;

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
}

#pragma mark - Dynamic properties

@dynamic selectedIndex;

- (void)setSelectedIndex:(NSUInteger)selectedIndex;
{
    if (selectedIndex < NSNotFound) {
        selectedIndex %= [self.windows count];
        self.selectedWindow = [self.windows objectAtIndex:selectedIndex];
        [self.collectionView selectCellAtIndex:selectedIndex];
    } else {
        self.selectedWindow = nil;
        [self.collectionView deselectCell];
    }
}

- (NSUInteger)selectedIndex;
{
    return [self.windows indexOfObject:self.selectedWindow];
}

#pragma mark Internal

- (void)createWindowIfNeeded;
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
        }
        self.appWindow = switcherWindow;
        
        NNHUDCollectionView *collectionView = [[NNHUDCollectionView alloc] initWithFrame:NSMakeRect(self.appWindow.frame.size.width / 2.0, self.appWindow.frame.size.height / 2.0, 0.0, 0.0)];
        {
            collectionView.maxWidth = [NSScreen mainScreen].frame.size.width - (kNNScreenToWindowInset * 2.0);
            collectionView.maxCellSize = kNNMaxWindowThumbnailSize;
            collectionView.dataSource = self;
        }
        self.collectionView = collectionView;
        [self.appWindow.contentView addSubview:self.collectionView];
    });
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
    result.windowIsResponsive = !!window.haxWindow;
    return result;
}

#pragma mark NNWindowStoreDelegate

static BOOL needsReset;

- (void)storeWillChangeContent:(NNWindowStore *)store;
{
    needsReset = NO;
}

- (void)store:(NNWindowStore *)store didChangeWindow:(NNWindow *)window atIndex:(NSUInteger)index forChangeType:(NNWindowStoreChangeType)type newIndex:(NSUInteger)newIndex;
{
    switch (type) {
        case NNWindowStoreChangeInsert:
            NSLog(@"Added window %@", window);
            [self.windows insertObject:window atIndex:newIndex];
            needsReset = YES;
            break;
            
        case NNWindowStoreChangeMove:
            [self.windows removeObjectAtIndex:index];
            [self.windows insertObject:window atIndex:newIndex];
            needsReset = YES;
            break;
            
        case NNWindowStoreChangeDelete:
            [self.windows removeObjectAtIndex:index];
            needsReset = YES;
            break;
            
        case NNWindowStoreChangeWindowContent: {
            NNWindowThumbnailView *thumb = (NNWindowThumbnailView *)[self.collectionView cellForIndex:index];
            [thumb setWindowThumbnail:window.image];
            [thumb setNeedsDisplay:YES];
            break;
        }
        
        case NNWindowStoreChangeResponsive: {
            NNWindowThumbnailView *thumb = (NNWindowThumbnailView *)[self.collectionView cellForIndex:index];
            thumb.windowIsResponsive = YES;
            [thumb setNeedsDisplay:YES];
            break;
        }
    }
}

- (void)storeDidChangeContent:(NNWindowStore *)store;
{
//    [self createSwitcherWindowIfNeeded];
    // endUpdates, etc.
    if (needsReset) {
        [self.collectionView reloadData];
    }
    
    if ([self.windows count]) {
        if (self.selectedIndex >= NSNotFound) {
            self.selectedIndex = 0;
        }
        
        [self.collectionView selectCellAtIndex:self.selectedIndex];
    }
}

#pragma mark NNHotKeyManagerDelegate

- (void)hotKeyManagerInvokedInterface:(NNHotKeyManager *)manager;
{
    [self.store startUpdatingWindowList];

    // TODO(numist): put this on a time delay. NSTimer!
    [self createWindowIfNeeded];
    [self.appWindow orderFront:self];
    [self.collectionView reloadData];
    
    [self.store startUpdatingWindowContents];
}

- (void)hotKeyManagerDismissedInterface:(NNHotKeyManager *)manager;
{
    [self.appWindow orderOut:self];
    self.selectedIndex = NSNotFound;
    [self.store stopUpdatingWindowList];
    [self.store stopUpdatingWindowContents];
}

- (void)hotKeyManagerBeginIncrementingSelection:(NNHotKeyManager *)manager;
{
    if (![self.windows count]) {
        return;
    }

    if (self.selectedIndex >= NSNotFound) {
        self.selectedIndex = 0;
    } else if (!self.incrementing || self.selectedIndex != [self.windows count] - 1) {
        self.selectedIndex = (self.selectedIndex + 1) % [self.windows count];
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
    } else if (!self.decrementing || self.selectedIndex != 0) {
        self.selectedIndex = self.selectedIndex == 0 ? [self.windows count] - 1 : self.selectedIndex - 1;
    }
    
    self.decrementing = YES;
}

- (void)hotKeyManagerEndDecrementingSelection:(NNHotKeyManager *)manager;
{
    self.decrementing = NO;
}

- (void)hotKeyManagerClosedWindow:(NNHotKeyManager *)manager;
{
    NSLog(@"Close window: %@", self.selectedWindow);
}

- (void)hotKeyManagerClosedApplication:(NNHotKeyManager *)manager;
{
    NSLog(@"Close Application: %@", self.selectedWindow.application);
}

@end
