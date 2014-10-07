//
//  SWInterfaceController.m
//  Switch
//
//  Created by Scott Perry on 10/01/14.
//  Copyright © 2014 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWInterfaceController.h"

#import "NSScreen+SWAdditions.h"
#import "SWCoreWindowController.h"
#import "SWEventTap.h"
#import "SWPreferencesService.h"
#import "SWWindow.h"


@interface SWInterfaceController () <SWCoreWindowControllerDelegate>

@property (nonatomic, readonly, weak) id<SWInterfaceControllerDelegate> delegate;

@property (nonatomic, readonly, strong) NSMutableDictionary *windowControllerCache;
@property (nonatomic, readwrite, strong) NSDictionary *windowControllersByScreenID;
@property (nonatomic, readwrite, strong) id<SWCoreWindowControllerAPI> windowControllerDispatcher;

@property (nonatomic, readwrite, copy) NSOrderedSet *windowList;
@property (nonatomic, readwrite, strong) SWWindow *selectedWindow;

@end


@implementation SWInterfaceController

- (instancetype)initWithDelegate:(id<SWInterfaceControllerDelegate>)delegate;
{
    BailUnless((self = [super init]), nil);

    self->_delegate = delegate;

    self->_windowControllerCache = [NSMutableDictionary new];
    BailUnless(self->_windowControllerCache, nil);

    return self;
}

#pragma mark - SWCoreWindowControllerDelegate

- (void)coreWindowController:(SWCoreWindowController *)controller didSelectWindow:(SWWindow *)window;
{
    Check([NSThread isMainThread]);
    id<SWInterfaceControllerDelegate> delegate = self.delegate;
    [delegate interfaceController:self didSelectWindow:window];
}

- (void)coreWindowController:(SWCoreWindowController *)controller didActivateWindow:(SWWindow *)window;
{
    Check([NSThread isMainThread]);
    id<SWInterfaceControllerDelegate> delegate = self.delegate;
    [delegate interfaceController:self didActivateWindow:window];
}

- (void)coreWindowControllerDidClickOutsideInterface:(SWCoreWindowController *)controller;
{
    Check([NSThread isMainThread]);
    id<SWInterfaceControllerDelegate> delegate = self.delegate;
    [delegate interfaceControllerDidClickOutsideInterface:self];
}

#pragma mark - SWInterfaceController

- (void)shouldShowInterface:(_Bool)showInterface;
{
    Check([NSThread isMainThread]);
    if (showInterface == self->_showInterface) { return; }
    self->_showInterface = showInterface;

    if (showInterface ) {
        [self _showInterface];
    } else {
        [self _hideInterface];
    }
}

- (void)updateWindowList:(NSOrderedSet *)windowList;
{
    Check([NSThread isMainThread]);

    self.windowList = windowList;

    if (!self.showingInterface) { return; }

    [self _updateWindowList];
}

- (void)selectWindow:(SWWindow *)window;
{
    Check([NSThread isMainThread]);

    self.selectedWindow = window;

    if (!self.showingInterface) { return; }

    [self _updateSelection];
}

- (void)disableWindow:(SWWindow *)window;
{
    Check([NSThread isMainThread]);

    [self.windowControllerDispatcher disableWindow:window];
}

- (void)enableWindow:(SWWindow *)window;
{
    Check([NSThread isMainThread]);

    [self.windowControllerDispatcher enableWindow:window];
}

#pragma mark - Private

- (void)_updateSelection;
{
    Check([NSThread isMainThread]);

    SWWindow *selectedWindow = self.selectedWindow;
    [self.windowControllerDispatcher selectWindow:(SWWindow *)selectedWindow];
    Check(selectedWindow);
}

