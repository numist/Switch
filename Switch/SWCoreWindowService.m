//
//  SWCoreWindowService.m
//  Switch
//
//  Created by Scott Perry on 11/19/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWCoreWindowService.h"

#import "NSScreen+SWAdditions.h"
#import "SWAccessibilityService.h"
#import "SWApplication.h"
#import "SWCoreWindowController.h"
#import "SWEventTap.h"
#import "SWPreferencesService.h"
#import "SWSelector.h"
#import "SWWindowGroup.h"
#import "SWWindowListService.h"


static NSTimeInterval kWindowDisplayDelay = 0.15;
static int kScrollThreshold = 50;


@interface SWCoreWindowService () <SWCoreWindowControllerDelegate, SWWindowListSubscriber>

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
@property (nonatomic, assign) int scrollOffset;

#pragma mark Logging state
@property (nonatomic, strong) NSDate *invocationTime;

#pragma mark UI
@property (nonatomic, strong) NSMutableDictionary *windowControllerCache;
@property (nonatomic, strong) NSDictionary *windowControllersByScreenID;
@property (nonatomic, strong) SWCoreWindowController *windowControllerDispatcher;

@end


@implementation SWCoreWindowService

#pragma mark Initialization

- (instancetype)init;
{
    if (!(self = [super init])) { return nil; }
    
    _windowControllerCache = [NSMutableDictionary new];

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
        @strongify(self);
        [self _updateSelection];
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
    
    return self;
}

#pragma mark NNService

+ (NNServiceType)serviceType;
{
    return NNServiceTypePersistent;
}

+ (NSSet *)dependencies;
{
    return [NSSet setWithArray:@[[SWEventTap class], [SWPreferencesService class], [SWAccessibilityService class]]];
}

- (void)startService;
{
    [super startService];
    
    [self _registerEvents];
}

- (void)stopService;
{
    [self _deregisterEvents];
    
    [super stopService];
}

#pragma mark SWCoreWindowService

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
        self.displayTimer = [NSTimer scheduledTimerWithTimeInterval:kWindowDisplayDelay target:self selector:NNSelfSelector1(_displayTimerFired:) userInfo:nil repeats:NO];
        
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
    
    SWEventTap *eventTap = [SWEventTap sharedService];
    if (interfaceVisible) {
        Check(!self.windowControllersByScreenID);
        
        self.windowControllersByScreenID = ^{
            NSMutableDictionary *windowControllers = [NSMutableDictionary new];
            NSArray *screens = [SWPreferencesService sharedService].multimonInterface
            ? [NSScreen screens]
            : @[[NSScreen mainScreen]];
            
            for (NSScreen *screen in screens) {
                SWCoreWindowController *windowController = [self.windowControllerCache objectForKey:@(screen.sw_screenNumber)];
                if (!windowController) {
                    windowController = [[SWCoreWindowController alloc] initWithScreen:screen];
                    self.windowControllerCache[@(screen.sw_screenNumber)] = windowController;
                }
                [windowController.window setFrame:screen.frame display:YES];
                windowController.delegate = self;
                windowControllers[@(screen.sw_screenNumber)] = windowController;
            }
            
            // Remove any window controllers assigned to screens that no longer exist.
            for (NSNumber *screenNumber in self.windowControllerCache.allKeys.copy) {
                if (![windowControllers.allValues containsObject:self.windowControllerCache[screenNumber]]) {
                    [self.windowControllerCache removeObjectForKey:screenNumber];
                }
            }
            
            return windowControllers;
        }();

        self.windowControllerDispatcher = (SWCoreWindowController *)^{
            NNMultiDispatchManager *dispatcher = [[NNMultiDispatchManager alloc] initWithProtocol:@protocol(SWCoreWindowControllerAPI)];
            
            for (SWCoreWindowController *windowController in self.windowControllersByScreenID.allValues) {
                [dispatcher addObserver:windowController];
            }
            
            return dispatcher;
        }();
        
        [self _updateWindowControllerWindowGroups];
        [self _updateSelection];
        
        // layoutSubviewsIfNeeded isn't instant due to Auto Layout magic, so let everything take effect before showing the window.
        dispatch_async(dispatch_get_main_queue(), ^{
            for (SWCoreWindowController *windowController in self.windowControllersByScreenID.allValues) {
                [windowController.window orderFront:self];
            }
        });
        
        @weakify(self);
        [eventTap registerForEventsWithType:kCGEventScrollWheel object:self block:^(CGEventRef event) {
            CFRetain(event);
            dispatch_async(dispatch_get_main_queue(), ^{
                NNCFAutorelease(event);
                @strongify(self);

                if (!self.interfaceVisible) { return; }

                int delta = (int)CGEventGetIntegerValueField(event, kCGScrollWheelEventPointDeltaAxis1);
                if (delta == 0) { return; }

                self.scrollOffset += delta;

                int units = (self.scrollOffset / (NSInteger)kScrollThreshold);
                if (units != 0) {
                    self.scrollOffset -= (units * kScrollThreshold);

                    SWSelector *selector = self.selector;
                    while (units > 0) {
                        selector = selector.incrementWithoutWrapping;
                        units--;
                    }
                    while (units < 0) {
                        selector = selector.decrementWithoutWrapping;
                        units++;
                    }
                    self.selector = selector;
                }
            });
        }];
    } else {
        [eventTap removeBlockForEventsWithType:kCGEventScrollWheel object:self];
        self.windowControllerDispatcher = nil;

        for (SWCoreWindowController *windowController in self.windowControllersByScreenID.allValues) {
            [windowController.window orderOut:self];
            windowController.delegate = nil;
        }
        self.windowControllersByScreenID = nil;
    }
}

