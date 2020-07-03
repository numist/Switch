//
//  nn_isaSwizzlingTests.m
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
#import <Foundation/Foundation.h>

// Class ISAGood can be used for swizzling any NSObject
@protocol ISAGood <NSObject> - (void)foo; @end
@interface ISAGood : NSObject <ISAGood> @end
@implementation ISAGood - (void)foo { NSLog(@"foooooo! "); } - (void)doesNotRecognizeSelector:(__attribute__((unused)) SEL)aSelector { NSLog(@"FAUX NOES!"); } @end


// Class ISANoSharedAncestor can only be used to swizzle instances that areKindOf NSArray
@protocol ISANoSharedAncestor <NSObject> - (void)foo; @end
@interface ISANoSharedAncestor : NSArray <ISANoSharedAncestor> @end
@implementation ISANoSharedAncestor - (void)foo { NSLog(@"foooooo! "); } @end


// Class ISANoProtocol doesn't have a corersponding protocol and cannot be used for swizzling
@interface ISANoProtocol : NSObject @end
@implementation ISANoProtocol - (void)foo { NSLog(@"foooooo! "); } @end


// Class ISAAddsProperties adds properties to its superclass and thus cannot be used for swizzling
@protocol ISAAddsProperties <NSObject> - (void)foo; @end
@interface ISAAddsProperties : NSObject <ISAAddsProperties> @property (nonatomic, assign) NSUInteger bar; @end
@implementation ISAAddsProperties - (void)foo { NSLog(@"foooooo! "); } @end


// Class ISAAddsProperties adds legal properties to its superclass
@protocol ISAAddsLegalProperties <NSObject> @end
@interface ISAAddsLegalProperties : NSObject <ISAAddsLegalProperties> @property (nonatomic, readonly, assign) NSUInteger bar; @end
@implementation ISAAddsLegalProperties @dynamic bar; - (NSUInteger)bar { NSLog(@"foooooo! "); return 7; } @end


// Class ISAAddsIvars adds ivars to its superclass and thus cannot be used for swizzling
@protocol ISAAddsIvars <NSObject> - (void)foo; @end
@interface ISAAddsIvars : NSObject <ISAAddsIvars> { NSUInteger bar; } @end
@implementation ISAAddsIvars - (void)foo { NSLog(@"foooooo! "); } @end


// Class ISAExtraProtocol adds an extra protocol that the swizzled object must conform to.
@protocol ISAExtraProtocol <NSObject> - (void)foo; @end
@interface ISAExtraProtocol : NSObject <ISAExtraProtocol, NSCacheDelegate> @end
@implementation ISAExtraProtocol - (void)foo { NSLog(@"foooooo! "); } @end

// Class ISANameConflicts can be used for swizzling any NSObject and provides a class and instance method with the same selector
@protocol ISANameConflicts <NSObject> - (BOOL)isClassMethod; + (BOOL)isClassMethod; @end
@interface ISANameConflicts : NSObject <ISANameConflicts> @end
@implementation ISANameConflicts - (BOOL)isClassMethod { return NO; } + (BOOL)isClassMethod { return YES; } @end

@interface nn_isaSwizzlingTests : XCTestCase

@end

@implementation nn_isaSwizzlingTests

- (void)testInteractionWithKVO;
{
    #pragma message "Not even sure how to do this without making the world's biggest mess. There's no reason why it shouldn't work, but it's not tested."
}

- (void)testExtraProtocol;
{
    NSObject *bar = [[NSObject alloc] init];
    
    XCTAssertFalse([bar conformsToProtocol:@protocol(ISAExtraProtocol)], @"Object is not virgin");
    
    XCTAssertTrue(nn_object_swizzleIsa(bar, [ISAExtraProtocol class]), @"Failed to swizzle object");
    
    XCTAssertTrue([bar conformsToProtocol:@protocol(ISAExtraProtocol)], @"Object is not swizzled correctly");
    XCTAssertTrue([bar conformsToProtocol:@protocol(NSCacheDelegate)], @"Object is missing extra protocol");
}

- (void)testAddsProperties;
{
    NSObject *bar = [[NSObject alloc] init];
    
    XCTAssertFalse(nn_object_swizzleIsa(bar, [ISAAddsProperties class]), @"Failed to fail to swizzle object");
}

- (void)testAddsLegalProperties;
{
    NSObject *bar = [[NSObject alloc] init];
    
    XCTAssertTrue(nn_object_swizzleIsa(bar, [ISAAddsLegalProperties class]), @"Failed to swizzle object");
    XCTAssertEqual(((ISAAddsLegalProperties *)bar).bar, (NSUInteger)7, @"Oops properties");
}

- (void)testAddsIvars;
{
    NSObject *bar = [[NSObject alloc] init];
    
    XCTAssertFalse(nn_object_swizzleIsa(bar, [ISAAddsIvars class]), @"Failed to fail to swizzle object");
}

