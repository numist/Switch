//
//  NNPreferencesWindowController.m
//  Switch
//
//  Created by Scott Perry on 10/10/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNPreferencesWindowController.h"

#import <Sparkle/Sparkle.h>


@interface NNPreferencesWindowController ()

@end


static void * NNCFAutorelease(CFTypeRef ref) {
    _Pragma("clang diagnostic push");
    if (ref) {
        _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"");
        [(__bridge id)ref performSelector:NSSelectorFromString(@"autorelease")];
    }
    _Pragma("clang diagnostic ignored \"-Wincompatible-pointer-types-discards-qualifiers\"")
    return ref;
    _Pragma("clang diagnostic pop");
}


@implementation NNPreferencesWindowController

#pragma mark NSWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    NSTextFieldCell *currentVersionCell = self.currentVersionCell;
    currentVersionCell.title = [NSString stringWithFormat:@"Currently using version %@", [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"]];
    
    NSButton *autoLaunchEnabled = self.autoLaunchEnabledBox;
    autoLaunchEnabled.state = [self isAutoLaunchEnabled] ? NSOnState : NSOffState;
}

#pragma mark Target-action

- (IBAction)autoLaunchChanged:(NSButton *)sender {
    if (sender.state == NSOnState) {
        [self enableAutoLaunch];
    } else {
        [self disableAutolaunch];
    }
}

- (IBAction)autoUpdatesChanged:(NSButton *)sender {
    // Disallow turning off auto updates when there is no GM build.
    sender.state = NSOnState;
}

- (IBAction)preReleaseUpdatesChanged:(NSButton *)sender {
    // Disallow turning off pre-release updates when there is no GM build.
    sender.state = NSOnState;
}

- (IBAction)changelogPressed:(NSButton *)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/numist/Switch/releases"]];
}

- (IBAction)quitPressed:(NSButton *)sender {
    exit(0);
}

- (IBAction)checkForUpdatesPressed:(NSButton *)sender {
    [[SUUpdater sharedUpdater] checkForUpdates:self];
}

#pragma mark Internal

//
// Launch at login helper methods!
//
// If you ever want to make this app sandbox-compatible, you're going to have to make a helper app and use SMLoginItemSetEnabled and LSRegisterURL.
// See http://www.delitestudio.com/2011/10/25/start-dockless-apps-at-login-with-app-sandbox-enabled/ for more info.
//

- (BOOL)isAutoLaunchEnabled;
{
    return !![self selfFromLSSharedFileList];
}

- (void)enableAutoLaunch;
{
	NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    
	LSSharedFileListRef loginItems = NNCFAutorelease(LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL));
    Check(loginItems);
	if (loginItems) {
		NNCFAutorelease(LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemLast, NULL, NULL, (__bridge CFURLRef)url, NULL, NULL));
	}
}

- (void)disableAutolaunch;
{
    LSSharedFileListItemRef itemRef = [self selfFromLSSharedFileList];
    Check(itemRef);
    if (itemRef) {
        LSSharedFileListRef loginItems = NNCFAutorelease(LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL));
        LSSharedFileListItemRemove(loginItems, itemRef);
    }
}

- (LSSharedFileListItemRef)selfFromLSSharedFileList;
{
	LSSharedFileListRef loginItems = NNCFAutorelease(LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL));
    BailUnless(loginItems, NULL);
    
    UInt32 snapshotSeed;
    NSArray  *loginItemsArray = (NSArray *)CFBridgingRelease(LSSharedFileListCopySnapshot(loginItems, &snapshotSeed));
    Check(loginItemsArray);

    NSString * appPath = [[NSBundle mainBundle] bundlePath];
    for (id item in loginItemsArray) {
        LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
        
        CFURLRef url;
        if (LSSharedFileListItemResolve(itemRef, 0, &url, NULL) == noErr) {
            NSString * urlPath = [(__bridge NSURL *)NNCFAutorelease(url) path];
            if ([urlPath compare:appPath] == NSOrderedSame) {
                return NNCFAutorelease(CFRetain(itemRef));
            }
        }
    }
    
    return NULL;
}

@end
