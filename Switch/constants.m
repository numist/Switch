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

const CGFloat screenToSwitcherWindowInset = 16.0;
const CGFloat maxWindowThumbnailSize = 128.0;
const CGFloat maxApplicationIconSize = 64.0;
const CGFloat itemToThumbInset = 8.0;
const CGFloat windowToItemInset = 20.0;
const CGFloat windowRoundRectRadius = 32.0;
const CGFloat windowToSelectionInset = 5.0; // TODO: this is probably a computable constant based on the thumb insets or something.

const NSTimeInterval delayBeforePresentingSwitcherWindow = 0.25;
