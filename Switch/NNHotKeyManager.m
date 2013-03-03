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


@interface NNHotKeyManager ()

@property (nonatomic, assign) CFMachPortRef eventTap;
@property (nonatomic, assign) CFRunLoopSourceRef runLoopSource;
@property (nonatomic, assign) BOOL activatedSwitcher;

- (CGEventRef)eventTapProxy:(CGEventTapProxy)proxy didReceiveEvent:(CGEventRef)event ofType:(CGEventType)type;

@end


static CGEventRef nnCGEventCallback(CGEventTapProxy proxy, CGEventType type,
                                    CGEventRef event, void *refcon)
{
    return event;
//    return [(__bridge NNHotKeyManager *)refcon eventTapProxy:proxy didReceiveEvent:event ofType:type];
}


@implementation NNHotKeyManager

- (instancetype)init;
{
    self = [super init];
    if (!self) return nil;
    
    if (![[NSThread currentThread] isMainThread]) {
        NSLog(@"%@ must be instanciated on the main thread", [self class]);
        return nil;
    }
    
    // Create an event tap. We are interested in key presses.
    CGEventMask        eventMask;
    eventMask = (CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp) | CGEventMaskBit(kCGEventFlagsChanged));
    _eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, eventMask, nnCGEventCallback, (__bridge void *)(self));
    if (!_eventTap) {
        return nil;
    }
    
    // Create a run loop source.
    _runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, self.eventTap, 0);
    
    // Add to the current run loop.
    CFRunLoopAddSource(CFRunLoopGetCurrent(), _runLoopSource, kCFRunLoopCommonModes);
    
    // Enable the event tap.
    CGEventTapEnable(self.eventTap, true);
    
    return self;
}

- (void)dealloc;
{
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), _runLoopSource, kCFRunLoopCommonModes);
    CFRelease(_eventTap);
}

- (CGEventRef)eventTapProxy:(CGEventTapProxy)proxy didReceiveEvent:(CGEventRef)event ofType:(CGEventType)type;
{
    // Paranoid sanity check.
    if ((type != kCGEventKeyDown) && (type != kCGEventKeyUp) && (type != kCGEventFlagsChanged))
        return event;
    
    // The incoming keycode and meta key information.
    CGKeyCode keycode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
    BOOL commandKeyIsPressed = (CGEventGetFlags(event) & kCGEventFlagMaskCommand) == kCGEventFlagMaskCommand;
    BOOL shiftKeyIsPressed = (CGEventGetFlags(event) & kCGEventFlagMaskShift) == kCGEventFlagMaskShift;
    
    if (commandKeyIsPressed && keycode == 48 && type == kCGEventKeyDown && !self.activatedSwitcher) {
        self.activatedSwitcher = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            //            [NSApp postEvent:<#(NSEvent *)#> atStart:<#(BOOL)#>];
            NSLog(@"RELEZSE THE KRZKEN!");
        });
        return NULL;
    } else if (!commandKeyIsPressed && self.activatedSwitcher) {
        self.activatedSwitcher = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            //            [NSApp postEvent:<#(NSEvent *)#> atStart:<#(BOOL)#>];
            NSLog(@"RECALL THE KRAKEN!");
        });
        return NULL;
    } else if (self.activatedSwitcher) {
        if (keycode == 48) {
            if (type == kCGEventKeyDown) {
                if (!shiftKeyIsPressed) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //                    [NSApp postEvent:￼ atStart:￼];
                        NSLog(@"ITERATE THE KRAKEN!");
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //                    [NSApp postEvent:￼ atStart:￼];
                        NSLog(@"ITERATE THE KRAKEN BACKWARDS!");
                    });
                }
            }
        }
        return NULL;
    }
    
    // We must return the event to avoid deleting it.
    return event;
}



// AXUIElementPerformAction(rbx, @"AXRaise");
// then determine space, if appropriate (it's not!) and switch to it
// if !GetCurrentProcess == window's process
// SetFrontProcessWithOptions(thing, 0x1)
// BOOM












@end
