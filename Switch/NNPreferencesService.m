//
//  NNPreferencesService.m
//  Switch
//
//  Created by Scott Perry on 10/20/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNPreferencesService.h"

#import "NNEventManager.h"
#import "NNHotKey.h"
#import "NNPreferencesWindowController.h"


@interface NNPreferencesService ()

@property (nonatomic, strong) NNPreferencesWindowController *preferencesWindowController;

@end


@implementation NNPreferencesService

- (NNServiceType)serviceType;
{
    return NNServiceTypePersistent;
}

- (void)startService;
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
    
    NNEventManager *keyManager = [NNEventManager sharedManager];
    [keyManager registerHotKey:[NNHotKey hotKeyWithKeycode:kVK_Tab modifiers:NNHotKeyModifierOption] forEvent:NNEventManagerEventTypeInvoke];
    [keyManager registerHotKey:[NNHotKey hotKeyWithKeycode:kVK_Tab modifiers:(NNHotKeyModifierOption | NNHotKeyModifierShift)] forEvent:NNEventManagerEventTypeDecrement];
    [keyManager registerHotKey:[NNHotKey hotKeyWithKeycode:kVK_ANSI_W modifiers:NNHotKeyModifierOption] forEvent:NNEventManagerEventTypeCloseWindow];
    [keyManager registerHotKey:[NNHotKey hotKeyWithKeycode:kVK_Escape modifiers:NNHotKeyModifierOption] forEvent:NNEventManagerEventTypeCancel];
    [keyManager registerHotKey:[NNHotKey hotKeyWithKeycode:kVK_ANSI_Comma modifiers:NNHotKeyModifierOption] forEvent:NNEventManagerEventTypeShowPreferences];
    
    self.preferencesWindowController = [[NNPreferencesWindowController alloc] initWithWindowNibName:@"NNPreferencesWindowController"];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"firstLaunch"]) {
        [self.preferencesWindowController showWindow:self];
        [defaults setBool:NO forKey:@"firstLaunch"];
    }

    [defaults synchronize];
}

- (void)showPreferencesWindow:(id)sender;
{
    [self.preferencesWindowController showWindow:sender];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [self.preferencesWindowController.window makeKeyAndOrderFront:sender];
}

@end
