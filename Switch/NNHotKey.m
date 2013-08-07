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

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%u + %u", self.code, self.modifiers];
//    return [NSString stringWithFormat:@"%@%@", NNStringForModifierKeys(self.modifiers), NNStringForKeycode(self.code)];
}

@end
