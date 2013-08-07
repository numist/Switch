//
//  NNCoreWindowController.m
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

#import "NNCoreWindowController.h"

#import <ReactiveCocoa/EXTScope.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

#import "NNAPIEnabledWorker.h"
#import "NNApplication.h"
#import "NNHotKey.h"
#import "NNHotKeyManager.h"
#import "NNHUDCollectionView.h"
#import "NNWindow.h"
#import "NNWindowStore.h"
#import "NNWindowThumbnailView.h"


static NSTimeInterval kNNWindowDisplayDelay = 0.15;


@interface NNCoreWindowController () <NNWindowStoreDelegate, NNHUDCollectionViewDataSource, NNHUDCollectionViewDelegate>

#pragma mark State
@property (nonatomic, assign) BOOL active;
@property (nonatomic, assign) BOOL windowListLoaded;
@property (nonatomic, strong) NSTimer *displayTimer;
@property (nonatomic, assign) BOOL pendingSwitch;
@property (nonatomic, assign) NSUInteger selectedIndex;
@property (nonatomic, assign) BOOL adjustedIndex;
@property (nonatomic, assign) BOOL interfaceLoaded;

#pragma mark UI
@property (nonatomic, strong) NNHUDCollectionView *collectionView;

#pragma mark NNWindowStore and state
@property (nonatomic, strong) NSMutableArray *windows;
@property (nonatomic, strong) NNWindowStore *store;

#pragma mark NNHotKeyManager and state
@property (nonatomic, strong) NNHotKeyManager *keyManager;
@property (nonatomic, assign) BOOL incrementing;
@property (nonatomic, assign) BOOL decrementing;

@end


@implementation NNCoreWindowController

- (id)initWithWindow:(NSWindow *)window
{
    // Don't pretend—this initializer wouldn't know what to do with a window parameter.
    Check(!window);
    
    self = [super initWithWindow:window];
    if (!self) { return nil; }
    
    self.windows = [NSMutableArray new];
    self.store = [[NNWindowStore alloc] initWithDelegate:self];
    
    self.keyManager = [NNHotKeyManager sharedManager];
    [self.keyManager registerHotKey:[[NNHotKey alloc] initWithKeycode:48 modifiers:NNHotKeyModifierOption] forEvent:NNHotKeyManagerEventTypeInvoke];
    [self.keyManager registerHotKey:[[NNHotKey alloc] initWithKeycode:48 modifiers:(NNHotKeyModifierOption | NNHotKeyModifierShift)] forEvent:NNHotKeyManagerEventTypeDecrement];
    [self.keyManager registerHotKey:[[NNHotKey alloc] initWithKeycode:13 modifiers:NNHotKeyModifierOption] forEvent:NNHotKeyManagerEventTypeCloseWindow];
    
    Check(![self isWindowLoaded]);
    (void)self.window;
    [self setUpReactions];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:NSApplicationWillResignActiveNotification object:[NSApplication sharedApplication]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hotKeyManagerEventNotification:) name:NNHotKeyManagerNotificationName object:self.keyManager];
    
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationWillResignActiveNotification object:[NSApplication sharedApplication]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NNHotKeyManagerNotificationName object:self.keyManager];
}

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
        switcherWindow.acceptsMouseMovedEvents = YES;
        
        displayRect = [switcherWindow convertRectFromScreen:windowRect];
    }
    self.window = switcherWindow;
    
    NNHUDCollectionView *collectionView = [[NNHUDCollectionView alloc] initWithFrame:NSMakeRect(displayRect.size.width / 2.0, displayRect.size.height / 2.0, 0.0, 0.0)];
    {
        collectionView.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin;
        collectionView.maxWidth = displayRect.size.width - (kNNScreenToWindowInset * 2.0);
        collectionView.maxCellSize = kNNMaxWindowThumbnailSize;
        collectionView.dataSource = self;
        collectionView.delegate = self;
    }
    self.collectionView = collectionView;
    [self.window.contentView addSubview:self.collectionView];
    self.interfaceLoaded = YES;
}

#pragma  mark NNCoreWindowController Internal

