//  OpenEars 
//  http://www.politepix.com/openears
//
//  AudioSessionManager.m
//  OpenEars
//
//  AudioSessionManager is a class for initializing the Audio Session and forwarding changes in the Audio
//  Session to the OpenEarsEventsObserver class so they can be reacted to when necessary.
//
//  Copyright Politepix UG (haftungsbeschränkt) 2012. All rights reserved.
//  http://www.politepix.com
//  Contact at http://www.politepix.com/contact
//
//  this file is licensed under the Politepix Shared Source license found 
//  found in the root of the source distribution. Please see the file "Version.txt" in the root of 
//  the source distribution for the version number of this OpenEars package.

/*
 *  System Versioning Preprocessor Macros
 */ 

#import <UIKit/UIDevice.h>

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

/*
 *  Usage
 */ 


#import "AudioSessionManager.h"
#import "RuntimeVerbosity.h"


@implementation AudioSessionManager
@synthesize soundMixing;
@synthesize audioMode;

extern int openears_logging;

static AudioSessionManager *sharedStaticAudioSessionManager = nil;

void audioSessionInterruptionListener(void *inClientData,
									  UInt32 inInterruptionState);
void performRouteChange(void);
void audioSessionPropertyListener(void *inClientData,
								  AudioSessionPropertyID inID,
								  UInt32 inDataSize,
								  const void *inData);

void audioSessionPropertyListener(void *inClientData,
								  AudioSessionPropertyID inID,
								  UInt32 inDataSize,
								  const void *inData);






- (void)dealloc {

       [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

- (id) init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(setAllAudioSessionSettings) 
                                                     name:@"SetAllAudioSessionSettings"
                                                   object:nil];
        soundMixing = FALSE;
    }
    return self;
}



+ (id)sharedAudioSessionManager {
    @synchronized(self) {
        if(sharedStaticAudioSessionManager == nil)
            sharedStaticAudioSessionManager = [[super allocWithZone:NULL] init];
    }
    return sharedStaticAudioSessionManager;
}
+ (id)allocWithZone:(NSZone *)zone {
    return [[self sharedAudioSessionManager] retain];
}
- (id)copyWithZone:(NSZone *)zone {
    return self;
}
- (id)retain {
    return self;
}
- (NSUInteger)retainCount {
    return UINT_MAX; //denotes an object that cannot be released
}
- (oneway void)release {
    // never release
}
- (id)autorelease {
    return self;
}


