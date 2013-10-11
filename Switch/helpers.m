//
//  helpers.m
//  Switch
//
//  Created by Scott Perry on 10/11/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "helpers.h"

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
