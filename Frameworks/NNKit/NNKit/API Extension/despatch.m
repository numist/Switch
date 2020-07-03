//
//  despatch.m
//  NNKit
//
//  Created by Scott Perry on 09/05/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#include "despatch.h"


void despatch_sync_main_reentrant(dispatch_block_t block)
{
    if ([[NSThread currentThread] isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

BOOL despatch_group_yield(dispatch_group_t group)
{
    // Let the runloop consume another event.
    NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
    assert(currentRunLoop); // I sure have gotten paranoid in my old age.
    (void)[currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];
    
    // dispatch_group_wait docs say it returns zero or nonzero. Luckily, it needs to be inverted anyway, so a valid BOOL value gets enforced.
    return !dispatch_group_wait(group, DISPATCH_TIME_NOW);
}
