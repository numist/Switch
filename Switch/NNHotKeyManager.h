//
//  NNHotKeyManager.h
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


@class NNHotKey;
@protocol NNHotKeyManagerDelegate;


typedef NS_ENUM(NSUInteger, NNHotKeyManagerEventType) {
    NNHotKeyManagerEventTypeInvoke,
    NNHotKeyManagerEventTypeDismiss,        // You cannot set this, it is bound to the release of all modifiers after a NNHotKeyManagerEventTypeInvoke
    NNHotKeyManagerEventTypeIncrement,      // You cannot set this, it is bound to the same key as NNHotKeyManagerEventTypeInvoke (keyDown)
    NNHotKeyManagerEventTypeEndIncrement,   // You cannot set this, it is bound to the same key as NNHotKeyManagerEventTypeInvoke (keyUp)
    NNHotKeyManagerEventTypeDecrement,
    NNHotKeyManagerEventTypeEndDecrement,   // You cannot set this, it is bound to the same key as NNHotKeyManagerEventTypeDecrement (keyUp)
    NNHotKeyManagerEventTypeCloseWindow,
};


extern NSString *NNHotKeyManagerNotificationName;
extern NSString *NNHotKeyManagerEventTypeKey;


@interface NNHotKeyManager : NSObject

+ (NNHotKeyManager *)sharedManager;

- (void)registerHotKey:(NNHotKey *)hotKey forEvent:(NNHotKeyManagerEventType)eventType;

@end
