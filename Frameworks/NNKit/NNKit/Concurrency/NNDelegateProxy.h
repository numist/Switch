//
//  NNDelegateProxy.h
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

#import <Foundation/Foundation.h>


/*!
 * @class NNDelegateProxy
 *
 * @discussion
 * A proxy object ensuring that messages to the delegate are dispatched on the
 * main thread.
 *
 * Messages declared as oneway void are dispatched asynchronously, messages that
 * are optional are dispatched against nil if the delegate does not implement them.
 * Messages that are optional and non-void are a bad idea and you shouldn't use them.
 */
@interface NNDelegateProxy : NSProxy

/*!
 * @method proxyWithDelegate:protocol:
 *
 * @discussion
 * Creates a new proxy for <i>delegate</i> conforming to
 * <i>protocol</i>.
 *
 * @param delegate
 * The object to receive delegate messages.
 *
 * @param protocol
 * The protocol to which <i>delegate</i> conforms. Can be <code>NULL</code>,
 * but shouldn't be.
 *
 * @result
 * Proxy to stand in for <i>delegate</i> for messages conforming to
 * <i>protocol</i>.
 */
+ (id)proxyWithDelegate:(id)delegate protocol:(Protocol *)protocol;

@end
