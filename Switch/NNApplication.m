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
#import "NNApplicationCache.h"
#import "NNWindow+Private.h"


@interface NNApplication () <HAXElementDelegate>

@property (nonatomic, readonly, assign) pid_t pid;
@property (atomic, retain) NSRunningApplication *app;
@property (nonatomic, readonly, assign) ProcessSerialNumber psn;

@property (nonatomic, strong) dispatch_queue_t haxLock;
@property (nonatomic, strong, readonly) HAXApplication *haxApp;

@end


@implementation NNApplication

+ (instancetype)applicationWithPID:(pid_t)pid;
{
    @synchronized(self) {
        NNApplication *result = [[NNApplicationCache sharedCache] cachedApplicationWithPID:pid];
        
        if (!result) {
            result = [[self alloc] initWithPID:pid];
            
            if (result) {
                [[NNApplicationCache sharedCache] cacheApplication:result withPID:pid];
            }
        }
        
        return result;
    }
}

- (instancetype)initWithPID:(pid_t)pid;
{
    self = [super init];
    if (!self) return nil;
    
    _pid = pid;
    
    _haxLock = despatch_lock_create([[NSString stringWithFormat:@"%@ <%p>", [self class], self] UTF8String]);

    OSStatus status = GetProcessForPID(self.pid, &_psn);
    if (status) {
        return nil;
    }
    
    _app = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
    
    // Load the HAXWindow ASAP, but without blocking.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        (void)self.haxApp;
    });

    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone;
{
    Check(!zone);
    return self;
}

- (NSUInteger)hash;
{
    return (NSUInteger)self.pid;
}

- (BOOL)isEqual:(id)object;
{
    Check(object);
    return ([object isKindOfClass:[self class]] && [self hash] == [object hash]);
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%p <%d (%@)>", self, self.pid, self.name];
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
        NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:[self.app bundleIdentifier]];
        if (path) {
            _icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
        } else {
            Log(@"Application %@ does not have an icon!", self);
            // TODO(numist): Can this even happen?
            NotTested();
        }
    }
    
    return _icon;
}

#pragma mark HAXElementDelegate

- (void)elementWasDestroyed:(HAXElement *)element;
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @synchronized(self) {
            if (element != self->_haxApp) { return; }
            
            @autoreleasepool {
                self->_haxApp = nil;
                (void)self.haxApp;
            }
        }
    });
}

#pragma mark Dynamic accessors

@synthesize haxApp = _haxApp;

- (HAXApplication *)haxApp;
{
    @synchronized(self) {
        if (!_haxApp) {
            _haxApp = [HAXApplication applicationWithPID:self.pid];
            
            if (_haxApp) {
                _haxApp.delegate = self;
            }
        }
        if (!_haxApp && [[NNApplicationCache sharedCache] cachedApplicationWithPID:self.pid]) {
            [[NNApplicationCache sharedCache] removeApplicationWithPID:self.pid];
        }
        
        return _haxApp;
    }
}

#pragma mark NNApplication

- (BOOL)isCurrentApplication;
{
    return self.pid == [[NSProcessInfo processInfo] processIdentifier];
}

- (BOOL)isFrontMostApplication;
{
    return self.app.active;
}

- (void)raise;
{
    if (![self isFrontMostApplication]) {
        SetFrontProcessWithOptions(&_psn, kSetFrontProcessFrontWindowOnly);
    }
}

#pragma mark Private

- (HAXWindow *)haxWindowForWindow:(NNWindow *)window;
{
    __block HAXWindow *result = nil;
    
    NSRect windowRect = window.cgBounds;
    NSString *windowName = window.name;
    
    dispatch_sync(self.haxLock, ^{
        NSArray *haxWindows = [self.haxApp windows];
        for (HAXWindow *haxWindow in haxWindows) {
            if (RECTS_EQUAL(windowRect, haxWindow.frame)) {
                if (result) {
                    result = [windowName isEqualToString:haxWindow.title] ? haxWindow : result;
                } else {
                    result = haxWindow;
                }
            }
        }
    });

    return result;
}

@end
