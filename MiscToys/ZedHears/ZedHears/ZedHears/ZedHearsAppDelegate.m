//
//  ZedHearsAppDelegate.m
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

#import "ZedHearsAppDelegate.h"

@implementation ZedHearsAppDelegate

- (void)measurer:(NSTimer *)timer
{
    if ([self.recorder isRecording]) {
        if (pFrames==5) {
            avgHear = 0;
        }
        [self.recorder updateMeters];
        int vDisplay = (65-abs((int)[self.recorder averagePowerForChannel:0]));
        vDisplay = MIN(80,vDisplay);
        vDisplay = MAX(vDisplay,01);
        if (!pFrames) {
            avgHear = vDisplay;
        } else {
            avgHear = ((vDisplay+avgHear)/2);
        }
        pFrames++;
        if (pFrames>5) {
            if (!lastAvg) {
                // The initial "fill" pass of calibration completed,
                // do nothing for now...
            } else {
                if (avgHear>lastAvg&&avgHear-lastAvg>=10) {
                    NSLog(@" !! Significant increase! (avg: %i, prv: %i)",avgHear,lastAvg);
                } else if (lastAvg>avgHear&&lastAvg-avgHear>=10) {
                    NSLog(@" !! Significant decrease! (avg: %i, prv: %i)",avgHear,lastAvg);
                }
            }
            lastAvg = avgHear;
            pFrames = 0;
        }
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    pFrames = 0;
    avgHear = 0;
    lastAvg = 0;
    NSURL *fileURL = [NSURL fileURLWithPath:@"/tmp/ZedHears.wav"];
    NSDictionary *audioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInt: AVAudioQualityMax],AVEncoderAudioQualityKey,
                                   [NSNumber numberWithInt:              16  ],AVEncoderBitRateKey,
                                   [NSNumber numberWithInt:               1  ],AVNumberOfChannelsKey,
                                   [NSNumber numberWithFloat:          8000.0],AVSampleRateKey,
                                   nil];
    self.recorder = [[AVAudioRecorder alloc] initWithURL:fileURL settings:audioSettings error:NULL];
    [self.recorder setMeteringEnabled:YES];
    [self.recorder record];
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(measurer:) userInfo:nil repeats:YES];
    if (timer) {
        // Do nothing besides silence the compiler warnings... ;)
    }
}

@end
