//
//  NNMultiDispatchManagerTests.m
//  NNKit
//
//  Created by Scott Perry on 11/19/13.
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
#import <NNKit/NNMultiDispatchManager.h>


unsigned callCount = 0;
dispatch_group_t group;


@protocol NNMultiDispatchManagerTestProtocol <NSObject>
- (void)foo:(id)sender;
- (oneway void)bar:(id)sender;
@optional
- (void)baz:(id)sender;
- (id)qux:(id)sender;
@end


@interface NNMultiDispatchManagerTestObject : NSObject <NNMultiDispatchManagerTestProtocol>
@end
@implementation NNMultiDispatchManagerTestObject
- (void)foo:(id)sender;
{
    callCount++;
}
- (oneway void)bar:(id)sender;
{
    callCount++;
    dispatch_group_leave(group);
}
@end


@interface NNMultiDispatchManagerTestObject2 : NSObject <NNMultiDispatchManagerTestProtocol>
@end
@implementation NNMultiDispatchManagerTestObject2
- (void)foo:(id)sender;
{
    callCount++;
}
- (oneway void)bar:(id)sender;
{
    callCount++;
    dispatch_group_leave(group);
}
- (void)baz:(id)sender;
{
    callCount++;
}
@end


@interface NNMultiDispatchManagerTests : XCTestCase

@end


@implementation NNMultiDispatchManagerTests

- (void)setUp
{
    [super setUp];

    callCount = 0;
    group = dispatch_group_create();
}

- (void)testSync
{
    NNMultiDispatchManager *manager = [[NNMultiDispatchManager alloc] initWithProtocol:@protocol(NNMultiDispatchManagerTestProtocol)];
    __attribute__((objc_precise_lifetime)) id foo1 = [NNMultiDispatchManagerTestObject new];
    __attribute__((objc_precise_lifetime)) id foo2 = [NNMultiDispatchManagerTestObject new];
    __attribute__((objc_precise_lifetime)) id foo3 = [NNMultiDispatchManagerTestObject2 new];
    __attribute__((objc_precise_lifetime)) id foo4 = [NNMultiDispatchManagerTestObject2 new];
    [manager addObserver:foo1];
    [manager addObserver:foo2];
    [manager addObserver:foo3];
    [manager addObserver:foo4];
    
    [(id<NNMultiDispatchManagerTestProtocol>)manager foo:self];
    XCTAssertEqual(callCount, (unsigned)4, @"");
}

- (void)testAsync;
{
    NNMultiDispatchManager *manager = [[NNMultiDispatchManager alloc] initWithProtocol:@protocol(NNMultiDispatchManagerTestProtocol)];
    __attribute__((objc_precise_lifetime)) id foo1 = [NNMultiDispatchManagerTestObject new];
    __attribute__((objc_precise_lifetime)) id foo2 = [NNMultiDispatchManagerTestObject new];
    __attribute__((objc_precise_lifetime)) id foo3 = [NNMultiDispatchManagerTestObject2 new];
    __attribute__((objc_precise_lifetime)) id foo4 = [NNMultiDispatchManagerTestObject2 new];
    [manager addObserver:foo1];
    [manager addObserver:foo2];
    [manager addObserver:foo3];
    [manager addObserver:foo4];
    dispatch_group_enter(group);
    dispatch_group_enter(group);
    dispatch_group_enter(group);
    dispatch_group_enter(group);

    XCTAssertEqual(callCount, (unsigned)0, @"");
    [(id<NNMultiDispatchManagerTestProtocol>)manager bar:self];
    
    while(!despatch_group_yield(group));
    XCTAssertEqual(callCount, (unsigned)4, @"");
}

- (void)testOptionalSelector;
{
    NNMultiDispatchManager *manager = [[NNMultiDispatchManager alloc] initWithProtocol:@protocol(NNMultiDispatchManagerTestProtocol)];
    __attribute__((objc_precise_lifetime)) id foo1 = [NNMultiDispatchManagerTestObject new];
    __attribute__((objc_precise_lifetime)) id foo2 = [NNMultiDispatchManagerTestObject new];
    __attribute__((objc_precise_lifetime)) id foo3 = [NNMultiDispatchManagerTestObject2 new];
    __attribute__((objc_precise_lifetime)) id foo4 = [NNMultiDispatchManagerTestObject2 new];
    [manager addObserver:foo1];
    [manager addObserver:foo2];
    [manager addObserver:foo3];
    [manager addObserver:foo4];
    
    XCTAssertNoThrow([(id<NNMultiDispatchManagerTestProtocol>)manager baz:self], @"");
    XCTAssertEqual(callCount, (unsigned)2, @"");
}

- (void)testBadSelector;
{
    NNMultiDispatchManager *manager = [[NNMultiDispatchManager alloc] initWithProtocol:@protocol(NNMultiDispatchManagerTestProtocol)];
    __attribute__((objc_precise_lifetime)) id foo1 = [NNMultiDispatchManagerTestObject new];
    __attribute__((objc_precise_lifetime)) id foo2 = [NNMultiDispatchManagerTestObject new];
    __attribute__((objc_precise_lifetime)) id foo3 = [NNMultiDispatchManagerTestObject2 new];
    __attribute__((objc_precise_lifetime)) id foo4 = [NNMultiDispatchManagerTestObject2 new];
    [manager addObserver:foo1];
    [manager addObserver:foo2];
    [manager addObserver:foo3];
    [manager addObserver:foo4];
    
    XCTAssertThrows([(id)manager invokeWithTarget:self], @"");
    XCTAssertEqual(callCount, (unsigned)0, @"");
}

- (void)testWeakDispatch
{
    NNMultiDispatchManager *manager = [[NNMultiDispatchManager alloc] initWithProtocol:@protocol(NNMultiDispatchManagerTestProtocol)];
    __attribute__((objc_precise_lifetime)) id foo1 = [NNMultiDispatchManagerTestObject new];
    __attribute__((objc_precise_lifetime)) id foo4 = [NNMultiDispatchManagerTestObject2 new];
    @autoreleasepool {
        id foo2 = [NNMultiDispatchManagerTestObject new];
        id foo3 = [NNMultiDispatchManagerTestObject2 new];
        [manager addObserver:foo1];
        [manager addObserver:foo2];
        [manager addObserver:foo3];
        [manager addObserver:foo4];
    }
    
    [(id<NNMultiDispatchManagerTestProtocol>)manager foo:self];
    XCTAssertEqual(callCount, (unsigned)2, @"");
}

- (void)testIllegalReturnType
{
    NNMultiDispatchManager *manager = [[NNMultiDispatchManager alloc] initWithProtocol:@protocol(NNMultiDispatchManagerTestProtocol)];
    __attribute__((objc_precise_lifetime)) id foo1 = [NNMultiDispatchManagerTestObject new];
    __attribute__((objc_precise_lifetime)) id foo2 = [NNMultiDispatchManagerTestObject new];
    __attribute__((objc_precise_lifetime)) id foo3 = [NNMultiDispatchManagerTestObject2 new];
    __attribute__((objc_precise_lifetime)) id foo4 = [NNMultiDispatchManagerTestObject2 new];
    [manager addObserver:foo1];
    [manager addObserver:foo2];
    [manager addObserver:foo3];
    [manager addObserver:foo4];
    
    XCTAssertThrows((void)[(id<NNMultiDispatchManagerTestProtocol>)manager qux:self], @"");
    XCTAssertEqual(callCount, (unsigned)0, @"");
}

@end
