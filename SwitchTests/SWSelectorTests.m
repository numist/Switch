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
@property (nonatomic, strong, readonly) NSOrderedSet *list321;

@end


@implementation SWSelectorTests

- (void)setUp
{
    [super setUp];
    
    self->_list0 = [NSOrderedSet orderedSetWithArray:@[@(0)]];
    self->_list0123 = [NSOrderedSet orderedSetWithArray:@[@(0), @(1), @(2), @(3)]];
    self->_list321 = [NSOrderedSet orderedSetWithArray:@[@(3), @(2), @(1)]];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#define updateWithEmptyAndCheck(_selector_) \
    _selector_ = [(_selector_) updateWithWindowList:[NSOrderedSet new]]; \
    XCTAssertNil((_selector_).selectedWindow); \
    XCTAssertEqual((_selector_).selectedIndex, NSNotFound);

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
    XCTAssertNotNil(selector);
    XCTAssertNil(selector.selectedWindow);
    XCTAssertEqual(selector.selectedIndex, 0);
    
    updateWithEmptyAndCheck(selector);
}

- (void)testEmptyIncrement;
{
    SWSelector *selector = [SWSelector new];
    
    selector = [selector increment];
    XCTAssertNil(selector.selectedWindow);
    XCTAssertEqual(selector.selectedIndex, 1);
    
    selector = [selector increment];
    XCTAssertNil(selector.selectedWindow);
    XCTAssertEqual(selector.selectedIndex, 2);
    
    updateWithEmptyAndCheck(selector);
}

- (void)testEmptyIncrementWithoutWrapping;
{
    SWSelector *selector = [SWSelector new];
    
    selector = [selector incrementWithoutWrapping];
    XCTAssertNil(selector.selectedWindow);
    XCTAssertEqual(selector.selectedIndex, 1);
    
    selector = [selector incrementWithoutWrapping];
    XCTAssertNil(selector.selectedWindow);
    XCTAssertEqual(selector.selectedIndex, 2);
    
    updateWithEmptyAndCheck(selector);
}

- (void)testEmptyDecrement;
{
    SWSelector *selector = [SWSelector new];
    
    selector = [selector decrement];
    XCTAssertNil(selector.selectedWindow);
    XCTAssertEqual(selector.selectedIndex, -1);
    
    selector = [selector decrement];
    XCTAssertNil(selector.selectedWindow);
    XCTAssertEqual(selector.selectedIndex, -2);
    
    updateWithEmptyAndCheck(selector);
}

- (void)testEmptyDecrementWithoutWrapping;
{
    SWSelector *selector = [SWSelector new];
    
    selector = [selector decrementWithoutWrapping];
    XCTAssertNil(selector.selectedWindow);
    XCTAssertEqual(selector.selectedIndex, -1);
    
    selector = [selector decrementWithoutWrapping];
    XCTAssertNil(selector.selectedWindow);
    XCTAssertEqual(selector.selectedIndex, -2);
    
    updateWithEmptyAndCheck(selector);
}

- (void)testSet;
{
    SWSelector *selector = [[SWSelector new] updateWithWindowList:self.list0123];
    XCTAssertEqualObjects(selector.selectedWindow, self.list0123[0]);
    XCTAssertEqual(selector.selectedIndex, 0);
}

- (void)testIncrement;
{
    SWSelector *selector = [[SWSelector new] updateWithWindowList:self.list0123];
    
    selector = [selector increment];
    XCTAssertEqualObjects(selector.selectedWindow, self.list0123[1]);
    XCTAssertEqual(selector.selectedIndex, 1);
    
    selector = [selector increment];
    XCTAssertEqualObjects(selector.selectedWindow, self.list0123[2]);
    XCTAssertEqual(selector.selectedIndex, 2);

    selector = [selector increment];
    XCTAssertEqualObjects(selector.selectedWindow, self.list0123[3]);
    XCTAssertEqual(selector.selectedIndex, 3);

    selector = [selector increment];
    XCTAssertEqualObjects(selector.selectedWindow, self.list0123[0]);
    XCTAssertEqual(selector.selectedIndex, 0);
    
    selector = [selector increment];
    XCTAssertEqualObjects(selector.selectedWindow, self.list0123[1]);
    XCTAssertEqual(selector.selectedIndex, 1);
    
    updateWithEmptyAndCheck(selector);
}