- (void)setInvoked:(BOOL)invoked;
{
    [SWEventTap sharedService].suppressKeyEvents = invoked;
    self->_invoked = invoked;
}

#pragma mark SWCoreWindowControllerDelegate

- (void)coreWindowController:(SWCoreWindowController *)controller didSelectWindowGroup:(SWWindowGroup *)windowGroup;
{
    if (windowGroup == self.selector.selectedWindowGroup) { return; }
    self.selector = [self.selector selectIndex:(NSInteger)[self.windowGroups indexOfObject:windowGroup]];
    self.scrollOffset = 0;
}

- (void)coreWindowController:(SWCoreWindowController *)controller didActivateWindowGroup:(SWWindowGroup *)windowGroup;
{
    if (!Check([self.selector.selectedWindowGroup isEqual:windowGroup])) {
        [self coreWindowController:controller didSelectWindowGroup:windowGroup];
    }
    
    self.pendingSwitch = YES;
    // Clicking on an item cancels the keyboard invocation.
    self.invoked = NO;
}

#pragma mark SWWindowListSubscriber

- (oneway void)windowListService:(SWWindowListService *)service updatedList:(NSOrderedSet *)windows;
{
    [self _updateWindowGroups:windows];
}

#pragma mark - Private

- (void)_updateWindowControllerWindowGroups;
{
    if (!self.windowControllersByScreenID.count) { return; }
    
    NSMutableDictionary *windowsPerScreen = [NSMutableDictionary new];
    for (NSNumber *screenNumber in self.windowControllersByScreenID.allKeys) {
        windowsPerScreen[screenNumber] = [NSMutableOrderedSet new];
    }
    
    for (SWWindowGroup *windowGroup in self.windowGroups) {
        NSNumber *screenNumber = @([windowGroup screen].sw_screenNumber);

        // If there is no window controller that owns that screen, assign the group to the main screen.
        if (![windowsPerScreen objectForKey:screenNumber]) {
            screenNumber = @([NSScreen mainScreen].sw_screenNumber);
            Check([windowsPerScreen objectForKey:screenNumber]);
        }

        [windowsPerScreen[screenNumber] addObject:windowGroup];
    }
    
    for (NSNumber *screenNumber in windowsPerScreen.allKeys) {
        SWCoreWindowController *windowController = self.windowControllersByScreenID[screenNumber];
        windowController.windowGroups = windowsPerScreen[screenNumber];
    }
}

- (void)_updateSelection;
{
    [self.windowControllerDispatcher selectWindowGroup:self.selector.selectedWindowGroup];
}

