//
//  SWPreferencesService.m
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

#import "SWPreferencesService.h"

#import <MASPreferencesWindowController.h>
#import <NNKit/NNService+Protected.h>

#import "SWAPIEnabledWorker.h"
#import "SWAdvancedPreferencesViewController.h"
#import "SWGeneralPreferencesViewController.h"
#import "SWKeyboardPreferencesViewController.h"


/**
 * Defining new preferences:
 *     • Put a property in the header. Do not set a fancy getter or setter or you'll have to define shim methods yourself.
 *     • Add a key to the list below.
 *     • Generate a getter/setter under the "Preferences: setters" pragma.
 *     • Set a default value in -defaultValues
 */


static NSString const * const kSWFirstLaunchKey = @"firstLaunch";
static NSString const * const kSWMultimonInterfaceKey = @"multimonInterface";
static NSString const * const kSWMultimonGroupByMonitorKey = @"multimonGroupByMonitor";
static NSString const * const kSWShowStatusItemKey = @"showStatusItem";
static NSString const * const kSWAppcastURLKey = @"SUFeedURL";


@interface SWPreferencesService ()

@property (nonatomic, strong) MASPreferencesWindowController *preferencesWindowController;

@end


@implementation SWPreferencesService

#pragma mark - NNService

+ (NNServiceType)serviceType;
{
    return NNServiceTypePersistent;
}

- (instancetype)init;
{
    BailUnless(self = [super init], nil);
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:self.defaultValues];

    return self;
}

- (void)startService;
{
    [super startService];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

#   if DEBUG
    {
        BOOL resetDefaults = NO;
        
        if (resetDefaults) {
            for (NSString *key in self.defaultValues.allKeys) {
                [defaults removeObjectForKey:key];
            }
        }
    }
#   endif
    
    NSViewController *(^prefPaneForClass)(Class) = ^(Class class){
        return [[class alloc] initWithNibName:NSStringFromClass(class) bundle:[NSBundle mainBundle]];
    };
    NSViewController *generalViewController = prefPaneForClass([SWGeneralPreferencesViewController class]);
    NSViewController *keyboardViewController = prefPaneForClass([SWKeyboardPreferencesViewController class]);
    NSViewController *advancedViewController = prefPaneForClass([SWAdvancedPreferencesViewController class]);
    NSArray *controllers = @[generalViewController, keyboardViewController, advancedViewController];
    NSString *title = NSLocalizedString(@"Preferences", @"Common title for Preferences window");
    
    self.preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers title:title];
    
    if ([defaults boolForKey:[kSWFirstLaunchKey copy]] && [SWAPIEnabledWorker isAPIEnabled]) {
        [self private_setObject:@NO forKey:kSWFirstLaunchKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showPreferencesWindow:self];
        });
    }

    [defaults synchronize];
}

#pragma mark - Preferences: setters

#define generateObjectPropertyMethods(setter, property, key) \
- (void)setter(id)property; { [self private_setObject:property forKey:key]; } \
- (id)property; { return [self private_objectForKey:key]; }

#define generateBoolPropertyMethods(setter, property, key) \
generateObjectPropertyMethods(GENERATED_obj_##setter, GENERATED_obj_##property, key) \
- (void)setter(_Bool)property; { [self GENERATED_obj_##setter@(property)]; } \
- (_Bool)property; { return [[self GENERATED_obj_##property] boolValue]; }

generateBoolPropertyMethods(setMultimonInterface:, multimonInterface, kSWMultimonInterfaceKey)
generateBoolPropertyMethods(setMultimonGroupByMonitor:, multimonGroupByMonitor, kSWMultimonGroupByMonitorKey)
generateBoolPropertyMethods(setShowStatusItem:, showStatusItem, kSWShowStatusItemKey)
generateObjectPropertyMethods(setAppcastURL:, appcastURL, kSWAppcastURLKey)

#pragma mark Preferences: default values

- (NSDictionary *)defaultValues;
{
    static NSDictionary *_defaultValues = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultValues = @{
            kSWFirstLaunchKey : @YES,
            kSWMultimonInterfaceKey : @YES,
            kSWMultimonGroupByMonitorKey : @NO,
            kSWShowStatusItemKey : @YES,
            kSWAppcastURLKey : @"https://raw.github.com/numist/Switch/develop/appcast.xml",
        };
    });
    return _defaultValues;
}

#pragma mark - SWPreferencesService

- (void)showPreferencesWindow:(id)sender;
{
    [self.preferencesWindowController showWindow:sender];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [self.preferencesWindowController.window makeKeyAndOrderFront:sender];
}

#pragma mark - Internal

- (void)private_setObject:(id)object forKey:(NSString const * const)key;
{
    if (object == nil) {
        object = self.defaultValues[key];
    }
    [[NSUserDefaults standardUserDefaults] setObject:object forKey:[key copy]];
}

- (id)private_objectForKey:(NSString const * const)key;
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:[key copy]];
}

@end
