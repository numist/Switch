// HAXWindow.m
// Created by Rob Rix on 2011-01-06
// Copyright 2011 Rob Rix

#import "HAXWindow.h"
#import "HAXElement+Protected.h"

@implementation HAXWindow

-(NSArray *)views {
	NSArray *axChildren = self.children;
    NSMutableArray *result = [NSMutableArray array];
    
    NSString * axRole;
    for (HAXElement * haxElementI in axChildren) {
        axRole = [haxElementI getAttributeValueForKey:(__bridge NSString *)kAXRoleAttribute error:NULL];
        if ([axRole isEqualToString:@"AXView"]) {
            HAXView * haxView = [HAXView elementWithElementRef:(AXUIElementRef)haxElementI.elementRef];
            [result addObject:haxView];
        }
    }
	return result;
}

-(BOOL)raise {
	return [self performAction:(__bridge NSString *)kAXRaiseAction error:NULL];
}

-(BOOL)close {
	HAXElement *element = [self elementOfClass:[HAXElement class] forKey:(__bridge NSString *)kAXCloseButtonAttribute error:NULL];
	return [element performAction:(__bridge NSString *)kAXPressAction error:NULL];
}

@end
