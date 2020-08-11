// HAXElement.h
// Created by Rob Rix on 2011-01-06
// Copyright 2011 Rob Rix

#import <Foundation/Foundation.h>

@protocol HAXElementDelegate;

@class HAXButton;

@interface HAXElement : NSObject

@property (nonatomic, weak) id<HAXElementDelegate> delegate;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *role;
@property (nonatomic, readonly) BOOL hasChildren;
@property (nonatomic, readonly) NSArray<HAXElement *> *children;
@property (nonatomic, readonly) NSArray<NSString *> *attributeNames;
@property (nonatomic, readonly) NSArray<HAXButton *> *buttons;
@property (nonatomic, readonly) pid_t processIdentifier;

-(BOOL)isEqualToElement:(HAXElement *)other;

@end

@protocol HAXElementDelegate <NSObject>
@optional
-(void)elementWasDestroyed:(HAXElement *)element;
@end
