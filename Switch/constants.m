//
//  constants.m
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

#import "constants.h"


// Notifications
NSString *NNAXAPIDisabledNotification = @"NNAXAPIDisabledNotification";

// Maxima
const CGFloat kNNMaxWindowThumbnailSize = 128.0;
const CGFloat kNNMaxApplicationIconSize = kNNMaxWindowThumbnailSize / 2.0;

// Window
const CGFloat kNNScreenToWindowInset = 16.0;

// Items
const CGFloat kNNWindowToItemInset = 8.0;
const CGFloat kNNItemBorderWidth = 3.0;

// Thumbs
const CGFloat kNNItemToThumbInset = kNNItemBorderWidth + 8.0;
const CGFloat kNNWindowToThumbInset = kNNWindowToItemInset + kNNItemToThumbInset;

// Round rect radii
const CGFloat kNNWindowRoundRectRadius = 20.0;
const CGFloat kNNSelectionRoundRectRadius = kNNWindowRoundRectRadius - kNNWindowToItemInset;

// Timing
const NSTimeInterval delayBeforePresentingSwitcherWindow = 0.25;

// Maths
__attribute__((const)) static CGFloat nnItemSideLength(CGFloat thumbSize)
{
    return kNNItemToThumbInset * 2.0 + thumbSize;
}

__attribute__((const)) static NSSize nnItemSize(CGFloat thumbSize)
{
    return NSMakeSize(nnItemSideLength(thumbSize),
                      nnItemSideLength(thumbSize));
}

__attribute__((const)) NSRect nnItemRect(CGFloat thumbSize, NSUInteger index)
{
    return (NSRect){
        .origin.x = kNNWindowToItemInset + (index * (nnItemSideLength(thumbSize) - kNNItemBorderWidth)),
        .origin.y = kNNWindowToItemInset,
        .size = nnItemSize(thumbSize)
    };
}

__attribute__((const)) static NSSize nnThumbSize(CGFloat thumbSize)
{
    return NSMakeSize(thumbSize, thumbSize);
}

__attribute__((const)) NSRect nnThumbRect(CGFloat thumbSize, NSUInteger index)
{
    return (NSRect){
        .origin.x = kNNWindowToThumbInset + index * (nnItemSideLength(thumbSize) - kNNItemBorderWidth),
        .origin.y = kNNWindowToThumbInset,
        .size = nnThumbSize(thumbSize)
    };
}

__attribute__((const)) CGFloat nnTotalPadding(NSUInteger numWindows)
{
    return kNNWindowToItemInset * 2.0 + numWindows * (kNNItemToThumbInset * 2.0 - kNNItemBorderWidth) + kNNItemBorderWidth;
}

__attribute__((const)) CGFloat nnTotalWidth(CGFloat thumbSize, NSUInteger numWindows)
{
    NSRect lastItem = nnItemRect(thumbSize, (numWindows - 1));
    return lastItem.origin.x + lastItem.size.width + kNNWindowToItemInset;
}

__attribute__((const)) NSString *NNStringFromCGWindowLevel(long level)
{
    if (level == kCGBaseWindowLevel) {
        return @"kCGBaseWindowLevel";
    } else if (level == kCGMinimumWindowLevel) {
        return @"kCGMinimumWindowLevel";
    } else if (level == kCGDesktopWindowLevel) {
        return @"kCGDesktopWindowLevel";
    } else if (level == kCGDesktopIconWindowLevel) {
        return @"kCGDesktopIconWindowLevel";
    } else if (level == kCGBackstopMenuLevel) {
        return @"kCGBackstopMenuLevel";
    } else if (level == kCGNormalWindowLevel) {
        return @"kCGNormalWindowLevel";
    } else if (level == kCGFloatingWindowLevel) {
        return @"kCGFloatingWindowLevel";
    } else if (level == kCGTornOffMenuWindowLevel) {
        return @"kCGTornOffMenuWindowLevel";
    } else if (level == kCGDockWindowLevel) {
        return @"kCGDockWindowLevel";
    } else if (level == kCGMainMenuWindowLevel) {
        return @"kCGMainMenuWindowLevel";
    } else if (level == kCGStatusWindowLevel) {
        return @"kCGStatusWindowLevel";
    } else if (level == kCGModalPanelWindowLevel) {
        return @"kCGModalPanelWindowLevel";
    } else if (level == kCGPopUpMenuWindowLevel) {
        return @"kCGPopUpMenuWindowLevel";
    } else if (level == kCGDraggingWindowLevel) {
        return @"kCGDraggingWindowLevel";
    } else if (level == kCGScreenSaverWindowLevel) {
        return @"kCGScreenSaverWindowLevel";
    } else if (level == kCGCursorWindowLevel) {
        return @"kCGCursorWindowLevel";
    } else if (level == kCGOverlayWindowLevel) {
        return @"kCGOverlayWindowLevel";
    } else if (level == kCGHelpWindowLevel) {
        return @"kCGHelpWindowLevel";
    } else if (level == kCGUtilityWindowLevel) {
        return @"kCGUtilityWindowLevel";
    } else if (level == kCGAssistiveTechHighWindowLevel) {
        return @"kCGAssistiveTechHighWindowLevel";
    } else if (level == kCGMaximumWindowLevel) {
        return @"kCGMaximumWindowLevel";
    }
    return @"kNNUnknownWindowLevel";
}
