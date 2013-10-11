//
//  helpers.h
//  Switch
//
//  Created by Scott Perry on 10/11/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NNCFAutorelease(ref) _NNCFAutorelease(CFBridgingRelease((ref)))

void * _NNCFAutorelease(id obj);
