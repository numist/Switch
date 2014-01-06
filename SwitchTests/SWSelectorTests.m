//
//  SWSelectorTests.m
//  Switch
//
//  Created by Scott Perry on 01/05/14.
//  Copyright © 2014 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <XCTest/XCTest.h>
#import "SWSelector.h"


@interface SWSelectorTests : XCTestCase

@property (nonatomic, strong, readonly) NSOrderedSet *list0;
@property (nonatomic, strong, readonly) NSOrderedSet *list0123;

@end


@implementation SWSelectorTests

- (void)setUp
{
    [super setUp];
    
    self->_list0 = [NSOrderedSet orderedSetWithArray:@[@(0)]];
    self->_list0123 = [NSOrderedSet orderedSetWithArray:@[@(0), @(1), @(2), @(3)]];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#define updateWithEmptyAndCheck(_selector_) \
    _selector_ = [(_selector_) updateWithWindowGroups:[NSOrderedSet new]]; \
    XCTAssertNil((_selector_).selectedWindowGroup, @""); \
    XCTAssertEqual((_selector_).selectedIndex, (__typeof__((_selector_).selectedIndex))NSNotFound, @"");

- (void)testEmptySet;
{
    SWSelector *selector = [SWSelector new];
    updateWithEmptyAndCheck(selector);
}

- (void)testEmptySetIncrement;
{
    SWSelector *selector = [[SWSelector new] increment];
    updateWithEmptyAndCheck(selector);
}

- (void)testEmptySetIncrementWithoutWrapping;
{
    SWSelector *selector = [[SWSelector new] incrementWithoutWrapping];
    updateWithEmptyAndCheck(selector);
}

- (void)testEmptySetDecrement;
{
    SWSelector *selector = [[SWSelector new] decrement];
    updateWithEmptyAndCheck(selector);
}

- (void)testEmptySetDecrementWithoutWrapping;
{
    SWSelector *selector = [[SWSelector new] decrementWithoutWrapping];
    updateWithEmptyAndCheck(selector);
}

- (void)testEmpty;
{
    SWSelector *selector = [SWSelector new];
    XCTAssertNotNil(selector, @"");
    XCTAssertNil(selector.selectedWindowGroup, @"");
    XCTAssertEqual(selector.selectedIndex, (__typeof__(selector.selectedIndex))0, @"");
    
    updateWithEmptyAndCheck(selector);
}

- (void)testEmptyIncrement;
{
    SWSelector *selector = [SWSelector new];
    
    selector = [selector increment];
    XCTAssertNil(selector.selectedWindowGroup, @"");
    XCTAssertEqual(selector.selectedIndex, (__typeof__(selector.selectedIndex))1, @"");
    
    selector = [selector increment];
    XCTAssertNil(selector.selectedWindowGroup, @"");
    XCTAssertEqual(selector.selectedIndex, (__typeof__(selector.selectedIndex))2, @"");
    
    updateWithEmptyAndCheck(selector);
}

- (void)testEmptyIncrementWithoutWrapping;
{
    SWSelector *selector = [SWSelector new];
    
    selector = [selector incrementWithoutWrapping];
    XCTAssertNil(selector.selectedWindowGroup, @"");
    XCTAssertEqual(selector.selectedIndex, (__typeof__(selector.selectedIndex))1, @"");
    
    selector = [selector incrementWithoutWrapping];
    XCTAssertNil(selector.selectedWindowGroup, @"");
    XCTAssertEqual(selector.selectedIndex, (__typeof__(selector.selectedIndex))2, @"");
    
    updateWithEmptyAndCheck(selector);
}

- (void)testEmptyDecrement;
{
    SWSelector *selector = [SWSelector new];
    
    selector = [selector decrement];
    XCTAssertNil(selector.selectedWindowGroup, @"");
    XCTAssertEqual(selector.selectedIndex, (__typeof__(selector.selectedIndex))-1, @"");
    
    selector = [selector decrement];
    XCTAssertNil(selector.selectedWindowGroup, @"");
    XCTAssertEqual(selector.selectedIndex, (__typeof__(selector.selectedIndex))-2, @"");
    
    updateWithEmptyAndCheck(selector);
}

- (void)testEmptyDecrementWithoutWrapping;
{
    SWSelector *selector = [SWSelector new];
    
    selector = [selector decrementWithoutWrapping];
    XCTAssertNil(selector.selectedWindowGroup, @"");
    XCTAssertEqual(selector.selectedIndex, (__typeof__(selector.selectedIndex))-1, @"");
    
    selector = [selector decrementWithoutWrapping];
    XCTAssertNil(selector.selectedWindowGroup, @"");
    XCTAssertEqual(selector.selectedIndex, (__typeof__(selector.selectedIndex))-2, @"");
    
    updateWithEmptyAndCheck(selector);
}

- (void)testSet;
{
    SWSelector *selector = [[SWSelector new] updateWithWindowGroups:self.list0123];
    XCTAssertEqualObjects(selector.selectedWindowGroup, self.list0123[0], @"");
    XCTAssertEqual(selector.selectedIndex, (__typeof__(selector.selectedIndex))0, @"");
}

- (void)testIncrement;
{
    SWSelector *selector = [[SWSelector new] updateWithWindowGroups:self.list0123];
    
    selector = [selector increment];
    XCTAssertEqualObjects(selector.selectedWindowGroup, self.list0123[1], @"");
    XCTAssertEqual(selector.selectedIndex, (__typeof__(selector.selectedIndex))1, @"");
    
    selector = [selector increment];
    XCTAssertEqualObjects(selector.selectedWindowGroup, self.list0123[2], @"");
    XCTAssertEqual(selector.selectedIndex, (__typeof__(selector.selectedIndex))2, @"");

    selector = [selector increment];
    XCTAssertEqualObjects(selector.selectedWindowGroup, self.list0123[3], @"");
    XCTAssertEqual(selector.selectedIndex, (__typeof__(selector.selectedIndex))3, @"");

    selector = [selector increment];
    XCTAssertEqualObjects(selector.selectedWindowGroup, self.list0123[0], @"");
    XCTAssertEqual(selector.selectedIndex, (__typeof__(selector.selectedIndex))0, @"");
    
    selector = [selector increment];
    XCTAssertEqualObjects(selector.selectedWindowGroup, self.list0123[1], @"");
    XCTAssertEqual(selector.selectedIndex, (__typeof__(selector.selectedIndex))1, @"");
    
    updateWithEmptyAndCheck(selector);
}

- (void)testIncrementWithoutWrapping;
{
    SWSelector *selector = [[SWSelector new] updateWithWindowGroups:self.list0123];
    
    selector = [selector incrementWithoutWrapping];
    XCTAssertEqualObjects(selector.selectedWindowGroup, self.list0123[1], @"");
    XCTAssertEqual(selector.selectedIndex, (__typeof__(selector.selectedIndex))1, @"");
    
    selector = [selector incrementWithoutWrapping];
    XCTAssertEqualObjects(selector.selectedWindowGroup, self.list0123[2], @"");
    XCTAssertEqual(selector.selectedIndex, (__typeof__(selector.selectedIndex))2, @"");
    
    selector = [selector incrementWithoutWrapping];
    XCTAssertEqualObjects(selector.selectedWindowGroup, self.list0123[3], @"");
    XCTAssertEqual(selector.selectedIndex, (__typeof__(selector.selectedIndex))3, @"");
    
    selector = [selector incrementWithoutWrapping];
    XCTAssertEqualObjects(selector.selectedWindowGroup, self.list0123[3], @"");
    XCTAssertEqual(selector.selectedIndex, (__typeof__(selector.selectedIndex))3, @"");
    
    updateWithEmptyAndCheck(selector);
}

- (void)testDecrement;
{
    SWSelector *selector = [[SWSelector new] updateWithWindowGroups:self.list0123];
    
    selector = [selector decrement];
    XCTAssertEqualObjects(selector.selectedWindowGroup, self.list0123[3], @"");
    XCTAssertEqual(selector.selectedIndex, (__typeof__(selector.selectedIndex))3, @"");
    
    selector = [selector decrement];
    XCTAssertEqualObjects(selector.selectedWindowGroup, self.list0123[2], @"");
    XCTAssertEqual(selector.selectedIndex, (__typeof__(selector.selectedIndex))2, @"");
    
    selector = [selector decrement];
    XCTAssertEqualObjects(selector.selectedWindowGroup, self.list0123[1], @"");
    XCTAssertEqual(selector.selectedIndex, (__typeof__(selector.selectedIndex))1, @"");
    
    selector = [selector decrement];
    XCTAssertEqualObjects(selector.selectedWindowGroup, self.list0123[0], @"");
    XCTAssertEqual(selector.selectedIndex, (__typeof__(selector.selectedIndex))0, @"");
    
    updateWithEmptyAndCheck(selector);
}

- (void)testDecrementWithoutWrapping;
{
    SWSelector *selector = [[SWSelector new] updateWithWindowGroups:self.list0123];
    
    selector = [selector decrementWithoutWrapping];
    XCTAssertEqualObjects(selector.selectedWindowGroup, self.list0123[0], @"");
    XCTAssertEqual(selector.selectedIndex, (__typeof__(selector.selectedIndex))0, @"");
    
    updateWithEmptyAndCheck(selector);
}

@end
