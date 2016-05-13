//
//  SWMacVimTests.m
//  Switch
//
//  Created by Scott Perry on 01/11/14.
//  Copyright © 2016 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWWindowListServiceTestSuperclass.h"


@interface SWMacVimTests : SWWindowListServiceTestSuperclass

@end


@implementation SWMacVimTests

// No issue #, found during development
- (void)testInsetWindows
{
    NSDictionary *window2Description = @{
        NNWindowAlpha : @1,
        NNWindowBounds : DICT_FROM_RECT(((CGRect){
            .size.height = 675,
            .size.width = 584,
            .origin.x = 50,
            .origin.y = 22
        })),
        NNWindowIsOnscreen : @1,
        NNWindowLayer : @0,
        NNWindowMemoryUsage : @1752852,
        NNWindowName : @"[No Name] - VIM1",
        NNWindowNumber : @84626,
        NNWindowOwnerName : @"MacVim",
        NNWindowOwnerPID : @47503,
        NNWindowSharingState : @1,
        NNWindowStoreType : @2,
    };
    
    NSDictionary *window1Description = @{
        NNWindowAlpha : @1,
        NNWindowBounds : DICT_FROM_RECT(((CGRect){
            // This was gerrymandered a little bit, but it's close to the actual conditions—the window is slightly smaller than the one beneath it.
            .size.height = 673,
            .size.width = 582,
            .origin.x = 51,
            .origin.y = 23
        })),
        NNWindowIsOnscreen : @1,
        NNWindowLayer : @0,
        NNWindowMemoryUsage : @1643220,
        NNWindowNumber : @84625,
        NNWindowOwnerName : @"MacVim",
        NNWindowOwnerPID : @47503,
        NNWindowSharingState : @1,
        NNWindowStoreType : @2,
    };
    
    NSArray *infoList = @[window1Description, window2Description];
    
    [self updateListServiceWithInfoList:infoList];
    
    XCTAssertEqual(self.listService.windows.count, 2, @"");
    if (self.listService.windows.count == 2) {
        XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).mainWindow.windowDescription, window1Description, @"");
        XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:1]).mainWindow.windowDescription, window2Description, @"");
    }
}

// No issue #, found during development
- (void)testOverlappingWindows;
{
    NSDictionary *window1Description = @{
        NNWindowAlpha : @1,
        NNWindowBounds : DICT_FROM_RECT(((CGRect){
            .size.height = 675,
            .size.width = 584,
            .origin.x = 50,
            .origin.y = 22
        })),
        NNWindowIsOnscreen : @1,
        NNWindowLayer : @0,
        NNWindowMemoryUsage : @1752852,
        NNWindowNumber : @84913,
        NNWindowOwnerName : @"MacVim",
        NNWindowOwnerPID : @47503,
        NNWindowSharingState : @1,
        NNWindowStoreType : @2,
    };
    
    NSDictionary *window2Description = @{
        NNWindowAlpha : @1,
        NNWindowBounds : DICT_FROM_RECT(((CGRect){
            .size.height = 675,
            .size.width = 584,
            .origin.x = 739,
            .origin.y = 22
        })),
        NNWindowIsOnscreen : @1,
        NNWindowLayer : @0,
        NNWindowMemoryUsage : @1643220,
        NNWindowName : @"[No Name] - VIM1",
        NNWindowNumber : @84626,
        NNWindowOwnerName : @"MacVim",
        NNWindowOwnerPID : @47503,
        NNWindowSharingState : @1,
        NNWindowStoreType : @2,
    };
    
    NSArray *infoList = @[window1Description, window2Description];

    [self updateListServiceWithInfoList:infoList];
    
    XCTAssertEqual(self.listService.windows.count, 2, @"");
    if (self.listService.windows.count == 2) {
        XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).mainWindow.windowDescription, window1Description, @"");
        XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:1]).mainWindow.windowDescription, window2Description, @"");
    }
}

@end
