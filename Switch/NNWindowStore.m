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

#import "NNWindowStore+Private.h"

#import "despatch.h"
#import "NNDelegateProxy.h"
#import "NNWindow.h"
#import "NNWindowListWorker.h"
#import "NNWindowWorker.h"


@interface NNWindowStore ()

@property (nonatomic, strong) NNWindowListWorker *listWorker;
@property (nonatomic, strong, readonly) dispatch_queue_t lock;
@property (nonatomic, assign) BOOL updatingWindowContents;
@property (nonatomic, strong) NSMutableDictionary *windowWorkers;

@end


@implementation NNWindowStore

- (instancetype)init;
{
    self = [super init];
    if (!self) return nil;
    
    despatch_lock_promote(dispatch_get_main_queue());
    _lock = despatch_lock_create([[NSString stringWithFormat:@"%@ <%p>", [self class], self] UTF8String]);
    
    return self;
}

#pragma mark Actions

- (void)startUpdatingWindowList;
{
    dispatch_async(self.lock, ^{
        if (!self.listWorker) {
            self.listWorker = [[NNWindowListWorker alloc] initWithWindowStore:self];
            [self.listWorker start];
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

    [self.delegate windowStore:self contentsOfWindowDidChange:window];
}

#pragma mark Private

- (oneway void)setWindows:(NSArray *)newArray;
{
    dispatch_async(self.lock, ^{
        NSArray *oldArray = _windows;
        _windows = newArray;
        
        BOOL windowsChanged = ![oldArray isEqualToArray:newArray];
        
        // Have to catch which windows are old/new if updating window contents to manage the workers.
        if (self.updatingWindowContents) {
            for (NNWindow *window in oldArray) {
                if (![newArray containsObject:window]) {
                    [self.windowWorkers removeObjectForKey:window];
                }
            }
            
            for (NNWindow *window in newArray) {
                if (![oldArray containsObject:window]) {
                    NNWindowWorker *worker = [[NNWindowWorker alloc] initWithModelObject:window];
                    worker.delegate = (id<NNWindowWorkerDelegate>)self;
                    [worker start];
                    [self.windowWorkers setObject:worker forKey:window];
                }
            }
        }
        
        if (windowsChanged) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate windowStoreDidUpdateWindowList:self];
            });
        }
    });
}

@end
