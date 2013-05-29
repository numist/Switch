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
#import "NNHUDCollectionView.h"
#import "NNWindowStore.h"
#import "NNWindow.h"
#import "NNApplication.h"
#import "NNWindowThumbnailView.h"
#import "NNHotKeyManager.h"


@interface NNAppDelegate () <NNWindowStoreDelegate, NNHUDCollectionViewDataSource, NNHotKeyManagerDelegate>

@property (nonatomic, strong) NNHotKeyManager *keyManager;
@property (nonatomic, assign) BOOL incrementing;
@property (nonatomic, assign) BOOL decrementing;

@property (nonatomic, strong) NSWindow *appWindow;
@property (nonatomic, strong) NNHUDCollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *windows;
@property (nonatomic, strong) NNWindowStore *store;

@property (nonatomic, assign) NSUInteger selectedIndex;
@property (nonatomic, weak) NNWindow *selectedWindow;

@end


@implementation NNAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
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
    }
    self.appWindow = switcherWindow;
    
    NNHUDCollectionView *collectionView = [[NNHUDCollectionView alloc] initWithFrame:NSMakeRect(self.appWindow.frame.size.width / 2.0, self.appWindow.frame.size.height / 2.0, 0.0, 0.0)];
    {
        collectionView.maxWidth = [NSScreen mainScreen].frame.size.width - (kNNScreenToWindowInset * 2.0);
        collectionView.maxCellSize = 128;
        collectionView.dataSource = self;
    }
    self.collectionView = collectionView;
    [self.appWindow.contentView addSubview:self.collectionView];

    
    
    
    
    self.windows = [NSMutableArray new];
    self.store = [[NNWindowStore alloc] initWithDelegate:self];
    
    
    self.keyManager = [NNHotKeyManager new];
    self.keyManager.delegate = self;
}

#pragma mark Properties
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

// TODO: support for closing windows, quitting apps, mouse events?

#pragma mark NNWindowStoreDelegate

- (void)store:(NNWindowStore *)store didChangeWindow:(NNWindow *)window atIndex:(NSUInteger)index forChangeType:(NNWindowStoreChangeType)type newIndex:(NSUInteger)newIndex;
{
    switch (type) {
        case NNWindowStoreChangeInsert:
            [self.windows insertObject:window atIndex:newIndex];
            break;
            
        case NNWindowStoreChangeMove:
            [self.windows removeObjectAtIndex:index];
            [self.windows insertObject:window atIndex:newIndex];
            break;
            
        case NNWindowStoreChangeDelete:
            [self.windows removeObjectAtIndex:index];
            break;
            
        case NNWindowStoreChangeUpdate:
            break;
    }
}

- (void)storeDidChangeContent:(NNWindowStore *)store;
{
//    [self createSwitcherWindowIfNeeded];
    // endUpdates, etc.
    [self.collectionView reloadData];
    
    if ([self.windows count]) {
        if (self.selectedIndex >= NSNotFound) {
            self.selectedIndex = 0;
        }
        
        [self.collectionView selectCellAtIndex:self.selectedIndex];
    }
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

#pragma mark - NNHotKeyManagerDelegate

- (void)hotKeyManagerInvokedInterface:(NNHotKeyManager *)manager;
{
    [self.store startUpdatingWindowList];

    [self.appWindow orderFront:self];
    
    [self.store startUpdatingWindowContents];
}

- (void)hotKeyManagerDismissedInterface:(NNHotKeyManager *)manager;
{
    [self.appWindow orderOut:self];
    self.selectedIndex = NSNotFound;
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
    NSLog(@"Boom.");
}

- (void)hotKeyManagerClosedApplication:(NNHotKeyManager *)manager;
{
    NSLog(@"BOOM!");
}

@end
