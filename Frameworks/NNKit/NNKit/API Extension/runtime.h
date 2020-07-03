//
//  runtime.h
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

#ifndef NNKit_rantime_h
#define NNKit_rantime_h

#include <objc/runtime.h>

#import <NNKit/macros.h>

// Memory-backed property generation for categories
#define NNSynthesizeObjectStorage(type, name, getter, setter) \
- (type)getter { return objc_getAssociatedObject(self, NNSelfSelector(getter)); } \
- (void)setter(type)name { \
    int association = [NNMemoize(^{ \
        objc_property_t property = class_getProperty([self class], #name); \
        int association = OBJC_ASSOCIATION_ASSIGN; \
        char *value = NULL; \
        if ((value = property_copyAttributeValue(property, "W"))) { \
            free(value); \
            @throw [NSException exceptionWithName:@"oops" reason:@"Not implemented" userInfo:nil]; \
        } else if ((value = property_copyAttributeValue(property, "C"))) { \
            free(value); \
            association = OBJC_ASSOCIATION_COPY; \
        } else if ((value = property_copyAttributeValue(property, "&"))) { \
            free(value); \
            association = OBJC_ASSOCIATION_RETAIN; \
        } \
        return @(association); \
    }) intValue]; \
    objc_setAssociatedObject(self, NNSelfSelector(getter), name, association); \
}

/*!
 * @function nn_selector_belongsToProtocol
 *
 * @abstract
 * Returns whether a selector belongs to a specific protocol.
 *
 * @discussion
 * Search hinting can be performed by using the required and instance parameters, which are set on
 * successful match to the instance/class, required/optional settings of the match.
 *
 * @param selector
 * The selector to be found.
 *
 * @param protocol
 * The protocol to be searched.
 *
 * @param required
 * Whether the match should be required or not. Can be <code>NULL</code>.
 * If not-<code>NULL</code> and the selector is found in the protocol,
 * the parameter is set to the requirement setting of the match.
 *
 * @param instance
 * Whether the match should be instance or class-level. Can be <code>NULL</code>.
 * If not-<code>NULL</code> and the selector is found in the protocol, the
 * parameter is set to the instance/class setting of the match.
 *
 * @result
 * <code>YES</code> if the protocol contains any selector matching selector.
 * <code>NO</code> otherwise.
 */
BOOL nn_selector_belongsToProtocol(SEL selector, Protocol *protocol, BOOL *required, BOOL *instance);

#endif
