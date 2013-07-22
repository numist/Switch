//
//  NNPollingObject.m
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

#import "NNPollingObject.h"

#import <ReactiveCocoa/EXTScope.h>


static const NSTimeInterval NNPollingIntervalFastest = 1.0 / 60.0;


@interface NNPollingObject ()

@property (nonatomic, strong, readonly) dispatch_queue_t queue;

@end


@implementation NNPollingObject

+ (NSString *)notificationName;
{
    return [NSString stringWithFormat:@"%@%@", NSStringFromClass(self), @"PollCompleteNotification"];
}

- (instancetype)initWithQueue:(dispatch_queue_t)queue;
{
    self = [super init];
    if (!self) return nil;
    
    _queue = queue;
    
    dispatch_async(_queue, ^{
        [self workerLoop];
    });
    
    return self;
}

- (void)workerLoop;
{
    NSDate *start = [NSDate date];

    [self main];
    
    // TODO(numist): this should emit a log or provide a status bit or something?
    if (self.interval <= 0.0) { return; }
    
    @weakify(self);
    double delayInSeconds = MAX(self.interval - [[NSDate date] timeIntervalSinceDate:start], NNPollingIntervalFastest);
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, self.queue, ^(void){
        @strongify(self);
        [self workerLoop];
    });
}

- (void)postNotification:(NSDictionary *)userInfo;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:[[self class] notificationName] object:self userInfo:userInfo];
    });
}

- (void)main;
{
    @throw [NSException exceptionWithName:@"NNPollingObjectException" reason:@"Method must be overridden by subclass!" userInfo:@{ @"_cmd" : NSStringFromSelector(_cmd), @"class" : NSStringFromClass([self class]) }];
}

@end
