//  NSScreen+Helpers.h
//  Created by Scott Perry on 2020-09-26
//  Copyright 2020 Scott Perry

#import <Cocoa/Cocoa.h>

NSRect cocoaScreenFrameFromCarbonScreenFrame(CGRect carbonFrame);
CGPoint carbonScreenPointFromCocoaScreenPoint(NSPoint cocoaPoint);
