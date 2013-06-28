//
//  NNWindow+NNWindowFiltering.h
//  Switch
//
//  Created by Scott Perry on 06/25/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNWindow.h"


typedef NSPoint NNVec2;


@interface NNWindow (NNWindowFiltering)

+ (NSArray *)filterValidWindowsFromArray:(NSArray *)array;

- (NNVec2)offsetOfCenterToCenterOfWindow:(NNWindow *)window;
- (NSSize)sizeDifferenceFromWindow:(NNWindow *)window;
- (BOOL)enclosedByWindow:(NNWindow *)window;
- (NNWindow *)previousNamedSiblingFromCollection:(NSArray *)array;
- (NNWindow *)nextNamedSiblingFromCollection:(NSArray *)array;


@end
