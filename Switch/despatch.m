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

#include <assert.h>
#include <dispatch/dispatch.h>

dispatch_queue_t despatch_lock_create(const char *label)
{
    dispatch_queue_t result = dispatch_queue_create(label, DISPATCH_QUEUE_SERIAL);
    dispatch_queue_set_specific(result, (__bridge const void *)(result), (__bridge void *)(result), NULL);
    return result;
}

inline static void despatch_assert_is_lock(dispatch_queue_t lock)
{
    assert(dispatch_queue_get_specific(lock, (__bridge const void *)(lock)));
}

void despatch_lock_assert(dispatch_queue_t lock)
{
    despatch_assert_is_lock(lock);
    assert(dispatch_get_specific((__bridge const void *)(lock)));
}

void despatch_lock_assert_not(dispatch_queue_t lock)
{
    despatch_assert_is_lock(lock);
    assert(!dispatch_get_specific((__bridge const void *)(lock)));
}

//void despatch_lock_async(dispatch_queue_t lock, dispatch_block_t block)
//{
//    despatch_assert_is_lock(lock);
//    dispatch_async(lock, block);
//}
//
//void despatch_lock_sync(dispatch_queue_t lock, dispatch_block_t block)
//{
//    despatch_assert_is_lock(lock);
//    // TODO: stack tracking
//    dispatch_sync(lock, block);
//}