void audioSessionInterruptionListener(void *inClientData,
									  UInt32 inInterruptionState) { // Listen for interruptions to the Audio Session.
	
	
	// It's important on the iPhone to have the ability to react to an interruption in app audio such as an incoming or user-initiated phone call.
	// For Pocketsphinx it might be necessary to restart the recognition loop afterwards, or the app's UI might need to be reset or redrawn. 
	// By observing for the AudioSessionInterruptionDidBegin and AudioQueueInterruptionEnded NSNotifications and forwarding them to OpenEarsEventsObserver,
	// the developer using OpenEars can react to an interruption.
	 
	if (inInterruptionState == kAudioSessionBeginInterruption) { // There was an interruption.

		
		if(openears_logging == 1) NSLog(@"The Audio Session was interrupted.");
		NSDictionary *userInfoDictionary = [NSDictionary dictionaryWithObject:@"AudioSessionInterruptionDidBegin" forKey:@"OpenEarsNotificationType"]; // Send notification to OpenEarsEventsObserver.
		NSNotification *notification = [NSNotification notificationWithName:@"OpenEarsNotification" object:nil userInfo:userInfoDictionary];
		[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
		
		
	} else if (inInterruptionState == kAudioSessionEndInterruption) { // The interruption is over.
	
		NSDictionary *userInfoDictionary = [NSDictionary dictionaryWithObject:@"AudioSessionInterruptionDidEnd" forKey:@"OpenEarsNotificationType"]; // Send notification to OpenEarsEventsObserver.
		NSNotification *notification = [NSNotification notificationWithName:@"OpenEarsNotification" object:nil userInfo:userInfoDictionary];
		[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
		if(openears_logging == 1) NSLog(@"The Audio Session interruption is over.");
	}
}

void performRouteChange() {
	
	if(openears_logging == 1) NSLog(@"Performing Audio Route change.");
	CFStringRef audioRoute;
	UInt32 size = sizeof(CFStringRef);
	OSStatus getAudioRouteError = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &audioRoute); /* Get the new route */
	
	if (getAudioRouteError != 0) {
		if(openears_logging == 1) NSLog(@"Error %d: Unable to get new audio route.", (int)getAudioRouteError);
	} else {
		
        
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // Create the pool.
        
		if(openears_logging == 1) NSLog(@"The new audio route is %@",(NSString *)audioRoute);			
		
		NSDictionary *userInfoDictionary = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"AudioRouteDidChangeRoute",[NSString stringWithFormat:@"%@",audioRoute],nil] forKeys:[NSArray arrayWithObjects:@"OpenEarsNotificationType",@"AudioRoute",nil]];
		NSNotification *notification = [NSNotification notificationWithName:@"OpenEarsNotification" object:nil userInfo:userInfoDictionary];
		[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES]; // Forward the audio route change to OpenEarsEventsObserver.
        
        [pool drain];
	}
    
    //CFRelease(audioRoute); // This either results in a small leak or an overrelease depending on circumstances and the leak is preferable until I know exactly why.
}


