//
//  SWWordTests.m
//  Switch
//
//  Created by Scott Perry on 02/12/14.
//  Copyright (c) 2014 Scott Perry. All rights reserved.
//

#import "SWWindowListServiceTests.h"

@interface SWWordTests : SWWindowListServiceTests

@end

@implementation SWWordTests

- (void)testGiantInvisibleWindow;
{
    NSDictionary *windowDescription = @{
		NNWindowLayer : @0,
		NNWindowName : @"Document1",
		NNWindowMemoryUsage : @5548372,
		NNWindowIsOnscreen : @1,
		NNWindowSharingState : @1,
		NNWindowOwnerPID : @65457,
		NNWindowNumber : @17655,
		NNWindowOwnerName : @"Microsoft Word",
		NNWindowStoreType : @2,
		NNWindowBounds : @{
			@"Height" : @823,
			@"Width" : @1264,
			@"X" : @436,
			@"Y" : @245,
		},
		NNWindowAlpha : @1.000000,
	};
    
    NSArray *infoList = @[
		@{
			NNWindowLayer : @0,
			NNWindowMemoryUsage : @3892476,
			NNWindowIsOnscreen : @1,
			NNWindowSharingState : @1,
			NNWindowOwnerPID : @65457,
			NNWindowNumber : @17657,
			NNWindowOwnerName : @"Microsoft Word",
			NNWindowStoreType : @2,
			NNWindowBounds : @{
				@"Height" : @769,
				@"Width" : @1264,
				@"X" : @436,
				@"Y" : @299,
			},
			NNWindowAlpha : @1.000000,
		},
		windowDescription,
		@{
			NNWindowLayer : @0,
			NNWindowName : @"Microsoft Word",
			NNWindowMemoryUsage : @9020668,
			NNWindowIsOnscreen : @1,
			NNWindowSharingState : @1,
			NNWindowOwnerPID : @65457,
			NNWindowNumber : @17635,
			NNWindowOwnerName : @"Microsoft Word",
			NNWindowStoreType : @2,
			NNWindowBounds : @{
				@"Height" : @1174,
				@"Width" : @1920,
				@"X" : @0,
				@"Y" : @22,
			},
			NNWindowAlpha : @1.000000,
		}
    ];
    
    [self updateListServiceWithInfoList:infoList];
    
    XCTAssertEqual(self.listService.windows.count, (__typeof__(self.listService.windows.count))1, @"");
    XCTAssertEqual(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).windows.count, (NSUInteger)2, @"");
    XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).mainWindow.windowDescription, windowDescription, @"");
}

@end
