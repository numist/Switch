//
//  SWStateMachine.m
//  Switch
//
//  Created by Scott Perry on 09/26/14.
//  Copyright © 2014 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWApplication.h"
#import "SWSelector.h"
#import "SWStateMachine.h"
#import "SWWindow.h"


#ifdef STATE_MACHINE_DEBUG
    #define StateLog NSLog
#else
    #define StateLog(...)
#endif


@interface SWStateMachine ()

@property (nonatomic, readwrite, weak) id<SWStateMachineDelegate> delegate;
@property (nonatomic, readwrite, copy) NSOrderedSet *windowList;
@property (nonatomic, readwrite, copy) SWWindow *selectedWindow;

#pragma mark - Core state

@property (nonatomic, readwrite, assign) _Bool invoked;
@property (nonatomic, readwrite, assign, getter=wantsDisplayTimer) _Bool displayTimer;
@property (nonatomic, readwrite, assign) _Bool pendingSwitch;
@property (nonatomic, readwrite, assign) _Bool windowListLoaded;
@property (nonatomic, readwrite, assign, getter=wantsWindowListUpdates) _Bool windowListUpdates;

#pragma mark - Dependant state

@property (nonatomic, readwrite, assign, getter=isActive) _Bool active;
@property (nonatomic, readwrite, assign, getter=wantsInterfaceVisible) _Bool interfaceVisible;

#pragma mark - Selector state

@property (nonatomic, readwrite, assign) _Bool selectorAdjusted;
@property (nonatomic, readwrite, strong) SWSelector *selector;
@property (nonatomic, readwrite, assign) int scrollOffset;

@end


@implementation SWStateMachine

+ (instancetype)stateMachineWithDelegate:(id<SWStateMachineDelegate>) delegate;
{
    return [[self alloc] initWithDelegate:delegate];
}

- (instancetype)initWithDelegate:(id<SWStateMachineDelegate>) delegate;
{
    BailUnless(self = [super init], nil);
    
    self.delegate = delegate;
    
    return self;
}

- (void)setActive:(_Bool)active;
{
    SWLogMainThreadOnly();
    if (active == self.active) { return; }
    self->_active = active;

    id<SWStateMachineDelegate> delegate = self.delegate;

    if (active) {
        // This shouldn't ever happen because of pendingSwitch.
        Check(self.invoked);
        
        if (!Check(!self.displayTimer)) {
            [delegate stateMachineWantsDisplayTimerInvalidated:self];
        }
        [delegate stateMachineWantsDisplayTimerStarted:self];
        self.displayTimer = true;
        
        Check(!self.selector);
        self.selector = [SWSelector new];

        Check(!self.windowList.count);
        Check(!self.windowListLoaded);
        self.windowListUpdates = true;
    }

    [self private_updateInterfaceVisible];

    if (!active) {
        self.windowListUpdates = false;
        [self private_updateWindowList:nil];
        Check(!self.windowList.count);
        Check(!self.windowListLoaded);
        
        if (self.displayTimer) {
            [delegate stateMachineWantsDisplayTimerInvalidated:self];
            self.displayTimer = false;
        }
        
        self.selector = nil;
        self.pendingSwitch = false;
    }
}

- (void)setInterfaceVisible:(_Bool)interfaceVisible;
{
    SWLogMainThreadOnly();
    if (interfaceVisible == self.interfaceVisible) { return; }
    self->_interfaceVisible = interfaceVisible;

    if (interfaceVisible) {
        [self private_adjustSelectorIfNecessary];
    }
}

- (void)setInvoked:(bool)invoked {
    SWLogMainThreadOnly();
    if (invoked == _invoked) {
        return;
    }
    _invoked = invoked;
    
    [self private_updateActive];
}

- (void)setPendingSwitch:(bool)pendingSwitch {
    SWLogMainThreadOnly();
    if (pendingSwitch == _pendingSwitch) {
        return;
    }
    _pendingSwitch = pendingSwitch;
    
    [self private_updateActive];
    [self private_raiseWindowIfNeeded];
}

- (void)setDisplayTimer:(bool)displayTimer {
    SWLogMainThreadOnly();
    if (displayTimer == _displayTimer) {
        return;
    }
    _displayTimer = displayTimer;
    
    [self private_updateInterfaceVisible];
}

- (void)setWindowListLoaded:(bool)windowListLoaded {
    SWLogMainThreadOnly();
    if (windowListLoaded == _windowListLoaded) {
        return;
    }
    _windowListLoaded = windowListLoaded;

    [self private_updateInterfaceVisible];
    [self private_raiseWindowIfNeeded];
}

- (void)setSelector:(SWSelector *)selector {
    SWLogMainThreadOnly();
    if (selector == _selector) {
        return;
    }
    _selector = selector;

    [self private_updateSelectedWindow];
}

#pragma mark - Feedback

- (void)displayTimerCompleted;
{
    SWLogMainThreadOnly();
    if (!self.pendingSwitch) {
        StateLog(@"State machine display timer completed");
        self.displayTimer = false;
    }
}

#pragma mark - Keyboard interactions

