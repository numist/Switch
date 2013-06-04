//
//  NNHAXWindowCache.m
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

#import "NNHAXWindowCache.h"

#import <Haxcessibility/Haxcessibility.h>
#import <Haxcessibility/HAXElement+Protected.h>

#import "despatch.h"


static NSString *kNNHaxWindowCacheObserverKey = @"NNHaxWindowCacheObserverKey";
static NSString *kNNHaxWindowCacheElementDestroyedNotification = @"NNHaxWindowCacheElementDestroyedNotification";
static NSString *kNNHaxWindowCacheWindowIDKey = @"windowID";


@interface NNHAXWindowCache ()

@property (nonatomic, readonly) NSMutableDictionary *cache;
@property (nonatomic, readonly) dispatch_queue_t lock;

+ (NSNotificationCenter *)notificationCenter;

@end


static void axCallback(AXObserverRef observer, AXUIElementRef element, CFStringRef notification, void *refcon) {
    BailUnless(CFStringCompare(notification, kAXUIElementDestroyedNotification, 0) == kCFCompareEqualTo,);
    [[NNHAXWindowCache notificationCenter] postNotificationName:kNNHaxWindowCacheElementDestroyedNotification object:nil userInfo:@{
        kNNHaxWindowCacheWindowIDKey : @((CGWindowID)refcon)
    }];
}


@implementation NNHAXWindowCache

#pragma mark NNHAXWindowCache (class)

+ (instancetype)sharedCache;
{
    static NNHAXWindowCache *_sharedCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedCache = [self new];
    });
    
    return _sharedCache;
}

+ (NSNotificationCenter *)notificationCenter;
{
    static NSNotificationCenter *_center;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _center = [NSNotificationCenter new];
    });
    return _center;
}

#pragma mark NSObject

- (instancetype)init;
{
    self = [super init];
    if (!self) { return nil; }
    
    _cache = [NSMutableDictionary new];
    _lock = despatch_lock_create([[NSString stringWithFormat:@"%@ <%p>", [self class], self] UTF8String]);
    [[NNHAXWindowCache notificationCenter] addObserver:self selector:@selector(elementDestroyedNotification:) name:kNNHaxWindowCacheElementDestroyedNotification object:nil];
    
    return self;
}

- (void)dealloc;
{
    [[NNHAXWindowCache notificationCenter] removeObserver:self name:kNNHaxWindowCacheElementDestroyedNotification object:nil];
}

#pragma mark NNHAXWindowCache

- (HAXWindow *)cachedWindowWithID:(CGWindowID)windowID;
{
    __block HAXWindow *result;
    
    dispatch_sync(self.lock, ^{
        result = [self.cache objectForKey:@(windowID)];
    });
    
    return result;
}

- (void)cacheWindow:(HAXWindow *)window withID:(CGWindowID)windowID;
{
    dispatch_sync(self.lock, ^{
        [self removeWindowWithID:windowID];
        
        if ([self addAXObserverForWindow:window withID:windowID]) {
            [self.cache setObject:window forKey:@(windowID)];
        }
    });
}

#pragma mark NSNotificationCenter

- (void)elementDestroyedNotification:(NSNotification *)notification;
{
    dispatch_async(self.lock, ^{
        BailUnless([notification.userInfo objectForKey:kNNHaxWindowCacheWindowIDKey],);
        [self removeWindowWithID:[[notification.userInfo objectForKey:kNNHaxWindowCacheWindowIDKey] unsignedIntValue]];
    });
}

#pragma mark Internal

- (void)removeWindowWithID:(CGWindowID)windowID;
{
    despatch_lock_assert(self.lock);
    
    HAXWindow *window = [self.cache objectForKey:@(windowID)];
    if (!window) { return; }
    
    [self.cache removeObjectForKey:@(windowID)];
    [self removeAXObserverForWindow:window];
}

- (BOOL)addAXObserverForWindow:(HAXWindow *)window withID:(CGWindowID)windowID;
{
    despatch_lock_assert(self.lock);

    AXObserverRef observer;
    AXError err;
    pid_t pid;

    err = AXUIElementGetPid(window.elementRef, &pid);
    BailUnless(err == kAXErrorSuccess, NO);

    err = AXObserverCreate(pid, axCallback, &observer);
    BailUnless(err == kAXErrorSuccess, NO);
    
    err = AXObserverAddNotification(observer, window.elementRef, kAXUIElementDestroyedNotification, (void *)windowID);
    BailUnless(err == kAXErrorSuccess, NO);
    
    CFRunLoopAddSource([[NSRunLoop mainRunLoop] getCFRunLoop], AXObserverGetRunLoopSource(observer), kCFRunLoopDefaultMode);
    
    objc_setAssociatedObject(window, (__bridge const void *)kNNHaxWindowCacheObserverKey, (__bridge id)observer, OBJC_ASSOCIATION_ASSIGN);
    
    return YES;
}

- (void)removeAXObserverForWindow:(HAXWindow *)window;
{
    AXObserverRef observer = (__bridge AXObserverRef)objc_getAssociatedObject(window, (__bridge const void *)kNNHaxWindowCacheObserverKey);
    BailUnless(observer,);
    
    AXError err;
    err = AXObserverRemoveNotification(observer, window.elementRef, kAXUIElementDestroyedNotification);
    Check(err == kAXErrorSuccess || err == kAXErrorInvalidUIElement);
    
    CFRunLoopSourceRef observerRunLoopSource = AXObserverGetRunLoopSource(observer);
    Check(observerRunLoopSource);
    if (observerRunLoopSource) {
        CFRunLoopRemoveSource([[NSRunLoop mainRunLoop] getCFRunLoop], observerRunLoopSource, kCFRunLoopDefaultMode);
    }
    
    CFRelease(observer);
    observer = NULL;
    
    objc_setAssociatedObject(window, (__bridge const void *)kNNHaxWindowCacheObserverKey, nil, OBJC_ASSOCIATION_ASSIGN);
}

@end