void audioSessionPropertyListener(void *inClientData,
								  AudioSessionPropertyID inID,
								  UInt32 inDataSize,
								  const void *inData) { // We also listen to some Audio Session properties so that we can react to changes such as new audio routes (e.g. headphones plugged/unplugged).
	
	 // It may be necessary to react to changes in the audio route; for instance, if the user inserts or removes the headphone mic, 
	 // it's probably necessary to restart a continuous recognition loop in order to calibrate to the changed background levels.
	 
	
	if (inID == kAudioSessionProperty_AudioRouteChange) { // If the property change triggering the function is a change of audio route,

        //   if(openears_logging == 1)  {
            CFStringRef audioRouteOldRoute = (CFStringRef)[(NSDictionary *)inData valueForKey:(NSString *)CFSTR(kAudioSession_AudioRouteChangeKey_OldRoute)];
        //}
		CFNumberRef audioRouteChangeReasonKey = (CFNumberRef)CFDictionaryGetValue((CFDictionaryRef)inData, CFSTR(kAudioSession_AudioRouteChangeKey_Reason));
		SInt32 audioRouteChangeReason;
		CFNumberGetValue(audioRouteChangeReasonKey, kCFNumberSInt32Type, &audioRouteChangeReason); // Get the reason for the route change.
			
		if(openears_logging == 1) NSLog(@"Audio route has changed for the following reason:");
		
		BOOL performChange = TRUE;
		
		// We only want to perform the OpenEars full-on notification and delegate method route change for a device change or a wake from sleep. We don't want to do it for programmatic changes to the audio session or mysterious reasons.
		
		switch (audioRouteChangeReason) {
			case kAudioSessionRouteChangeReason_Unknown:
				performChange = FALSE;
				if(openears_logging == 1) NSLog(@"Reason unknown");
				break;
			case kAudioSessionRouteChangeReason_NewDeviceAvailable:
				performChange = TRUE;
				if(openears_logging == 1) NSLog(@"A new device has become available");
				break;	
			case kAudioSessionRouteChangeReason_OldDeviceUnavailable:
				performChange = TRUE;
				if(openears_logging == 1) NSLog(@"An old device has become unavailable");
				break;
			case kAudioSessionRouteChangeReason_CategoryChange:
				performChange = FALSE;
				if(openears_logging == 1) NSLog(@"There has been a change of category");
				break;	
			case kAudioSessionRouteChangeReason_Override:
				performChange = FALSE;
				if(openears_logging == 1) NSLog(@"There has been an override to the audio session");
				break;
			case kAudioSessionRouteChangeReason_WakeFromSleep:
				performChange = TRUE;
				if(openears_logging == 1) NSLog(@"The device has awoken from sleep");
				break;	
			case kAudioSessionRouteChangeReason_NoSuitableRouteForCategory:
				performChange = FALSE;
				if(openears_logging == 1) NSLog(@"There is no suitable route for the category");
				break;				
			default:
				performChange = FALSE;
				if(openears_logging == 1) NSLog(@"Unknown reason");
				break;
		}

		if(openears_logging == 1) NSLog(@"The previous audio route was %@", (NSString *)audioRouteOldRoute);

		CFStringRef audioRoute;
		UInt32 size = sizeof(CFStringRef);
		OSStatus getAudioRouteError = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &audioRoute);
		if(getAudioRouteError) {
			if(openears_logging != 0) NSLog(@"Error getting current audio route: %d", (int)getAudioRouteError);	
		}
		
		if(performChange == TRUE) {
	
			if(openears_logging == 1) NSLog(@"This is a case for performing a route change. Before the route change, the current route is %@",(NSString *)audioRoute);
			performRouteChange();
		} else {
			if(openears_logging == 1) NSLog(@"This is not a case in which OpenEars performs a route change voluntarily. At the close of this function, the audio route is %@",(NSString *)audioRoute);
		}
        
		if(getAudioRouteError == 0) {        
           //CFRelease(audioRoute); // This either results in a small leak or an overrelease depending on circumstances and the leak is preferable until I know exactly why.
        }
        
	} else if (inID == kAudioSessionProperty_AudioInputAvailable) {
		
		 // Here we're listening and sending notifications for changes in the availability of the input device.
		 
		if(openears_logging == 1) NSLog(@"There was a change in input device availability: ");
		if (inDataSize == sizeof(UInt32)) {
			UInt32 audioInputIsAvailable = *(UInt32*)inData;
			if(audioInputIsAvailable == 0) { // Input became unavailable.
				
				NSDictionary *userInfoDictionary = [NSDictionary dictionaryWithObject:@"AudioInputDidBecomeUnavailable" forKey:@"OpenEarsNotificationType"];
				NSNotification *notification = [NSNotification notificationWithName:@"OpenEarsNotification" object:nil userInfo:userInfoDictionary];
				[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES]; // Forward the input availability change to OpenEarsEventsObserver.
				if(openears_logging == 1) NSLog(@"the audio input is now unavailable.");
			} else if (audioInputIsAvailable == 1) { // Input became available again.
				
				if(openears_logging == 1) NSLog(@"the audio input is now available.");
				NSDictionary *userInfoDictionary = [NSDictionary dictionaryWithObject:@"AudioInputDidBecomeAvailable" forKey:@"OpenEarsNotificationType"];
				NSNotification *notification = [NSNotification notificationWithName:@"OpenEarsNotification" object:nil userInfo:userInfoDictionary];
				[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES]; // Forward the input availability change to OpenEarsEventsObserver.
			}
		}
	}
}




