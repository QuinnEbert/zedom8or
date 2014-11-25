//
//  DebuggingOutput.m
//  OpenEars
//
//
//  Copyright Politepix UG (haftungsbeschränkt) 2012. All rights reserved.
//  http://www.politepix.com
//  Contact at http://www.politepix.com/contact
//
//  this file is licensed under the Politepix Shared Source license found 
//  found in the root of the source distribution. Please see the file "Version.txt" in the root of 
//  the source distribution for the version number of this OpenEars package.

#import "OpenEarsLogging.h"
#import "RuntimeVerbosity.h"
#import <UIKit/UIDevice.h>
#import "Version.h"

extern int openears_logging;

@implementation OpenEarsLogging

+ (id)startOpenEarsLogging
{
    static dispatch_once_t once;
    static id startOpenEarsLogging;
    dispatch_once(&once, ^{
        startOpenEarsLogging = [[self alloc] init];
    });
    openears_logging = 1;
    int bits = 0;

#if __LP64__
    bits = 64;
#else
    bits = 32;
#endif
    NSLog(@"Starting OpenEars logging for OpenEars version %@ on %d-bit device: %@ running iOS version: %f",kCurrentVersion,bits,[[UIDevice currentDevice]model ], [[[UIDevice currentDevice] systemVersion] floatValue]);
    return startOpenEarsLogging;
}

@end
