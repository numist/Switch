//
//  NNServiceManager.m
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

#import "NNServiceManager.h"

#import <objc/runtime.h>

#import "nn_autofree.h"
#import "macros.h"
#import "NNCleanupProxy.h"
#import "NNMultiDispatchManager.h"
#import "NNService+Protected.h"
#import "NNWeakSet.h"


static NSMutableSet *claimedServices;


#ifndef NS_BLOCK_ASSERTIONS
static BOOL _serviceIsValid(Class service)
{
    return [service isSubclassOfClass:[NNService class]];
}
#endif


@interface _NNServiceInfo : NSObject

@property (nonatomic, strong, readonly) NNWeakSet *subscribers;
@property (nonatomic, assign, readonly) NNServiceType type;
@property (nonatomic, strong, readonly) NNService *instance;
@property (nonatomic, strong, readonly) NSSet *dependencies;
@property (nonatomic, strong, readonly) Protocol *subscriberProtocol;

- (instancetype)initWithService:(Class)service;

@end


@implementation _NNServiceInfo

- (instancetype)initWithService:(Class)service;
{
    NSParameterAssert(_serviceIsValid(service));
    if (!(self = [super init])) { return nil; }
    
    self->_subscribers = [NNWeakSet new];
    self->_instance = [service sharedService];
    self->_instance.subscriberDispatcher.enabled = NO;
    self->_type = [service serviceType];
    self->_dependencies = [service dependencies] ?: [NSSet set];
    self->_subscriberProtocol = [service subscriberProtocol] ?: @protocol(NSObject);

    return self;
}

@end


@interface NNServiceManager ()

// Class => _NNServiceInfo
@property (nonatomic, strong) NSMutableDictionary *lookup;
#define SERVICEINFO(service) ((_NNServiceInfo *)self.lookup[(service)])

// Class
@property (nonatomic, strong) NSMutableSet *runningServices;

// Class => NSMutableSet<Class>
@property (nonatomic, strong) NSMutableDictionary *dependantServices;

@end


@implementation NNServiceManager

#pragma mark - Initialization

+ (void)initialize;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        claimedServices = [NSMutableSet new];
    });
}

+ (NNServiceManager *)sharedManager;
{
    static NNServiceManager *_sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [NNServiceManager new];
    });
    
    return _sharedManager;
}

- (void)registerAllPossibleServices;
{
    BOOL (^classIsService)(Class) = ^(Class class){
        while ((class = class_getSuperclass(class))) {
            if (class == objc_getClass("NNService")) {
                return YES;
            }
        }
        
        return NO;
    };
    
    int numClasses = objc_getClassList(NULL, 0);
    Class *buffer = (__unsafe_unretained Class *)nn_autofree(malloc(numClasses * sizeof(Class *)));
    (void)objc_getClassList(buffer, numClasses);
    
    for (size_t i = 0; i < numClasses; ++i) {
        if (classIsService(buffer[i])) {
            [self registerService:buffer[i]];
        }
    }
}

- (instancetype)init;
{
    if (!(self = [super init])) { return nil; }
    
    self->_lookup = [NSMutableDictionary new];
    self->_runningServices = [NSMutableSet new];
    self->_dependantServices = [NSMutableDictionary new];
    
    return self;
}

- (void)dealloc;
{
    while (self->_runningServices.count) {
        for (Class service in self->_runningServices) {
            if (SERVICEINFO(service).dependencies.count == 0) {
                [self _stopService:service];
                break;
            }
        }
    }
    
    @synchronized([NNServiceManager class]) {
        for (Class service in self->_lookup) {
            [claimedServices removeObject:service];
        }
    }
}

#pragma mark - NSObject

- (NSString *)description;
{
    NSMutableString *result = [NSMutableString stringWithFormat:@"<%@: %p>, services:", NSStringFromClass([self class]), self];
    for (Class service in self->_lookup) {
        [result appendFormat:@"\n\t%@: %@", ([self->_runningServices containsObject:service] ? @"running" : @"stopped"), service];
    }
    return result;
}

#pragma mark - NNServiceManager

- (void)registerService:(Class)service;
{
    NSAssert([NSThread isMainThread], @"Boundary call was not made on main thread");
    
    NSParameterAssert(_serviceIsValid(service));
    if (SERVICEINFO(service)) {
        return;
    }
    
    _NNServiceInfo *info = [[_NNServiceInfo alloc] initWithService:service];
    
    @synchronized([NNServiceManager class]) {
        if ([claimedServices containsObject:service]) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Service %@ already being managed", NSStringFromClass(service)] userInfo:nil];
        }
        [claimedServices addObject:service];
    }
    
    self.lookup[service] = info;

    for (Class dependency in info.dependencies) {
        NSMutableSet *deps = self.dependantServices[dependency];
        if (!deps) {
            self.dependantServices[dependency] = deps = [NSMutableSet new];
        }

        [deps addObject:service];
    }

    [self _startServiceIfReady:service];
}

- (NNService *)instanceForService:(Class)service;
{
    NSAssert([NSThread isMainThread], @"Boundary call was not made on main thread");

    // May be nil if service is not registered!
    return SERVICEINFO(service).instance;
}

