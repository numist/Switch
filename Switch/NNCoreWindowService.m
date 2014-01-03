//
//  NNCoreWindowService.m
//  Switch
//
//  Created by Scott Perry on 11/19/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNCoreWindowService.h"

#import "NNCoreWindowController.h"
#import "NNEventManager.h"


@interface NNCoreWindowService ()

@property (nonatomic, strong, readonly) NNCoreWindowController *coreWindowController;

@end


@implementation NNCoreWindowService

#pragma mark NNService

- (NNServiceType)serviceType;
{
    return NNServiceTypePersistent;
}

- (NSSet *)dependencies;
{
    return [NSSet setWithObject:[NNEventManager self]];
}

- (void)startService;
{
    #pragma message "Disabled UI here"
//    self->_coreWindowController = [[NNCoreWindowController alloc] initWithWindow:nil];
}

@end
