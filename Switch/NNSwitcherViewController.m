//
//  NNSwitcherViewController.m
//  Switch
//
//  Created by Scott Perry on 03/01/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNSwitcherViewController.h"
#import "NNRoundedRectView.h"
#import "NNWindowThumbnailView.h"
#import "NNWindowData.h"

@interface NNSwitcherViewController ()

@property (nonatomic, weak) NNSwitcher *switcher;

@property (nonatomic, strong) NNWindowThumbnailView *selectedView;
@property (nonatomic, strong) NSDictionary *thumbViews;
@property (nonatomic, assign) BOOL firstUpdate;

@end

@implementation NNSwitcherViewController

- (id)initWithSwitcher:(NNSwitcher *)switcher;
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;

    _switcher = switcher;
    _firstUpdate = YES;
    
    return self;
}

- (void)loadView;
{
    NSLog(@"View loaded");
    self.view = [[NNRoundedRectView alloc] initWithFrame:NSZeroRect];
}

- (void)updateViewsWithWindowList:(NSArray *)windows;
{
    if (self.firstUpdate) {
        self.firstUpdate = NO;
        NSLog(@"First draw, no need to animate!");
    } else {
        NSLog(@"Animation needed");
    }
}

- (void)setSelectedView:(NNWindowThumbnailView *)selectedView;
{
    _selectedView.selected = NO;
    selectedView.selected = YES;
    _selectedView = selectedView;
}

#pragma mark NNSwitcherDelegate

- (void)switcher:(NNSwitcher *)switcher didUpdateIndex:(unsigned int)index;
{
    self.selectedView = [self.thumbViews objectForKey:[self.switcher.windows objectAtIndex:index]];
}

- (void)switcher:(NNSwitcher *)switcher didUpdateWindowList:(NSArray *)windows;
{
    [self updateViewsWithWindowList:windows];
}

- (void)switcher:(NNSwitcher *)switcher contentsOfWindowDidChange:(NNWindowData *)window;
{
    [[self.thumbViews objectForKey:window] setWindowThumbnail:window.image];
}

#pragma mark Internal

@end
