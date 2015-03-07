//
//  SWWindow.m
//  Switch
//
//  Created by Scott Perry on 02/21/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWWindow.h"
#import "SWWindow+TweetbotQuirks.h"

#import <Haxcessibility/HAXElement+Protected.h>
#import <Haxcessibility/Haxcessibility.h>

#import "NSScreen+SWAdditions.h"
#import "SWApplication.h"


@implementation SWWindow

#pragma mark - Initialization

+ (instancetype)windowWithDescription:(NSDictionary *)description;
{
    return [[self alloc] initWithDescription:description];
}

- (instancetype)initWithDescription:(NSDictionary *)description;
{
    BailUnless(self = [super init], nil);
    
    if (!description) {
        return nil;
    }

    _windowDescription = [description copy];
    _application = [SWApplication applicationWithPID:[[self.windowDescription objectForKey:(NSString *)kCGWindowOwnerPID] intValue] name:[self.windowDescription objectForKey:(NSString *)kCGWindowOwnerName]];
    
    return self;
}

#pragma mark - NSObject

- (instancetype)copyWithZone:(NSZone *)zone;
{
    Check(!zone);
    return self;
}

- (NSUInteger)hash;
{
    return self.windowID;
}

- (BOOL)isEqual:(id)object;
{
    return ([object isKindOfClass:[self class]] && [[self windowDescription] isEqual:[object windowDescription]]);
}

- (BOOL)isSameWindow:(SWWindow *)window;
{
    if (window.windowID != self.windowID) {
        return NO;
    }
    
    if (![window.application.name isEqualToString:self.application.name]) {
        return NO;
    }
    
    return YES;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%p <%u (%@)>", self, self.windowID, self.name];
}

#pragma mark - SWWindow

- (CGRect)flippedFrame;
{
    CGRect result = {{},{}};
    bool success = CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)[self.windowDescription objectForKey:(NSString *)kCGWindowBounds], &result);
    BailUnless(success, ((CGRect){{0.0,0.0},{0.0,0.0}}));
    return result;
}

- (CGRect)frame;
{
    CGFloat totalScreenHeight = NSScreen.sw_totalScreenHeight;
    CGRect flippedFrame = self.flippedFrame;
    flippedFrame.origin.y = totalScreenHeight - (flippedFrame.origin.y + flippedFrame.size.height);
    return flippedFrame;
}

- (NSString *)name;
{
    return [self.windowDescription objectForKey:(__bridge NSString *)kCGWindowName];
}

- (NSScreen *)screen;
{
    CGRect cgFrame = self.flippedFrame;
    
    return [[NSScreen screens] nn_reduce:^id(NSScreen *accumulator, NSScreen *item) {
        if (!accumulator) {
            accumulator = [NSScreen mainScreen];
        }
        
        CGFloat (^overlapWithScreen)(NSScreen *) = ^(NSScreen *screen) {
            CGDirectDisplayID displayID = [screen.deviceDescription[@"NSScreenNumber"] unsignedIntValue];
            CGRect displayRect = CGDisplayBounds(displayID);
            CGRect intersection = CGRectIntersection(displayRect, cgFrame);
            return intersection.size.width * intersection.size.height;
        };

        if (overlapWithScreen(item) > overlapWithScreen(accumulator)) {
            return item;
        } else {
            return accumulator;
        }
    }];
}

- (CGWindowID)windowID;
{
    return (CGWindowID)[[self.windowDescription objectForKey:(__bridge NSString *)kCGWindowNumber] unsignedLongValue];
}

- (BOOL)isRelatedToLowerWindow:(SWWindow *)window;
{
    NSParameterAssert(window.application.canBeActivated);
    
    // Powerbox (for example) names its windows, but cannot be activated.
    if (!self.application.canBeActivated) {
        return YES;
    }
    
    // Windows belonging to different applications are unrelated.
    if (![self.application isEqual:window.application]) {
        return NO;
    }

    // Named windows are (usually) main windows themselves
    if (self.name.length && window.name.length) {
        return NO;
    }
    
    // This is a special case for catching the shadow opening for sheets
    if (self.frame.size.height < 20.0 && [self.windowDescription[(__bridge NSString *)kCGWindowAlpha] floatValue] < 1.0) {
        return YES;
    }
    
    if ([self.application.name isEqualToString:@"Tweetbot"]) {
        return [self tweetbot_isRelatedToLowerWindow:window];
    } else if ([self.application.name isEqualToString:@"MacVim"]) {
        // MacVim isn't known to have any extraneous unnamed windows… yet?
        return NO;
    }
    
    if (![self enclosedByWindow:window]) {
        return NO;
    }
    
    return YES;
}

- (NNVec2)offsetOfCenterToCenterOfWindow:(SWWindow *)window;
{
    CGRect selfBounds = self.frame;
    CGRect windowBounds = window.frame;
    
    return (NNVec2){
        .x = ((windowBounds.origin.x + (windowBounds.size.width / 2.0)) - (selfBounds.origin.x + (selfBounds.size.width / 2.0))),
        .y = ((windowBounds.origin.y + (windowBounds.size.height / 2.0)) - (selfBounds.origin.y + (selfBounds.size.height / 2.0)))
    };
}

- (NSSize)sizeDifferenceFromWindow:(SWWindow *)window;
{
    CGRect selfBounds = self.frame;
    CGRect windowBounds = window.frame;
    
    return (NSSize){
        .width = selfBounds.size.width - windowBounds.size.width,
        .height = selfBounds.size.height - windowBounds.size.height
    };
}

- (BOOL)enclosedByWindow:(SWWindow *)window;
{
    return CGRectContainsRect(window.frame, self.frame);
}

@end
