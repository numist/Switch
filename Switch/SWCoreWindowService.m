//
//  SWCoreWindowService.m
//  Switch
//
//  Created by Scott Perry on 11/19/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "SWCoreWindowService.h"

#import "SWCoreWindowController.h"
#import "SWEventTap.h"


@interface SWCoreWindowService ()

@property (nonatomic, strong, readonly) SWCoreWindowController *coreWindowController;

@end


@implementation SWCoreWindowService

#pragma mark NNService

- (NNServiceType)serviceType;
{
    return NNServiceTypePersistent;
}

- (void)startService;
{
    [super startService];
    
    if (!self.coreWindowController) {
        self->_coreWindowController = [[SWCoreWindowController alloc] initWithWindow:nil];
    }
}

@end
