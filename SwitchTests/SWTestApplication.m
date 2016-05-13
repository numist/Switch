//
//  SWTestApplication.m
//  Switch
//
//  Created by Scott Perry on 09/29/14.
//  Copyright © 2014 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWTestApplication.h"


@interface SWTestApplication ()

@property (nonatomic, assign, readwrite) pid_t pid;
@property (nonatomic, copy, readwrite) NSImage *icon;
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, assign, readwrite, getter=isLiveApplication) BOOL liveApplication;
@property (nonatomic, assign, readwrite) BOOL canBeActivated;

@end


@implementation SWTestApplication

@synthesize pid = _pid;
@synthesize icon = _icon;
@synthesize name = _name;
@synthesize liveApplication = _liveApplication;
@synthesize canBeActivated = _canBeActivated;

- (instancetype)initWithPID:(pid_t)pid name:(NSString *)name;
{
    if (!(self = [super init])) { return nil; }

    self->_pid = pid;
    self->_name = name;
    self->_active = [name isEqualToString:@"Switch"];
    self->_liveApplication = YES;
    self->_canBeActivated = ^{
        NSArray *applicationNamesThatCannotBeActivated = @[
            @"com.apple.security.pboxd",
            @"com.apple.appkit.xpc.openAndSav",
        ];
        return ![applicationNamesThatCannotBeActivated containsObject:self.name];
    }();

    return self;
}

- (NSRunningApplication *)runningApplication;
{
    __builtin_trap();
}

@end
