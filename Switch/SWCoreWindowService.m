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
#import "SWEventTap.h"
#import "SWInterfaceController.h"
#import "SWPreferencesService.h"
#import "SWScrollControl.h"
#import "SWStateMachine.h"
#import "SWWindow.h"
#import "SWWindowListService.h"


static NSTimeInterval const kWindowDisplayDelay = 0.2;
static int const kScrollThreshold = 50;


@interface SWCoreWindowService () <SWWindowListSubscriber, SWStateMachineDelegate, SWInterfaceControllerDelegate>

#pragma mark - State machine inputs
@property (nonatomic, strong) NSTimer *displayTimer;
@property (nonatomic, strong) SWScrollControl *scroller;

@property (nonatomic, readonly, strong) SWStateMachine *stateMachine;

#pragma mark - UI
@property (nonatomic, readonly, strong) SWInterfaceController *interface;

@end


@implementation SWCoreWindowService

#pragma mark - Initialization

- (instancetype)init;
{
    if (!(self = [super init])) { return nil; }

    self->_stateMachine = [SWStateMachine stateMachineWithDelegate:self];

    self->_interface = [[SWInterfaceController alloc] initWithDelegate:self];

    @weakify(self);
    self->_scroller = [[SWScrollControl alloc] initWithThreshold:kScrollThreshold incHandler:^{
        @strongify(self);
        [self.stateMachine incrementWithInvoke:false direction:SWIncrementDirectionIncreasing isRepeating:true];
    } decHandler:^{
        @strongify(self);
        [self.stateMachine incrementWithInvoke:false direction:SWIncrementDirectionDecreasing isRepeating:true];
    }];

    // update window group UI state with the state machine's updates of window groups
    [RACObserve(self, stateMachine.windowList) subscribeNext:^(NSOrderedSet *windowList) {
        @strongify(self);
        [self.interface updateWindowList:windowList];
    }];
    // update the selected window group with the state machine's update of selector.selectedWindow
    [RACObserve(self, stateMachine.selectedWindow) subscribeNext:^(SWWindow *window) {
        @strongify(self);
        [self.interface selectWindow:window];
    }];
    // start and stop window list updates based on stateMachine.windowListUpdates
    [[[RACObserve(self, stateMachine.windowListUpdates)
    distinctUntilChanged] skip:1]
    subscribeNext:^(NSNumber *windowListUpdates) {
        if ([windowListUpdates boolValue]) {
            [[NNServiceManager sharedManager] addSubscriber:self forService:[SWWindowListService self]];
            // Update with the service's current set of windows, in case it's already running.
            [self.stateMachine updateWindowList:[SWWindowListService sharedService].windows];
        } else {
            [[NNServiceManager sharedManager] removeSubscriber:self forService:[SWWindowListService self]];
        }
    }];
    // show or hide the interface based on stateMachine.interfaceVisible
    [[[RACObserve(self, stateMachine.interfaceVisible)
    distinctUntilChanged] skip:1]
    subscribeNext:^(NSNumber *interfaceVisible) {
        if ([interfaceVisible boolValue]) {
            [self _showInterface];
        } else {
            [self _hideInterface];
        }
    }];
    // set [SWEventTap sharedService].suppressKeyEvents = self.stateMachine.invoked;
    RAC([SWEventTap sharedService], suppressKeyEvents) = RACObserve(self, stateMachine.invoked);

    return self;
}