- (void)testIncrementWithoutWrapping;
{
    SWSelector *selector = [[SWSelector new] updateWithWindowList:self.list0123];
    
    selector = [selector incrementWithoutWrapping];
    XCTAssertEqualObjects(selector.selectedWindow, self.list0123[1]);
    XCTAssertEqual(selector.selectedIndex, 1);
    
    selector = [selector incrementWithoutWrapping];
    XCTAssertEqualObjects(selector.selectedWindow, self.list0123[2]);
    XCTAssertEqual(selector.selectedIndex, 2);
    
    selector = [selector incrementWithoutWrapping];
    XCTAssertEqualObjects(selector.selectedWindow, self.list0123[3]);
    XCTAssertEqual(selector.selectedIndex, 3);
    
    selector = [selector incrementWithoutWrapping];
    XCTAssertEqualObjects(selector.selectedWindow, self.list0123[3]);
    XCTAssertEqual(selector.selectedIndex, 3);
    
    updateWithEmptyAndCheck(selector);
}

- (void)testDecrement;
{
    SWSelector *selector = [[SWSelector new] updateWithWindowList:self.list0123];
    
    selector = [selector decrement];
    XCTAssertEqualObjects(selector.selectedWindow, self.list0123[3]);
    XCTAssertEqual(selector.selectedIndex, 3);
    
    selector = [selector decrement];
    XCTAssertEqualObjects(selector.selectedWindow, self.list0123[2]);
    XCTAssertEqual(selector.selectedIndex, 2);
    
    selector = [selector decrement];
    XCTAssertEqualObjects(selector.selectedWindow, self.list0123[1]);
    XCTAssertEqual(selector.selectedIndex, 1);
    
    selector = [selector decrement];
    XCTAssertEqualObjects(selector.selectedWindow, self.list0123[0]);
    XCTAssertEqual(selector.selectedIndex, 0);
    
    updateWithEmptyAndCheck(selector);
}

- (void)testDecrementWithoutWrapping;
{
    SWSelector *selector = [[SWSelector new] updateWithWindowList:self.list0123];
    
    selector = [selector decrementWithoutWrapping];
    XCTAssertEqualObjects(selector.selectedWindow, self.list0123[0]);
    XCTAssertEqual(selector.selectedIndex, 0);
    
    updateWithEmptyAndCheck(selector);
}

- (void)testDecrementBeforeUpdate;
{
    SWSelector *selector = [SWSelector new];
    
    selector = [selector decrement];
    selector = [selector updateWithWindowList:self.list0123];

    XCTAssertEqualObjects(selector.selectedWindow, self.list0123.lastObject);
    XCTAssertEqual(selector.selectedIndex, (self.list0123.count - 1));
    
    updateWithEmptyAndCheck(selector);
}

- (void)testIncrementBeforeUpdate;
{
    SWSelector *selector = [SWSelector new];
    
    selector = [selector increment];
    selector = [selector increment];
    selector = [selector increment];
    selector = [selector increment];
    selector = [selector updateWithWindowList:self.list0123];
    
    XCTAssertEqualObjects(selector.selectedWindow, self.list0123.firstObject);
    XCTAssertEqual(selector.selectedIndex, 0);
    
    updateWithEmptyAndCheck(selector);
}

- (void)testUpdateWithSmallerList;
{
    SWSelector *selector = [SWSelector new];
    
    selector = [selector increment];
    selector = [selector increment];
    selector = [selector updateWithWindowList:self.list0123];
    selector = [selector updateWithWindowList:self.list0];
    
    XCTAssertEqualObjects(selector.selectedWindow, self.list0123.firstObject);
    XCTAssertEqual(selector.selectedIndex, 0);
    
    updateWithEmptyAndCheck(selector);
}

