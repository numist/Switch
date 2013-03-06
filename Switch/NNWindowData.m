//
//  NNWindowData.m
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

#import "NNWindowData+Private.h"

#import "NNApplication.h"


@interface NNWindowData ()

@property (atomic, strong) NSImage *image;
@property (nonatomic, strong, readonly) NSDictionary *windowDescription;

@end


@implementation NNWindowData

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
    _exists = YES;
    
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone;
{
    return [[NNWindowData alloc] initInternalWithDescription:self.windowDescription];
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

#pragma mark NNWindowData

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
@dynamic windowID;

- (CGWindowID)windowID;
{
    return (CGWindowID)[[self.windowDescription objectForKey:(NSString *)kCGWindowNumber] unsignedLongValue];
}

@synthesize exists = _exists;

- (BOOL)exists;
{
    // If the window ceased to exist, don't rediscover it if the window ID gets reused.
    if (!_exists) {
        return NO;
    }
    
    CFArrayRef cgList = CGWindowListCreate(kCGWindowListOptionIncludingWindow, self.windowID);
    NSArray *list = CFBridgingRelease(cgList);
    
    if (!list || ![list count]) {
        if (!list) {
            NSLog(@"Is there no window server? How did we even get here?!");
        }
        _exists = NO;
    }
    
    return _exists;
}

- (NSString *)name;
{
    return [self.windowDescription objectForKey:(NSString *)kCGWindowName];
}

#pragma mark Private

- (CGImageRef)createCGWindowImage;
{
    CGImageRef result = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow, self.windowID, kCGWindowImageBoundsIgnoreFraming);
    
    if (CGImageGetHeight(result) < 1.0 || CGImageGetWidth(result) < 1.0) {
        CFRelease(result);
        return NULL;
    }
    
    return result;
}

@end
