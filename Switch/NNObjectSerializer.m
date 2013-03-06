//
//  NNObjectSerializer.m
//  Switch
//
//  Created by Scott Perry on 03/04/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//


#import "NNObjectSerializer.h"

#import "despatch.h"


static void *kNNSerializerKey = (void *)1784668075; // Guaranteed random by arc4random()


@interface NNObjectSerializer () {
    NSObject *target;
    dispatch_queue_t lock;
}
@end


@implementation NNObjectSerializer

#pragma mark Class Functionality Methods

+ (id)createSerializedObjectForObject:(id)obj;
{
    assert(!objc_getAssociatedObject(obj, kNNSerializerKey));
    
    return [[self alloc] initWithObject:obj];
}

+ (id)serializedObjectForObject:(id)obj;
{
    id result = [self internalSerializedObjectForObject:obj];
    assert(result);
    return result;
}

+ (void)useMainQueueForObject:(id)obj;
{
    NNObjectSerializer *proxy = [self serializedObjectForObject:obj];
    dispatch_queue_t queue = dispatch_get_main_queue();
    despatch_lock_promote(queue);
    proxy->lock = queue;
}

+ (void)performOnObject:(id)obj block:(dispatch_block_t)work;
{
    dispatch_async([self queueForObject:obj], work);
}

+ (void)performAndWaitOnObject:(id)obj block:(dispatch_block_t)work;
{
    dispatch_sync([self queueForObject:obj], work);
}

+ (void)performOnObject:(id)obj afterDelay:(NSTimeInterval)delayInSeconds block:(dispatch_block_t)work;
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, [self queueForObject:obj], work);
}

+ (void)assertObjectLockHeld:(id)obj;
{
    assert([self objectLockHeld:obj]);
}

+ (void)assertObjectLockNotHeld:(id)obj;
{
    assert(![self objectLockHeld:obj]);
}

#pragma mark Internal Class Methods

+ (id)internalSerializedObjectForObject:(id)obj;
{
    id result = nil;
    
    if (object_getClass(obj) == [NNObjectSerializer class]) {
        result = obj;
    }
    
    if (!result) {
        result = objc_getAssociatedObject(obj, kNNSerializerKey);
    }
    
    return result;
}

+ (BOOL)objectLockHeld:(id)obj;
{
    return despatch_lock_is_held([self queueForObject:obj]);
}

+ (dispatch_queue_t)queueForObject:(id)obj;
{
    NNObjectSerializer *serializedObject = [self internalSerializedObjectForObject:obj];
    if (serializedObject) {
        return serializedObject->lock;
    } else {
        return dispatch_get_main_queue();
    }
}

#pragma mark Instance Methods

- (id)initWithObject:(id)obj;
{
    assert(![NNObjectSerializer internalSerializedObjectForObject:obj]);
    
    self->target = obj;
    self->lock = despatch_lock_create([[NSString stringWithFormat:@"Lock for %@", [obj description]] UTF8String]);
    objc_setAssociatedObject(obj, kNNSerializerKey, self, OBJC_ASSOCIATION_ASSIGN);
    
    return self;
}

- (BOOL)isProxy;
{
    return [super isProxy];
}

- (void)dealloc;
{
    objc_setAssociatedObject(self->target, kNNSerializerKey, nil, OBJC_ASSOCIATION_ASSIGN);
}

- (void)forwardInvocation:(NSInvocation *)invocation;
{
    [invocation setTarget:self->target];
    dispatch_block_t invoke = ^{ [invocation invoke]; };
    
    if ([[invocation methodSignature] isOneway]) {
        // Oneway methods are automatically asynchronous.
        [invocation retainArguments];
        dispatch_async(self->lock, invoke);
    } else {
        if (despatch_lock_is_held(self->lock)) {
            // Recursive lock acquisition has to be supported for objects that have to do most of their work on the main queue (like views—and maybe their controllers), but taking any other lock recursively is a sign that maybe something is wrong with your program. Things you call synchronously should not call back into you synchronously!
            if (self->lock != dispatch_get_main_queue()) {
                NSLog(@"WARNING: Taking lock %@ recursively!", self->lock);
            }
            invoke();
        } else {
            dispatch_sync(self->lock, invoke);
        }
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel;
{
    if ([self->target respondsToSelector:sel]) {
        return [self->target methodSignatureForSelector:sel];
    }
    return [super methodSignatureForSelector:sel];
}

@end
