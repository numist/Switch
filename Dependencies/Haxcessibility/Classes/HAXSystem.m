// HAXSystem.m
// Created by Rob Rix on 2011-01-06
// Copyright 2011 Rob Rix

#import "HAXApplication.h"
#import "HAXSystem.h"
#import "HAXElement+Protected.h"

@implementation HAXSystem

+(instancetype)system {
	AXUIElementRef element = AXUIElementCreateSystemWide();
	HAXSystem *result = [[HAXSystem alloc] initWithElementRef:element];
	CFRelease(element);
	return result;
}


-(HAXApplication *)focusedApplication {
	return [self elementOfClass:[HAXApplication class] forKey:(NSString *)kAXFocusedApplicationAttribute error:NULL];
}

@end
