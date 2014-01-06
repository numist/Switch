//
//  SWSelector.m
//  Switch
//
//  Created by Scott Perry on 01/05/14.
//  Copyright © 2014 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWSelector.h"


@interface SWSelector ()

@property (nonatomic, copy, readonly) NSOrderedSet *windowGroups;

@end


@implementation SWSelector

#pragma mark - NSObject

- (instancetype)initWithWindowGroups:(NSOrderedSet *)windowGroups selectedIndex:(NSInteger)index;
{
    if (!(self = [super init])) { return nil; }
    
    if (windowGroups && !windowGroups.count) {
        Check(index == NSNotFound);
        index = NSNotFound;
    } else if (windowGroups.count) {
        while (!Check(index >= 0)) {
            index += windowGroups.count;
        }
        if(!Check((NSUInteger)index < windowGroups.count)) {
            index = (NSInteger)windowGroups.count - 1;
        }
    }
    
    _windowGroups = windowGroups;
    _selectedIndex = index;
    _selectedWindowGroup = (NSUInteger)index >= windowGroups.count ? nil : windowGroups[(NSUInteger)index];
    
    return self;
}

- (instancetype)init;
{
    return [self initWithWindowGroups:nil selectedIndex:0];
}

#pragma mark - SWSelector

- (instancetype)increment;
{
    NSInteger newSelectedIndex = self.selectedIndex + 1;
    
    if (self.windowGroups) {
        if (!self.windowGroups.count) {
            Check(self.selectedIndex == NSNotFound);
            return self;
        }
        
        if (newSelectedIndex >= self.windowGroups.count) {
            newSelectedIndex %= self.windowGroups.count;
            
            Check(newSelectedIndex == 0);
        }
    }
    
    return [[[self class] alloc] initWithWindowGroups:self.windowGroups selectedIndex:newSelectedIndex];
}

- (instancetype)incrementWithoutWrapping;
{
    if (!self.windowGroups) {
        return [self increment];
    }
    
    if (self.selectedIndex < (self.windowGroups.count - 1)) {
        return [self increment];
    }
    
    return self;
}

- (instancetype)decrement;
{
    Check(!self.windowGroups || self.selectedIndex < self.windowGroups.count);

    NSInteger newSelectedIndex = self.selectedIndex - 1;
    
    if (self.windowGroups) {
        if (!self.windowGroups.count) {
            Check(self.selectedIndex == NSNotFound);
            return self;
        }
        
        while (newSelectedIndex < 0) {
            newSelectedIndex += self.windowGroups.count;
            
            Check(newSelectedIndex == (NSInteger)self.windowGroups.count - 1);
        }
    }
    
    return [[[self class] alloc] initWithWindowGroups:self.windowGroups selectedIndex:newSelectedIndex];
}

- (instancetype)decrementWithoutWrapping;
{
    if (!self.windowGroups) {
        return [self decrement];
    }
    
    if (self.selectedIndex > 0) {
        return [self decrement];
    }
    
    return self;
}

- (instancetype)updateWithWindowGroups:(NSOrderedSet *)windowGroups;
{
    NSInteger newSelectedIndex = self.selectedIndex;
    
    if (!windowGroups) {
        return [[[self class] alloc] initWithWindowGroups:windowGroups selectedIndex:self.selectedIndex];
    }
    
    if (!windowGroups.count) {
        return [[[self class] alloc] initWithWindowGroups:windowGroups selectedIndex:NSNotFound];
    }
    
    if (!self.windowGroups) {
        if (newSelectedIndex < 0) {
            do {
                newSelectedIndex += windowGroups.count;
            } while (newSelectedIndex < 0);
        }
        newSelectedIndex = (NSInteger)((NSUInteger)newSelectedIndex % windowGroups.count);
    } else if (self.windowGroups.count == 0) {
        newSelectedIndex = 0;
    } else if ([windowGroups containsObject:self.selectedWindowGroup]) {
        newSelectedIndex = (NSInteger)[windowGroups indexOfObject:self.selectedWindowGroup];
    } else if ((NSInteger)windowGroups.count <= newSelectedIndex) {
        newSelectedIndex = (NSInteger)windowGroups.count - 1;
    }
    
    return [[[self class] alloc] initWithWindowGroups:windowGroups selectedIndex:newSelectedIndex];
}

@end
