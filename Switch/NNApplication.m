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

#import "NNWindow+Private.h"


@interface NNApplication () <HAXElementDelegate>

@property (nonatomic, readonly, assign) pid_t pid;
@property (atomic, retain) NSRunningApplication *app;

@end


@implementation NNApplication

+ (instancetype)applicationWithPID:(pid_t)pid;
{
    return [[self alloc] initWithPID:pid];
}

- (instancetype)initWithPID:(pid_t)pid;
{
    if (!(self = [super init])) { return nil; }
    
    _pid = pid;
    _app = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];

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

- (NSString *)name;
{
    return [self.app localizedName];
}

- (NSImage *)icon;
{
    NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:[self.app bundleIdentifier]];
    return [[NSWorkspace sharedWorkspace] iconForFile:path];
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

- (BOOL)canBeActivated;
{
    NSApplicationActivationPolicy activationPolicy = self.app.activationPolicy;
    return activationPolicy == NSApplicationActivationPolicyRegular || activationPolicy == NSApplicationActivationPolicyAccessory;
}

@end
