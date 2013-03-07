//
//  NNDelegateProxy.m
//  Switch
//
//  Created by Scott Perry on 03/05/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNDelegateProxy.h"

#import <objc/runtime.h>

#import "NNObjectSerializer.h"


@interface NNDelegateProxy () {
    Protocol *_protocol;
    __weak id _sender;
    __weak id _delegate;
}
@end


@implementation NNDelegateProxy

+ (id)proxyForDelegate:(id)delegate sender:(id)sender protocol:(Protocol *)delegateProtocol;
{
    if (object_getClass(delegate) == [NNDelegateProxy class]) {
        NNDelegateProxy *delegateProxy = delegate;
        if (delegateProxy->_sender == sender && delegateProxy->_protocol == delegateProtocol) {
            return delegateProxy;
        } else {
            delegate = delegateProxy->_delegate;
        }
    }
    
    return [[self alloc] initWithDelegate:delegate sender:sender protocol:delegateProtocol];
}

- (instancetype)initWithDelegate:(id)delegate sender:(id)sender protocol:(Protocol *)delegateProtocol __attribute__((nonnull(2,3)));
{
    self->_protocol = delegateProtocol;
    self->_delegate = delegate;
    self->_sender = sender;
    
    return self;
}

- (void)forwardInvocation:(NSInvocation *)invocation;
{
    BOOL selectorIsRequiredDelegateMethod = !!protocol_getMethodDescription(self->_protocol, [invocation selector], YES /* isRequiredMethod */, YES /* isInstanceMethod */).name;
    BOOL selectorIsDelegateMethod = !!protocol_getMethodDescription(self->_protocol, [invocation selector], NO /* isRequiredMethod */, YES /* isInstanceMethod */).name || selectorIsRequiredDelegateMethod;
    BOOL invokeSynchronously = YES;

    if (selectorIsDelegateMethod) {
        // Make sure the delegate object doesn't magically disappear half-way through the forwarding machinery.
        id delegate = self->_delegate;
        id serializedDelegate = [NNObjectSerializer serializedObjectForObject:delegate];

        // Using a seralizedObject proxy (established in init) guarantees that oneway methods are called asynchronously while all other methods are called synchronously.
        [invocation setTarget:serializedDelegate];
        
        // Sending a delegate message is complicated!
        if (delegate) {
            // Can't call respondsToSelector on the delegate until thread safety has been established.
            dispatch_block_t handleOptionalMessage = ^{
                if (!selectorIsRequiredDelegateMethod && ![delegate respondsToSelector:[invocation selector]]) {
                    // Optional messages allow for the target to not implement the method. This becomes the same as a message to nil.
                    [invocation setTarget:nil];
                }
            };
            
            if ([[invocation methodSignature] isOneway]) {
                // Oneway delegate methods allow for asynchronous sending of the message
                invokeSynchronously = NO;
                [invocation retainArguments];
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    handleOptionalMessage();
                    [invocation invoke];
                });
            } else {
                // All other methods must be called off the caller's locking queue or we run the risk of deadlock!
                //     TODO: is there a way to die more gracefully here?
                [NNObjectSerializer assertObjectLockNotHeld:self->_sender];
                handleOptionalMessage();
            }
        }
    }
    
    if (invokeSynchronously) {
        [invocation invoke];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel;
{
    NSMethodSignature *result;
    
    {
        struct objc_method_description optionalMethodDescription = protocol_getMethodDescription(self->_protocol, sel, NO /* isRequiredMethod */, YES /* isInstanceMethod */);
        if (optionalMethodDescription.types) {
            result = [NSMethodSignature signatureWithObjCTypes:optionalMethodDescription.types];
        }
    }
    
    if (!result) {
        struct objc_method_description requiredMethodDescription = protocol_getMethodDescription(self->_protocol, sel, YES /* isRequiredMethod */, YES /* isInstanceMethod */);
        if (requiredMethodDescription.types) {
            result = [NSMethodSignature signatureWithObjCTypes:requiredMethodDescription.types];
        }
    }
    
    if (!result) {
        result = [super methodSignatureForSelector:sel];
    }
    
    return result;
}

@end
