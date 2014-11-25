//
//  Version.h
//  OpenEars
//
//  Created by Halle on 9/24/12.
//  Copyright (c) 2012 Politepix. All rights reserved.
//

#define kCurrentVersionTokenized @"{{{{1.71}}}}"
#define kCurrentVersion [[kCurrentVersionTokenized stringByReplacingOccurrencesOfString:@"{" withString:@""] stringByReplacingOccurrencesOfString:@"}" withString:@""]