- (void)incrementWithInvoke:(_Bool)invokesInterface direction:(SWIncrementDirection)direction isRepeating:(_Bool)autorepeat;
{
    SWLogMainThreadOnly();
    StateLog(@"State machine key event with invoke:%@ direction:%@ repeating:%@",
          invokesInterface ? @"true" : @"false",
          direction == SWIncrementDirectionIncreasing ? @"increasing" : @"decreasing",
          autorepeat ? @"true" : @"false");
    
    if (invokesInterface) {
        self.invoked = true;
    }
    
    if (self.pendingSwitch) {
        self.invoked = true;
        self.pendingSwitch = false;
    }
    
    if (autorepeat) {
        self.selector = direction == SWIncrementDirectionIncreasing ? self.selector.incrementWithoutWrapping : self.selector.decrementWithoutWrapping;
    } else {
        self.selector = direction == SWIncrementDirectionIncreasing ? self.selector.increment : self.selector.decrement;
    }
    
    self.scrollOffset = 0;
}

- (void)closeWindow;
{
    SWLogMainThreadOnly();
    StateLog(@"State machine event close window");

    if (self.interfaceVisible) {
        if (self.selectedWindow) {
            id<SWStateMachineDelegate> delegate = self.delegate;
            [delegate stateMachine:self wantsWindowClosed:self.selectedWindow];
        }
    }
}

- (void)cancelInvocation;
{
    SWLogMainThreadOnly();
    StateLog(@"State machine event cancel invocation");

    if (self.invoked) {
        self.invoked = false;
    }
}

- (void)endInvocation;
{
    SWLogMainThreadOnly();
    StateLog(@"State machine event end invocation");

    if (self.invoked) {
        self.pendingSwitch = true;
        self.invoked = false;
    }
}

#pragma mark - GUI interactions

- (void)selectWindow:(SWWindow *)window;
{
    SWLogMainThreadOnly();
    StateLog(@"State machine mouse select window group: %@", window);

    if (!self.windowList) { return; }

    [self private_adjustSelectorIfNecessary];

    NSUInteger index = [self.selector.windowList indexOfObject:window];
    Check(index < self.selector.windowList.count || index == NSNotFound);
    self.selector = [self.selector selectIndex:(NSInteger)index];
}

- (void)activateWindow:(SWWindow *)window;
{
    SWLogMainThreadOnly();
    StateLog(@"State machine mouse activate window group: %@", window);

    if (!self.windowList) { return; }

    if (![self.selector.selectedWindow isEqual:window]) {
        [self selectWindow:window];
    }

    if ([self.windowList containsObject:window]) {
        self.pendingSwitch = true;
        // Clicking on an item cancels the keyboard invocation.
        self.invoked = false;
    }
}

#pragma mark - Data updates

- (void)updateWindowList:(NSOrderedSet *)windowList;
{
    SWLogMainThreadOnly();
    StateLog(@"State machine update window groups: %@", windowList);

    [self private_updateWindowList:windowList];
}

#pragma mark - Internal

- (void)private_adjustSelectorIfNecessary;
{
    SWLogMainThreadOnly();
    if (!self.selectorAdjusted) {
        Assert(self.windowListLoaded);
        Assert(self.selector.windowList == nil);
        if (self.selector.selectedIndex == 1 && [self.windowList count] > 1 && ![CLASS_CAST(SWWindow, [self.windowList objectAtIndex:0]).application isActiveApplication]) {
            self.selector = [[SWSelector new] updateWithWindowList:self.windowList];
        }
        self.selectorAdjusted = YES;
        self.selector = [self.selector updateWithWindowList:self.windowList];
    }
}

- (void)private_updateWindowList:(NSOrderedSet *)windowList;
{
    SWLogMainThreadOnly();
    // A nil update means clean up, we're shutting down until the next invocation.
    if (!windowList || !self.active) {
        self.windowList = nil;
        self.windowListLoaded = false;
        self.selectorAdjusted = false;
        return;
    }

    self.windowList = windowList;
    
    if (!self.windowListLoaded) {
        self.windowListLoaded = true;
    } else if (self.selectorAdjusted) {
        self.selector = [self.selector updateWithWindowList:windowList];
    }

    if (self.pendingSwitch && [[windowList firstObject] isEqual:self.selectedWindow] && [self.selectedWindow.application isActiveApplication]) {
        self.pendingSwitch = NO;
    }
}

- (void)private_raiseSelectedWindow;
{
    SWLogMainThreadOnly();
    BailUnless(self.pendingSwitch && self.windowListLoaded,);
    
    [self private_adjustSelectorIfNecessary];
    
    SWWindow *selectedWindow = self.selector.selectedWindow;
    _Bool noSelection = !selectedWindow;
    _Bool alreadyActiveWindow = !noSelection && [selectedWindow isEqual:self.windowList[0]] && [selectedWindow.application isActiveApplication];
    if (noSelection || alreadyActiveWindow) {
        self.pendingSwitch = false;
        return;
    }

    id<SWStateMachineDelegate> delegate = self.delegate;
    [delegate stateMachine:self wantsWindowRaised:selectedWindow];
}

#pragma mark Computed property updaters

- (void)private_updateInterfaceVisible {
    _Bool interfaceVisible = (_invoked || _pendingSwitch) && !_displayTimer && _windowListLoaded;
    if (self.interfaceVisible != interfaceVisible) {
        self.interfaceVisible = interfaceVisible;
    }
}

- (void)private_updateActive {
    _Bool active = _invoked || _pendingSwitch;
    if (self.active != active) {
        self.active = active;
    }
}

- (void)private_updateSelectedWindow {
    SWWindow *selectedWindow = _selector.selectedWindow;
    if (self.selectedWindow != selectedWindow) {
        self.selectedWindow = selectedWindow;
    }
}

- (void)private_raiseWindowIfNeeded {
    if (_pendingSwitch && _windowListLoaded) {
        [self private_raiseSelectedWindow];
    }
}

@end
