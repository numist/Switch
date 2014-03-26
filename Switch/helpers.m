//
//  helpers.m
//  Switch
//
//  Created by Scott Perry on 10/11/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "helpers.h"


BOOL NNNSSizesEqual(NSSize a, NSSize b)
{
    return a.width == b.width && a.height == b.height;
}

BOOL NNNSRectsEqual(NSRect a, NSRect b)
{
    return a.origin.x == b.origin.x && a.origin.y == b.origin.y && NNNSSizesEqual(a.size, b.size);
}

void *NNCFAutorelease(CFTypeRef cfObject)
{
    if (cfObject) {
        static Class arp = Nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            arp = NSClassFromString(@"NSAutoreleasePool");
            Assert(arp);
        });
        
        [arp addObject:(__bridge id)cfObject];
    }
    
    return (void *)cfObject;
}
