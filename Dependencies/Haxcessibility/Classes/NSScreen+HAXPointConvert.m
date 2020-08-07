//  NSScreen+HAXPointConvert.m
//  Created by Kocsis Olivér on 2014-05-05
//  Copyright 2014 Joinect Technologies

#import "NSScreen+HAXPointConvert.h"

@implementation NSScreen (HAXPointConvert)

+ (NSScreen*)hax_screenWithPoint:(NSPoint)p {
    NSScreen *screen = nil;
    for (NSScreen *screenI in [NSScreen screens]) {
        if (NSPointInRect(p, [screenI frame])) {
            screen = screenI;
            break;
        }
    }
    return screen;
}

- (NSRect)hax_frameCarbon {
    NSRect originScreenFrame = ((NSScreen *)[NSScreen screens][0]).frame;
    
    NSRect carbonFrame;
    carbonFrame.origin=  NSMakePoint([self frame].origin.x,
                                    originScreenFrame.size.height -
                                    [self frame].origin.y -
                                    [self frame].size.height );;
    carbonFrame.size = [self frame].size;
    return carbonFrame;
}

+ (NSRect)hax_cocoaScreenFrameFromCarbonScreenFrame:(CGRect)carbonPoint {
    NSRect originScreenFrame = ((NSScreen *)[NSScreen screens][0]).frame;
    
    NSRect cocoaFrame;
    cocoaFrame.origin=  NSMakePoint(carbonPoint.origin.x,
                                    originScreenFrame.size.height -
                                    carbonPoint.origin.y -
                                    carbonPoint.size.height );;
    cocoaFrame.size = carbonPoint.size;
    return cocoaFrame;
}

+ (CGPoint)hax_carbonScreenPointFromCocoaScreenPoint:(NSPoint)cocoaPoint {
    NSScreen *foundScreen = nil;
    CGPoint thePoint;
    
    for (NSScreen *screen in [NSScreen screens]) {
        if (NSPointInRect(cocoaPoint, [screen frame])) {
            foundScreen = screen;
        }
    }
    
    if (foundScreen) {
        CGFloat screenHeight = [foundScreen frame].size.height;
        thePoint = CGPointMake(cocoaPoint.x, screenHeight - cocoaPoint.y - 1);
    } else {
        thePoint = CGPointMake(0.0, 0.0);
    }
    
    return thePoint;
}

@end
