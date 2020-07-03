//
//  NNService.h
//  NNKit
//
//  Created by Scott Perry on 10/17/13.
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
 * @enum NNServiceType
 *
 * @discussion
 * Represents the type of a service. Persistent services are started once all of
 * their dependencies have been started, on-demand services are started when an
 * object subscribes to the service.
 */
typedef NS_ENUM(uint8_t, NNServiceType) {
    NNServiceTypePersistent,
    NNServiceTypeOnDemand,
};


/*!
 * @class NNService
 *
 * @discussion
 * Discuss.
 */
@interface NNService : NSObject

/*!
 * @method sharedService
 *
 * @discussion
 * Service singleton accessor.
 *
 * @result
 * Singleton object for the service.
 */
+ (instancetype)sharedService;

/*!
 * @method serviceType
 *
 * @discussion
 * The type of the service. Must be overridden. Valid services must not return NNServiceTypeNone.
 */
+ (NNServiceType)serviceType;

/*!
 * @method dependencies
 *
 * @discussion
 * Services are not started until their dependencies have all been started first.
 * This means multiple services can be made on-demand by having a root service
 * that is on-demand and multiple dependant services that are persistent.
 *
 * @result
 * Returns a set of <code>Class</code>es that this service depends on to run.
 * Default implementation returns nil;
 */
+ (NSSet *)dependencies;

/*!
 * @method subscriberProtocol
 *
 * @discussion
 * Protocol for subscribers to conform to. Default implementation returns <code>&#64;protocol(NSObject)</code>.
 */
+ (Protocol *)subscriberProtocol;

/*!
 * @method startService
 *
 * @discussion
 * Called when the service is started.
 */
- (void)startService __attribute__((objc_requires_super));

/*!
 * @method stopService
 *
 * @discussion
 * Called when the service is stopped.
 */
- (void)stopService __attribute__((objc_requires_super));

@end
