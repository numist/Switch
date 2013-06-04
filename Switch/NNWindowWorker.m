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
#import "NNWindow+Private.h"


static const NSTimeInterval NNPollingIntervalFast = 1.0 / (24.0 * 1000.0 / 1001.0); // 24p applied to NTSC, drawn on 1's.
static const NSTimeInterval NNPollingIntervalSlow = 1.0;


@interface NNWindowWorker ()

@property (nonatomic, weak) id<NNWindowWorkerDelegate> delegate;
@property (nonatomic, strong, readonly) dispatch_queue_t lock;
@property (nonatomic, strong) __attribute__((NSObject)) CGImageRef previousCapture;
@property (nonatomic, assign) NSTimeInterval updateInterval;
@property (nonatomic, weak) NNWindow *window;

@end


@implementation NNWindowWorker

- (instancetype)initWithModelObject:(NNWindow *)window delegate:(id<NNWindowWorkerDelegate>)delegate;
{
    self = [super init];
    BailUnless(self, nil);
    BailUnless(window, nil);
    BailUnless(delegate, nil);
    
    _lock = despatch_lock_create([[NSString stringWithFormat:@"%@ <%p>", [self class], self] UTF8String]);
    _window = window;
    _delegate = delegate;
    _updateInterval = NNPollingIntervalFast;
    
    dispatch_async(_lock, ^{
        [self workerLoop];
    });
    
    return self;
}

- (void)dealloc;
{
    // Oops ARC won't save me here. rdar://14018474
    if (_previousCapture) {
        CFRelease(_previousCapture);
        _previousCapture = nil;
    }
}

#pragma mark Internal

- (oneway void)workerLoop;
{
    despatch_lock_assert(self.lock);

    NNWindow *window = self.window;

    NSDate *start = [NSDate date];
    CGImageRef cgImage = [window copyCGWindowImage];
    
    if (cgImage) {
        BOOL imageChanged = NO;
        
        size_t newWidth = CGImageGetWidth(cgImage);
        size_t newHeight = CGImageGetHeight(cgImage);
        { // Did the image change?
            if (!self.previousCapture) {
                imageChanged = YES;
            } else {
                size_t oldWidth = CGImageGetWidth(self.previousCapture);
                size_t oldHeight = CGImageGetHeight(self.previousCapture);
                
                if (newWidth != oldWidth || newHeight != oldHeight) {
                    imageChanged = YES;
                } else {
                    imageChanged = imagesDifferByCGDataProviderComparison(cgImage, self.previousCapture);
                }
            }
        }
        
        if (!imageChanged) {
            self.updateInterval = MIN(NNPollingIntervalSlow, self.updateInterval * 2.0);
        } else {
            self.updateInterval = NNPollingIntervalFast;
            self.previousCapture = cgImage;
            
            NNWindow *update = [window copy];
            update.image = [[NSImage alloc] initWithCGImage:cgImage size:NSMakeSize(newWidth, newHeight)];
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong __typeof__(self.delegate) delegate = self.delegate;
                [delegate windowWorker:self didUpdateContentsOfWindow:update];
            });
        }
        
        CFRelease(cgImage); cgImage = NULL;
    } else if (window.exists) {
        // Didn't get a real image, but the window exists. Try again ASAP.
        self.updateInterval = NNPollingIntervalFast;
    } else {
        // Window does not exist. Stop the worker loop.
        NotTested();
        return;
    }
    
    // All done, schedule the next update.
    __weak __typeof__(self) weakSelf = self;
    double delayInSeconds = MAX(self.updateInterval - [[NSDate date] timeIntervalSinceDate:start], 0.0);
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, self.lock, ^(void){
        __strong __typeof__(self) self = weakSelf;
        __strong __typeof__(self.delegate) delegate = self.delegate;
        if (delegate) {
            [self workerLoop];
        }
    });
}

@end
