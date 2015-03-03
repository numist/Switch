//
//  SWScrollControl.m
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

#import "SWScrollControl.h"


static NSInteger const kMaxThreshold = NSIntegerMax / 2;


@interface SWScrollControl ()

@property (nonatomic, readonly, strong) dispatch_block_t inc;
@property (nonatomic, readonly, strong) dispatch_block_t dec;
@property (nonatomic, readonly, assign) NSInteger threshold;
@property (nonatomic, readwrite, assign) NSInteger offset;

@end


@implementation SWScrollControl

- (instancetype)initWithThreshold:(NSInteger)threshold incHandler:(dispatch_block_t)incBlock decHandler:(dispatch_block_t)decBlock;
{
    BailUnless(self = [super init], nil);

    self->_inc = incBlock;
    self->_dec = decBlock;
    self->_threshold = labs(threshold);

    if (self->_threshold > kMaxThreshold) {
        NSLog(@"%@ does not support thresholds larger than %ld", NSStringFromClass([self class]), kMaxThreshold);
        return nil;
    }

    return self;
}

- (void)feed:(NSInteger)numEvents;
{
    NSInteger units = numEvents / self.threshold;
    numEvents -= (units * self.threshold);

    self.offset += numEvents;
    units += (self.offset / self.threshold);

    if (units != 0) {
        self.offset = self.offset % self.threshold;

        while (units > 0) {
            self.inc();
            units--;
        }
        while (units < 0) {
            self.dec();
            units++;
        }
    }
}

- (void)reset;
{
    self.offset = 0;
}

@end
