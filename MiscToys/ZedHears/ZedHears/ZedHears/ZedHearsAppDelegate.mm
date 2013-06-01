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

#import "TelnetZH.h"

@implementation ZedHearsAppDelegate

@synthesize fileURL;

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
        if (APP_MODE == APP_MODE_NORMAL && cFrames < 15) {
            // Normal mode: we calibrate a "normal average" over 15 seconds
            // at the start of every minute-long capture "round."  Do that:
            if (!cFrames) {
                // We are on the first frame of the calibration round,
                // the average is equal to the frame's level:
                caliAvg = vDisplay;
            } else {
                // We are on a non-first frame of the calibration round,
                // the average is equal to the average level of this and
                // the previous audio frame:
                caliAvg = ((vDisplay+caliAvg)/2);
            }
            cFrames++;
        } else {
            if (APP_MODE == APP_MODE_NORMAL&&cFrames == 15)
                NSLog(@" !! Normal mode calibration completed: %i average",caliAvg);
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
            // Increment the "normal mode" frame counter as well:
            cFrames++;
            if (pFrames>5) {
                // We hit the 5-sample capacity for level comparison...
                if (!lastAvg) {
                    // The initial "calibration" pass for comparison completed,
                    // do nothing for now...
                } else {
                    if (APP_MODE == APP_MODE_SIMPLE) {
                        // Simple mode, knee-jerk adjustment:
                        if (avgHear>lastAvg&&avgHear-lastAvg>=10) {
                            if (APP_MODE >= APP_MODE_SIMPLE) { //FIXME: overkill?
                                // Saw a significant increase (10dB-ish), increase the receiver volume?
                                if (avgHear <= 30) {
                                    // We will decrement a bit *ONLY* if avgHear is more than 30,
                                    // this avoids us silencing things perhaps a bit too much:
                                    NSLog(@" !! Hit volume safety margin, won't decrease the volume...");
                                } else {
                                    // The margins are safe, dip the volume down a notch:
                                    NSLog(@" .. Decreasing volume a bit...");
                                    VolumeDn((char *)VSX_1022_K_HOSTNAME);
                                }
                            }
                        } else if (lastAvg>avgHear&&lastAvg-avgHear>=10) {
                            if (APP_MODE >= APP_MODE_SIMPLE) { //FIXME: overkill?
                                // Saw a significant decrease (10dB-ish), increase the receiver volume?
                                if (avgHear >= 50) {
                                    // We will increment a bit *ONLY* if avgHear is less than 60,
                                    // this avoids us flying off the handle and hurting our ears:
                                    NSLog(@" !! Hit volume safety margin, won't increase the volume...");
                                } else {
                                    // The margins are safe, kick the volume up a notch:
                                    NSLog(@" .. Increasing volume a bit...");
                                    VolumeUp((char *)VSX_1022_K_HOSTNAME);
                                }
                            }
                        }
                    } else if (APP_MODE == APP_MODE_NORMAL) {
                        // Normal mode, store current volume setting from receiver:
                        curVol = VolumePct((char *)VSX_1022_K_HOSTNAME);
                        // We only perform calibration-targeted adjustment if the
                        // volume level remains unchanged (except by AVC action):
                        if (curVol==preVol) {
                            // Perform calibration-targeted adjustment:
                            if (avgHear>caliAvg&&avgHear-caliAvg>=APP_MODE_NORMAL_SAFETY) {
                                if (APP_MODE >= APP_MODE_SIMPLE) { //FIXME: overkill?
                                    // Saw a significant increase, increase the receiver volume?
                                    if (avgHear <= 30) {
                                        // We will decrement a bit *ONLY* if avgHear is more than 30,
                                        // this avoids us silencing things perhaps a bit too much:
                                        NSLog(@" !! Hit volume safety margin, won't decrease the volume...");
                                    } else {
                                        // The margins are safe, dip the volume down a notch:
                                        NSLog(@" .. Decreasing volume a bit...");
                                        VolumeDn((char *)VSX_1022_K_HOSTNAME);
                                    }
                                }
                            } else if (caliAvg>avgHear&&caliAvg-avgHear>=APP_MODE_NORMAL_SAFETY) {
                                if (APP_MODE >= APP_MODE_SIMPLE) { //FIXME: overkill?
                                    // Saw a significant decrease, increase the receiver volume?
                                    if (avgHear >= 50) {
                                        // We will increment a bit *ONLY* if avgHear is less than 60,
                                        // this avoids us flying off the handle and hurting our ears:
                                        NSLog(@" !! Hit volume safety margin, won't increase the volume...");
                                    } else {
                                        // The margins are safe, kick the volume up a notch:
                                        NSLog(@" .. Increasing volume a bit...");
                                        VolumeUp((char *)VSX_1022_K_HOSTNAME);
                                    }
                                }
                            }
                        } else {
                            NSLog(@" !! User changed volume, remember, keep analyzing...");
                        }
                        preVol = curVol;
                    }
                }
                if (APP_MODE == APP_MODE_LEVELS) {
                    NSLog(@" .. Average level heard: %i",avgHear);
                }
                // Store this for analysing the next time we hit the comparison capacity:
                lastAvg = avgHear;
                // Reset the current comparison round counter:
                pFrames = 0;
            }
        }
        if (APP_MODE != APP_MODE_NORMAL)
            cFrames++;
        // If we have looped 60 seconds, reset recorder:
        if (cFrames >= 60) {
            NSLog(@" .. Recorder reset, 60 seconds");
            cFrames = 0;
            [self resetRecorder];
        }
    } else {
        NSLog(@" !! Skipped a step, recorder was stopped");
    }
}

- (void)resetRecorder
{
    // We need to clean up a bit if we were recording already:
    if ([self.recorder isRecording]) {
        // Cancel recording:
        [self.recorder stop];
        // Delete temporary:
        [[NSFileManager defaultManager] removeItemAtURL:self.fileURL error:nil];
    }
    // Reset variables, as needed:
    if (APP_MODE == APP_MODE_NORMAL) {
        pFrames = 0;
        avgHear = 0;
        lastAvg = 0;
        caliAvg = 0;
    }
    // Temporary file to record audio to for sampling/analysis from system audio input:
    self.fileURL = [NSURL fileURLWithPath:@"/tmp/ZedHears.wav"];
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
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Initialise variables:
    pFrames = 0;
    avgHear = 0;
    lastAvg = 0;
    cFrames = 0;
    caliAvg = 0;
    preVol = -1;
    curVol = -1;
    [self resetRecorder];
    // Create, schedule, and start a timer for sampling and analysis:
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(measurer:) userInfo:nil repeats:YES];
    // Silence OCD-irritating compiler warnings, do some other stuff:
    if (timer) {
        // Hide the annoying default window, stupidly:
        [self.window orderOut:self];
    }
}

@end
