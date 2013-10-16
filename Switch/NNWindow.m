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
    BOOL windowIsShared = [[description objectForKey:(__bridge NSString *)kCGWindowSharingState] longValue] != kCGWindowSharingNone;
    BOOL windowIsNormalLevel = [[description objectForKey:(__bridge NSString *)kCGWindowLayer] longValue]== kCGNormalWindowLevel;
    
#   if DEBUG
    {
        NSString *applicationName = [description objectForKey:(__bridge NSString *)kCGWindowOwnerName];
        static NSArray *knownOffenders = nil;
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            knownOffenders = @[@"Notification Center"];
        });
        
        // It would be interesting to know what other applications' windows have sharing disabled.
        if (!windowIsShared && ![knownOffenders containsObject:applicationName]) {
            DebugBreak();
        }
    }
#   endif
    
    return windowIsShared && windowIsNormalLevel;
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
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @synchronized(self) {
            BailUnless(element == self->_haxWindow, );
            
            @autoreleasepool {
                self->_haxWindow = nil;
                (void)self.haxWindow;
            }
        }
    });
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
    if (![self.haxWindow raise] ) { return NO; }
    
    // Then raise the application (if it's not already topmost)
    [self.application raise];
    
    Log(@"Raising window %@ took %0.5fs", self, [[NSDate date] timeIntervalSinceDate:start]);

    return YES;
}

- (BOOL)close;
{
    NSDate *start = [NSDate date];

    BOOL result = [self.haxWindow close];
    
    Log(@"Closing window %@ took %0.5fs", self, [[NSDate date] timeIntervalSinceDate:start]);
    
    return result;
}

#pragma mark Private

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
