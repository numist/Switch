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
#import <ReactiveCocoa/ReactiveCocoa.h>

#import "SWEventManager.h"
#import "SWHUDCollectionView.h"
#import "SWWindowThumbnailView.h"
#import "SWAccessibilityService.h"
#import "SWApplication.h"
#import "SWSelector.h"
#import "SWWindowGroup.h"
#import "SWWindowListService.h"


NSString const *SWCoreWindowControllerActivityNotification = @"SWCoreWindowControllerActivityNotification";
NSString const *SWCoreWindowControllerActiveKey = @"SWCoreWindowControllerActiveKey";


static NSTimeInterval kNNWindowDisplayDelay = 0.15;


@interface SWCoreWindowController () <SWWindowListSubscriber, SWEventManagerSubscriber, SWHUDCollectionViewDataSource, SWHUDCollectionViewDelegate>

#pragma mark Core state
@property (nonatomic, assign) BOOL active;
@property (nonatomic, strong) NSTimer *displayTimer;
@property (nonatomic, assign) BOOL interfaceLoaded;
@property (nonatomic, assign) BOOL pendingSwitch;

@property (nonatomic, assign) BOOL windowListLoaded;
@property (nonatomic, strong) NSOrderedSet *windowGroups;

#pragma mark Selector state
@property (nonatomic, strong) SWSelector *selector;
@property (nonatomic, assign) BOOL adjustedIndex;
@property (nonatomic, assign) BOOL incrementing;
@property (nonatomic, assign) BOOL decrementing;

#pragma mark Logging state
@property (nonatomic, strong) NSDate *invocationTime;

#pragma mark UI
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
    
    [self _setUpReactions];
    
    [[NNServiceManager sharedManager] addSubscriber:self forService:[SWEventManager class]];
    [[NNServiceManager sharedManager] addObserver:self forService:[SWAccessibilityService class]];
    
    return self;
}

#pragma mark NSWindowController

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
    
    SWHUDCollectionView *collectionView = [[SWHUDCollectionView alloc] initWithFrame:NSMakeRect(displayRect.size.width / 2.0, displayRect.size.height / 2.0, 0.0, 0.0)];
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

#pragma mark SWWindowListSubscriber

- (oneway void)windowListService:(SWWindowListService *)service updatedList:(NSOrderedSet *)windows;
{
    self.windowGroups = windows;
    self.selector = [self.selector updateWithWindowGroups:windows];
    [self.collectionView reloadData];
    
    if (self.windowGroups.count) {
        [self.collectionView selectCellAtIndex:self.selector.selectedUIndex];
    } else {
        [self.collectionView deselectCell];
    }
    
    if (!self.windowListLoaded) {
        SWLog(@"Window list loaded with %lu windows (%.3fs elapsed)", (unsigned long)self.windowGroups.count, [[NSDate date] timeIntervalSinceDate:self.invocationTime]);
        
        [self _layoutCollectionView];
        
        self.windowListLoaded = YES;
    } else {
        SWLog(@"Window list updated with %lu windows (%.3fs elapsed)", (unsigned long)self.windowGroups.count, [[NSDate date] timeIntervalSinceDate:self.invocationTime]);
    }
}

#pragma mark SWEventManagerSubscriber

