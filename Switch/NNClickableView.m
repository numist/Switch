//
//  NNClickableView.m
//  Switch
//
//  Created by Scott Perry on 06/25/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNClickableView.h"

#import "NNAppDelegate.h"


@interface NNClickableView ()

@property (nonatomic, weak, readonly) id target;

@end


@implementation NNClickableView

- (instancetype)initWithFrame:(NSRect)frameRect target:(id)target;
{
    self = [super initWithFrame:frameRect];
    if (!self) { return nil; }
    
    _target = target;

    [self setWantsLayer:YES];
    
    return self;
}

- (void)mouseDown:(NSEvent *)theEvent;
{
    [self.target view:self detectedEvent:theEvent];
}

@end
