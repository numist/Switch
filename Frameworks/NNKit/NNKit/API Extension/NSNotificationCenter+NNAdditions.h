//
//  NSNotificationCenter+NNAdditions.h
//  NNKit
//
//  Created by Scott Perry on 11/14/13.
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
 * @category NNAdditions
 *
 * @discussion
 * Provides weak observer support to <code>NSNotificationCenter</code>.
 */
@interface NSNotificationCenter (NNAdditions)

/*!
 * @method addWeakObserver:selector:name:object:
 *
 * @abstract
 * Adds an entry to the receiver's dispatch table with an observer, a notification
 * selector and optional criteria: notification name and sender.
 *
 * @discussion
 * The observer is referenced weakly and does not need to be explicitly removed when
 * the object is deallocated.
 *
 * @param observer
 * Object registering as an observer. This value must not be <code>nil</code>.
 *
 * @param aSelector
 * Selector that specifies the message the receiver sends <i>observer</i> to notify
 * it of the notification posting. The method specified by <i>aSelector</i> must have
 * one and only one argument (an instance of <code>NSNotification</code>).
 *
 * @param aName
 * The name of the notification for which to register the observer; that is, only
 * notifications with this name are delivered to the observer. If you pass
 * <code>nil</code>, the notification center doesn’t use a notification’s name to
 * decide whether to deliver it to the observer.
 *
 * @param anObject
 * The object whose notifications the observer wants to receive; that is, only
 * notifications sent by this sender are delivered to the observer. If you pass
 * <code>nil</code>, the notification center doesn’t use a notification’s sender
 * to decide whether to deliver it to the observer.
 */
- (void)addWeakObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject;

@end