- (oneway void)eventManager:(SWEventManager *)manager didProcessKeyForEventType:(SWEventManagerEventType)eventType;
{
    switch (eventType) {
        case SWEventManagerEventTypeInvoke: {
            [[SWAccessibilityService sharedService] checkAPI];
            
            // If the interface is not being shown, bring it up.
            if (!self.active) {
                self.invocationTime = [NSDate date];
                SWLog(@"Invoked (0s elapsed)");
                self.active = YES;
            }
            break;
        }
            
        case SWEventManagerEventTypeDismiss: {
            if (self.active) {
                SWLog(@"Dismissed (%.3fs elapsed)", [[NSDate date] timeIntervalSinceDate:self.invocationTime]);
                self.pendingSwitch = YES;
            }
            break;
        }
            
        case SWEventManagerEventTypeIncrement: {
            if (self.active) {
                if (self.incrementing) {
                    self.selector = [self.selector incrementWithoutWrapping];
                } else {
                    self.selector = [self.selector increment];
                }
                self.incrementing = YES;
            }
            
            break;
        }
            
        case SWEventManagerEventTypeEndIncrement: {
            self.incrementing = NO;
            break;
        }
            
        case SWEventManagerEventTypeDecrement: {
            if (self.active) {
                if (self.decrementing) {
                    self.selector = [self.selector decrementWithoutWrapping];
                } else {
                    self.selector = [self.selector decrement];
                }
                self.decrementing = YES;
            }
            
            break;
        }
            
        case SWEventManagerEventTypeEndDecrement: {
            self.decrementing = NO;
            break;
        }
            
        case SWEventManagerEventTypeCloseWindow: {
            if (self.active) {
                SWWindowGroup *selectedWindowGroup = self.selector.selectedWindowGroup;
                if (!selectedWindowGroup) {
                    break;
                }
                
                SWWindowThumbnailView *thumb = (SWWindowThumbnailView *)[self.collectionView cellForIndex:self.selector.selectedUIndex];
                Check(!thumb || [thumb isKindOfClass:[SWWindowThumbnailView class]]);
                
                Check(self.windowListLoaded);
                
                /** Closing a window will change the window list ordering in unwanted ways if all of the following are true:
                 *     • The first window is being closed
                 *     • The first window's application has another window open in the list
                 *     • The first window and second window belong to different applications
                 * This can be worked around by first raising the second window.
                 * This may still result in odd behaviour if firstWindow.close fails, but applications not responding to window close events is incorrect behaviour (performance is a feature!) whereas window list shenanigans are (relatively) expected.
                 */
                SWWindowGroup *nextWindow = nil;
                {
                    BOOL onlyChild = ([self.windowGroups indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop){
                        if (idx == self.selector.selectedUIndex) { return NO; }
                        return [((SWWindowGroup *)obj).application isEqual:selectedWindowGroup.application];
                    }] == NSNotFound);
                    
                    BOOL differentApplications = [self.windowGroups count] > 1 && ![[self.windowGroups[0] application] isEqual:[self.windowGroups[1] application]];
                    
                    if (self.selector.selectedIndex == 0 && !onlyChild && differentApplications) {
                        nextWindow = [self.windowGroups objectAtIndex:1];
                    }
                }
                
                // If sending events to Switch itself, we have to use the main thread!
                dispatch_queue_t actionQueue = [selectedWindowGroup.application isCurrentApplication] ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                
                [thumb setActive:NO];
                
#               pragma clang diagnostic push
#               pragma clang diagnostic ignored "-Wshadow"
                __weak __typeof(thumb) weakThumb = thumb;
                dispatch_async(actionQueue, ^{
                    [[SWAccessibilityService sharedService] raiseWindow:nextWindow.mainWindow completion:nil];
                    [[SWAccessibilityService sharedService] closeWindow:selectedWindowGroup.mainWindow completion:^(NSError *error) {
                        if (error) {
                            // We *should* re-raise selectedWindow, but if it didn't succeed at -close it will also probably fail to -raise.
                            dispatch_async(dispatch_get_main_queue(), ^{
                                __typeof(thumb) thumb = weakThumb;
                                [thumb setActive:YES];
                            });
                        }
                    }];
                });
#               pragma clang diagnostic pop
            }
            
            break;
        }
            
        case SWEventManagerEventTypeCancel: {
            if (Check(self.active)) {
                self.active = NO;
            }
            break;
        }
            
        default:
            break;
    }
}

- (oneway void)eventManagerDidDetectMouseMove:(SWEventManager *)manager;
{
    if (self.active) {
        NSPoint windowLocation = [self.window convertScreenToBase:[NSEvent mouseLocation]];
        if(NSPointInRect([self.collectionView convertPoint:windowLocation fromView:nil], [self.collectionView bounds])) {
            NSEvent *event = [NSEvent mouseEventWithType:NSMouseMoved location:windowLocation modifierFlags:NSAlternateKeyMask timestamp:(NSTimeInterval)0 windowNumber:self.window.windowNumber context:(NSGraphicsContext *)nil eventNumber:0 clickCount:0 pressure:1.0];
            [self.collectionView mouseMoved:event];
        }
    }
}

