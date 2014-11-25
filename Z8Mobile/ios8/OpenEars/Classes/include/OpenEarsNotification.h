//
//  OpenEarsNotification.h
//  OpenEars
//
//  Created by Halle on 1/27/13.
//  Copyright (c) 2014 Politepix. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 @class  OpenEarsNotification
 @brief  Convenience class for sending an OpenEarsNotification.
 */

@interface OpenEarsNotification : NSObject


/** Send notification. */
+ (void) performOpenEarsNotificationOnMainThread:(NSString *)notificationNameAsString withOptionalObjects:(NSArray *)objects andKeys:(NSArray *)keys;

@end
