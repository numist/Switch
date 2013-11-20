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
#import "NNEventManager.h"
#import "NNHUDCollectionView.h"
#import "NNWindow.h"
#import "NNWindowStore.h"
#import "NNWindowThumbnailView.h"


NSString const *NNCoreWindowControllerActivityNotification = @"NNCoreWindowControllerActivityNotification";
NSString const *NNCoreWindowControllerActiveKey = @"NNCoreWindowControllerActiveKey";


static NSTimeInterval kNNWindowDisplayDelay = 0.1;


@interface NNCoreWindowController () <NNWindowStoreDelegate, NNHUDCollectionViewDataSource, NNHUDCollectionViewDelegate>

#pragma mark State
@property (nonatomic, strong) NSDate *invocationTime;
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
@property (nonatomic, strong) NSMutableOrderedSet *windows;
@property (nonatomic, strong) NNWindowStore *store;

#pragma mark NNEventManager and state
@property (nonatomic, strong) NNEventManager *keyManager;
@property (nonatomic, assign) BOOL incrementing;
@property (nonatomic, assign) BOOL decrementing;

@end


@implementation NNCoreWindowController

- (id)initWithWindow:(NSWindow *)window
{
    Check(!window);
    if (!(self = [super initWithWindow:window])) { return nil; }
    
    self.windows = [NSMutableOrderedSet new];
    self.store = [[NNWindowStore alloc] initWithDelegate:self];
    
    Check(![self isWindowLoaded]);
    (void)self.window;
    [self setUpReactions];
    
    self.keyManager = [NNEventManager sharedManager];
    [[NSNotificationCenter defaultCenter] addWeakObserver:self selector:@selector(hotKeyManagerEventNotification:) name:NNEventManagerKeyNotificationName object:self.keyManager];
    [[NSNotificationCenter defaultCenter] addWeakObserver:self selector:@selector(hotKeyManagerMouseNotification:) name:NNEventManagerMouseNotificationName object:self.keyManager];
    
    return self;
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
#   pragma message "factor the contents of these out into methods where appropriate"
    // Interface is only visible when Switch is active, the window list has loaded, and the display timer has timed out.
    [[[[RACSignal
        combineLatest:@[RACObserve(self, windowListLoaded), RACObserve(self, displayTimer)]
        reduce:^(NSNumber *windowListLoaded, NSTimer *displayTimer) {
            return @(self.active && [windowListLoaded boolValue] && !displayTimer);
        }]
        distinctUntilChanged]
        skip:1]
        subscribeNext:^(NSNumber *shouldDisplayInterface) {
            if ([shouldDisplayInterface boolValue]) {
                [self.window setFrame:[NSScreen mainScreen].frame display:YES];
                [self.window orderFront:self];
                [self.store startUpdatingWindowContents];
                NNLog(@"Showed interface (%.3fs elapsed)", [[NSDate date] timeIntervalSinceDate:self.invocationTime]);
            } else {
                NNLog(@"Hiding interface (%.3fs elapsed)", [[NSDate date] timeIntervalSinceDate:self.invocationTime]);
                [self.window orderOut:self];
            }
        }];
    
    // Adjust the selected index by 1 if the first window's application is not already frontmost, but do this as late as possible.
    [[[[RACSignal
        combineLatest:@[RACObserve(self, pendingSwitch), RACObserve(self, displayTimer)]
        reduce:^(NSNumber *pendingSwitch, NSTimer *displayTimer){
            return @([pendingSwitch boolValue] || displayTimer == nil);
        }]
        distinctUntilChanged]
        skip:1]
        subscribeNext:^(NSNumber *adjustIndex) {
            if (!self.adjustedIndex && [adjustIndex boolValue]) {
                if (self.selectedIndex == 1 && [self.windows count] > 1 && ![((NNWindow *)[self.windows objectAtIndex:0]).application isFrontMostApplication]) {
                    NNLog(@"Adjusted index to select first window (%.3fs elapsed)", [[NSDate date] timeIntervalSinceDate:self.invocationTime]);
                    self.selectedIndex = 0;
                } else {
                    NNLog(@"Index does not need adjustment (%.3fs elapsed)", [[NSDate date] timeIntervalSinceDate:self.invocationTime]);
                }
                self.adjustedIndex = YES;
            }
        }];
    
    // Clean up all that crazy state when the activation state changes.
    [[[RACObserve(self, active)
        distinctUntilChanged]
        skip:1]
        subscribeNext:^(NSNumber *active) {
            if ([active boolValue]) {
                NNLog(@"Switch is active (%.3fs elapsed)", [[NSDate date] timeIntervalSinceDate:self.invocationTime]);
                Check(![self.windows count]);
                Check(!self.displayTimer);
             
                self.displayTimer = [NSTimer scheduledTimerWithTimeInterval:kNNWindowDisplayDelay target:self selector:@selector(displayTimerFired:) userInfo:nil repeats:NO];
                self.adjustedIndex = NO;
                self.windowListLoaded = NO;
                self.selectedIndex = 0;
             
                [self.store startUpdatingWindowList];
         } else {
                NNLog(@"Deactivating Switch (%.3fs elapsed)", [[NSDate date] timeIntervalSinceDate:self.invocationTime]);
                Check(!self.pendingSwitch);
             
                [self.store stopUpdatingWindowList];
                [self.store stopUpdatingWindowContents];
                [self.displayTimer invalidate];
                self.displayTimer = nil;
                self.pendingSwitch = NO;
                [self.collectionView deselectCell];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:(NSString *)NNCoreWindowControllerActivityNotification object:self userInfo:@{NNCoreWindowControllerActiveKey : active}];
        }];
    
    [[[RACSignal
        combineLatest:@[RACObserve(self, pendingSwitch), RACObserve(self, windowListLoaded)] reduce:^(NSNumber *pendingSwitch, NSNumber *windowListLoaded){
            return @([pendingSwitch boolValue] && [windowListLoaded boolValue]);
        }]
        distinctUntilChanged]
        subscribeNext:^(id x) {
            if ([x boolValue]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.pendingSwitch = NO;
                 
                    __block BOOL raiseSuccessful = YES;
                    NNWindow *selectedWindow = [self selectedWindow];
                    NNWindowThumbnailView *thumb = [self cellForWindow:selectedWindow];
                    [thumb setActive:NO];
                 
                    if (selectedWindow) {
                        // If sending events to Switch itself, we have to use the main thread!
                        dispatch_queue_t actionQueue = [selectedWindow.application isCurrentApplication] ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

                        dispatch_async(actionQueue, ^{
                            raiseSuccessful = [selectedWindow raise];
                         
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (raiseSuccessful) {
                                    if (!self.active) {
                                        NNLog(@"Switcher already inactive after successful -raise");
                                        DebugBreak();
                                    }
                                    self.active = NO;
                                }
                                [thumb setActive:YES];
                            });
                        });
                    } else {
                        NNLog(@"No windows to raise! (Selection index: %lu)", self.selectedIndex);
                        self.active = NO;
                    }
                });
            }
        }];
    
    [[RACObserve(self, selectedIndex)
        distinctUntilChanged]
        subscribeNext:^(id x) {
            NSUInteger index = [x unsignedIntegerValue];
            if (index == self.collectionView.selectedIndex) { return; }
         
            if ([self.windows count]) {
                if (index < [self.windows count]) {
                    [self.collectionView selectCellAtIndex:index];
                } else {
                    [self.collectionView deselectCell];
                }
            }
        }];
}

