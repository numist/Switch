//
//  NNAXDisabledWindowController.m
//  Switch
//
//  Created by Scott Perry on 06/28/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNAXDisabledWindowController.h"

@interface NNAXDisabledWindowController ()

@property (nonatomic, weak) IBOutlet NSButton *accessibilityIcon;
@property (nonatomic, weak) IBOutlet NSButton *enabledCheckbox;
@property (nonatomic, weak) IBOutlet NSTextFieldCell *promptMessage;

- (IBAction)accessibilityClicked:(id)sender;
- (IBAction)checkboxClicked:(id)sender;
- (IBAction)relaunchClicked:(id)sender;

@end

@implementation NNAXDisabledWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    ((NSView *)self.window.contentView).wantsLayer = YES;
    
    NSTextFieldCell *message = self.promptMessage;
    message.stringValue = [NSString stringWithFormat:@"%@ relies on Accessibility features in Mac OS X", [[NSRunningApplication currentApplication] localizedName]];
}

- (IBAction)accessibilityClicked:(id)sender;
{
    NSLog(@"open UniversalAccessPref.prefPane");
}

- (IBAction)checkboxClicked:(id)sender;
{
    NSButton *checkbox = self.enabledCheckbox;
    checkbox.state = AXAPIEnabled() ? NSOnState : NSOffState;
}

- (IBAction)relaunchClicked:(id)sender;
{
    NSLog(@"Not actually sure how to do this D:");
    abort();
}

/*
Want to detect:
    when system preferences/accessibility is launched/active
    when AXAPI is enabled/disabled
 */
@end
