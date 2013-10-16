//
//  NNEventManager.m
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

#import "NNEventManager.h"

#include <ApplicationServices/ApplicationServices.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

#import "NNHotKey.h"
#import "NNCoreWindowController.h"
#import "NSNotificationCenter+RACSupport.h"


NSString *NNEventManagerMouseNotificationName = @"NNEventManagerMouseNotificationName";
NSString *NNEventManagerKeyNotificationName = @"NNEventManagerEventNotificationName";
NSString *NNEventManagerEventTypeKey = @"eventType";
NSString *NNEventManagerEventMouseLocationKey = @"mouseLocation";


static NSSet *kNNKeysUnsettable;
static NSDictionary *kNNKeysNeedKeyUpEvent;


@interface NNEventManager () {
    CFMachPortRef eventTap;
    CFRunLoopSourceRef runLoopSource;
}

@property (nonatomic, assign) BOOL activatedSwitcher;

@property (nonatomic, strong, readonly) NSMutableDictionary *keyMap;

- (CGEventRef)eventTapProxy:(CGEventTapProxy)proxy didReceiveEvent:(CGEventRef)event ofType:(CGEventType)type;

@end


static CGEventRef nnCGEventCallback(CGEventTapProxy proxy, CGEventType type,
                                    CGEventRef event, void *refcon)
{
    return [(__bridge NNEventManager *)refcon eventTapProxy:proxy didReceiveEvent:event ofType:type];
}


@implementation NNEventManager

+ (void)initialize;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kNNKeysUnsettable = [NSSet setWithArray:@[ @(NNEventManagerEventTypeIncrement), @(NNEventManagerEventTypeEndIncrement), @(NNEventManagerEventTypeEndDecrement)]];
        kNNKeysNeedKeyUpEvent = @{
            @(NNEventManagerEventTypeIncrement) : @(NNEventManagerEventTypeEndIncrement),
            @(NNEventManagerEventTypeDecrement) : @(NNEventManagerEventTypeEndDecrement)
        };
    });
}

+ (NNEventManager *)sharedManager;
{
    static NNEventManager *_singleton;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _singleton = [NNEventManager new];
    });
    
    return _singleton;
}

- (instancetype)init;
{
    if (!(self = [super init])) { return nil; }
    
    NSAssert([[NSThread currentThread] isMainThread], @"%@ must be instanciated on the main thread", [self class]);
    
    if (![self insertEventTap]) {
        return nil;
    }
    
    _keyMap = [NSMutableDictionary new];
    
    RAC(self, activatedSwitcher) = [[NSNotificationCenter.defaultCenter
        rac_addObserverForName:(NSString *)NNCoreWindowControllerActivityNotification object:nil]
        map:^(NSNotification *notification) {
            return notification.userInfo[NNCoreWindowControllerActiveKey];
        }];
    
    return self;
}

- (void)dealloc;
{
    [self removeEventTap];
}

- (void)registerHotKey:(NNHotKey *)hotKey forEvent:(NNEventManagerEventType)eventType;
{
    if ([kNNKeysUnsettable containsObject:@(eventType)]) {
        @throw [NSException exceptionWithName:@"NNEventManagerRegistrationException" reason:@"That keybinding cannot be set, try setting it's parent?" userInfo:@{ NNEventManagerEventTypeKey : @(eventType), @"key" : hotKey }];
    }
    
    [self.keyMap setObject:@(eventType) forKey:hotKey];
}

#pragma mark Internal

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
    CGEventMask eventMask = (CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp) | CGEventMaskBit(kCGEventFlagsChanged) | CGEventMaskBit(kCGEventMouseMoved));
    
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
    BOOL switcherActive = self.activatedSwitcher;
    
    if (type == kCGEventTapDisabledByTimeout) {
        // Re-enable the event tap.
        NNLog(@"Event tap timed out?!");
        CGEventTapEnable(self->eventTap, true);
    }
    
    if (type == kCGEventTapDisabledByUserInput) {
        NotTested();
    }
    
    if (switcherActive && type == kCGEventMouseMoved) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:NNEventManagerMouseNotificationName object:self userInfo:@{
                NNEventManagerEventTypeKey : @(NNEventManagerMouseEventTypeMove),
                NNEventManagerEventMouseLocationKey : [NSValue valueWithPoint:[NSEvent mouseLocation]]
            }];
        });
        return event;
    }
    
    // Paranoid sanity check.
    if ((type != kCGEventKeyDown) && (type != kCGEventKeyUp) && (type != kCGEventFlagsChanged)) {
        return event;
    }
    
    // Parse the incoming keycode and modifier key information.
    CGKeyCode keycode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
    
    __typeof__(NNHotKeyModifierKey) modifiers = 0;
    if ((CGEventGetFlags(event) & kCGEventFlagMaskAlternate) == kCGEventFlagMaskAlternate) {
        modifiers |= NNHotKeyModifierOption;
    }
    if ((CGEventGetFlags(event) & kCGEventFlagMaskShift) == kCGEventFlagMaskShift) {
        modifiers |= NNHotKeyModifierShift;
    }
    if ((CGEventGetFlags(event) & kCGEventFlagMaskControl) == kCGEventFlagMaskControl) {
        modifiers |= NNHotKeyModifierControl;
    }
    if ((CGEventGetFlags(event) & kCGEventFlagMaskCommand) == kCGEventFlagMaskCommand) {
        modifiers |= NNHotKeyModifierCmd;
    }
    
    NNHotKey *key = [NNHotKey hotKeyWithKeycode:keycode modifiers:modifiers];
    
    // Invocation is a special case, enabling all other keys
    if (!switcherActive && type == kCGEventKeyDown) {
        NSArray *invokeKeys = [self.keyMap allKeysForObject:@(NNEventManagerEventTypeInvoke)];
        for (NNHotKey *hotKey in invokeKeys) {
            if (hotKey.code == keycode && hotKey.modifiers == modifiers) {
                switcherActive = YES;
                [self dispatchEvent:NNEventManagerEventTypeInvoke];
                break;
            }
        }
    }
    
    if (switcherActive) {
        if (!modifiers) {
            [self dispatchEvent:NNEventManagerEventTypeDismiss];
            return NULL;
        }
        
        NSNumber *boxedKeyDownEventType = self.keyMap[key];
        // Invoke maps to Increment at this point
        if (boxedKeyDownEventType && [boxedKeyDownEventType unsignedIntegerValue] == NNEventManagerEventTypeInvoke) {
            boxedKeyDownEventType = @(NNEventManagerEventTypeIncrement);
        }

        // Prefetch keyup event, if applicable.
        NSNumber *boxedKeyUpEventType = nil;
        if (type == kCGEventKeyUp) {
            boxedKeyUpEventType = kNNKeysNeedKeyUpEvent[boxedKeyDownEventType];
        }
        
        if (boxedKeyDownEventType) {
            if (type == kCGEventKeyDown) {
                [self dispatchEvent:[boxedKeyDownEventType unsignedIntegerValue]];
            } else if (boxedKeyUpEventType) {
                [self dispatchEvent:[boxedKeyUpEventType unsignedIntegerValue]];
            }
        }
        
        event = NULL;
    }
    
    return event;
}

- (void)dispatchEvent:(NNEventManagerEventType)eventType;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:NNEventManagerKeyNotificationName object:self userInfo:@{ NNEventManagerEventTypeKey : @(eventType) }];
    });
}

@end
