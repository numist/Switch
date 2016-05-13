//
//  SWXcodeTests.m
//  Switch
//
//  Created by Scott Perry on 05/13/16.
//  Copyright © 2016 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWWindowListServiceTestSuperclass.h"


@interface SWXcodeTests : SWWindowListServiceTestSuperclass

@end


@implementation SWXcodeTests

- (void)testFullScreenWindow {
    NSArray *infoList = @[
        @{
            NNWindowLayer : @0,
            NNWindowAlpha : @1.000000,
            NNWindowMemoryUsage : @1024,
            NNWindowIsOnscreen : @1,
            NNWindowSharingState : @1,
            NNWindowOwnerPID : @60683,
            NNWindowNumber : @14131,
            NNWindowOwnerName : @"Xcode",
            NNWindowStoreType : @1,
            NNWindowBounds : @{
                @"Height" : @74,
                @"Width" : @1366,
                @"X" : @0,
                @"Y" : @22,
            },
            NNWindowName : @"",
        },
        @{
            NNWindowLayer : @0,
            NNWindowAlpha : @1.000000,
            NNWindowMemoryUsage : @4002976,
            NNWindowIsOnscreen : @1,
            NNWindowSharingState : @1,
            NNWindowOwnerPID : @60683,
            NNWindowNumber : @9487,
            NNWindowOwnerName : @"Xcode",
            NNWindowStoreType : @2,
            NNWindowBounds : @{
                @"Height" : @727,
                @"Width" : @1366,
                @"X" : @0,
                @"Y" : @41,
            },
            NNWindowName : @"SWCoreWindowService.m",
        },
    ];
    
    [self updateListServiceWithInfoList:infoList];
    XCTAssertEqual(self.listService.windows.count, 1, @"Xcode was incorrectly filtered");
    if (self.listService.windows.count == 1) {
        XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).mainWindow.name, @"SWCoreWindowService.m");
    }
}

@end
