//
//  SWEventManager.h
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

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>


@class SWHotKey;
@class SWEventManager;


typedef NS_ENUM(NSUInteger, SWEventManagerEventType) {
    SWEventManagerEventTypeInvoke,
    SWEventManagerEventTypeDismiss,        // You cannot set this, it is bound to the release of all modifiers after a SWEventManagerEventTypeInvoke
    SWEventManagerEventTypeIncrement,      // You cannot set this, it is bound to the same key as SWEventManagerEventTypeInvoke (keyDown)
    SWEventManagerEventTypeEndIncrement,   // You cannot set this, it is bound to the same key as SWEventManagerEventTypeInvoke (keyUp)
    SWEventManagerEventTypeDecrement,
    SWEventManagerEventTypeEndDecrement,   // You cannot set this, it is bound to the same key as SWEventManagerEventTypeDecrement (keyUp)
    SWEventManagerEventTypeCloseWindow,
    SWEventManagerEventTypeCancel,
    SWEventManagerEventTypeShowPreferences,
};


@protocol SWEventManagerSubscriber <NSObject>
@optional

- (oneway void)eventManager:(SWEventManager *)manager didProcessKeyForEventType:(SWEventManagerEventType)eventType;
- (oneway void)eventManagerDidDetectMouseMove:(SWEventManager *)manager;

@end


@interface SWEventManager : NNService

- (void)registerHotKey:(SWHotKey *)hotKey forEvent:(SWEventManagerEventType)eventType;

@end
