//
//  NNSafariRegressionTests.m
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


@interface SWSafariTests : SWWindowListServiceTests

@end


@implementation SWSafariTests

// https://github.com/numist/Switch/issues/8
- (void)testSearchMatches;
{
    NSDictionary *windowDescription = @{
        NNWindowAlpha : @1,
        NNWindowBounds : DICT_FROM_RECT(((CGRect){
           .size.height = 706,
           .size.width = 1366,
           .origin.x = 0,
           .origin.y = 22
        })),
        NNWindowIsOnscreen : @1,
        NNWindowLayer : @0,
        NNWindowMemoryUsage : @316020,
        NNWindowName : @"mikeash.com: Performance Comparisons of Common Operations",
        NNWindowNumber : @31886,
        NNWindowOwnerName : @"Safari",
        NNWindowOwnerPID : @164,
        NNWindowSharingState : @1,
        NNWindowStoreType : @2,
    };
    NSArray *infoList = @[
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
              .size.height = 26,
              .size.width = 224,
              .origin.x = 50,
              .origin.y = 413
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @29980,
            NNWindowName : @"",
            NNWindowNumber : @32161,
            NNWindowOwnerName : @"Safari",
            NNWindowOwnerPID : @164,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        windowDescription
    ];
    
    [self updateListServiceWithInfoList:infoList];
    XCTAssertEqual(self.listService.windows.count, (__typeof__(self.listService.windows.count))1, @"Safari was incorrectly grouped");
    XCTAssertEqual(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).windows.count, infoList.count, @"");
    XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).mainWindow.windowDescription, windowDescription, @"");
}

@end
