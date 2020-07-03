//
//  NNComprehensionTests.m
//  NNKit
//
//  Created by Scott Perry on 03/11/14.
//  Copyright © 2014 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <XCTest/XCTest.h>

#import <NNKit/NNKit.h>


@interface NNComprehensionTests : XCTestCase

@end

@implementation NNComprehensionTests

- (void)testFilter;
{
    NSArray *inputArray = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10];
    NSSet *inputSet = [NSSet setWithArray:inputArray];
    NSOrderedSet *inputOrderedSet = [NSOrderedSet orderedSetWithArray:inputArray];

    NSArray *outputArray = @[@3, @6, @9];
    NSSet *outputSet = [NSSet setWithArray:outputArray];
    NSOrderedSet *outputOrderedSet = [NSOrderedSet orderedSetWithArray:outputArray];

    nn_filter_block_t filterBlock = ^(id item){ return (BOOL)!([item integerValue] % 3); };

    XCTAssertEqualObjects(outputArray, [inputArray nn_filter:filterBlock], @"Filtered array did not match expectations");
    XCTAssertEqualObjects(outputSet, [inputSet nn_filter:filterBlock], @"Filtered set did not match expectations");
    XCTAssertEqualObjects(outputOrderedSet, [inputOrderedSet nn_filter:filterBlock], @"Filtered array did not match expectations");
}

- (void)testMap;
{
    NSArray *inputArray = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10];
    NSSet *inputSet = [NSSet setWithArray:inputArray];
    NSOrderedSet *inputOrderedSet = [NSOrderedSet orderedSetWithArray:inputArray];

    NSArray *outputArray = @[@2, @4, @6, @8, @10, @12, @14, @16, @18, @20];
    NSSet *outputSet = [NSSet setWithArray:outputArray];
    NSOrderedSet *outputOrderedSet = [NSOrderedSet orderedSetWithArray:outputArray];

    nn_map_block_t mapBlock = ^(id item){ return @([item integerValue] * 2); };

    XCTAssertEqualObjects(outputArray, [inputArray nn_map:mapBlock], @"Filtered array did not match expectations");
    XCTAssertEqualObjects(outputSet, [inputSet nn_map:mapBlock], @"Filtered set did not match expectations");
    XCTAssertEqualObjects(outputOrderedSet, [inputOrderedSet nn_map:mapBlock], @"Filtered array did not match expectations");
}

- (void)testReduce;
{
    NSArray *inputArray = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10];
    NSSet *inputSet = [NSSet setWithArray:inputArray];
    NSOrderedSet *inputOrderedSet = [NSOrderedSet orderedSetWithArray:inputArray];

    NSNumber *output = @55;

    XCTAssertEqualObjects(output, [inputArray nn_reduce:^(id acc, id item){ return @([acc integerValue] + [item integerValue]); }], @"");
    XCTAssertEqualObjects(output, [inputSet nn_reduce:^(id acc, id item){ return @([acc integerValue] + [item integerValue]); }], @"");
    XCTAssertEqualObjects(output, [inputOrderedSet nn_reduce:^(id acc, id item){ return @([acc integerValue] + [item integerValue]); }], @"");
}

@end
