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

#import <dlfcn.h>

#import "NNAPIEnabledWorker.h"
#import "NNAXDisabledWindowController.h"
#import "NNCoreWindowController.h"
#import "NNPreferencesWindowController.h"


@interface NNAppDelegate ()

@property (nonatomic, strong) NNAXDisabledWindowController *disabledWindowController;
@property (nonatomic, strong) NNCoreWindowController *coreWindowController;
@property (nonatomic, strong) NNPreferencesWindowController *preferencesWindowController;

@end


@implementation NNAppDelegate

#pragma mark NSObject

- (void)dealloc;
{
    #pragma message "Add a check in case applicationDidFinishLaunching was never called"
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NNAXAPIDisabledNotification object:nil];
}

#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.coreWindowController = [[NNCoreWindowController alloc] initWithWindow:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accessibilityAPIDisabled:) name:NNAXAPIDisabledNotification object:nil];

    if (![NNAPIEnabledWorker isAPIEnabled]) {
        [self requestAXAPITrust];
    }
    
    self.preferencesWindowController = [[NNPreferencesWindowController alloc] initWithWindowNibName:@"NNPreferencesWindowController"];
    [self.preferencesWindowController showWindow:self];
}

#pragma mark IBActions

- (IBAction)showPreferences:(NSMenuItem *)sender {
        DebugBreak();
}

#pragma mark Notifications

- (void)accessibilityAPIDisabled:(NSNotification *)note;
{
    [self requestAXAPITrust];
}

#pragma mark NNAppDelegate

- (void)requestAXAPITrust;
{
    #pragma message "Remove when it's time to deprecate Mountain Lion."
    static Boolean (*isProcessTrustedWithOptions)(CFDictionaryRef options);
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void* handle = dlopen(0,RTLD_NOW|RTLD_GLOBAL);
        assert(handle);
        isProcessTrustedWithOptions = dlsym(handle, "AXIsProcessTrustedWithOptions");
        dlclose(handle);
        handle = NULL;
    });
    
    if (isProcessTrustedWithOptions) {
        #pragma message "That string literal should be changed to the appropriate symbol when 10.9 has shipped."
        isProcessTrustedWithOptions((__bridge CFDictionaryRef)@{ @"AXTrustedCheckOptionPrompt" : @YES });
    } else {
        static dispatch_once_t twiceToken;
        dispatch_once(&twiceToken, ^{
            self.disabledWindowController = [[NNAXDisabledWindowController alloc] initWithWindowNibName:@"NNAXDisabledWindowController"];
        });
        
        [self.disabledWindowController showWindow:self];
    }
}

@end
