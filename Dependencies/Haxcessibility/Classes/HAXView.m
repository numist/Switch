//  HAXView.m
//  Created by Kocsis Olivér on 2014-05-12
//  Copyright 2014 Joinect Technologies

#import "HAXView.h"
#import "HAXElement+Protected.h"
#import "NSScreen+Helpers.h"

@implementation HAXView

-(CGPoint)carbonOrigin {
    CGPoint origin = {0};
    AXValueRef originRef = (AXValueRef)[self copyAttributeValueForKey:(__bridge NSString *)kAXPositionAttribute error:NULL];
    if(originRef) {
        AXValueGetValue(originRef, kAXValueCGPointType, &origin);
        CFRelease(originRef);
        originRef = NULL;
    }
    return origin;
}

-(void)setCarbonOrigin:(CGPoint)carbonOrigin {
    AXValueRef originRef = AXValueCreate(kAXValueCGPointType, &carbonOrigin);
    [self setAttributeValue:originRef forKey:(__bridge NSString *)kAXPositionAttribute error:NULL];
    CFRelease(originRef);
}

-(NSPoint)origin {
    return cocoaScreenFrameFromCarbonScreenFrame(self.carbonFrame).origin;
}

-(void)setOrigin:(NSPoint)origin {
    self.carbonOrigin = carbonScreenPointFromCocoaScreenPoint(origin);
}

-(NSSize)size {
    CGSize size = {0};
    AXValueRef sizeRef = (AXValueRef)[self copyAttributeValueForKey:(__bridge NSString *)kAXSizeAttribute error:NULL];
    if(sizeRef) {
        AXValueGetValue(sizeRef, kAXValueCGSizeType, &size);
        CFRelease(sizeRef);
        sizeRef = NULL;
    }
    return size;
}

-(void)setSize:(NSSize)size {
    AXValueRef sizeRef = AXValueCreate(kAXValueCGSizeType, &size);
    [self setAttributeValue:sizeRef forKey:(__bridge NSString *)kAXSizeAttribute error:NULL];
    CFRelease(sizeRef);
}

-(CGRect)carbonFrame {
	return (CGRect){ .origin = self.carbonOrigin, .size = self.size };
}

-(void)setCarbonFrame:(CGRect)carbonFrame {
    self.carbonOrigin = carbonFrame.origin;
    self.size = carbonFrame.size;
}

-(NSRect)frame {
    return cocoaScreenFrameFromCarbonScreenFrame(self.carbonFrame);
}

-(void)setFrame:(NSRect)frame {
    self.origin = frame.origin;
    self.size = frame.size;
}

-(NSString *)title {
	return [self getAttributeValueForKey:(__bridge NSString *)kAXTitleAttribute error:NULL];
}

-(NSScreen *)screen {
    NSScreen *matchingScreen = nil;
    NSRect viewFrame = self.frame;
    NSUInteger bestOverlap = 0;
    for (NSScreen * screenI in [NSScreen screens]) {
        NSRect intersection = NSIntersectionRect(screenI.frame, viewFrame);
        NSUInteger intersectionOverlap = intersection.size.width * intersection.size.height;
        if(intersectionOverlap > bestOverlap) {
            matchingScreen = screenI;
            bestOverlap = intersectionOverlap;
        }
    }
    return matchingScreen;
}

-(BOOL)isFullscreen {
    BOOL isFullScreen = NO;
    NSArray * sceenArray = [NSScreen screens];
    NSRect windowFrame = self.frame;

    for (NSScreen * screenI in sceenArray) {
        NSRect screenFrame;
        screenFrame = [screenI frame];
        if(NSEqualRects(screenFrame, windowFrame)) {
            isFullScreen = YES;
            break;
        }
    }
    
    return isFullScreen;
}

@end
