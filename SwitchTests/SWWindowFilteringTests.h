//
//  NNWindowFilteringTests.h
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

#ifndef Switch_NNWindowFilteringTests_h
#define Switch_NNWindowFilteringTests_h


#define DICT_FROM_RECT(rect) ((__bridge_transfer NSDictionary *)CGRectCreateDictionaryRepresentation(rect))


static NSString *NNWindowAlpha;
static NSString *NNWindowBounds;
static NSString *NNWindowIsOnscreen;
static NSString *NNWindowLayer;
static NSString *NNWindowMemoryUsage;
static NSString *NNWindowName;
static NSString *NNWindowNumber;
static NSString *NNWindowOwnerName;
static NSString *NNWindowOwnerPID;
static NSString *NNWindowSharingState;
static NSString *NNWindowStoreType;

__attribute__((constructor)) static void NNWindowKeyInit() {
    NNWindowAlpha = (__bridge NSString *)kCGWindowAlpha;
    NNWindowBounds = (__bridge NSString *)kCGWindowBounds;
    NNWindowIsOnscreen = (__bridge NSString *)kCGWindowIsOnscreen;
    NNWindowLayer = (__bridge NSString *)kCGWindowLayer;
    NNWindowMemoryUsage = (__bridge NSString *)kCGWindowMemoryUsage;
    NNWindowName = (__bridge NSString *)kCGWindowName;
    NNWindowNumber = (__bridge NSString *)kCGWindowNumber;
    NNWindowOwnerName = (__bridge NSString *)kCGWindowOwnerName;
    NNWindowOwnerPID = (__bridge NSString *)kCGWindowOwnerPID;
    NNWindowSharingState = (__bridge NSString *)kCGWindowSharingState;
    NNWindowStoreType = (__bridge NSString *)kCGWindowStoreType;
}

#endif
