//
//  NNCleanupProxy.h
//  NNKit
//
//  Created by Scott Perry on 11/18/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>


/*!
 * @class NNCleanupProxy
 *
 * @discussion
 * A cleanup proxy is used when a weak reference to an object is desired, but not possible. An example
 * of this is registering for notifications—the notification center should maintain a weak reference
 * to the object instead of requiring bracketed add/remove observer calls.
 *
 * The one caveat to using a weak proxy in this situation is that method signatures must be pre-cached,
 * since the runtime will explode if a nil method signature is returned during the message forwarding
 * process. The NNCleanupProxy object will helpfully assert if a method signature does not already
 * exist in cache at the time it is needed.
 *
 * For example use, see
 * <code>NSNotificationCenter+NNAdditions addWeakObserver:selector:name:object:</code>.
 */
@interface NNCleanupProxy : NSProxy

/*!
 * @method cleanupProxyForTarget:
 *
 * @abstract
 * Creates a proxy object holding a weak reference to, forwarding messages to, and with an object
 * lifetime dependant on <i>target</i>.
 */
+ (NNCleanupProxy *)cleanupProxyForTarget:(id)target withKey:(uintptr_t)key;

/*!
 * @method cleanupProxyForTarget:conformingToProtocol:
 *
 * @abstract
 * Creates a proxy object holding a weak reference to, forwarding messages to, and with an object
 * lifetime dependant on <i>target</i>, conforming to protocol <i>protocol</i>.
 */
+ (NNCleanupProxy *)cleanupProxyForTarget:(id)target conformingToProtocol:(Protocol *)protocol withKey:(uintptr_t)key;

+ (void)cleanupAfterTarget:(id)target withBlock:(void (^)())block withKey:(uintptr_t)key;

+ (void)cancelCleanupForTarget:(id)target withKey:(uintptr_t)key;

/*!
 * @property cleanupBlock
 *
 * @abstract
 * The block run when target is deallocated (in the absence of other strong references to the proxy).
 *
 * @discussion
 * This block is used to clean up any registrations that have been made for the proxy that require
 * bracketed calls to remove. Messages sent to the proxy intended for its <i>target</i> will react
 * with the same semantics as messaging nil.
 */
@property (nonatomic, readwrite, copy) void (^cleanupBlock)();

/*!
 * @method cacheMethodSignatureForSelector:
 *
 * @abstract
 * Caches the method signature of a selector that the proxy is expected to forward to the target.
 *
 * @discussion
 * If an unexpected method is sent to the proxy with the expectation that it will be forwarded,
 * the proxy will throw an exception as if the selector is not recognized. Likewise if a method
 * signature cannot be cached, the proxy will throw an exception.
 *
 * @param aSelector
 * The selector for which the method signature should be fetched from the proxy's <i>target</i>.
 */
- (void)cacheMethodSignatureForSelector:(SEL)aSelector;

//- (void)cacheMethodSignaturesForProtocol:(Protocol)aProtocol;

@end