- (void)_updateWindowList;
{
    Check([NSThread isMainThread]);

    NSOrderedSet *windowList = self.windowList;

    if (!windowList) {
        id<SWCoreWindowControllerAPI> dispatch = self.windowControllerDispatcher;
        Check(dispatch);
        [dispatch updateWindowList:nil];
        return;
    }

    // Create a dictionary of ordered sets of windows where each key refers to a screen…
    NSDictionary *windowsByScreen = ^{
        NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:self.windowControllersByScreenID.count];
        for (NSNumber *screenNumber in self.windowControllersByScreenID.allKeys) {
            result[screenNumber] = [NSMutableOrderedSet new];
        }
        return result;
    }();

    // …and each value is a windowList of the windows on that screen.
    for (SWWindow *window in windowList) {
        NSNumber *screenNumber = @([window screen].sw_screenNumber);

        /** This shouldn't be possible! We just built windowsByScreen.
         * I think Past Me intended this to check self.windowControllersByScreenID[screenNumber],
         * but even then a controller responsible for the main screen isn't necessarily guaranteed
         * to exist if this check failed.
         */
        if (!Check([windowsByScreen objectForKey:screenNumber])) {
            screenNumber = @([NSScreen mainScreen].sw_screenNumber);
        }

        [windowsByScreen[screenNumber] addObject:window];
    }

    for (NSNumber *screenNumber in windowsByScreen.allKeys) {
        SWCoreWindowController *windowController = self.windowControllersByScreenID[screenNumber];
        Check(windowController);
        windowController.windowList = windowsByScreen[screenNumber];
    }
}

- (void)_showInterface;
{
    Check([NSThread isMainThread]);
    Check(self.windowList);
    Check(!self.windowControllersByScreenID);

    // Build up a hash of window controllers, each one representing/covering one screen.
    self.windowControllersByScreenID = ^{
        NSMutableDictionary *windowControllers = [NSMutableDictionary new];
        NSArray *screens = [SWPreferencesService sharedService].multimonInterface
                         ? [NSScreen screens]
                         : @[[NSScreen mainScreen]];

        for (NSScreen *screen in screens) {
            // Cache: Fetch/fulfull window controllers.
            SWCoreWindowController *windowController = [self.windowControllerCache objectForKey:@(screen.sw_screenNumber)];
            if (!windowController) {
                windowController = [[SWCoreWindowController alloc] initWithScreen:screen];
                self.windowControllerCache[@(screen.sw_screenNumber)] = windowController;
            }

            // Initialize window controllers for their screens.
            [windowController.window setFrame:screen.frame display:YES];
            windowController.delegate = self;
            windowControllers[@(screen.sw_screenNumber)] = windowController;
        }

        // Cache: evict window controllers for screens that no longer exist.
        for (NSNumber *screenNumber in self.windowControllerCache.allKeys.copy) {
            if (![windowControllers.allValues containsObject:self.windowControllerCache[screenNumber]]) {
                [self.windowControllerCache removeObjectForKey:screenNumber];
            }
        }

        return windowControllers;
    }();

    // Build a dispatch manager responsible for messaging all the window controllers.
    self.windowControllerDispatcher = (SWCoreWindowController *)^{
        NNMultiDispatchManager *dispatcher = [[NNMultiDispatchManager alloc] initWithProtocol:@protocol(SWCoreWindowControllerAPI)];

        for (SWCoreWindowController *windowController in self.windowControllersByScreenID.allValues) {
            [dispatcher addObserver:windowController];
        }

        return dispatcher;
    }();

    // Populate window controllers with the data that's already on hand.
    [self _updateWindowList];
    [self _updateSelection];

    // layoutSubviewsIfNeeded isn't instant due to Auto Layout magic, so let everything take effect before showing the window.
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.showInterface) {
            for (SWCoreWindowController *windowController in self.windowControllersByScreenID.allValues) {
                [windowController.window orderFront:self];
            }
        }
    });
}

- (void)_hideInterface;
{
    Check([NSThread isMainThread]);
    Check(self.windowControllersByScreenID);

    // Hide all the windows
    for (SWCoreWindowController *windowController in self.windowControllersByScreenID.allValues) {
        [windowController.window orderOut:self];
        windowController.delegate = nil;
    }

    self.windowList = nil;
    [self _updateWindowList];

    self.windowControllersByScreenID = nil;
    self.windowControllerDispatcher = nil;
}

@end
