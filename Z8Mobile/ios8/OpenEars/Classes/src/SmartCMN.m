//
//  SmartCMN.m
//  OpenEars
//
//  Created by Halle on 1/27/13.
//  Copyright (c) 2014 Politepix. All rights reserved.
//

#import "SmartCMN.h"

@implementation SmartCMN

extern int openears_logging;

#if TARGET_IPHONE_SIMULATOR
NSString * const DeviceOrSimulator = @"Simulator";
#else
NSString * const DeviceOrSimulator = @"Device";
#endif

#pragma mark -
#pragma mark Smart CMN Management
#pragma mark -

- (NSString *) pathToCmnPlistAsString {
    return [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"cmnvalues.plist"];
}

- (void) removeCmnPlist {
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSError *fileRemovalError = nil;
    BOOL removalSuccess = [fileManager removeItemAtPath:[self pathToCmnPlistAsString] error:&fileRemovalError];
    if (removalSuccess == FALSE) {
        if(openears_logging==1) {
            NSLog(@"Error while removing cmn plist: %@", [fileRemovalError description]);    
        }
    }
    [fileManager release];
}

- (BOOL) cmnInitPlistFileExists {
    if ( [[NSFileManager defaultManager] fileExistsAtPath:[self pathToCmnPlistAsString]] ) {
        return TRUE;
    } else {
        return FALSE;
    }
}

- (NSMutableDictionary *) loadCmnPlistIntoDictionary {
    
    return [NSMutableDictionary dictionaryWithContentsOfFile:[self pathToCmnPlistAsString]];
}

- (BOOL) writeOutCmnPlistFromDictionary:(NSMutableDictionary *)mutableDictionary {
    return [mutableDictionary writeToFile:[self pathToCmnPlistAsString] atomically:YES];
}

- (BOOL) valuesLookReasonableforCmn:(float)cmn andRoute:(CFStringRef)route {
    
    if(cmn != cmn || route == NULL) { // If there are no values here, stop before trying to read them at all.
        return FALSE;
    }
    
    if((cmn > 3 && cmn < 120) && (([(NSString *)route length] > 2) && ([(NSString *)route length] < 100))) {
        return TRUE;
    } else {
        return FALSE;
    }
}

- (void) finalizeCmn:(float)cmnFloat atRoute:(CFStringRef)routeString forAcousticModelAtPath:(NSString *)acousticModelPath withModelName:(NSString *)modelName {
    
    NSMutableDictionary *mutableCmnPlistDictionary = nil;
    
    if([self valuesLookReasonableforCmn:cmnFloat andRoute:routeString] == TRUE) {
        
        NSNumber *cmnNumber = [NSNumber numberWithFloat:cmnFloat];
        
        NSString *addressToValue = [self addressToCMNValueForAcousticModelAtPath:acousticModelPath atRoute:routeString withModelName:modelName ];
        
        if([self cmnInitPlistFileExists] == TRUE) {
            mutableCmnPlistDictionary = [self loadCmnPlistIntoDictionary]; 
            [mutableCmnPlistDictionary setObject:cmnNumber forKey:addressToValue];   
        } else {
            mutableCmnPlistDictionary = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:cmnNumber,nil] forKeys:[NSArray arrayWithObjects:addressToValue,nil]];
        }
    }
    
    BOOL writeOutSuccess = [self writeOutCmnPlistFromDictionary:mutableCmnPlistDictionary];
    
    if(writeOutSuccess == FALSE) {
        NSLog(@"Writing out cmn plist was not successful");
    }
}

- (float) defaultCMNForAcousticModelAtPath:(NSString *)path {
    
    if([path rangeOfString:@"AcousticModelSpanish"].location != NSNotFound) return 9.5;
    else if([path rangeOfString:@"AcousticModelEnglish"].location != NSNotFound) return 47;
    else return 47;    
}

- (float) smartCmnValuesForRoute:(CFStringRef)routeString forAcousticModelAtPath:(NSString *)acousticModelPath withModelName:(NSString *)modelName {
    
    // if there is a plist and
    // if the plist has an entry for this route and acoustic model and device
    // set the cmninit value to that entry.
    if([self cmnInitPlistFileExists]) {
        
        NSDictionary *cmnPlistDictionary = (NSDictionary *)[self loadCmnPlistIntoDictionary];
        
        NSString *addressToValue = [self addressToCMNValueForAcousticModelAtPath:acousticModelPath atRoute:routeString withModelName:modelName];
        
        if([cmnPlistDictionary objectForKey:addressToValue]) {
            float previouscmn = [[cmnPlistDictionary objectForKey:addressToValue]floatValue];
            
            if((previouscmn == previouscmn) && (previouscmn > 3) && (previouscmn < 100)) { // I fink you not freeky and I like you a lot.
                if(openears_logging == 1) {
                    NSLog(@"Restoring SmartCMN value of %f", previouscmn);   
                }
                return previouscmn;
                
            } else {
                if(openears_logging == 1) {
                    NSLog(@"SmartCMN didn't like the value %f so it is using the fresh CMN value %f.", previouscmn,[self defaultCMNForAcousticModelAtPath:acousticModelPath]);   
                }    
                return [self defaultCMNForAcousticModelAtPath:acousticModelPath];
            }
        } else {
            if(openears_logging == 1) {
                NSLog(@"There was no previous CMN value in the plist so we are using the fresh CMN value %f.",[self defaultCMNForAcousticModelAtPath:acousticModelPath]);
            }  
            return [self defaultCMNForAcousticModelAtPath:acousticModelPath];
        }
    } else {
        if(openears_logging == 1) {
            NSLog(@"There is no CMN plist so we are using the fresh CMN value %f.",[self defaultCMNForAcousticModelAtPath:acousticModelPath]);
        }  
        return [self defaultCMNForAcousticModelAtPath:acousticModelPath];        
    }
}

- (NSString *) addressToCMNValueForAcousticModelAtPath:(NSString *)acousticModelPath atRoute:(CFStringRef)routeString withModelName:(NSString *) modelName {
    
    return [NSString stringWithFormat:@"%@.%@.%@.%@",modelName,DeviceOrSimulator,[acousticModelPath lastPathComponent],(NSString *)routeString];
}




@end
