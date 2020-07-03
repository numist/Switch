//
//  NNDelegateProxy.m
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

#import "NNDelegateProxy.h"

#import "despatch.h"
#import "runtime.h"


@interface NNDelegateProxy ()

@property (readonly, weak) id delegate;
@property (readonly, assign) Protocol *protocol;

@end


@implementation NNDelegateProxy

+ (id)proxyWithDelegate:(id)delegate protocol:(Protocol *)protocol;
{
    if (protocol && delegate) {
        NSAssert([delegate conformsToProtocol:protocol], @"Object %@ does not conform to protocol %@", delegate, NSStringFromProtocol(protocol));
    }

    NNDelegateProxy *proxy = [self alloc];
    proxy->_delegate = delegate;
    proxy->_protocol = protocol;
    return proxy;
}

// Helper function to provide an autoreleasing reference to the delegate property
- (id)strongDelegate;
{
    id delegate = self.delegate;
    return delegate;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel;
{
    return [self.strongDelegate methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation;
{
#   ifndef NS_BLOCK_ASSERTIONS
    {
        BOOL instanceMethod = YES;
        NSAssert(nn_selector_belongsToProtocol(invocation.selector, self.protocol, NULL, &instanceMethod) && instanceMethod, @"Instance method %@ not found in protocol %@", NSStringFromSelector(invocation.selector), NSStringFromProtocol(self.protocol));
    }
#   endif
    
    id delegate = self.delegate;
    BOOL requiredMethod = NO;
    nn_selector_belongsToProtocol(invocation.selector, self.protocol, &requiredMethod, NULL);
    if (!requiredMethod && ![delegate respondsToSelector:invocation.selector]) {
        return;
    }
    
    if (invocation.methodSignature.isOneway) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [invocation invokeWithTarget:delegate];
        });
    } else {
        despatch_sync_main_reentrant(^{
            [invocation invokeWithTarget:delegate];
        });
    }
}

@end
