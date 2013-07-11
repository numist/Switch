//
//  NNHotKeyManager.m
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
// From alterkeys.c : http://osxbook.com
//

#import "NNHotKeyManager.h"

#include <ApplicationServices/ApplicationServices.h>


@interface NNHotKeyManager () {
    CFMachPortRef eventTap;
    CFRunLoopSourceRef runLoopSource;
}

@property (nonatomic, assign) BOOL activatedSwitcher;

- (CGEventRef)eventTapProxy:(CGEventTapProxy)proxy didReceiveEvent:(CGEventRef)event ofType:(CGEventType)type;

@end


static CGEventRef nnCGEventCallback(CGEventTapProxy proxy, CGEventType type,
                                    CGEventRef event, void *refcon)
{
    return [(__bridge NNHotKeyManager *)refcon eventTapProxy:proxy didReceiveEvent:event ofType:type];
}


@implementation NNHotKeyManager

- (instancetype)init;
{
    self = [super init];
    if (!self) return nil;
    
    NSAssert([[NSThread currentThread] isMainThread], @"%@ must be instanciated on the main thread", [self class]);
    
    if (![self insertEventTap]) {
        return nil;
    }
    
    return self;
}

- (void)dealloc;
{
    [self removeEventTap];
}

- (void)removeEventTap;
{
    if (self->runLoopSource) {
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), self->runLoopSource, kCFRunLoopCommonModes);
        self->runLoopSource = NULL;
    }
    if (self->eventTap) {
        CFRelease(self->eventTap);
        self->eventTap = NULL;
    }
}

- (BOOL)insertEventTap;
{
    // Create an event tap. We are interested in key presses.
    CGEventMask eventMask = (CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp) | CGEventMaskBit(kCGEventFlagsChanged));
    
    self->eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, eventMask, nnCGEventCallback, (__bridge void *)(self));
    BailUnless(self->eventTap, NO);
    
    // Create a run loop source.
    self->runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, self->eventTap, 0);
    BailWithBlockUnless(self->runLoopSource, ^{
        [self removeEventTap];
        return NO;
    });
    
    // Add to the current run loop.
    CFRunLoopAddSource(CFRunLoopGetCurrent(), self->runLoopSource, kCFRunLoopCommonModes);
    
    // Enable the event tap.
    CGEventTapEnable(self->eventTap, true);
    
    return YES;
}

- (CGEventRef)eventTapProxy:(CGEventTapProxy)proxy didReceiveEvent:(CGEventRef)event ofType:(CGEventType)type;
{
    if (type == kCGEventTapDisabledByTimeout) {
        // Re-enable the event tap.
        Log(@"Event tap timed out?!");
        CGEventTapEnable(self->eventTap, true);
    }
    
    if (type == kCGEventTapDisabledByUserInput) {
        NotTested();
    }
    
    // Paranoid sanity check.
    if ((type != kCGEventKeyDown) && (type != kCGEventKeyUp) && (type != kCGEventFlagsChanged))
        return event;
    
    // The incoming keycode and meta key information.
    CGKeyCode keycode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
    BOOL optionKeyIsPressed = (CGEventGetFlags(event) & kCGEventFlagMaskAlternate) == kCGEventFlagMaskAlternate;
    BOOL shiftKeyIsPressed = (CGEventGetFlags(event) & kCGEventFlagMaskShift) == kCGEventFlagMaskShift;
    
    if (optionKeyIsPressed && keycode == 48 && type == kCGEventKeyDown && !self.activatedSwitcher) {
        self.activatedSwitcher = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate hotKeyManagerInvoked:self];
        });
    }
    
    if (self.activatedSwitcher) {
        if (!optionKeyIsPressed) {
            self.activatedSwitcher = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate hotKeyManagerDismissed:self];
            });
            return NULL;
        }
        
        switch (keycode) {
            case 48: { // Tab key
                if (!shiftKeyIsPressed) {
                    if (type == kCGEventKeyDown) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate hotKeyManagerBeginIncrementingSelection:self];
                        });
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate hotKeyManagerEndIncrementingSelection:self];
                        });
                    }
                } else {
                    if (type == kCGEventKeyDown) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate hotKeyManagerBeginDecrementingSelection:self];
                        });
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate hotKeyManagerEndDecrementingSelection:self];
                        });
                    }
                }
                break;
            }
            
            case 13: { // W key
                if (type == kCGEventKeyDown) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.delegate hotKeyManagerClosedWindow:self];
                    });
                }
                break;
            }
                
            case 12: { // Q key
                if (type == kCGEventKeyDown) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.delegate hotKeyManagerClosedApplication:self];
                    });
                }
                break;
            }
                
            default:
                break;
        }
        return NULL;
    }
    
    // We must return the event to avoid deleting it.
    return event;
}

@end
