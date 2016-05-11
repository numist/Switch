//
//  SWWindowListWorker.m
//  Switch
//
//  Created by Scott Perry on 02/22/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWWindowListWorker.h"

#import <NNKit/NNPollingObject+Protected.h>


static NSTimeInterval refreshInterval = 0.1;


@interface SWWindowListWorker ()

@property (nonatomic, copy, readwrite) NSArray *windowInfoList;
@property (nonatomic, strong) dispatch_queue_t private_queue;

@end


@implementation SWWindowListWorker

#pragma mark - Initialization

- (instancetype)init;
{
    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    if (!(self = [super initWithQueue:q])) { return nil; }
    
    self.private_queue = q;
    self.interval = refreshInterval;

    return self;
}

#pragma mark - NNPollingObject

- (oneway void)main;
{
    [self private_refreshWindowList];
}

#pragma mark - SWWindowListWorker

- (void)refreshWindowListAndWait;
{
    dispatch_sync(self.private_queue, ^{
        [self private_refreshWindowList];
    });
}

- (void)private_refreshWindowList;
{
    SWLogBackgroundThreadOnly();
    
    SWTimeTask(SWCodeBlock({
        CFArrayRef cgWindowInfoList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements,  kCGNullWindowID);
        NSArray *windowInfoList = CFBridgingRelease(cgWindowInfoList);
        if (![self.windowInfoList isEqualToArray:windowInfoList]) {
            self.windowInfoList = windowInfoList;
            [self postNotification:@{@"windows" : self.windowInfoList}];
        }
    }), @"Copying window info list");
}

@end
