//
//  SWWindowWorker.m
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

#import "SWWindowWorker.h"

#import <NNKit/NNPollingObject+Protected.h>
#import <ReactiveCocoa/EXTScope.h>

#import "imageComparators.h"
#import "SWWindow.h"


static const NSTimeInterval NNPollingIntervalFast = 1.0 / (24.0 * 1000.0 / 1001.0); // 24p applied to NTSC, drawn on 1's.
static const NSTimeInterval NNPollingIntervalSlow = 1.0;


@interface SWWindowWorker ()

@property (nonatomic, copy, readonly) SWWindow *window;

@property (nonatomic, strong) __attribute__((NSObject)) CGImageRef previousCapture;

@end


@implementation SWWindowWorker

#pragma mark Initialization

- (instancetype)initWithModelObject:(SWWindow *)window;
{
    BailUnless(window, nil);
    if (!(self = [super initWithQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)])) { return nil; }
    
    _window = window;
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

#pragma mark NNPollingObject

- (oneway void)main;
{
    CGImageRef cgImage = NNCFAutorelease(CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow, self.window.windowID, kCGWindowImageBoundsIgnoreFraming));

    if (CGImageGetHeight(cgImage) < 1.0 || CGImageGetWidth(cgImage) < 1.0) {
        cgImage = NULL;
    }
    
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
            
            [self postNotification:@{
                @"window" : self.window,
                @"content" : [[NSImage alloc] initWithCGImage:cgImage size:NSMakeSize(newWidth, newHeight)],
            }];
        }
    } else if ([CFBridgingRelease(CGWindowListCreate(kCGWindowListOptionIncludingWindow, self.window.windowID)) count]) {
        // Didn't get a real image, but the window exists. Try again ASAP.
        self.interval = NNPollingIntervalFast;
    } else {
        // Window does not exist. Stop the worker loop.
        self.interval = -1.0;
        return;
    }
}

#pragma mark SWWindowWorker

- (CGWindowID)windowID;
{
    return self.window.windowID;
}

@end
