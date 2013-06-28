//
//  NNWindowFilter.m
//  Switch
//
//  Created by Scott Perry on 06/28/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNWindowFilter.h"


@interface NNWindowFilter ()

@property (nonatomic, strong, readonly) NSString *applicationName;

@end


@implementation NNWindowFilter

+ (instancetype)alloc;
{
    // This is a virtual class and may not be instanciated.
    if ([self isEqual:[NNWindowFilter class]]) {
        return nil;
    }
    
    return [super alloc];
}

+ (instancetype)filter;
{
    return [self new];
}

- (instancetype)init;
{
    self = [super init];
    if (!self) { return nil; }

    Assert([[[self class] superclass] isEqual: [NNWindowFilter class]]);
    const char *className = class_getName([self class]);
    size_t appNameLength = strlen(className) - strlen(class_getName([[self class] superclass]));
    char *appName = alloca(appNameLength + 1);
    appName[appNameLength] = '\0';
    memcpy(appName, className + 2, appNameLength);
    _applicationName = [NSString stringWithCString:appName encoding:NSASCIIStringEncoding];
    
    return self;
}

- (NSArray *)filterInvalidWindowsFromArray:(NSArray *)array;
{
    return array;
}

@end
