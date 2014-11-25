//
//  OpenEarsStaticAnalysisToggle.h
//  OpenEars
//
//  Created by Halle on 8/21/13.
//  Copyright (c) 2013 Politepix. All rights reserved.
//

#ifndef OpenEars_OpenEarsStaticAnalysisToggle_h
#define OpenEars_OpenEarsStaticAnalysisToggle_h

// Because many of the dependencies in OpenEars are 10-20 years old and sometimes use coding conventions that are out of style, some of them trigger large numbers of static analysis warnings that are probably dangerous to act on. If we accept that the dependency functions are working correctly and therefore aren't going to change them, and in the majority of cases it should be assumed that they are due to the long period of real-world testing, it is probably preferable most of the time not to see them so it is possible to easily see static analysis warnings in OpenEars itself. However, this should be possible to turn off in order to get help with issues that may actually arise within a dependency based on current or future changes of standards, compilers, or just actual bugs that haven't come up before for various reasons. In order to receive static analysis warnings for dependencies in OpenEars, uncomment #define STATICANALYZEDEPENDENCIES below. If you would like to see every reference to an int that gets shortened from a long, uncomment SHOW64BITCOMPLAINTS. No need to change the digit following the definition.


//#define STATICANALYZEDEPENDENCIES 1
//#define SHOW64BITCOMPLAINTS 1

#endif
