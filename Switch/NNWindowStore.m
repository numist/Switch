//
//  NNWindowStore.m
//  Switch
//
//  Created by Scott Perry on 02/22/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNWindowStore.h"

#import "despatch.h"
#import "NNWindow.h"
#import "NNWindowListWorker.h"
#import "NNWindowWorker.h"


@interface NNWindowStore () <NNWindowListWorkerDelegate>

@property (nonatomic, weak) id<NNWindowStoreDelegate> delegate;

// Serialization
@property (nonatomic, strong) dispatch_queue_t lock;

// Window list updates
@property (nonatomic, strong) NNWindowListWorker *listWorker;
@property (nonatomic, strong) NSArray *windows;

// Window content updates
@property (nonatomic, assign) BOOL updatingWindowContents;
@property (nonatomic, strong) NSMutableDictionary *windowWorkers;

@end


@implementation NNWindowStore

- (instancetype)initWithDelegate:(id<NNWindowStoreDelegate>)delegate;
{
    self = [super init];
    if (!self) return nil;
    
    despatch_lock_promote(dispatch_get_main_queue());
    _lock = dispatch_get_main_queue();
    
    _delegate = delegate;
    _windows = [NSArray new];
    
    return self;
}

#pragma mark Actions

- (void)startUpdatingWindowList;
{
    dispatch_async(self.lock, ^{
        if (!self.listWorker) {
            self.listWorker = [[NNWindowListWorker alloc] initWithDelegate:self];
        }
    });
}

- (void)stopUpdatingWindowList;
{
    dispatch_async(self.lock, ^{
        self.listWorker = nil;
    });
}

- (void)startUpdatingWindowContents;
{
    dispatch_async(self.lock, ^{
        self.updatingWindowContents = YES;
        self.windowWorkers = [NSMutableDictionary dictionaryWithCapacity:[_windows count]];
        for (NNWindow *window in _windows) {
            NNWindowWorker *worker = [[NNWindowWorker alloc] initWithModelObject:window];
            worker.delegate = (id<NNWindowWorkerDelegate>)self;
            [worker start];
            [self.windowWorkers setObject:worker forKey:window];
        }
    });
}

- (void)stopUpdatingWindowContents;
{
    dispatch_async(self.lock, ^{
        self.updatingWindowContents = NO;
        self.windowWorkers = nil;
    });
}

#pragma mark NNWindowWorkerDelegate

- (void)windowWorker:(NNWindowWorker *)worker didUpdateContentsOfWindow:(NNWindow *)window;
{
    despatch_lock_assert(dispatch_get_main_queue());

    __strong __typeof__(self.delegate) delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(storeWillChangeContent:)]) {
        [delegate storeWillChangeContent:self];
    }
    if ([delegate respondsToSelector:@selector(store:didChangeWindow:atIndex:forChangeType:newIndex:)]) {
        [delegate store:self didChangeWindow:window atIndex:[self.windows indexOfObject:window] forChangeType:NNWindowStoreChangeUpdate newIndex:[self.windows indexOfObject:window]];
    }
    if ([delegate respondsToSelector:@selector(storeDidChangeContent:)]) {
        [delegate storeDidChangeContent:self];
    }
}

#pragma mark Private

- (void)listWorker:(NNWindowListWorker *)worker didUpdateWindowList:(NSArray *)newArray;
{
    dispatch_async(self.lock, ^{
        NSMutableArray *oldArray = [_windows mutableCopy];
        
        BOOL windowsChanged = ![oldArray isEqualToArray:newArray];
        __strong __typeof__(self.delegate) delegate = nil;
        
        if (windowsChanged) {
            delegate = self.delegate;
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([delegate respondsToSelector:@selector(storeWillChangeContent:)]) {
                    [delegate storeWillChangeContent:self];
                }
            });
        }
        
        NSMutableArray *changes = [NSMutableArray new];
        for (NNWindow *window in oldArray) {
            if (![newArray containsObject:window]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([delegate respondsToSelector:@selector(store:didChangeWindow:atIndex:forChangeType:newIndex:)]) {
                        [delegate store:self didChangeWindow:window atIndex:[oldArray indexOfObject:window] forChangeType:NNWindowStoreChangeDelete newIndex:NSNotFound];
                    }
                });
                
                if (self.updatingWindowContents) {
                    [self.windowWorkers removeObjectForKey:window];
                    [changes addObject:window];
                }
            }
        }
        // Match old array with new.
        [oldArray removeObjectsInArray:changes];
        [changes removeAllObjects];

        
        for (NNWindow *window in newArray) {
            if (![oldArray containsObject:window]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([delegate respondsToSelector:@selector(store:didChangeWindow:atIndex:forChangeType:newIndex:)]) {
                        [delegate store:self didChangeWindow:window atIndex:NSNotFound forChangeType:NNWindowStoreChangeInsert newIndex:[newArray indexOfObject:window]];
                    }
                });
                
                // Match old array with new.
                [oldArray insertObject:window atIndex:[newArray indexOfObject:window]];
                
                if (self.updatingWindowContents) {
                    NNWindowWorker *worker = [[NNWindowWorker alloc] initWithModelObject:window];
                    worker.delegate = (id<NNWindowWorkerDelegate>)self;
                    [worker start];
                    [self.windowWorkers setObject:worker forKey:window];
                }
            }
        }
        
        
        for (NNWindow *window in newArray) {
            NSUInteger oldIndex = [oldArray indexOfObject:window];
            NSUInteger newIndex = [newArray indexOfObject:window];

            if (oldIndex != newIndex) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([delegate respondsToSelector:@selector(store:didChangeWindow:atIndex:forChangeType:newIndex:)]) {
                        [delegate store:self didChangeWindow:window atIndex:oldIndex forChangeType:NNWindowStoreChangeMove newIndex:newIndex];
                    }
                });
                [oldArray removeObject:window];
                [oldArray insertObject:window atIndex:[newArray indexOfObject:window]];
            }
        }
        
        
        if (windowsChanged) {
            _windows = newArray;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([delegate respondsToSelector:@selector(storeDidChangeContent:)]) {
                    [delegate storeDidChangeContent:self];
                }
            });
        }
    });
}

@end