#pragma mark - NNService

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

    @weakify(self);
    SWEventTap *eventTap = [SWEventTap sharedService];

    BOOL (^updateSelector)(CGEventRef, BOOL, SWIncrementDirection) = ^(CGEventRef event, BOOL invokesInterface, SWIncrementDirection direction) {
        @strongify(self);
        BailUnless(event, YES);

        // If this hotKey doesn't invoke the interface and it is not already active, pass the event through and do nothing.
        if (!invokesInterface && !self.stateMachine.invoked) {
            return YES;
        }

        // The event is passed by reference. Copy it in case it mutates after control returns to the caller. Released in the async block below.
        event = CGEventCreateCopy(event);
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);

            // Avoid leaking the event if this block early-returns.
            NNCFAutorelease(event);

            if (CGEventGetType(event) == kCGEventKeyDown) {
                _Bool autorepeat = CGEventGetIntegerValueField(event, kCGKeyboardEventAutorepeat);

                [self.stateMachine incrementWithInvoke:invokesInterface direction:direction isRepeating:autorepeat];

                [self.scroller reset];
            }
        });

        return NO;
    };

    // Incrementing/invoking is bound to option-tab by default.
    [eventTap registerHotKey:[SWHotKey hotKeyWithKeycode:kVK_Tab modifiers:SWHotKeyModifierOption] object:self block:^BOOL(CGEventRef event) {
        _Bool invoking = true;
        SWIncrementDirection direction = SWIncrementDirectionIncreasing;
        return updateSelector(event, invoking, direction);
    }];

    // Option-arrow can be used to change the selection when Switch has been invoked.
    [eventTap registerHotKey:[SWHotKey hotKeyWithKeycode:kVK_RightArrow modifiers:SWHotKeyModifierOption] object:self block:^BOOL(CGEventRef event) {
        _Bool invoking = false;
        SWIncrementDirection direction = SWIncrementDirectionIncreasing;
        return updateSelector(event, invoking, direction);
    }];

    // Decrementing/invoking is bound to option-shift-tab by default.
    [eventTap registerHotKey:[SWHotKey hotKeyWithKeycode:kVK_Tab modifiers:(SWHotKeyModifierOption|SWHotKeyModifierShift)] object:self block:^BOOL(CGEventRef event) {
        _Bool invoking = true;
        SWIncrementDirection direction = SWIncrementDirectionDecreasing;
        return updateSelector(event, invoking, direction);
    }];

    // Option-arrow can be used to change the selection when Switch has been invoked.
    [eventTap registerHotKey:[SWHotKey hotKeyWithKeycode:kVK_LeftArrow modifiers:SWHotKeyModifierOption] object:self block:^BOOL(CGEventRef event) {
        _Bool invoking = false;
        SWIncrementDirection direction = SWIncrementDirectionDecreasing;
        return updateSelector(event, invoking, direction);
    }];

    // Closing a window is bound to option-W when the interface is open.
    [eventTap registerHotKey:[SWHotKey hotKeyWithKeycode:kVK_ANSI_W modifiers:SWHotKeyModifierOption] object:self block:^BOOL(CGEventRef event) {
        @strongify(self);

        if (CGEventGetType(event) != kCGEventKeyDown) {
            return YES;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            [self.stateMachine closeWindow];
        });
        return !self.stateMachine.interfaceVisible;
    }];

    // Showing the preferences is bound to option-, when the interface is open. This action closes the interface.
    [eventTap registerHotKey:[SWHotKey hotKeyWithKeycode:kVK_ANSI_Comma modifiers:SWHotKeyModifierOption] object:self block:^BOOL(CGEventRef event) {
        @strongify(self);
        if (CGEventGetType(event) == kCGEventKeyDown) {
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                if (self.stateMachine.active) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        @strongify(self);
                        [[SWPreferencesService sharedService] showPreferencesWindow:self];
                    });
                }
                [self.stateMachine cancelInvocation];
            });
            return NO;
        }
        return YES;
    }];

    // Cancelling the switcher is bound to option-escape. This action closes the interface.
    [eventTap registerHotKey:[SWHotKey hotKeyWithKeycode:kVK_Escape modifiers:SWHotKeyModifierOption] object:self block:^(CGEventRef event){
        @strongify(self);
        if (CGEventGetType(event) == kCGEventKeyDown) {
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                [self.stateMachine cancelInvocation];
            });
            return (BOOL)!self.stateMachine.active;
        }
        return YES;
    }];

    // Releasing the option key when the interface is open raises the selected window. If that action is successful, it will close the interface.
    [eventTap registerModifier:SWHotKeyModifierOption object:self block:^(BOOL matched) {
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            if (!matched) {
                [self.stateMachine endInvocation];
            }
        });
    }];
}

- (void)stopService;
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

    [super stopService];
}

#pragma mark - SWWindowListSubscriber

- (oneway void)windowListService:(SWWindowListService *)service updatedList:(NSOrderedSet *)windows;
{
    [self.stateMachine updateWindowList:windows];
}

#pragma mark - SWStateMachineDelegate

- (void)stateMachineWantsDisplayTimerStarted:(SWStateMachine *)stateMachine;
{
    self.displayTimer = [NSTimer scheduledTimerWithTimeInterval:kWindowDisplayDelay target:self selector:NNSelfSelector1(_displayTimerFired:) userInfo:nil repeats:NO];
}

- (void)stateMachineWantsDisplayTimerInvalidated:(SWStateMachine *)stateMachine;
{
    [self.displayTimer invalidate];
    self.displayTimer = nil;
}

