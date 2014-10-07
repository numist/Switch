//
//  SWInterfaceController.h
//  Switch
//
//  Created by Scott Perry on 10/01/14.
//  Copyright © 2014 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>


@class SWInterfaceController;
@class SWWindow;


@protocol SWInterfaceControllerDelegate <NSObject>

- (void)interfaceController:(SWInterfaceController *)controller didSelectWindow:(SWWindow *)window;
- (void)interfaceController:(SWInterfaceController *)controller didActivateWindow:(SWWindow *)window;
- (void)interfaceControllerDidClickOutsideInterface:(SWInterfaceController *)controller;

@end


@interface SWInterfaceController : NSObject

@property (nonatomic, readwrite, assign, getter=showingInterface, setter=shouldShowInterface:) _Bool showInterface;

- (instancetype)initWithDelegate:(id<SWInterfaceControllerDelegate>)delegate;

- (void)updateWindowList:(NSOrderedSet *)windowList;
- (void)selectWindow:(SWWindow *)window;
- (void)disableWindow:(SWWindow *)window;
- (void)enableWindow:(SWWindow *)window;

@end
