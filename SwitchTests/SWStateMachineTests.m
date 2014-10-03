//
//  SWStateMachineTests.m
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

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "SWStateMachine.h"
#import "SWWindowFilteringTests.h"
#import "SWWindow.h"
#import "SWWindowListService.h"
#import "SWTestApplication.h"


#ifndef MAX_TIME_PER_TEST
#define MAX_TIME_PER_TEST 1.0
#endif


@interface SWStateMachineTests : XCTestCase

+ (NSMutableOrderedSet *)windowList;

@property (nonatomic, readonly, strong) SWStateMachine *stateMachineUnderTest;
@property (nonatomic, readonly, strong) id<SWStateMachineDelegate> stateMachineDelegateMock;
@property (nonatomic, readwrite, assign, getter=isNiceMock) _Bool niceMock;

@property (nonatomic, readonly, assign) unsigned monkeyCount;

@end


static uint32_t (^die)(uint32_t sides) = ^(uint32_t sides){
    return arc4random_uniform(sides);
};

static _Bool (^coin)() = ^{
    return (_Bool)die(2);
};

static NSMutableOrderedSet *(^rwgs)() = ^{
    NSMutableOrderedSet *windowList = [SWStateMachineTests windowList];
    NSUInteger numWindows = coin(windowList.count + 1);

    if (numWindows == windowList.count) { return (NSMutableOrderedSet *)nil; }

    while (numWindows > windowList.count) {
        [windowList removeObjectAtIndex:die((uint32_t)windowList.count)];
    }

    return (NSMutableOrderedSet *)windowList;
};

static SWWindow *(^rwg)() = ^{
    return [rwgs() objectAtIndex:0];
};


@implementation SWStateMachineTests

- (void)setUp
{
    [super setUp];

    self.niceMock = false;
    self->_stateMachineDelegateMock = OCMStrictProtocolMock(@protocol(SWStateMachineDelegate));
    self->_stateMachineUnderTest = [SWStateMachine stateMachineWithDelegate:self.stateMachineDelegateMock];

    self->_monkeyCount = 15;

    self.continueAfterFailure = NO;
}

- (void)tearDown
{
    self->_stateMachineDelegateMock = nil;
    self->_stateMachineUnderTest = nil;

    [super tearDown];
}