- (NNWindowThumbnailView *)cellForWindow:(NNWindow *)window;
{
    if (!window) {
        return nil;
    }
    
    // Cache collection view cells as associated objects on the window model objects.
    NNWindowThumbnailView *result = objc_getAssociatedObject(window, (__bridge const void *)[NNWindowThumbnailView class]);
    if (!result) {
        result = [[NNWindowThumbnailView alloc] initWithFrame:NSZeroRect window:window];
        if (!Check(result)) {
            return nil;
        }
        objc_setAssociatedObject(window, (__bridge const void *)[NNWindowThumbnailView class], result, OBJC_ASSOCIATION_RETAIN);
    }
    
    return result;
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
    if (!self.windowListLoaded) {
        NNLog(@"Window list loaded with %lu windows (%.3fs elapsed)", (unsigned long)self.windows.count, [[NSDate date] timeIntervalSinceDate:self.invocationTime]);
        self.windowListLoaded = YES;
    }
    
    if ([self.windows count]) {
        if (self.selectedIndex >= [self.windows count]) {
            self.selectedIndex = [self.windows count] - 1;
        }
        [self.collectionView selectCellAtIndex:self.selectedIndex];
    }
    
    [self.collectionView endUpdates];
}

#pragma mark - Notifications/Timers

- (void)displayTimerFired:(NSTimer *)timer;
{
    if (![timer isEqual:self.displayTimer]) {
        return;
    }
    
    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:self.invocationTime];
    NNLog(@"Display timer fired %.3fs %@ (%.3fs elapsed)", fabs(elapsed - kNNWindowDisplayDelay), (elapsed - kNNWindowDisplayDelay) > 0.0 ? @"late" : @"early", elapsed);
    
    self.displayTimer = nil;
}

