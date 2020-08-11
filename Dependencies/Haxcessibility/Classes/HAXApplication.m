// HAXApplication.m
// Created by Rob Rix on 2011-01-06
// Copyright 2011 Rob Rix

#import "HAXApplication.h"
#import "HAXElement+Protected.h"
#import "HAXWindow.h"

@implementation HAXApplication

+(HAXApplication *)applicationWithPID:(pid_t)pid {
	AXUIElementRef app = AXUIElementCreateApplication(pid);
	id result = nil;
	if (app) {
		result = [[HAXApplication alloc] initWithElementRef:app];
		CFRelease(app);
	}
	return result;
}

-(HAXWindow *)focusedWindow {
	return [self elementOfClass:[HAXWindow class] forKey:(NSString *)kAXFocusedWindowAttribute error:NULL];
}

-(NSArray *)windows {
	NSArray *axWindowObjects = [self getAttributeValueForKey:(NSString *)kAXWindowsAttribute error:NULL];
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:[axWindowObjects count]];
	for (id axObject in axWindowObjects) {
		[result addObject:[[HAXWindow alloc] initWithElementRef:(AXUIElementRef)axObject]];
	}
	return result;
}

-(NSString *)localizedName {
	return [self getAttributeValueForKey:(NSString *)kAXTitleAttribute error:NULL];
}

@end
