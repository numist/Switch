//
//  NSNotificationCenter+NNAdditions.m
//  NNKit
//
//  Created by Scott Perry on 11/14/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NSNotificationCenter+NNAdditions.h"

#import "NNCleanupProxy.h"


@implementation NSNotificationCenter (NNAdditions)

- (void)addWeakObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject;
{
    NSString *key = [NSString stringWithFormat:@"%p-%@-%@-%p", anObject, NSStringFromSelector(aSelector), aName, self];
    NNCleanupProxy *proxy = [NNCleanupProxy cleanupProxyForTarget:observer withKey:[key hash]];
	
    __weak NSNotificationCenter *weakCenter = self;
    __unsafe_unretained NNCleanupProxy *unsafeProxy = proxy;
	
    [proxy cacheMethodSignatureForSelector:aSelector];
    proxy.cleanupBlock = ^{
        NSNotificationCenter *center = weakCenter;
        
        [center removeObserver:unsafeProxy name:aName object:anObject];
    };
    [self addObserver:proxy selector:aSelector name:aName object:anObject];
}

@end
