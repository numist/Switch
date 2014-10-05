//
//  SWSheetTests.m
//  Switch
//
//  Created by Scott Perry on 10/11/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWWindowListServiceTestSuperclass.h"


@interface SWSheetTests : SWWindowListServiceTestSuperclass

@end


@implementation SWSheetTests

// https://github.com/numist/Switch/issues/9
- (void)testSheetFiltering;
{
    NSDictionary *windowDescription = @{
        NNWindowAlpha : @1,
        NNWindowBounds : DICT_FROM_RECT(((CGRect){
            .size.height = 706,
            .size.width = 1000,
            .origin.x = 181,
            .origin.y = 58
        })),
        NNWindowIsOnscreen : @1,
        NNWindowLayer : @0,
        NNWindowMemoryUsage : @2941236,
        NNWindowName : @"Instruments1",
        NNWindowNumber : @33085,
        NNWindowOwnerName : @"Instruments",
        NNWindowOwnerPID : @75257,
        NNWindowSharingState : @1,
        NNWindowStoreType : @2,
    };
    NSArray *infoList = @[
        @{
            NNWindowAlpha : @(0.8500000238418579),
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 10,
                .size.width = 469,
                .origin.x = 447,
                .origin.y = 136
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @5404,
            NNWindowNumber : @33143,
            NNWindowOwnerName : @"Instruments",
            NNWindowOwnerPID : @75257,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },@{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 131,
                .size.width = 456,
                .origin.x = 453,
                .origin.y = 136
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @61300,
            NNWindowNumber : @33142,
            NNWindowOwnerName : @"Instruments",
            NNWindowOwnerPID : @75257,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        windowDescription
    ];
    
    [self updateListServiceWithInfoList:infoList];

    XCTAssertEqual(self.listService.windows.count, 1, @"");
    if (self.listService.windows.count == 1) {
        XCTAssertEqual(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).windows.count, infoList.count, @"");
        XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).mainWindow.windowDescription, windowDescription, @"");
    }
}

// https://github.com/numist/Switch/issues/55
- (void)testTextEditSaveDialog;
{
    NSDictionary *windowDescription = @{
        NNWindowAlpha : @1,
        NNWindowBounds : DICT_FROM_RECT(((CGRect){
            .size.height = 412,
            .size.width = 640,
            .origin.x = 147,
            .origin.y = 47
        })),
        NNWindowIsOnscreen : @1,
        NNWindowLayer : @0,
        NNWindowMemoryUsage : @1220180,
        NNWindowName : @"Untitled.txt",
        NNWindowNumber : @74761,
        NNWindowOwnerName : @"TextEdit",
        NNWindowOwnerPID : @82763,
        NNWindowSharingState : @1,
        NNWindowStoreType : @2,
    };
    NSArray *infoList = @[
        @{
            NNWindowAlpha : @0.8500000238418579,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 10,
                .size.width = 503,
                .origin.x = 216,
                .origin.y = 69
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @21756,
            NNWindowNumber : @74771,
            NNWindowOwnerName : @"TextEdit",
            NNWindowOwnerPID : @82763,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 58,
                .size.width = 463,
                .origin.x = 235,
                .origin.y = 281
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @111868,
            NNWindowName : @"",
            NNWindowNumber : @74770,
            NNWindowOwnerName : @"TextEdit",
            NNWindowOwnerPID : @82763,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 319,
                .size.width = 489,
                .origin.x = 222,
                .origin.y = 69
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @636156,
            NNWindowName : @"Save",
            NNWindowNumber : @74764,
            NNWindowOwnerName : @"com.apple.appkit.xpc.openAndSav",
            NNWindowOwnerPID : @82769,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 319,
                .size.width = 490,
                .origin.x = 222,
                .origin.y = 69
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @806740,
            NNWindowName : @"Save",
            NNWindowNumber : @74765,
            NNWindowOwnerName : @"TextEdit",
            NNWindowOwnerPID : @82763,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        windowDescription,
    ];
    
    [self updateListServiceWithInfoList:infoList];
    
    XCTAssertEqual(self.listService.windows.count, 1, @"");
    if (self.listService.windows.count == 1) {
        XCTAssertEqual(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).windows.count, infoList.count, @"");
        XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).mainWindow.windowDescription, windowDescription, @"");
    }
}

@end
