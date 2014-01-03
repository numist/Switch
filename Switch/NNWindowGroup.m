//
//  NNWindowGroup.m
//  Switch
//
//  Created by Scott Perry on 12/24/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNWindowGroup.h"

#import "NNWindow.h"


@implementation NNWindowGroup

- (instancetype)initWithWindows:(NSOrderedSet *)windows mainWindow:(NNWindow *)mainWindow;
{
    NSParameterAssert([windows containsObject:mainWindow]);

    if (!(self = [super init])) { return nil; }
    
    _windows = [windows copy];
    _mainWindow = mainWindow;
    
    return self;
}

- (NSUInteger)hash;
{
    return self.mainWindow.windowID;
}

- (BOOL)isEqual:(id)object;
{
    if (![object isKindOfClass:[NNWindowGroup class]]) {
        return NO;
    }
    
    if (![[object windows] isEqual:self.windows]) {
        return NO;
    }
    
    if (![[object mainWindow] isEqual:self.mainWindow]) {
        return NO;
    }
    
    return YES;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%u (%@), %lu windows total>", self.mainWindow.windowID, self.mainWindow.name, self.windows.count];
}

- (NNApplication *)application;
{
    return self.mainWindow.application;
}

- (NSString *)name;
{
    return self.mainWindow.name;
}

- (NSRect)frame;
{
    NSPoint min = self.mainWindow.frame.origin, max = self.mainWindow.frame.origin;
    
    for (NNWindow *window in self.windows) {
        min.x = MIN(min.x, window.frame.origin.x);
        min.y = MIN(min.y, window.frame.origin.y);
        max.x = MAX(max.x, window.frame.origin.x + window.frame.size.width);
        max.y = MAX(max.y, window.frame.origin.y + window.frame.size.height);
    }
    
    return (NSRect){.origin = min, .size.width = max.x - min.x, .size.height = max.y - min.y};
}

@end
