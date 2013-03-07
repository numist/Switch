//
//  NNDelegateProxy.h
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

#import <Foundation/Foundation.h>


@interface NNDelegateProxy : NSProxy

+ (id)proxyForDelegate:(id)delegate sender:(id)sender protocol:(Protocol *)delegateProtocol __attribute__((nonnull(2,3)));

@end

#define generateDelegateAccessors(proxyStorage, delegateProtocol) \
    @dynamic delegate; \
    \
    - (void)setDelegate:(id<delegateProtocol>)delegate; \
    { \
        proxyStorage = [NNDelegateProxy proxyForDelegate:delegate sender:self protocol:@protocol(delegateProtocol)]; \
    } \
    \
    - (id<delegateProtocol>)delegate; \
    { \
        return proxyStorage; \
    }


// EXAMPLE USAGE:
#if 0

/*
 * Delegate proxies are intended for use by objects that send messages to their delegates. Just store a (strong!) reference to an NNDelegateProxy object and pass it messages intended for the delegate!
 *
 * Using a proxy reduces boilerplate code:
 * The proxy automatically handles messages sent to delegates that do not implement optional methods in the protocol—they will return the same value as if the message was sent to nil.
 * Delegate methods that are declared oneway void are run asynchronously—control returns immediately to the caller. Perfect when aren't worried about the order your messages are delivered!
 *
 * Using a proxy improves thread safety:
 * NNDelegateProxy is intended for use in an environment that makes use of the NNObjectSerializer class. If you're not using it, don't worry—your delegate messages will get delivered on the main thread.
 * The proxy automatically handles lock safety when delegate methods must return a value, refusing to send a message to a delegate while the sender's lock is held.
 */

/**
 * Setting the delegate
 */

- (void)setDelegate:(id<MyClassDelegate>)delegate;
{
    _delegate = [NNDelegateProxy proxyForDelegate:delegate sender:self protocol:@protocol(MyClassDelegate)];
}


/**
 * Delegate method is declared with return type oneway void (recommended!)
 */

// Don't forget—never let an unsafe reference to self escape the object!
id serializedSelf = [NNObjectSerializer serializedObjectForObject:self];

// The delegate proxy knows the delegate method is oneway void and dispatches it asynchronously—this call returns immediately.
[self.delegate delegateMethod:serializedSelf];


/**
 * Delegate method returns a value
 */

// Drop the sender's lock by dispatching onto a global concurrent queue.
// Locking order should follow object ownership—if you have a lock cycle, you also have a retain cycle!
dispatch_async(dispatch_get_global_queue(0, 0), ^{
    
    // Get a safe accessor to self
    id serializedSelf = [NNObjectSerializer serializedObjectForObject:self];
    
    // Call the delegate, remember: only emit safe references to self to other objects!
    id result = [serializedSelf.delegate delegateMethod:serializedSelf];
    
    // At this point you can use the result in a safe context using a block and the object serializer class.
    [NNObjectSerializer performOnObject:serializedSelf block:^{
        self.something = result;
        NSLog(@"%@", [result debugDescription]);
    }];
    
    // Or if the work is minor, use the safe reference to self.
    serializedSelf.something = result;
});
    
#endif
