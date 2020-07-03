//
//  NSArray+NNComprehensions.m
//  NNKit
//
//  Created by Scott Perry on 02/25/14.
//  Copyright © 2014 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NSCollections+NNComprehensions.h"

#define FILTER_DECLARATION() - (instancetype)nn_filter:(nn_filter_block_t)block
#define FILTER_DEFINITION(__type__) \
    id result = [[[__type__ class] new] mutableCopy]; \
    for (id object in self) { \
        if (block(object)) { \
            [result addObject:object]; \
        } \
    } \
    return result

#define MAP_DECLARATION() - (instancetype)nn_map:(nn_map_block_t)block
#define MAP_DEFINITION(__type__) \
    id result = [[[__type__ class] new] mutableCopy]; \
    for (id object in self) { \
        [result addObject:block(object)]; \
    } \
    return result


#define REDUCE_DECLARATION() - (id)nn_reduce:(nn_reduce_block_t)block
#define REDUCE_DEFINITION(__type__) \
    id accumulator = nil; \
    for (id object in self) { \
        accumulator = block(accumulator, object); \
    } \
    return accumulator


@implementation NSArray (NNComprehensions)

FILTER_DECLARATION();
{
    FILTER_DEFINITION(NSArray);
}

MAP_DECLARATION();
{
    MAP_DEFINITION(NSArray);
}

REDUCE_DECLARATION();
{
    REDUCE_DEFINITION(NSArray);
}

@end

@implementation NSSet (NNComprehensions)

FILTER_DECLARATION();
{
    FILTER_DEFINITION(NSSet);
}

MAP_DECLARATION();
{
    MAP_DEFINITION(NSSet);
}

REDUCE_DECLARATION();
{
    REDUCE_DEFINITION(NSSet);
}

@end

@implementation NSOrderedSet (NNComprehensions)

FILTER_DECLARATION();
{
    FILTER_DEFINITION(NSOrderedSet);
}

MAP_DECLARATION();
{
    MAP_DEFINITION(NSOrderedSet);
}

REDUCE_DECLARATION();
{
    REDUCE_DEFINITION(NSOrderedSet);
}

@end
