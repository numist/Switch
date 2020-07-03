//
//  NNSelfInvalidatingObjectTests.m
//  NNKit
//
//  Created by Scott Perry on 09/05/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <XCTest/XCTest.h>

#import <NNKit/NNKit.h>


// Fuckin' state, man.
static BOOL objectInvalidated;
static BOOL objectDestroyed;


@interface NNSelfInvalidatingObjectTests : XCTestCase
// The XCT macros don't work outside of an XCTestCase object, so events have to be forwarded back to the test case.
- (void)invalidated:(id)obj;
- (void)destroyed:(id)obj;
@end


@interface NNInvalidatingTestObject : NNSelfInvalidatingObject

@property (assign, readonly) NNSelfInvalidatingObjectTests *test;

@end


@implementation NNInvalidatingTestObject

- (instancetype)initWithTestObject:(NNSelfInvalidatingObjectTests *)obj;
{
    if (!(self = [super init])) { return nil; }
    
    _test = obj;
    
    return self;
}

- (void)invalidate;
{
    [self.test invalidated:self];
    
    [super invalidate];
}
- (void)dealloc;
{
    [_test destroyed:self];
    
    [super dealloc];
}
@end


@implementation NNSelfInvalidatingObjectTests

- (void)setUp
{
    [super setUp];
    
    objectInvalidated = NO;
    objectDestroyed = NO;
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)invalidated:(id)obj;
{
    XCTAssertTrue([[NSThread currentThread] isMainThread], @"Invalidation happened on a queue other than the main queue!");
    XCTAssertFalse(objectInvalidated, @"Object was invalidated multiple times!");
    objectInvalidated = YES;
}

- (void)destroyed:(id)obj;
{
    XCTAssertTrue(objectInvalidated, @"Object was destroyed before it was invalidated!");
    objectDestroyed = YES;
}

- (void)testDeallocInvalidation
{
    NNInvalidatingTestObject *obj = [[NNInvalidatingTestObject alloc] initWithTestObject:self];
    
    XCTAssertFalse(objectInvalidated, @"Object was still valid before it was released");
    
    [obj release];
    obj = nil;
    
    while (!objectDestroyed) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    
    XCTAssertTrue(objectInvalidated, @"Object was not invalidated before it was destroyed");
}

- (void)testManualInvalidation
{
    NNInvalidatingTestObject *obj = [[NNInvalidatingTestObject alloc] initWithTestObject:self];
    
    XCTAssertFalse(objectInvalidated, @"Object was still valid before it was released");
    
    // Ensure the autorelease pool gets drained within the scope of this test.
    @autoreleasepool {
        [obj invalidate];
    }
    
    XCTAssertTrue(objectInvalidated, @"Object was manually invalidated before it was destroyed");

    [obj release];
    obj = nil;
    
    while (!objectDestroyed) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    
    XCTAssertTrue(objectInvalidated, @"Object was not invalidated before it was destroyed");
}

- (void)testManualDealloc
{
    XCTAssertThrows([[NNSelfInvalidatingObject new] dealloc], @"Invalidating objects are not supposed to accept -dealloc quietly");
}

@end
