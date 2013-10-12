//
//  helpers.m
//  Switch
//
//  Created by Scott Perry on 10/11/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "helpers.h"


BOOL NNNSSizesEqual(NSSize a, NSSize b)
{
    return a.width == b.width && a.height == b.height;
}

BOOL NNNSRectsEqual(NSRect a, NSRect b)
{
    return a.origin.x == b.origin.x && a.origin.y == b.origin.y && NNNSSizesEqual(a.size, b.size);
}

void * _NNCFAutorelease(id obj) {
    _Pragma("clang diagnostic push");
    if (obj) {
        _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"");
        [[obj performSelector:NSSelectorFromString(@"retain")] performSelector:NSSelectorFromString(@"autorelease")];
    }
    _Pragma("clang diagnostic ignored \"-Wincompatible-pointer-types-discards-qualifiers\"")
    return (__bridge void *)obj;
    _Pragma("clang diagnostic pop");
}

NSOrderedSet *NNFilterOrderedSet(NSOrderedSet *set, BOOL(^predicate)(id each))
{
    NSMutableOrderedSet *result = [NSMutableOrderedSet new];
    for (id item in set) {
        if (predicate(item)) {
            [result addObject:item];
        }
    }
    return result;
}
