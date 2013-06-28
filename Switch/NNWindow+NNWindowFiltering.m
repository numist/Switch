//
//  NNWindow+NNWindowFiltering.m
//  Switch
//
//  Created by Scott Perry on 06/25/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNWindow+NNWindowFiltering.h"

#import "NNApplication.h"
#import "NNWindowFilter.h"


@implementation NNWindow (NNWindowFiltering)

static NSSet *registeredAppFilters;
static NSSet *registeredAppNames;

+ (NSArray *)filterInvalidWindowsFromArray:(NSArray *)array;
{
    [self setUpApplicationFiltersIfNeeded];
    
    // Collection filters:
    for (NNWindowFilter *filter in registeredAppFilters) {
        array = [filter filterInvalidWindowsFromArray:array];
    }
    
    return [array filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, __attribute__((unused)) NSDictionary *bindings) {
        NNWindow *window = evaluatedObject;
        
        // Skip windows handled by an application-specific filter.
        if ([registeredAppNames containsObject:window.application.name]) {
            return YES;
        }
        
        // Issues #2, #8, #9: Most applications name their valid windows and leave the invalid ones blank.
        if (![window.name length]) {
            return NO;
        }
        
        return YES;
    }]];
}

+ (void)setUpApplicationFiltersIfNeeded;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableSet *filters;
        NSMutableSet *names;
        registeredAppFilters = filters = [NSMutableSet set];
        registeredAppNames = names = [NSMutableSet set];
        
        // Get number of registered classes
        int numClasses = objc_getClassList(NULL, 0);
        
        Class *classes = (__unsafe_unretained Class *)alloca(sizeof(Class) * (unsigned)numClasses);
        (void)objc_getClassList(classes, numClasses);
        
        for (int i = 0; i < numClasses; ++i) {
            Class class = classes[i];
            // Filter first by prefix:
            if (strncmp(class_getName(class), "NN", 2)) { continue; }
            // Then by superclass:
            if (![NNWindowFilter isEqual:[class superclass]]) { continue; }
            
            NNWindowFilter *filter = [class filter];
            [filters addObject:filter];
            // If a filter is application agnostic, it may not return an object for -applicationName
            if (filter.applicationName) {
                [names addObject:filter.applicationName];
            }
        }
    });
}

- (NNVec2)offsetOfCenterToCenterOfWindow:(NNWindow *)window;
{
    NSRect selfBounds = self.cgBounds;
    NSRect windowBounds = window.cgBounds;
    
    return (NNVec2){
        .x = ((windowBounds.origin.x + (windowBounds.size.width / 2.0)) - (selfBounds.origin.x + (selfBounds.size.width / 2.0))),
        .y = ((windowBounds.origin.y + (windowBounds.size.height / 2.0)) - (selfBounds.origin.y + (selfBounds.size.height / 2.0)))
    };
}

- (NSSize)sizeDifferenceFromWindow:(NNWindow *)window;
{
    NSRect selfBounds = self.cgBounds;
    NSRect windowBounds = window.cgBounds;

    return (NSSize){
        .width = selfBounds.size.width - windowBounds.size.width,
        .height = selfBounds.size.height - windowBounds.size.height
    };
}

- (BOOL)enclosedByWindow:(NNWindow *)window;
{
    NNVec2 c2cOffset = [self offsetOfCenterToCenterOfWindow:window];
    NNVec2 absC2COffset = (NNVec2){ .x = fabs(c2cOffset.x), .y = fabs(c2cOffset.y) };
    NSSize sizeDifference = [window sizeDifferenceFromWindow:self];

    return sizeDifference.width > absC2COffset.x * 2.0 && sizeDifference.height > absC2COffset.y * 2.0;
}

- (NNWindow *)nextNamedSiblingFromCollection:(NSArray *)array;
{
    NSUInteger s = [array indexOfObject:self];
    if (s > [array count]) {
        Check(s == NSNotFound);
        return nil;
    }
    
    for (NSUInteger i = s + 1; i < [array count]; ++i) {
        NNWindow *result = array[i];
        
        if (![result.application.name isEqualToString:self.application.name]) {
            return nil;
        }
        
        if ([result.name length]) {
            return result;
        }
    }
    
    return nil;
}

- (NNWindow *)previousNamedSiblingFromCollection:(NSArray *)array;
{
    NSUInteger s = [array indexOfObject:self];
    if (s > [array count]) {
        Check(s == NSNotFound);
        return nil;
    }
    
    for (NSInteger i = (NSInteger)s - 1; i >= 0; --i) {
        NNWindow *result = array[(NSUInteger)i];
        
        if (![result.application.name isEqualToString:self.application.name]) {
            return nil;
        }
        
        if ([result.name length]) {
            return result;
        }
    }
    
    return nil;
}

@end
