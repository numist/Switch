//
//  NNDelegateProxyTests.m
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


@protocol MYClassDelegate <NSObject>

- (void)objectCalledDelegateMethod:(id)obj;
- (oneway void)asyncMethod;

@optional

- (void)unimplementedOptionalMethod;
- (oneway void)unimplementedOnewayOptionalMethod;

@end


@interface NNDelegateProxyTests : XCTestCase <MYClassDelegate>

@end


@interface MYClass : NSObject

@property (strong) id<MYClassDelegate> delegateProxy;

@end

@implementation MYClass

- (instancetype)initWithDelegate:(id)delegate;
{
    if (!(self = [super init])) { return nil; }
    
    _delegateProxy = [NNDelegateProxy proxyWithDelegate:delegate protocol:@protocol(MYClassDelegate)];
    
    return self;
}

- (void)globalAsync;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.delegateProxy objectCalledDelegateMethod:self];
    });
}

- (void)globalSync;
{
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.delegateProxy objectCalledDelegateMethod:self];
    });
}

- (void)mainAsync;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegateProxy objectCalledDelegateMethod:self];
    });
}

- (void)invalid;
{
    [(id)self.delegateProxy willChangeValueForKey:@""];
}

- (void)async;
{
    [self.delegateProxy asyncMethod];
}

- (void)optional;
{
    [self.delegateProxy unimplementedOptionalMethod];
}

- (void)onewayOptional;
{
    [self.delegateProxy unimplementedOnewayOptionalMethod];
}

@end


static dispatch_group_t group;


@implementation NNDelegateProxyTests

- (void)setUp
{
    [super setUp];
    
    group = dispatch_group_create();
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testGlobalAsync;
{
    dispatch_group_enter(group);
    [[[MYClass alloc] initWithDelegate:self] globalAsync];
    
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:0.1];
    while (!despatch_group_yield(group) && [[NSDate date] compare:timeout] == NSOrderedAscending);
    XCTAssertFalse(dispatch_group_wait(group, DISPATCH_TIME_NOW), @"Delegate message was never received (timed out)!");
}

- (void)testGlobalSync;
{
    dispatch_group_enter(group);
    [[[MYClass alloc] initWithDelegate:self] globalSync];
    XCTAssertFalse(dispatch_group_wait(group, DISPATCH_TIME_NOW), @"Delegate message was not received synchronously!");
}

- (void)testMainAsync;
{
    dispatch_group_enter(group);
    [[[MYClass alloc] initWithDelegate:self] mainAsync];
    
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:0.1];
    while (!despatch_group_yield(group) && [[NSDate date] compare:timeout] == NSOrderedAscending);
    XCTAssertFalse(dispatch_group_wait(group, DISPATCH_TIME_NOW), @"Delegate message was never received (timed out)!");
}

- (void)testInvalidDelegateMethod;
{
    XCTAssertThrows([[[MYClass alloc] initWithDelegate:self] invalid], @"Invalid delegate method was allowed to pass through!");
}

- (void)testOnewayAsync;
{
    dispatch_group_enter(group);
    [[[MYClass alloc] initWithDelegate:self] async];
    
    XCTAssertTrue(dispatch_group_wait(group, DISPATCH_TIME_NOW), @"Delegate message was not supposed to be sent synchronously.");
    
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:0.1];
    while (!despatch_group_yield(group) && [[NSDate date] compare:timeout] == NSOrderedAscending);
    XCTAssertFalse(dispatch_group_wait(group, DISPATCH_TIME_NOW), @"Delegate message was never received (timed out)!");
}

- (void)testOptional;
{
    XCTAssertNoThrow([[[MYClass alloc] initWithDelegate:self] optional], @"Sending optional messages to delegate proxies should never blow up.");
    XCTAssertNoThrow([[[MYClass alloc] initWithDelegate:self] onewayOptional], @"Sending optional messages to delegate proxies should never blow up.");
}


#pragma mark MYClassDelegate

- (oneway void)asyncMethod;
{
    [self objectCalledDelegateMethod:nil];
}

- (void)objectCalledDelegateMethod:(id)obj;
{
    XCTAssertTrue([[NSThread currentThread] isMainThread], @"Delegate message was not dispatched on the main queue!");
    dispatch_group_leave(group);
}

@end
