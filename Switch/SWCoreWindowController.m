//
//  SWCoreWindowController.m
//  Switch
//
//  Created by Scott Perry on 07/10/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWCoreWindowController.h"

#import "NSSet+SWChaining.h"
#import "SWEventTap.h"
#import "SWHUDCollectionView.h"
#import "SWWindowGroup.h"
#import "SWWindowThumbnailView.h"


@interface SWCoreWindowController () <SWHUDCollectionViewDataSource, SWHUDCollectionViewDelegate>

@property (nonatomic, assign, readwrite) BOOL interfaceLoaded;
@property (nonatomic, assign, readonly) CGRect screenFrame;
@property (nonatomic, strong, readwrite) SWHUDCollectionView *collectionView;
@property (nonatomic, strong, readonly) NSMutableDictionary *collectionCells;

@end


@implementation SWCoreWindowController

#pragma mark Initialization

- (id)initWithRect:(CGRect)frame;
{
    if (!(self = [super initWithWindow:nil])) { return nil; }
    
    _collectionCells = [NSMutableDictionary new];
    _screenFrame = frame;

    Check(![self isWindowLoaded]);
    (void)self.window;
    
    @weakify(self);
    [[SWEventTap sharedService] registerForEventsWithType:kCGEventMouseMoved object:self block:^(CGEventRef event) {
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            
            NSPoint windowLocation = [self.window convertScreenToBase:[NSEvent mouseLocation]];
            if(NSPointInRect([self.collectionView convertPoint:windowLocation fromView:nil], [self.collectionView bounds])) {
                NSEvent *mouseEvent = [NSEvent mouseEventWithType:NSMouseMoved location:windowLocation modifierFlags:NSAlternateKeyMask timestamp:(NSTimeInterval)0 windowNumber:self.window.windowNumber context:(NSGraphicsContext *)nil eventNumber:0 clickCount:0 pressure:1.0];
                [self.collectionView mouseMoved:mouseEvent];
            }
        });
    }];
    
    return self;
}

- (void)dealloc;
{
    [[SWEventTap sharedService] removeBlockForEventsWithType:kCGEventMouseMoved object:self];
}

#pragma mark - NSWindowController

- (BOOL)isWindowLoaded;
{
    return self.interfaceLoaded;
}

- (void)loadWindow;
{
    NSWindow *switcherWindow = [[NSWindow alloc] initWithContentRect:self.screenFrame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    switcherWindow.movableByWindowBackground = NO;
    switcherWindow.hasShadow = NO;
    switcherWindow.opaque = NO;
    switcherWindow.backgroundColor = [NSColor clearColor];
    switcherWindow.level = NSPopUpMenuWindowLevel;
    self.window = switcherWindow;
    
    NSRect displayRect = [switcherWindow convertRectFromScreen:self.screenFrame];

    SWHUDCollectionView *collectionView = [[SWHUDCollectionView alloc] initWithFrame:displayRect];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    self.collectionView = collectionView;
    
    self.window.contentView = self.collectionView;
    self.interfaceLoaded = YES;
}

#pragma mark SWCoreWindowController

- (void)setWindowGroups:(NSOrderedSet *)windowGroups;
{
    // Throw out any cells that aren't needed anymore.
    NSSet *removedWindowGroups = [[NSSet setWithArray:self.collectionCells.allKeys] sw_minusSet:windowGroups.set];
    [self.collectionCells removeObjectsForKeys:removedWindowGroups.allObjects];

    _windowGroups = windowGroups;
    [self.collectionView reloadData];
}

- (void)selectWindowGroup:(SWWindowGroup *)windowGroup;
{
    NSUInteger index = [self.windowGroups indexOfObject:windowGroup];

    if (index < self.windowGroups.count) {
        [self.collectionView selectCellAtIndex:index];
    } else {
        [self.collectionView deselectCell];
    }
}

- (void)disableWindowGroup:(SWWindowGroup *)windowGroup;
{
    if (![self.windowGroups containsObject:windowGroup]) { return; }
    
    [self _thumbnailForWindowGroup:windowGroup].active = NO;
}

- (void)enableWindowGroup:(SWWindowGroup *)windowGroup;
{
    if (![self.windowGroups containsObject:windowGroup]) { return; }
    
    [self _thumbnailForWindowGroup:windowGroup].active = YES;
}

#pragma mark SWHUDCollectionViewDataSource

- (CGFloat)HUDCollectionViewMaximumCellSize:(SWHUDCollectionView *)view;
{
    return kNNMaxWindowThumbnailSize;
}

- (NSUInteger)HUDCollectionViewNumberOfCells:(SWHUDCollectionView *)view;
{
    return self.windowGroups.count;
}

- (NSView *)HUDCollectionView:(SWHUDCollectionView *)view viewForCellAtIndex:(NSUInteger)index;
{
    BailUnless([view isEqual:self.collectionView], [[NSView alloc] initWithFrame:NSZeroRect]);
    
    // Boundary method, index may not be in-bounds.
    SWWindowGroup *windowGroup = index < self.windowGroups.count ? self.windowGroups[index] : nil;
    BailUnless(windowGroup, [[NSView alloc] initWithFrame:NSZeroRect]);

    if (!self.collectionCells[windowGroup]) {
        self.collectionCells[windowGroup] = [[SWWindowThumbnailView alloc] initWithFrame:NSZeroRect windowGroup:windowGroup];
    }

    return self.collectionCells[windowGroup];
}

#pragma mark SWHUDCollectionViewDelegate

- (void)HUDCollectionView:(SWHUDCollectionView *)view didSelectCellAtIndex:(NSUInteger)index;
{
    Assert(index < self.windowGroups.count);
    id<SWCoreWindowControllerDelegate> delegate = self.delegate;
    [delegate coreWindowController:self didSelectWindowGroup:self.windowGroups[index]];
}

- (void)HUDCollectionView:(SWHUDCollectionView *)view activateCellAtIndex:(NSUInteger)index;
{
    Assert(index < self.windowGroups.count);
    id<SWCoreWindowControllerDelegate> delegate = self.delegate;
    [delegate coreWindowController:self didActivateWindowGroup:self.windowGroups[index]];
}

#pragma mark - Private

- (SWWindowThumbnailView *)_thumbnailForWindowGroup:(SWWindowGroup *)windowGroup;
{
    NSUInteger index = [self.windowGroups indexOfObject:windowGroup];

    if (index < self.windowGroups.count) {
        id thumb = [self.collectionView cellForIndex:index];

        if (!Check([thumb isKindOfClass:[SWWindowThumbnailView class]])) {
            return nil;
        } else {
            return thumb;
        }
    }

    BailUnless(NO, nil);
}

@end