+ (NSMutableOrderedSet *)windowList;
{
    NSArray *windowInfoList = @[
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 768,
                .size.width = 1366,
                .origin.x = 0,
                .origin.y = 0
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @101,
            NNWindowMemoryUsage : @4228348,
            NNWindowName : @"",
            NNWindowNumber : @1357,
            NNWindowOwnerName : @"Switch",
            NNWindowOwnerPID : @8392,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 22,
                .size.width = 30,
                .origin.x = 1161,
                .origin.y = 0
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @25,
            NNWindowMemoryUsage : @5372,
            NNWindowName : @"",
            NNWindowNumber : @1317,
            NNWindowOwnerName : @"Switch",
            NNWindowOwnerPID : @8392,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 0,
                .size.width = 0,
                .origin.x = 1260,
                .origin.y = 0
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @25,
            NNWindowMemoryUsage : @1276,
            NNWindowName : @"",
            NNWindowNumber : @1286,
            NNWindowOwnerName : @"Location Menu",
            NNWindowOwnerPID : @8287,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 0,
                .size.width = 0,
                .origin.x = 1260,
                .origin.y = 0
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @25,
            NNWindowMemoryUsage : @1276,
            NNWindowName : @"",
            NNWindowNumber : @45,
            NNWindowOwnerName : @"Dropbox",
            NNWindowOwnerPID : @222,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 0,
                .size.width = 0,
                .origin.x = 1161,
                .origin.y = 0
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @25,
            NNWindowMemoryUsage : @1276,
            NNWindowName : @"",
            NNWindowNumber : @51,
            NNWindowOwnerName : @"Alfred 2",
            NNWindowOwnerPID : @226,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 0,
                .size.width = 0,
                .origin.x = 1260,
                .origin.y = 0
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @25,
            NNWindowMemoryUsage : @1276,
            NNWindowName : @"",
            NNWindowNumber : @62,
            NNWindowOwnerName : @"SystemUIServer",
            NNWindowOwnerPID : @165,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 0,
                .size.width = 0,
                .origin.x = 1260,
                .origin.y = 0
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @25,
            NNWindowMemoryUsage : @1276,
            NNWindowName : @"",
            NNWindowNumber : @50,
            NNWindowOwnerName : @"CrashPlan menu bar",
            NNWindowOwnerPID : @227,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 22,
                .size.width = 24,
                .origin.x = 1342,
                .origin.y = 0
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @25,
            NNWindowMemoryUsage : @5372,
            NNWindowName : @"",
            NNWindowNumber : @44,
            NNWindowOwnerName : @"Bartender",
            NNWindowOwnerPID : @219,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 0,
                .size.width = 0,
                .origin.x = 1161,
                .origin.y = 0
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @25,
            NNWindowMemoryUsage : @1276,
            NNWindowName : @"",
            NNWindowNumber : @43,
            NNWindowOwnerName : @"Flux",
            NNWindowOwnerPID : @217,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 0,
                .size.width = 0,
                .origin.x = 1260,
                .origin.y = 0
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @25,
            NNWindowMemoryUsage : @1276,
            NNWindowName : @"",
            NNWindowNumber : @61,
            NNWindowOwnerName : @"SystemUIServer",
            NNWindowOwnerPID : @165,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 0,
                .size.width = 0,
                .origin.x = 1260,
                .origin.y = 0
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @25,
            NNWindowMemoryUsage : @1276,
            NNWindowName : @"",
            NNWindowNumber : @60,
            NNWindowOwnerName : @"SystemUIServer",
            NNWindowOwnerPID : @165,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 0,
                .size.width = 0,
                .origin.x = 1161,
                .origin.y = 0
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @25,
            NNWindowMemoryUsage : @1276,
            NNWindowName : @"",
            NNWindowNumber : @46,
            NNWindowOwnerName : @"1Password mini",
            NNWindowOwnerPID : @190,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 0,
                .size.width = 0,
                .origin.x = 1161,
                .origin.y = 0
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @25,
            NNWindowMemoryUsage : @1276,
            NNWindowName : @"",
            NNWindowNumber : @41,
            NNWindowOwnerName : @"Satellite Eyes",
            NNWindowOwnerPID : @242,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 22,
                .size.width = 69,
                .origin.x = 1191,
                .origin.y = 0
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @25,
            NNWindowMemoryUsage : @9468,
            NNWindowName : @"",
            NNWindowNumber : @59,
            NNWindowOwnerName : @"SystemUIServer",
            NNWindowOwnerPID : @165,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 22,
                .size.width = 30,
                .origin.x = 1260,
                .origin.y = 0
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @25,
            NNWindowMemoryUsage : @5372,
            NNWindowName : @"",
            NNWindowNumber : @58,
            NNWindowOwnerName : @"SystemUIServer",
            NNWindowOwnerPID : @165,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 0,
                .size.width = 0,
                .origin.x = 1260,
                .origin.y = 0
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @25,
            NNWindowMemoryUsage : @1276,
            NNWindowName : @"",
            NNWindowNumber : @57,
            NNWindowOwnerName : @"SystemUIServer",
            NNWindowOwnerPID : @165,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 22,
                .size.width = 52,
                .origin.x = 1290,
                .origin.y = 0
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @25,
            NNWindowMemoryUsage : @9468,
            NNWindowName : @"",
            NNWindowNumber : @56,
            NNWindowOwnerName : @"SystemUIServer",
            NNWindowOwnerPID : @165,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 0,
                .size.width = 0,
                .origin.x = 1342,
                .origin.y = 0
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @25,
            NNWindowMemoryUsage : @1276,
            NNWindowName : @"",
            NNWindowNumber : @25,
            NNWindowOwnerName : @"SystemUIServer",
            NNWindowOwnerPID : @165,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 0,
                .size.width = 0,
                .origin.x = 1161,
                .origin.y = 0
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @25,
            NNWindowMemoryUsage : @1276,
            NNWindowName : @"",
            NNWindowNumber : @39,
            NNWindowOwnerName : @"SystemUIServer",
            NNWindowOwnerPID : @165,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @0,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 22,
                .size.width = 1366,
                .origin.x = 0,
                .origin.y = 0
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @25,
            NNWindowMemoryUsage : @5372,
            NNWindowNumber : @40,
            NNWindowOwnerName : @"SystemUIServer",
            NNWindowOwnerPID : @165,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 0,
                .size.width = 0,
                .origin.x = 1366,
                .origin.y = 0
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @25,
            NNWindowMemoryUsage : @1276,
            NNWindowName : @"",
            NNWindowNumber : @38,
            NNWindowOwnerName : @"Notification Center",
            NNWindowOwnerPID : @188,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 22,
                .size.width = 1366,
                .origin.x = 0,
                .origin.y = 0
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @24,
            NNWindowMemoryUsage : @124156,
            NNWindowName : @"Menubar",
            NNWindowNumber : @12,
            NNWindowOwnerName : @"Window Server",
            NNWindowOwnerPID : @87,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 43,
                .size.width = 1261,
                .origin.x = 53,
                .origin.y = 798
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @19,
            NNWindowMemoryUsage : @222460,
            NNWindowName : @"Magic Mirror",
            NNWindowNumber : @1351,
            NNWindowOwnerName : @"Dock",
            NNWindowOwnerPID : @162,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 742,
                .size.width = 1366,
                .origin.x = 0,
                .origin.y = 22
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @4416340,
            NNWindowName : @"SWWindowListService.m",
            NNWindowNumber : @91,
            NNWindowOwnerName : @"Xcode",
            NNWindowOwnerPID : @415,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 317,
                .size.width = 744,
                .origin.x = 45,
                .origin.y = 34
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @46916,
            NNWindowName : @"Wreck-It Ralph",
            NNWindowNumber : @1355,
            NNWindowOwnerName : @"QuickTime Player",
            NNWindowOwnerPID : @8438,
            NNWindowSharingState : @1,
            NNWindowStoreType : @1,
        },
        @{
            NNWindowAlpha : @"0.8500000238418579",
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 10,
                .size.width = 503,
                .origin.x = 534,
                .origin.y = 60
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @21756,
            NNWindowNumber : @1342,
            NNWindowOwnerName : @"TextEdit",
            NNWindowOwnerPID : @8428,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 58,
                .size.width = 463,
                .origin.x = 553,
                .origin.y = 272
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @111868,
            NNWindowName : @"",
            NNWindowNumber : @1341,
            NNWindowOwnerName : @"TextEdit",
            NNWindowOwnerPID : @8428,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 319,
                .size.width = 489,
                .origin.x = 540,
                .origin.y = 60
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @636156,
            NNWindowName : @"Save",
            NNWindowNumber : @1336,
            NNWindowOwnerName : @"com.apple.appkit.xpc.openAndSav",
            NNWindowOwnerPID : @8436,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 319,
                .size.width = 490,
                .origin.x = 540,
                .origin.y = 60
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @806740,
            NNWindowName : @"Save",
            NNWindowNumber : @1337,
            NNWindowOwnerName : @"TextEdit",
            NNWindowOwnerPID : @8428,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 702,
                .size.width = 858,
                .origin.x = 356,
                .origin.y = 38
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @2484948,
            NNWindowName : @"Untitled.txt",
            NNWindowNumber : @1334,
            NNWindowOwnerName : @"TextEdit",
            NNWindowOwnerPID : @8428,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 698,
                .size.width = 1279,
                .origin.x = 0,
                .origin.y = 22
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @3661844,
            NNWindowName : @"untitled 16",
            NNWindowNumber : @754,
            NNWindowOwnerName : @"TextMate",
            NNWindowOwnerPID : @5985,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 698,
                .size.width = 1365,
                .origin.x = 0,
                .origin.y = 22
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @3932116,
            NNWindowName : @"untitled 12",
            NNWindowNumber : @755,
            NNWindowOwnerName : @"TextMate",
            NNWindowOwnerPID : @5985,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 422,
                .size.width = 1012,
                .origin.x = 73,
                .origin.y = 22
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @2167060,
            NNWindowName : @"~/C/Switch — fish",
            NNWindowNumber : @626,
            NNWindowOwnerName : @"Terminal",
            NNWindowOwnerPID : @3579,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        }
    ];

    NSOrderedSet *windowObjectList = [SWWindowListService filterInfoDictionariesToWindowObjects:windowInfoList];
    NSOrderedSet *windowList = [SWWindowListService filterWindowObjectsToWindowGroups:windowObjectList];

    if (!windowList) { abort(); }

    NSMutableOrderedSet *mutableList = [windowList isKindOfClass:[NSMutableOrderedSet class]] ? windowList : [windowList mutableCopy];
    SWWindow *firstWindow = [windowList firstObject];
    [mutableList removeObjectAtIndex:0];
    [((SWTestApplication *)firstWindow.application) setActive:YES];
    [mutableList insertObject:firstWindow atIndex:0];

    if(![((SWWindow *)[mutableList objectAtIndex:0]).application isActiveApplication]) { abort(); }

    return mutableList;
}

- (void)setNiceMock:(_Bool)niceMock;
{
    if (niceMock == self.niceMock) { return; }

    self->_stateMachineDelegateMock = niceMock
                                    ? OCMProtocolMock(@protocol(SWStateMachineDelegate))
                                    : OCMStrictProtocolMock(@protocol(SWStateMachineDelegate));
    self->_stateMachineUnderTest = [SWStateMachine stateMachineWithDelegate:self.stateMachineDelegateMock];
}

