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

+ (dispatch_queue_t)queueForObject:(id)obj;
{
    return ((NNObjectSerializer *)[self serializedObjectForObject:obj])->lock;
}

+ (id)serializedObjectForObject:(id)obj;
{
    return objc_getAssociatedObject(obj, kNNSerializerKey) ?: [[self alloc] initWithObject:obj];
}

+ (void)useMainQueueForObject:(id)obj;
{
    NNObjectSerializer *proxy = [self serializedObjectForObject:obj];
    dispatch_queue_t queue = dispatch_get_main_queue();
    despatch_lock_promote(queue);
    proxy->lock = queue;
}

#pragma mark Instance Methods

- (id)initWithObject:(id)obj;
{
    assert(!objc_getAssociatedObject(obj, kNNSerializerKey));
    
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
    
    if ([[invocation methodSignature] methodReturnLength]) {
        if (despatch_lock_is_held(self->lock)) {
            invoke();
        } else {
            dispatch_sync(self->lock, invoke);
        }
    } else {
        dispatch_async(self->lock, invoke);
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel;
{
    return [self->target methodSignatureForSelector:sel] ?: [super methodSignatureForSelector:sel];
}

@end
