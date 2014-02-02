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

#import "SWPreferencesService.h"
#import "SWWindowListService.h"


@implementation SWAppDelegate

#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NNServiceManager sharedManager] registerAllPossibleServices];
    
    SWLog(@"Launched %@ %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:(__bridge id)kCFBundleNameKey], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]);
}

- (void)relaunch:(id)sender;
{
    NSString *launcherSource = [[NSBundle bundleForClass:[SUUpdater class]]  pathForResource:@"relaunch" ofType:@""];
    Check(launcherSource);
    NSString *launcherTarget = [NSTemporaryDirectory() stringByAppendingPathComponent:[launcherSource lastPathComponent]];
    NSString *appPath = [[NSBundle mainBundle] bundlePath];
    NSString *processID = [NSString stringWithFormat:@"%d", [[NSProcessInfo processInfo] processIdentifier]];
    
    NSError *error = NULL;
    [[NSFileManager defaultManager] removeItemAtPath:launcherTarget error:&error];
    Check(error);
    [[NSFileManager defaultManager] copyItemAtPath:launcherSource toPath:launcherTarget error:&error];
    Check(error);
	
    [NSTask launchedTaskWithLaunchPath:launcherTarget arguments:@[appPath, processID]];
    [NSApp terminate:sender];
}

#pragma mark IBAction

- (IBAction)showPreferences:(id)sender {
    [[SWPreferencesService sharedService] showPreferencesWindow:sender];
}

@end
