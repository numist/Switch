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
#import <ReactiveCocoa/EXTScope.h>


static NSTimeInterval refreshInterval = 0.1;


@interface SWWindowListWorker ()

@property (nonatomic, copy, readwrite) NSArray *windowInfoList;

@end


@implementation SWWindowListWorker

- (instancetype)init;
{
    if (!(self = [super initWithQueue:dispatch_get_global_queue(0, 0)])) { return nil; }
    
    self.interval = refreshInterval;

    return self;
}

#pragma mark Internal

- (oneway void)main;
{
    CFArrayRef cgWindowInfoList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements,  kCGNullWindowID);
    NSArray *windowInfoList = CFBridgingRelease(cgWindowInfoList);
    if (![self.windowInfoList isEqualToArray:windowInfoList]) {
        self.windowInfoList = windowInfoList;
        [self postNotification:@{@"windows" : self.windowInfoList}];
    }
}

@end
