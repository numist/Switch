//
//  SWFinderTests.m
//  Switch
//
//  Created by Scott Perry on 05/13/16.
//  Copyright © 2016 Scott Perry. All rights reserved.
//

#import "SWWindowListServiceTestSuperclass.h"

@interface SWFinderTests : SWWindowListServiceTestSuperclass

@end

@implementation SWFinderTests

- (void)testQuicklookWindow;
{
    // This Quicklook window was recorded on OS X 10.11.3 when Finder was not frontmost
    NSArray *infoList = @[
         @{
            NNWindowLayer : @0,
            NNWindowAlpha : @1.000000,
            NNWindowMemoryUsage : @1024,
            NNWindowIsOnscreen : @1,
            NNWindowSharingState : @1,
            NNWindowOwnerPID : @58213,
            NNWindowNumber : @14164,
            NNWindowOwnerName : @"Finder",
            NNWindowStoreType : @1,
            NNWindowBounds : @{
                @"Height" : @669,
                @"Width" : @366,
                @"X" : @500,
                @"Y" : @59,
            },
            NNWindowName : @"",
        },
    ];
    
    [self updateListServiceWithInfoList:infoList];
    XCTAssertEqual(self.listService.windows.count, 0, @"Finder QuickLook window was incorrectly filtered");
}

@end
