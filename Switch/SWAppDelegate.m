//
//  SWAppDelegate.m
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

#import "SWAppDelegate.h"

#import <Sparkle/Sparkle.h>
#import <HockeySDK/HockeySDK.h>

#import "SWPreferencesService.h"
#import "SWWindowListService.h"


@implementation SWAppDelegate

#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
{
    [[NNServiceManager sharedManager] registerAllPossibleServices];
 
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"81d830d8a7181d7e0df6eeb805bb9728"];
    [[BITHockeyManager sharedHockeyManager] startManager];
    
    SWLog(@"Launched %@ %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:(__bridge id)kCFBundleNameKey], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]);
}

- (void)relaunch:(id)sender;
{
    // TODO: This should pop up a "please restart Switch" dialog. It sucks, but it's the best we can do in this situation.
    void (^failureBlock)() = ^{};
    
    NSString *launcherSource = [[NSBundle bundleForClass:[self class]]  pathForResource:@"relaunch" ofType:nil];
    BailWithBlockUnless(launcherSource, failureBlock);
    
    NSString *launcherTarget = [NSTemporaryDirectory() stringByAppendingPathComponent:[launcherSource lastPathComponent]];
    NSString *appPath = [[NSBundle mainBundle] bundlePath];
    NSString *processID = [NSString stringWithFormat:@"%d", [[NSProcessInfo processInfo] processIdentifier]];
    
    NSError *error = NULL;
    BOOL success = YES;
    success = [[NSFileManager defaultManager] removeItemAtPath:launcherTarget error:&error];
    if (!success) {
        // Code 4: "The operation couldn’t be completed. No such file or directory"
        BailWithBlockUnless(error.code == 4, failureBlock);
    }
    
    success = [[NSFileManager defaultManager] copyItemAtPath:launcherSource toPath:launcherTarget error:&error];
    BailWithBlockUnless(success, failureBlock);
	
    [NSTask launchedTaskWithLaunchPath:launcherTarget arguments:@[appPath, processID]];
    [NSApp terminate:sender];
}

#pragma mark IBAction

- (IBAction)showPreferences:(id)sender;
{
    [[SWPreferencesService sharedService] showPreferencesWindow:sender];
}

@end
