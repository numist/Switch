//
//  NNStrongifiedPropertiesTests.m
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


@interface NNStrongifiedPropertiesTests : XCTestCase

@end



@interface NNStrongifyTestClass : NNStrongifiedProperties

@property (weak) id foo;
@property id bar;
@property (weak) id TLA;
@property (weak) id qux;
@property (weak) id Qux;

@end
@interface NNStrongifyTestClass (NNStrongGetters)

- (id)strongFoo; // Good
- (id)strongBar; // Bad -- strong
- (id)strongTLA; // Good
- (id)strongQux; // Bad -- ambiguous

@end
@implementation NNStrongifyTestClass
@end



@interface NNSwizzledStrongifierTestClass : NSObject

@property (weak) id foo;
@property id bar;
@property (weak) id TLA;
@property (weak) id qux;
@property (weak) id Qux;

@end
@interface NNSwizzledStrongifierTestClass (NNStrongGetters)

- (id)strongFoo; // Good
- (id)strongBar; // Bad -- strong
- (id)strongTLA; // Good
- (id)strongQux; // Bad -- ambiguous

@end
@implementation NNSwizzledStrongifierTestClass


@end



@implementation NNStrongifiedPropertiesTests

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

- (void)testBasicStrongGetter
{
    NNStrongifyTestClass *obj = [NNStrongifyTestClass new];
    id boo = [NSObject new];
    obj.foo = boo;
    XCTAssertEqual([obj strongFoo], boo, @"Basic weak property did not resolve a strong getter.");
    [boo self];
}

- (void)testCapitalizedStrongGetter
{
    NNStrongifyTestClass *obj = [NNStrongifyTestClass new];
    id boo = [NSObject new];
    obj.TLA = boo;
    XCTAssertEqual([obj strongTLA], boo, @"Capitalized weak property did not resolve a strong getter.");
    [boo self];
}

- (void)testStrongGetterWithStrongProperty
{
    XCTAssertThrows([[NNStrongifyTestClass new] strongBar], @"Strongified strong property access resulted in a valid IMP.");
}

- (void)testAmbiguousStrongGetter
{
    XCTAssertThrows([[NNStrongifyTestClass new] strongQux], @"Ambiguous property access found an IMP.");
}

- (void)testNilling
{
    NNStrongifyTestClass *obj = [NNStrongifyTestClass new];
    @autoreleasepool {
        id boo = [NSObject new];
        obj.foo = boo;
        [boo self];
    }
    XCTAssertNil([obj strongFoo], @"Weak property did not nil as expected.");
}

- (void)testSwizzledBasicStrongGetter
{
    NNSwizzledStrongifierTestClass *obj = [NNSwizzledStrongifierTestClass new];
    BOOL swizzled = nn_object_swizzleIsa(obj, [NNStrongifiedProperties class]);
    XCTAssertTrue(swizzled);
    id boo = [NSObject new];
    obj.foo = boo;
    XCTAssertEqual([obj strongFoo], boo, @"Basic weak property did not resolve a strong getter.");
    [boo self];
}

- (void)testSwizzledCapitalizedStrongGetter
{
    NNSwizzledStrongifierTestClass *obj = [NNSwizzledStrongifierTestClass new];
    BOOL swizzled = nn_object_swizzleIsa(obj, [NNStrongifiedProperties class]);
    XCTAssertTrue(swizzled);
    id boo = [NSObject new];
    obj.TLA = boo;
    XCTAssertEqual([obj strongTLA], boo, @"Capitalized weak property did not resolve a strong getter.");
    [boo self];
}

- (void)testSwizzledStrongGetterWithStrongProperty
{
    NNSwizzledStrongifierTestClass *obj = [NNSwizzledStrongifierTestClass new];
    nn_object_swizzleIsa(obj, [NNStrongifiedProperties class]);
    XCTAssertThrows([obj strongBar], @"Strongified strong property access resulted in a valid IMP.");
}

- (void)testSwizzledAmbiguousStrongGetter
{
    NNSwizzledStrongifierTestClass *obj = [NNSwizzledStrongifierTestClass new];
    nn_object_swizzleIsa(obj, [NNStrongifiedProperties class]);
    XCTAssertThrows([obj strongQux], @"Ambiguous property access resulted in a single IMP.");
}

- (void)testSwizzledNilling
{
    NNSwizzledStrongifierTestClass *obj = [NNSwizzledStrongifierTestClass new];
    BOOL swizzled = nn_object_swizzleIsa(obj, [NNStrongifiedProperties class]);
    XCTAssertTrue(swizzled);
    @autoreleasepool {
        id boo = [NSObject new];
        obj.foo = boo;
        [boo self];
    }
    XCTAssertNil([obj strongFoo], @"Weak property did not nil as expected.");
}

@end