#pragma mark SWHUDCollectionViewDataSource

- (NSUInteger)HUDViewNumberOfCells:(SWHUDCollectionView *)view;
{
    return [self.windowGroups count];
}

- (NSView *)HUDView:(SWHUDCollectionView *)view viewForCellAtIndex:(NSUInteger)index;
{
    SWWindowGroup *windowGroup = [self.windowGroups objectAtIndex:index];
    BailUnless(windowGroup, [[NSView alloc] initWithFrame:NSZeroRect]);
    
    return [[SWWindowThumbnailView alloc] initWithFrame:NSZeroRect windowGroup:windowGroup];
}

#pragma mark SWHUDCollectionViewDelegate

- (void)HUDView:(SWHUDCollectionView *)view willSelectCellAtIndex:(NSUInteger)index;
{
    self.selector = [self.selector selectIndex:index];
}

- (void)HUDView:(SWHUDCollectionView *)view activateCellAtIndex:(NSUInteger)index;
{
    BailUnless(self.active,);
    
    if (!Check(index == self.selector.selectedUIndex)) {
        self.selector = [self.selector selectIndex:index];
    }
    
    self.pendingSwitch = YES;
}

#pragma  mark Internal

- (void)_activate;
{
    SWLog(@"Switch is active (%.3fs elapsed)", [[NSDate date] timeIntervalSinceDate:self.invocationTime]);
    
    if (!Check(!self.displayTimer)) {
        [self.displayTimer invalidate];
    }
    
    self.displayTimer = [NSTimer scheduledTimerWithTimeInterval:kNNWindowDisplayDelay target:self selector:@selector(_displayTimerFired:) userInfo:nil repeats:NO];

    if (Check(![self.windowGroups count])) {
        self.adjustedIndex = NO;
        self.windowListLoaded = NO;
        self.selector = [SWSelector new];
    }
    
    [[NNServiceManager sharedManager] addSubscriber:self forService:[SWWindowListService self]];
}

- (void)_deactivate;
{
    SWLog(@"Deactivating Switch (%.3fs elapsed)", [[NSDate date] timeIntervalSinceDate:self.invocationTime]);

    [[NNServiceManager sharedManager] removeSubscriber:self forService:[SWWindowListService self]];
    
    [self.displayTimer invalidate];
    self.displayTimer = nil;
    self.pendingSwitch = NO;
    
    // To save on CPU, we dispose of all views, whch will disable their content updating mechanisms.
    self.windowGroups = nil;
    [self.collectionView reloadData];
    [self.collectionView deselectCell];
}

- (void)_displayInterface;
{
    [self.window orderFront:self];
    SWLog(@"Showed interface (%.3fs elapsed)", [[NSDate date] timeIntervalSinceDate:self.invocationTime]);
}

- (void)_hideInterface;
{
    SWLog(@"Hiding interface (%.3fs elapsed)", [[NSDate date] timeIntervalSinceDate:self.invocationTime]);
    [self.window orderOut:self];
}

- (void)_adjustIndex;
{
    BailUnless(!self.adjustedIndex,);
    
    if (self.selector.selectedIndex == 1 && [self.windowGroups count] > 1 && !((SWWindowGroup *)[self.windowGroups objectAtIndex:0]).mainWindow.application.runningApplication.active) {
        SWLog(@"Adjusted index to select first window (%.3fs elapsed)", [[NSDate date] timeIntervalSinceDate:self.invocationTime]);
        self.selector = [[SWSelector new] updateWithWindowGroups:self.windowGroups];
    } else {
        SWLog(@"Index does not need adjustment (%.3fs elapsed)", [[NSDate date] timeIntervalSinceDate:self.invocationTime]);
    }
    self.adjustedIndex = YES;
}

