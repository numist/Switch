//
//  NNHotKey.m
//  Switch
//
//  Created by Scott Perry on 07/16/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNHotKey.h"


@implementation NNHotKey

- (instancetype)initWithKeycode:(unsigned int)code modifiers:(unsigned int)modifiers;
{
    self = [super init];
    if (!self) return nil;
    
    _modifiers = modifiers;
    _code = code;
    
    return self;
}

- (NSUInteger)hash;
{
    return self.modifiers | self.code;
}

- (BOOL)isEqual:(id)object;
{
    return [self isKindOfClass:[object class]] && [object isKindOfClass:[self class]] && ((NNHotKey *)object).code == self.code && ((NNHotKey *)object).modifiers == self.modifiers;
}

- (instancetype)copyWithZone:(NSZone *)zone;
{
    return self;
}

- (NSString *)modifierDescription;
{
    NSString *result = @"";
    
    if (self.modifiers & NNHotKeyModifierCmd) {
        result = [result stringByAppendingString:@"⌘"];
    }
    if (self.modifiers & NNHotKeyModifierShift) {
        result = [result stringByAppendingString:@"⇧"];
    }
    if (self.modifiers & NNHotKeyModifierOption) {
        result = [result stringByAppendingString:@"⌥"];
    }
    if (self.modifiers & NNHotKeyModifierControl) {
        result = [result stringByAppendingString:@"⌃"];
    }
    
    return result;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%@%u",
            [self modifierDescription],
            self.code];
}

@end
