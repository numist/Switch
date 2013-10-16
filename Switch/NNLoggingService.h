//
//  NNLoggingService.h
//  Switch
//
//  Created by Scott Perry on 10/15/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NNLoggingService : NSObject

+ (NNLoggingService *)sharedLoggingService;

- (NSString *)logDirectoryPath;
- (void)rotateLogIfNecessary;
- (void)takeWindowListSnapshot;

@end

#define NNLog(fmt, ...) do { \
        [[NNLoggingService sharedLoggingService] rotateLogIfNecessary]; \
        Log(fmt, ##__VA_ARGS__); \
    } while(0)
