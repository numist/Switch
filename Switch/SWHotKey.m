//
//  SWHotKey.m
//  Switch
//
//  Created by Scott Perry on 07/16/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWHotKey.h"


@implementation SWHotKey

#pragma mark Initialization

+ (SWHotKey *)hotKeyWithKeycode:(unsigned)code modifiers:(unsigned)modifiers;
{
    return [[SWHotKey alloc] initWithKeycode:code modifiers:modifiers];
}

- (instancetype)initWithKeycode:(unsigned int)code modifiers:(unsigned int)modifiers;
{
    if (!(self = [super init])) { return nil; }
    
    _modifiers = modifiers;
    _code = code;
    
    return self;
}

#pragma mark NSObject

- (NSUInteger)hash;
{
    return self.modifiers | self.code;
}

- (BOOL)isEqual:(id)object;
{
    return [self isKindOfClass:[object class]] && [object isKindOfClass:[self class]] && ((SWHotKey *)object).code == self.code && ((SWHotKey *)object).modifiers == self.modifiers;
}

- (instancetype)copyWithZone:(NSZone *)zone;
{
    return self;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%@%u",
            [self modifierDescription],
            self.code];
}

#pragma mark Internal

- (NSString *)modifierDescription;
{
    NSString *result = @"";
    
    if (self.modifiers & SWHotKeyModifierCmd) {
        result = [result stringByAppendingString:@"⌘"];
    }
    if (self.modifiers & SWHotKeyModifierShift) {
        result = [result stringByAppendingString:@"⇧"];
    }
    if (self.modifiers & SWHotKeyModifierOption) {
        result = [result stringByAppendingString:@"⌥"];
    }
    if (self.modifiers & SWHotKeyModifierControl) {
        result = [result stringByAppendingString:@"⌃"];
    }
    
    return result;
}

@end
