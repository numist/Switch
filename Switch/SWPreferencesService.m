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

#import <NNKit/NNService+Protected.h>
#import <MASPreferencesWindowController.h>

#import "SWAPIEnabledWorker.h"
#import "SWAdvancedPreferencesViewController.h"
#import "SWGeneralPreferencesViewController.h"
#import "SWKeyboardPreferencesViewController.h"

static NSString *kSWFirstLaunchKey = @"firstLaunch";
static NSString *kSWMultimonInterfaceKey = @"multimonInterface";


@interface SWPreferencesService ()

@property (nonatomic, strong) MASPreferencesWindowController *preferencesWindowController;

@end


@implementation SWPreferencesService

#pragma mark NNService

+ (NNServiceType)serviceType;
{
    return NNServiceTypePersistent;
}

- (instancetype)init;
{
    if (!(self = [super init])) { return nil; }
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:self._defaultValues];

    _multimonInterface = [[self _objectForKey:kSWMultimonInterfaceKey] boolValue];
    
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
            for (NSString *key in self._defaultValues.allKeys) {
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
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kSWFirstLaunchKey] && [SWAPIEnabledWorker isAPIEnabled]) {
        [self _setObject:@NO forKey:kSWFirstLaunchKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showPreferencesWindow:self];
        });
    }

    [defaults synchronize];
}

#pragma mark SWPreferencesService

- (void)setMultimonInterface:(BOOL)multimonInterface;
{
    _multimonInterface = multimonInterface;
    [self _setObject:@(multimonInterface) forKey:kSWMultimonInterfaceKey];
}

- (void)showPreferencesWindow:(id)sender;
{
    [self.preferencesWindowController showWindow:sender];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [self.preferencesWindowController.window makeKeyAndOrderFront:sender];
}

- (void)_setObject:(id)object forKey:(NSString *)key;
{
    [[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
}

- (id)_objectForKey:(NSString *)key;
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

#pragma mark Internal

- (NSDictionary *)_defaultValues;
{
    static NSDictionary *_defaultValues = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultValues = @{
            kSWFirstLaunchKey : @YES,
            kSWMultimonInterfaceKey : @YES,
        };
    });
    return _defaultValues;
}

@end
