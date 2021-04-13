//  HAXButton.m
//  Created by Kocsis Olivér on 2014-05-21
//  Copyright 2014 Joinect Technologies

#import "HAXButton.h"
#import "HAXElement+Protected.h"

@implementation HAXButton

-(void)press {
    [self performAction:(__bridge NSString *)kAXPressAction error:NULL];
}

@end
