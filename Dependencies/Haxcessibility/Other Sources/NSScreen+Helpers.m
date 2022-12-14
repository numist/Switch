//  NSScreen+Helpers.m
//  Created by Scott Perry on 2020-09-26
//  Copyright 2020 Scott Perry

#import "NSScreen+Helpers.h"

static NSScreen *hax_screenWithPoint(NSPoint p) {
    for (NSScreen *screen in [NSScreen screens]) {
        if (NSPointInRect(p, [screen frame])) {
            return screen;
        }
    }
    return nil;
}

NSRect cocoaScreenFrameFromCarbonScreenFrame(CGRect carbonFrame) {
    // TODO(numist): is this actually correct with multimon?
    NSRect originScreenFrame = ((NSScreen *)[NSScreen screens][0]).frame;

    return NSMakeRect(
        carbonFrame.origin.x,
        originScreenFrame.size.height - carbonFrame.origin.y - carbonFrame.size.height,
        carbonFrame.size.width,
        carbonFrame.size.height
    );
}

CGPoint carbonScreenPointFromCocoaScreenPoint(NSPoint cocoaPoint) {
    NSScreen *foundScreen = hax_screenWithPoint(cocoaPoint);

    if (foundScreen) {
        return CGPointMake(
            cocoaPoint.x,
            foundScreen.frame.size.height - cocoaPoint.y - 1
        );
    }
    return CGPointZero;
}
