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


@implementation SWSelector

#pragma mark - Initialization

- (instancetype)initWithWindowList:(NSOrderedSet *)windowList selectedIndex:(NSInteger)index;
{
    BailUnless(self = [super init], nil);
    
    if ((windowList && !windowList.count) || index == NSNotFound) {
        Check(index == NSNotFound);
        index = NSNotFound;
    } else if (windowList.count) {
        while (index < 0) {
            index += windowList.count;
        }
        if ((NSUInteger)index >= windowList.count) {
            index = index % (NSInteger)windowList.count;
        }
    }
    
    _windowList = windowList;
    _selectedIndex = index;
    _selectedWindow = (NSUInteger)index >= windowList.count ? nil : windowList[(NSUInteger)index];
    
    return self;
}

- (instancetype)init;
{
    return [self initWithWindowList:nil selectedIndex:0];
}

#pragma mark - SWSelector

- (NSUInteger)selectedUIndex;
{
    if (!Check(self.selectedIndex >= 0)) {
        return 0;
    }
    
    return (NSUInteger)self.selectedIndex;
}

- (instancetype)increment;
{
    NSInteger newSelectedIndex = (self.selectedIndex == NSNotFound)
                               ? 0
                               : self.selectedIndex + 1;

    if (self.windowList && !self.windowList.count) {
        Check(self.selectedIndex == NSNotFound);
        return self;
    }
    
    return [[[self class] alloc] initWithWindowList:self.windowList selectedIndex:newSelectedIndex];
}

- (instancetype)incrementWithoutWrapping;
{
    if (!self.windowList) {
        return [self increment];
    }
    
    if (self.selectedUIndex != (self.windowList.count - 1)) {
        return [self increment];
    }
    
    return self;
}

- (instancetype)decrement;
{
    Check(!self.windowList || self.selectedUIndex < self.windowList.count || self.selectedIndex == NSNotFound);

    NSInteger newSelectedIndex = (self.selectedIndex == NSNotFound)
                               ? (NSInteger)self.windowList.count - 1
                               : self.selectedIndex - 1;
    
    if (self.windowList && !self.windowList.count) {
        Check(self.selectedIndex == NSNotFound);
        return self;
    }
    
    return [[[self class] alloc] initWithWindowList:self.windowList selectedIndex:newSelectedIndex];
}

- (instancetype)decrementWithoutWrapping;
{
    if (!self.windowList) {
        return [self decrement];
    }
    
    if (self.selectedIndex != 0) {
        return [self decrement];
    }
    
    return self;
}

- (instancetype)selectIndex:(NSInteger)index;
{
    if (self.windowList) {
        if (!self.windowList.count) {
            Check(self.selectedIndex == NSNotFound);
            Check(index == NSNotFound);
            index = NSNotFound;
        } else if (index > (NSInteger)self.windowList.count) {
            Check(index == NSNotFound);
            index = NSNotFound;
        } else {
            Check(index >= 0);
            index = MAX(index, 0);
            
            Check(index < (NSInteger)self.windowList.count);
            index = MIN(index, (NSInteger)self.windowList.count - 1);
        }
    }
    
    return [[[self class] alloc] initWithWindowList:self.windowList selectedIndex:index];
}

- (instancetype)updateWithWindowList:(NSOrderedSet *)windowList;
{
    // Carry over the current selected index by default.
    NSInteger newSelectedIndex = self.selectedIndex;
    
    if (windowList && !windowList.count) {
        // Empty set? Selected window not found.
        newSelectedIndex = NSNotFound;
    } else if (!Check(windowList) || !self.windowList) {
        newSelectedIndex = self.selectedIndex;
    } else if (self.windowList.count == 0) {
        // Previously empty list? Select the beginning.
        newSelectedIndex = 0;
    } else if ([windowList containsObject:self.selectedWindow]) {
        // Select the same window group as was previously selected, if it's still there.
        newSelectedIndex = (NSInteger)[windowList indexOfObject:self.selectedWindow];
    } else if ((NSInteger)windowList.count <= newSelectedIndex) {
        // Clamp the selected index to the end of the window list.
        newSelectedIndex = (NSInteger)windowList.count - 1;
    }
    
    return [[[self class] alloc] initWithWindowList:windowList selectedIndex:newSelectedIndex];
}

@end
