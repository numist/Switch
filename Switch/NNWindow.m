//
//  NNWindow.m
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

#import "NNWindow+Private.h"

#import <Haxcessibility/Haxcessibility.h>

#import "NNApplication+Private.h"
#import "NNWindowCache.h"


@interface NNWindow () <HAXElementDelegate>

@property (atomic, strong) NSImage *image;
@property (nonatomic, strong, readonly) NSDictionary *windowDescription;
@property (atomic, readonly) HAXWindow *haxWindow;

@end


@implementation NNWindow

+ (instancetype)windowWithDescription:(NSDictionary *)description;
{
    if (![self descriptionDescribesInterestingWindow:description]) {
        return nil;
    }
    
    @synchronized(self) {
        CGWindowID windowID = (CGWindowID)[[description objectForKey:(__bridge NSString *)kCGWindowNumber] unsignedLongValue];
        NNWindow *result = [[NNWindowCache sharedCache] cachedWindowWithID:windowID];
        
        if (!result) {
            result = [[self alloc] initWithDescription:description];
            
            if (result) {
                [[NNWindowCache sharedCache] cacheWindow:result withID:windowID];
            }
        }

        return result;
    }
}

+ (BOOL)descriptionDescribesInterestingWindow:(NSDictionary *)description;
{
    // Only match windows at kCGNormalWindowLevel
    if ([[description objectForKey:(__bridge NSString *)kCGWindowLayer] longValue] != kCGNormalWindowLevel) {
        return NO;
    }

    // For now, windows whose contents are not accessible are not supported.
    BailUnless([[description objectForKey:(__bridge NSString *)kCGWindowSharingState] longValue] != kCGWindowSharingNone, NO);
    
    return YES;
}

- (instancetype)initWithDescription:(NSDictionary *)description;
{
    self = [super init];
    if (!self) return nil;
    
    if (!description) {
        return nil;
    }

    _windowDescription = [description copy];
    _application = [NNApplication applicationWithPID:[[self.windowDescription objectForKey:(NSString *)kCGWindowOwnerPID] intValue]];

    
    if (!_application) {
        return nil;
    }
    
    // Load the HAXWindow ASAP, but without blocking.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        (void)self.haxWindow;
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
    return self.windowID;
}

- (BOOL)isEqual:(id)object;
{
    Check(object);
    return ([object isKindOfClass:[self class]] && [self hash] == [object hash]);
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%p <%u (%@)>", self, self.windowID, self.name];
}

#pragma mark HAXElementDelegate

- (void)elementWasDestroyed:(HAXElement *)element;
{
    @synchronized(self) {
        BailUnless(element == _haxWindow, );
        
        @autoreleasepool {
            _haxWindow = nil;
            (void)self.haxWindow;
        }
    }
}

#pragma mark Dynamic accessors

@synthesize haxWindow = _haxWindow;

- (HAXWindow *)haxWindow;
{
    @synchronized(self) {
        if (!_haxWindow) {
            _haxWindow = [self.application haxWindowForWindow:self];
            
            if (_haxWindow) {
                _haxWindow.delegate = self;
            }
        }
        if (!_haxWindow && [[NNWindowCache sharedCache] cachedWindowWithID:self.windowID]) {
            [[NNWindowCache sharedCache] removeWindowWithID:self.windowID];
        }

        return _haxWindow;
    }
}

@dynamic cgBounds;
- (NSRect)cgBounds;
{
    CGRect result = {0};
    bool success = CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)[self.windowDescription objectForKey:(NSString *)kCGWindowBounds], &result);
    BailUnless(success, (NSRect){0});
    return result;
}

@synthesize name = _name;
- (NSString *)name;
{
    if (!_name) {
        _name = [self.windowDescription objectForKey:(__bridge NSString *)kCGWindowName];
    }
    return _name;
}

- (CGWindowID)windowID;
{
    return (CGWindowID)[[self.windowDescription objectForKey:(__bridge NSString *)kCGWindowNumber] unsignedLongValue];
}

- (BOOL)exists;
{
    CFArrayRef cgList = CGWindowListCreate(kCGWindowListOptionIncludingWindow, self.windowID);
    
    if (![CFBridgingRelease(cgList) count]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)raise;
{
    // First, raise the window
    if (![self.haxWindow raise] ) { return NO; }
    
    // Then raise the application (if it's not already topmost)
    [self.application raise];
    return YES;
}

- (BOOL)close;
{
    return [self.haxWindow close];
}

#pragma mark Private

- (CGImageRef)copyCGWindowImage;
{
    CGImageRef result = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow, self.windowID, kCGWindowImageBoundsIgnoreFraming);
    
    BailUnless(result, NULL);
    
    if (CGImageGetHeight(result) < 1.0 || CGImageGetWidth(result) < 1.0) {
        CFRelease(result);
        return NULL;
    }
    
    return result;
}

@end
