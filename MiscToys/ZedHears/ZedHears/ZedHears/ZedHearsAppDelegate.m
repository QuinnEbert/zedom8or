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
    // Only process audio levels when the recording's running:
    if ([self.recorder isRecording]) {
        // Force the AVAudioRecorder to compute the current input level:
        [self.recorder updateMeters];
        // Compute the (approximate) decibel level of the first audio channel
        // from the input device by sampling the level from the AVAudioRecorder,
        // and subtracting that value from 65 (this always worked reliably in my
        // own personal test cases):
        int vDisplay = (65-abs((int)[self.recorder averagePowerForChannel:0]));
        // Normalise the frame's level to a positive number (roughly decibels),
        // minimum of positive one, maximum of positive eighty:
        vDisplay = MIN(80,vDisplay);
        vDisplay = MAX(vDisplay,01);
        if (!pFrames) {
            // We are on the first frame of the comparison round,
            // the average is equal to the frame's level:
            avgHear = vDisplay;
        } else {
            // We are on a non-first frame of the comparison round,
            // the average is equal to the average level of this and
            // the previous audio frame:
            avgHear = ((vDisplay+avgHear)/2);
        }
        // Increment the current comparison round counter:
        pFrames++;
        if (pFrames>5) {
            // We hit the 5-sample capacity for level comparison...
            if (!lastAvg) {
                // The initial "calibration" pass for comparison completed,
                // do nothing for now...
            } else {
                if (avgHear>lastAvg&&avgHear-lastAvg>=10) {
                    // Saw a significant increase (10dB-ish), decrease the receiver volume?
                    
                } else if (lastAvg>avgHear&&lastAvg-avgHear>=10) {
                    // Saw a significant decrease (10dB-ish), increase the receiver volume?
                    
                }
            }
            // Store this for analysing the next time we hit the comparison capacity:
            lastAvg = avgHear;
            // Reset the current comparison round counter:
            pFrames = 0;
        }
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Initialise variables:
    pFrames = 0;
    avgHear = 0;
    lastAvg = 0;
    // Temporary file to record audio to for sampling/analysis from system audio input:
    NSURL *fileURL = [NSURL fileURLWithPath:@"/tmp/ZedHears.wav"];
    // Settings to use for the AVAudioRecorder for sampling:
    NSDictionary *audioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInt: AVAudioQualityMax],AVEncoderAudioQualityKey,
                                   [NSNumber numberWithInt:              16  ],AVEncoderBitRateKey,
                                   [NSNumber numberWithInt:               1  ],AVNumberOfChannelsKey,
                                   [NSNumber numberWithFloat:          8000.0],AVSampleRateKey,
                                   nil];
    // Initialise the sampling/analysis AVAudioRecorder:
    self.recorder = [[AVAudioRecorder alloc] initWithURL:fileURL settings:audioSettings error:NULL];
    // Tell the recorder to support metering:
    [self.recorder setMeteringEnabled:YES];
    // Tell the recorder to start recording:
    [self.recorder record];
    // Create, schedule, and start a timer for sampling and analysis:
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(measurer:) userInfo:nil repeats:YES];
    // Silence OCD-irritating compiler warnings:
    if (timer) {
        // Do nothing besides silence the compiler warnings... ;)
    }
}

@end
