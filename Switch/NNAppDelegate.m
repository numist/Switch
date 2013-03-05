//
//  NNAppDelegate.m
//  Switch
//
//  Created by Scott Perry on 02/24/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNAppDelegate.h"

#import "NNSwitcher.h"


@interface NNAppDelegate ()

@property (nonatomic, strong) NNSwitcher *switcher;

@end


@implementation NNAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application

    [self invokeSwitcher];
    
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self incrementKeyDown];
    });
}

#pragma mark Internal

- (void)invokeSwitcher;
{
    self.switcher = [NNSwitcher new];
}

- (void)dismissSwitcher;
{
    self.switcher = nil;
}

- (void)incrementKeyDown;
{
    // TODO: key repeat support
    self.switcher.index += 1;
    
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self incrementKeyDown];
    });
}

- (void)incrementKeyUp;
{
    // TODO: key repeat support
    NSLog(@"Stop incrementing");
}

- (void)decrementKeyDown;
{
    // TODO: key repeat support
    self.switcher.index -= 1;
}

- (void)decrementKeyUp;
{
    // TODO: key repeat support
    NSLog(@"Stop decrementing");
}

// TODO: support for closing windows, quitting apps, mouse events?

@end
