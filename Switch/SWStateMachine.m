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

- (instancetype)initWithDelegate:(id<SWStateMachineDelegate>) delegate;
{
    if (!(self = [super init])) { return nil; }
    
    self.delegate = delegate;
    
    @weakify(self);
    
    // interfaceVisible = ((invoked || pendingSwitch) && displayTimer == nil && windowListLoaded)
    RAC(self, interfaceVisible) = [[RACSignal
    combineLatest:@[RACObserve(self, invoked), RACObserve(self, displayTimer), RACObserve(self, pendingSwitch), RACObserve(self, windowListLoaded)]
    reduce:^(NSNumber *invoked, NSNumber *displayTimer, NSNumber *pendingSwitch, NSNumber *windowListLoaded){
        return @((invoked.boolValue || pendingSwitch.boolValue) && !displayTimer.boolValue && windowListLoaded.boolValue);
    }]
    distinctUntilChanged];
    
    // Initial setup and final teardown of the switcher.
    RAC(self, active) = [[RACSignal
    combineLatest:@[RACObserve(self, invoked), RACObserve(self, pendingSwitch)]
    reduce:^(NSNumber *invoked, NSNumber *pendingSwitch){
        return @(invoked.boolValue || pendingSwitch.boolValue);
    }]
    distinctUntilChanged];
    
    // Update the selected cell in the collection view when the selector is updated.
    [[RACObserve(self, selector)
    distinctUntilChanged]
    subscribeNext:^(SWSelector *selector) {
        @strongify(self);
        self.selectedWindow = self.selector.selectedWindow;
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

- (void)setActive:(_Bool)active;
{
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
    } else {
        self.windowListUpdates = false;
        [self _updateWindowList:nil];
        Check(!self.windowList.count);
        Check(!self.windowListLoaded);
        
        if (self.displayTimer) {
            [delegate stateMachineWantsDisplayTimerInvalidated:self];
            self.displayTimer = false;
        }
        
        self.selector = nil;
    }
}

- (void)setInterfaceVisible:(_Bool)interfaceVisible;
{
    if (interfaceVisible == self.interfaceVisible) { return; }
    self->_interfaceVisible = interfaceVisible;

    if (interfaceVisible) {
        [self _adjustSelector];
    }
}

- (void)setInvoked:(_Bool)invoked;
{
    self->_invoked = invoked;
}

#pragma mark - Feedback

- (void)displayTimerCompleted;
{
    StateLog(@"State machine display timer completed");
    self.displayTimer = false;
}

#pragma mark - Keyboard interactions

- (_Bool)incrementWithInvoke:(_Bool)invokesInterface direction:(SWIncrementDirection)direction isRepeating:(_Bool)autorepeat;
{
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
    
    if (!self.invoked) {
        return true;
    }
    
    if (autorepeat) {
        self.selector = direction == SWIncrementDirectionIncreasing ? self.selector.incrementWithoutWrapping : self.selector.decrementWithoutWrapping;
    } else {
        self.selector = direction == SWIncrementDirectionIncreasing ? self.selector.increment : self.selector.decrement;
    }
    
    self.scrollOffset = 0;
    
    return false;
}

- (_Bool)closeWindow;
{
    StateLog(@"State machine event close window");

    if (self.interfaceVisible) {
        if (self.selectedWindow) {
            id<SWStateMachineDelegate> delegate = self.delegate;
            [delegate stateMachine:self wantsWindowClosed:self.selectedWindow];
        }
        return false;
    }
    return true;
}

- (_Bool)cancelInvocation;
{
    StateLog(@"State machine event cancel invocation");

    // Setting pendingSwitch here is to work around #105
    self.pendingSwitch = false;

    if (self.invoked) {
        self.invoked = false;
        return false;
    }
    return true;
}

- (void)endInvocation;
{
    StateLog(@"State machine event end invocation");

    if (self.invoked) {
        self.pendingSwitch = true;
        self.invoked = false;
    }
}

#pragma mark - GUI interactions

- (void)selectWindow:(SWWindow *)window;
{
    StateLog(@"State machine mouse select window group: %@", window);

    if (!self.windowList) { return; }

    [self _adjustSelector];

    NSUInteger index = [self.selector.windowList indexOfObject:window];
    Check(index < self.selector.windowList.count || index == NSNotFound);
    self.selector = [self.selector selectIndex:(NSInteger)index];
}

- (void)activateWindow:(SWWindow *)window;
{
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
    StateLog(@"State machine update window groups: %@", windowList);

    [self _updateWindowList:windowList];
}

#pragma mark - Internal

- (void)_adjustSelector;
{
    if (!self.selectorAdjusted) {
        Check(self.windowListLoaded);
        Check(self.selector.windowList == nil);
        if (self.selector.selectedIndex == 1 && [self.windowList count] > 1 && ![CLASS_CAST(SWWindow, [self.windowList objectAtIndex:0]).application isActiveApplication]) {
            self.selector = [[SWSelector new] updateWithWindowList:self.windowList];
        }
        self.selectorAdjusted = YES;
        self.selector = [self.selector updateWithWindowList:self.windowList];
    }
}

- (void)_updateWindowList:(NSOrderedSet *)windowList;
{
    // A nil update means clean up, we're shutting down until the next invocation.
    if (!windowList || !self.active) {
        self.windowList = nil;
        self.windowListLoaded = false;
        self.selectorAdjusted = false;
        return;
    }

    // I suspect this is the problem for #105
    if (self.windowList.count == windowList.count && self.selectedWindow) {
        Check([windowList containsObject:self.selectedWindow]);
    }

    self.windowList = windowList;
    
    if (!self.windowListLoaded) {
        self.windowListLoaded = true;
    } else {
        if (self.selectorAdjusted) {
            self.selector = [self.selector updateWithWindowList:windowList];
        }
    }

    if (self.pendingSwitch && [[windowList firstObject] isEqual:self.selectedWindow] && [self.selectedWindow.application isActiveApplication]) {
        self.pendingSwitch = NO;
    }
}

- (void)_raiseSelectedWindow;
{
    BailUnless(self.pendingSwitch && self.windowListLoaded,);
    
    [self _adjustSelector];
    
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

@end
