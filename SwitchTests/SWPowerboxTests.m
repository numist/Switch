//
//  SWPowerboxTests.m
//  Switch
//
//  Created by Scott Perry on 10/11/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWWindowListServiceTests.h"


@interface SWPowerboxTests : SWWindowListServiceTests

@end


@implementation SWPowerboxTests

// https://github.com/numist/Switch/issues/10
- (void)testPowerboxSaveDialog_10_9_Seed;
{
    NSDictionary *windowDescription = @{
        NNWindowAlpha : @1,
        NNWindowBounds : DICT_FROM_RECT(((CGRect){
            .size.height = 412,
            .size.width = 640,
            .origin.x = 147,
            .origin.y = 47
        })),
        NNWindowIsOnscreen : @1,
        NNWindowLayer : @0,
        NNWindowMemoryUsage : @1110708,
        NNWindowName : @"Untitled.txt",
        NNWindowNumber : @33261,
        NNWindowOwnerName : @"TextEdit",
        NNWindowOwnerPID : @75652,
        NNWindowSharingState : @1,
        NNWindowStoreType : @2,
    };
    NSArray *infoList = @[
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 58,
                .size.width = 423,
                .origin.x = 256,
                .origin.y = 255
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @21788,
            NNWindowName : @"",
            NNWindowNumber : @33264,
            NNWindowOwnerName : @"TextEdit",
            NNWindowOwnerPID : @75652,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },@{
            NNWindowAlpha : @0.8500000238418579,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 10,
                .size.width = 478,
                .origin.x = 229,
                .origin.y = 69
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @5404,
            NNWindowNumber : @33270,
            NNWindowOwnerName : @"TextEdit",
            NNWindowOwnerPID : @75652,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },@{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 293,
                .size.width = 465,
                .origin.x = 235,
                .origin.y = 69
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @220020,
            NNWindowName : @"Save",
            NNWindowNumber : @33265,
            NNWindowOwnerName : @"com.apple.security.pboxd",
            NNWindowOwnerPID : @75654,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        windowDescription
    ];

    [self updateListServiceWithInfoList:infoList];
    XCTAssertEqual(self.listService.windows.count, (__typeof__(self.listService.windows.count))1, @"Powerbox save dialog wasn't grouped correctly");
    if (self.listService.windows.count == 1) {
        XCTAssertEqual(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).windows.count, infoList.count, @"");
        XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).mainWindow.windowDescription, windowDescription, @"Main window for group was not identified correctly");
    }
}

- (void)testPowerboxSaveDialog_10_9_0;
{
    NSDictionary *windowDescription = @{
        NNWindowAlpha : @1,
        NNWindowBounds : DICT_FROM_RECT(((CGRect){
            .size.height = 412,
            .size.width = 640,
            .origin.x = 259,
            .origin.y = 79
        })),
        NNWindowIsOnscreen : @1,
        NNWindowLayer : @0,
        NNWindowMemoryUsage : @1101076,
        NNWindowName : @"Untitled.txt",
        NNWindowNumber : @48043,
        NNWindowOwnerName : @"TextEdit",
        NNWindowOwnerPID : @82763,
        NNWindowSharingState : @1,
        NNWindowStoreType : @2,
    };

    NSArray *infoList = @[
        @{
            NNWindowAlpha : @0.8500000238418579,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 10,
                .size.width = 503,
                .origin.x = 328,
                .origin.y = 101
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @21756,
            NNWindowNumber : @48051,
            NNWindowOwnerName : @"TextEdit",
            NNWindowOwnerPID : @82763,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 58,
                .size.width = 463,
                .origin.x = 347,
                .origin.y = 313
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @111868,
            NNWindowName : @"",
            NNWindowNumber : @48050,
            NNWindowOwnerName : @"TextEdit",
            NNWindowOwnerPID : @82763,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 319,
                .size.width = 489,
                .origin.x = 334,
                .origin.y = 101
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @636156,
            NNWindowName : @"Save",
            NNWindowNumber : @48045,
            NNWindowOwnerName : @"com.apple.appkit.xpc.openAndSav",
            NNWindowOwnerPID : @82769,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 319,
                .size.width = 490,
                .origin.x = 334,
                .origin.y = 101
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @806740,
            NNWindowName : @"Save",
            NNWindowNumber : @48046,
            NNWindowOwnerName : @"TextEdit",
            NNWindowOwnerPID : @82763,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        windowDescription
    ];

    [self updateListServiceWithInfoList:infoList];
    
    XCTAssertEqual(self.listService.windows.count, (__typeof__(self.listService.windows.count))1, @"Powerbox save dialog wasn't grouped correctly");
    if (self.listService.windows.count == 1) {
        XCTAssertEqual(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).windows.count, infoList.count, @"");
        XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).mainWindow.windowDescription, windowDescription, @"Main window for group was not identified correctly");
    }
}

- (void)testMacVimSaveDialog;
{
    NSDictionary *windowDescription = 	@{
    	NNWindowLayer : @0,
    	NNWindowName : @"[No Name] + - VIM",
    	NNWindowMemoryUsage : @1752852,
    	NNWindowIsOnscreen : @1,
    	NNWindowSharingState : @1,
    	NNWindowOwnerPID : @47503,
    	NNWindowNumber : @90316,
    	NNWindowOwnerName : @"MacVim",
    	NNWindowStoreType : @2,
    	NNWindowBounds : @{
    		@"Height" : @675,
    		@"Width" : @584,
    		@"X" : @50,
    		@"Y" : @22,
    	},
    	NNWindowAlpha : @1.000000,
    };
    NSArray *infoList = @[
    	@{
    		NNWindowLayer : @0,
    		NNWindowMemoryUsage : @21756,
    		NNWindowIsOnscreen : @1,
    		NNWindowSharingState : @1,
    		NNWindowOwnerPID : @47503,
    		NNWindowNumber : @90319,
    		NNWindowOwnerName : @"MacVim",
    		NNWindowStoreType : @2,
    		NNWindowBounds : @{
    			@"Height" : @10,
    			@"Width" : @437,
    			@"X" : @124,
    			@"Y" : @44,
    		},
    		NNWindowAlpha : @0.850000,
    	},
    	@{
    		NNWindowLayer : @0,
    		NNWindowMemoryUsage : @305172,
    		NNWindowIsOnscreen : @1,
    		NNWindowSharingState : @1,
    		NNWindowOwnerPID : @47503,
    		NNWindowNumber : @90318,
    		NNWindowOwnerName : @"MacVim",
    		NNWindowStoreType : @2,
    		NNWindowBounds : @{
    			@"Height" : @166,
    			@"Width" : @424,
    			@"X" : @130,
    			@"Y" : @44,
    		},
    		NNWindowAlpha : @1.000000,
    	},
        windowDescription,
    ];
    
    [self updateListServiceWithInfoList:infoList];
    
    XCTAssertEqual(self.listService.windows.count, (__typeof__(self.listService.windows.count))1, @"Save dialog wasn't grouped correctly");
    if (self.listService.windows.count == 1) {
        XCTAssertEqual(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).windows.count, infoList.count, @"");
        XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).mainWindow.windowDescription, windowDescription, @"Main window for group was not identified correctly");
    }
}

@end
