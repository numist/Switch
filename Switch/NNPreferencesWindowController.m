//
//  NNPreferencesWindowController.m
//  Switch
//
//  Created by Scott Perry on 10/10/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNPreferencesWindowController.h"

@interface NNPreferencesWindowController ()

@end

@implementation NNPreferencesWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)autoLaunchChanged:(NSButton *)sender {
    if (sender.state == NSOnState) {
        NSLog(@"Turned on autolaunch");
    } else {
        NSLog(@"Turned off autolaunch");
    }
}

- (IBAction)autoUpdatesChanged:(NSButton *)sender {
    if (sender.state == NSOnState) {
        NSLog(@"Turned on autoupdates");
    } else {
        NSLog(@"Turned off autoupdates");
    }
}

- (IBAction)preReleaseUpdatesChanged:(NSButton *)sender {
    sender.state = NSOnState;
}

- (IBAction)changelogPressed:(NSButton *)sender {
    NSLog(@"changelog BONK");
}

- (IBAction)quitPressed:(NSButton *)sender {
    exit(0);
}

- (IBAction)checkForUpdatesPressed:(NSButton *)sender {
    NSLog(@"check for updates BONK");
}

@end
