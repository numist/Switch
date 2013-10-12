//
//  NNTweetbotRegressionTests.m
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
//  This file tests for regressions concerning Tweetbot:
//  * https://github.com/numist/Switch/issues/2
//

#import <XCTest/XCTest.h>

#import "NNWindowFilteringTests.h"


@interface NNTweetbotRegressionTests : XCTestCase

@end


@implementation NNTweetbotRegressionTests

- (NNWindow *)mainWindow;
{
    return [NNWindow windowWithDescription:@{
        NNWindowAlpha : @1,
        NNWindowBounds : DICT_FROM_RECT(((CGRect){
            .size.height = 636,
            .size.width = 480,
            .origin.x = 293,
            .origin.y = 74
        })),
        NNWindowIsOnscreen : @1,
        NNWindowLayer : @0,
        NNWindowMemoryUsage : @1710196,
        NNWindowName : @"Main Window",
        NNWindowNumber : @85208,
        NNWindowOwnerName : @"Tweetbot",
        NNWindowOwnerPID : @9258,
        NNWindowSharingState : @1,
        NNWindowStoreType : @2,
    }];
}

- (NSOrderedSet *)mainWindows;
{
    return [NSOrderedSet orderedSetWithArray:@[
        [NNWindow windowWithDescription:@{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 30,
                .size.width = 412,
                .origin.x = 360,
                .origin.y = 110
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @62748,
            NNWindowName : @"",
            NNWindowNumber : @114910,
            NNWindowOwnerName : @"Tweetbot",
            NNWindowOwnerPID : @9258,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        }],
        [self mainWindow]
    ]];
}

- (NNWindow *)imageWindow;
{
    return [NNWindow windowWithDescription:@{
        NNWindowAlpha : @1,
        NNWindowBounds : DICT_FROM_RECT(((CGRect){
            .size.height = 379,
            .size.width = 1002,
            .origin.x = 124,
            .origin.y = 300
        })),
        NNWindowIsOnscreen : @1,
        NNWindowLayer : @0,
        NNWindowMemoryUsage : @2541364,
        NNWindowName : @"",
        NNWindowNumber : @117515,
        NNWindowOwnerName : @"Tweetbot",
        NNWindowOwnerPID : @9258,
        NNWindowSharingState : @1,
        NNWindowStoreType : @2,
    }];
}

- (void)testFilterUnreadBanner;
{
    XCTAssertEqualObjects([NSOrderedSet orderedSetWithObject:[self mainWindow]], [NNWindow filterInvalidWindowsFromSet:[self mainWindows]], @"Unread banner was not filtered out correctly");
}

- (void)testFilterWithImageWindow;
{
    NSMutableOrderedSet *windows = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mainWindows]];
    [windows addObject:[self imageWindow]];
    
    XCTAssertEqualObjects(([NSOrderedSet orderedSetWithArray:@[[self mainWindow], [self imageWindow]]]), [NNWindow filterInvalidWindowsFromSet:windows], @"Tweetbot unread banner was not filtered out correctly");

    [windows removeObjectAtIndex:(windows.count - 1)];
    [windows insertObject:[self imageWindow] atIndex:0];
    
    XCTAssertEqualObjects(([NSOrderedSet orderedSetWithArray:@[[self imageWindow], [self mainWindow]]]), [NNWindow filterInvalidWindowsFromSet:windows], @"Unread banner was not filtered out correctly");
}

@end