- (void)addObserver:(id)observer forService:(Class)service;
{
    NSAssert([NSThread isMainThread], @"Boundary call was not made on main thread");
    
    if (!SERVICEINFO(service)) {
        NSLog(@"Service %@ was not already known, attempting to register with %@.", NSStringFromClass(service), self);
        [self registerService:service];
        NSAssert(SERVICEINFO(service), @"Failed to register service %@ with %@", NSStringFromClass(service), self);
    }
    
    NSParameterAssert([observer conformsToProtocol:SERVICEINFO(service).subscriberProtocol]);
    
    [SERVICEINFO(service).instance.subscriberDispatcher addObserver:observer];
}

- (void)removeObserver:(id)observer forService:(Class)service;
{
    NSAssert([NSThread isMainThread], @"Boundary call was not made on main thread");
    NSParameterAssert(SERVICEINFO(service));
    NSParameterAssert(![SERVICEINFO(service).subscribers containsObject:observer]);
    NSParameterAssert([SERVICEINFO(service).instance.subscriberDispatcher hasObserver:observer]);
    
    [SERVICEINFO(service).instance.subscriberDispatcher removeObserver:observer];
}

- (void)addSubscriber:(id)subscriber forService:(Class)service;
{
    // -addObserver already takes care of parameter validity checking and thread-safety checks.
    [self addObserver:subscriber forService:service];
    
    if ([SERVICEINFO(service).subscribers containsObject:subscriber]) {
        NSLog(@"Object %@ is already subscribed to service %@", subscriber, NSStringFromClass(service));
        return;
    }

    [SERVICEINFO(service).subscribers addObject:subscriber];
    __weak typeof(self) weakSelf = self;
    [NNCleanupProxy cleanupAfterTarget:subscriber withBlock:^{ dispatch_async(dispatch_get_main_queue(), ^{
        typeof(self) self = weakSelf;
        [self _stopServiceIfDone:service];
    }); } withKey:((uintptr_t)service ^ (uintptr_t)self)];
    
    [self _startServiceIfReady:service];
}

- (void)removeSubscriber:(id)subscriber forService:(Class)service;
{
    NSAssert([NSThread isMainThread], @"Boundary call was not made on main thread");
    NSParameterAssert(SERVICEINFO(service));
    NSParameterAssert([SERVICEINFO(service).subscribers containsObject:subscriber]);
    
    [NNCleanupProxy cancelCleanupForTarget:subscriber withKey:((uintptr_t)service ^ (uintptr_t)self)];
    [SERVICEINFO(service).subscribers removeObject:subscriber];

    // This must come after the removal of the subscriber to catch the case where a caller tries to remove an observer that is actually a subscriber.
    [self removeObserver:subscriber forService:service];
    
    [self _stopServiceIfDone:service];
}

#pragma mark Private

- (void)_startServiceIfReady:(Class)service;
{
    if ([self.runningServices containsObject:service]) {
        return;
    }
    
    if (SERVICEINFO(service).type == NNServiceTypeOnDemand && SERVICEINFO(service).subscribers.count == 0) {
        return;
    }
    
    if (![SERVICEINFO(service).dependencies isSubsetOfSet:self.runningServices]) {
        return;
    }

    [self _startService:service];
}

- (void)_stopServiceIfDone:(Class)service;
{
    // This is not needed for correctness, but let's avoid all that recursion if possible.
    if (![self.runningServices containsObject:service]) {
        return;
    }

    // Why is this calling count on subscribers.allObjects instead of on subscribers? Because:
    // NSHashMap was giving a count of 1 when the actual membership of the set was 0 (count didn't update synchronously with object death). allObjects (correctly) returns an empty array in this case.
    // This was the one feature that NNMutableWeakSet had that cost it the most in terms of performance, so it's understandable that NSHashMap doesn't support it..
    NSUInteger actualSubscriberCount = SERVICEINFO(service).subscribers.allObjects.count;
    
    BOOL dependenciesMet = [SERVICEINFO(service).dependencies isSubsetOfSet:self.runningServices];
    BOOL serviceIsWanted = SERVICEINFO(service).type != NNServiceTypeOnDemand || actualSubscriberCount > 0;
    if (dependenciesMet && serviceIsWanted) {
        return;
    }
    
    [self _stopService:service];
}

- (void)_startService:(Class)service;
{
    NSParameterAssert(![self.runningServices containsObject:service]);

    NNService *instance = SERVICEINFO(service).instance;
    
    instance.subscriberDispatcher.enabled = YES;
    
    [instance startService];
    
    [self.runningServices addObject:service];
    
    for (Class dependantClass in self.dependantServices[service]) {
        [self _startServiceIfReady:dependantClass];
    }
}

- (void)_stopService:(Class)service;
{
    NSParameterAssert([self.runningServices containsObject:service]);
    
    NNService *instance = SERVICEINFO(service).instance;

    [self.runningServices removeObject:service];
    
    for (Class dependantClass in self.dependantServices[service]) {
        [self _stopServiceIfDone:dependantClass];
    }
    
    [instance stopService];
    
    instance.subscriberDispatcher.enabled = NO;
}

@end