- (void)_updateWindowGroups:(NSOrderedSet *)windowGroups;
{
    if ([windowGroups isEqual:self.windowGroups]) {
        return;
    }
 
    // A nil update means clean up, we're shutting down until the next invocation.
    if (!windowGroups) {
        self.windowGroups = nil;
        self.windowControllerDispatcher.windowGroups = nil;
        self.windowListLoaded = NO;
        return;
    }

    self.windowGroups = windowGroups;
    [self _updateWindowControllerWindowGroups];
    self.selector = [self.selector updateWithWindowGroups:windowGroups];

    if (!self.windowListLoaded) {
        SWLog(@"Window list loaded with %lu windows (%.3fs elapsed)", (unsigned long)self.windowGroups.count, [[NSDate date] timeIntervalSinceDate:self.invocationTime]);

        if (self.selector.selectedIndex == 1 && [self.windowGroups count] > 1 && !CLASS_CAST(SWWindowGroup, [self.windowGroups objectAtIndex:0]).mainWindow.application.runningApplication.active) {
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

- (void)_raiseSelectedWindow;
{
    BailUnless(self.pendingSwitch && self.windowListLoaded,);

    SWWindowGroup *selectedWindowGroup = self.selector.selectedWindowGroup;
    if (!selectedWindowGroup) {
        SWLog(@"No windows to raise! (Selection index: %lu)", self.selector.selectedUIndex);
        self.pendingSwitch = NO;
        return;
    }

    [self.windowControllerDispatcher disableWindowGroup:selectedWindowGroup];
    
    [[SWAccessibilityService sharedService] raiseWindow:selectedWindowGroup.mainWindow completion:^(NSError *error) {
        // TODO: This does not always mean that the window has been raised, just that it was told to!
        if (!error) {
            self.pendingSwitch = NO;
        }

        [self.windowControllerDispatcher enableWindowGroup:selectedWindowGroup];
    }];
}

- (void)_closeSelectedWindow;
{
    Check(self.interfaceVisible);

    SWWindowGroup *selectedWindowGroup = self.selector.selectedWindowGroup;
    if (!selectedWindowGroup) { return; }

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
            return [CLASS_CAST(SWWindowGroup, obj).application isEqual:selectedWindowGroup.application];
        }] == NSNotFound);

        BOOL differentApplications = [self.windowGroups count] > 1 && ![[self.windowGroups[0] application] isEqual:[self.windowGroups[1] application]];

        if (self.selector.selectedIndex == 0 && !onlyChild && differentApplications) {
            nextWindow = [self.windowGroups objectAtIndex:1];
        }
    }

    // If sending events to Switch itself, we have to use the main thread!
    dispatch_queue_t actionQueue = [selectedWindowGroup.application isCurrentApplication] ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    [self.windowControllerDispatcher disableWindowGroup:selectedWindowGroup];

    // Yo dawg, I herd you like async blocks…
    dispatch_async(actionQueue, ^{
        [[SWAccessibilityService sharedService] raiseWindow:nextWindow.mainWindow completion:^(NSError *raiseError){
            dispatch_async(actionQueue, ^{
                [[SWAccessibilityService sharedService] closeWindow:selectedWindowGroup.mainWindow completion:^(NSError *closeError) {
                    if (closeError) {
                        // We *should* re-raise selectedWindow, but if it didn't succeed at -close it will also probably fail to -raise.
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.windowControllerDispatcher enableWindowGroup:selectedWindowGroup];
                        });
                    }
                }];
            });
        }];
    });
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