- (void)_raiseSelectedWindow;
{

    BailUnless(self.pendingSwitch && self.windowListLoaded,);
    
    self.pendingSwitch = NO;
    
    SWWindowGroup *selectedWindow = self.selector.selectedWindowGroup;
    if (!selectedWindow) {
        SWLog(@"No windows to raise! (Selection index: %lu)", self.selector.selectedUIndex);
        self.active = NO;
        return;
    }
    
    SWWindowThumbnailView *thumb = (SWWindowThumbnailView *)[self.collectionView cellForIndex:self.selector.selectedUIndex];
    Check(!thumb || [thumb isKindOfClass:[SWWindowThumbnailView class]]);
    
    thumb.active = NO;
    
#   pragma clang diagnostic push
#   pragma clang diagnostic ignored "-Wshadow"
    __weak __typeof(thumb) weakThumb = thumb;
    [[SWAccessibilityService sharedService] raiseWindow:selectedWindow.mainWindow completion:^(NSError *error) {
        SWWindowThumbnailView *thumb = weakThumb;
        
        if (!error) {
            if (!self.active) {
                SWLog(@"Switcher already inactive after successful -raise");
            }
            self.active = NO;
        }
        
        thumb.active = YES;
    }];
#   pragma clang diagnostic pop
}

- (void)_setUpReactions;
{
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
             [self _displayInterface];
         } else {
             [self _hideInterface];
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
             [self _adjustIndex];
         }
     }];
    
    // Clean up all that crazy state when the activation state changes.
    [[[RACObserve(self, active)
       distinctUntilChanged]
      skip:1]
     subscribeNext:^(NSNumber *active) {
         if ([active boolValue]) {
             [self _activate];
         } else {
             [self _deactivate];
         }
         
         [[NSNotificationCenter defaultCenter] postNotificationName:(NSString *)SWCoreWindowControllerActivityNotification object:self userInfo:@{SWCoreWindowControllerActiveKey : active}];
     }];
    
    [[[RACSignal
       combineLatest:@[RACObserve(self, pendingSwitch), RACObserve(self, windowListLoaded)] reduce:^(NSNumber *pendingSwitch, NSNumber *windowListLoaded){
           return @([pendingSwitch boolValue] && [windowListLoaded boolValue]);
       }]
      distinctUntilChanged]
     subscribeNext:^(id x) {
         if ([x boolValue]) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self _raiseSelectedWindow];
             });
         }
     }];
    
    [[RACObserve(self, selector.selectedIndex)
      distinctUntilChanged]
     subscribeNext:^(id x) {
         if (!self.windowGroups.count) { return; }
         
         NSInteger index = [x integerValue];
         NSUInteger uindex = (NSUInteger)index;
         
         if (uindex == self.collectionView.selectedIndex) { return; }
         
         if (index >= 0 && uindex < [self.windowGroups count]) {
             [self.collectionView selectCellAtIndex:uindex];
         } else {
             [self.collectionView deselectCell];
         }
     }];
}

- (void)_layoutCollectionView;
{
    [self.window setFrame:[NSScreen mainScreen].frame display:YES];
    
    NSRect windowRect = [NSScreen mainScreen].frame;
    NSRect displayRect = [self.window convertRectFromScreen:windowRect];
    
    self.collectionView.maxWidth = displayRect.size.width - (kNNScreenToWindowInset * 2.0);
    
    NSRect collectionRect = self.collectionView.frame;
    collectionRect.origin.x = (displayRect.size.width - collectionRect.size.width) / 2.0;
    collectionRect.origin.y = (displayRect.size.height - collectionRect.size.height) / 2.0;
    self.collectionView.frame = collectionRect;
    
    [self.collectionView reloadData];
}

- (void)_displayTimerFired:(NSTimer *)timer;
{
    if (![timer isEqual:self.displayTimer]) {
        return;
    }
    
    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:self.invocationTime];
    SWLog(@"Display timer fired %.3fs %@ (%.3fs elapsed)", fabs(elapsed - kNNWindowDisplayDelay), (elapsed - kNNWindowDisplayDelay) > 0.0 ? @"late" : @"early", elapsed);
    
    self.displayTimer = nil;
}

@end
