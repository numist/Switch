//
//  nn_isaSwizzling.m
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

#import "nn_isaSwizzling_Private.h"

#import <objc/runtime.h>

#import "NNISASwizzledObject.h"
#import "nn_autofree.h"


static NSString *_prefixForSwizzlingClass(Class aClass)
{
    return [NSString stringWithFormat:@"SwizzledWith%s_", class_getName(aClass)];
}

static NSString * _classNameForObjectWithSwizzlingClass(id anObject, Class aClass)
{
    return [NSString stringWithFormat:@"%@%s", _prefixForSwizzlingClass(aClass), object_getClassName(anObject)];
}

#pragma mark Class copying functions

static void _class_addMethods(Class targetClass, Method *methods) {
    Method method;
    for (NSUInteger i = 0; methods && (method = methods[i]); i++) {
        // targetClass is a brand new shiny class, so this should never fail because it already implements a method (even though its superclass(es) might).
        if(!class_addMethod(targetClass, method_getName(method), method_getImplementation(method), method_getTypeEncoding(method))) {
            // numist/NNKit#17
            NSLog(@"Warning: Replacing method %@ previously defined by class %@?", NSStringFromSelector(method_getName(method)), NSStringFromClass(targetClass));
            class_replaceMethod(targetClass, method_getName(method), method_getImplementation(method), method_getTypeEncoding(method));
        }
    }
}

static void _class_addClassMethodsFromClass(Class targetClass, Class source)
{
    _class_addMethods(object_getClass(targetClass), nn_autofree(class_copyMethodList(object_getClass(source), NULL)));
}

static void _class_addInstanceMethodsFromClass(Class targetClass, Class source)
{
    _class_addMethods(targetClass, nn_autofree(class_copyMethodList(source, NULL)));
}

static void _class_addProtocolsFromClass(Class targetClass, Class aClass)
{
    Protocol * __unsafe_unretained *protocols = (Protocol * __unsafe_unretained *)nn_autofree(class_copyProtocolList(aClass, NULL));
    Protocol __unsafe_unretained *protocol;
    
    for (NSUInteger i = 0; protocols && (protocol = protocols[i]); i++) {
        // targetClass is a brand new shiny class, so this should never fail because it already conforms to a protocol (even though its superclass(es) might).
        if (!class_addProtocol(targetClass, protocol)) {
            NSLog(@"Warning: class %@ already conforms to protocol %@?", NSStringFromClass(targetClass), NSStringFromProtocol(protocol));
        }
    }
}

static void _class_addPropertiesFromClass(Class targetClass, Class aClass)
{
    objc_property_t *properties = nn_autofree(class_copyPropertyList(aClass, NULL));
    objc_property_t property;
    
    for (NSUInteger i = 0; properties && (property = properties[i]); i++) {
        unsigned attributeCount;
        objc_property_attribute_t *attributes = nn_autofree(property_copyAttributeList(property, &attributeCount));

        // targetClass is a brand new shiny class, so this should never fail because it already has certain properties (even though its superclass(es) might).
        if(!class_addProperty(targetClass, property_getName(property), attributes, attributeCount)) {
            // numist/NNKit#17
            NSLog(@"Warning: Replacing property %s previously defined by class %@?", property_getName(property), NSStringFromClass(targetClass));
            class_replaceProperty(targetClass, property_getName(property), attributes, attributeCount);
        }
    }
}

#pragma mark Swizzling safety checks

static void _class_checkForNonDynamicProperties(Class aClass)
{
    objc_property_t *properties = nn_autofree(class_copyPropertyList(aClass, NULL));
    
    for (unsigned i = 0; properties && properties[i]; i++) {
        objc_property_attribute_t *attributes = nn_autofree(property_copyAttributeList(properties[i], NULL));
        
        for (unsigned j = 0; attributes && attributes[j].name; j++) {
            if (!strcmp(attributes[j].name, "D")) { // The property is dynamic (@dynamic).
                NSLog(@"Warning: Swizzling class %s contains non-dynamic property %s", class_getName(aClass), property_getName(properties[i]));
            }
        }
    }
}

static BOOL _class_containsIvars(Class aClass)
{
    unsigned ivars;
    free(class_copyIvarList(aClass, &ivars));
    return ivars != 0;
}

#pragma mark Isa swizzling

static Class _targetClassForObjectWithSwizzlingClass(id anObject, Class aClass)
{
    Class targetClass = objc_getClass(_classNameForObjectWithSwizzlingClass(anObject, aClass).UTF8String);
    
    if (!targetClass) {
        BOOL success = YES;
        const char *swizzlingClassName = class_getName(aClass);

        Class sharedAncestor = class_getSuperclass(aClass);
        if (![anObject isKindOfClass:sharedAncestor]) {
            NSLog(@"Target object %@ must be a subclass of %@ to be swizzled with class %s.", anObject, sharedAncestor, swizzlingClassName);
            success = NO;
        }
        
        _class_checkForNonDynamicProperties(aClass);
        
        if (_class_containsIvars(aClass)) {
            NSLog(@"Swizzling class %s cannot contain ivars not inherited from its superclass", swizzlingClassName);
            success = NO;
        }
        
        if (!success) {
            return Nil;
        }
        
        targetClass = objc_allocateClassPair(object_getClass(anObject), _classNameForObjectWithSwizzlingClass(anObject, aClass).UTF8String, 0);
        _class_addClassMethodsFromClass(targetClass, aClass);
        _class_addInstanceMethodsFromClass(targetClass, aClass);
        _class_addProtocolsFromClass(targetClass, aClass);
        _class_addPropertiesFromClass(targetClass, aClass);
        
        objc_registerClassPair(targetClass);
    }
    
    return targetClass;
}

static BOOL _object_swizzleIsa(id anObject, Class aClass)
{
    assert(!nn_alreadySwizzledObjectWithSwizzlingClass(anObject, aClass));
    
    Class targetClass = _targetClassForObjectWithSwizzlingClass(anObject, aClass);
    
    if (!targetClass) {
        return NO;
    }
    
    object_setClass(anObject, targetClass);
    
    return YES;
}

#pragma mark Privately-exported functions

BOOL nn_alreadySwizzledObjectWithSwizzlingClass(id anObject, Class aClass)
{
    NSString *classPrefix = _prefixForSwizzlingClass(aClass);
    
    for (Class candidate = object_getClass(anObject); candidate; candidate = class_getSuperclass(candidate)) {
        if ([[NSString stringWithUTF8String:class_getName(candidate)] hasPrefix:classPrefix]) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark Publicly-exported funtions

BOOL nn_object_swizzleIsa(id anObject, Class aClass) {
    BOOL success = YES;
    
    @autoreleasepool {
        // Bootstrap the object with the necessary lies, like overriding -class to report the original class.
        if (!nn_alreadySwizzledObjectWithSwizzlingClass(anObject, [NNISASwizzledObject class])) {
            [NNISASwizzledObject prepareObjectForSwizzling:anObject];
            
            success = _object_swizzleIsa(anObject, [NNISASwizzledObject class]);
        }
        
        if (success && !nn_alreadySwizzledObjectWithSwizzlingClass(anObject, aClass)) {
            success = _object_swizzleIsa(anObject, aClass);
        }
    }
    
    return success;
}