- (void)stateMachineInvokeWithDirection:(SWIncrementDirection)direction;
{
    if (self.stateMachineUnderTest.active) {
        [self.stateMachineUnderTest incrementWithInvoke:true direction:direction isRepeating:false];
        return;
    }

    // State machine is inactive, everything should be off.
    XCTAssertNil(self.stateMachineUnderTest.windowList);
    XCTAssertNil(self.stateMachineUnderTest.selectedWindow);

    XCTAssertFalse(self.stateMachineUnderTest.interfaceVisible);
    XCTAssertFalse(self.stateMachineUnderTest.windowListUpdates);
    XCTAssertFalse(self.stateMachineUnderTest.displayTimer);
    XCTAssertFalse(self.stateMachineUnderTest.pendingSwitch);
    XCTAssertFalse(self.stateMachineUnderTest.active);

    [self stateMachineExpectDisplayTimerStart:^{
        [self stateMachineExpectWindowListUpdates:true block:^{
            [self.stateMachineUnderTest incrementWithInvoke:true direction:direction isRepeating:false];
        }];
    }];

    XCTAssertNil(self.stateMachineUnderTest.windowList);
    XCTAssertNil(self.stateMachineUnderTest.selectedWindow);

    XCTAssertTrue(self.stateMachineUnderTest.active);
    XCTAssertTrue(self.stateMachineUnderTest.invoked);
    XCTAssertTrue(self.stateMachineUnderTest.windowListUpdates);
    XCTAssertTrue(self.stateMachineUnderTest.displayTimer);

    XCTAssertFalse(self.stateMachineUnderTest.pendingSwitch);
}

- (void)stateMachineShowUIWithWindowList:(NSOrderedSet *)windowList;
{
    if (!self.stateMachineUnderTest.active) {
        XCTFail(@"Call stateMachineInvokeWithDirection: before %@!", NSStringFromSelector(_cmd));
    }
    
    if (self.stateMachineUnderTest.interfaceVisible) { return; }

    [self _windowList:windowList];

    [self stateMachineExpectShowInterface:true block:^{
        [self _timer];
    }];
}

- (void)stateMachineInRaiseStateMonkey:(unsigned)iterations;
{
    @autoreleasepool {
        NSArray *monkeys = @[
            ^{
                // -> windowlist (with selectedwindow not first/active) ->
                NSMutableOrderedSet *windowList = rwgs();
                if ([[windowList objectAtIndex:0] isEqual:self.stateMachineUnderTest.selectedWindow]) {
                    SWWindow *tmp = windowList[0];
                    [windowList removeObjectAtIndex:0];
                    ((SWTestApplication *)tmp.application).active = false;
                    [windowList insertObject:tmp atIndex:0];
                }
                // If selectedWindow is firstWindow, make inactiveWindow and updateWindows
                XCTAssertNoThrow([self.stateMachineUnderTest updateWindowList:windowList]);
            },
            ^{
                // -> hotkey(invoking or no, inc or dec)+ -> (windowlist(any) | hotkey(invoking or no, inc or dec))* -> keyEventModifierReleased (selectedwindow not first/active) -> raise ->
                XCTAssertNoThrow([self.stateMachineUnderTest incrementWithInvoke:coin() direction:(coin() ? SWIncrementDirectionIncreasing : SWIncrementDirectionDecreasing) isRepeating:coin()]);
            
                for (unsigned i = die(self.monkeyCount); i < self.monkeyCount; ++i) {
                    if (coin()) {
                        XCTAssertNoThrow([self.stateMachineUnderTest incrementWithInvoke:coin() direction:(coin() ? SWIncrementDirectionIncreasing : SWIncrementDirectionDecreasing) isRepeating:coin()]);
                    } else {
                        XCTAssertNoThrow([self.stateMachineUnderTest updateWindowList:rwgs()]);
                    }
                }

                XCTAssertNoThrow([self.stateMachineUnderTest updateWindowList:[SWStateMachineTests windowList]]);
                XCTAssertNoThrow([self.stateMachineUnderTest incrementWithInvoke:coin() direction:(coin() ? SWIncrementDirectionIncreasing : SWIncrementDirectionDecreasing) isRepeating:coin()]);

                XCTAssertNotNil(self.stateMachineUnderTest.selectedWindow);

                // If selectedWindow is firstWindow, make inactiveWindow and updateWindows
                _Bool selectedWindowIsFirst = [self.stateMachineUnderTest.windowList indexOfObject:self.stateMachineUnderTest.selectedWindow] == 0;
                _Bool selectedWindowIsActive = [self.stateMachineUnderTest.selectedWindow.application isActiveApplication];
                if (selectedWindowIsActive && selectedWindowIsFirst) {
                    NSMutableOrderedSet *windowList = [SWStateMachineTests windowList];
                    SWWindow *tmp = windowList[0];
                    [windowList removeObjectAtIndex:0];
                    ((SWTestApplication *)tmp.application).active = false;
                    [windowList insertObject:tmp atIndex:0];
                    XCTAssertNoThrow([self.stateMachineUnderTest updateWindowList:windowList]);
                }

                OCMExpect([self.stateMachineDelegateMock stateMachine:self.stateMachineUnderTest wantsWindowRaised:self.stateMachineUnderTest.selectedWindow]);
                XCTAssertNoThrow([self.stateMachineUnderTest endInvocation]);
                [self mockVerify];
            }
        ];
    
        ((dispatch_block_t)[monkeys objectAtIndex:die((uint32_t)monkeys.count)])();
    
        if (--iterations) {
            [self stateMachineInRaiseStateMonkey:iterations];
        }
    }
}

- (void)stateMachineExpectDisplayTimerStart:(dispatch_block_t)block;
{
    OCMExpect([self.stateMachineDelegateMock stateMachineWantsDisplayTimerStarted:self.stateMachineUnderTest]);
    
    XCTAssertNoThrow(block());
    
    [self mockVerify];
}

- (void)stateMachineExpectDisplayTimerInvalidate:(dispatch_block_t)block;
{
    OCMExpect([self.stateMachineDelegateMock stateMachineWantsDisplayTimerInvalidated:self.stateMachineUnderTest]);
    
    XCTAssertNoThrow(block());
    
    [self mockVerify];
}

- (void)stateMachineExpectRaise:(dispatch_block_t)block;
{
    SWWindow *selectedWindow = self.stateMachineUnderTest.selectedWindow ?: [OCMArg any];
    
    OCMExpect([self.stateMachineDelegateMock stateMachine:self.stateMachineUnderTest wantsWindowRaised:selectedWindow]);
    
    XCTAssertNoThrow(block());
    
    [self mockVerify];
}

- (void)stateMachineExpectClose:(dispatch_block_t)block;
{
    OCMExpect([self.stateMachineDelegateMock stateMachine:self.stateMachineUnderTest wantsWindowClosed:self.stateMachineUnderTest.selectedWindow]);
    
    XCTAssertNoThrow(block());
    
    [self mockVerify];
}

