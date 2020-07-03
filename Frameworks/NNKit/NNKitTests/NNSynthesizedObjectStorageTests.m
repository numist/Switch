//
//  NNSynthesizedObjectStorageTests.m
//  NNKit
//
//  Created by Scott Perry on 06/23/15.
//  Copyright © 2015 Scott Perry. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "runtime.h"

#import "memoize.h"


@interface NNSynthesizedObjectStorageTestObject : NSObject <NSCopying>

@property (nonatomic, strong) NSNumber *number;

@end


@implementation NNSynthesizedObjectStorageTestObject

- (instancetype)init {
    if (!(self = [super init])) { return nil; }
    _number = @(arc4random());
    return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    NNSynthesizedObjectStorageTestObject *result = [NNSynthesizedObjectStorageTestObject new];
    result.number = self.number;
    return result;
}

- (BOOL)isEqual:(id)object {
    return ([object isKindOfClass:[self class]] && [[object number] isEqualToNumber:self.number]);
}

@end


@interface NNSynthesizedObjectStorageTests : XCTestCase
@end


@interface NNSynthesizedObjectStorageTests (NNSynthesizedProperties)

@property (nonatomic, strong) NNSynthesizedObjectStorageTestObject *prop_ns;
@property (nonatomic, assign) NNSynthesizedObjectStorageTestObject *prop_na;
@property (nonatomic, weak) NNSynthesizedObjectStorageTestObject *prop_nw;
@property (nonatomic, copy) NNSynthesizedObjectStorageTestObject *prop_nc;

@end


@implementation NNSynthesizedObjectStorageTests (NNSynthesizedProperties)

NNSynthesizeObjectStorage(id, prop_ns, prop_ns, setProp_ns:)
NNSynthesizeObjectStorage(id, prop_na, prop_na, setProp_na:)
NNSynthesizeObjectStorage(id, prop_nw, prop_nw, setProp_nw:)
NNSynthesizeObjectStorage(id<NSCopying>, prop_nc, prop_nc, setProp_nc:)

@end


@implementation NNSynthesizedObjectStorageTests

- (void)testTestObjects {
    XCTAssertNotNil([[NNSynthesizedObjectStorageTestObject new] number]);
}

- (void)testStrong {
    @autoreleasepool {
        id obj = [NNSynthesizedObjectStorageTestObject new];
        self.prop_ns = obj;
        XCTAssertEqual(self.prop_ns, obj);
    }
    XCTAssertNotNil(self.prop_ns);
    XCTAssertNotNil([self.prop_ns number]);
}

- (void)testAssign {
    @autoreleasepool {
        id obj = [NNSynthesizedObjectStorageTestObject new];
        self.prop_na = obj;
        XCTAssertEqual(self.prop_na, obj);
    }
}

#warning This is not implemented yet.
//- (void)testWeak {
//    @autoreleasepool {
//        id obj = [NNSynthesizedObjectStorageTestObject new];
//        self.prop_nw = obj;
//        XCTAssertEqual(self.prop_nw, obj);
//    }
//    XCTAssertNil(self.prop_nw);
//}

- (void)testCopy {
    @autoreleasepool {
        id obj = [NNSynthesizedObjectStorageTestObject new];
        self.prop_nc = obj;
        XCTAssertEqualObjects(self.prop_nc, obj);
        XCTAssertNotEqual(self.prop_nc, obj);
    }
    XCTAssertNotNil(self.prop_nc);
    XCTAssertNotNil([self.prop_nc number]);
}

@end