- (void)testDoubleSwizzle;
{
    NSObject *bar = [[NSObject alloc] init];
    
    XCTAssertFalse([bar conformsToProtocol:@protocol(ISAGood)], @"Object is not virgin");
    XCTAssertFalse([bar respondsToSelector:@selector(foo)], @"Object is not virgin");
    
    XCTAssertThrows([(id<ISAGood>)bar foo], @"foooooo!");
    XCTAssertThrows([bar doesNotRecognizeSelector:nil], @"FAUX NOES!");
    
    XCTAssertTrue(nn_object_swizzleIsa(bar, [ISAGood class]), @"Failed to swizzle object");
    XCTAssertTrue(nn_object_swizzleIsa(bar, [ISAGood class]), @"Failed to swizzle object");
    
    XCTAssertTrue([bar conformsToProtocol:@protocol(ISAGood)], @"Object is not swizzled correctly");
    
    XCTAssertTrue([bar respondsToSelector:@selector(foo)], @"Object is not swizzled correctly");
    
    XCTAssertNoThrow([(id<ISAGood>)bar foo], @"foooooo!");
    XCTAssertNoThrow([bar doesNotRecognizeSelector:nil], @"FAUX NOES!");
    
    XCTAssertEqual([bar class], [NSObject class], @"Object should report itself as still being an NSObject");
}

- (void)testSharedAncestor;
{
    NSObject *bar = [[NSObject alloc] init];
    NSArray *arr = [[NSArray alloc] init];
    
    XCTAssertFalse(nn_object_swizzleIsa(bar, [ISANoSharedAncestor class]), @"Failed to fail to swizzle object");
    XCTAssertTrue(nn_object_swizzleIsa(arr, [ISANoSharedAncestor class]), @"Failed to swizzle object");
}

- (void)testNoProto;
{
    NSObject *bar = [[NSObject alloc] init];
    
    XCTAssertTrue(nn_object_swizzleIsa(bar, [ISANoProtocol class]), @"Failed to swizzle object");
}

- (void)testImplementationDetails;
{
    NSObject *bar = [[NSObject alloc] init];
    
#   pragma clang diagnostic push
#   pragma clang diagnostic ignored "-Wundeclared-selector"
    
    XCTAssertFalse([bar respondsToSelector:@selector(actualClass)], @"Object is not virgin");
    XCTAssertThrows([bar performSelector:@selector(actualClass)], @"actualClass exists?");
    
    XCTAssertTrue(nn_object_swizzleIsa(bar, [ISAGood class]), @"Failed to swizzle object");
    
    XCTAssertTrue([bar respondsToSelector:@selector(_swizzler_actualClass)], @"Object is not swizzled correctly");
    XCTAssertNoThrow([bar performSelector:@selector(_swizzler_actualClass)], @"Internal swizzle method actualClass not implemented?");
    
#   pragma clang diagnostic pop

}

- (void)testGood;
{
    NSObject *bar = [[NSObject alloc] init];
    
    XCTAssertFalse([bar conformsToProtocol:@protocol(ISAGood)], @"Object is not virgin");
    XCTAssertFalse([bar respondsToSelector:@selector(foo)], @"Object is not virgin");
    
    XCTAssertThrows([(id<ISAGood>)bar foo], @"foooooo!");
    XCTAssertThrows([bar doesNotRecognizeSelector:nil], @"FAUX NOES!");
    
    XCTAssertTrue(nn_object_swizzleIsa(bar, [ISAGood class]), @"Failed to swizzle object");
    
    XCTAssertTrue([bar conformsToProtocol:@protocol(ISAGood)], @"Object is not swizzled correctly");
    XCTAssertTrue([bar isKindOfClass:[ISAGood class]], @"Object is not swizzled correctly");
    
    XCTAssertTrue([bar respondsToSelector:@selector(foo)], @"Object is not swizzled correctly");
    
    XCTAssertNoThrow([(id<ISAGood>)bar foo], @"foooooo!");
    XCTAssertNoThrow([bar doesNotRecognizeSelector:nil], @"FAUX NOES!");
    
    XCTAssertEqual([bar class], [NSObject class], @"Object should report itself as still being an NSObject");
}

- (void)testSelectorNameConflicts;
{
    NSObject *bar = [[NSObject alloc] init];
    XCTAssertTrue(nn_object_swizzleIsa(bar, [ISANameConflicts class]), @"Failed to swizzle object");
    
    XCTAssertFalse([(id<ISANameConflicts>)bar isClassMethod], @"Instance method was swizzled with the class method");
    XCTAssertTrue([object_getClass(bar) isClassMethod], @"Class method was swizzled with the instance method");
    XCTAssertEqual([bar class], [NSObject class], @"Object should report itself as still being an NSObject");
}

@end
