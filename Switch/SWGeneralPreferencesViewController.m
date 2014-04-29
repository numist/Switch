//
//  SWGeneralPreferencesViewController.m
//  Switch
//
//  Created by Scott Perry on 10/10/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWGeneralPreferencesViewController.h"

#import <Sparkle/Sparkle.h>


@interface SWGeneralPreferencesViewController () <MASPreferencesViewController>

@property (nonatomic, weak) IBOutlet NSTextFieldCell *currentVersionCell;
@property (nonatomic, weak) IBOutlet NSButton *autoLaunchEnabledBox;

- (IBAction)autoLaunchChanged:(NSButton *)sender;
- (IBAction)autoUpdatesChanged:(NSButton *)sender;
- (IBAction)checkForUpdatesPressed:(NSButton *)sender;
- (IBAction)preReleaseUpdatesChanged:(NSButton *)sender;
- (IBAction)changelogPressed:(NSButton *)sender;
- (IBAction)quitPressed:(NSButton *)sender;

@end


@implementation SWGeneralPreferencesViewController

#pragma mark NSViewController

- (void)awakeFromNib;
{
    NSTextFieldCell *currentVersionCell = self.currentVersionCell;
    currentVersionCell.title = [NSString stringWithFormat:@"Currently using version %@", [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"]];
    
    NSButton *autoLaunchEnabled = self.autoLaunchEnabledBox;
    autoLaunchEnabled.state = [self _isAutoLaunchEnabled] ? NSOnState : NSOffState;
}

#pragma mark MASPreferencesViewController

- (NSString *)identifier
{
    return NSStringFromClass([self class]);
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"General", @"Toolbar item name for the General preference pane");
}

- (BOOL)hasResizableWidth;
{
    return NO;
}

- (BOOL)hasResizableHeight;
{
    return NO;
}

#pragma mark IBAction

- (IBAction)autoLaunchChanged:(NSButton *)sender {
    if (sender.state == NSOnState) {
        [self _enableAutoLaunch];
    } else {
        [self _disableAutolaunch];
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
    [[NSApplication sharedApplication] terminate:self];
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

- (BOOL)_isAutoLaunchEnabled;
{
    return !![self _selfFromLSSharedFileList];
}

- (void)_enableAutoLaunch;
{
	NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    
	LSSharedFileListRef loginItems = NNCFAutorelease(LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL));
    Check(loginItems);
	if (loginItems) {
		NNCFAutorelease(LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemLast, NULL, NULL, (__bridge CFURLRef)url, NULL, NULL));
	}
}

- (void)_disableAutolaunch;
{
    LSSharedFileListItemRef itemRef = [self _selfFromLSSharedFileList];
    Check(itemRef);
    if (itemRef) {
        LSSharedFileListRef loginItems = NNCFAutorelease(LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL));
        LSSharedFileListItemRemove(loginItems, itemRef);
    }
}

- (LSSharedFileListItemRef)_selfFromLSSharedFileList;
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
