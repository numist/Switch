//
//  NNWindowListService.m
//  Switch
//
//  Created by Scott Perry on 12/24/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNWindowListService.h"

#import "NNWindow+Private.h"
#import "NNWindowGroup.h"
#import "NNWindowListWorker.h"
#import "NNApplication.h"

#import <NNKit/NNService+Protected.h>


@interface NNWindowListService ()

@property (nonatomic, copy, readwrite) NSOrderedSet *windows;
@property (nonatomic, strong, readwrite) NNWindowListWorker *worker;

@end


@implementation NNWindowListService

- (id)init;
{
    NSAssert([NSThread isMainThread], @"Boundary call was not made on main thread");

    if (!(self = [super init])) { return nil; }
    
    _windows = [NSOrderedSet new];
    
    [[NSNotificationCenter defaultCenter] addWeakObserver:self selector:@selector(_workerUpdatedWindowList:) name:[NNWindowListWorker notificationName] object:nil];
    
    return self;
}

#pragma mark NNService

- (NNServiceType)serviceType;
{
    return NNServiceTypeOnDemand;
}

- (Protocol *)subscriberProtocol;
{
    return @protocol(NNWindowListSubscriber);
}

- (void)startService;
{
    NSAssert([NSThread isMainThread], @"Boundary call was not made on main thread");

    [super startService];
    
    self.worker = [NNWindowListWorker new];

    [(id<NNWindowListSubscriber>)self.subscriberDispatcher windowListServiceStarted:self];
}

- (void)stopService;
{
    NSAssert([NSThread isMainThread], @"Boundary call was not made on main thread");
    
    self.worker = nil;
    
    [(id<NNWindowListSubscriber>)self.subscriberDispatcher windowListServiceStopped:self];
    
    [super stopService];
}

- (void)_workerUpdatedWindowList:(NSNotification *)notification;
{
    NSAssert([NSThread isMainThread], @"Boundary call was not made on main thread");

    if (notification.object != self.worker) { NotTested(); return; }
    
    NSParameterAssert([notification.userInfo[@"windows"] isKindOfClass:[NSArray class]]);
    
    NSArray *windowInfoList = notification.userInfo[@"windows"];
    BailUnless(windowInfoList,);
    NSOrderedSet *windowObjectList = [self filterInfoDictionariesToWindowObjects:windowInfoList];
    NSOrderedSet *windowGroupList = [self filterWindowObjectsToWindowGroups:windowObjectList];
    
    if (![self.windows isEqualToOrderedSet:windowGroupList]) {
        self.windows = windowGroupList;
        [(id<NNWindowListSubscriber>)self.subscriberDispatcher windowListService:self updatedList:self.windows];
    }
}

- (NSOrderedSet *)filterInfoDictionariesToWindowObjects:(NSArray *)infoDicts;
{
    NSMutableOrderedSet *rawWindowList = [NSMutableOrderedSet orderedSetWithArray:infoDicts];
    
    for (NSInteger i = (NSInteger)rawWindowList.count - 1; i >= 0; --i) {
        // Non-normal windows are filtered out as the accuracy of their ordering in the window list cannot be guaranteed.
        if ([rawWindowList[(NSUInteger)i][(__bridge NSString *)kCGWindowLayer] longValue] != kCGNormalWindowLevel) {
            [rawWindowList removeObjectAtIndex:(NSUInteger)i];
        } else {
            [rawWindowList replaceObjectAtIndex:(NSUInteger)i withObject:[NNWindow windowWithDescription:rawWindowList[(NSUInteger)i]]];
        }
    }

    return rawWindowList;
}

- (NSOrderedSet *)filterWindowObjectsToWindowGroups:(NSOrderedSet *)rawWindowList;
{
    NSMutableOrderedSet *mutableWindowGroupList = [NSMutableOrderedSet new];
    
    __block NSMutableOrderedSet *windows = [NSMutableOrderedSet new];
    __block NNWindow *mainWindow = nil;
    dispatch_block_t addWindowGroup = ^{
        if (windows.count) {
            [mutableWindowGroupList addObject:[[NNWindowGroup alloc] initWithWindows:windows mainWindow:mainWindow]];

            windows = [NSMutableOrderedSet new];
            mainWindow = nil;
        }
    };
    
    for (NSInteger i = (NSInteger)rawWindowList.count - 1; i >= 0; --i) {
        NNWindow *window = rawWindowList[(NSUInteger)i];
        
        if (window.application.canBeActivated && window.name.length) {
            if (mainWindow && ![window isRelatedToLowerWindow:mainWindow]) {
                addWindowGroup();
            }
            
            // Named windows always supercede unnamed siblings in the same window group.
            if (!mainWindow.name.length) {
                mainWindow = window;
            }
        } else if (mainWindow && ![window isRelatedToLowerWindow:mainWindow]) {
            addWindowGroup();
        }
        
        // Some applications don't name their windows, some people juggle geese.
        if (!mainWindow && window.application.canBeActivated) {
            mainWindow = window;
        }
        
        [windows addObject:window];
    }
    if (mainWindow) {
        addWindowGroup();
    }
    
    return [mutableWindowGroupList reversedOrderedSet];
}

@end
