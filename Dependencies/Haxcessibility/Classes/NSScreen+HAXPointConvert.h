//  NSScreen+HAXPointConvert.h
//  Created by Kocsis Olivér on 2014-05-05
//  Copyright 2014 Joinect Technologies

#import <Cocoa/Cocoa.h>

@interface NSScreen (HAXPointConvert)

- (NSRect)hax_frameCarbon;
+ (NSScreen*)hax_screenWithPoint:(NSPoint)p;
+ (NSRect)hax_cocoaScreenFrameFromCarbonScreenFrame:(CGRect)carbonPoint;
+ (CGPoint)hax_carbonScreenPointFromCocoaScreenPoint:(NSPoint)cocoaPoint;

@end
