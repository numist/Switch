//
//  SWIsolatorTests.m
//  Switch
//
//  Created by Scott Perry on 04/30/14.
//  Copyright © 2014 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWWindowListServiceTests.h"


@interface SWIsolatorTests : SWWindowListServiceTests

@end


@implementation SWIsolatorTests

- (void)testIsolatorShieldFiltering;
{
    NSDictionary *windowDescription = @{
        NNWindowLayer : @0,
        NNWindowName : @"",
        NNWindowMemoryUsage : @5186812,
        NNWindowIsOnscreen : @1,
        NNWindowSharingState : @1,
        NNWindowOwnerPID : @428,
        NNWindowNumber : @121,
        NNWindowOwnerName : @"Isolator",
        NNWindowStoreType : @2,
        NNWindowBounds : @{
            @"Height" : @900,
            @"Width" : @1440,
            @"X" : @0,
            @"Y" : @0,
        },
        NNWindowAlpha : @0.731156,
    };
    NSArray *infoList = @[windowDescription];
    
    [self updateListServiceWithInfoList:infoList];
    
    XCTAssertEqual(self.listService.windows.count, (__typeof__(self.listService.windows.count))0, @"");
}

@end
