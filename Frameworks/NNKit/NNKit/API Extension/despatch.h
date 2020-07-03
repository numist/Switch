//
//  despatch.h
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

#ifndef NNKit_despatch_h
#define NNKit_despatch_h

/*!
 * @function despatch_sync_main_reentrant
 *
 * @abstract
 * Runs a block on the main queue, reentrantly if already on the main queue.
 *
 * @discussion
 * When on the main queue, executes the block synchronously before returning.
 * Otherwise, submits a block to the main queue and does not return until the block
 * has finished.
 *
 * @param block
 * The block to be invoked on the main queue.
 * The result of passing <code>NULL</code> in this parameter is undefined.
 * Which is to say it will probably crash.
 */
void despatch_sync_main_reentrant(dispatch_block_t block);

/*!
 * @function despatch_group_yield
 *
 * @abstract
 * Yields control of the current runloop. Return value indicates if the dispatch
 * group is clear.
 *
 * @discussion
 * When waiting for asynchronous jobs in a dispatch group that may block on the
 * current thread, this function yields the runloop and then returns the group
 * state.
 *
 * @param group
 * The group for which the caller is waiting.
 *
 * @result
 * <code>YES</code> if the group has no members, <code>NO</code> otherwise.
 */
BOOL despatch_group_yield(dispatch_group_t group);

#endif
