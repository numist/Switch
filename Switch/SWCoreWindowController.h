//
//  SWCoreWindowController.h
//  Switch
//
//  Created by Scott Perry on 07/10/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <Cocoa/Cocoa.h>


@class SWCoreWindowController;
@class SWWindowGroup;


@protocol SWCoreWindowControllerDelegate <NSObject>

- (void)coreWindowController:(SWCoreWindowController *)controller didSelectWindowGroup:(SWWindowGroup *)windowGroup;
- (void)coreWindowController:(SWCoreWindowController *)controller didActivateWindowGroup:(SWWindowGroup *)windowGroup;

@end


// A poor attempt at getting core window controllers to be well-behaved targets for the multi-dispatch manager.
@protocol SWCoreWindowControllerAPI <NSObject>

@required
- (void)selectWindowGroup:(SWWindowGroup *)windowGroup;
- (void)disableWindowGroup:(SWWindowGroup *)windowGroup;
- (void)enableWindowGroup:(SWWindowGroup *)windowGroup;

@end


@interface SWCoreWindowController : NSWindowController <SWCoreWindowControllerAPI>

@property (nonatomic, strong) NSOrderedSet *windowGroups;
@property (nonatomic, weak) id<SWCoreWindowControllerDelegate> delegate;

- (id)initWithRect:(CGRect)frame;

@end
