//
//  NNSelfInvalidatingObject.m
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
//  Requires -fno-objc-arc
//

#import "NNSelfInvalidatingObject.h"

#import <assert.h>


@interface NNSelfInvalidatingObject () {
    _Bool _valid;
}

@property (nonatomic, assign) long refCount;

@end


@implementation NNSelfInvalidatingObject

#pragma mark NSObject

- (instancetype)init;
{
    if (!(self = [super init])) { return nil; }
    
    self->_refCount = 0;
    self->_valid = true;
    
    /*
     * -invalidate supports two conditions:
     *   * invalidate may be called before the refCount hits zero, in which case the object should survive until its natural death.
     *   * invalidate may be called at refCount zero, in which case the object should survive until the end of the current runloop.
     * To satisfy both of these constraints, retain/release messages are forwarded to super and one extra retain is made (here) balanced by an autorelease in -invalidate to keep the object alive while it is still valid/invalidating.
     * Calling dealloc directly is an error and is not supported.
     */
    [self retain];
    
    return self;
}

- (instancetype)retain;
{
    @synchronized(self) {
        ++self.refCount;
    }
    [super retain];
    return self;
}

- (oneway void)release;
{
    @synchronized(self) {
        --self.refCount;
    }
    [super release];
}

- (oneway void)dealloc;
{
    if (self->_valid) {
        [super dealloc];
        @throw [NSException exceptionWithName:@"NNObjectLifetimeException" reason:@"Calling dealloc directly on a self-invalidating object is not supported (object destroyed without invalidation)." userInfo:nil];
    }

    [super dealloc];
}

#pragma mark NNSelfInvalidatingObject

- (void)invalidate;
{
    @synchronized(self) {
        if (self->_valid) {
            self->_valid = false;
            [self autorelease];
        }
    }
}

#pragma mark Internal

- (void)setRefCount:(long)refCount;
{
    self->_refCount = refCount;
    
    if (!refCount && self->_valid) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self invalidate];
        });
    }
}

@end
