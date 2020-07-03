//
//  NNISASwizzledObject.m
//  NNKit
//
//  Created by Scott Perry on 02/07/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNISASwizzledObject.h"

#import <objc/runtime.h>

#import "nn_isaSwizzling_Private.h"


static void *_NNSwizzleSuperclassKey;


__attribute__((constructor))
static void nn_isaSwizzling_init() {
    arc4random_buf(&_NNSwizzleSuperclassKey, sizeof(_NNSwizzleSuperclassKey));
}


@implementation NNISASwizzledObject

#pragma mark Swizzler runtime support.

+ (void)prepareObjectForSwizzling:(NSObject *)anObject;
{
    // Cache the original value of -class so the swizzled object can lie about itself later.
    objc_setAssociatedObject(anObject, _NNSwizzleSuperclassKey, [anObject class], OBJC_ASSOCIATION_ASSIGN);
}

#pragma mark Private swizzled methods

- (Class)_swizzler_actualClass
{
    return object_getClass(self);
}

#pragma mark Swizzled object overrides

- (Class)class
{
    Class superclass = objc_getAssociatedObject(self, _NNSwizzleSuperclassKey);
    
    if (!superclass) {
        NSLog(@"ERROR: couldn't find stashed superclass for swizzled object, falling back to parent class—if you're using KVO, this might break everything!");
        return class_getSuperclass(object_getClass(self));
    }
    
    return superclass;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    return [[self _swizzler_actualClass] conformsToProtocol:aProtocol];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [[self _swizzler_actualClass] instancesRespondToSelector:aSelector];
}

- (BOOL)isKindOfClass:(Class)aClass;
{
    if (nn_alreadySwizzledObjectWithSwizzlingClass(self, aClass)) {
        return YES;
    }
    
    return [super isKindOfClass:aClass];
}

@end
