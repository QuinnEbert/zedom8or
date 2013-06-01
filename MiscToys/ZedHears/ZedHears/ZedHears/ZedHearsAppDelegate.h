//
//  ZedHearsAppDelegate.h
//  ZedHears
//
//  LICENCE:
//   + You may compile this code and run it.
//   + You may NOT modify this code.
//   + You may NOT redistribute this code in any modified form.
//   + You may NOT use this code in any other way than accounted for above.
//   + These LICENCE terms are subject to change without any notice.
//
//  Created by Quinn Ebert on 5/24/13.
//  Copyright (c) 2013 Quinn Ebert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <AVFoundation/AVAudioRecorder.h>

#define APP_MODE_LEVELS 0        // No-action mode, outputs audio levels only
#define APP_MODE_SIMPLE 1        // Second-by-second level analysis, action based on 5-second averages
#define APP_MODE_NORMAL 2        // Better analysis, 1-minute "rounds," each calibrates/maintains 15-second average

#define APP_MODE APP_MODE_NORMAL // <=== SELECT YOUR MODE

#define APP_MODE_NORMAL_SAFETY 5 // Set the (approx.) "grace" (in volume level settings) ignored by normal mode checks

#define VSX_1022_K_HOSTNAME "192.168.1.Xyz"

@interface ZedHearsAppDelegate : NSObject <NSApplicationDelegate> {
    int pFrames;
    int avgHear;
    int lastAvg;
    int cFrames;
    int caliAvg;
    long preVol;
    long curVol;
    NSURL *fileURL;
}

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic,strong) AVAudioRecorder *recorder;

@property (strong, retain) NSURL *fileURL;

@end