- (void)testUpdateWithSharedSelectedObject;
{
    SWSelector *selector = [SWSelector new];

    selector = [selector increment];
    selector = [selector increment];

    selector = [selector updateWithWindowList:self.list0123];
    XCTAssertEqualObjects(selector.selectedWindow, self.list0123[2]);

    selector = [selector updateWithWindowList:self.list321];
    XCTAssertEqualObjects(selector.selectedWindow, self.list0123[2]);

    XCTAssertEqual(selector.selectedIndex, 1);
    
    updateWithEmptyAndCheck(selector);
}

- (void)testDeselectionWithUpdateToNotFoundIndex;
{
    SWSelector *selector = [SWSelector new];
    selector = [selector updateWithWindowList:self.list0123];

    XCTAssertEqualObjects(selector.selectedWindow, self.list0123[0]);
    XCTAssertEqual(selector.selectedIndex, 0);

    selector = [selector selectIndex:NSNotFound];

    XCTAssertNil(selector.selectedWindow);
    XCTAssertEqual(selector.selectedIndex, NSNotFound);
}

- (void)testIncrementAfterDeselection;
{
    SWSelector *selector = [SWSelector new];
    selector = [selector updateWithWindowList:self.list0123];
    selector = [selector selectIndex:NSNotFound];
    selector = [selector increment];
    XCTAssertEqualObjects(selector.selectedWindow, self.list0123[0]);
    XCTAssertEqual(selector.selectedIndex, 0);
}

- (void)testIncrementAfterDeselectionNoWrap;
{
    SWSelector *selector = [SWSelector new];
    selector = [selector updateWithWindowList:self.list0123];
    selector = [selector selectIndex:NSNotFound];
    selector = [selector incrementWithoutWrapping];
    XCTAssertEqualObjects(selector.selectedWindow, self.list0123[0]);
    XCTAssertEqual(selector.selectedIndex, 0);
}

- (void)testDecrementAfterDeselection;
{
    SWSelector *selector = [SWSelector new];
    selector = [selector updateWithWindowList:self.list0123];
    selector = [selector selectIndex:NSNotFound];
    selector = [selector decrement];
    XCTAssertEqualObjects(selector.selectedWindow, self.list0123[3]);
    XCTAssertEqual(selector.selectedIndex, 3);
}

- (void)testDecrementAfterDeselectionNoWrap;
{
    SWSelector *selector = [SWSelector new];
    selector = [selector updateWithWindowList:self.list0123];
    selector = [selector selectIndex:NSNotFound];
    selector = [selector decrementWithoutWrapping];
    XCTAssertEqualObjects(selector.selectedWindow, self.list0123[3]);
    XCTAssertEqual(selector.selectedIndex, 3);
}

- (void)testNoSelectedIndex;
{
    SWSelector *selector = [SWSelector new];
    NSUInteger selectedUIndex = [selector selectedUIndex];
    NSInteger selectedIndex = [selector selectedIndex];
    XCTAssertEqual(selectedUIndex, 0);
    XCTAssertEqual(selectedIndex, 0);
}

- (void)testEmptyList;
{
    SWSelector *selector = [SWSelector new];
    selector = [selector updateWithWindowList:[NSOrderedSet orderedSet]];
    selector = [selector increment];
    XCTAssertEqual(selector.selectedIndex, NSNotFound);
    selector = [selector decrement];
    XCTAssertEqual(selector.selectedIndex, NSNotFound);
}

- (void)testSelectInvalidIndex;
{
    SWSelector *selector = [SWSelector new];
    
    selector = [selector decrement];
    XCTAssertThrows(selector.selectedUIndex);
    
    selector = [selector updateWithWindowList:[NSOrderedSet orderedSet]];
    XCTAssertThrows([selector selectIndex:0]);
    selector = [selector updateWithWindowList:self.list0123];
    XCTAssertThrows([selector selectIndex:-1]);
    XCTAssertThrows([selector selectIndex:50]);
    selector = [selector selectIndex:NSNotFound];
    XCTAssertEqual(selector.selectedIndex, NSNotFound);
}

@end
