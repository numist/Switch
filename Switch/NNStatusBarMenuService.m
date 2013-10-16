//
//  NNStatusBarMenuService.m
//  Switch
//
//  Created by Scott Perry on 10/15/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNStatusBarMenuService.h"

#import "NNAppDelegate.h"


@interface NNStatusBarMenuService () <NSMenuDelegate>

@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSSet *debugItems;

@end


@implementation NNStatusBarMenuService

- (instancetype)init;
{
    if (!(self = [super init])) { return nil; }
    
    NSStatusItem *statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    statusItem.image = [[NSBundle mainBundle] imageForResource:@"weave"];
    statusItem.target = self;
    
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Status Bar Menu"];
    
    // and set self.menu.menu to a menu (AND RENAME THAT SHIT WHAT THE EVERLOVING FUCK)
    NSMenuItem * menuItem;
    
    menuItem = [[NSMenuItem alloc] initWithTitle:@"Preferences…" action:@selector(showPreferences:) keyEquivalent:@""];
    menuItem.target = [NSApplication sharedApplication].delegate;
    [menu addItem:menuItem];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    { // These get filtered out when option is not pressed:
        NSMutableSet *debugItems = [NSMutableSet set];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Hi there!" action:NULL keyEquivalent:@""];
        menuItem.enabled = NO;
        [menu addItem:menuItem];
        [debugItems addObject:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"Open Log Folder…" action:@selector(openLogFolder:) keyEquivalent:@""];
        menuItem.target = self;
        [menu addItem:menuItem];
        [debugItems addObject:menuItem];
        
        menuItem = [NSMenuItem separatorItem];
        [menu addItem:menuItem];
        [debugItems addObject:menuItem];
        
        _debugItems = debugItems;
    }
    
    menuItem = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""];
    menuItem.target = [NSApplication sharedApplication];
    [menu addItem:menuItem];
    
    menu.delegate = self;
    
    statusItem.menu = menu;
    
    _statusItem = statusItem;
    
    return self;
}

- (IBAction)openLogFolder:(id)sender;
{
    [[NSWorkspace sharedWorkspace] openFile:[[NNLoggingService sharedLoggingService] logDirectoryPath]];
}

- (void)menuNeedsUpdate:(NSMenu *)menu;
{
    NSUInteger flags = ([NSEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask);
    BOOL hideDebugItems = !(flags == NSAlternateKeyMask);
    
    for (NSMenuItem *item in self.debugItems) {
        item.hidden = hideDebugItems;
    }
}

@end
