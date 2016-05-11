//
//  SWLoggingService.m
//  Switch
//
//  Created by Scott Perry on 10/15/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWLoggingService.h"

#import "SWWindow.h"
#import "SWWindowListService.h"


@interface SWLoggingService ()

@property (nonatomic, strong) NSDateComponents *logDate;

@end


@implementation SWLoggingService

#pragma mark - NNService

+ (NNServiceType)serviceType;
{
    return NNServiceTypePersistent;
}

#pragma mark - SWLoggingService

- (NSString *)logDirectoryPath;
{
    NSString *libraryLogsPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    return [libraryLogsPath stringByAppendingPathComponent:@"Logs/Switch"];
}

- (void)rotateLogIfNecessary;
{
    if (![self private_dayChanged]) { return; }
    
    // In theory this code is running a race against other invocations of -rotateLogIfNecessary, but -_dayChanged returns YES so infrequently that it's not worth worrying about. The worst possible race condition is if the first time this is called in the program's lifetime is at 23:59:59.9999 and then again at 00:00:00.
    NSString *logDir = [self logDirectoryPath];
    BailUnless([self private_createDirectory:logDir],);
    
    // Remove old log files.
    NSTimeInterval longTime = 671993.28;
    NSFileManager *manager = [NSFileManager defaultManager];
    for (NSString *file in [manager enumeratorAtPath:logDir]) {
        NSDate *creationDate = [[manager attributesOfItemAtPath:[logDir stringByAppendingPathComponent:file] error:nil] fileCreationDate];

        if ([[NSDate date] timeIntervalSinceDate:creationDate] > longTime && [[file pathExtension] isEqualToString:@"log"]) {
            NSError *error = nil;
            NSString *absolutePath = [logDir stringByAppendingPathComponent:file];

            if (![manager removeItemAtPath:absolutePath error:&error]) {
                Log(@"Failed to remove log file %@: %@", absolutePath, error);
            }
        }
    }
    
    // Do not redirect output if attached to a console.
    if (isatty(STDERR_FILENO)) { return; }
    freopen([[self private_logFilePath] cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
}

- (void)takeWindowListSnapshot;
{
    NSArray *rawList = ^{
        CFArrayRef cgInfo = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements,  kCGNullWindowID);
        return CFBridgingRelease(cgInfo);
    }();
    
    NSOrderedSet *windowList = [SWWindowListService filterInfoDictionariesToWindowObjects:rawList];
    NSOrderedSet *windowGroupList = [SWWindowListService filterWindowObjectsToWindowGroups:windowList];
    NSOrderedSet *sortedGroupList = [SWWindowListService sortedWindowGroups:windowGroupList];
    
    NSString *snapshotDir = [[self logDirectoryPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"snapshot-%llu", (uint64_t)[[NSDate date] timeIntervalSince1970]]];
    BailUnless([self private_createDirectory:snapshotDir],);
    
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
    [handle writeData:[[self private_formattedWindowList:rawList] dataUsingEncoding:NSUTF8StringEncoding]];
    [handle writeData:[@"\nWindow list:\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [handle writeData:[[windowList debugDescription] dataUsingEncoding:NSUTF8StringEncoding]];
    [handle writeData:[@"\n\nWindow group list:\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [handle writeData:[[windowGroupList debugDescription] dataUsingEncoding:NSUTF8StringEncoding]];
    [handle writeData:[@"\n\nSorted window group list:\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [handle writeData:[[sortedGroupList debugDescription] dataUsingEncoding:NSUTF8StringEncoding]];
    [handle writeData:[@"\n\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    // TODO: log screen information as well

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
//        [NSArchiver archiveRootObject:contents toFile:[snapshotDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%u.ar", windowID]]];
        [contents lockFocus];
        NSBitmapImageRep *bitmapContents = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(CGRect){.origin = NSZeroPoint, .size = contents.size}];
        [contents unlockFocus];
        NSData *pngContents = [bitmapContents representationUsingType:NSPNGFileType properties:@{}];
        if (!pngContents) {
            [handle writeData:[[NSString stringWithFormat:@"Failed to save window contents for window ID %u: conversion to png failed\n", windowID] dataUsingEncoding:NSUTF8StringEncoding]];
        }
        
        if (![manager createFileAtPath:[snapshotDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%u.png", windowID]] contents:pngContents attributes:nil]) {
            [handle writeData:[[NSString stringWithFormat:@"Failed to save window contents for window ID %u: file creation failure\n", windowID] dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    
    handle = nil;
}

#pragma mark - Internal

- (NSString *)private_logFilePath;
{
    Assert(self.logDate);
    
    NSString *filename = [NSString stringWithFormat:@"Switch-%02ld-%02ld-%02ld.log", self.logDate.year, self.logDate.month, self.logDate.day];
    return [[self logDirectoryPath] stringByAppendingPathComponent:filename];
}

- (BOOL)private_dayChanged;
{
    @synchronized(self) {
        NSDateComponents *todaysComponents = ^{
            NSDate *today = [NSDate date];
            static NSCalendar *gregorian;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                gregorian.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
            });
            return [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:today];
        }();
        
        if (![todaysComponents isEqual:self.logDate]) {
            self.logDate = todaysComponents;
            return YES;
        }
        return NO;
    }
}

- (BOOL)private_createDirectory:(NSString *)path;
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

- (NSString *)private_formattedWindowList:(NSArray *)rawList;
{
    NSMutableString *result = [@"@[\n" mutableCopy];
    
    for (NSDictionary *windowDescription in rawList) {
        [result appendString:@"\t@{\n"];
        
        for (NSString *key in windowDescription) {
            [result appendString:@"\t\t"];
            [result appendString:[key stringByReplacingOccurrencesOfString:@"kCG" withString:@"NN"]];
            [result appendString:@" : "];
            
            id value = windowDescription[key];
            
            [result appendString:@"@"];
            if ([value isKindOfClass:[NSNumber class]]) {
                const char *type = [(NSNumber *)value objCType];
                
                if (!strcmp(type, "q")) {
                    [result appendFormat:@"%lld", [value longLongValue]];
                } else if (!strcmp(type, "c")) {
                    [result appendFormat:@"%d", [value charValue]];
                } else if (!strcmp(type, "d")) {
                    [result appendFormat:@"%f", [value doubleValue]];
                } else if (!strcmp(type, "i")) {
                    [result appendFormat:@"%d", [value intValue]];
                } else {
                    NotTested();
                }
            } else if ([value isKindOfClass:[NSString class]]) {
                [result appendFormat:@"\"%@\"", value];
            } else if ([value isKindOfClass:[NSDictionary class]]) {
                [result appendString:@"{\n"];

                Check(!strcmp([((NSDictionary *)value)[@"Height"] objCType], "d"));
                [result appendString:@"\t\t\t@\"Height\" : @"];
                [result appendFormat:@"%d", [((NSDictionary *)value)[@"Height"] intValue]];
                [result appendString:@",\n"];

                Check(!strcmp([((NSDictionary *)value)[@"Width"] objCType], "d"));
                [result appendString:@"\t\t\t@\"Width\" : @"];
                [result appendFormat:@"%d", [((NSDictionary *)value)[@"Width"] intValue]];
                [result appendString:@",\n"];

                Check(!strcmp([((NSDictionary *)value)[@"X"] objCType], "d"));
                [result appendString:@"\t\t\t@\"X\" : @"];
                [result appendFormat:@"%d", [((NSDictionary *)value)[@"X"] intValue]];
                [result appendString:@",\n"];

                Check(!strcmp([((NSDictionary *)value)[@"Y"] objCType], "d"));
                [result appendString:@"\t\t\t@\"Y\" : @"];
                [result appendFormat:@"%d", [((NSDictionary *)value)[@"Y"] intValue]];
                [result appendString:@",\n"];

                [result appendString:@"\t\t}"];
            } else {
                SWLog(@"Value is of type %@", NSStringFromClass([value class]));
                NotTested();
            }
            
            [result appendString:@",\n"];
        }
        
        [result appendString:@"\t},\n"];
    }
    
    [result appendString:@"];"];
        
    return result;
}

@end