- (void) setAllAudioSessionSettings {

    // Projects using Pocketsphinx and Flite should use the Audio Session Category kAudioSessionCategory_PlayAndRecord.
    // Using this category routes playback to the ear speaker when the headphones aren't plugged in.
    // This isn't really appropriate for a speech recognition/tts app as far as I can see so I'm re-routing the output to the 
    // main speaker.
    
    if(openears_logging == 1) NSLog(@"Checking and resetting all audio session settings.");

    
    
    
    
    
    UInt32 audioInputAvailable = 0; 
    UInt32 size = sizeof(audioInputAvailable);
    OSStatus audioInputAvailableError = AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &size, &audioInputAvailable);
    if (audioInputAvailableError != noErr) {
        if(openears_logging == 1) NSLog(@"Error %d: Unable to get the availability of the audio input.", (int)audioInputAvailableError);
    }
    if(audioInputAvailableError == 0 && audioInputAvailable == 0) {
        if(openears_logging == 1) NSLog(@"There is no audio input available.");
    } 
    
    
    /*
     kAudioSessionCategory_AmbientSound               = 'ambi',
     kAudioSessionCategory_SoloAmbientSound           = 'solo',
     kAudioSessionCategory_MediaPlayback              = 'medi',
     kAudioSessionCategory_RecordAudio                = 'reca',
     kAudioSessionCategory_PlayAndRecord              = 'plar',
     kAudioSessionCategory_AudioProcessing            = 'proc'
     */
    
    UInt32 audioCategoryClassification;
    if(audioInputAvailable == 1) {
        audioCategoryClassification = kAudioSessionCategory_PlayAndRecord;
    } else {
        audioCategoryClassification = kAudioSessionCategory_SoloAmbientSound;
    }
    UInt32 audioCategoryCheckSize = sizeof (UInt32);
    UInt32 audioCategoryCheck = 999;
    
    AudioSessionGetProperty (kAudioSessionProperty_AudioCategory, &audioCategoryCheckSize, &audioCategoryCheck);
   
    if(audioCategoryCheck == audioCategoryClassification) {
        if(openears_logging == 1) NSLog(@"audioCategory is correct, we will leave it as it is.");   
    } else {
        if(openears_logging == 1) NSLog(@"audioCategory is incorrect, we will change it."); 
        UInt32 audioCategory = audioCategoryClassification; // Set the Audio Session category to kAudioSessionCategory_PlayAndRecord.
        OSStatus audioCategoryStatus = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory);
        if (audioCategoryStatus != noErr) {
            if(openears_logging == 1) NSLog(@"Error %d: Unable to set audio category.", (int)audioCategoryStatus);
        } else {
            if(audioCategoryClassification == kAudioSessionCategory_PlayAndRecord) {
                if(openears_logging == 1) NSLog(@"audioCategory is now on the correct setting of kAudioSessionCategory_PlayAndRecord."); 
            } else {
                if(openears_logging == 1) NSLog(@"audioCategory is now on the correct setting of kAudioSessionCategory_AmbientSound.");
            }
        }
    }

    if(self.audioMode) {
        
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0")) { // we can set audio modes if we're in 5.0 or more

            // Thank you to hartsteins for proposing this and this code
            
            UInt32 audioModeClassification = nil;
            
            if([self.audioMode isEqualToString:@"Default"]) {
                audioModeClassification= kAudioSessionMode_Default;
            } else if([self.audioMode isEqualToString:@"VoiceChat"]) {
                audioModeClassification= kAudioSessionMode_VoiceChat;
            } else if([self.audioMode isEqualToString:@"VideoRecording"]) {
                audioModeClassification= kAudioSessionMode_VideoRecording;
            } else if([self.audioMode isEqualToString:@"Measurement"]) {
                audioModeClassification= kAudioSessionMode_Measurement;
            } else {
                audioModeClassification= kAudioSessionMode_Default;
            }
            
            UInt32 audioModeCheckSize = sizeof (UInt32);
            UInt32 audioModeCheck = 999;
            
            AudioSessionGetProperty (kAudioSessionProperty_Mode, &audioModeCheckSize, &audioModeCheck);
            
            if(audioModeCheck == audioModeClassification) {
                if(openears_logging==1)NSLog(@"audioMode is correct, we will leave it as it is.");
            } else {
                if(openears_logging==1)NSLog(@"audioMode is incorrect, we will change it.");
                UInt32 audioModeToSet = audioModeClassification;
                OSStatus audioModeStatus = AudioSessionSetProperty(kAudioSessionProperty_Mode, sizeof(audioModeToSet), &audioModeToSet);
                if (audioModeStatus != noErr) {
                    if(openears_logging==1)NSLog(@"Error %d: Unable to set audio mode.", (int)audioModeStatus);
                } else {
                    if(openears_logging==1)NSLog(@"audioMode is now on the correct setting.");
                }
            }
        }
    }
    
    
    UInt32 bluetoothInputCheckSize = sizeof (UInt32);
    UInt32 bluetoothInputCheck = 999;
    
    AudioSessionGetProperty (kAudioSessionProperty_OverrideCategoryEnableBluetoothInput, &bluetoothInputCheckSize, &bluetoothInputCheck);
    
    if(bluetoothInputCheck == 1) {
        if(openears_logging == 1) NSLog(@"bluetoothInput is correct, we will leave it as it is.");   
    } else {
        if(openears_logging == 1) NSLog(@"bluetoothInput is incorrect, we will change it."); 
        UInt32 bluetoothInput = 1;
        OSStatus bluetoothInputStatus = AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryEnableBluetoothInput,sizeof (bluetoothInput), &bluetoothInput);
        if (bluetoothInputStatus != noErr) {
            if(openears_logging == 1) NSLog(@"Error %d: Unable to set bluetooth input.", (int)bluetoothInputStatus);
        } else {
            if(openears_logging == 1) NSLog(@"bluetooth input is now on the correct setting of 1."); 
        }
    }
    
    


    if([self shouldOverrideAudioRoute]==TRUE) {
        
        UInt32 categoryDefaultToSpeakerCheckSize = sizeof (UInt32);
        UInt32 categoryDefaultToSpeakerCheck = 999;
        
        AudioSessionGetProperty (kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, &categoryDefaultToSpeakerCheckSize, &categoryDefaultToSpeakerCheck);
        
        if(categoryDefaultToSpeakerCheck == 1) {
            if(openears_logging == 1) NSLog(@"categoryDefaultToSpeaker is correct, we will leave it as it is.");   
        } else {
            if(openears_logging == 1) NSLog(@"categoryDefaultToSpeaker is incorrect, we will change it."); 
            
            UInt32 overrideCategoryDefaultToSpeaker = 1; // Re-route sound output to the main speaker.
            OSStatus overrideCategoryDefaultToSpeakerError = AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof (overrideCategoryDefaultToSpeaker), &overrideCategoryDefaultToSpeaker);
            if (overrideCategoryDefaultToSpeakerError != noErr) {
                if(openears_logging == 1) NSLog(@"Error %d: Unable to override the default speaker.", (int)overrideCategoryDefaultToSpeakerError);
            } else {
                if(openears_logging == 1) NSLog(@"CategoryDefaultToSpeaker is now on the correct setting of 1.");
            }
        }

    }
    
    if(self.soundMixing == TRUE) { // If the audioSessionManager soundmixing property is set to true, do the following. It defaults to false.
        UInt32 overrideCategoryMixWithOthersCheckSize = sizeof (UInt32);
        UInt32 overrideCategoryMixWithOthersCheck = 999;
        
        AudioSessionGetProperty (kAudioSessionProperty_OverrideCategoryMixWithOthers, &overrideCategoryMixWithOthersCheckSize, &overrideCategoryMixWithOthersCheck);
        
        if(overrideCategoryMixWithOthersCheck == 1) {
            if(openears_logging == 1) NSLog(@"OverrideCategoryMixWithOthers is correct, we will leave it as it is.");   
        } else {
            if(openears_logging == 1) NSLog(@"OverrideCategoryMixWithOthers is incorrect, we will change it."); 
            
            UInt32 overrideCategoryMixWithOthers = 1; // Allow background sounds to mix with the session
            OSStatus overrideCategoryMixWithOthersStatus = AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof (overrideCategoryMixWithOthers), &overrideCategoryMixWithOthers);
            if (overrideCategoryMixWithOthersStatus != noErr) {
                if(openears_logging == 1) NSLog(@"Error %d: Unable to set up OverrideCategoryMixWithOthers.", (int)overrideCategoryMixWithOthersStatus);
            } else {
                if(openears_logging == 1) NSLog(@"OverrideCategoryMixWithOthers is now on the correct setting of 1.");
            }
        }    
    }
    
    UInt32 preferredBufferSizeCheckSize = sizeof (Float32);
    Float32 preferredBufferSizeCheck = 99999.9;
    
    AudioSessionGetProperty (kAudioSessionProperty_PreferredHardwareIOBufferDuration, &preferredBufferSizeCheckSize, &preferredBufferSizeCheck);

    if (fabs(preferredBufferSizeCheck - kBufferLength) < 0.0001) {
        if(openears_logging == 1) NSLog(@"preferredBufferSize is correct, we will leave it as it is.");   
    } else {
        if(openears_logging == 1) NSLog(@"preferredBufferSize is incorrect, we will change it."); 
    
        Float32 preferredBufferSize = kBufferLength; // apparently for best results this should be divisible by 2 so once you've found the best rate, make it even. It was previously working reliably with 1/18
        
        OSStatus preferredBufferSizeStatus = AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize);
        if(preferredBufferSizeStatus != noErr) {
            if(openears_logging == 1) NSLog(@"Not able to set the preferred buffer size: %d", (int)preferredBufferSizeStatus);
        } else {
            if(openears_logging == 1) NSLog(@"PreferredBufferSize is now on the correct setting of %f.",kBufferLength);
        }
    }
    
    
 
    
    
    
    UInt32 preferredSampleRateCheckSize = sizeof (Float64);
    Float64 preferredSampleRateCheck = 99999.9;
    
    AudioSessionGetProperty (kAudioSessionProperty_PreferredHardwareSampleRate, &preferredSampleRateCheckSize, &preferredSampleRateCheck);
 
    if (fabs(preferredSampleRateCheck - kSamplesPerSecond) < 0.0001) {
        if(openears_logging == 1) NSLog(@"preferredSampleRateCheck is correct, we will leave it as it is.");   
    } else {
        if(openears_logging == 1) NSLog(@"preferredSampleRateCheck is incorrect, we will change it."); 
        
        Float64 preferredSampleRate = kSamplesPerSecond;
        OSStatus setPreferredHardwareSampleRate = AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareSampleRate, sizeof(preferredSampleRate), &preferredSampleRate);
        if(setPreferredHardwareSampleRate != noErr) {
            if(openears_logging == 1) NSLog(@"Couldn't set preferred hardware sample rate: %d", (int)setPreferredHardwareSampleRate);
        } else {
            if(openears_logging == 1) NSLog(@"preferred hardware sample rate is now on the correct setting of %f.",(Float64)kSamplesPerSecond);
        }
    }
    

    

}

