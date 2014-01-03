//
//  NNWindowListService.h
//  Switch
//
//  Created by Scott Perry on 12/24/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <NNKit/NNKit.h>


@class NNWindowListService;


@protocol NNWindowListSubscriber <NSObject>
@optional

- (oneway void)windowListServiceStarted:(NNWindowListService *)service;
- (oneway void)windowListService:(NNWindowListService *)service updatedList:(NSOrderedSet *)windows;
- (oneway void)windowListServiceStopped:(NNWindowListService *)service;

@end


@interface NNWindowListService : NNService

@property (nonatomic, copy, readonly) NSOrderedSet *windows;

@end
