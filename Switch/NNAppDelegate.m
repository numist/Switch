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
#import "NNHotKey.h"
#import "NNEventManager.h"
#import "NNPreferencesWindowController.h"


@interface NNAppDelegate ()

@property (nonatomic, strong) NNAXDisabledWindowController *disabledWindowController;
@property (nonatomic, strong) NNCoreWindowController *coreWindowController;
@property (nonatomic, strong) NNPreferencesWindowController *preferencesWindowController;
@property (nonatomic, strong) NSStatusItem *menu;
@property (nonatomic, assign) BOOL launched;

@end


@implementation NNAppDelegate

#pragma mark NSObject

- (void)dealloc;
{
    if (_launched) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NNAXAPIDisabledNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NNEventManagerKeyNotificationName object:[NNEventManager sharedManager]];
    }
}

#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    #pragma message "Keys (and default values) should be DRYed up a bit more."
    NSDictionary *userDefaultsValues = @{ @"firstLaunch" : @YES };
    [defaults registerDefaults:userDefaultsValues];

#   if DEBUG
    {
        BOOL resetDefaults = NO;
        
        if (resetDefaults) {
            [defaults removeObjectForKey:@"firstLaunch"];
        }
    }
#   endif
    
    self.coreWindowController = [[NNCoreWindowController alloc] initWithWindow:nil];
    
    #pragma message "Ultimately there should be one source of truth for setting (and changing!) hotkeys."
    [[NNEventManager sharedManager] registerHotKey:[NNHotKey hotKeyWithKeycode:kVK_ANSI_Comma modifiers:NNHotKeyModifierOption] forEvent:NNEventManagerEventTypeShowPreferences];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accessibilityAPIDisabled:) name:NNAXAPIDisabledNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hotKeyManagerEventNotification:) name:NNEventManagerKeyNotificationName object:[NNEventManager sharedManager]];

    if (![NNAPIEnabledWorker isAPIEnabled]) {
        [self requestAXAPITrust];
    }
    
    self.preferencesWindowController = [[NNPreferencesWindowController alloc] initWithWindowNibName:@"NNPreferencesWindowController"];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"firstLaunch"]) {
        [self.preferencesWindowController showWindow:self];
        [defaults setBool:NO forKey:@"firstLaunch"];
    }

    self.menu = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.menu.image = [[NSBundle mainBundle] imageForResource:@"weave"];
    self.menu.target = self;
    self.menu.action = @selector(showPreferences:);

    [defaults synchronize];
    self.launched = YES;
}

#pragma mark IBActions

- (IBAction)showPreferences:(id)sender {
    [self.preferencesWindowController showWindow:self];
}

#pragma mark Notifications

- (void)accessibilityAPIDisabled:(NSNotification *)note;
{
    [self requestAXAPITrust];
}

- (void)hotKeyManagerEventNotification:(NSNotification *)notification;
{
    NNEventManagerEventType eventType = [notification.userInfo[NNEventManagerEventTypeKey] unsignedIntegerValue];
    
    switch (eventType) {
        case NNEventManagerEventTypeShowPreferences:
            [self showPreferencesWindow];
            break;
            
        default:
            break;
    }
}

#pragma mark Internal

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

- (void)showPreferencesWindow;
{
    [self showPreferences:self];
    
    // HACK: There should be a better way to cancel the interface than committing identity fraud.
    [[NSNotificationCenter defaultCenter] postNotificationName:NNEventManagerKeyNotificationName object:[NNEventManager sharedManager] userInfo:@{NNEventManagerEventTypeKey : @(NNEventManagerEventTypeCancel)}];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [self.preferencesWindowController.window makeKeyAndOrderFront:self];
}

@end
