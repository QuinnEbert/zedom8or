//  OpenEars 
//  http://www.politepix.com/openears
//
//  FliteController.m
//  OpenEars
//  FliteController.m
//
//  Copyright Politepix UG (haftungsbeschränkt) 2012. All rights reserved.
//  http://www.politepix.com
//  Contact at http://www.politepix.com/contact
//
//  this file is licensed under the Politepix Shared Source license found 
//  found in the root of the source distribution. Please see the file "Version.txt" in the root of 
//  the source distribution for the version number of this OpenEars package.


#import "FliteController.h"

#import "AudioSessionManager.h"


#import "RuntimeVerbosity.h"

@implementation FliteController

@synthesize audioPlayer; // The audio player used to play back the speech.
@synthesize openEarsEventsObserver; // We'll use the OpenEarsEventsObserver class to stay informed about important changes in status to other parts of OpenEars.
@synthesize speechData;
@synthesize speechInProgress;
@synthesize duration_stretch;
@synthesize target_mean;
@synthesize target_stddev;
@synthesize userCanInterruptSpeech;
@synthesize quietFlite;
@synthesize noAudioSessionOverrides;
@synthesize audioSessionHasBeenInstantiated;

extern int openears_logging;

#pragma mark -
#pragma mark Memory Management and Initialization


- (void)dealloc {

    dispatch_release(backgroundQueue);

	[audioPlayer release];
	openEarsEventsObserver.delegate = nil; // It's always a good idea to set the OpenEarsEventsObserver delegate to nil before releasing it.
	[openEarsEventsObserver release];
	[speechData release];

    [super dealloc];
}

- (id) init {
    if (self = [super init]) {
		speechInProgress = FALSE;
        userCanInterruptSpeech = FALSE;
        quietFlite = FALSE;
        noAudioSessionOverrides = FALSE;
        audioSessionHasBeenInstantiated = FALSE;
        backgroundQueue = dispatch_queue_create("com.politepix.openears.flitecontroller", NULL); 

    }
    return self;
}

#pragma mark -
#pragma mark Lazy Accessors

// Lazy accessor for the AVAudioPlayer that will play back the file recorded by Flite.
- (AVAudioPlayer *)audioPlayer {
    
// In previous versions, the audio session was called out to here unless the developer set a bit not to, but we're going to stop doing that on the assumption that if speech recognition needs it, it can regulate the session on its own and if that leads to any issues they can be addressed in PocketsphinxController development only.
    
	if (audioPlayer == nil) {
		if(openears_logging == 1) NSLog(@"Flite audio player was nil when referenced so attempting to allocate a new audio player.");		
		NSError *dataError = nil;
		audioPlayer = [[AVAudioPlayer alloc] initWithData:self.speechData error:&dataError];
		if(dataError) {
			if(openears_logging == 1) NSLog(@"Error while loading speech data for Flite: %@", [dataError description]);		
		} else {
			if(openears_logging == 1) NSLog(@"Loading speech data for Flite concluded successfully.");		
		}
			
		audioPlayer.meteringEnabled = TRUE; // Enable metering so we can expose the metering function to developers.
		audioPlayer.delegate = self; // I'm not sure if I'm ultimately going to use these AVAudioPlayerDelegate methods since one of them was being a bit weird but this is on for now.
	}
	return audioPlayer;
}

// Lazy accessor for the OpenEarsEventsObserver object.
- (OpenEarsEventsObserver *)openEarsEventsObserver {
	if (openEarsEventsObserver == nil) {
		openEarsEventsObserver = [[OpenEarsEventsObserver alloc] init];
        openEarsEventsObserver.delegate = self;
	}
	return openEarsEventsObserver;
}


#pragma mark -
#pragma mark AVAudioPlayer Delegate Methods

// I think I'm just using these for interruption notifications and error logging at the moment.

