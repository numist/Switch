// HAXSystem.h
// Created by Rob Rix on 2011-01-06
// Copyright 2011 Rob Rix

#import <Haxcessibility/HAXElement.h>

@class HAXApplication;

@interface HAXSystem : HAXElement

+(nonnull instancetype)system;

@property (readonly, nullable) HAXApplication *focusedApplication;

@end
