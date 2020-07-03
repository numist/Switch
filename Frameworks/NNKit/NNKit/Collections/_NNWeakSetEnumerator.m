//
//  _NNWeakSetEnumerator.m
//  NNKit
//
//  Created by Scott Perry on 11/19/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "_NNWeakSetEnumerator.h"

#import "_NNWeakArrayTombstone.h"
#import "NNWeakSet.h"


@interface NNWeakSet (Private)

@property (nonatomic, readonly, strong) NSSet *backingStore;

@end


@interface _NNWeakSetEnumerator ()

@property (nonatomic, readonly, strong) NSEnumerator *tombstoneEnumerator;

@end


@implementation _NNWeakSetEnumerator

- (instancetype)initWithWeakSet:(NNWeakSet *)set;
{
    if (!(self = [super init])) { return nil; }
    
    self->_tombstoneEnumerator = [set.backingStore.copy objectEnumerator];
    
    return self;
}

- (NSArray *)allObjects;
{
    NSMutableArray<_NNWeakArrayTombstone *> *result = [NSMutableArray new];
    
    for (_NNWeakArrayTombstone *tombstone in self.tombstoneEnumerator.allObjects) {
        id obj = tombstone.target;
        if (obj) {
            [result addObject:obj];
        }
    }
    
    return result;
}

- (id)nextObject;
{
    id obj;
    _NNWeakArrayTombstone *tombstone;
    
    do {
        tombstone = self.tombstoneEnumerator.nextObject;
        obj = tombstone.target;
    } while (!obj && tombstone);
    
    return obj;
}

@end