-(BOOL)shouldOverrideAudioRoute { // Thank you to hartsteins for this method and this idea
    
    // Feel free to modify these results for your own app-specific needs
    
    BOOL shouldOverride = NO;
    CFStringRef device;
    UInt32 size = sizeof(device);
    
    OSStatus status = AudioSessionGetProperty (kAudioSessionProperty_AudioRoute,&size, &device);
    if (status != noErr) {
        if(openears_logging == 1){        
        NSLog(@"Error %d: Unable to get property.", (int)status);
        }
        return NO;
    }
    
    if(openears_logging == 1){
        NSLog(@"Output Device: %@.",(NSString*)device);
    }

    if([(NSString *)device isEqualToString:@"LineInOut"]) {
        shouldOverride = NO;
    } else if([(NSString *)device isEqualToString:@"HeadsetInOut"]) {
        shouldOverride = NO;
    } else if([(NSString *)device isEqualToString:@"HeadsetBT"]) {
        shouldOverride = NO;
    } else if([(NSString *)device isEqualToString:@"HeadphonesBT"]) {
        shouldOverride = NO;
    } else if([(NSString *)device isEqualToString:@"ReceiverAndMicrophone"]) {
        shouldOverride = YES;
    } else if([(NSString *)device isEqualToString:@"SpeakerAndMicrophone"]) {
        shouldOverride = YES;
    } else if([(NSString *)device isEqualToString:@"HeadphonesAndMicrophone"]) {
        shouldOverride = NO;
    } else if([(NSString *)device isEqualToString:@"AirTunes"]) {
        shouldOverride = NO;
    } else if([(NSString *)device isEqualToString:@"HDMIOutput"]) {
        shouldOverride = NO;
    } else if([(NSString *)device isEqualToString:@"Speaker"]) {
        shouldOverride = YES;
    } else if([(NSString *)device isEqualToString:@"Headphone"]) {
        shouldOverride = NO;
    }else if([(NSString *)device isEqualToString:@"Default"]) {
        shouldOverride = YES;
    }
    
    return shouldOverride;
}

