//
//  despatch.m
//  Switch
//
//  Created by Scott Perry on 02/24/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#include "despatch.h"

#include <assert.h>


static uint64_t despatch_lock_marker = 0xffc32e78ccb0b485;


inline static BOOL despatch_queue_is_lock(dispatch_queue_t queue);


dispatch_queue_t despatch_lock_create(const char *label)
{
    dispatch_queue_t result = dispatch_queue_create(label, DISPATCH_QUEUE_SERIAL);
    despatch_lock_promote(result);
    return result;
}

void despatch_lock_promote(dispatch_queue_t queue)
{
    if (!despatch_queue_is_lock(queue)) {
        dispatch_queue_set_specific(queue, (__bridge const void *)(queue), (__bridge void *)(queue), NULL);
        dispatch_queue_set_specific(queue, &despatch_lock_marker, &despatch_lock_marker, NULL);
    }
}

inline static BOOL despatch_queue_is_lock(dispatch_queue_t queue)
{
    return !!dispatch_queue_get_specific(queue, (__bridge const void *)(queue)) && !!dispatch_queue_get_specific(queue, &despatch_lock_marker);
}

void despatch_lock_assert(dispatch_queue_t lock)
{
    assert(despatch_lock_is_held(lock));
}

void despatch_lock_assert_not(dispatch_queue_t lock)
{
    assert(!despatch_lock_is_held(lock));
}

BOOL despatch_lock_is_held(dispatch_queue_t lock)
{
    assert(despatch_queue_is_lock(lock));
    return !!dispatch_get_specific((__bridge const void *)(lock));
}

BOOL despatch_any_locks_held()
{
    return !!dispatch_get_specific(&despatch_lock_marker);
}
