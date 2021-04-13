// HAXApplication.h
// Created by Rob Rix on 2011-01-06
// Copyright 2011 Rob Rix

#import <Haxcessibility/HAXElement.h>

@class HAXWindow;

@interface HAXApplication : HAXElement

@property (readonly, nullable) HAXWindow * focusedWindow;
@property (readonly, nonnull) NSArray<HAXWindow *> *windows;
@property (readonly, nullable) NSString *localizedName;

+(nullable HAXApplication *)applicationWithPID:(pid_t)pid;

-(nullable HAXWindow *)windowWithID:(CGWindowID)cgWindowID;

@end
