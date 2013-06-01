//
//  NNApplication.m
//  Switch
//
//  Created by Scott Perry on 02/21/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNApplication.h"

#import <Haxcessibility/Haxcessibility.h>

#import "despatch.h"
#import "NNWindow+Private.h"

#define COMPARE_RECTS(a, b) ({ \
    NSRect cmpA = (a); \
    NSRect cmpB = (b); \
    cmpA.origin.x == cmpB.origin.x && \
           cmpA.origin.y == cmpB.origin.y && \
           cmpA.size.width == cmpB.size.width && \
           cmpA.size.height == cmpB.size.height; \
})


@interface NNApplication ()

@property (atomic, retain) NSRunningApplication *app;

@property (nonatomic, strong) dispatch_queue_t haxLock;
@property (atomic, strong) HAXApplication *haxApp;

@end


@implementation NNApplication

- (instancetype)initWithPID:(pid_t)pid;
{
    self = [super init];
    if (!self) return nil;
    
    _pid = pid;
    _haxLock = despatch_lock_create([[NSString stringWithFormat:@"%@ <%p>", [self class], self] UTF8String]);
    
    _app = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];

    // This could take a while…
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        HAXApplication *app = [HAXApplication applicationWithPID:pid];
        dispatch_async(self.haxLock, ^{
            self.haxApp = app;
        });
    });
    
    return self;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%d (%@)", self.pid, self.name];
}

#pragma mark Properties

@synthesize name = _name;
- (NSString *)name;
{
    if (!_name) {
        _name = [self.app localizedName];
    }
    return _name;
}

@synthesize icon = _icon;
- (NSImage *)icon;
{
    if (!_icon) {
        NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:[self.app bundleIdentifier]]];
        _icon = icon;
    }
    
    return _icon;
}

#pragma mark NNApplication

- (HAXWindow *)haxWindowForWindow:(NNWindow *)window;
{
    if (despatch_any_locks_held()) {
        NSLog(@"Bad idea to call %s while holding a lock!", __PRETTY_FUNCTION__);
    }
    
    __block HAXWindow *result = nil;
    
    NSRect windowRect = window.cgBounds;
    NSString *windowName = window.name;
    
    dispatch_sync(self.haxLock, ^{
        NSArray *haxWindows = [self.haxApp windows];
        for (HAXWindow *haxWindow in haxWindows) {
            if (COMPARE_RECTS(windowRect, haxWindow.frame)) {
                if (result) {
                    result = [windowName isEqualToString:haxWindow.title] ? haxWindow : result;
                } else {
                    result = haxWindow;
                }
            }
        }
    });

    Check(result);

    return result;
}

@end
