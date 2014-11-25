//
//  RuntimeVerbosity.m
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

#import "RuntimeVerbosity.h"

int openears_logging = 0; // The only place this can be altered is in a single method in the OpenEarsLogging singleton. Every other class and module just reads it.
int verbose_pocketsphinx = 0; // The only place this can be altered is in a single method in PocketsphinxController. Every other class and module just reads it.
int verbose_cmuclmtk = 0;// The only place this can be altered is in a single method in LangugeModelGenerator. Every other class and module just reads it.
int returner = 1;
int perform_request = 0;