- (void)stateMachineExpectShowInterface:(_Bool)showInterface block:(dispatch_block_t)block;
{
    XCTAssertNoThrow(block());

    XCTAssertEqual(self.stateMachineUnderTest.interfaceVisible, showInterface);
    [self mockVerify];
}

- (void)stateMachineExpectWindowListUpdates:(_Bool)updateWindowList block:(dispatch_block_t)block;
{
    XCTAssertNoThrow(block());

    XCTAssertEqual(self.stateMachineUnderTest.windowListUpdates, updateWindowList);
    [self mockVerify];
}

- (void)stateMachineCompletePendingRaise;
{
    @autoreleasepool {
        // What window group is selected?
        SWWindow *selectedGroup = self.stateMachineUnderTest.selectedWindow;
        XCTAssertNotNil(selectedGroup);
        if (!selectedGroup) { return; }
        
        // Make a new set of windows with that window first and active
        NSMutableOrderedSet *windowList = [NSMutableOrderedSet orderedSetWithOrderedSet:self.stateMachineUnderTest.windowList];
        [windowList removeObject:selectedGroup];
        ((SWTestApplication *)selectedGroup.application).active = YES;
        [windowList insertObject:selectedGroup atIndex:0];
        
        if (!self.stateMachineUnderTest.interfaceVisible) {
            // if !ui, expect invalidatetimer
            OCMExpect([self.stateMachineDelegateMock stateMachineWantsDisplayTimerInvalidated:self.stateMachineUnderTest]);
        }
        
        // expect nowantwindowupdates
        [self stateMachineExpectWindowListUpdates:false block:^{
            // updateWindowList:
            [self _windowList:windowList];
        }];
        XCTAssertFalse(self.stateMachineUnderTest.interfaceVisible);
    }
}

- (void)mockVerify;
{
    OCMVerifyAll((OCMockObject *)self.stateMachineDelegateMock);
}

- (void)recordFailureWithDescription:(NSString *)description inFile:(NSString *)filePath atLine:(NSUInteger)lineNumber expected:(BOOL)expected;
{
    [super recordFailureWithDescription:description inFile:filePath atLine:lineNumber expected:expected];
}

#pragma mark - Events that do not invoke the state machine should not perturb it

- (void)testNonInvokingEventKeyEventIncreasingNonRepeating;
{
    XCTAssertTrue([self.stateMachineUnderTest incrementWithInvoke:false direction:SWIncrementDirectionIncreasing isRepeating:false]);
    
    XCTAssertNil(self.stateMachineUnderTest.windowList);
    XCTAssertNil(self.stateMachineUnderTest.selectedWindow);
    [self mockVerify];
    
    // Verify that the state machine is ok by running a common-case invoking test.
    [self testInvokeWindowListTimerKeyReleased];
}

- (void)testNonInvokingEventKeyEventIncreasingRepeating;
{
    XCTAssertTrue([self.stateMachineUnderTest incrementWithInvoke:false direction:SWIncrementDirectionIncreasing isRepeating:true]);
    
    XCTAssertNil(self.stateMachineUnderTest.windowList);
    XCTAssertNil(self.stateMachineUnderTest.selectedWindow);
    [self mockVerify];

    // Verify that the state machine is ok by running a common-case invoking test.
    [self testInvokeWindowListTimerKeyReleased];
}

- (void)testNonInvokingEventKeyEventDecreasingNonRepeating;
{
    XCTAssertTrue([self.stateMachineUnderTest incrementWithInvoke:false direction:SWIncrementDirectionDecreasing isRepeating:false]);
    
    XCTAssertNil(self.stateMachineUnderTest.windowList);
    XCTAssertNil(self.stateMachineUnderTest.selectedWindow);
    [self mockVerify];

    // Verify that the state machine is ok by running a common-case invoking test.
    [self testInvokeWindowListTimerKeyReleased];
}

- (void)testNonInvokingEventKeyEventDecreasingRepeating;
{
    XCTAssertTrue([self.stateMachineUnderTest incrementWithInvoke:false direction:SWIncrementDirectionDecreasing isRepeating:true]);
    
    XCTAssertNil(self.stateMachineUnderTest.windowList);
    XCTAssertNil(self.stateMachineUnderTest.selectedWindow);
    [self mockVerify];

    // Verify that the state machine is ok by running a common-case invoking test.
    [self testInvokeWindowListTimerKeyReleased];
}

- (void)testNonInvokingEventKeyEventCancelInvocation;
{
    XCTAssertTrue([self.stateMachineUnderTest cancelInvocation]);
    
    XCTAssertNil(self.stateMachineUnderTest.windowList);
    XCTAssertNil(self.stateMachineUnderTest.selectedWindow);
    [self mockVerify];

    // Verify that the state machine is ok by running a common-case invoking test.
    [self testInvokeWindowListTimerKeyReleased];
}

- (void)testNonInvokingEventKeyEventCloseWindow;
{
    XCTAssertTrue([self.stateMachineUnderTest closeWindow]);
    
    XCTAssertNil(self.stateMachineUnderTest.windowList);
    XCTAssertNil(self.stateMachineUnderTest.selectedWindow);
    [self mockVerify];

    // Verify that the state machine is ok by running a common-case invoking test.
    [self testInvokeWindowListTimerKeyReleased];
}

- (void)testNonInvokingEventKeyEventEndInvocation;
{
    [self.stateMachineUnderTest endInvocation];
    
    XCTAssertNil(self.stateMachineUnderTest.windowList);
    XCTAssertNil(self.stateMachineUnderTest.selectedWindow);
    [self mockVerify];

    // Verify that the state machine is ok by running a common-case invoking test.
    [self testInvokeWindowListTimerKeyReleased];
}

- (void)testUnexpectedEventDisplayTimerCompleted;
{
    [self.stateMachineUnderTest displayTimerCompleted];
    
    XCTAssertNil(self.stateMachineUnderTest.windowList);
    XCTAssertNil(self.stateMachineUnderTest.selectedWindow);
    [self mockVerify];

    // Verify that the state machine is ok by running a common-case invoking test.
    [self testInvokeWindowListTimerKeyReleased];
}

- (void)testUnexpectedEventMouseSelection;
{
    [self.stateMachineUnderTest selectWindow:nil];
    
    XCTAssertNil(self.stateMachineUnderTest.windowList);
    XCTAssertNil(self.stateMachineUnderTest.selectedWindow);
    [self mockVerify];

    // Verify that the state machine is ok by running a common-case invoking test.
    [self testInvokeWindowListTimerKeyReleased];
}

#pragma mark Illegal commands to the state machine

- (void)testIllegalEventMouseSelectedInvalidWindow;
{
    NSMutableOrderedSet *windowList = [[self class] windowList];
    SWWindow *window = [windowList lastObject];
    [windowList removeObjectAtIndex:(windowList.count - 1)];

    [self stateMachineInvokeWithDirection:SWIncrementDirectionDecreasing];
    [self stateMachineShowUIWithWindowList:windowList];

    XCTAssertNoThrow([self.stateMachineUnderTest selectWindow:window]);
    XCTAssertNil(self.stateMachineUnderTest.selectedWindow);

    [self.stateMachineUnderTest incrementWithInvoke:false direction:SWIncrementDirectionIncreasing isRepeating:false];
    XCTAssertEqualObjects(self.stateMachineUnderTest.selectedWindow, windowList[0]);
}

