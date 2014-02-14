//
//  SWEventTap.m
//  Switch
//
//  Created by Scott Perry on 02/13/14.
//  Copyright © 2014 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// Inspiration from alterkeys.c : http://osxbook.com
//

#import "SWEventTap.h"

#import <NNKit/NNService+Protected.h>

#import "SWAPIEnabledWorker.h"
#import "SWHotKey.h"
#import "NSNotificationCenter+RACSupport.h"


@interface SWEventTap ()

@property (nonatomic, assign, readwrite) CFMachPortRef eventTap;
@property (nonatomic, assign, readwrite) SWHotKeyModifierKey modifiers;
@property (nonatomic, assign, readwrite) CFRunLoopSourceRef runLoopSource;

@property (nonatomic, strong, readonly) NSMutableDictionary *eventTypeCallbacks;
@property (nonatomic, strong, readonly) NSMutableDictionary *modifierCallbacks;
@property (nonatomic, strong, readonly) NSMutableDictionary *keyFilters;

@end

static CGEventRef eventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon);

@implementation SWEventTap

- (instancetype)init;
{
    if (!(self = [super init])) { return nil; }
    
    _eventTypeCallbacks = [NSMutableDictionary new];
    _modifierCallbacks = [NSMutableDictionary new];
    _keyFilters = [NSMutableDictionary new];
    
    return self;
}

- (void)dealloc;
{
    [self _removeEventTap];
}

#pragma mark NNService

- (NNServiceType)serviceType;
{
    return NNServiceTypePersistent;
}

- (void)startService;
{
    [super startService];
    
    [self _insertEventTap];
}

- (void)stopService;
{
    [self _removeEventTap];
    
    [super stopService];
}

#pragma mark SWEventTap

- (void)registerHotKey:(SWHotKey *)hotKey withBlock:(SWEventTapKeyFilter)eventFilter;
{
    NSAssert([[NSThread currentThread] isMainThread], @"%@ must be called from the main thread", [self class]);

    if (!self.keyFilters[hotKey]) {
        self.keyFilters[hotKey] = [NSMutableArray new];
    }
    
    [self.keyFilters[hotKey] addObject:eventFilter];
}

- (void)registerModifier:(SWHotKeyModifierKey)modifiers withBlock:(SWEventTapModifierCallback)eventCallback;
{
    NSAssert([[NSThread currentThread] isMainThread], @"%@ must be called from the main thread", [self class]);

    if (!self.modifierCallbacks[@(modifiers)]) {
        self.modifierCallbacks[@(modifiers)] = [NSMutableArray new];
    }
    
    [self.modifierCallbacks[@(modifiers)] addObject:eventCallback];
}

- (void)registerForEventsWithType:(CGEventType)eventType withBlock:(SWEventTapCallback)eventCallback;
{
    NSAssert([[NSThread currentThread] isMainThread], @"%@ must be called from the main thread", [self class]);

    if (!self.eventTypeCallbacks[@(eventType)]) {
        self.eventTypeCallbacks[@(eventType)] = [NSMutableArray new];
    }
    
    [self.eventTypeCallbacks[@(eventType)] addObject:eventCallback];
}

#pragma mark Internal

// Called from dealloc, use direct ivar access.
- (void)_removeEventTap;
{
    if (self->_runLoopSource) {
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), self->_runLoopSource, kCFRunLoopCommonModes);
        self->_runLoopSource = NULL;
    }
    if (self->_eventTap) {
        CFRelease(self->_eventTap);
        self->_eventTap = NULL;
    }
}

- (BOOL)_insertEventTap;
{
    Assert(!self.eventTap);
    
    self.modifiers = 0;
    
    // Create an event tap. For now the list of event types is limited to mouse & keyboard events.
    CGEventMask eventMask = (CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp) | CGEventMaskBit(kCGEventFlagsChanged) | CGEventMaskBit(kCGEventMouseMoved) | CGEventMaskBit(kCGEventScrollWheel));
    
    self.eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, eventMask, eventCallback, (__bridge void *)(self));
    BailUnless(self.eventTap, NO);
    
    // Create a run loop source.
    self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, self.eventTap, 0);
    BailWithBlockUnless(self.runLoopSource, ^{
        [self _removeEventTap];
        return NO;
    });
    
    // Add to the current run loop.
    CFRunLoopAddSource(CFRunLoopGetCurrent(), self.runLoopSource, kCFRunLoopCommonModes);
    
    // Enable the event tap.
    CGEventTapEnable(self.eventTap, true);
    
    return YES;
}

static CGEventRef eventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
{
    #if DEBUG
        Check([NSThread isMainThread]);
    #endif
    
    SWEventTap *eventTap = (__bridge SWEventTap *)refcon;

    //
    // Event tap administration
    //
    if (type == kCGEventTapDisabledByTimeout) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Re-enable the event tap.
            SWLog(@"Event tap timed out?!");
            CGEventTapEnable(eventTap.eventTap, true);
        });
        return event;
    } else if (type == kCGEventTapDisabledByUserInput) {
        NotTested();
        return event;
    }
    
    //
    // Event type callbacks.
    //
    for (SWEventTapCallback callback in eventTap.eventTypeCallbacks[@(type)]) {
        callback(event);
    }
    
    // Escape if the event is not a key/modifier change event.
    if ((type != kCGEventKeyDown) && (type != kCGEventKeyUp) && (type != kCGEventFlagsChanged)) {
        return event;
    }

    //
    // Modifier key callbacks.
    //
    SWHotKey *key = [SWHotKey hotKeyFromEvent:event];
    if (type == kCGEventFlagsChanged) {
        SWHotKeyModifierKey flagChanges = key.modifiers ^ eventTap.modifiers;
        for (NSNumber *boxedRegisteredModifiers in eventTap.modifierCallbacks) {
            SWHotKeyModifierKey registeredModifiers = boxedRegisteredModifiers.unsignedIntValue;
            
            // Changes can't affect registrant.
            if (!(flagChanges & registeredModifiers)) continue;
            
            // Changes didn't affect registrant
            BOOL matched = (eventTap.modifiers & registeredModifiers) == registeredModifiers;
            BOOL matches = (key.modifiers & registeredModifiers) == registeredModifiers;
            if (matched == matches) continue;
            
            for (SWEventTapModifierCallback callback in eventTap.modifierCallbacks[boxedRegisteredModifiers]) {
                callback(matches);
            }
        }
        
        eventTap.modifiers = key.modifiers;
        
        return event;
    }
    
    //
    // Hotkey callbacks.
    //
    
    for (SWEventTapKeyFilter filter in eventTap.keyFilters[key]) {
        if (!filter(type == kCGEventKeyDown)) {
            event = NULL;
            break;
        }
    }

    return event;
}


@end
