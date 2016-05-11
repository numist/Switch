//
//  SWLoggingService.h
//  Switch
//
//  Created by Scott Perry on 10/15/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>


@interface SWLoggingService : NNService

- (NSString *)logDirectoryPath;
- (void)rotateLogIfNecessary;
- (void)takeWindowListSnapshot;

@end

#define SWLog(fmt, ...) do { \
        [[SWLoggingService sharedService] rotateLogIfNecessary]; \
        Log(fmt, ##__VA_ARGS__); \
    } while(0)

#define SWLogBackgroundThreadOnly() do { \
        if ([NSThread isMainThread]) { \
            SWLog(@"WARNING: -[%@ %@] was called on the main thread %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [NSThread callStackSymbols]); \
        } \
    } while(0)

#define SWCodeBlock(...) __VA_ARGS__

#define SWTimeTask(code, fmt, ...) do { \
        NSDate *start = [NSDate new]; \
        code \
        NSString *logmsg = [NSString stringWithFormat:fmt, ##__VA_ARGS__]; \
        NSTimeInterval elapsed = -[start timeIntervalSinceNow]; \
        if (elapsed > (1.0 / 60.0)) { \
            SWLog(@"%@ took %.3fs", logmsg, elapsed); \
        } \
    } while(0)
