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

#import "NNAPIEnabledWorker.h"


@interface NNAXDisabledWindowController ()

@property (nonatomic, strong) NNAPIEnabledWorker *apiWorker;

@property (nonatomic, weak) IBOutlet NSButton *enabledCheckbox;
@property (nonatomic, weak) IBOutlet NSTextFieldCell *promptMessage;
@property (nonatomic, weak) IBOutlet NSButton *quitButton;
@property (nonatomic, weak) IBOutlet NSButton *enableButton;

- (IBAction)checkboxClicked:(id)sender;
- (IBAction)enableButtonClicked:(id)sender;

@end

@implementation NNAXDisabledWindowController

- (void)dealloc;
{
    if (_apiWorker) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NNAPIEnabledChangedNotification object:_apiWorker];
    }
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    ((NSView *)self.window.contentView).wantsLayer = YES;
    
    [self.enableButton setKeyEquivalent:@"\r"];
    
    self.apiWorker = [NNAPIEnabledWorker new];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(apiStatusChangedNotification:) name:NNAPIEnabledChangedNotification object:self.apiWorker];
    
    [self updateWindowContents];
}

- (IBAction)checkboxClicked:(id)sender;
{
    [self updateWindowContents];

    NSLog(@"%@", [HAXSystem system].focusedApplication.windows);
}

- (IBAction)enableButtonClicked:(id)sender;
{
    if (!AXAPIEnabled()) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            // From https://github.com/mayoff/keyscope
            NSAppleScript *script = [[NSAppleScript alloc] initWithSource:@"tell app \"System Events\"\nset UI elements enabled to true\nget UI elements enabled\nend"];
            NSDictionary *error;
            NSAppleEventDescriptor *aed = [script executeAndReturnError:&error];
            if (!aed) {
#warning rephrase/re-not-die
                NSLog(@"keyscope/sniffer: error enabling universal access: %@", error);
                exit(1);
            }
            if ([aed descriptorType] != 'true') {
#warning rephrase/re-not-die
                NSLog(@"keyscope/sniffer: failed to enable universal access");
                exit(1);
            }
        });
    } else {
        NSLog(@"Close window");
    }
}

- (void)updateWindowContents;
{
    Boolean enabled = AXAPIEnabled();
    
    NSButton *checkbox = self.enabledCheckbox;
    checkbox.state = enabled ? NSOnState : NSOffState;
    
    if (enabled) {
        self.enableButton.title = @"Done";
        [self.quitButton setEnabled:NO];
    } else {
        self.enableButton.title = @"Enable";
        [self.quitButton setEnabled:YES];
    }
}

- (void)apiStatusChangedNotification:(NSNotification *)note;
{
    NSLog(@"Detected API transition");
    
    [self updateWindowContents];
}

@end
