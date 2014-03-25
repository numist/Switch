//
//  SWEventTap.h
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

#import "SWHotKey.h"


typedef BOOL (^SWEventTapKeyFilter)(CGEventRef event);
typedef void (^SWEventTapModifierCallback)(BOOL matched);
typedef void (^SWEventTapCallback)(CGEventRef event);


@interface SWEventTap : NNService

@property (nonatomic, assign, readwrite) BOOL suppressKeyEvents;

// For key bindings. Block can return NO to stop the event's further propagation.
- (void)registerHotKey:(SWHotKey *)hotKey object:(id)owner block:(SWEventTapKeyFilter)eventFilter;
- (void)removeBlockForHotKey:(SWHotKey *)hotKey object:(id)owner;

// For modifier key state updates. Used to dismiss the interface.
- (void)registerModifier:(SWHotKeyModifierKey)modifiers object:(id)owner block:(SWEventTapModifierCallback)eventCallback;
- (void)removeBlockForModifier:(SWHotKeyModifierKey)modifiers object:(id)owner;

// Primarily for mouse move and scroll events. Used for selector updates..
- (void)registerForEventsWithType:(CGEventType)eventType object:(id)owner block:(SWEventTapCallback)eventCallback;
- (void)removeBlockForEventsWithType:(CGEventType)eventType object:(id)owner;

@end
