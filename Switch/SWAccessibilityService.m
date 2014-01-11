//
//  SWAccessibilityService.m
//  Switch
//
//  Created by Scott Perry on 10/20/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWAccessibilityService.h"

#import "NNAPIEnabledWorker.h"


@interface SWAccessibilityService ()

@property (nonatomic, strong) NNAPIEnabledWorker *worker;
@property (nonatomic, strong, readonly) dispatch_queue_t haxQueue;

@end


@implementation SWAccessibilityService

- (instancetype)init;
{
    if (!(self = [super init])) { return nil; }
    
    _haxQueue = dispatch_queue_create("foo", DISPATCH_QUEUE_SERIAL);
    
    return self;
}

- (NNServiceType)serviceType;
{
    return NNServiceTypePersistent;
}

- (void)startService;
{
    [super startService];

    [self checkAPI];
}

- (void)accessibilityAPIAvailabilityChangedNotification:(NSNotification *)notification;
{
    BOOL accessibilityEnabled = [notification.userInfo[NNAXAPIEnabledKey] boolValue];
    
    SWLog(@"Accessibility API is %@abled", accessibilityEnabled ? @"en" : @"dis");
    
    if (accessibilityEnabled) {
        self.worker = nil;
    }
}

- (void)setWorker:(NNAPIEnabledWorker *)worker;
{
    if (worker == _worker) {
        return;
    }
    if (_worker) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NNAPIEnabledWorker.notificationName object:_worker];
    }
    if (worker) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accessibilityAPIAvailabilityChangedNotification:) name:NNAPIEnabledWorker.notificationName object:self.worker];
    }
    _worker = worker;
}

- (void)checkAPI;
{
    if (![NNAPIEnabledWorker isAPIEnabled]) {
        self.worker = [NNAPIEnabledWorker new];
        
        AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)@{ (__bridge NSString *)kAXTrustedCheckOptionPrompt : @YES });
    }
}

- (void)raiseWindow:(SWWindow *)window;
{
    dispatch_async(self.haxQueue, ^{
        
    });
}

- (void)closeWindow:(SWWindow *)window;
{
    dispatch_async(self.haxQueue, ^{
        
    });
}

/**
 
 want:
    application cache
    window cache
    application invalidation -> window invalidation
    window list -> hax objects
        dependecy on list, but don't want to start/stop based on list!
 */

@end
