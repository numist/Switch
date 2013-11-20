//
//  NNCoreWindowService.m
//  Switch
//
//  Created by Scott Perry on 11/19/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNCoreWindowService.h"

#import "NNCoreWindowController.h"


@interface NNCoreWindowService ()

@property (nonatomic, strong, readonly) NNCoreWindowController *coreWindowController;

@end


@implementation NNCoreWindowService

#pragma mark NNService

- (NNServiceType)serviceType;
{
    return NNServiceTypePersistent;
}

- (void)startService;
{
    self->_coreWindowController = [[NNCoreWindowController alloc] initWithWindow:nil];
}

@end
