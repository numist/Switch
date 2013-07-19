//
//  constants.h
//  Switch
//
//  Created by Scott Perry on 03/01/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>


// Notifications
extern NSString *NNAXAPIDisabledNotification;

// Points
extern const CGFloat kNNMaxWindowThumbnailSize;
extern const CGFloat kNNMaxApplicationIconSize;
extern const CGFloat kNNScreenToWindowInset;
extern const CGFloat kNNWindowToItemInset;
extern const CGFloat kNNItemBorderWidth;
extern const CGFloat kNNItemToThumbInset;
extern const CGFloat kNNWindowToThumbInset;
extern const CGFloat kNNWindowRoundRectRadius;
extern const CGFloat kNNSelectionRoundRectRadius;

// Seconds
extern const NSTimeInterval delayBeforePresentingSwitcherWindow;

// Maths
NSRect nnItemRect(CGFloat thumbSize, NSUInteger index);
NSRect nnThumbRect(CGFloat thumbSize, NSUInteger index);
CGFloat nnTotalPadding(NSUInteger numWindows);
CGFloat nnTotalWidth(CGFloat thumbSize, NSUInteger numWindows);

// Enum stringification
NSString *NNStringFromCGWindowLevel(long level);
