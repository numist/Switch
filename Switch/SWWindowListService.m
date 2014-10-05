//
//  SWWindowListService.m
//  Switch
//
//  Created by Scott Perry on 12/24/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWWindowListService.h"

#import <NNKit/NNService+Protected.h>

#import "SWApplication.h"
#import "SWWindow.h"
#import "SWWindowGroup.h"
#import "SWWindowListWorker.h"


@interface SWWindowListService ()

@property (nonatomic, copy, readwrite) NSOrderedSet *windows;
@property (nonatomic, strong, readwrite) SWWindowListWorker *worker;

@end


static NSMutableSet *loggedWindows;


@implementation SWWindowListService

#pragma mark - Initialization

- (id)init;
{
    NSAssert([NSThread isMainThread], @"Boundary call was not made on main thread");

    if (!(self = [super init])) { return nil; }
    
    [[NSNotificationCenter defaultCenter] addWeakObserver:self selector:NNSelfSelector1(_workerUpdatedWindowList:) name:[SWWindowListWorker notificationName] object:nil];
    
    return self;
}

#pragma mark - NNService

+ (NNServiceType)serviceType;
{
    return NNServiceTypeOnDemand;
}

+ (Protocol *)subscriberProtocol;
{
    return @protocol(SWWindowListSubscriber);
}

- (void)startService;
{
    NSAssert([NSThread isMainThread], @"Boundary call was not made on main thread");

    [super startService];
    
    loggedWindows = [NSMutableSet new];
    self.worker = [SWWindowListWorker new];

    [(id<SWWindowListSubscriber>)self.subscriberDispatcher windowListServiceStarted:self];
}

- (void)stopService;
{
    NSAssert([NSThread isMainThread], @"Boundary call was not made on main thread");
    
    loggedWindows = nil;
    self.worker = nil;
    self.windows = nil;
    
    [(id<SWWindowListSubscriber>)self.subscriberDispatcher windowListServiceStopped:self];
    
    [super stopService];
}

#pragma mark - SWWindowListService

+ (NSOrderedSet *)filterInfoDictionariesToWindowObjects:(NSArray *)infoDicts;
{
    return [NSOrderedSet orderedSetWithArray:[[infoDicts nn_filter:(nn_filter_block_t)^bool(NSDictionary *windowInfo) {
        NSString *applicationName = windowInfo[(__bridge NSString *)kCGWindowOwnerName];
        
        // Non-normal windows are filtered out as the accuracy of their ordering in the window list cannot be guaranteed.
        BOOL normalWindow = ([windowInfo[(__bridge NSString *)kCGWindowLayer] longValue] == kCGNormalWindowLevel);
        BOOL transparentWindow = ([windowInfo[(__bridge NSString *)kCGWindowAlpha] doubleValue] == 0.0);
        
        BOOL msWordWindow = [applicationName isEqualToString:@"Microsoft Word"];
        BOOL badMSWordWindow = msWordWindow && [windowInfo[(__bridge NSString *)kCGWindowName] isEqualToString:@"Microsoft Word"];
        
        BOOL isolatorWindow = [applicationName isEqualToString:@"Isolator"];
        BOOL isolatorShield = isolatorWindow && ([windowInfo[(__bridge NSString *)kCGWindowAlpha] doubleValue] < 0.9);

        return normalWindow && !transparentWindow && !badMSWordWindow && !isolatorShield;
    }] nn_map:(nn_map_block_t)^id(NSDictionary *windowInfo) {
        return [SWWindow windowWithDescription:windowInfo];
    }]];
}

+ (NSOrderedSet *)filterWindowObjectsToWindowGroups:(NSOrderedSet *)rawWindowList;
{
    NSMutableOrderedSet *mutableWindowGroupList = [NSMutableOrderedSet new];
    
    __block NSMutableOrderedSet *windows = [NSMutableOrderedSet new];
    __block SWWindow *mainWindow = nil;
    dispatch_block_t addWindowGroup = ^{
        if (windows.count) {
            SWWindowGroup *group = [[SWWindowGroup alloc] initWithWindows:[windows reversedOrderedSet] mainWindow:mainWindow];
            
            if (mutableWindowGroupList.count && [group isRelatedToLowerGroup:mutableWindowGroupList.lastObject]) {
                NSMutableOrderedSet *windowList = [group.windows mutableCopy];
                [windowList addObjectsFromArray:((SWWindowGroup *)mutableWindowGroupList.lastObject).windows.array];
                group = [[SWWindowGroup alloc] initWithWindows:windowList mainWindow:((SWWindowGroup *)mutableWindowGroupList.lastObject).mainWindow];
                [mutableWindowGroupList removeObject:mutableWindowGroupList.lastObject];
            }
            
            [mutableWindowGroupList addObject:group];
            
            if (![loggedWindows containsObject:group]) {
                if (!group.mainWindow.name) {
                    SWLog(@"Window for application %@ is not named.", mainWindow.application);
                } else if (!group.mainWindow.name.length) {
                    SWLog(@"Window for application %@ has zero-length name.", mainWindow.application);
                }
                [loggedWindows addObject:group];
            }

            windows = [NSMutableOrderedSet new];
            mainWindow = nil;
        }
    };
    
    for (NSInteger i = (NSInteger)rawWindowList.count - 1; i >= 0; --i) {
        SWWindow *window = rawWindowList[(NSUInteger)i];

        if (mainWindow && ![window isRelatedToLowerWindow:mainWindow]) {
            addWindowGroup();
        }
        
        if (window.application.canBeActivated) {
            // Some applications don't name their windows, some people juggle geese. Make sure there's always a main window for the group.
            if (!mainWindow) {
                mainWindow = window;
            } else
            // Named windows always supercede unnamed siblings in the same window group.
            if (window.name.length && !mainWindow.name.length) {
                mainWindow = window;
            }
        }
        
        [windows addObject:window];
    }
    if (mainWindow) {
        addWindowGroup();
    }
    
    return [mutableWindowGroupList reversedOrderedSet];
}

#pragma mark - Internal

- (void)_workerUpdatedWindowList:(NSNotification *)notification;
{
    NSAssert([NSThread isMainThread], @"Boundary call was not made on main thread");
    
    if (notification.object != self.worker) { return; }
    
    NSParameterAssert([notification.userInfo[@"windows"] isKindOfClass:[NSArray class]]);
    
    [self _updateWindowList:notification.userInfo[@"windows"]];
}

- (void)_updateWindowList:(NSArray *)windowInfoList;
{
    BailUnless(windowInfoList,);
    NSOrderedSet *windowObjectList = [[self class] filterInfoDictionariesToWindowObjects:windowInfoList];
    NSOrderedSet *windowGroupList = [[self class] filterWindowObjectsToWindowGroups:windowObjectList];
    
    // This probably needs to change for #105 to get fixed properly as well—there are two views of equality, window order and window order and activation.
    if (![self.windows isEqualToOrderedSet:windowGroupList]) {
        self.windows = windowGroupList;
        [(id<SWWindowListSubscriber>)self.subscriberDispatcher windowListService:self updatedList:self.windows];
    }
}

@end
