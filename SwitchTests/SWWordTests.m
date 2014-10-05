//
//  SWWordTests.m
//  Switch
//
//  Created by Scott Perry on 02/12/14.
//  Copyright © 2014 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWWindowListServiceTestSuperclass.h"

@interface SWWordTests : SWWindowListServiceTestSuperclass

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
    
    XCTAssertEqual(self.listService.windows.count, 1, @"");
    XCTAssertEqual(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).windows.count, (NSUInteger)2, @"");
    XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).mainWindow.windowDescription, windowDescription, @"");
}

@end
