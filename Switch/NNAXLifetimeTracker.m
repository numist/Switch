//
//  NNAXLifetimeTracker.m
//  Switch
//
//  Created by Scott Perry on 06/04/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNAXLifetimeTracker.h"

#import <Haxcessibility/Haxcessibility.h>
#import <Haxcessibility/HAXElement+Protected.h>

#import "despatch.h"

NSString *kNNAXLifetimeEndedNotification = @"NNAXLifetimeEndedNotification";

static NSString *kNNHaxWindowCacheObserverKey = @"NNHaxWindowCacheObserverKey";


@interface NNAXLifetimeTracker ()

@property (nonatomic, readonly) NSMutableSet *cache;
@property (nonatomic, readonly) dispatch_queue_t lock;

- (void)elementWasDestroyed:(HAXElement *)element;

@end


static void axCallback(AXObserverRef observer, AXUIElementRef element, CFStringRef notification, void *refcon) {
    BailUnless(CFStringCompare(notification, kAXUIElementDestroyedNotification, 0) == kCFCompareEqualTo,);
    
    [[NNAXLifetimeTracker sharedTracker] elementWasDestroyed:(__bridge HAXElement *)(refcon)];
}


@implementation NNAXLifetimeTracker

#pragma mark NNHAXWindowCache (class)

static NNAXLifetimeTracker *_sharedCache;

+ (instancetype)sharedTracker;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedCache = [self new];
        NSAssert(_sharedCache, @"Ok how does this even happen");
    });
    
    return _sharedCache;
}

#pragma mark NSObject

- (instancetype)init;
{
    if (_sharedCache) { return _sharedCache; }

    self = [super init];
    if (!self) { return nil; }
    
    _cache = [NSMutableSet new];
    _lock = despatch_lock_create([[NSString stringWithFormat:@"%@ <%p>", [self class], self] UTF8String]);
    
    return self;
}

#pragma mark NNAXLifetimeTracker

- (void)trackLifetimeOfHAXElement:(HAXElement *)element;
{
    dispatch_async(self.lock, ^{
        if (![self.cache containsObject:element]) {
            [self addAXObserverForHAXElement:element];
            [self.cache addObject:element];
        }
    });
}

#pragma mark Private

- (void)elementWasDestroyed:(HAXElement *)element;
{
    dispatch_async(self.lock, ^{
        if (![self.cache containsObject:element]) { return; }
        
        [self removeAXObserverForHAXElement:element];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kNNAXLifetimeEndedNotification object:element];
        [self.cache removeObject:element];
    });
}

#pragma mark Internal

- (BOOL)addAXObserverForHAXElement:(HAXElement *)element;
{
    despatch_lock_assert(self.lock);

    if (objc_getAssociatedObject(element, (__bridge const void *)kNNHaxWindowCacheObserverKey)) {
        return YES;
    }
    
    AXObserverRef observer;
    AXError err;
    pid_t pid;

    err = AXUIElementGetPid(element.elementRef, &pid);
    BailUnless(err == kAXErrorSuccess, NO);

    err = AXObserverCreate(pid, axCallback, &observer);
    BailUnless(err == kAXErrorSuccess, NO);
    
    err = AXObserverAddNotification(observer, element.elementRef, kAXUIElementDestroyedNotification, (__bridge void *)(element));
    BailUnless(err == kAXErrorSuccess, NO);
    
    CFRunLoopAddSource([[NSRunLoop mainRunLoop] getCFRunLoop], AXObserverGetRunLoopSource(observer), kCFRunLoopDefaultMode);
    
    objc_setAssociatedObject(element, (__bridge const void *)kNNHaxWindowCacheObserverKey, (__bridge id)observer, OBJC_ASSOCIATION_ASSIGN);
    
    return YES;
}

- (void)removeAXObserverForHAXElement:(HAXElement *)element;
{
    // TODO(numist): not safe against windows being added to multiple caches!
    // XXX: if caches are explicitly add-only, then this can be ok; removal will only happen when the object is being removed from all caches!
    despatch_lock_assert(self.lock);
    
    AXObserverRef observer = (__bridge AXObserverRef)objc_getAssociatedObject(element, (__bridge const void *)kNNHaxWindowCacheObserverKey);
    BailUnless(observer,);
    
    AXError err;
    err = AXObserverRemoveNotification(observer, element.elementRef, kAXUIElementDestroyedNotification);
    Check(err == kAXErrorSuccess || err == kAXErrorInvalidUIElement);
    
    CFRunLoopSourceRef observerRunLoopSource = AXObserverGetRunLoopSource(observer);
    Check(observerRunLoopSource);
    if (observerRunLoopSource) {
        CFRunLoopRemoveSource([[NSRunLoop mainRunLoop] getCFRunLoop], observerRunLoopSource, kCFRunLoopDefaultMode);
    }
    
    CFRelease(observer);
    observer = NULL;
    
    objc_setAssociatedObject(element, (__bridge const void *)kNNHaxWindowCacheObserverKey, nil, OBJC_ASSOCIATION_ASSIGN);
}

@end
