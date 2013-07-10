//
//  NNWindowWorker.m
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

#import "NNWindowWorker.h"

#import <ReactiveCocoa/EXTScope.h>

#import "imageComparators.h"
#import "NNWindow+Private.h"


static const NSTimeInterval NNPollingIntervalFast = 1.0 / (24.0 * 1000.0 / 1001.0); // 24p applied to NTSC, drawn on 1's.
static const NSTimeInterval NNPollingIntervalSlow = 1.0;


@interface NNWindowWorker ()

@property (atomic, weak, readonly) id<NNWindowWorkerDelegate> delegate;
@property (nonatomic, weak, readonly) NNWindow *window;

@property (nonatomic, strong) __attribute__((NSObject)) CGImageRef previousCapture;

@end


@implementation NNWindowWorker

- (instancetype)initWithModelObject:(NNWindow *)window delegate:(id<NNWindowWorkerDelegate>)delegate;
{
    self = [super initWithQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
    BailUnless(self, nil);
    BailUnless(window, nil);
    BailUnless(delegate, nil);
    
    _window = window;
    _delegate = delegate;
    self.interval = NNPollingIntervalFast;
    
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

- (oneway void)main;
{
    NNWindow *window = self.window;

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
            self.interval = MIN(NNPollingIntervalSlow, self.interval * 2.0);
        } else {
            self.interval = NNPollingIntervalFast;
            self.previousCapture = cgImage;
            
            window.image = [[NSImage alloc] initWithCGImage:cgImage size:NSMakeSize(newWidth, newHeight)];
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong __typeof__(self.delegate) delegate = self.delegate;
                [delegate windowWorker:self didUpdateContentsOfWindow:window];
            });
        }
        
        CFRelease(cgImage); cgImage = NULL;
    } else if (window.exists) {
        // Didn't get a real image, but the window exists. Try again ASAP.
        self.interval = NNPollingIntervalFast;
    } else {
        // Window does not exist. Stop the worker loop.
        return;
    }
}

@end
