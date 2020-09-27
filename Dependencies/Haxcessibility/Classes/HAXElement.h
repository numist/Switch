// HAXElement.h
// Created by Rob Rix on 2011-01-06
// Copyright 2011 Rob Rix

#import <Foundation/Foundation.h>

@protocol HAXElementDelegate;

@class HAXButton;

@interface HAXElement : NSObject

@property (nonatomic, nullable, weak) id<HAXElementDelegate> delegate;
@property (nonatomic, nullable, readonly) NSString *title;
@property (nonatomic, nullable, readonly) NSString *role;
@property (nonatomic, readonly) BOOL hasChildren;
@property (nonatomic, nullable, readonly) NSArray<HAXElement *> *children;
@property (nonatomic, nullable, readonly) NSArray<NSString *> *attributeNames;
@property (nonatomic, nullable, readonly) NSArray<HAXButton *> *buttons;
@property (nonatomic, readonly) pid_t processIdentifier;

@end

@protocol HAXElementDelegate <NSObject>
@optional
-(void)elementWasDestroyed:(nonnull HAXElement *)element;
@end
