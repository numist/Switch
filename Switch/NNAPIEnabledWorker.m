//
//  NNAPIEnabledWorker.m
//  Switch
//
//  Created by Scott Perry on 07/10/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
#import "NNAPIEnabledWorker.h"

#import <dlfcn.h>

#import "NNPollingObject+Protected.h"


@interface NNAPIEnabledWorker ()

@property (nonatomic, assign, readwrite) BOOL APIEnabled;

@end


@implementation NNAPIEnabledWorker

+ (BOOL)isAPIEnabled;
{
    // TODO(numist): Remove when it's time to deprecate Mountain Lion.
    static Boolean (*isProcessTrustedWithOptions)(CFDictionaryRef options);
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void* handle = dlopen(0,RTLD_NOW|RTLD_GLOBAL);
        assert(handle);
        isProcessTrustedWithOptions = dlsym(handle, "AXIsProcessTrustedWithOptions");
        dlclose(handle);
        handle = NULL;
    });
    
    Boolean result;
    
    if (isProcessTrustedWithOptions) {
        result = isProcessTrustedWithOptions(NULL);
    } else {
        result = AXAPIEnabled();
    }
    
    return (BOOL)result;
}

- (instancetype)init;
{
    if (!(self = [super initWithQueue:dispatch_get_global_queue(0, 0)])) { return nil; }
    
    _APIEnabled = [[self class] isAPIEnabled];
    self.interval = 0.25;
    
    return self;
}

- (void)main;
{
    BOOL enabled = [[self class] isAPIEnabled];
    if (enabled != self.APIEnabled) {
        self.APIEnabled = enabled;
        [self postNotification:@{ @"AXAPIEnabled" : @(enabled) }];
    }
}

@end
