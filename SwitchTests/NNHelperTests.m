//
//  NNHelperTests.m
//  Switch
//
//  Created by Scott Perry on 10/11/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "helpers.h"

@interface NNHelperTests : SenTestCase

@end

@implementation NNHelperTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class. 
    [super tearDown];
}

- (void)testBasicOrderedSetFiltering
{
    NSOrderedSet *unfiltered = [NSOrderedSet orderedSetWithArray:@[@"Sanguinary", @"Inspirational", @"Susurrus"]];
    NSOrderedSet *filtered = NNFilterOrderedSet(unfiltered, ^BOOL(id item) {
        return [item hasPrefix:@"S"];
    });
	STAssertEqualObjects(filtered, ([NSOrderedSet orderedSetWithArray:@[@"Sanguinary", @"Susurrus"]]), @"Filtering ordered sets is broken");
}

@end
