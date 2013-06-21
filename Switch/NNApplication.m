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
#import "NNAXLifetimeTracker.h"
#import "NNApplicationCache.h"
#import "NNWindow+Private.h"


@interface NNApplication ()

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
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
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
    return self.pid;
}

- (BOOL)isEqual:(id)object;
{
    Check(object);
    return ([object isKindOfClass:[self class]] && [self hash] == [object hash]);
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%d (%@)", self.pid, self.name];
}

- (void)dealloc;
{
    if (_haxApp) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kNNAXLifetimeEndedNotification object:_haxApp];
    }
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
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSBundle bundleWithPath:[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:[self.app bundleIdentifier]]];
    });
    
    return _icon;
}

#pragma mark Notifications

- (void)axLifetimeEndedNotification:(NSNotification *)note;
{
    __weak __typeof__(self) weakSelf;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        __strong __typeof__(self) self = weakSelf;
        if (!self) { return; }
        
        @synchronized(self) {
            BailUnless(note.object == _haxApp, );
            
            Log(@"Invalidated HAXWindow for %@", self);
            
            [[NSNotificationCenter defaultCenter] removeObserver:self name:note.name object:note.object];
            _haxApp = nil;
            
            (void)self.haxApp;
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
        }
        if (_haxApp) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(axLifetimeEndedNotification:) name:kNNAXLifetimeEndedNotification object:_haxApp];
            [[NNAXLifetimeTracker sharedTracker] trackLifetimeOfHAXElement:_haxApp];
        } else {
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

    Check(result);
    
    return result;
}

@end