- (NNWindow *)selectedWindow;
{
    return self.selectedIndex < [self.windows count] ? [self.windows objectAtIndex:self.selectedIndex] : nil;
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
             // TODO(numist): is there a better way to catch mouse moved events than this? Because ugh.
             [[NSRunningApplication currentApplication] activateWithOptions:NSApplicationActivateIgnoringOtherApps];
             [self.window setFrame:[NSScreen mainScreen].frame display:YES];
             [self.window orderFront:self];
             [self.store startUpdatingWindowContents];
         } else {
             [self.window orderOut:self];
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
                 NNWindowThumbnailView *thumb = [self cellForWindow:selectedWindow];
                 [thumb setActive:NO];
                 
                 dispatch_async(dispatch_get_global_queue(0, 0), ^{
                     if (selectedWindow) {
                         raiseSuccessful = [selectedWindow raise];
                     } else {
                         Check(self.selectedIndex == 0);
                         Log(@"No windows to raise! (Selection index: %lu)", self.selectedIndex);
                     }
                     
                     dispatch_async(dispatch_get_main_queue(), ^{
                         // If the raise happens before the display timer has expired, this code path is responsible for deactivation because the application never became active, so the terminating code in applicationWillResignActive: will not get called.
                         if (raiseSuccessful && self.displayTimer) {
                             Check(self.active);
                             self.active = NO;
                         }
                         [thumb setActive:YES];
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
        result = [[NNWindowThumbnailView alloc] initWithFrame:NSZeroRect window:window];
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

- (void)applicationWillResignActive:(__attribute__((unused)) NSNotification *)notification;
{
    self.active = NO;
}

#pragma mark NNHUDCollectionViewDataSource

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
    [self.collectionView beginUpdates];
}

- (void)store:(NNWindowStore *)store didChangeWindow:(NNWindow *)window atIndex:(NSUInteger)index forChangeType:(NNWindowStoreChangeType)type newIndex:(NSUInteger)newIndex;
{
    switch (type) {
        case NNWindowStoreChangeInsert:
            [self.windows insertObject:window atIndex:newIndex];
            [self cellForWindow:window].alphaValue = 1.0;
            [self.collectionView insertCellsAtIndexes:@[@(newIndex)] withAnimation:self.windowListLoaded];
            break;
            
        case NNWindowStoreChangeMove:
            [self.windows removeObjectAtIndex:index];
            [self.windows insertObject:window atIndex:newIndex];
            [self.collectionView moveCellAtIndex:index toIndex:newIndex];
            break;
            
        case NNWindowStoreChangeDelete:
            [self.windows removeObjectAtIndex:index];
            
            // Update the selected index so it doesn't go out of bounds (default value is zero).
            if (index == self.selectedIndex && index >= [self.windows count]) {
                self.selectedIndex = [self.windows count] ? [self.windows count] - 1 : 0;
                [self.collectionView selectCellAtIndex:self.selectedIndex];
            }
            [self.collectionView deleteCellsAtIndexes:@[@(index)] withAnimation:self.active];
            break;
            
        case NNWindowStoreChangeWindowContent: {
            [self.collectionView[index] setThumbnail:window.image];
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
    
    [self.collectionView endUpdates];
}

#pragma mark NNHotKeyManagerDelegate

- (void)hotKeyManagerEventNotification:(NSNotification *)notification;
{
    NNHotKeyManagerEventType eventType = [notification.userInfo[NNHotKeyManagerEventTypeKey] unsignedIntegerValue];
    
    switch (eventType) {
        case NNHotKeyManagerEventTypeInvoke: {
            if (![NNAPIEnabledWorker isAPIEnabled]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:NNAXAPIDisabledNotification object:self];
                return;
            }
            
            // If the interface is not being shown, bring it up.
            if (!self.active) {
                self.active = YES;
            }
            break;
        }

        case NNHotKeyManagerEventTypeDismiss: {
            if (self.active) {
                self.pendingSwitch = YES;
            }
            break;
        }

        case NNHotKeyManagerEventTypeIncrement: {
            if (self.active) {
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

            break;
        }

        case NNHotKeyManagerEventTypeEndIncrement: {
            self.incrementing = NO;
            break;
        }

        case NNHotKeyManagerEventTypeDecrement: {
            if (self.active) {
                NSInteger newIndex = (NSInteger)self.selectedIndex;
                
                if (newIndex >= (NSInteger)NSNotFound) {
                    newIndex = (NSInteger)[self.windows count] - 1;
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

            break;
        }

        case NNHotKeyManagerEventTypeEndDecrement: {
            self.decrementing = NO;
            break;
        }

        case NNHotKeyManagerEventTypeCloseWindow: {
            if (self.active) {
                __block BOOL success;
                NNWindow *selectedWindow = [self selectedWindow];
                NNWindowThumbnailView *thumb = [self cellForWindow:selectedWindow];
                NNWindow *nextWindow = nil;
                
                // If the first and second window belong to different applications, and the first application has another visible window, closing the first window will activate the first application's next window, changing the window order. This is fixed by tracking the next window (if it belongs to a different application) and raising it. This only matters when closing the frontmost window.
                if (self.selectedIndex == 0 && (self.selectedIndex + 1) < [self.windows count] && ![nextWindow.application isEqual:selectedWindow]) {
                    nextWindow = [self.windows objectAtIndex:(self.selectedIndex + 1)];
                }
                
                [thumb setActive:NO];
                
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    if ((success = [selectedWindow close])) {
                        if ([nextWindow raise]) {
                            // TODO(numist): is there a better way to catch mouse moved events than this? Because ugh.
                            [[NSRunningApplication currentApplication] activateWithOptions:NSApplicationActivateIgnoringOtherApps];
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [thumb setActive:YES];
                    });
                });
            }

            break;
        }

        default:
            NotTested();
            break;
    }
}

@end
