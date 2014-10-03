//
//  SWImageComparisonTests.m
//  Switch
//
//  Created by Scott Perry on 09/30/14.
//  Copyright © 2014 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

#define TESTING 1
#import "imageComparators.h"


@interface SWImageComparisonTests : XCTestCase {
    CGImageRef cgImageA;
    CGImageRef cgImageAA;
    CGImageRef cgImageB;
}

@property (nonatomic, strong, readonly) NSImage *imageA;
@property (nonatomic, strong, readonly) NSImage *imageAA;
@property (nonatomic, strong, readonly) NSImage *imageB;

@end


@implementation SWImageComparisonTests

- (void)setUp {
    [super setUp];

    self.continueAfterFailure = NO;

    NSString *aPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"1376" ofType:@"ar"];
    NSString *bPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"5891" ofType:@"ar"];

    self->_imageA = [NSUnarchiver unarchiveObjectWithFile:aPath];
    self->_imageAA = [NSUnarchiver unarchiveObjectWithFile:aPath];
    self->_imageB = [NSUnarchiver unarchiveObjectWithFile:bPath];

    self->cgImageA = [self.imageA CGImageForProposedRect:NULL context:NULL hints:NULL];
    self->cgImageAA = [self.imageAA CGImageForProposedRect:NULL context:NULL hints:NULL];
    self->cgImageB = [self.imageB CGImageForProposedRect:NULL context:NULL hints:NULL];
}

- (void)testTIFFComparisonDifferent {
    [self measureBlock:^{
        (void)imagesDifferByCachedTIFFComparison(self.imageA, self.imageB);
    }];
}

- (void)testTIFFComparisonSame {
    [self measureBlock:^{
        (void)imagesDifferByCachedTIFFComparison(self.imageA, self.imageAA);
    }];
}

- (void)testCGDataProviderComparisonDifferent {
    [self measureBlock:^{
        (void)imagesDifferByCGDataProviderComparison(self->cgImageA, self->cgImageB);

    }];
}

- (void)testCGDataProviderComparisonSame {
    [self measureBlock:^{
        (void)imagesDifferByCGDataProviderComparison(self->cgImageA, self->cgImageAA);
    }];
}

- (void)testBitmapContextComparisonDifferent {
    [self measureBlock:^{
        (void)imagesDifferByCachedBitmapContextComparison(self.imageA, self.imageB);
    }];
}

- (void)testBitmapContextComparisonSame {
    [self measureBlock:^{
        (void)imagesDifferByCachedBitmapContextComparison(self.imageA, self.imageAA);
    }];
}

@end
