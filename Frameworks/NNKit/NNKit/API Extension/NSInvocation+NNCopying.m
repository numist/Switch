//
//  NSInvocation+NNCopying.m
//  NNKit
//
//  Created by Scott Perry on 03/10/14.
//  Copyright © 2014 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NSInvocation+NNCopying.h"

@implementation NSInvocation (NNCopying)

- (instancetype)nn_copy;
{
    NSMethodSignature *signature = [self methodSignature];
    NSUInteger const arguments = signature.numberOfArguments;

    NSInvocation *result = [NSInvocation invocationWithMethodSignature:signature];

    void *heapBuffer = NULL;
    size_t heapBufferSize = 0;

    NSUInteger alignp = 0;
    for (NSUInteger i = 0; i < arguments; i++) {
        const char *type = [signature getArgumentTypeAtIndex:i];
        NSGetSizeAndAlignment(type, NULL, &alignp);

        if (alignp > heapBufferSize) {
            heapBuffer = heapBuffer
                       ? reallocf(heapBuffer, alignp)
                       : malloc(alignp);
            heapBufferSize = alignp;
        }

        [self getArgument:heapBuffer atIndex:i];
		[result setArgument:heapBuffer atIndex:i];
    }

    if (heapBuffer) {
        free(heapBuffer);
    }

    result.target = self.target;

    if (self.argumentsRetained) {
        [result retainArguments];
    }

    return result;
}

@end
