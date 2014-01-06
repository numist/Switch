//
//  SWWindowContentsService.m
//  Switch
//
//  Created by Scott Perry on 01/02/14.
//  Copyright © 2014 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWWindowContentsService.h"

#import <NNKit/NNService+Protected.h>

#import "SWWindowListService.h"
#import "SWWindowGroup.h"
#import "SWWindowWorker.h"


@interface SWWindowContentsService () <SWWindowListSubscriber>

@property (nonatomic, strong) NSMutableDictionary *workers;
@property (nonatomic, strong) NSMutableDictionary *content;
@property (nonatomic, strong) dispatch_queue_t queue;

@end


@implementation SWWindowContentsService

- (id)init;
{
    if (!(self = [super init])) { return nil; }
    
    _workers = [NSMutableDictionary new];
    _content = [NSMutableDictionary new];
    _queue = dispatch_queue_create([[NSString stringWithFormat:@""] UTF8String], DISPATCH_QUEUE_SERIAL);
    
    [[NSNotificationCenter defaultCenter] addWeakObserver:self selector:@selector(windowUpdateNotification:) name:[SWWindowWorker notificationName] object:nil];
    
    return self;
}

- (NNServiceType)serviceType;
{
    return NNServiceTypePersistent;
}

- (NSSet *)dependencies;
{
    return [NSSet setWithArray:@[[SWWindowListService class]]];
}

- (Protocol *)subscriberProtocol;
{
    return @protocol(SWWindowContentsSubscriber);
}

- (void)startService;
{
    [super startService];
    
    NSOrderedSet *windows = [SWWindowListService sharedService].windows;
    [self windowListService:nil updatedList:windows];
    
    [[NNServiceManager sharedManager] addObserver:self forService:[SWWindowListService class]];
}

- (void)stopService;
{
    dispatch_async(self.queue, ^{
        [self.workers removeAllObjects];
    });
    
    [super stopService];
}

- (NSImage *)contentForWindow:(SWWindow *)window;
{
    return [self.content objectForKey:window];
}

- (void)windowUpdateNotification:(NSNotification *)notification;
{
    dispatch_async(self.queue, ^{
        if (![self.workers objectForKey:@(((SWWindowWorker *)notification.object).windowID)]) {
            return;
        }
        
        NSImage *content = notification.userInfo[@"content"];
        SWWindow *window = notification.userInfo[@"window"];
        
        [self.content setObject:content forKey:@(window.windowID)];
        
        [(id<SWWindowContentsSubscriber>)self.subscriberDispatcher windowContentService:self updatedContent:content forWindow:window];
    });
}

#pragma mark - SWWindowListSubscriber

- (oneway void)windowListService:(SWWindowListService *)service updatedList:(NSOrderedSet *)windowList;
{
    dispatch_async(self.queue, ^{
        NSMutableSet *existingWindows = [NSMutableSet new];
        for (SWWindowGroup *windowGroup in windowList) {
            for (SWWindow *window in windowGroup.windows) {
                [existingWindows addObject:window];
            }
        }
        
        NSSet *trackedWindows;
        NSMutableSet *appearedWindows;
        NSMutableSet *vanishedWindows;
        
        // Update window workers
        trackedWindows = [NSSet setWithArray:[self.workers allKeys]];
        
        appearedWindows = [existingWindows mutableCopy];
        [appearedWindows minusSet:trackedWindows];
        for (SWWindow *window in appearedWindows) {
            [self.workers setObject:[[SWWindowWorker alloc] initWithModelObject:window] forKey:window];
        }
        
        vanishedWindows = [trackedWindows mutableCopy];
        [vanishedWindows minusSet:existingWindows];
        for (SWWindow *window in vanishedWindows) {
            [self.workers removeObjectForKey:window];
        }
        
        // Update window content cache
        trackedWindows = [NSSet setWithArray:[self.content allKeys]];
        
        vanishedWindows = [trackedWindows mutableCopy];
        [vanishedWindows minusSet:existingWindows];
        for (SWWindow *window in vanishedWindows) {
            [self.content removeObjectForKey:window];
        }
    });
}

@end
