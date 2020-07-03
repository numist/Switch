//
//  NNStrongifiedProperties.m
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

#import "NNStrongifiedProperties.h"

#import <objc/runtime.h>
#import <objc/message.h>

#import "nn_autofree.h"


static SEL weakGetterForPropertyName(Class myClass, NSString *propertyName) {
    objc_property_t property = NULL;
    do {
        property = class_getProperty(myClass, [propertyName UTF8String]);
        if (property) {
            break;
        }
    } while ((myClass = class_getSuperclass(myClass)));
    
    if (!property) {
        return NO;
    }
    
    objc_property_attribute_t *attributes = nn_autofree(property_copyAttributeList(property, NULL));
    BOOL propertyIsWeak = NO;
    SEL getter = NSSelectorFromString(propertyName);
    for (int i = 0; attributes[i].name != NULL; ++i) {
        if (!strcmp(attributes[i].name, "W")) {
            propertyIsWeak = YES;
        }
        if (!strncmp(attributes[i].name, "G", 1)) {
            getter = NSSelectorFromString([NSString stringWithFormat:@"%s", attributes[i].name + 1]);
        }
        if (!strcmp(attributes[i].name, "T") && strcmp(attributes[i].value, "@")) {
            return NO;
        }
    }
    attributes = NULL;
    
    if (!propertyIsWeak) {
        return NULL;
    }
    
    return getter;
}


static _Bool selectorIsStrongGetter(Class myClass, SEL sel, SEL *weakGetter) {
    NSString *selectorName = NSStringFromSelector(sel);
    NSRange prefixRange = [selectorName rangeOfString:@"strong"];
    
    BOOL selectorIsStrongGetter = prefixRange.location == 0;
    
    if (!selectorIsStrongGetter) {
        if (weakGetter) {
            *weakGetter = NULL;
        }
        return NO;
    }
    
    // Also check uppercase in case it's an acronym?
    
    NSString *upperName = [selectorName substringFromIndex:prefixRange.length];
    NSString *lowerName = [NSString stringWithFormat:@"%@%@",
                           [[selectorName substringWithRange:(NSRange){prefixRange.length, 1}] lowercaseString],
                           [selectorName substringFromIndex:prefixRange.length + 1]];
    
    SEL lowerGetter = weakGetterForPropertyName(myClass, lowerName);
    SEL upperGetter = weakGetterForPropertyName(myClass, upperName);
    
    if (lowerGetter && upperGetter) {
        // Selector is ambiguous, do not support synthesizing a strongified getter for this property.
        return NO;
    }
    
    if (!lowerGetter && !upperGetter) {
        return NO;
    }

    *weakGetter = lowerGetter ?: upperGetter;

    return YES;
}


static id strongGetterIMP(id self, SEL _cmd) {
    SEL weakSelector = NULL;
    
#   ifndef NS_BLOCK_ASSERTIONS
    {
        BOOL sane = selectorIsStrongGetter([self class], _cmd, &weakSelector);
        NSAssert(sane, @"Selector %@ does not represent a valid strongifying getter method", NSStringFromSelector(_cmd));
    }
#   endif
    
    if (!weakSelector) { return nil; }
    
    id strongRef = ((id (*)(id, SEL))objc_msgSend)(self, weakSelector);
    
    return strongRef;
}


@implementation NNStrongifiedProperties

+ (BOOL)resolveInstanceMethod:(SEL)sel;
{
    SEL weakSelector = NULL;
    if (selectorIsStrongGetter(self, sel, &weakSelector)) {
        Method weakGetter = class_getInstanceMethod(self, weakSelector);
        const char *getterEncoding = method_getTypeEncoding(weakGetter);
        class_addMethod(self, sel, (IMP)strongGetterIMP, getterEncoding);
        return YES;
    }
    
    return NO;
}

@end