// Here is where we're initiating the audio session.  This should only happen once in an app session.  If a second attempt is made to initiate an audio session using this class, it will hopefully

- (void) startAudioSession {

	OSStatus audioSessionInitializationError = AudioSessionInitialize(NULL, NULL, audioSessionInterruptionListener, NULL); // Try to initialize the audio session.
    
	if (audioSessionInitializationError !=0 && audioSessionInitializationError != kAudioSessionAlreadyInitialized) { // There was an error and it wasn't that the audio session is already initialized.
		if(openears_logging == 1) NSLog(@"Error %d: Unable to initialize the audio session.", (int)audioSessionInitializationError);
	} else { // If there was no error we'll set the properties of the audio session now.
		
        if (audioSessionInitializationError !=0 && audioSessionInitializationError == kAudioSessionAlreadyInitialized) {
            if(openears_logging == 1) NSLog(@"The audio session has already been initialized but we will override its properties.");
        } else {
            if(openears_logging == 1) NSLog(@"The audio session has never been initialized so we will do that now.");
        }
        
        [self setAllAudioSessionSettings];
		
        OSStatus setAudioSessionActiveError = AudioSessionSetActive(true);  // Finally, start the audio session.
        if (setAudioSessionActiveError != 0) {
            if(openears_logging == 1) NSLog(@"Error %d: Unable to set the audio session active.", (int)setAudioSessionActiveError);
        }
        
        //    UInt32 audioInputAvailable = 0;  // Find out if there is an available audio input. We are adding these listeners after the session has started because sometimes the category change doesn't complete before adding the listeners and the category change is heard as a route change.
        //    UInt32 size = sizeof(audioInputAvailable);
        //    OSStatus audioInputAvailableError = AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &size, &audioInputAvailable);
        //    if (audioInputAvailableError != 0) {
        //        if(openears_logging == 1) NSLog(@"Error %d: Unable to get the availability of the audio input.", (int)audioInputAvailableError);
        //    }
        //    if(audioInputAvailableError == 0 && audioInputAvailable == 0) {
        //        if(openears_logging == 1) NSLog(@"There is no audio input available.");
        //    }
        //    
        OSStatus addAvailabilityListenerError = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioInputAvailable, audioSessionPropertyListener, NULL); // Create listener for changes in the Audio Session properties.
        if (addAvailabilityListenerError != 0) {
            
            if(openears_logging == 1) NSLog(@"Error %d: Unable to add the listener for changes in input availability.", (int)addAvailabilityListenerError);
        }
        
        OSStatus audioRouteChangeListenerError = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, audioSessionPropertyListener, NULL); // Create listener for changes in the audio route.
        if (audioRouteChangeListenerError != 0) {
            if(openears_logging == 1) NSLog(@"Error %d: Unable to start audio route change listener.", (int)audioRouteChangeListenerError);
        }
        
		if(openears_logging == 1) NSLog(@"AudioSessionManager startAudioSession has reached the end of the initialization.");
	}
	
	if(openears_logging == 1) NSLog(@"Exiting startAudioSession.");
}


@end
