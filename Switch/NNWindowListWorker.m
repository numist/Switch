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

#import <ReactiveCocoa/EXTScope.h>

#import "NNWindow+Private.h"


static NSTimeInterval refreshInterval = 0.1;


@interface NNWindowListWorker ()

@property (nonatomic, weak) id<NNWindowListWorkerDelegate> delegate;

@end


@implementation NNWindowListWorker

- (instancetype)initWithDelegate:(id<NNWindowListWorkerDelegate>)delegate;
{
    self = [super init];
    if (!self) return nil;
    
    _delegate = delegate;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self workerLoop];
    });

    return self;
}

#pragma mark Internal

- (oneway void)workerLoop;
{
    CFArrayRef cgInfo = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements,  kCGNullWindowID);
    NSArray *info = CFBridgingRelease(cgInfo);
    
    NSArray *windows = [NSMutableArray arrayWithCapacity:[info count]];
    
    for (unsigned i = 0; i < [info count]; i++) {
        NNWindow *window = [NNWindow windowWithDescription:[info objectAtIndex:i]];

        // Window found or info valid for creating a new window.
        if (window) {
            Check(![windows containsObject:window]);
            [(NSMutableArray *)windows addObject:window];
        }
    }
    
    windows = [NNWindow filterValidWindowsFromArray:windows];
    
    // Schedule delegate update and next iteration of worker loop.
    @weakify(self);

    NSArray *result = [windows copy];
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self);
        if (self) {
            __strong __typeof__(self.delegate) delegate = self.delegate;
            [delegate listWorker:self didUpdateWindowList:result];
        }
    });
    
    double delayInSeconds = refreshInterval;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void){
        @strongify(self);
        [self workerLoop];
    });
}

@end
