//
//  NNLoggingService.m
//  Switch
//
//  Created by Scott Perry on 10/15/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNLoggingService.h"

#import "NNWindow+Private.h"


static NNLoggingService *sharedLoggingService;


__attribute__((constructor)) static void initializeLoggingService() {
    (void)[NNLoggingService sharedLoggingService];
}


@interface NNLoggingService ()

@property (nonatomic, strong) NSDateComponents *logDate;

@end


@implementation NNLoggingService

#pragma mark - NNLoggingService

+ (NNLoggingService *)sharedLoggingService;
{
    if (!sharedLoggingService) {
        @synchronized([NNLoggingService class]) {
            if (!sharedLoggingService) {
                sharedLoggingService = [NNLoggingService new];
            }
        }
    }
    return sharedLoggingService;
}

- (NSString *)logDirectoryPath;
{
    NSString *libraryLogsPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    return [libraryLogsPath stringByAppendingPathComponent:@"Logs/Switch"];
}

- (void)rotateLogIfNecessary;
{
    // Do not redirect output if attached to a console.
    if (isatty(STDERR_FILENO)) { return; }
    
    NSString *logDir = [self logDirectoryPath];
    BailUnless([self createDirectory:logDir],);
    
    // Remove old log files.
    NSTimeInterval longTime = 671993.28;
    NSFileManager *manager = [NSFileManager defaultManager];
    for (NSString *file in [manager enumeratorAtPath:logDir]) {
        NSDate *creationDate = [[manager attributesOfItemAtPath:[logDir stringByAppendingPathComponent:file] error:nil] fileCreationDate];

        if ([[NSDate date] timeIntervalSinceDate:creationDate] > longTime && [[file pathExtension] isEqualToString:@"log"]) {
            NSError *error;
            NSString *absolutePath = [logDir stringByAppendingPathComponent:file];

            if (![manager removeItemAtPath:absolutePath error:&error]) {
                Log(@"Failed to remove log file %@: %@", absolutePath, error);
            }
        }
    }
    
    // Open new log file if the day has changed.
    if ([self dayChanged]) {
        freopen([[self logFilePath] cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
    }
}

#pragma mark Internal

- (NSString *)logFilePath;
{
    Assert(self.logDate);
    
    NSString *filename = [NSString stringWithFormat:@"Switch-%2ld-%2ld-%2ld.log", self.logDate.year, self.logDate.month, self.logDate.day];
    return [[self logDirectoryPath] stringByAppendingPathComponent:filename];
}

- (BOOL)dayChanged;
{
    NSDateComponents *todaysComponents = ^{
        NSDate *today = [NSDate date];
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        gregorian.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        return [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:today];
    }();
    
    if (![todaysComponents isEqual:self.logDate]) {
        self.logDate = todaysComponents;
        return YES;
    }
    return NO;
}

- (BOOL)createDirectory:(NSString *)path;
{
    NSFileManager *manager = [NSFileManager defaultManager];

    // Create and verify log directory, if it doesn't already exist.
    if (![manager fileExistsAtPath:path]) {
        [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    BOOL isDirectory = NO;
    BailWithBlockUnless([manager fileExistsAtPath:path isDirectory:&isDirectory], ^{
        Log(@"Directory %@ does not exist, even after attempting to create it!", path);
        return NO;
    });
    BailWithBlockUnless(isDirectory, ^{
        Log(@"Could not create directory %@ because a non-folder file already exists at that path.", path);
        return NO;
    });
    
    return YES;
}

@end
