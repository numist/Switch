//
//  NNCleanupProxyTests.m
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
#import <NNKit/NNCleanupProxy.h>


@protocol NNCleanupProxyTestProtocol <NSObject>
- (BOOL)someKindOfSelectorWithObject:(id)foo;
@end


@protocol NNCleanupProxyTestProtocol2 <NNCleanupProxyTestProtocol>
- (BOOL)someKindOfSelectorWithObject2:(id)foo;
@end


@interface NNCleanupProxyTestClass : NSObject <NNCleanupProxyTestProtocol2>
@end
@implementation NNCleanupProxyTestClass
- (NSUInteger)hash;
{
    return (uintptr_t)self;
}

- (BOOL)isEqual:(NSObject *)object;
{
    return self.hash == object.hash;
}

- (BOOL)someKindOfSelectorWithObject:(id)foo;
{
    return YES;
}
- (BOOL)someKindOfSelectorWithObject2:(id)foo;
{
    return YES;
}
- (BOOL)anotherKindofSelectorWithObject:(id)foo;
{
    return YES;
}
@end


@interface NNCleanupProxyTests : XCTestCase

@end


@implementation NNCleanupProxyTests

- (void)testCleanupBlock;
{
    __block BOOL cleanupComplete = NO;
    @autoreleasepool {
        __attribute__((objc_precise_lifetime)) id foo = [NSObject new];
        NNCleanupProxy *proxy = [NNCleanupProxy cleanupProxyForTarget:foo withKey:(uintptr_t)foo];
        proxy.cleanupBlock = ^{ cleanupComplete = YES; };
    }
    XCTAssertTrue(cleanupComplete, @"");
}

- (void)testProtocolMethodDispatch;
{
    @autoreleasepool {
        __attribute__((objc_precise_lifetime)) id foo = [NNCleanupProxyTestClass new];
        id<NNCleanupProxyTestProtocol2> proxy = (id)[NNCleanupProxy cleanupProxyForTarget:foo conformingToProtocol:@protocol(NNCleanupProxyTestProtocol2) withKey:(uintptr_t)foo];
        XCTAssertTrue([proxy someKindOfSelectorWithObject:self], @"");
        XCTAssertTrue([proxy someKindOfSelectorWithObject2:self], @"");
    }
}

- (void)testUndeclaredMethodDispatch;
{
    @autoreleasepool {
        __attribute__((objc_precise_lifetime)) id foo = [NNCleanupProxyTestClass new];
        NNCleanupProxyTestClass *proxy = (id)[NNCleanupProxy cleanupProxyForTarget:foo withKey:(uintptr_t)foo];
        XCTAssertThrows([proxy someKindOfSelectorWithObject:self], @"");
        XCTAssertThrows([proxy someKindOfSelectorWithObject2:self], @"");
        XCTAssertThrows([proxy anotherKindofSelectorWithObject:self], @"");
    }
}

- (void)testExplicitlyDeclaredMethodDispatch;
{
    @autoreleasepool {
        __attribute__((objc_precise_lifetime)) id foo = [NNCleanupProxyTestClass new];
        NNCleanupProxy *proxy = [NNCleanupProxy cleanupProxyForTarget:foo withKey:(uintptr_t)foo];
        [proxy cacheMethodSignatureForSelector:@selector(anotherKindofSelectorWithObject:)];
        
        NNCleanupProxyTestClass *castProxy = (id)proxy;
        XCTAssertTrue([castProxy anotherKindofSelectorWithObject:self], @"");
    }
}

- (void)testNilMessagingAfterTargetDealloc;
{
    NNCleanupProxyTestClass *proxy = nil;
    
    @autoreleasepool {
        __attribute__((objc_precise_lifetime)) id foo = [NNCleanupProxyTestClass new];
        proxy = (id)[NNCleanupProxy cleanupProxyForTarget:foo conformingToProtocol:@protocol(NNCleanupProxyTestProtocol2) withKey:(uintptr_t)foo];
    }

    XCTAssertThrows([proxy someKindOfSelectorWithObject:self], @"");
    XCTAssertThrows([proxy someKindOfSelectorWithObject2:self], @"");
    XCTAssertThrows([proxy anotherKindofSelectorWithObject:self], @"");
}

- (void)testCachingInvalidMethod;
{
    @autoreleasepool {
        __attribute__((objc_precise_lifetime)) id foo = [NNCleanupProxyTestClass new];
        NNCleanupProxy *proxy = [NNCleanupProxy cleanupProxyForTarget:foo withKey:(uintptr_t)foo];
        XCTAssertThrows([proxy cacheMethodSignatureForSelector:@selector(testCachingInvalidMethod)]);
    }
}

- (void)testProxyMatchesObject;
{
    @autoreleasepool {
        __attribute__((objc_precise_lifetime)) id foo = [NNCleanupProxyTestClass new];
        NNCleanupProxy *proxy = [NNCleanupProxy cleanupProxyForTarget:foo withKey:(uintptr_t)foo];
        
        XCTAssertTrue([foo isEqual:proxy]);
        NSSet *set = [NSSet setWithObject:proxy];
        XCTAssertTrue([set containsObject:foo]);

        XCTAssertTrue([proxy isEqual:foo]);
        set = [NSSet setWithObject:foo];
        XCTAssertTrue([set containsObject:proxy]);
    }
}

@end
