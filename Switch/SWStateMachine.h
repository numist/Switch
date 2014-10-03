//
//  SWStateMachine.h
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

#import <Foundation/Foundation.h>


@class SWStateMachine, SWWindow;


typedef NS_ENUM(uint8_t, SWIncrementDirection) {
    SWIncrementDirectionIncreasing,
    SWIncrementDirectionDecreasing
};


@protocol SWStateMachineDelegate <NSObject>

- (void)stateMachineWantsDisplayTimerStarted:(SWStateMachine *)stateMachine;
// Delegate may call -displayTimerCompleted sometime between these two calls to show display.
- (void)stateMachineWantsDisplayTimerInvalidated:(SWStateMachine *)stateMachine;

- (void)stateMachine:(SWStateMachine *)stateMachine wantsWindowRaised:(SWWindow *)window;
- (void)stateMachine:(SWStateMachine *)stateMachine wantsWindowClosed:(SWWindow *)window;

@end


@interface SWStateMachine : NSObject

@property (nonatomic, readonly, assign, getter=wantsInterfaceVisible) _Bool interfaceVisible;
@property (nonatomic, readonly, assign, getter=wantsWindowListUpdates) _Bool windowListUpdates;

- (instancetype)initWithDelegate:(id<SWStateMachineDelegate>) delegate;

#pragma mark - Delegate responses
- (void)displayTimerCompleted;

#pragma mark - Keyboard interactions
// Key events return whether the event should be allowed to propagate.
- (_Bool)incrementWithInvoke:(_Bool)invokesInterface direction:(SWIncrementDirection)direction isRepeating:(_Bool)autorepeat;
- (_Bool)closeWindow;
- (_Bool)cancelInvocation;
- (void)endInvocation;

#pragma mark - GUI interactions
- (void)selectWindow:(SWWindow *)window;
- (void)activateWindow:(SWWindow *)window;

#pragma mark - Data updates
- (void)updateWindowList:(NSOrderedSet *)windowList;

@end

@interface SWStateMachine (Observables)

// Valid when .interfaceVisible == true or .pendingSwitch == true
@property (nonatomic, readonly, copy) NSOrderedSet *windowList;
// Valid when .interfaceVisible == true or .pendingSwitch == true
@property (nonatomic, readonly, copy) SWWindow *selectedWindow;

@property (nonatomic, readonly, assign) _Bool invoked;
@property (nonatomic, readonly, assign, getter=wantsDisplayTimer) _Bool displayTimer;
@property (nonatomic, readonly, assign) _Bool pendingSwitch;
@property (nonatomic, readonly, assign, getter=isActive) _Bool active;

@end
