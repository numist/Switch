//
//  NNWindow.m
//  Docking
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

#import "NNApplication.h"


@interface NNWindow ()

@property (atomic, strong) NSImage *image;
@property (nonatomic, strong, readonly) NSDictionary *windowDescription;

@end


@implementation NNWindow

- (instancetype)initWithDescription:(NSDictionary *)description;
{
    self = [super init];
    if (!self) return nil;
    
    if (!description) {
        return nil;
    }

    self = [self initInternalWithDescription:description];
    
    if (!_application || ![self isValidWindow]) {
        return nil;
    }
    
    return self;
}

- (instancetype)initInternalWithDescription:(NSDictionary *)description;
{
    self = [super init];
    if (!self) return nil;
    
    _windowDescription = [description copy];
    _application = [[NNApplication alloc] initWithPID:[[self.windowDescription objectForKey:(NSString *)kCGWindowOwnerPID] intValue]];
    
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone;
{
    NNWindow *copy = [[NNWindow alloc] initInternalWithDescription:self.windowDescription];
    [copy setImage:self.image];
    return copy;
}

- (NSUInteger)hash;
{
    return self.windowID;
}

- (BOOL)isEqual:(id)object;
{
    return ([object isKindOfClass:[self class]] && [self hash] == [object hash]);
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%u (%@)", self.windowID, self.name];
}

#pragma mark NNWindow

/* Broken:
 * Doesn't see GitHub
 * Doesn't see the entirety of TweetBot (like the New Tweets ribbon because some of the elements are technically both separate windows and desktop elements as reported by CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements,  kCGNullWindowID);)
 */
- (BOOL)isValidWindow;
{
    // Real windows have names. Can't care about the others
    if (!self.name || [self.name length] == 0) {
        return NO;
    }
    
    // Catches WindowServer and maybe other daemons.
    if (!self.application.name || [self.application.name length] == 0) {
        return NO;
    }
    
    // Don't report own windows. Maybe later if there are ever preferences? For now, KISS
    if (self.application.pid == [[NSProcessInfo processInfo] processIdentifier]) {
        return NO;
    }
    
    // Last ditch catch-all
    static NSSet *disallowedApps;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        disallowedApps = [NSSet setWithArray:@[
                          @"SystemUIServer",
                          @"NotificationCenter", @"Notification Center",
                          @"Dock",
                          @"WindowServer"
                          ]];
    });
    if ([disallowedApps containsObject:self.application.name]) {
        return NO;
    }
    
    return YES;
}

#pragma mark Dynamic accessors
@dynamic name;

- (CGWindowID)windowID;
{
    return (CGWindowID)[[self.windowDescription objectForKey:(NSString *)kCGWindowNumber] unsignedLongValue];
}

- (BOOL)exists;
{
    CFArrayRef cgList = CGWindowListCreate(kCGWindowListOptionIncludingWindow, self.windowID);
    
    if (![CFBridgingRelease(cgList) count]) {
        return NO;
    }
    
    return YES;
}

- (NSString *)name;
{
    return [self.windowDescription objectForKey:(NSString *)kCGWindowName];
}

#pragma mark Private

- (CGImageRef)copyCGWindowImage;
{
    CGImageRef result = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow, self.windowID, kCGWindowImageBoundsIgnoreFraming);
    
    if (CGImageGetHeight(result) < 1.0 || CGImageGetWidth(result) < 1.0) {
        CFRelease(result);
        return NULL;
    }
    
    return result;
}

@end