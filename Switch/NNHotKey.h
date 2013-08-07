//
//  NNHotKey.h
//  Switch
//
//  Created by Scott Perry on 07/16/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NNHotKey : NSObject <NSCopying>

@property (nonatomic, readonly) unsigned code;
@property (nonatomic, readonly) unsigned modifiers;

- (instancetype)initWithKeycode:(unsigned)code modifiers:(unsigned)modifiers;

@end