- (void)stateMachine:(SWStateMachine *)stateMachine wantsWindowRaised:(SWWindow *)window;
{
    SWWindow *selectedWindow = self.stateMachine.selectedWindow;
    if (!selectedWindow) {
        return;
    }

    [self.interface disableWindow:selectedWindow];

    @weakify(self);
    [[SWAccessibilityService sharedService] raiseWindow:selectedWindow completion:^(NSError *error) {
        @strongify(self);
        if (error) {
            SWLog(@"Failed to raise window group %@: %@", selectedWindow, error);
        } else if (self.stateMachine.pendingSwitch) {
            // Sending a cancel invocation here is to work around #105
            [self.stateMachine cancelInvocation];
            Check(!self.stateMachine.wantsInterfaceVisible);
        }

        [self.interface enableWindow:selectedWindow];
    }];
}

- (void)stateMachine:(SWStateMachine *)stateMachine wantsWindowClosed:(SWWindow *)window;
{
    SWWindow *selectedWindow = self.stateMachine.selectedWindow;
    if (!selectedWindow) { return; }
    NSOrderedSet *windowList = self.stateMachine.windowList;

    /** Closing a window will change the window list ordering in unwanted ways if all of the following are true:
     *     • The first window is being closed
     *     ? The first window's application is active
     *     • The first window's application has another window open in the list
     *     • The first window and second window belong to different applications
     * This can be worked around by first raising the second window.
     * This may still result in odd behaviour if firstWindow.close fails, but applications not responding to window close events is incorrect behaviour (performance is a feature!) whereas window list shenanigans are (relatively) expected.
     */
    SWWindow *nextWindow = nil;
    {
        NSUInteger selectedIndex = [windowList indexOfObject:selectedWindow];
        BOOL onlyChild = ([windowList indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop){
            // Do not count the selected window, we're looking for the existence of a sibling.
            if (idx == selectedIndex) { return NO; }
            return [CLASS_CAST(SWWindow, obj).application isEqual:selectedWindow.application];
        }] == NSNotFound);

        BOOL differentApplications = [windowList count] > 1 && ![[windowList[0] application] isEqual:[windowList[1] application]];

        if (selectedIndex == 0 && !onlyChild && differentApplications) {
            nextWindow = [windowList objectAtIndex:1];
        }
    }

    [self.interface disableWindow:selectedWindow];

    @weakify(self);
    [[SWAccessibilityService sharedService] raiseWindow:nextWindow completion:^(NSError *raiseError){
        if (raiseError) {
            SWLog(@"Failed to raise window group %@: %@", nextWindow, raiseError);
        }
        [[SWAccessibilityService sharedService] closeWindow:selectedWindow completion:^(NSError *closeError) {
            if (closeError) {
                SWLog(@"Failed to close window group %@: %@", selectedWindow, closeError);
                // We *should* re-raise selectedWindow, but if it didn't succeed at -close it will also probably fail to -raise.
                dispatch_async(dispatch_get_main_queue(), ^{
                    @strongify(self);
                    [self.interface enableWindow:selectedWindow];
                });
            }
        }];
    }];
}

#pragma mark - SWInterfaceControllerDelegate

- (void)interfaceController:(SWInterfaceController *)controller didSelectWindow:(SWWindow *)window;
{
    [self.stateMachine selectWindow:window];
    [self.scroller reset];
}

- (void)interfaceController:(SWInterfaceController *)controller didActivateWindow:(SWWindow *)window;
{
    [self.stateMachine activateWindow:window];
    [self.scroller reset];
}

- (void)interfaceControllerDidClickOutsideInterface:(SWInterfaceController *)controller;
{
    [self.stateMachine cancelInvocation];
}

#pragma mark - Private callbacks

- (void)_displayTimerFired:(NSTimer *)timer;
{
    if (![timer isEqual:self.displayTimer]) {
        return;
    }

    [self.stateMachine displayTimerCompleted];
    self.displayTimer = nil;
}

- (void)_showInterface;
{
    @weakify(self);
    [[SWEventTap sharedService] registerForEventsWithType:kCGEventScrollWheel object:self block:^(CGEventRef event) {
        // The event may be passed by reference and reused later. Copy it in case it mutates after control returns to the caller. Released in the async block below.
        event = CGEventCreateCopy(event);
        dispatch_async(dispatch_get_main_queue(), ^{
            NNCFAutorelease(event);
            @strongify(self);

            int delta = (int)CGEventGetIntegerValueField(event, kCGScrollWheelEventPointDeltaAxis1);
            if (delta == 0) { return; }

            [self.scroller feed:delta];
        });
    }];

    [self.interface shouldShowInterface:true];
}

- (void)_hideInterface;
{
    [[SWEventTap sharedService] removeBlockForEventsWithType:kCGEventScrollWheel object:self];

    [self.interface shouldShowInterface:false];
}

@end
