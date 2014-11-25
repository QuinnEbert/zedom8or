//
//  CommandArray.h
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
/**\cond HIDDEN_SYMBOLS*/
#import <Foundation/Foundation.h>

#define kJSGFLanguageWeight 3

@interface CommandArray : NSObject

- (NSArray *)commandArrayForlanguageModel:(NSString *)languageModelPath dictionaryPath:(NSString *)dictionaryPath acousticModelPath:(NSString *)acousticModelPath isJSGF:(BOOL)languageModelIsJSGF;

@end
/**\endcond */
