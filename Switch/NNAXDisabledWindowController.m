//
//  NNAXDisabledWindowController.m
//  Switch
//
//  Created by Scott Perry on 06/28/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNAXDisabledWindowController.h"

#import <Haxcessibility/Haxcessibility.h>
#import <QuartzCore/QuartzCore.h>

#import "NNAPIEnabledWorker.h"


static NSTimeInterval NNWindoFadeOutInterval = 1.0;


@interface NNAXDisabledWindowController ()

@property (nonatomic, strong) NNAPIEnabledWorker *apiWorker;
@property (nonatomic, assign) BOOL selfEnabled;

@property (nonatomic, weak) IBOutlet NSButton *enabledCheckbox;
@property (nonatomic, weak) IBOutlet NSTextFieldCell *promptMessage;
@property (nonatomic, weak) IBOutlet NSButton *quitButton;
@property (nonatomic, weak) IBOutlet NSButton *enableButton;

- (IBAction)checkboxClicked:(id)sender;
- (IBAction)enableButtonClicked:(id)sender;
- (IBAction)quitButtonClicked:(id)sender;

@end

@implementation NNAXDisabledWindowController

#pragma mark NSObject

- (instancetype)initWithWindowNibName:(NSString *)windowNibName;
{
    self = [super initWithWindowNibName:windowNibName];
    if (!self) { return nil; }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accessibilityAPIDisabled:) name:NNAXAPIDisabledNotification object:nil];
    
    return self;
}

- (void)dealloc;
{
    // Use the setter to remove the notification observer.
    self.apiWorker = nil;
}

#pragma mark NSWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    ((NSView *)self.window.contentView).wantsLayer = YES;
    
    CABasicAnimation *alphaAnimation = [CABasicAnimation animation];
    alphaAnimation.duration = NNWindoFadeOutInterval;
    
    self.window.animations = @{
        @"alphaValue" : alphaAnimation
    };
}

- (void)showWindow:(id)sender;
{
    if (!self.apiWorker) {
        self.apiWorker = [NNAPIEnabledWorker new];
    }
    
    [super showWindow:sender];
    [[NSRunningApplication currentApplication] activateWithOptions:NSApplicationActivateIgnoringOtherApps];

    self.window.alphaValue = 1.0f;
    self.selfEnabled = NO;

    [self updateWindowContents];
    
    NSButton *enableButton = self.enableButton;
    [self.window setDefaultButtonCell:(NSButtonCell *)enableButton];
    [self.window makeFirstResponder:enableButton];
}

- (void)close;
{
    self.apiWorker = nil;
    
    [super close];
}

#pragma mark - Properties

- (void)setApiWorker:(NNAPIEnabledWorker *)apiWorker;
{
    if (_apiWorker == apiWorker) { return; }
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    if (_apiWorker) {
        [center removeObserver:self name:NNPollCompleteNotification object:_apiWorker];
    }
    if (apiWorker) {
        [center addObserver:self selector:@selector(apiStatusChangedNotification:) name:NNPollCompleteNotification object:apiWorker];
    }
    _apiWorker = apiWorker;
}

#pragma mark Actions

- (IBAction)checkboxClicked:(__attribute__((unused)) id)sender;
{
    [self updateWindowContents];
}

- (IBAction)enableButtonClicked:(__attribute__((unused)) id)sender;
{
    if (![NNAPIEnabledWorker isAPIEnabled]) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            // Programmatic enabling of support for assistive devices via https://github.com/mayoff/keyscope
            NSAppleScript *script = [[NSAppleScript alloc] initWithSource:@"tell app \"System Events\"\n\tset UI elements enabled to true\n\tget UI elements enabled\nend"];
            NSDictionary *error;
            NSAppleEventDescriptor *aed = [script executeAndReturnError:&error];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSRunningApplication currentApplication] activateWithOptions:NSApplicationActivateIgnoringOtherApps];
                [self.window makeKeyAndOrderFront:self];
            });
            
            if (!aed) {
                Log(@"error enabling support for assistive devices: %@", error);
            } else if ([aed descriptorType] != 'true') {
                Log(@"failed to enable support for assistive devices");
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.selfEnabled = YES;
                    [self updateWindowContents];
                    [self animateClosed];
                });
            }
        });
    } else {
        [self close];
    }
}

- (IBAction)quitButtonClicked:(__attribute__((unused)) id)sender;
{
    exit(0);
}

#pragma mark Notifications

- (void)apiStatusChangedNotification:(__attribute__((unused)) NSNotification *)note;
{
    [self updateWindowContents];
}

- (void)accessibilityAPIDisabled:(__attribute__((unused)) NSNotification *)note;
{
    if (!self.apiWorker && !AXAPIEnabled()) {
        [self showWindow:self];
    }
}

#pragma mark Internal

- (void)animateClosed;
{
    Check([NNAPIEnabledWorker isAPIEnabled]);
    
    [self.window.animator setAlphaValue:0.0f];
    
    double delayInSeconds = NNWindoFadeOutInterval;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        // Avoid losing a minor race.
        if ([NNAPIEnabledWorker isAPIEnabled]) {
            [self close];
        } else {
            [self showWindow:self];
        }
    });
}

- (void)updateWindowContents;
{
    BOOL enabled = [NNAPIEnabledWorker isAPIEnabled];
    NSButton *checkbox = self.enabledCheckbox;
    NSButton *enableButton = self.enableButton;
    NSButton *quitButton = self.quitButton;
    
    if (enabled) {
        checkbox.state = NSOnState;
        enableButton.title = self.selfEnabled ? @"Thanks!" : @"Done";
        [quitButton setEnabled:NO];
    } else {
        checkbox.state = NSOffState;
        enableButton.title = @"Enable";
        [quitButton setEnabled:YES];
    }
}

@end
