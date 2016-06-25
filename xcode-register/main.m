//
//  main.m
//  xcode-register
//
//  Created by Maxthon Chan on 6/25/16.
//  Copyright © 2016 DreamCity. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <getopt.h>
#import <libgen.h>

static const struct option options[] =
{
//  { name,         has_arg,            flag,   val }
    { "help",       no_argument,        NULL,   'h' },
    { "version",    no_argument,        NULL,   'V' },
    { "verbose",    no_argument,        NULL,   'v' },
    { "xcode",      required_argument,  NULL,   'x' },
    { NULL,         0,                  NULL,   0 }
};

void usage(const char *argv0)
{
    fprintf(stderr,
            "%1$s: register plugins for a version of Xcode.\n"
            "\n"
            "Usage:  %1$s [-x /Applications/Xcode.app] [<bundles>]\n"
            "\n"
            "Options:\n"
            "        --xcode, -x:    Path to the Xcode application.\n"
            "                        Default to /Applications/Xcode.app.\n"
            "        --verbose, -v:  Increase verbosity, print debug information.\n"
            "        --help, -h:     Print this message and exit.\n"
            "        --version, -V:  Print version information and exit.\n",
            basename((char *)argv0));
}

void version(const char *argv0)
{
    fprintf(stderr,
            "%1$s (DreamCity xcode-register) version 1.0\n"
            "Copyright (c) 2016 DreamCity. All rights reserved.\n"
            "This program is free software; you may redistribute it under the terms of\n"
            "the 3-clause BSD license. This program has absolutely no warranty.\n",
            basename((char *)argv0));
}

int main(int argc, const char * argv[]) {
    @autoreleasepool
    {
        NSString *xcodePath = @"/Applications/Xcode.app";
        NSMutableArray<NSBundle *> *xcodeBundles = [NSMutableArray array];
        BOOL verbose = NO;
        
        int ch = 0;
        while ((ch = getopt_long(argc, (char *const *)argv, "hVvx:", options, NULL)) != -1)
        {
            switch (ch)
            {
                case 'h':
                    usage(argv[0]);
                    exit(EXIT_SUCCESS);
                    break;
                case 'V':
                    version(argv[0]);
                    exit(EXIT_SUCCESS);
                    break;
                case 'v':
                    verbose = YES;
                    break;
                case 'x':
                    xcodePath = @(optarg);
                    break;
                default:
                    usage(argv[0]);
                    exit(EXIT_FAILURE);
            }
        }
        
        for (int idx = optind; idx < argc; idx++)
        {
            NSBundle *bundle = [NSBundle bundleWithPath:@(argv[idx])];
            if (bundle.infoDictionary[@"DVTPlugInCompatibilityUUIDs"])
                [xcodeBundles addObject:bundle];
        }
        
        if (!xcodeBundles.count)
        {
            NSString *bundlesDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"Developer/Shared/Xcode/Plug-ins/"];
            NSError *error = nil;
            NSArray<NSString *> *bundles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:bundlesDirectory
                                                                                               error:&error];
            if (!bundles)
            {
                fprintf(stderr, "Cannot load bundle list: %s. Try enumerate them in command line?\n", error.localizedDescription.UTF8String);
                exit(EXIT_FAILURE);
            }
            
            for (NSString *item in bundles)
            {
                NSBundle *bundle = [NSBundle bundleWithPath:[bundlesDirectory stringByAppendingPathComponent:item]];
                if (bundle.infoDictionary[@"DVTPlugInCompatibilityUUIDs"])
                    [xcodeBundles addObject:bundle];
            }
        }
        
        if (!xcodeBundles.count)
        {
            fprintf(stderr, "Cannot load bundles. Try enumerate them in command line?\n");
            exit(EXIT_FAILURE);
        }
        
        NSBundle *xcode = [NSBundle bundleWithPath:xcodePath];
        NSString *xcodeUUID = xcode.infoDictionary[@"DVTPlugInCompatibilityUUID"];
        
        if (!xcodeUUID.length)
        {
            fprintf(stderr, "Cannot load Xcode UUID. Are you sure you have Xcode properly installed at %s?\n", xcodePath.UTF8String);
            exit(EXIT_FAILURE);
        }
        
        if (verbose)
        {
            fprintf(stderr, "Installing UUID %s for Xcode installation %s to bundles:\n", xcodeUUID.UTF8String, xcodePath.UTF8String);
            for (NSBundle *item in xcodeBundles)
                fprintf(stderr, "* %s (%s)\n", item.bundlePath.UTF8String, item.bundleIdentifier.UTF8String);
        }
        
        for (NSBundle *bundle in xcodeBundles)
        {
            NSString *infoPath = [bundle.bundlePath stringByAppendingPathComponent:@"Contents/Info.plist"];
            NSError *error = nil;
            NSData *plistData = [NSData dataWithContentsOfFile:infoPath
                                                       options:0
                                                         error:&error];
            if (!plistData)
            {
                fprintf(stderr, "Failed to read file %s: %s.\n", infoPath.UTF8String, error.localizedDescription.UTF8String);
                continue;
            }
            
            error = nil;
            NSPropertyListFormat format = 0;
            NSMutableDictionary *infoDictionary = [NSPropertyListSerialization propertyListWithData:plistData
                                                                                            options:NSPropertyListMutableContainersAndLeaves
                                                                                             format:&format error:&error];
            
            if (!infoDictionary)
            {
                fprintf(stderr, "Failed to parse plist file %s: %s.\n", infoPath.UTF8String, error.localizedDescription.UTF8String);
                continue;
            }
            
            NSMutableArray *compatibilityUUIDs = infoDictionary[@"DVTPlugInCompatibilityUUIDs"];
            if ([compatibilityUUIDs containsObject:xcodeUUID])
            {
                fprintf(stderr, "Bundle %s (%s) already supports this Xcode version. Skipping.\n", bundle.bundlePath.UTF8String, bundle.bundleIdentifier.UTF8String);
                continue;
            }
            [compatibilityUUIDs addObject:xcodeUUID];
            
            error = nil;
            plistData = [NSPropertyListSerialization dataWithPropertyList:infoDictionary
                                                                   format:format
                                                                  options:0
                                                                    error:&error];
            if (!plistData)
            {
                fprintf(stderr, "Failed to generate Info.plist data: %s.\n", error.localizedDescription.UTF8String);
                continue;
            }
            
            error = nil;
            if (![plistData writeToFile:infoPath options:NSDataWritingAtomic error:&error])
            {
                fprintf(stderr, "Failed to write file %s: %s.\n", infoPath.UTF8String, error.localizedDescription.UTF8String);
                continue;
            }
            
            if (verbose)
            {
                fprintf(stderr, "Registered bundle %s (%s).\n", bundle.bundlePath.UTF8String, bundle.bundleIdentifier.UTF8String);
            }
        }
    }
    return EXIT_SUCCESS;
}
