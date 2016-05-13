//
//  SWXcodeTests.m
//  Switch
//
//  Created by Scott Perry on 05/13/16.
//  Copyright © 2016 Scott Perry. All rights reserved.
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
