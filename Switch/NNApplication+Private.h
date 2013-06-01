//
//  NNApplication+Private.h
//  Switch
//
//  Created by Scott Perry on 05/31/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNApplication.h"


@class HAXWindow;
@class NNWindow;


@interface NNApplication (Private)

- (instancetype)initWithPID:(pid_t)pid;

- (HAXWindow *)haxWindowForWindow:(NNWindow *)window __attribute__((nonnull(1)));

@end
