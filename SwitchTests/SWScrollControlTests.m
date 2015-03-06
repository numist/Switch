//
//  SWScrollControlTests.m
//  Switch
//
//  Created by Scott Perry on 09/30/14.
//  Copyright © 2014 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "SWScrollControl.h"


@interface SWScrollControlTests : XCTestCase
@end


@implementation SWScrollControlTests

- (void)testBasic {
    NSInteger const threshold = 50;
    __block NSInteger units = 0;
    SWScrollControl *scroller = [[SWScrollControl alloc] initWithThreshold:threshold incHandler:^{
        ++units;
    } decHandler:^{
        --units;
    }];

    void (^verifyFeed)(NSInteger feed) = ^(NSInteger feed){
        units = 0;
        [scroller feed:feed];
        XCTAssertEqual(feed / threshold, units);
    };

    verifyFeed(threshold);
    verifyFeed(-threshold);
    verifyFeed(threshold * 20);
    verifyFeed(-threshold * 20);
}

- (void)testNegativeThreshold;
{
    NSInteger const threshold = 50;
    __block NSInteger units = 0;
    SWScrollControl *scroller = [[SWScrollControl alloc] initWithThreshold:-threshold incHandler:^{
        ++units;
    } decHandler:^{
        --units;
    }];

    void (^verifyFeed)(NSInteger feed) = ^(NSInteger feed){
        units = 0;
        [scroller reset];
        [scroller feed:feed];
        XCTAssertEqual(feed / threshold, units);
    };

    verifyFeed(threshold);
    verifyFeed(-threshold);
    verifyFeed(threshold * 20);
    verifyFeed(-threshold * 20);
}

- (void)testMaximumThreshold;
{
    NSInteger const threshold = NSIntegerMax / 2;
    __block NSInteger units = 0;
    SWScrollControl *scroller = [[SWScrollControl alloc] initWithThreshold:threshold incHandler:^{
        ++units;
    } decHandler:^{
        --units;
    }];

    units = 0;
    [scroller reset];
    [scroller feed:threshold];
    XCTAssertEqual(1, units);

    units = 0;
    [scroller reset];
    [scroller feed:(threshold / 2)];
    // Attempt to force an overflow
    [scroller feed:(threshold / 3) * 2];
    XCTAssertEqual(1, units);

    units = 0;
    [scroller reset];
    [scroller feed:-(threshold / 2)];
    [scroller feed:-(threshold % 2)];
    // Attempt to force an underflow
    [scroller feed:-(threshold / 3) * 2];
    XCTAssertEqual(-1, units);

    units = 0;
    [scroller reset];
    // Attempt to force an overflow
    [scroller feed:threshold - 1];
    [scroller feed:NSIntegerMax];
    XCTAssertEqual((NSIntegerMax / threshold) + 1, units);

    units = 0;
    [scroller reset];
    // Attempt to force an underflow
    [scroller feed:-threshold - 1];
    [scroller feed:NSIntegerMin];
    XCTAssertEqual((NSIntegerMin / threshold) - 1, units);

}

- (void)testUnrealisticThreshold;
{
    NSInteger const threshold = NSIntegerMax;
    __block NSInteger units = 0;
    SWScrollControl *scroller = [[SWScrollControl alloc] initWithThreshold:threshold incHandler:^{
        ++units;
    } decHandler:^{
        --units;
    }];

    // For now, until it matters enough that this work at that kind of scale—it's not worth writing all that code :/
    XCTAssertNil(scroller);
}

- (void)testAccumulatorOverflowIncrementing;
{
    NSInteger const threshold = 50;
    __block NSInteger units = 0;
    SWScrollControl *scroller = [[SWScrollControl alloc] initWithThreshold:threshold incHandler:^{
        ++units;
    } decHandler:^{
        --units;
    }];
    
    units = 0;
    [scroller reset];
    for (int i = 0; i < 10; i++) {
        [scroller feed:15];
    }
    XCTAssertEqual(3, units);

    units = 0;
    [scroller reset];
    for (int i = 0; i < 10; i++) {
        [scroller feed:-15];
    }
    XCTAssertEqual(-3, units);
}

@end
