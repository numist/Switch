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

#import "NNObjectSerializer.h"
#import "NNWindowData.h"
#import "NNWindowListWorker.h"
#import "NNWindowWorker.h"


@interface NNWindowStore ()

@property (nonatomic, strong) NNWindowListWorker *listWorker;

@property (nonatomic, assign) BOOL updatingWindowContents;
@property (nonatomic, strong) NSMutableDictionary *windowWorkers;

@end


@implementation NNWindowStore

- (instancetype)init;
{
    self = [super init];
    if (!self) return nil;
    
    return [NNObjectSerializer serializedObjectForObject:self];
}

#pragma mark Actions

- (void)startUpdatingWindowList;
{
    if (!self.listWorker) {
        self.listWorker = [[NNWindowListWorker alloc] initWithWindowStore:self];
    }
}

- (void)stopUpdatingWindowList;
{
    self.listWorker = nil;
}

- (void)startUpdatingWindowContents;
{
    self.updatingWindowContents = YES;
    self.windowWorkers = [NSMutableDictionary dictionaryWithCapacity:[_windows count]];
    for (NNWindowData *window in _windows) {
        NNWindowWorker *worker = [[NNWindowWorker alloc] initWithModelObject:window];
        worker.delegate = (id<NNWindowWorkerDelegate>)self;
        [self.windowWorkers setObject:worker forKey:window];
    }
}

- (void)stopUpdatingWindowContents;
{
    self.updatingWindowContents = NO;
    self.windowWorkers = nil;
}

#pragma mark NNWindowWorkerDelegate

- (void)windowWorker:(NNWindowWorker *)worker didUpdateContentsOfWindow:(NNWindowData *)window;
{
    id<NNWindowStoreDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(windowStore:contentsOfWindowDidChange:)]) {
        [delegate windowStore:[NNObjectSerializer serializedObjectForObject:self] contentsOfWindowDidChange:window];
    }
}

#pragma mark Private

- (void)setWindows:(NSArray *)newArray;
{
    NSArray *oldArray = _windows;
    _windows = newArray;
    
    BOOL windowsChanged = ![oldArray isEqualToArray:newArray];
    
    if (self.updatingWindowContents) {
        for (NNWindowData *window in oldArray) {
            if (![newArray containsObject:window]) {
                [self.windowWorkers removeObjectForKey:window];
            }
        }
        
        for (NNWindowData *window in newArray) {
            if (![oldArray containsObject:window]) {
                NNWindowWorker *worker = [[NNWindowWorker alloc] initWithModelObject:window];
                worker.delegate = (id<NNWindowWorkerDelegate>)self;
                [self.windowWorkers setObject:worker forKey:window];
            }
        }
    }
    
    if (windowsChanged) {
        NSLog(@"Window array changed, tracks %lu windows", [newArray count]);
        id<NNWindowStoreDelegate> delegate = self.delegate;
        if (delegate) {
            if ([delegate respondsToSelector:@selector(windowStoreDidUpdateWindowList:)]) {
                [delegate windowStoreDidUpdateWindowList:[NNObjectSerializer serializedObjectForObject:self]];
            }
        }
    }
}

@end
