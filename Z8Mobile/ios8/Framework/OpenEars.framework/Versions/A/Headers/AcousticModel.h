//
//  AcousticModel.h
//  OpenEars
//
//  Created by Halle on 8/14/13.
//  Copyright (c) 2013 Politepix. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 @class  AcousticModel
 @brief  Convenience class for accessing the acoustic model bundles. All this does is allow you to reference your chosen model by including this header in your class and then letting you call [AcousticModel pathToModel:@"AcousticModelEnglish"] or [AcousticModel pathToModel:@"AcousticModelSpanish"] in any of the methods which ask for a path to an acoustic model.
 */

@interface AcousticModel : NSObject


/** Reference the path to any acoustic model bundle you've dragged into your project (such as AcousticModelSpanish.bundle or AcousticModelEnglish.bundle) by calling this class method like [AcousticModel pathToModel:@"AcousticModelEnglish"] after importing this class. */
+ (NSString *) pathToModel:(NSString *) acousticModelBundleName;

@end
