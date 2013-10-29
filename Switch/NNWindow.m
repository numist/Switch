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
#import <Haxcessibility/HAXElement+Protected.h>

#import "NNApplication+Private.h"
#import "NNWindowCache.h"


@interface NNWindow () <HAXElementDelegate>

@property (atomic, strong) NSImage *image;
@property (atomic, strong) NSDictionary *windowDescription;
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
        
        // #24: update window's info dict in case the frame or title changed
        result.windowDescription = description;

        return result;
    }
}

+ (BOOL)descriptionDescribesInterestingWindow:(NSDictionary *)description;
{
    return [[description objectForKey:(__bridge NSString *)kCGWindowLayer] longValue] == kCGNormalWindowLevel;
}

- (instancetype)initWithDescription:(NSDictionary *)description;
{
    if (!(self = [super init])) { return nil; }
    
    if (!description) {
        return nil;
    }

    _windowDescription = [description copy];
    _application = [NNApplication applicationWithPID:[[self.windowDescription objectForKey:(NSString *)kCGWindowOwnerPID] intValue] name:[self.windowDescription objectForKey:(NSString *)kCGWindowOwnerName]];

    
    if (!_application) {
        return nil;
    }
    
    // Load the HAXWindow ASAP, but without blocking.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        (void)self.haxWindow;
    });
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(haxApplicationWasDestroyed:) name:NNHAXApplicationWasInvalidatedNotification object:_application];
    
    NNLog(@"Created window %@ belonging to application %@", self, _application);
    
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

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NNHAXApplicationWasInvalidatedNotification object:self.application];
}

#pragma mark HAXElementDelegate

- (void)elementWasDestroyed:(HAXElement *)element;
{
    NNLog(@"HAX element for window %@ was destroyed", self);

    if (element == self->_haxWindow) {
        [self handleElementDestruction];
    }
}

#pragma mark Notifications

- (void)haxApplicationWasDestroyed:(NSNotification *)notification;
{
    NNLog(@"HAX element for window %@ destroyed (parent desroyed)", self);

    if (notification.object == self.application && self->_haxWindow) {
        [self handleElementDestruction];
    }
}

#pragma mark Dynamic accessors

@synthesize haxWindow = _haxWindow;

- (HAXWindow *)haxWindow;
{
    @synchronized(self) {
        if (!_haxWindow) {
            _haxWindow = [self.application haxWindowForWindow:self];
            _haxWindow.delegate = self;
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
    CGRect result = {{},{}};
    bool success = CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)[self.windowDescription objectForKey:(NSString *)kCGWindowBounds], &result);
    BailUnless(success, ((NSRect){{},{}}));
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

#pragma mark NNWindow

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
    NSDate *start = [NSDate date];

    // First, raise the window
    NSError *error;
    if (![self.haxWindow performAction:(__bridge NSString *)kAXRaiseAction error:&error]) {
        NNLog(@"Raising %@ window %@ failed after %.3fs: %@", self.application.name, self, [[NSDate date] timeIntervalSinceDate:start], error);
        return NO;
    }
    
    // Then raise the application (if it's not already topmost)
    [self.application raise];
    
    NNLog(@"Raising %@ window %@ took %.3fs", self.application.name, self, [[NSDate date] timeIntervalSinceDate:start]);
    return YES;
}

- (BOOL)close;
{
    NSDate *start = [NSDate date];

    NSError *error;
    HAXElement *element = [self.haxWindow elementOfClass:[HAXElement class] forKey:(__bridge NSString *)kAXCloseButtonAttribute error:NULL];
	BOOL result = [element performAction:(__bridge NSString *)kAXPressAction error:&error];
    
    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:start];
    if (result) {
        NNLog(@"Closing %@ window %@ took %.3fs", self.application.name, self, elapsed);
    } else {
        NNLog(@"Closing %@ window %@ failed after %.3fs: %@", self.application.name, self, elapsed, error);
    }
    
    return result;
}

#pragma mark Private

- (void)handleElementDestruction;
{
    @synchronized(self) {
        self->_haxWindow = nil;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        @synchronized(self) {
            (void)self.haxWindow;
        }
    });
}

- (CGImageRef)cgWindowImage;
{
    CGImageRef result = NNCFAutorelease(CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow, self.windowID, kCGWindowImageBoundsIgnoreFraming));
    
    BailUnless(result, NULL);
    
    if (CGImageGetHeight(result) < 1.0 || CGImageGetWidth(result) < 1.0) {
        return NULL;
    }
    
    return result;
}

@end
