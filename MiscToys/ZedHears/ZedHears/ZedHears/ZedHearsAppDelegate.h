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

@interface ZedHearsAppDelegate : NSObject <NSApplicationDelegate> {
    int pFrames;
    int avgHear;
    int lastAvg;
}

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic,strong) AVAudioRecorder *recorder;

@end
