//
//  SWChromeTests.m
//  Switch
//
//  Created by Scott Perry on 01/19/14.
//  Copyright © 2014 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWWindowListServiceTestSuperclass.h"


@interface SWChromeTests : SWWindowListServiceTestSuperclass

@end


@implementation SWChromeTests

- (void)testStatusBar
{
    NSDictionary *windowDescription = @{
        NNWindowAlpha : @1,
        NNWindowBounds : DICT_FROM_RECT(((CGRect){
            .size.height = 731,
            .size.width = 1366,
            .origin.x = 0,
            .origin.y = 22
        })),
        NNWindowIsOnscreen : @1,
        NNWindowLayer : @0,
        NNWindowMemoryUsage : @4350292,
        NNWindowName : @"96001-06025-07 BOLT, FLANGE (6X25) $0.74",
        NNWindowNumber : @11304,
        NNWindowOwnerName : @"Google Chrome",
        NNWindowOwnerPID : @8705,
        NNWindowSharingState : @1,
        NNWindowStoreType : @2
    };
    NSArray *infoList = @[
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
              .size.height = 18,
              .size.width = 456,
              .origin.x = 0,
              .origin.y = 735
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @38140,
            NNWindowName : @"",
            NNWindowNumber : @1303,
            NNWindowOwnerName : @"Google Chrome",
            NNWindowOwnerPID : @8705,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2
        },
        windowDescription
    ];
    
    [self updateListServiceWithInfoList:infoList];
    XCTAssertEqual(self.listService.windows.count, 1, @"Chrome was incorrectly filtered");
    if (self.listService.windows.count == 1) {
        XCTAssertEqual(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).windows.count, infoList.count, @"");
        XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).mainWindow.windowDescription, windowDescription, @"");
    }
}

- (void)testMultipleWindows;
{
    NSDictionary *window1Description = @{
		NNWindowLayer : @0,
		NNWindowName : @"",
		NNWindowMemoryUsage : @5372,
		NNWindowIsOnscreen : @1,
		NNWindowSharingState : @1,
		NNWindowOwnerPID : @8705,
		NNWindowNumber : @17988,
		NNWindowOwnerName : @"Google Chrome",
		NNWindowStoreType : @2,
		NNWindowBounds : @{
			@"Height" : @1,
			@"Width" : @456,
			@"X" : @0,
			@"Y" : @752,
		},
		NNWindowAlpha : @0.000000,
	};
	NSDictionary *window2Description = @{
		NNWindowLayer : @0,
		NNWindowName : @"(2) Facebook",
		NNWindowMemoryUsage : @4350292,
		NNWindowIsOnscreen : @1,
		NNWindowSharingState : @1,
		NNWindowOwnerPID : @8705,
		NNWindowNumber : @17989,
		NNWindowOwnerName : @"Google Chrome",
		NNWindowStoreType : @2,
		NNWindowBounds : @{
			@"Height" : @731,
			@"Width" : @1366,
			@"X" : @0,
			@"Y" : @22,
		},
		NNWindowAlpha : @1.000000,
	};
	NSDictionary *window3Description = @{
		NNWindowLayer : @0,
		NNWindowName : @"",
		NNWindowMemoryUsage : @5372,
		NNWindowIsOnscreen : @1,
		NNWindowSharingState : @1,
		NNWindowOwnerPID : @8705,
		NNWindowNumber : @17960,
		NNWindowOwnerName : @"Google Chrome",
		NNWindowStoreType : @2,
		NNWindowBounds : @{
			@"Height" : @1,
			@"Width" : @456,
			@"X" : @0,
			@"Y" : @752,
		},
		NNWindowAlpha : @0.000000,
	};
	NSDictionary *window4Description = @{
		NNWindowLayer : @0,
		NNWindowName : @"[Ardent] climbing this week? - numist@numist.net - numist.net Mail",
		NNWindowMemoryUsage : @4112212,
		NNWindowIsOnscreen : @1,
		NNWindowSharingState : @1,
		NNWindowOwnerPID : @8705,
		NNWindowNumber : @17961,
		NNWindowOwnerName : @"Google Chrome",
		NNWindowStoreType : @2,
		NNWindowBounds : @{
			@"Height" : @731,
			@"Width" : @1366,
			@"X" : @0,
			@"Y" : @22,
		},
		NNWindowAlpha : @1.000000,
	};
	NSDictionary *window5Description = @{
		NNWindowLayer : @0,
		NNWindowName : @"",
		NNWindowMemoryUsage : @5372,
		NNWindowIsOnscreen : @1,
		NNWindowSharingState : @1,
		NNWindowOwnerPID : @8705,
		NNWindowNumber : @17963,
		NNWindowOwnerName : @"Google Chrome",
		NNWindowStoreType : @2,
		NNWindowBounds : @{
			@"Height" : @1,
			@"Width" : @410,
			@"X" : @68,
			@"Y" : @740,
		},
		NNWindowAlpha : @0.000000,
	};
	NSDictionary *window6Description = @{
		NNWindowLayer : @0,
		NNWindowName : @"Google+ Hangouts",
		NNWindowMemoryUsage : @3625300,
		NNWindowIsOnscreen : @1,
		NNWindowSharingState : @1,
		NNWindowOwnerPID : @8705,
		NNWindowNumber : @17964,
		NNWindowOwnerName : @"Google Chrome",
		NNWindowStoreType : @2,
		NNWindowBounds : @{
			@"Height" : @719,
			@"Width" : @1229,
			@"X" : @68,
			@"Y" : @22,
		},
		NNWindowAlpha : @1.000000,
	};
	NSArray *infoList = @[
		window1Description,
		window2Description,
		window3Description,
		window4Description,
		window5Description,
		window6Description,
	];
	
    [self updateListServiceWithInfoList:infoList];
    XCTAssertEqual(self.listService.windows.count, 3, @"Chrome was incorrectly filtered");
    if (self.listService.windows.count == 3) {
        XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).mainWindow.windowDescription, window2Description, @"");
        XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:1]).mainWindow.windowDescription, window4Description, @"");
        XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:2]).mainWindow.windowDescription, window6Description, @"");
    }
}

@end
