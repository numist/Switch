//
//  NNHUDCollectionViewTests.m
//  Switch
//
//  Created by Scott Perry on 06/26/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <XCTest/XCTest.h>

#import "NNHUDCollectionView.h"
#import "NSWindow+NNScreenCapture.h"

@interface NNHUDCollectionViewTests : XCTestCase

@end

@implementation NNHUDCollectionViewTests

- (BOOL)compareWindow:(NSWindow *)window toReference:(NSString *)filename;
{
    NSData *reference = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"SwitchTests/References/%@", filename]];
    NSData *comparator = [[window nnImage] TIFFRepresentation];
    return [reference isEqualToData:comparator];
}

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

/*- (void)testEmptyCollectionView
{
    NSRect windowRect = NSMakeRect(0.0, 0.0, 800.0, 100.0);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:windowRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    {
        window.movableByWindowBackground = NO;
        window.hasShadow = NO;
        window.opaque = NO;
        window.backgroundColor = [NSColor clearColor];
        window.level = NSPopUpMenuWindowLevel;
        window.acceptsMouseMovedEvents = YES;
    }
    
    NNHUDCollectionView *collectionView = [[NNHUDCollectionView alloc] initWithFrame:NSMakeRect((800.0 - 100.0) / 2.0, 0.0, 100.0, 100.0)];
    [window.contentView addSubview:collectionView];
    
    [[NSRunningApplication currentApplication] activateWithOptions:NSApplicationActivateIgnoringOtherApps];
    [window orderFront:self];
    
//    [[window nnImage] writeTIFFToFile:@"SwitchTests/References/image.tiff"];
    
    XCTAssertTrue([self compareWindow:window toReference:@"image.tiff"], @"");
}*/

@end
