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

#import "SWWindowListServiceTests.h"


@interface SWChromeTests : SWWindowListServiceTests

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
    XCTAssertEqual(self.listService.windows.count, (__typeof__(self.listService.windows.count))1, @"Dash was incorrectly filtered out");
    if (self.listService.windows.count == 1) {
        XCTAssertEqual(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).windows.count, infoList.count, @"");
        XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).mainWindow.windowDescription, windowDescription, @"");
    }
}

@end
