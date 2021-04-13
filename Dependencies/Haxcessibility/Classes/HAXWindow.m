// HAXWindow.m
// Created by Rob Rix on 2011-01-06
// Copyright 2011 Rob Rix

#import "HAXWindow.h"
#import "HAXElement+Protected.h"

extern AXError _AXUIElementGetWindow(AXUIElementRef, CGWindowID* out);

@implementation HAXWindow

-(NSArray *)views {
	NSArray *axChildren = self.children;
    NSMutableArray *result = nil;

    if (axChildren) {
        result = [NSMutableArray arrayWithCapacity:axChildren.count];

        for (HAXElement * haxElementI in axChildren) {
            NSString * axRole = [haxElementI getAttributeValueForKey:(__bridge NSString *)kAXRoleAttribute error:NULL];
            if ([axRole isEqualToString:@"AXView"]) {
                HAXView * haxView = [[HAXView init] initWithElementRef:(AXUIElementRef)haxElementI.elementRef];
                [result addObject:haxView];
            }
        }
    }
	return result;
}

-(BOOL)raise {
    __block BOOL success = NO;
    pid_t pid = self.processIdentifier;
    if (pid == [NSProcessInfo processInfo].processIdentifier && ![NSThread isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{ success = [self raise]; });
        return success;
    }
    if ([self performAction:(__bridge NSString *)kAXRaiseAction error:NULL]) {
        ProcessSerialNumber psn;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if (pid && GetProcessForPID (pid, &psn) == 0) {
            success = (noErr == SetFrontProcessWithOptions(&psn, kSetFrontProcessFrontWindowOnly));
        }
#pragma clang diagnostic pop
    }
    return success;
}

-(BOOL)close {
	HAXElement *element = [self elementOfClass:[HAXElement class] forKey:(__bridge NSString *)kAXCloseButtonAttribute error:NULL];
	return [element performAction:(__bridge NSString *)kAXPressAction error:NULL];
}

// https://stackoverflow.com/a/9624565
-(CGWindowID)cgWindowID {
  CGWindowID result;
  AXError err = _AXUIElementGetWindow(self.elementRef, &result);
  if (err == kAXErrorSuccess) {
    return result;
  }
  return kCGNullWindowID;
}

@end
