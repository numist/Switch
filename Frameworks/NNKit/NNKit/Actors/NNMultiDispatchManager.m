//
//  NNMultiDispatchManager.m
//  NNKit
//
//  Created by Scott Perry on 11/19/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNMultiDispatchManager.h"

#import "NNWeakSet.h"
#import "despatch.h"
#import "nn_autofree.h"
#import "NSInvocation+NNCopying.h"
#import "runtime.h"


@interface NNMultiDispatchManager ()

@property (nonatomic, readonly, strong) NSMutableDictionary *signatureCache;
@property (nonatomic, readonly, strong) NNWeakSet *observers;

@end


@implementation NNMultiDispatchManager

- (instancetype)initWithProtocol:(Protocol *)protocol;
{
    if (!(self = [super init])) { return nil; }
    
    self->_enabled = YES;
    self->_protocol = protocol;
    self->_signatureCache = [NSMutableDictionary new];
    [self _cacheMethodSignaturesForProcotol:protocol];
    self->_observers = [NNWeakSet new];

    return self;
}

@synthesize enabled = _enabled;

- (BOOL)isEnabled;
{
    @synchronized(self) {
        return self->_enabled;
    }
}

- (void)setIsEnabled:(BOOL)enabled;
{
    @synchronized(self) {
        self->_enabled = enabled;
    }
}

- (void)addObserver:(id)observer;
{
    NSParameterAssert([observer conformsToProtocol:self.protocol]);
    
    @synchronized(self) {
        [self.observers addObject:observer];
    }
}

- (BOOL)hasObserver:(id)observer;
{
    NSAssert([NSThread isMainThread], @"Boundary call was not made on main thread");
    
    @synchronized(self) {
        return [self.observers containsObject:observer];
    }
}

- (void)removeObserver:(id)observer;
{
    NSAssert([NSThread isMainThread], @"Boundary call was not made on main thread");
    
    @synchronized(self) {
        [self.observers removeObject:observer];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector;
{
    @synchronized(self) {
        return [self.signatureCache objectForKey:NSStringFromSelector(aSelector)];
    }
}

- (void)forwardInvocation:(NSInvocation *)anInvocation;
{
    @synchronized(self) {
        if (self.enabled) {
            if (anInvocation.methodSignature.isOneway) {
                // If we're going async, copy the invocation to avoid multiple threads calling -invoke or otherwise acting in a thread-unsafe manner.
                anInvocation = [anInvocation nn_copy];
                [anInvocation retainArguments];
            }
            
            NSAssert(strstr(anInvocation.methodSignature.methodReturnType, "v"), @"Method return type must be void.");
            dispatch_block_t dispatch = ^{
                [self private_forwardInvocation:anInvocation];
            };
            if (anInvocation.methodSignature.isOneway) {
                dispatch_async(dispatch_get_main_queue(), dispatch);
            } else {
                despatch_sync_main_reentrant(dispatch);
            }
        }
        
        anInvocation.target = nil;
        [anInvocation invoke];
    }
}

#pragma mark Private

- (void)_cacheMethodSignaturesForProcotol:(Protocol *)protocol;
{
    @synchronized(self) {
        unsigned int totalCount;
        for (uint8_t i = 0; i < 1 << 1; ++i) {
            struct objc_method_description *methodDescriptions = nn_autofree(protocol_copyMethodDescriptionList(protocol, i & 1, YES, &totalCount));
            
            for (unsigned j = 0; j < totalCount; j++) {
                struct objc_method_description *methodDescription = methodDescriptions + j;
                [self.signatureCache setObject:[NSMethodSignature signatureWithObjCTypes:methodDescription->types] forKey:NSStringFromSelector(methodDescription->name)];
            }
        }
        
        // Recurse to include other protocols to which this protocol adopts
        Protocol * __unsafe_unretained *adoptions = (Protocol * __unsafe_unretained *)nn_autofree(protocol_copyProtocolList(protocol, &totalCount));
        for (unsigned j = 0; j < totalCount; j++) {
            [self _cacheMethodSignaturesForProcotol:adoptions[j]];
        }
    }
}

- (void)private_forwardInvocation:(NSInvocation *)anInvocation;
{
    @synchronized(self) {
        BOOL required = YES;
        BOOL instance = YES;
        BOOL sanity = nn_selector_belongsToProtocol(anInvocation.selector, self.protocol, &required, &instance);

#ifndef NS_BLOCK_ASSERTIONS
        NSAssert(sanity && instance, @"Selector %@ is not actually part of protocol %@?!", NSStringFromSelector(anInvocation.selector), NSStringFromProtocol(self.protocol));
#else
        (void)sanity;
#endif

        for (id obj in self.observers) {
            if ([obj respondsToSelector:anInvocation.selector] || required) {
                [anInvocation invokeWithTarget:obj];
            }
        }
    }
}

@end
