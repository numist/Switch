//
//  _NNWeakArrayTombstone.m
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

#import "_NNWeakArrayTombstone.h"


@interface _NNWeakArrayTombstone ()

@property (nonatomic, readonly, assign) NSUInteger hash;

@end


@implementation _NNWeakArrayTombstone

+ (_NNWeakArrayTombstone *)tombstoneWithTarget:(id)target;
{
    _NNWeakArrayTombstone *tombstone = [_NNWeakArrayTombstone new];
    tombstone->_target = target;
    return tombstone;
}

@synthesize hash = _hash;
- (NSUInteger)hash;
{
    if (!self->_hash) {
        @synchronized(self) {
            if (!self->_hash) {
                id target = self.target;
                if (target) {
                    self->_hash = [target hash];
                } else {
                    self->_hash = (uintptr_t)self;
                }
            }
        }
    }
    
    return self->_hash;
}

- (BOOL)isEqual:(id)object;
{
    id target = self.target;
    return [target isEqual:object] ? YES : (uintptr_t)object == (uintptr_t)self;
}

@end
