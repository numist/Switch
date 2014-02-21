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

#import "SWAccessibilityService.h"
#import "SWApplication.h"
#import "SWEventTap.h"
#import "SWHUDCollectionView.h"
#import "SWPreferencesService.h"
#import "SWSelector.h"
#import "SWWindowGroup.h"
#import "SWWindowListService.h"
#import "SWWindowThumbnailView.h"


NSString const *SWCoreWindowControllerActivityNotification = @"SWCoreWindowControllerActivityNotification";
NSString const *SWCoreWindowControllerActiveKey = @"SWCoreWindowControllerActiveKey";


static NSTimeInterval kWindowDisplayDelay = 0.15;


@interface SWCoreWindowController () <SWWindowListSubscriber, SWHUDCollectionViewDataSource, SWHUDCollectionViewDelegate>

#pragma mark NSWindow state
@property (nonatomic, assign) BOOL interfaceLoaded;

#pragma mark Core state
@property (nonatomic, assign) BOOL invoked;
@property (nonatomic, strong) NSTimer *displayTimer;
@property (nonatomic, assign) BOOL pendingSwitch;

@property (nonatomic, assign) BOOL windowListLoaded;
@property (nonatomic, strong) NSOrderedSet *windowGroups;

#pragma mark Dependant state
@property (nonatomic, assign) BOOL active;
@property (nonatomic, assign) BOOL interfaceVisible;

#pragma mark Selector state
@property (nonatomic, strong) SWSelector *selector;
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _setUpReactions];
        [self _registerEvents];
    });
    
    [[NNServiceManager sharedManager] addObserver:self forService:[SWAccessibilityService class]];
    
    return self;
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

#pragma mark SWCoreWindowController

- (void)setActive:(BOOL)active;
{
    if (active == self.active) { return; }
    self->_active = active;
    
    if (active) {
        // This shouldn't ever happen because of pendingSwitch.
        Check(self.invoked);

        self.invocationTime = [NSDate date];
        SWLog(@"Switch is active (%.3fs elapsed)", [[NSDate date] timeIntervalSinceDate:self.invocationTime]);

        if (!Check(!self.displayTimer)) {
            [self.displayTimer invalidate];
        }
        self.displayTimer = [NSTimer scheduledTimerWithTimeInterval:kWindowDisplayDelay target:self selector:@selector(_displayTimerFired:) userInfo:nil repeats:NO];
        
        Check(!self.selector);
        self.selector = [SWSelector new];
        
        Check(!self.windowGroups.count);
        Check(!self.windowListLoaded);
        [[NNServiceManager sharedManager] addSubscriber:self forService:[SWWindowListService self]];
        // Update with the service's current set of windows, in case it's already running.
        [self _updateWindowGroups:[SWWindowListService sharedService].windows];
    } else {
        [[NNServiceManager sharedManager] removeSubscriber:self forService:[SWWindowListService self]];
        [self _updateWindowGroups:nil];
        Check(!self.windowGroups.count);
        Check(!self.windowListLoaded);
        
        if (self.displayTimer) {
            [self.displayTimer invalidate];
            self.displayTimer = nil;
        }
        
        self.selector = nil;
    }
}

- (void)setInterfaceVisible:(BOOL)interfaceVisible;
{
    if (interfaceVisible == self.interfaceVisible) { return; }
    self->_interfaceVisible = interfaceVisible;
    
    if (interfaceVisible) {
        [self _displayInterface];
    } else {
        [self _hideInterface];
    }
}

- (void)setInvoked:(BOOL)invoked;
{
    if (invoked == self.invoked) { return; }
    self->_invoked = invoked;
    
    [SWEventTap sharedService].suppressKeyEvents = invoked;
}

#pragma mark - SWWindowListSubscriber

- (oneway void)windowListService:(SWWindowListService *)service updatedList:(NSOrderedSet *)windows;
{
    [self _updateWindowGroups:windows];
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
    if (!Check(index == self.selector.selectedUIndex)) {
        self.selector = [self.selector selectIndex:index];
    }
    
    self.pendingSwitch = YES;
    // Clicking on an item cancels the keyboard invocation.
    self.invoked = NO;
}

#pragma  mark - Internal