/* audioPlayerBeginInterruption: is called when the audio session has been interrupted while the player was playing. The player will have been paused. */
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player {
	if(openears_logging == 1) NSLog(@"AVAudioPlayer begin interruption called.");		
	[self interruptionRoutine:player];
}

- (void) finishPlaying {

    
    SEL method = NSSelectorFromString(@"externalPlaybackIsComplete");
    
    if([self respondsToSelector:method]) { // If we are hosting an external speech controller let's allow it to do wrap-up
         
        [self performSelector:method];
    } else { // Otherwise wrap up Flite speech here.
        [NSThread sleepForTimeInterval:.15]; // This amount is basically to account for the possible latency between the AVAudioPlayer thinking it is finished and the end of sound emerging from the speaker. If it turns out that speech recognition is switching on too soon, it might need to be longer.
        self.speechInProgress = FALSE;
        [self performSelectorOnMainThread:@selector(sendResumeNotificationOnMainThread) withObject:nil waitUntilDone:NO];
        self.audioPlayer = nil;
    }

}

/* audioPlayerEndInterruption:withFlags: is called when the audio session interruption has ended and this player had been interrupted while playing. */
/* Currently the only flag is AVAudioSessionInterruptionFlags_ShouldResume. */


- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withFlags:(NSUInteger)flags {
	if(openears_logging == 1) NSLog(@"AVAudioPlayer end interruption called.");		
	[self interruptionOverRoutine:player];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
	if(openears_logging == 1) NSLog(@"AVAudioPlayer did finish playing with success flag of %d", flag);
	[self finishPlaying];

}

/* if an error occurs while decoding it will be reported to the delegate. */
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
	if(openears_logging == 1) NSLog(@"Error while decoding AVAudioPlayer: %@", [error description]);
[self finishPlaying];
}



#pragma mark -
#pragma mark Interruption Handling

// If an interruption is received or ended either via the AVAudioPlayer delegate methods or OpenEarsEventsObserver, stop playing.

- (void) interruptionRoutine:(AVAudioPlayer *)player {
	
	if(openears_logging == 1) NSLog(@"AVAudioPlayer received an interruption");			
	
	if(player.playing == TRUE) {
		[player stop];
		self.speechInProgress = FALSE;
	}
    
    SEL method = NSSelectorFromString(@"externalInterruptionHasStarted");
    
    if([self respondsToSelector:method]) { // If we are hosting an external speech controller let's allow it to do wrap-up
        
        [self performSelector:method];
    }
}

- (void) interruptionOverRoutine:(AVAudioPlayer *)player {
	
	if(openears_logging == 1) NSLog(@"AVAudioPlayer interruption ended");			
	
	
	if(player.playing == TRUE) {
		[player stop];
		self.speechInProgress = FALSE;
	}
    
    SEL method = NSSelectorFromString(@"externalInterruptionHasEnded");
    
    if([self respondsToSelector:method]) { // If we are hosting an external speech controller let's allow it to do wrap-up
        
        [self performSelector:method];
    }
}

#pragma mark -
#pragma mark Notification Routing

// Notify OpenEarsEventsObserver that Flite needs recognition suspended due to speech.

- (void) sendSuspendNotificationOnMainThread {
	if(openears_logging == 1) NSLog(@"Flite sending suspend recognition notification.");		
	NSDictionary *userInfoDictionary = [NSDictionary dictionaryWithObject:@"FliteDidStartSpeaking" forKey:@"OpenEarsNotificationType"];
	NSNotification *notification = [NSNotification notificationWithName:@"OpenEarsNotification" object:nil userInfo:userInfoDictionary];
	[[NSNotificationCenter defaultCenter] performSelector:@selector(postNotification:) withObject:notification afterDelay:0.0];
}

