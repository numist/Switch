//
//  memoize.c
//  NNKit
//
//  Created by Scott Perry on 06/23/15.
//  Copyright © 2015 Scott Perry. All rights reserved.
//

#import "memoize.h"

#import <objc/runtime.h>


id _NNMemoize(id self, SEL _cmd, id (^block)()) {
    id result;
    void *key = (void *)((uintptr_t)(__bridge void *)self ^ (uintptr_t)(void *)_cmd ^ (uintptr_t)&_NNMemoize);
    
    @synchronized(self) {
        result = objc_getAssociatedObject(self, key);
        if (!result) {
            result = block();
            objc_setAssociatedObject(self, key, result, OBJC_ASSOCIATION_COPY_NONATOMIC);
        }
    }
    
    return result;
}