- (void)hotKeyManagerEventNotification:(NSNotification *)notification;
{
    NNEventManagerEventType eventType = [notification.userInfo[NNEventManagerEventTypeKey] unsignedIntegerValue];
    
    switch (eventType) {
        case NNEventManagerEventTypeInvoke: {
            if (![NNAPIEnabledWorker isAPIEnabled]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:NNAXAPIDisabledNotification object:self];
                return;
            }
            
            // If the interface is not being shown, bring it up.
            if (!self.active) {
                self.invocationTime = [NSDate date];
                NNLog(@"Invoked (0s elapsed)");
                self.active = YES;
            }
            break;
        }

        case NNEventManagerEventTypeDismiss: {
            if (self.active) {
                NNLog(@"Dismissed (%.3fs elapsed)", [[NSDate date] timeIntervalSinceDate:self.invocationTime]);
                self.pendingSwitch = YES;
            }
            break;
        }

        case NNEventManagerEventTypeIncrement: {
            if (self.active) {
                NSUInteger newIndex = self.selectedIndex;
                
                if (newIndex >= NSNotFound) {
                    newIndex = 0;
                } else if (!self.incrementing || self.selectedIndex <= [self.windows count] - 1) {
                    newIndex += 1;
                }
                
                if (self.windowListLoaded) {
                    if ([self.windows count]) {
                        if (!self.incrementing) {
                            newIndex %= [self.windows count];
                        } else if (newIndex >= [self.windows count]) {
                            newIndex = [self.windows count] - 1;
                        }
                    } else {
                        newIndex = 0;
                    }
                }
                
                self.selectedIndex = newIndex;
                
                self.incrementing = YES;
            }

            break;
        }

        case NNEventManagerEventTypeEndIncrement: {
            self.incrementing = NO;
            break;
        }

        case NNEventManagerEventTypeDecrement: {
            if (self.active) {
                NSInteger newIndex = (NSInteger)self.selectedIndex;
                
                if (newIndex >= (NSInteger)NSNotFound) {
                    newIndex = (NSInteger)[self.windows count] - 1;
                } else if (!self.decrementing || newIndex != 0) {
                    newIndex -= 1;
                }
                
                if (self.windowListLoaded) {
                    if ([self.windows count]) {
                        if (!self.decrementing) {
                            while (newIndex < 0) { newIndex += [self.windows count]; }
                        } else if (newIndex < 0) {
                            newIndex = 0;
                        }
                    } else {
                        newIndex = 0;
                    }
                }
                
                self.selectedIndex = newIndex;
                
                self.decrementing = YES;
            }

            break;
        }

        case NNEventManagerEventTypeEndDecrement: {
            self.decrementing = NO;
            break;
        }

        case NNEventManagerEventTypeCloseWindow: {
            if (self.active) {
                __block BOOL success;
                NNWindow *selectedWindow = [self selectedWindow];
                NNWindowThumbnailView *thumb = [self cellForWindow:selectedWindow];
                
                /* Closing a window will change the window list ordering in unwanted ways if all of the following are true:
                 *     • The first window is being closed
                 *     • The first window's application has another window open in the list
                 *     • The first window and second window belong to different applications
                 * This can be worked around by first raising the second window.
                 * This may still result in odd behaviour if firstWindow.close fails, but applications not responding to window close events is incorrect behaviour (performance is a feature!) whereas window list shenanigans are (relatively) expected.
                 */
                NNWindow *nextWindow = nil;
                {
                    BOOL onlyChild = ([self.windows indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                        if (idx == self.selectedIndex) { return NO; }
                        return [((NNWindow *)obj).application isEqual:selectedWindow.application];
                    }] == NSNotFound);
                    BOOL differentApplications = [self.windows count] > 1 && ![[self.windows[0] application] isEqual:[self.windows[1] application]];

                    if (self.selectedIndex == 0 && !onlyChild && differentApplications) {
                        nextWindow = [self.windows objectAtIndex:1];
                    }
                }
                
                // If sending events to Switch itself, we have to use the main thread!
                dispatch_queue_t actionQueue = [selectedWindow.application isCurrentApplication] ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                
                [thumb setActive:NO];
                
                dispatch_async(actionQueue, ^{
                    [nextWindow raise];
                    success = [selectedWindow close];
                    
                    if (!success) {
                        // We *should* re-raise selectedWindow, but if it didn't succeed at -close it will also probably fail to -raise.
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [thumb setActive:YES];
                        });
                    }
                });
            }

            break;
        }
            
        case NNEventManagerEventTypeCancel: {
            if (Check(self.active)) {
                self.active = NO;
            }
            break;
        }

        default:
            break;
    }
}

- (void)hotKeyManagerMouseNotification:(NSNotification *)notification;
{
    if (self.active) {
        NSPoint windowLocation = [self.window convertScreenToBase:[notification.userInfo[@"mouseLocation"] pointValue]];
        if(NSPointInRect([self.collectionView convertPoint:windowLocation fromView:nil], [self.collectionView bounds])) {
            NSEvent *event = [NSEvent mouseEventWithType:NSMouseMoved location:windowLocation modifierFlags:NSAlternateKeyMask timestamp:(NSTimeInterval)0 windowNumber:self.window.windowNumber context:(NSGraphicsContext *)nil eventNumber:0 clickCount:0 pressure:1.0];
            [self.collectionView mouseMoved:event];
        }
    }
}

@end
