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

#import <ReactiveCocoa/EXTScope.h>

#import "SWEventTap.h"
#import "SWHUDCollectionView.h"
#import "SWWindowThumbnailView.h"


@interface SWCoreWindowController () <SWHUDCollectionViewDataSource, SWHUDCollectionViewDelegate>

@property (nonatomic, assign) BOOL interfaceLoaded;
@property (nonatomic, strong) SWHUDCollectionView *collectionView;

@end


@implementation SWCoreWindowController

#pragma mark Initialization

- (id)initWithWindow:(NSWindow *)window
{
    Check(!window);
    if (!(self = [super initWithWindow:window])) { return nil; }
    
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
    NSRect windowRect;
    {
        NSScreen *mainScreen = [NSScreen mainScreen];
        windowRect = mainScreen.frame;
    }
    
    NSWindow *switcherWindow = [[NSWindow alloc] initWithContentRect:windowRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    NSRect displayRect;
    {
        switcherWindow.movableByWindowBackground = NO;
        switcherWindow.hasShadow = NO;
        switcherWindow.opaque = NO;
        switcherWindow.backgroundColor = [NSColor clearColor];
        switcherWindow.level = NSPopUpMenuWindowLevel;
        
        displayRect = [switcherWindow convertRectFromScreen:windowRect];
    }
    self.window = switcherWindow;
    
    SWHUDCollectionView *collectionView = [[SWHUDCollectionView alloc] initWithFrame:displayRect];
    {
        collectionView.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable;
        collectionView.dataSource = self;
        collectionView.delegate = self;
    }
    self.collectionView = collectionView;
    self.window.contentView = self.collectionView;
    self.interfaceLoaded = YES;
}

#pragma mark SWCoreWindowController

- (void)setWindowGroups:(NSOrderedSet *)windowGroups;
{
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
    [self _thumbnailForWindowGroup:windowGroup].active = NO;
}

- (void)enableWindowGroup:(SWWindowGroup *)windowGroup;
{
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
    
    return [[SWWindowThumbnailView alloc] initWithFrame:NSZeroRect windowGroup:windowGroup];
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
