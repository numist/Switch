//
//  NNWindowWorker.m
//  Docking
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

#import "NNWindowWorker.h"

#import "despatch.h"
#import "imageComparators.h"
#import "NNObjectSerializer.h"
#import "NNWindowData+Private.h"


static NSTimeInterval NNPollingIntervalFast = 0.05;
static NSTimeInterval NNPollingIntervalSlow = 1.0;


@interface NNWindowWorker ()

@property (nonatomic, weak) NNWindowData *window;
@property (nonatomic, assign) NSTimeInterval updateInterval;
@property (nonatomic, strong) NSImage *previousCapture;

@end


@implementation NNWindowWorker

- (instancetype)initWithModelObject:(NNWindowData *)window;
{
    self = [super init];
    if (!self) { return nil; }
    
    _window = window;
    _updateInterval = NNPollingIntervalFast;
    
    NNWindowWorker *serializedSelf = [NNObjectSerializer serializedObjectForObject:self];
    
    return serializedSelf;
}

- (oneway void)start;
{
    [self workerLoop];
}

#pragma Internal

- (oneway void)workerLoop;
{
    // Short circuit in case the window went away or we were told to stop.
    if (!self.window) {
        return;
    }
    
    NSDate *start = [NSDate date];
    NSImage *result = [self.window getCGWindowImage];
    
    if (result) {
        BOOL imageChanged = NO;
        { // Did the image change?
            if (!self.previousCapture) {
                imageChanged = YES;
            } else {
                NSSize newImageSize = result.size;
                NSSize oldImageSize = self.previousCapture.size;
                
                if (newImageSize.width != oldImageSize.width || newImageSize.height != oldImageSize.height) {
                    imageChanged = YES;
                } else {
                    imageChanged = imagesDifferByCachedBitmapContextComparison(result, self.previousCapture);
                }
            }
        }
        
        if (!imageChanged) {
            self.updateInterval = MIN(NNPollingIntervalSlow, self.updateInterval * 2.0);
        } else {
            self.updateInterval = NNPollingIntervalFast;
            self.previousCapture = result;
            self.window.image = [result copy];
            id<NNWindowWorkerDelegate> delegate = self.delegate;
            NNWindowData *window = self.window;
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [delegate windowWorker:[NNObjectSerializer serializedObjectForObject:self] didUpdateContentsOfWindow:window];
            });
        }
    } else if (self.window.exists) {
        // Didn't get a real image, but the window exists. Try again ASAP.
        self.updateInterval = NNPollingIntervalFast;
    }
    
    // All done, schedule the next update.
    __weak NNWindowWorker *this = self;
    double delayInSeconds = self.updateInterval - [[NSDate date] timeIntervalSinceDate:start];
    if (delayInSeconds < 0.0) {
//        NSLog(@"WARNING: Window content analysis for %@ took %f seconds longer than update interval %f", self.window, fabs(delayInSeconds), self.updateInterval);
    }
    [NNObjectSerializer performOnObject:self afterDelay:MAX(0.01, delayInSeconds) block:^{
        [this workerLoop];
    }];
}

@end
