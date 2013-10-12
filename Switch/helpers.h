//
//  helpers.h
//  Switch
//
//  Created by Scott Perry on 10/11/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <Foundation/Foundation.h>


#define NNAssertMainQueue() NSAssert([[NSThread currentThread] isMainThread], @"Current path of execution must be run on the main thread");

BOOL NNNSRectsEqual(NSRect a, NSRect b);
BOOL NNNSSizesEqual(NSSize a, NSSize b);

#define NNCFAutorelease(ref) _NNCFAutorelease(CFBridgingRelease((ref)))
void * _NNCFAutorelease(id obj);

NSOrderedSet *NNFilterOrderedSet(NSOrderedSet *set, BOOL(^predicate)(id each));
