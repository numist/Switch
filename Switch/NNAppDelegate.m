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

#import "NNAXAPIService.h"
#import "NNCoreWindowController.h"
#import "NNEventManager.h"
#import "NNLoggingService.h"
#import "NNPreferencesService.h"
#import "NNStatusBarMenuService.h"
#import "NSNotificationCenter+RACSupport.h"


@implementation NNAppDelegate

#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NNServiceManager sharedManager] registerService:[NNLoggingService self]];
    [[NNServiceManager sharedManager] registerService:[NNPreferencesService self]];
    [[NNServiceManager sharedManager] registerService:[NNCoreWindowController self]];
    [[NNServiceManager sharedManager] registerService:[NNStatusBarMenuService self]];
    [[NNServiceManager sharedManager] registerService:[NNAXAPIService self]];

    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:NNEventManagerKeyNotificationName object:[NNEventManager sharedManager]]
        subscribeNext:^(NSNotification *x) {
            if ([x.userInfo[NNEventManagerEventTypeKey] unsignedIntegerValue] == NNEventManagerEventTypeShowPreferences) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showPreferencesWindow];
                });
            }
        }];
}

#pragma mark IBActions

- (IBAction)showPreferences:(id)sender {
    [[NNPreferencesService sharedService] showPreferencesWindow:sender];
}

#pragma mark Internal

- (void)showPreferencesWindow;
{
    // HACK: There should be a better way to cancel the interface than committing identity fraud.
    [[NSNotificationCenter defaultCenter] postNotificationName:NNEventManagerKeyNotificationName object:[NNEventManager sharedManager] userInfo:@{NNEventManagerEventTypeKey : @(NNEventManagerEventTypeCancel)}];
    
    [self showPreferences:self];
}

@end