- (void)testIllegalEventMouseActivatedInvalidWindow;
{
    NSMutableOrderedSet *windowList = [[self class] windowList];
    SWWindow *window = [windowList lastObject];
    [windowList removeObjectAtIndex:(windowList.count - 1)];

    [self stateMachineInvokeWithDirection:SWIncrementDirectionDecreasing];
    [self stateMachineShowUIWithWindowList:windowList];

    XCTAssertNoThrow([self.stateMachineUnderTest activateWindow:window]);
    XCTAssertNil(self.stateMachineUnderTest.selectedWindow);

    [self.stateMachineUnderTest incrementWithInvoke:false direction:SWIncrementDirectionDecreasing isRepeating:false];
    XCTAssertEqualObjects(self.stateMachineUnderTest.selectedWindow, [windowList lastObject]);
}

#pragma mark Common real life edge cases

- (void)testRaiseEmptyWindowList;
{
    [self stateMachineInvokeWithDirection:SWIncrementDirectionIncreasing];
    [self.stateMachineUnderTest updateWindowList:[NSOrderedSet new]];
    XCTAssertEqualObjects(self.stateMachineUnderTest.windowList, [NSOrderedSet new]);
    XCTAssertNil(self.stateMachineUnderTest.selectedWindow);
    
    [self stateMachineExpectWindowListUpdates:false block:^{
        [self stateMachineExpectDisplayTimerInvalidate:^{
            [self.stateMachineUnderTest endInvocation];
        }];
    }];
}

- (void)testRaiseFirstWindowAlreadyActive;
{
    [self stateMachineInvokeWithDirection:SWIncrementDirectionIncreasing];
    [self.stateMachineUnderTest incrementWithInvoke:false direction:SWIncrementDirectionDecreasing isRepeating:false];

    NSOrderedSet *windowList = [[self class] windowList];
    XCTAssertTrue([((SWWindow *)[windowList objectAtIndex:0]).application isActiveApplication]);
    [self _windowList:windowList];

    [self stateMachineExpectDisplayTimerInvalidate:^{
        [self stateMachineExpectWindowListUpdates:false block:^{
            [self _keyReleased];
        }];
    }];
}

- (void)testInvocationSelectsFirstWindowIfInactive;
{
    [self stateMachineInvokeWithDirection:SWIncrementDirectionIncreasing];

    NSMutableOrderedSet *windowList = [[self class] windowList];
    SWWindow *firstWindow = [windowList objectAtIndex:0];
    [windowList removeObjectAtIndex:0];
    ((SWTestApplication *)firstWindow.application).active = NO;
    [windowList insertObject:firstWindow atIndex:0];
    XCTAssertFalse([((SWWindow *)[windowList objectAtIndex:0]).application isActiveApplication]);

    [self _windowList:windowList];

    [self stateMachineExpectRaise:^{
        [self _keyReleased];
        XCTAssertEqualObjects(self.stateMachineUnderTest.selectedWindow, [windowList objectAtIndex:0]);
    }];
}

- (void)testInvocationSelectsSecondWindowIfFirstIsActive;
{
    [self stateMachineInvokeWithDirection:SWIncrementDirectionIncreasing];

    NSOrderedSet *windowList = [[self class] windowList];
    XCTAssertTrue([((SWWindow *)[windowList objectAtIndex:0]).application isActiveApplication]);
    [self _windowList:windowList];

    [self stateMachineExpectRaise:^{
        [self _keyReleased];
        XCTAssertEqualObjects(self.stateMachineUnderTest.selectedWindow, [windowList objectAtIndex:1]);
    }];
}

- (void)testLastWindowSelectedOnDecInvocation;
{
    NSOrderedSet *windowList = [[self class] windowList];
    [self stateMachineInvokeWithDirection:SWIncrementDirectionDecreasing];
    [self stateMachineShowUIWithWindowList:windowList];

    [self stateMachineExpectRaise:^{
        [self _keyReleased];
        XCTAssertEqualObjects(self.stateMachineUnderTest.selectedWindow, [windowList lastObject]);
    }];
}

- (void)testNonAutorepeatIncrementingWraps;
{
    NSOrderedSet *windowList = [[self class] windowList];
    [self stateMachineInvokeWithDirection:SWIncrementDirectionIncreasing];
    [self stateMachineShowUIWithWindowList:windowList];

    for (sw_unused id window in windowList) {
        [self.stateMachineUnderTest incrementWithInvoke:false direction:SWIncrementDirectionIncreasing isRepeating:false];
    }
    XCTAssertEqualObjects(self.stateMachineUnderTest.selectedWindow, windowList[1]);
}

- (void)testNonAutorepeatDecrementingWraps;
{
    NSOrderedSet *windowList = [[self class] windowList];
    [self stateMachineInvokeWithDirection:SWIncrementDirectionIncreasing];
    [self stateMachineShowUIWithWindowList:windowList];

    for (sw_unused id window in windowList) {
        [self.stateMachineUnderTest incrementWithInvoke:false direction:SWIncrementDirectionDecreasing isRepeating:false];
    }
    XCTAssertEqualObjects(self.stateMachineUnderTest.selectedWindow, windowList[1]);
}

- (void)testAutorepeatIncrementingDoesNotWrap;
{
    NSOrderedSet *windowList = [[self class] windowList];
    [self stateMachineInvokeWithDirection:SWIncrementDirectionIncreasing];
    [self stateMachineShowUIWithWindowList:windowList];

    for (sw_unused id window in windowList) {
        [self.stateMachineUnderTest incrementWithInvoke:false direction:SWIncrementDirectionIncreasing isRepeating:true];
    }
    XCTAssertEqualObjects(self.stateMachineUnderTest.selectedWindow, [windowList lastObject]);
}

- (void)testAutorepeatDecrementingDoesNotWrap;
{
    NSOrderedSet *windowList = [[self class] windowList];
    [self stateMachineInvokeWithDirection:SWIncrementDirectionIncreasing];
    [self stateMachineShowUIWithWindowList:windowList];

    [self.stateMachineUnderTest incrementWithInvoke:false direction:SWIncrementDirectionIncreasing isRepeating:true];

    for (sw_unused id window in windowList) {
        [self.stateMachineUnderTest incrementWithInvoke:false direction:SWIncrementDirectionDecreasing isRepeating:true];
    }
    XCTAssertEqualObjects(self.stateMachineUnderTest.selectedWindow, windowList[0]);
}

