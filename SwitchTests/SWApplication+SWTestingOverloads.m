//
//  SWApplication+SWTestingOverloads.m
//  Switch
//
//  Created by Scott Perry on 01/06/14.
//  Copyright © 2014 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWApplication.h"


@interface SWApplication (SWTestingOverloads)

@end


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

@implementation SWApplication (SWTestingOverloads)

- (BOOL)isCurrentApplication;
{
    return [self.name isEqualToString:@"Switch"];
}

- (BOOL)isFrontMostApplication;
{
    // For now, at least.
    return NO;
}

- (BOOL)canBeActivated;
{
    static NSSet *applicationNamesThatCannotBeActivated;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        applicationNamesThatCannotBeActivated = [NSSet setWithArray:@[
            @"com.apple.security.pboxd",
            @"com.apple.appkit.xpc.openAndSav",
        ]];
    });
    
    return ![applicationNamesThatCannotBeActivated containsObject:self.name];
}

@end

#pragma clang diagnostic pop
