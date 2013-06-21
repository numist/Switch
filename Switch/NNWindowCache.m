//
//  NNWindowCache.m
//  Switch
//
//  Created by Scott Perry on 06/20/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNWindowCache.h"


@interface NNWindowCache ()

@property (nonatomic, strong, readonly) NSMutableDictionary *cache;

@end


@implementation NNWindowCache

+ (instancetype)sharedCache;
{
    static NNWindowCache *_sharedCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedCache = [self new];
        NSAssert(_sharedCache, @"Wait what how");
    });
    
    return _sharedCache;
}

- (instancetype)init;
{
    self = [super init];
    if (!self) { return nil; }
    
    _cache = [NSMutableDictionary new];
    
    return self;
}

- (NNWindow *)cachedWindowWithID:(CGWindowID)windowID;
{
    @synchronized(self) {
        return [self.cache objectForKey:@(windowID)];
    }
}

- (void)cacheWindow:(NNWindow *)window withID:(CGWindowID)windowID __attribute__((nonnull(1)));
{
    @synchronized(self) {
        if ([self cachedWindowWithID:windowID]) {
            Log(@"Already have a window for id %u!", windowID);
        }
        
        [self.cache setObject:window forKey:@(windowID)];
    }
}

- (void)removeWindowWithID:(CGWindowID)windowID;
{
    @synchronized(self) {
        if (![self cachedWindowWithID:windowID]) {
            Log(@"Don't have a window for id %u!", windowID);
        }
        
        [self.cache removeObjectForKey:@(windowID)];
    }
}

@end