- (void)testNilFirstWindowListUpdate;
{
    [self stateMachineInvokeWithDirection:SWIncrementDirectionIncreasing];
    XCTAssertNoThrow([self.stateMachineUnderTest updateWindowList:nil]);
    [self _windowList:nil];

    [self stateMachineExpectShowInterface:true block:^{
        [self _timer];
    }];

    [self stateMachineExpectRaise:^{
        [self _keyReleased];
    }];
}

#pragma mark Different paths to single-hotkey raise events

- (void)_timer;
{
    XCTAssertNoThrow([self.stateMachineUnderTest displayTimerCompleted]);
};

- (void)_windowList:(NSOrderedSet *)windowList;
{
    @autoreleasepool {
        if (windowList == nil) {
            windowList = [[self class] windowList];
        }

        XCTAssertNoThrow([self.stateMachineUnderTest updateWindowList:windowList]);
    }
}

- (void)_keyReleased;
{
    XCTAssertNoThrow([self.stateMachineUnderTest endInvocation]);
}

// invoke: -> timer -> windowlist -> wantsDisplay -> keyEventModifierReleased -> raise -> YYY
- (void)testInvokeTimerWindowListKeyReleased;
{
    [self stateMachineInvokeWithDirection:SWIncrementDirectionIncreasing];
    
    [self _timer];
    
    // Remember: if (!showingUI) expectWantsDisplay
    if (!self.stateMachineUnderTest.interfaceVisible) {
        [self stateMachineExpectShowInterface:true block:^{
            [self _windowList:nil];
        }];
    } else {
        [self _windowList:nil];
    }
    
    [self stateMachineExpectRaise:^{
        [self _keyReleased];
    }];
}

// invoke: -> windowlist -> timer -> wantsDisplay -> keyEventModifierReleased -> raise -> YYY
- (void)testInvokeWindowListTimerKeyReleased;
{
    [self stateMachineInvokeWithDirection:SWIncrementDirectionIncreasing];
    
    [self _windowList:nil];
    
    // Remember: if (!showingUI) expectWantsDisplay
    if (!self.stateMachineUnderTest.interfaceVisible) {
        [self stateMachineExpectShowInterface:true block:^{
            [self _timer];
        }];
    } else {
        [self _timer];
    }
    
    [self stateMachineExpectRaise:^{
        [self _keyReleased];
    }];
}

// invoke: -> windowlist -> keyEventModifierReleased -> raise -> timer -> wantsDisplay -> YYY
- (void)testInvokeWindowListKeyReleasedTimer;
{
    [self stateMachineInvokeWithDirection:SWIncrementDirectionIncreasing];
    
    [self _windowList:nil];
    
    [self stateMachineExpectRaise:^{
        [self _keyReleased];
    }];

    // Remember: if (!showingUI) expectWantsDisplay
    if (!self.stateMachineUnderTest.interfaceVisible) {
        [self stateMachineExpectShowInterface:true block:^{
            [self _timer];
        }];
    } else {
        [self _timer];
    }
}

// invoke: -> keyEventModifierReleased -> windowlist -> raise -> timer -> wantsDisplay -> YYY
- (void)testInvokeKeyReleasedWindowListTimer;
{
    [self stateMachineInvokeWithDirection:SWIncrementDirectionIncreasing];

    [self _keyReleased];
    [self stateMachineExpectRaise:^{
        [self _windowList:nil];
    }];

    // Remember: if (!showingUI) expectWantsDisplay
    if (!self.stateMachineUnderTest.interfaceVisible) {
        [self stateMachineExpectShowInterface:true block:^{
            [self _timer];
        }];
    } else {
        [self _timer];
    }
}

// invoke: -> keyEventModifierReleased -> timer -> windowlist -> wantsDisplay/raise -> YYY
- (void)testInvokeKeyReleasedTimerWindowList;
{
    [self stateMachineInvokeWithDirection:SWIncrementDirectionIncreasing];
    
    [self _keyReleased];
    
    [self _timer];

    [self stateMachineExpectRaise:^{
        // Remember: if (!showingUI) expectWantsDisplay
        if (!self.stateMachineUnderTest.interfaceVisible) {
            [self stateMachineExpectShowInterface:true block:^{
                [self _windowList:nil];
            }];
        } else {
            [self _windowList:nil];
        }
    }];
}

// invoke: -> timer -> keyEventModifierReleased -> windowlist -> raise/wantsDisplay -> YYY
- (void)testInvokeTimerKeyReleasedWindowList;
{
    [self stateMachineInvokeWithDirection:SWIncrementDirectionIncreasing];
    
    [self _timer];

    [self _keyReleased];
    
    [self stateMachineExpectRaise:^{
        // Remember: if (!showingUI) expectWantsDisplay
        if (!self.stateMachineUnderTest.interfaceVisible) {
            [self stateMachineExpectShowInterface:true block:^{
                [self _windowList:nil];
            }];
        } else {
            [self _windowList:nil];
        }
    }];
}

// invoke: -> keyEventModifierReleased -> windowlist -> raise -> YYY
- (void)testInvokeKeyReleasedWindowList;
{
    [self stateMachineInvokeWithDirection:SWIncrementDirectionIncreasing];
    
    [self _keyReleased];
    
    [self stateMachineExpectRaise:^{
        [self _windowList:nil];
    }];
}

// invoke: -> windowlist -> keyEventModifierReleased -> raise -> YYY
- (void)testInvokeWindowListKeyReleased;
{
    [self stateMachineInvokeWithDirection:SWIncrementDirectionIncreasing];
    
    [self _windowList:nil];
    
    [self stateMachineExpectRaise:^{
        [self _keyReleased];
    }];
}

#pragma mark Other paths to de-invocation

- (void)testDismissalByMouseActivation;
{
    NSOrderedSet *windowList = [[self class] windowList];
    [self stateMachineInvokeWithDirection:SWIncrementDirectionDecreasing];
    [self stateMachineShowUIWithWindowList:windowList];

    [self stateMachineExpectRaise:^{
        [self.stateMachineUnderTest activateWindow:[windowList lastObject]];
    }];
}

- (void)testUIDismissalByCancelHotkey;
{
    [self stateMachineInvokeWithDirection:SWIncrementDirectionIncreasing];
    [self stateMachineShowUIWithWindowList:nil];
    [self stateMachineExpectShowInterface:false block:^{
        [self stateMachineExpectWindowListUpdates:false block:^{
            [self.stateMachineUnderTest cancelInvocation];
        }];
    }];
}

- (void)testDismissalByCancelHotkey;
{
    [self stateMachineInvokeWithDirection:SWIncrementDirectionIncreasing];

    [self stateMachineExpectDisplayTimerInvalidate:^{
        [self stateMachineExpectWindowListUpdates:false block:^{
            [self.stateMachineUnderTest cancelInvocation];
        }];
    }];
}

#pragma mark Compound tests executing end-to-end usage

