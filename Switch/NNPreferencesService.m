//
//  NNPreferencesService.m
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

#import "NNPreferencesService.h"

#import <NNKit/NNService+Protected.h>

#import "NNEventManager.h"
#import "NNHotKey.h"
#import "NNPreferencesWindowController.h"


static NSString *kNNFirstLaunchKey = @"firstLaunch";


@interface NNPreferencesService ()

@property (nonatomic, strong) NNPreferencesWindowController *preferencesWindowController;

@end


@implementation NNPreferencesService

#pragma mark - NNService

- (NNServiceType)serviceType;
{
    return NNServiceTypePersistent;
}

- (Protocol *)subscriberProtocol;
{
    return @protocol(NNPreferencesServiceDelegate);
}

- (void)startService;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:self._defaultValues];
    
#   if DEBUG
    {
        BOOL resetDefaults = NO;
        
        if (resetDefaults) {
            for (NSString *key in self._defaultValues.allKeys) {
                [defaults removeObjectForKey:key];
            }
        }
    }
#   endif
    
    // TODO: When these become customizable, they will become fields in the app's preferences.
    NNEventManager *keyManager = [NNEventManager sharedManager];
    [keyManager registerHotKey:[NNHotKey hotKeyWithKeycode:kVK_Tab modifiers:NNHotKeyModifierOption] forEvent:NNEventManagerEventTypeInvoke];
    [keyManager registerHotKey:[NNHotKey hotKeyWithKeycode:kVK_Tab modifiers:(NNHotKeyModifierOption | NNHotKeyModifierShift)] forEvent:NNEventManagerEventTypeDecrement];
    [keyManager registerHotKey:[NNHotKey hotKeyWithKeycode:kVK_ANSI_W modifiers:NNHotKeyModifierOption] forEvent:NNEventManagerEventTypeCloseWindow];
    [keyManager registerHotKey:[NNHotKey hotKeyWithKeycode:kVK_Escape modifiers:NNHotKeyModifierOption] forEvent:NNEventManagerEventTypeCancel];
    [keyManager registerHotKey:[NNHotKey hotKeyWithKeycode:kVK_ANSI_Comma modifiers:NNHotKeyModifierOption] forEvent:NNEventManagerEventTypeShowPreferences];
    
    self.preferencesWindowController = [[NNPreferencesWindowController alloc] initWithWindowNibName:@"NNPreferencesWindowController"];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kNNFirstLaunchKey]) {
        [self setObject:@NO forKey:kNNFirstLaunchKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showPreferencesWindow:self];
        });
    }

    [defaults synchronize];
}

#pragma mark - NNPreferencesService

- (void)showPreferencesWindow:(id)sender;
{
    [self.preferencesWindowController showWindow:sender];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [self.preferencesWindowController.window makeKeyAndOrderFront:sender];
}

- (void)setObject:(id)object forKey:(NSString *)key;
{
    [[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
    [(id<NNPreferencesServiceDelegate>)self.subscriberDispatcher preferencesService:self didSetValue:object forKey:key];
}

- (id)objectForKey:(NSString *)key;
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

#pragma mark Private

- (NSDictionary *)_defaultValues;
{
    static NSDictionary *_defaultValues = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultValues = @{
            kNNFirstLaunchKey : @YES,
        };
    });
    return _defaultValues;
}

@end
