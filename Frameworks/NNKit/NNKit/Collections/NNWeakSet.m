//
//  NNWeakSet.m
//  NNKit
//
//  Created by Scott Perry on 11/15/13.
//  Copyright © 2016 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNWeakSet.h"

#import "_NNWeakArrayTombstone.h"
#import "_NNWeakSetEnumerator.h"
#import "NNCleanupProxy.h"


@interface NNWeakSet ()

@property (nonatomic, readonly, strong) NSMutableSet *backingStore;

- (void)_removeObjectAllowingNil:(id)object;

@end


/**
 
 collection -> tombstone                    // Unavoidable. The whole point of this exercise.
 tombstone -> object [style = "dotted"];    // Obvious.
 cleanup -> tombstone [style = "dotted"];   // For removing the tombstone from the collection.
 cleanup -> collection [style = "dotted"];  // For removing the tombstone from the collection.
 object -> cleanup;                         // Object association, the only strong reference to the proxy.
 object -> tombstone [style = "dotted];     // Object association so the collection can look at the object and find the tombstone.
 
 */


@implementation NNWeakSet

- (instancetype)initWithCapacity:(NSUInteger)numItems;
{
    if (!(self = [super init])) { return nil; }
    
    self->_backingStore = [[NSMutableSet alloc] initWithCapacity:numItems];
    
    return self;
}

- (id)init;
{
    if (!(self = [super init])) { return nil; }
    
    self->_backingStore = [NSMutableSet new];
    
    return self;
}

#pragma mark NSSet

- (NSUInteger)count;
{
    @synchronized(self.backingStore) {
        return self.backingStore.count;
    }
}

- (id)member:(id)object;
{
    @synchronized(self.backingStore) {
        return ((_NNWeakArrayTombstone *)[self.backingStore member:object]).target;
    }
}

- (NSEnumerator *)objectEnumerator;
{
    @synchronized(self.backingStore) {
        return [[_NNWeakSetEnumerator alloc] initWithWeakSet:self];
    }
}

#pragma mark NSMutableSet

- (void)addObject:(id)object;
{
    _NNWeakArrayTombstone *tombstone = [_NNWeakArrayTombstone tombstoneWithTarget:object];
    NNCleanupProxy *proxy = [NNCleanupProxy cleanupProxyForTarget:object withKey:(uintptr_t)self];
    
    __weak NNWeakSet *weakCollection = self;
    __weak _NNWeakArrayTombstone *weakTombstone = tombstone;
    proxy.cleanupBlock = ^{
        NNWeakSet *collection = weakCollection;
        [collection _removeObjectAllowingNil:weakTombstone];
    };
    
    @synchronized(self.backingStore) {
        [self.backingStore addObject:tombstone];
    }
}

- (void)removeObject:(id)object;
{
    [NNCleanupProxy cancelCleanupForTarget:object withKey:(uintptr_t)self];
    @synchronized(self.backingStore) {
        [self.backingStore removeObject:object];
    }
}

#pragma mark Private

- (void)_removeObjectAllowingNil:(id)object;
{
    if (!object) { return; }
    
    @synchronized(self.backingStore) {
        [self.backingStore removeObject:object];
    }
}

@end