- (void)_updateWindowGroups:(NSOrderedSet *)windowGroups;
{
    // Idempotent, at least as far as setting nil is concerned (equal sets may have different addresses).
    if (windowGroups == self.windowGroups) { return; }
    
    // A nil update means clean up, we're shutting down until the next invocation.
    if (!windowGroups) {
        self.windowGroups = nil;
        self.windowListLoaded = NO;
        // To save on CPU, dispose of all views, which will disable their content updating mechanisms.
        [self.collectionView reloadData];
        [self.collectionView deselectCell];
        return;
    }
    
    self.windowGroups = windowGroups;
    [self.collectionView reloadData];
    
    self.selector = [self.selector updateWithWindowGroups:windowGroups];
    
    if (!self.windowGroups.count) {
        [self.collectionView deselectCell];
    }
    
    if (!self.windowListLoaded) {
        SWLog(@"Window list loaded with %lu windows (%.3fs elapsed)", (unsigned long)self.windowGroups.count, [[NSDate date] timeIntervalSinceDate:self.invocationTime]);
        
        [self _layoutCollectionView];
        
        if (self.selector.selectedIndex == 1 && [self.windowGroups count] > 1 && !((SWWindowGroup *)[self.windowGroups objectAtIndex:0]).mainWindow.application.runningApplication.active) {
            SWLog(@"Adjusted index to select first window (%.3fs elapsed)", [[NSDate date] timeIntervalSinceDate:self.invocationTime]);
            self.selector = [[SWSelector new] updateWithWindowGroups:self.windowGroups];
        } else {
            SWLog(@"Index does not need adjustment (%.3fs elapsed)", [[NSDate date] timeIntervalSinceDate:self.invocationTime]);
        }
        
        self.windowListLoaded = YES;
    } else {
        SWLog(@"Window list updated with %lu windows (%.3fs elapsed)", (unsigned long)self.windowGroups.count, [[NSDate date] timeIntervalSinceDate:self.invocationTime]);
    }
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

- (void)_raiseSelectedWindow;
{
    BailUnless(self.pendingSwitch && self.windowListLoaded,);
    
    SWWindowGroup *selectedWindow = self.selector.selectedWindowGroup;
    if (!selectedWindow) {
        SWLog(@"No windows to raise! (Selection index: %lu)", self.selector.selectedUIndex);
        self.pendingSwitch = NO;
        return;
    }
    
    SWWindowThumbnailView *thumb = (SWWindowThumbnailView *)[self.collectionView cellForIndex:self.selector.selectedUIndex];
    Check([thumb isKindOfClass:[SWWindowThumbnailView class]]);
    
    thumb.active = NO;
    
    @weakify(thumb);
    [[SWAccessibilityService sharedService] raiseWindow:selectedWindow.mainWindow completion:^(NSError *error) {
        @strongify(thumb);
        
        // TODO: This does not always mean that the window has been raised, just that it was told to!
        if (!error) {
            self.pendingSwitch = NO;
        }
        
        thumb.active = YES;
    }];
}

- (void)_closeSelectedWindow;
{
    Check(self.interfaceVisible);

    SWWindowGroup *selectedWindowGroup = self.selector.selectedWindowGroup;
    if (!selectedWindowGroup) { return; }
    
    SWWindowThumbnailView *thumb = (SWWindowThumbnailView *)[self.collectionView cellForIndex:self.selector.selectedUIndex];
    Check(!thumb || [thumb isKindOfClass:[SWWindowThumbnailView class]]);
    
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
    
    @weakify(thumb);
    // TODO: ASCII art leo_inception_reaction.jpg
    dispatch_async(actionQueue, ^{
        [[SWAccessibilityService sharedService] raiseWindow:nextWindow.mainWindow completion:^(NSError *raiseError){
            dispatch_async(actionQueue, ^{
                [[SWAccessibilityService sharedService] closeWindow:selectedWindowGroup.mainWindow completion:^(NSError *closeError) {
                    if (closeError) {
                        // We *should* re-raise selectedWindow, but if it didn't succeed at -close it will also probably fail to -raise.
                        dispatch_async(dispatch_get_main_queue(), ^{
                            @strongify(thumb);
                            [thumb setActive:YES];
                        });
                    }
                }];
            });
        }];
    });
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
    SWLog(@"Display timer fired %.3fs %@ (%.3fs elapsed)", fabs(elapsed - kWindowDisplayDelay), (elapsed - kWindowDisplayDelay) > 0.0 ? @"late" : @"early", elapsed);
    
    self.displayTimer = nil;
}

#pragma mark Internal Initialization

- (void)_setUpReactions;
{
    @weakify(self);
    
    // interfaceVisible = (((invoked && displayTimer == nil) || pendingSwitch) && windowListLoaded)
    RAC(self, interfaceVisible) = [[RACSignal
    combineLatest:@[RACObserve(self, invoked), RACObserve(self, displayTimer), RACObserve(self, pendingSwitch), RACObserve(self, windowListLoaded)]
    reduce:^(NSNumber *invoked, NSTimer *displayTimer, NSNumber *pendingSwitch, NSNumber *windowListLoaded){
        return @(((invoked.boolValue && displayTimer == nil) || pendingSwitch.boolValue) && windowListLoaded.boolValue);
    }]
    distinctUntilChanged];

    // Initial setup and final teardown of the switcher.
    RAC(self, active) = [[RACSignal
    combineLatest:@[RACObserve(self, invoked), RACObserve(self, pendingSwitch)]
    reduce:^(NSNumber *invoked, NSNumber *pendingSwitch){
        return @(invoked.boolValue || pendingSwitch.boolValue);
    }]
    distinctUntilChanged];
    
    // When invoked is set to YES, reset pendingSwitch to NO.
    RAC(self, pendingSwitch) = [[[RACObserve(self, invoked)
    distinctUntilChanged]
    filter:^(NSNumber *invoked){
        return invoked.boolValue;
    }]
    map:^(NSNumber *invoked){
        return @(!invoked.boolValue);
    }];
    
    // Update the selected cell in the collection view when the selector is updated.
    [[RACObserve(self, selector)
    distinctUntilChanged]
    subscribeNext:^(SWSelector *selector) {
        if (!self.windowGroups.count) { return; }
        
        NSInteger index = selector.selectedIndex;
        NSUInteger uindex = selector.selectedUIndex;
        
        if (!selector || index < 0 || uindex > [self.windowGroups count]) {
            [self.collectionView deselectCell];
        } else if (uindex != self.collectionView.selectedIndex) {
            [self.collectionView selectCellAtIndex:uindex];
        }
    }];
    
    // raise when (pendingSwitch && windowListLoaded)
    [[[[RACSignal
    combineLatest:@[RACObserve(self, pendingSwitch), RACObserve(self, windowListLoaded)]
    reduce:^(NSNumber *pendingSwitch, NSNumber *windowListLoaded){
        return @(pendingSwitch.boolValue && windowListLoaded.boolValue);
    }]
    distinctUntilChanged]
    filter:^(NSNumber *shouldRaise) {
         return shouldRaise.boolValue;
    }]
    subscribeNext:^(NSNumber *shouldRaise) {
        @strongify(self);
        [self _raiseSelectedWindow];
    }];
}

- (void)_registerEvents;
{
    @weakify(self);
    SWEventTap *eventTap = [SWEventTap sharedService];
    
    // Incrementing/invoking is bound to option-tab by default.
    [eventTap registerHotKey:[SWHotKey hotKeyWithKeycode:kVK_Tab modifiers:SWHotKeyModifierOption] withBlock:^BOOL(BOOL keyDown) {
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            if (keyDown) {
                self.invoked = YES;
                if (self.incrementing) {
                    self.selector = [self.selector incrementWithoutWrapping];
                } else {
                    self.selector = [self.selector increment];
                }
            }
            self.incrementing = keyDown;
        });
        return NO;
    }];
    
    // Option-arrow can be used to change the selection when Switch has been invoked.
    [eventTap registerHotKey:[SWHotKey hotKeyWithKeycode:kVK_RightArrow modifiers:SWHotKeyModifierOption] withBlock:^BOOL(BOOL keyDown) {
        @strongify(self);
        if (self.invoked) {
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                if (keyDown) {
                    if (self.incrementing) {
                        self.selector = [self.selector incrementWithoutWrapping];
                    } else {
                        self.selector = [self.selector increment];
                    }
                }
                self.incrementing = keyDown;
            });
            return NO;
        }
        return YES;
    }];
    
    // Decrementing/invoking is bound to option-shift-tab by default.
    [eventTap registerHotKey:[SWHotKey hotKeyWithKeycode:kVK_Tab modifiers:(SWHotKeyModifierOption|SWHotKeyModifierShift)] withBlock:^BOOL(BOOL keyDown) {
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            if (keyDown) {
                self.invoked = YES;
                if (self.decrementing) {
                    self.selector = [self.selector decrementWithoutWrapping];
                } else {
                    self.selector = [self.selector decrement];
                }
            }
            self.decrementing = keyDown;
        });
        return NO;
    }];
    
    // Option-arrow can be used to change the selection when Switch has been invoked.
    [eventTap registerHotKey:[SWHotKey hotKeyWithKeycode:kVK_LeftArrow modifiers:SWHotKeyModifierOption] withBlock:^BOOL(BOOL keyDown) {
        @strongify(self);
        if (self.invoked) {
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                if (keyDown) {
                    if (self.decrementing) {
                        self.selector = [self.selector decrementWithoutWrapping];
                    } else {
                        self.selector = [self.selector decrement];
                    }
                }
                self.decrementing = keyDown;
            });
            return NO;
        }
        return YES;
    }];
    
    // Closing a window is bound to option-W when the interface is open.
    [eventTap registerHotKey:[SWHotKey hotKeyWithKeycode:kVK_ANSI_W modifiers:SWHotKeyModifierOption] withBlock:^BOOL(BOOL keyDown) {
        @strongify(self);
        if (keyDown && self.interfaceVisible) {
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                [self _closeSelectedWindow];
            });
            return NO;
        }
        return YES;
    }];
    
    // Showing the preferences is bound to option-, when the interface is open. This action closes the interface.
    [eventTap registerHotKey:[SWHotKey hotKeyWithKeycode:kVK_ANSI_Comma modifiers:SWHotKeyModifierOption] withBlock:^BOOL(BOOL keyDown) {
        if (keyDown && self.interfaceVisible) {
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                self.invoked = NO;
                [[SWPreferencesService sharedService] showPreferencesWindow:self];
            });
            return NO;
        }
        return YES;
    }];
    
    // Cancelling the switcher is bound to option-escape. This action closes the interface.
    [eventTap registerHotKey:[SWHotKey hotKeyWithKeycode:kVK_Escape modifiers:SWHotKeyModifierOption] withBlock:^(BOOL keyDown){
        @strongify(self);
        if (keyDown && self.invoked) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.invoked = NO;
            });
            return NO;
        }
        return YES;
    }];
    
    // Releasing the option key when the interface is open raises the selected window. If that action is successful, it will close the interface.
    [eventTap registerModifier:SWHotKeyModifierOption withBlock:^(BOOL matched) {
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            if (!matched) {
                if (self.invoked) {
                    SWLog(@"Dismissed (%.3fs elapsed)", [[NSDate date] timeIntervalSinceDate:self.invocationTime]);

                    self.pendingSwitch = YES;
                    self.invoked = NO;
                }
            }
        });
    }];
    
    // Mouse moved events get captured when the interface is visible in order to update the selected item.
    [eventTap registerForEventsWithType:kCGEventMouseMoved withBlock:^(CGEventRef event) {
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            if (!self.interfaceVisible) { return; }
            
            NSPoint windowLocation = [self.window convertScreenToBase:[NSEvent mouseLocation]];
            if(NSPointInRect([self.collectionView convertPoint:windowLocation fromView:nil], [self.collectionView bounds])) {
                NSEvent *mouseEvent = [NSEvent mouseEventWithType:NSMouseMoved location:windowLocation modifierFlags:NSAlternateKeyMask timestamp:(NSTimeInterval)0 windowNumber:self.window.windowNumber context:(NSGraphicsContext *)nil eventNumber:0 clickCount:0 pressure:1.0];
                [self.collectionView mouseMoved:mouseEvent];
            }
        });
    }];
}

@end
