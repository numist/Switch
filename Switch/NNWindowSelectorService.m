//
//  NNWindowSelectorService.m
//  Switch
//
//  Created by Scott Perry on 11/19/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNWindowSelectorService.h"

#import "NNWindowStore.h"


@interface NNWindowSelectorService () <NNWindowStoreDelegate>

@end


@implementation NNWindowSelectorService

- (NSSet *)dependencies;
{
    return [NSSet setWithObject:[NNWindowStore self]];
}

- (NNServiceType)serviceType;
{
    return NNServiceTypePersistent;
}



@end
