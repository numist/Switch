//
//  macros.h
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

#pragma once

// Compile-time key path additions
#define NNKeyPath(object, keyPath) ({ if (NO) { (void)((object).keyPath); } @#keyPath; })
#define NNSelfKeyPath(keyPath) NNKeyPath(self, keyPath)
#define NNTypedKeyPath(ObjectClass, keyPath) NNKeyPath(((ObjectClass *)nil), keyPath)
#define NNProtocolKeyPath(Protocol, keyPath) NNKeyPath(((id <Protocol>)nil), keyPath)

// Compile-time selector additions
#define NNSelector(object, selectorName) ({ if (NO) { (void)[(object) selectorName]; } @selector(selectorName); })
#define NNSelfSelector(selectorName) NNSelector(self, selectorName)
#define NNTypedSelector(ObjectClass, selectorName) NNSelector(((ObjectClass *)nil), selectorName)
#define NNProtocolSelector(Protocol, selectorName) NNSelector(((id <Protocol>)nil), selectorName)

#define NNSelector1(object, selectorName) ({ if (NO) { (void)[(object) selectorName nil]; } @selector(selectorName); })
#define NNSelfSelector1(selectorName) NNSelector1(self, selectorName)
#define NNTypedSelector1(ObjectClass, selectorName) NNSelector1(((ObjectClass *)nil), selectorName)
#define NNProtocolSelector1(Protocol, selectorName) NNSelector1(((id <Protocol>)nil), selectorName)
