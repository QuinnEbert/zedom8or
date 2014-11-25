//
//  SmartCMN.h
//  OpenEars
//
//  Created by Halle on 1/27/13.
//  Copyright (c) 2014 Politepix. All rights reserved.
//


/**
 @class  SmartCMN
 @brief  SmartCMN
 */

@interface SmartCMN : NSObject {
}
- (void) finalizeCmn:(float)cmnFloat atRoute:(CFStringRef)routeString forAcousticModelAtPath:(NSString *)acousticModelPath withModelName:(NSString *)modelName;
- (float) smartCmnValuesForRoute:(CFStringRef)routeString forAcousticModelAtPath:(NSString *)acousticModelPath withModelName:(NSString *)modelName;
- (void) removeCmnPlist;

@end
