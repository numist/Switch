// HAXWindow.h
// Created by Rob Rix on 2011-01-06
// Copyright 2011 Rob Rix

#import <Cocoa/Cocoa.h>
#import <Haxcessibility/HAXView.h>

@interface HAXWindow : HAXView

@property (nonatomic, readonly) NSArray *views;

-(BOOL)raise;
-(BOOL)close;

@end