- (void)ptestInvokeTimerWindowListKeyReleasedSuccessfulRaise;
{
    [self testInvokeTimerWindowListKeyReleased];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeWindowListTimerKeyReleasedSuccessfulRaise;
{
    [self testInvokeWindowListTimerKeyReleased];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeWindowListKeyReleasedTimerSuccessfulRaise;
{
    [self testInvokeWindowListKeyReleasedTimer];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeKeyReleasedWindowListTimerSuccessfulRaise;
{
    [self testInvokeKeyReleasedWindowListTimer];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeKeyReleasedTimerWindowListSuccessfulRaise;
{
    [self testInvokeKeyReleasedTimerWindowList];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeTimerKeyReleasedWindowListSuccessfulRaise;
{
    [self testInvokeTimerKeyReleasedWindowList];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeKeyReleasedWindowListSuccessfulRaise;
{
    [self testInvokeKeyReleasedWindowList];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeWindowListKeyReleasedSuccessfulRaise;
{
    [self testInvokeWindowListKeyReleased];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeTimerWindowListKeyReleasedSuccessfulRaiseTwice;
{
    [self testInvokeTimerWindowListKeyReleased];
    [self stateMachineCompletePendingRaise];
    [self testInvokeTimerWindowListKeyReleased];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeWindowListTimerKeyReleasedSuccessfulRaiseTwice;
{
    [self testInvokeWindowListTimerKeyReleased];
    [self stateMachineCompletePendingRaise];
    [self testInvokeWindowListTimerKeyReleased];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeWindowListKeyReleasedTimerSuccessfulRaiseTwice;
{
    [self testInvokeWindowListKeyReleasedTimer];
    [self stateMachineCompletePendingRaise];
    [self testInvokeWindowListKeyReleasedTimer];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeKeyReleasedWindowListTimerSuccessfulRaiseTwice;
{
    [self testInvokeKeyReleasedWindowListTimer];
    [self stateMachineCompletePendingRaise];
    [self testInvokeKeyReleasedWindowListTimer];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeKeyReleasedTimerWindowListSuccessfulRaiseTwice;
{
    [self testInvokeKeyReleasedTimerWindowList];
    [self stateMachineCompletePendingRaise];
    [self testInvokeKeyReleasedTimerWindowList];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeTimerKeyReleasedWindowListSuccessfulRaiseTwice;
{
    [self testInvokeTimerKeyReleasedWindowList];
    [self stateMachineCompletePendingRaise];
    [self testInvokeTimerKeyReleasedWindowList];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeKeyReleasedWindowListSuccessfulRaiseTwice;
{
    [self testInvokeKeyReleasedWindowList];
    [self stateMachineCompletePendingRaise];
    [self testInvokeKeyReleasedWindowList];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeWindowListKeyReleasedSuccessfulRaiseTwice;
{
    [self testInvokeWindowListKeyReleased];
    [self stateMachineCompletePendingRaise];
    [self testInvokeWindowListKeyReleased];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeTimerWindowListKeyReleasedSuccessfulRaiseInterrupted;
{
    [self testInvokeTimerWindowListKeyReleased];
    [self testInvokeTimerWindowListKeyReleased];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeWindowListTimerKeyReleasedSuccessfulRaiseInterrupted;
{
    [self testInvokeWindowListTimerKeyReleased];
    [self testInvokeWindowListTimerKeyReleased];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeWindowListKeyReleasedTimerSuccessfulRaiseInterrupted;
{
    [self testInvokeWindowListKeyReleasedTimer];
    [self testInvokeWindowListKeyReleasedTimer];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeWindowListKeyReleasedSuccessfulRaiseInterrupted;
{
    [self testInvokeWindowListKeyReleased];
    [self testInvokeWindowListKeyReleased];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeTimerWindowListKeyReleasedSuccessfulRaiseWithMonkey;
{
    [self testInvokeTimerWindowListKeyReleased];
    [self stateMachineInRaiseStateMonkey:self.monkeyCount];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeWindowListTimerKeyReleasedSuccessfulRaiseWithMonkey;
{
    [self testInvokeWindowListTimerKeyReleased];
    [self stateMachineInRaiseStateMonkey:self.monkeyCount];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeWindowListKeyReleasedTimerSuccessfulRaiseWithMonkey;
{
    [self testInvokeWindowListKeyReleasedTimer];
    [self stateMachineInRaiseStateMonkey:self.monkeyCount];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeKeyReleasedWindowListTimerSuccessfulRaiseWithMonkey;
{
    [self testInvokeKeyReleasedWindowListTimer];
    [self stateMachineInRaiseStateMonkey:self.monkeyCount];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeKeyReleasedTimerWindowListSuccessfulRaiseWithMonkey;
{
    [self testInvokeKeyReleasedTimerWindowList];
    [self stateMachineInRaiseStateMonkey:self.monkeyCount];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeTimerKeyReleasedWindowListSuccessfulRaiseWithMonkey;
{
    [self testInvokeTimerKeyReleasedWindowList];
    [self stateMachineInRaiseStateMonkey:self.monkeyCount];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeKeyReleasedWindowListSuccessfulRaiseWithMonkey;
{
    [self testInvokeKeyReleasedWindowList];
    [self stateMachineInRaiseStateMonkey:self.monkeyCount];
    [self stateMachineCompletePendingRaise];
}

- (void)ptestInvokeWindowListKeyReleasedSuccessfulRaiseWithMonkey;
{
    [self testInvokeWindowListKeyReleased];
    [self stateMachineInRaiseStateMonkey:self.monkeyCount];
    [self stateMachineCompletePendingRaise];
}

- (void)testAllParalellTests;
{
    NSArray *ptests = @[
        @"ptestInvokeTimerWindowListKeyReleasedSuccessfulRaise",
        @"ptestInvokeWindowListTimerKeyReleasedSuccessfulRaise",
        @"ptestInvokeWindowListKeyReleasedTimerSuccessfulRaise",
        @"ptestInvokeKeyReleasedWindowListTimerSuccessfulRaise",
        @"ptestInvokeKeyReleasedTimerWindowListSuccessfulRaise",
        @"ptestInvokeTimerKeyReleasedWindowListSuccessfulRaise",
        @"ptestInvokeKeyReleasedWindowListSuccessfulRaise",
        @"ptestInvokeWindowListKeyReleasedSuccessfulRaise",
        @"ptestInvokeTimerWindowListKeyReleasedSuccessfulRaiseTwice",
        @"ptestInvokeWindowListTimerKeyReleasedSuccessfulRaiseTwice",
        @"ptestInvokeWindowListKeyReleasedTimerSuccessfulRaiseTwice",
        @"ptestInvokeKeyReleasedWindowListTimerSuccessfulRaiseTwice",
        @"ptestInvokeKeyReleasedTimerWindowListSuccessfulRaiseTwice",
        @"ptestInvokeTimerKeyReleasedWindowListSuccessfulRaiseTwice",
        @"ptestInvokeKeyReleasedWindowListSuccessfulRaiseTwice",
        @"ptestInvokeWindowListKeyReleasedSuccessfulRaiseTwice",
        @"ptestInvokeTimerWindowListKeyReleasedSuccessfulRaiseInterrupted",
        @"ptestInvokeWindowListTimerKeyReleasedSuccessfulRaiseInterrupted",
        @"ptestInvokeWindowListKeyReleasedTimerSuccessfulRaiseInterrupted",
        @"ptestInvokeWindowListKeyReleasedSuccessfulRaiseInterrupted",
        @"ptestInvokeTimerWindowListKeyReleasedSuccessfulRaiseWithMonkey",
        @"ptestInvokeWindowListTimerKeyReleasedSuccessfulRaiseWithMonkey",
        @"ptestInvokeWindowListKeyReleasedTimerSuccessfulRaiseWithMonkey",
        @"ptestInvokeKeyReleasedWindowListTimerSuccessfulRaiseWithMonkey",
        @"ptestInvokeKeyReleasedTimerWindowListSuccessfulRaiseWithMonkey",
        @"ptestInvokeTimerKeyReleasedWindowListSuccessfulRaiseWithMonkey",
        @"ptestInvokeKeyReleasedWindowListSuccessfulRaiseWithMonkey",
        @"ptestInvokeWindowListKeyReleasedSuccessfulRaiseWithMonkey",
    ];

    #warning Running tests in parallel doesn't work. Judging from the backtraces RAC is getting confused somewhere?
    dispatch_queue_t queue = dispatch_queue_create("thing", DISPATCH_QUEUE_SERIAL);
    // For a Good Time™, uncomment the line below. The tests fail in unexpected ways, and occasionally the testrunner will crash in the RAC scheduler queue.
//    queue = dispatch_get_global_queue(0, 0);

    dispatch_apply(ptests.count, queue, ^(size_t i) {
        NSLog(@"Test case %@ started.", ptests[i]);
        SWStateMachineTests *test = [SWStateMachineTests testCaseWithSelector:NSSelectorFromString(ptests[i])];
        [test setUp];
        XCTAssertNoThrow([test invokeTest]);
        [test tearDown];
        NSLog(@"Test case %@ finished.", ptests[i]);
    });
}

- (void)testAllSuccessfulRaiseTestsAgainstSameStateMachine;
{
    [self ptestInvokeTimerWindowListKeyReleasedSuccessfulRaise];
    [self ptestInvokeWindowListTimerKeyReleasedSuccessfulRaise];
    [self ptestInvokeWindowListKeyReleasedTimerSuccessfulRaise];
    [self ptestInvokeKeyReleasedWindowListTimerSuccessfulRaise];
    [self ptestInvokeKeyReleasedTimerWindowListSuccessfulRaise];
    [self ptestInvokeTimerKeyReleasedWindowListSuccessfulRaise];
    [self ptestInvokeKeyReleasedWindowListSuccessfulRaise];
    [self ptestInvokeWindowListKeyReleasedSuccessfulRaise];
    [self ptestInvokeTimerWindowListKeyReleasedSuccessfulRaiseTwice];
    [self ptestInvokeWindowListTimerKeyReleasedSuccessfulRaiseTwice];
    [self ptestInvokeWindowListKeyReleasedTimerSuccessfulRaiseTwice];
    [self ptestInvokeKeyReleasedWindowListTimerSuccessfulRaiseTwice];
    [self ptestInvokeKeyReleasedTimerWindowListSuccessfulRaiseTwice];
    [self ptestInvokeTimerKeyReleasedWindowListSuccessfulRaiseTwice];
    [self ptestInvokeKeyReleasedWindowListSuccessfulRaiseTwice];
    [self ptestInvokeWindowListKeyReleasedSuccessfulRaiseTwice];
    [self ptestInvokeTimerWindowListKeyReleasedSuccessfulRaiseInterrupted];
    [self ptestInvokeWindowListTimerKeyReleasedSuccessfulRaiseInterrupted];
    [self ptestInvokeWindowListKeyReleasedTimerSuccessfulRaiseInterrupted];
    [self ptestInvokeWindowListKeyReleasedSuccessfulRaiseInterrupted];
    [self ptestInvokeTimerWindowListKeyReleasedSuccessfulRaiseWithMonkey];
    [self ptestInvokeWindowListTimerKeyReleasedSuccessfulRaiseWithMonkey];
    [self ptestInvokeWindowListKeyReleasedTimerSuccessfulRaiseWithMonkey];
    [self ptestInvokeKeyReleasedWindowListTimerSuccessfulRaiseWithMonkey];
    [self ptestInvokeKeyReleasedTimerWindowListSuccessfulRaiseWithMonkey];
    [self ptestInvokeTimerKeyReleasedWindowListSuccessfulRaiseWithMonkey];
    [self ptestInvokeKeyReleasedWindowListSuccessfulRaiseWithMonkey];
    [self ptestInvokeWindowListKeyReleasedSuccessfulRaiseWithMonkey];
}

- (void)testAllAPIAtRandom;
{
    self.niceMock = true;

    NSArray *tests = @[
        ^{ (void)self.stateMachineUnderTest.windowList; },
        ^{ (void)self.stateMachineUnderTest.selectedWindow; },
        ^{ [self.stateMachineUnderTest displayTimerCompleted]; },
        ^{ [self.stateMachineUnderTest displayTimerCompleted]; },
        ^{ [self.stateMachineUnderTest incrementWithInvoke:coin() direction:(coin() ? SWIncrementDirectionIncreasing : SWIncrementDirectionDecreasing) isRepeating:coin()]; },
        ^{ [self.stateMachineUnderTest incrementWithInvoke:coin() direction:(coin() ? SWIncrementDirectionIncreasing : SWIncrementDirectionDecreasing) isRepeating:coin()]; },
        ^{ [self.stateMachineUnderTest incrementWithInvoke:coin() direction:(coin() ? SWIncrementDirectionIncreasing : SWIncrementDirectionDecreasing) isRepeating:coin()]; },
        ^{ [self.stateMachineUnderTest closeWindow]; },
        ^{ [self.stateMachineUnderTest cancelInvocation]; },
        ^{ [self.stateMachineUnderTest endInvocation]; },
        ^{ [self.stateMachineUnderTest selectWindow:rwg()]; },
        ^{ [self.stateMachineUnderTest activateWindow:rwg()]; },
        ^{ [self.stateMachineUnderTest updateWindowList:rwgs()]; },
        ^{ [self.stateMachineUnderTest updateWindowList:rwgs()]; },
        ^{ [self.stateMachineUnderTest updateWindowList:rwgs()]; },
    ];

    unsigned iterations = 0;
    NSDate *start = [NSDate date];
    while (-[start timeIntervalSinceNow] < MAX_TIME_PER_TEST) {
        @autoreleasepool {
            for (unsigned i = 0; i < tests.count; ++i) {
                iterations++;
                XCTAssertNoThrow(((dispatch_block_t)tests[die((uint32_t)tests.count)])());
            }
        }
    }
    NSLog(@"Ran %u iterations of random API tests", iterations);
}

@end
