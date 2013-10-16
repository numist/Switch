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

- (void)takeWindowListSnapshot;
{
    NSArray *rawList = ^{
        CFArrayRef cgInfo = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements,  kCGNullWindowID);
        return CFBridgingRelease(cgInfo);
    }();
    
    NSOrderedSet *objectList = ^{
        NSMutableOrderedSet *result = [NSMutableOrderedSet orderedSetWithCapacity:[rawList count]];
        for (unsigned i = 0; i < [rawList count]; i++) {
            NNWindow *window = [NNWindow windowWithDescription:rawList[i]];
            if (window) {
                [result addObject:window];
            }
        }
        return result;
    }();
    
    NSOrderedSet *filteredList = [NNWindow filterInvalidWindowsFromSet:objectList];
    
    NSString *snapshotDir = [[self logDirectoryPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"snapshot-%llu", (uint64_t)[[NSDate date] timeIntervalSince1970]]];
    BailUnless([self createDirectory:snapshotDir],);
    
    NSString *listFile = [snapshotDir stringByAppendingPathComponent:@"windowlist.txt"];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    BailWithBlockUnless([manager createFileAtPath:listFile contents:nil attributes:nil], ^{
        Log(@"Failed to create file %@", listFile);
    });
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:listFile];
    BailWithBlockUnless(handle, ^{
        Log(@"Failed to open %@ for writing", listFile);
    });
    [handle writeData:[@"Raw list:\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [handle writeData:[[rawList debugDescription] dataUsingEncoding:NSUTF8StringEncoding]];
    [handle writeData:[@"\nObject list:\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [handle writeData:[[objectList debugDescription] dataUsingEncoding:NSUTF8StringEncoding]];
    [handle writeData:[@"\n\nFiltered list:\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [handle writeData:[[filteredList debugDescription] dataUsingEncoding:NSUTF8StringEncoding]];
    [handle writeData:[@"\n\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    for (NSDictionary *description in rawList) {
        CGWindowID windowID = (CGWindowID)[[description objectForKey:(__bridge NSString *)kCGWindowNumber] unsignedLongValue];
        CGImageRef cgContents = NNCFAutorelease(CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow, windowID, kCGWindowImageBoundsIgnoreFraming));
        
        if (!cgContents) {
            [handle writeData:[[NSString stringWithFormat:@"Failed to save window contents for window ID %u: CGWindowListCreateImage returned NULL\n", windowID] dataUsingEncoding:NSUTF8StringEncoding]];
            continue;
        }
        
        if (CGImageGetHeight(cgContents) < 1.0 || CGImageGetWidth(cgContents) < 1.0) {
            [handle writeData:[[NSString stringWithFormat:@"Failed to save window contents for window ID %u: image is zero size\n", windowID] dataUsingEncoding:NSUTF8StringEncoding]];
            continue;
        }
        
        NSImage *contents = [[NSImage alloc] initWithCGImage:cgContents size:(NSSize){.width = CGImageGetWidth(cgContents), .height = CGImageGetHeight(cgContents)}];
        [contents lockFocus];
        NSBitmapImageRep *bitmapContents = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){.origin = NSZeroPoint, .size = contents.size}];
        [contents unlockFocus];
        NSData *pngContents = [bitmapContents representationUsingType:NSPNGFileType properties:nil];
        if (!pngContents) {
            [handle writeData:[[NSString stringWithFormat:@"Failed to save window contents for window ID %u: conversion to png failed\n", windowID] dataUsingEncoding:NSUTF8StringEncoding]];
        }
        
        if (![manager createFileAtPath:[snapshotDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%u.png", windowID]] contents:pngContents attributes:nil]) {
            [handle writeData:[[NSString stringWithFormat:@"Failed to save window contents for window ID %u: file creation failure\n", windowID] dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    
    handle = nil;
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
