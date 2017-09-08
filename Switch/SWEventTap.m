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
    BailUnless(self = [super init], nil);
    
    _eventTypeCallbacks = [NSMutableDictionary new];
    _modifierCallbacks = [NSMutableDictionary new];
    _keyFilters = [NSMutableDictionary new];
    
    return self;
}

- (void)dealloc;
{
    [self private_removeEventTap];
}

#pragma mark - NNService

+ (NNServiceType)serviceType;
{
    return NNServiceTypePersistent;
}

- (void)startService;
{
    [super startService];
    
    [self private_insertEventTap];
}

- (void)stopService;
{
    [self private_removeEventTap];
    
    [super stopService];
}

#pragma mark - SWEventTap

- (void)registerHotKey:(SWHotKey *)hotKey object:(id)owner block:(SWEventTapKeyFilter)eventFilter;
{
    SWLogMainThreadOnly();

    if (!self.keyFilters[hotKey]) {
        self.keyFilters[hotKey] = [NSMutableDictionary new];
    }
    
    NSNumber *ownerKey = @((uintptr_t)owner);
    
    // I don't love this limitation, but removing it is complicated and enables questionable functionality anyway.
    Assert(!self.keyFilters[hotKey][ownerKey]);
    
    [self.keyFilters[hotKey] setObject:eventFilter forKey:ownerKey];
}

- (void)removeBlockForHotKey:(SWHotKey *)hotKey object:(id)owner;
{
    [self.keyFilters[hotKey] removeObjectForKey:@((uintptr_t)owner)];
}

- (void)registerModifier:(SWHotKeyModifierKey)modifiers object:(id)owner block:(SWEventTapModifierCallback)eventCallback;
{
    SWLogMainThreadOnly();

    if (!self.modifierCallbacks[@(modifiers)]) {
        self.modifierCallbacks[@(modifiers)] = [NSMutableDictionary new];
    }
    
    NSNumber *ownerKey = @((uintptr_t)owner);
    
    // I don't love this limitation, but removing it is complicated and enables questionable functionality anyway.
    Assert(!self.modifierCallbacks[@(modifiers)][ownerKey]);
    
    [self.modifierCallbacks[@(modifiers)] setObject:eventCallback forKey:@((uintptr_t)owner)];
}

- (void)removeBlockForModifier:(SWHotKeyModifierKey)modifiers object:(id)owner;
{
    [self.modifierCallbacks[@(modifiers)] removeObjectForKey:@((uintptr_t)owner)];
}

- (void)registerForEventsWithType:(CGEventType)eventType object:(id)owner block:(SWEventTapCallback)eventCallback;
{
    SWLogMainThreadOnly();

    if (!self.eventTypeCallbacks[@(eventType)]) {
        self.eventTypeCallbacks[@(eventType)] = [NSMutableDictionary new];
    }
    
    NSNumber *ownerKey = @((uintptr_t)owner);
    
    // I don't love this limitation, but removing it is complicated and enables questionable functionality anyway.
    Assert(!self.eventTypeCallbacks[@(eventType)][ownerKey]);
    
    [self.eventTypeCallbacks[@(eventType)] setObject:eventCallback forKey:@((uintptr_t)owner)];
}

- (void)removeBlockForEventsWithType:(CGEventType)eventType object:(id)owner;
{
    [self.eventTypeCallbacks[@(eventType)] removeObjectForKey:@((uintptr_t)owner)];
}

#pragma mark - Internal

// Called from dealloc, use direct ivar access.
- (void)private_removeEventTap;
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

- (BOOL)private_insertEventTap;
{
    Assert(!self.eventTap);
    
    self.modifiers = 0;
    
    // Create an event tap. For now the list of event types is limited to mouse & keyboard events.
    CGEventMask eventMask = (
        CGEventMaskBit(kCGEventKeyDown) |
        CGEventMaskBit(kCGEventKeyUp) |
        CGEventMaskBit(kCGEventFlagsChanged) |
        CGEventMaskBit(kCGEventMouseMoved) |
        CGEventMaskBit(kCGEventScrollWheel) |
    0);
    
    self.eventTap = CGEventTapCreate(kCGAnnotatedSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, eventMask, eventCallback, (__bridge void *)(self));
    BailUnless(self.eventTap, NO);
    
    // Create a run loop source.
    // XXX: why does calling the property setter here tickle the static analyzer the wrong way, but setting the ivar directly doesn't?
    self->_runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, self.eventTap, 0);
    BailWithBlockUnless(self.runLoopSource, ^{
        [self private_removeEventTap];
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
    Assert([NSThread isMainThread]);
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
    for (SWEventTapCallback callback in [eventTap.eventTypeCallbacks[@(type)] allValues]) {
        callback(event);
    }
    
    // Prevent other applications from receiving scroll events when the application is consuming keyboard events.
    if (type == kCGEventScrollWheel) {
        return eventTap.suppressKeyEvents ? NULL : event;
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
            
            for (SWEventTapModifierCallback callback in [eventTap.modifierCallbacks[boxedRegisteredModifiers] allValues]) {
                callback(matches);
            }
        }
        
        eventTap.modifiers = key.modifiers;
        
        return event;
    }
    
    //
    // Hotkey callbacks.
    //
    
    for (SWEventTapKeyFilter filter in [eventTap.keyFilters[key] allValues]) {
        if (!filter(event)) {
            event = NULL;
            break;
        }
    }

    return eventTap.suppressKeyEvents ? NULL : event;
}


@end
