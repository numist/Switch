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

#import "NNObjectSerializer.h"


// A horribly hacked-up version of https://gist.github.com/numist/3838169
#import <objc/runtime.h>
static NSMethodSignature *selector_belongsToProtocol(SEL selector, Protocol *protocol, BOOL *requiredPtr)
{
    for (int optionbits = 0; optionbits < 2; optionbits++) {
        // Check required methods first, then optional
        BOOL required = optionbits & 1;
        struct objc_method_description hasMethod = protocol_getMethodDescription(protocol, selector, required, YES /* isInstanceMethod */);
        if (hasMethod.name || hasMethod.types) {
            if (requiredPtr) {
                *requiredPtr = required;
            }
            return [NSMethodSignature signatureWithObjCTypes:hasMethod.types];
        }
    }
    
    return nil;
}


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
    self->_delegate = [NNObjectSerializer serializedObjectForObject:delegate];
    self->_sender = [NNObjectSerializer serializedObjectForObject:sender];
    
    return self;
}

- (void)forwardInvocation:(NSInvocation *)invocation;
{
    // Make sure the delegate object doesn't magically disappear half-way through message delivery.
    id delegate = self->_delegate;

    // Fast path—message to nil.
    if (!delegate) {
        [invocation setTarget:nil];
        [invocation invoke];
        return;
    }
    
    // Using a seralizedObject proxy guarantees that oneway methods are called asynchronously while all other methods are called synchronously.
    [invocation setTarget:delegate];
    
    // TODO: Determine some information
    BOOL selectorIsRequiredForDelegateProtocol;
    BOOL selectorIsDelegateMessage = !!selector_belongsToProtocol([invocation selector], self->_protocol, &selectorIsRequiredForDelegateProtocol);
    
    if (selectorIsDelegateMessage) {
        // Sending a delegate message is complicated!
        if (!selectorIsRequiredForDelegateProtocol && ![delegate respondsToSelector:[invocation selector]]) {
            // Optional messages allow for the target to not implement the method. This becomes the same as a message to nil.
            [invocation setTarget:nil];
        }
        
        if ([[invocation methodSignature] isOneway]) {
            // Oneway delegate methods allow for asynchronous sending of the message
            // TODO: does this actually work? I suppose it should since the target is the serialized object proxy and not the object itself, so we just add another layer of BS
            [invocation retainArguments];
        } else {
            // Al other methods must be called asynchronously—check that we're not on the sender's lock queue or we run the risk of deadlock!
            [NNObjectSerializer assertObjectLockNotHeld:self->_sender];
        }
    }
    
    [invocation invoke];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel;
{
    NSMethodSignature *result = selector_belongsToProtocol(sel, self->_protocol, NULL);
    
    id delegate = self->_delegate;
    if (!result && [delegate respondsToSelector:sel]) {
        result = [delegate methodSignatureForSelector:sel];
    }
    
    if (!result) {
        result = [super methodSignatureForSelector:sel];
    }
    
    return result;
}

@end
