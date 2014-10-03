//
//  SWApplication.m
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

#import "SWApplication.h"

#import <Haxcessibility/Haxcessibility.h>

#import "SWWindow.h"


@interface SWApplication ()

@property (nonatomic, strong, readonly) NSRunningApplication *runningApplication;

@end


@implementation SWApplication

#pragma mark - Initialization

+ (instancetype)applicationWithPID:(pid_t)pid name:(NSString *)name;
{
    Class factory = self;
    if (NSClassFromString(@"SWTestApplication")) {
        factory = NSClassFromString(@"SWTestApplication");
    }
    return [[factory alloc] initWithPID:pid name:name];
}

- (instancetype)initWithPID:(pid_t)pid name:(NSString *)name;
{
    if (!(self = [super init])) { return nil; }
    
    _pid = pid;
    _runningApplication = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
    _name = name ?: [_runningApplication localizedName];

    return self;
}

#pragma mark - NSObject

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

#pragma mark - SWApplication

- (NSImage *)icon;
{
    NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:[self.runningApplication bundleIdentifier]];
    return [[NSWorkspace sharedWorkspace] iconForFile:path];
}

- (BOOL)isActiveApplication;
{
    return self.runningApplication.active;
}

- (BOOL)isCurrentApplication;
{
    return self.pid == [[NSProcessInfo processInfo] processIdentifier];
}

- (BOOL)canBeActivated;
{
    NSApplicationActivationPolicy activationPolicy = self.runningApplication.activationPolicy;
    return activationPolicy == NSApplicationActivationPolicyRegular || activationPolicy == NSApplicationActivationPolicyAccessory;
}

@end
