// HAXElement+Protected.h
// Created by Rob Rix on 2011-01-06
// Copyright 2011 Rob Rix

#import <Haxcessibility/HAXElement.h>

@interface HAXElement ()

+(instancetype)elementWithElementRef:(AXUIElementRef)elementRef __attribute__((nonnull(1)));
-(instancetype)initWithElementRef:(AXUIElementRef)elementRef __attribute__((nonnull(1)));

@property (nonatomic, readonly) AXUIElementRef elementRef __attribute__((NSObject));

-(id)getAttributeValueForKey:(NSString *)key error:(NSError **)error __attribute__((nonnull(1)));
-(CFTypeRef)copyAttributeValueForKey:(NSString *)key error:(NSError **)error __attribute__((nonnull(1)));
-(BOOL)setAttributeValue:(CFTypeRef)value forKey:(NSString *)key error:(NSError **)error __attribute__((nonnull(1,2)));
-(BOOL)performAction:(NSString *)action error:(NSError **)error __attribute__((nonnull(1)));

-(id)elementOfClass:(Class)klass forKey:(NSString *)key error:(NSError **)error __attribute__((nonnull(1,2)));

@end