- (void)_registerEvents;
{
    @weakify(self);
    SWEventTap *eventTap = [SWEventTap sharedService];

    BOOL (^updateSelector)(CGEventRef, BOOL, BOOL) = ^(CGEventRef event, BOOL invokesInterface, BOOL incrementing) {
        BailUnless(event, YES);
        
        // If this hotKey doesn't invoke the interface and it is not already active, pass the event through and do nothing.
        if (!invokesInterface && !self.invoked) {
            return YES;
        }
        
        // The event is passed by reference. Copy it in case it mutates after control returns to the caller. Released in the async block below.
        event = CGEventCreateCopy(event);
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);

            // Avoid leaking the event if this block early-returns.
            NNCFAutorelease(event);
            
            if (CGEventGetType(event) == kCGEventKeyDown) {
                if (invokesInterface) {
                    self.invoked = YES;
                }

                if (!Check(self.invoked)) {
                    return;
                }

                if (CGEventGetIntegerValueField(event, kCGKeyboardEventAutorepeat)) {
                    self.selector = incrementing ? self.selector.incrementWithoutWrapping : self.selector.decrementWithoutWrapping;
                } else {
                    self.selector = incrementing ? self.selector.increment : self.selector.decrement;
                }
                
                self.scrollOffset = 0;
            }
        });
        
        return NO;
    };
    
    // Incrementing/invoking is bound to option-tab by default.
    [eventTap registerHotKey:[SWHotKey hotKeyWithKeycode:kVK_Tab modifiers:SWHotKeyModifierOption] object:self block:^BOOL(CGEventRef event) {
        // Invokes, incrementing.
        return updateSelector(event, YES, YES);
    }];

    // Option-arrow can be used to change the selection when Switch has been invoked.
    [eventTap registerHotKey:[SWHotKey hotKeyWithKeycode:kVK_RightArrow modifiers:SWHotKeyModifierOption] object:self block:^BOOL(CGEventRef event) {
        // Does not invoke, incrementing.
        return updateSelector(event, NO, YES);
    }];

    // Decrementing/invoking is bound to option-shift-tab by default.
    [eventTap registerHotKey:[SWHotKey hotKeyWithKeycode:kVK_Tab modifiers:(SWHotKeyModifierOption|SWHotKeyModifierShift)] object:self block:^BOOL(CGEventRef event) {
        // Invokes, decrementing.
        return updateSelector(event, YES, NO);
    }];

    // Option-arrow can be used to change the selection when Switch has been invoked.
    [eventTap registerHotKey:[SWHotKey hotKeyWithKeycode:kVK_LeftArrow modifiers:SWHotKeyModifierOption] object:self block:^BOOL(CGEventRef event) {
        // Does not invoke, decrementing.
        return updateSelector(event, NO, NO);
    }];

    // Closing a window is bound to option-W when the interface is open.
    [eventTap registerHotKey:[SWHotKey hotKeyWithKeycode:kVK_ANSI_W modifiers:SWHotKeyModifierOption] object:self block:^BOOL(CGEventRef event) {
        @strongify(self);
        if (CGEventGetType(event) == kCGEventKeyDown && self.interfaceVisible) {
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                [self _closeSelectedWindow];
            });
            return NO;
        }
        return YES;
    }];

    // Showing the preferences is bound to option-, when the interface is open. This action closes the interface.
    [eventTap registerHotKey:[SWHotKey hotKeyWithKeycode:kVK_ANSI_Comma modifiers:SWHotKeyModifierOption] object:self block:^BOOL(CGEventRef event) {
        @strongify(self);
        if (CGEventGetType(event) == kCGEventKeyDown && self.invoked) {
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
    [eventTap registerHotKey:[SWHotKey hotKeyWithKeycode:kVK_Escape modifiers:SWHotKeyModifierOption] object:self block:^(CGEventRef event){
        @strongify(self);
        if (CGEventGetType(event) == kCGEventKeyDown && self.invoked) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.invoked = NO;
            });
            return NO;
        }
        return YES;
    }];

    // Releasing the option key when the interface is open raises the selected window. If that action is successful, it will close the interface.
    [eventTap registerModifier:SWHotKeyModifierOption object:self block:^(BOOL matched) {
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
}

- (void)_deregisterEvents;
{
    SWEventTap *eventTap = [SWEventTap sharedService];
    [eventTap removeBlockForHotKey:[SWHotKey hotKeyWithKeycode:kVK_Tab modifiers:SWHotKeyModifierOption] object:self];
    [eventTap removeBlockForHotKey:[SWHotKey hotKeyWithKeycode:kVK_RightArrow modifiers:SWHotKeyModifierOption] object:self];
    [eventTap removeBlockForHotKey:[SWHotKey hotKeyWithKeycode:kVK_Tab modifiers:(SWHotKeyModifierOption|SWHotKeyModifierShift)] object:self];
    [eventTap removeBlockForHotKey:[SWHotKey hotKeyWithKeycode:kVK_LeftArrow modifiers:SWHotKeyModifierOption] object:self];
    [eventTap removeBlockForHotKey:[SWHotKey hotKeyWithKeycode:kVK_ANSI_W modifiers:SWHotKeyModifierOption] object:self];
    [eventTap removeBlockForHotKey:[SWHotKey hotKeyWithKeycode:kVK_ANSI_Comma modifiers:SWHotKeyModifierOption] object:self];
    [eventTap removeBlockForHotKey:[SWHotKey hotKeyWithKeycode:kVK_Escape modifiers:SWHotKeyModifierOption] object:self];
    [eventTap removeBlockForModifier:SWHotKeyModifierOption object:self];
}

@end