- (void) sendResumeNotificationOnMainThread {
	if(openears_logging == 1) NSLog(@"Flite sending resume recognition notification.");		
	NSDictionary *userInfoDictionary = [NSDictionary dictionaryWithObject:@"FliteDidFinishSpeaking" forKey:@"OpenEarsNotificationType"];
	NSNotification *notification = [NSNotification notificationWithName:@"OpenEarsNotification" object:nil userInfo:userInfoDictionary];
	// need delay of length of buffer next (half a sec) since it is the last buffer-full that is being analyzed, not the next one.
	[[NSNotificationCenter defaultCenter] performSelector:@selector(postNotification:) withObject:notification afterDelay:0.5];
}

#pragma mark -
#pragma mark OpenEarsEventsObserver delegate methods



- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
	if(openears_logging == 1) NSLog(@"Flite sending interrupt speech request.");		

    // If userCanInterruptSpeech == TRUE, interrupt the playback if a new hypothesis is received via OpenEarsEventsObserver.
    
	if(self.userCanInterruptSpeech == TRUE)[self interruptTalking];

}

#pragma mark -
#pragma mark View Controller Methods

// Externally-accessed method that returns the playback levels of the Flite audio file.

- (Float32) fliteOutputLevel {
	if([self.audioPlayer isPlaying] == TRUE) {
		[self.audioPlayer updateMeters];		
		return [self.audioPlayer averagePowerForChannel:0];
	} return 0.0;
}

- (void) interruptTalking {
	if(openears_logging == 1) NSLog(@"Flite interrupting existing talking if necessary.");		
	/* If there is a statement being made already, let's do some cleanup */

    
     SEL method = NSSelectorFromString(@"externalInterruptTalking");
    
    
    if([self respondsToSelector:method]) { // If we are hosting an external speech controller let's allow it to do its own interruption requirements
        
        [self performSelector:method];
    } else { // Otherwise interrupt Flite speech here.
        if(self.speechInProgress == TRUE) {
            if(openears_logging == 1) NSLog(@"Flite speech is in progress so in order to interrupt it we are stopping playback.");		
            [self.audioPlayer stop];
        }
        
        if(self.speechInProgress == TRUE) {
            if(openears_logging == 1) NSLog(@"Flite audio player is instantiated while trying to interrupt speech so we are setting the audio player to nil.");
            audioPlayer = nil;
        }
        
    }
    
    
    
    
    

}

