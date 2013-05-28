//
//  NNWindowListWorker.m
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

#import "NNWindowListWorker.h"

#import "despatch.h"
#import "NNWindow+Private.h"
#import "NNWindowStore+Private.h"


static NSTimeInterval refreshInterval = 0.1;


@interface NNWindowListWorker ()

@property (atomic, strong, readonly) dispatch_queue_t lock;
@property (nonatomic, weak) NNWindowStore *store;
@property (nonatomic, retain) NSMutableDictionary *windowDict;

@end


@implementation NNWindowListWorker

- (instancetype)initWithWindowStore:(NNWindowStore *)store;
{
    self = [super init];
    if (!self) return nil;
    
    _lock = despatch_lock_create([[NSString stringWithFormat:@"%@ <%p>", [self class], self] UTF8String]);
    _store = store;
    
    // All calls made by the owner of this object should be serialized.
    return self;
}

- (oneway void)start;
{
    dispatch_async(self.lock, ^{
        [self workerLoop];
    });
}

#pragma mark Internal

- (oneway void)workerLoop;
{
    despatch_lock_assert(self.lock);
    
    CFArrayRef cgInfo = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements,  kCGNullWindowID);
    NSArray *info = CFBridgingRelease(cgInfo);
    
    NSMutableDictionary *newWindowDict = [NSMutableDictionary dictionaryWithCapacity:[info count]];
    NSMutableArray *windows = [NSMutableArray arrayWithCapacity:[info count]];
    
    for (unsigned i = 0; i < [info count]; i++) {
        NSNumber *windowID = [[(NSArray *)info objectAtIndex:i] objectForKey:(NSString *)kCGWindowNumber];
        NNWindow *window = [self.windowDict objectForKey:windowID];
        
        // Not a window we already know about? Try building a new one.
        if (!window) {
            window = [[NNWindow alloc] initWithDescription:[info objectAtIndex:i]];
        }
        
        // Window found or info valid for creating a new window.
        if (window) {
            [windows addObject:window];
            [newWindowDict setObject:window forKey:windowID];
        }
    }
    
    self.windowDict = newWindowDict;
    // TODO: This should probably be a delegate mechanism, for clarity.
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof__(self.store) store = self.store;
        store.windows = windows;
    });
    
    // All done, schedule the next update.
    __weak __typeof__(self) weakSelf = self;
    double delayInSeconds = refreshInterval;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, self.lock, ^(void){
        __strong __typeof__(self) self = weakSelf;
        [self workerLoop];
    });
}

@end
