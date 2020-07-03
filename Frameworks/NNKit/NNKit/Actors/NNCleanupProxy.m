//
//  NNCleanupProxy.m
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

#import "NNCleanupProxy.h"

#import <objc/runtime.h>

#import "nn_autofree.h"


@interface NNCleanupProxy ()

@property (nonatomic, readonly, weak) NSObject *target;
@property (nonatomic, readonly, assign) NSUInteger hash;
@property (nonatomic, readonly, strong) NSMutableDictionary *signatureCache;

@end


// XXX: rdar://15478132 means no explicit local strongification here due to retain leak :(
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wreceiver-is-weak"

@implementation NNCleanupProxy

+ (NNCleanupProxy *)cleanupProxyForTarget:(id)target withKey:(uintptr_t)key;
{
    return [self cleanupProxyForTarget:target conformingToProtocol:@protocol(NSObject) withKey:key];
}

+ (NNCleanupProxy *)cleanupProxyForTarget:(id)target conformingToProtocol:(Protocol *)protocol withKey:(uintptr_t)key;
{
    NSParameterAssert([target conformsToProtocol:protocol]);
    
    NNCleanupProxy *result = [NNCleanupProxy alloc];
    result->_target = target;
    result->_signatureCache = [NSMutableDictionary new];
    objc_setAssociatedObject(target, (void *)key, result, OBJC_ASSOCIATION_RETAIN);

    [result cacheMethodSignaturesForProcotol:protocol];
    
    return result;
}

+ (void)cleanupAfterTarget:(id)target withBlock:(void (^)())block withKey:(uintptr_t)key;
{
    NNCleanupProxy *result = [NNCleanupProxy cleanupProxyForTarget:target withKey:(uintptr_t)key];
    result.cleanupBlock = block;
}

+ (void)cancelCleanupForTarget:(id)target withKey:(uintptr_t)key;
{
    objc_setAssociatedObject(target, (void *)key, nil, OBJC_ASSOCIATION_RETAIN);
}

- (void)dealloc;
{
    // If the proxy is in dealloc and the target is still live, then no cleanup is needed—the proxy has been removed or replaced.
    if (self->_target) {
        return;
    }
    
    if (self->_cleanupBlock) {
        self->_cleanupBlock();
    }
}

#pragma mark NSObject protocol

@synthesize hash = _hash;
- (NSUInteger)hash;
{
    @synchronized(self) {
        if (!self->_hash) {
            self->_hash = self.target.hash;
        }
    }
    
    return self->_hash;
}

- (BOOL)isEqual:(id)object;
{
    return [object isEqual:self.target];
}

#pragma mark Message forwarding

- (id)forwardingTargetForSelector:(SEL)aSelector;
{
    if ([self.signatureCache objectForKey:NSStringFromSelector(aSelector)]) {
        return self.target;
    }
    
    return self;
}

#pragma mark NNCleanupProxy

- (void)cacheMethodSignatureForSelector:(SEL)aSelector;
{
    NSMethodSignature *signature = [self.target methodSignatureForSelector:aSelector];

    if (signature) {
        [self.signatureCache setObject:signature forKey:NSStringFromSelector(aSelector)];
    } else {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Unable to get method signature for selector %@ from target of instance %p", NSStringFromSelector(aSelector), self] userInfo:nil];
    }
}

// This could be faster/lighter if method signature was late-binding, at the cost of higher complexity.
- (void)cacheMethodSignaturesForProcotol:(Protocol *)protocol;
{
    unsigned int totalCount;
    for (uint8_t i = 0; i < 1 << 1; ++i) {
        struct objc_method_description *methodDescriptions = nn_autofree(protocol_copyMethodDescriptionList(protocol, i & 1, YES, &totalCount));
        
        for (unsigned j = 0; j < totalCount; j++) {
            struct objc_method_description *methodDescription = methodDescriptions + j;
            [self.signatureCache setObject:[NSMethodSignature signatureWithObjCTypes:methodDescription->types] forKey:NSStringFromSelector(methodDescription->name)];
        }
    }

    // Recurse to include other protocols to which this protocol adopts
    Protocol * __unsafe_unretained *adoptions = protocol_copyProtocolList(protocol, &totalCount);
    for (unsigned j = 0; j < totalCount; j++) {
        [self cacheMethodSignaturesForProcotol:adoptions[j]];
    }
}

@end

#pragma clang diagnostic pop