- (void) say:(NSString *)statement withVoice:(FliteVoice *)voiceToUse {
    
    [self.openEarsEventsObserver setDelegate:self]; // Sign up for the OpenEarsEventsObserver delegate methods.

    if([voiceToUse respondsToSelector:@selector(substringFromIndex:)]) {
        NSLog(@"It looks like you're trying to use the old-style voice names as an NSString with the FliteController say:withVoice: method, but it is now necessary to pass this method an FliteVoice instead of a voice name as an NSString. You can read more about this in the changelog and in the OpenEars documentation at http://www.politepix.com/openears/yourapp or see how it is implemented in the current OpenEarsSampleApp that is part of the OpenEars distribution at http://www.politepix.com/openears. The reason for this change is to make speech performance a little faster and to make it much easier for you to control the eventual binary size of your application without having to ever recompile the framework. Cancelling say:withVoice: so it doesn't crash.");
        return;  
    }
    
	cst_voice *voice = voiceToUse.voice; // Flite uses this to generate speech
	
	if(openears_logging == 1) NSLog(@"I'm running flite"); 

    NSTimeInterval start = 0.0;
    
    if(openears_logging == 1) {
        start = [NSDate timeIntervalSinceReferenceDate]; // If logging is on, let's time the Flite processing time so the developer can see if the voice chosen is fast enough.
    }
	const char *statementToSay = [statement UTF8String];
	
	if(target_mean > 0) {
		float actual_target_mean = voiceToUse.target_mean_default;
		float new_target_mean = actual_target_mean * target_mean; 
		flite_feat_set_float(voice->features,"int_f0_target_mean",new_target_mean);
		
	}
	
	if(target_stddev > 0) {
		
		float actual_target_stddev = voiceToUse.target_stddev_default;
		float new_target_stddev = actual_target_stddev * target_stddev; 
		flite_feat_set_float(voice->features,"int_f0_target_stddev",new_target_stddev);
		
	}
	
	if(duration_stretch > 0) {
		
		float actual_duration_stretch = voiceToUse.duration_stretch_default;
		float new_duration_stretch = actual_duration_stretch * duration_stretch; 
		flite_feat_set_float(voice->features,"duration_stretch",new_duration_stretch);
		
	}
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SetAllAudioSessionSettings" object:nil]; // We'll first check that all the audio session settings are correct for speech and fix them if not.
    
    
	cst_wave *speechwaveform = flite_text_to_wave(statementToSay,voice);
	
	// Let's make a virtual wav file
	
	char *headerstring;
    short headershort;
    int headerint;
    int numberofbytes;
	SInt8 *wavBuffer = (SInt8 *)malloc((speechwaveform->num_samples * 2) + 8 + 16 + 12 + 8);
	int writeoffset = 0;
    headerstring = "RIFF";
	memcpy(wavBuffer + writeoffset,headerstring,4);
	writeoffset += 4;
	
    numberofbytes = (speechwaveform->num_samples * 2) + 8 + 16 + 12;
	memcpy(wavBuffer + writeoffset,&numberofbytes,4);
	writeoffset += 4;
	
    headerstring = "WAVE";
	memcpy(wavBuffer + writeoffset,headerstring,4);
	writeoffset += 4;

    headerstring = "fmt ";
	memcpy(wavBuffer + writeoffset,headerstring,4);
	writeoffset += 4;

    numberofbytes = 16;
	memcpy(wavBuffer + writeoffset,&numberofbytes,4);
	writeoffset += 4;
       
    headershort = 0x0001;  // Type of sample, this is for PCM
	memcpy(wavBuffer + writeoffset,&headershort,2);
	writeoffset += 2;
       
    headershort = 1; // channels
	memcpy(wavBuffer + writeoffset,&headershort,2);
	writeoffset += 2;

    headerint = speechwaveform->sample_rate;  // rate
	memcpy(wavBuffer + writeoffset,&headerint,4);
	writeoffset += 4;
	
    headerint = (speechwaveform->sample_rate * 1 * sizeof(short)); // bytes per second
	memcpy(wavBuffer + writeoffset,&headerint,4);
	writeoffset += 4;

    headershort = (1 * sizeof(short)); // block alignment
	memcpy(wavBuffer + writeoffset,&headershort,2);
	writeoffset += 2;
       
    headershort = 2 * 8; // bits per sample
	memcpy(wavBuffer + writeoffset,&headershort,2);
	writeoffset += 2;
        
    headerstring = "data";
	memcpy(wavBuffer + writeoffset,headerstring,4);
	writeoffset += 4;
    
	headerint = (speechwaveform->num_samples * 2); // bytes in the sample buffer
	memcpy(wavBuffer + writeoffset,&headerint,4);
	writeoffset += 4;
	memcpy(wavBuffer + writeoffset,speechwaveform->samples,speechwaveform->num_samples * 2);

	int overallsize = (speechwaveform->num_samples * 1 * sizeof(short)) + 8 + 16 + 12 + 8;

	NSData *data = [[NSData alloc] initWithBytes:wavBuffer length:overallsize];
	self.speechData = data;
	[data release];
	free(wavBuffer);
	delete_wave(speechwaveform);
	if(openears_logging == 1) NSLog(@"I'm done running flite and it took %f seconds", [NSDate timeIntervalSinceReferenceDate] - start); // Deliver the timing info if logging is on.
	[self performSelectorOnMainThread:@selector(sendSuspendNotificationOnMainThread) withObject:nil waitUntilDone:NO]; // Send a suspend notification so (under some circumstances) recognition isn't on while speaking is in progress.
    
	[self.audioPlayer play]; // Play the sound created by Flite.
	self.speechInProgress = TRUE;

}


@end

