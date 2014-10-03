//
//  SWWindowListServiceTests.m
//  Switch
//
//  Created by Scott Perry on 09/27/14.
//  Copyright © 2014 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWWindowListServiceTestSuperclass.h"


@interface SWWindowListService (Internal)

- (void)_updateWindowList:(NSArray *)windowInfoList;

@end


@interface SWWindowListServiceTests : SWWindowListServiceTestSuperclass

@end


@implementation SWWindowListServiceTests

- (void)testEmpty
{
    XCTAssertNil(self.listService.windows, @"");

    [self measureBlock:^{
        [self.listService _updateWindowList:@[]];
    }];
    XCTAssertEqualObjects(self.listService.windows, [NSOrderedSet new], @"");
}

- (void)testNormalDay
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

    [self measureBlock:^{
        [self.listService _updateWindowList:windowInfoList];
    }];

    XCTAssertEqual(6, self.listService.windows.count);
}

@end
