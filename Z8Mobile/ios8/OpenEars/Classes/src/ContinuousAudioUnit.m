//  OpenEars 
//  http://www.politepix.com/openears
//
//  ContinuousAudioUnit.mm
//  OpenEars
//
//  ContinuousAudioUnit is a class which handles the interaction between the Pocketsphinx continuous recognition loop and Core Audio.
//
//  Copyright Politepix UG (haftungsbeschränkt) 2012
//  http://www.politepix.com
//  Contact at http://www.politepix.com/contact
//
//  this file is licensed under the Politepix Shared Source license found 
//  found in the root of the source distribution. Please see the file "Version.txt" in the root of 
//  the source distribution for the version number of this OpenEars package.

#import "OpenEarsStaticAnalysisToggle.h"
#if defined TARGET_IPHONE_SIMULATOR && TARGET_IPHONE_SIMULATOR // This is the driver for the simulator only, since the low-latency audio unit driver doesn't work with the simulator at all.
#import "AudioQueueFallback.h"

#else

#import "ContinuousAudioUnit.h"

#import "RuntimeVerbosity.h"

extern int openears_logging;

static PocketsphinxAudioDevice *audioDriver;
int framesOfSilence = 0;

#define kOutputBus 1

#pragma mark -
#pragma mark Audio Unit Callback

static OSStatus	AudioUnitRenderCallback (void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    
	if (inNumberFrames > 0) {
        
		OSStatus renderStatus = AudioUnitRender(audioDriver->audioUnit, ioActionFlags, inTimeStamp, kOutputBus, inNumberFrames, ioData);
		
		if(renderStatus != noErr) {
			switch (renderStatus) {
				case kAudioUnitErr_InvalidProperty:
					if(openears_logging == 1) NSLog(@"Audio Unit render error: kAudioUnitErr_InvalidProperty");
					break;
				case kAudioUnitErr_InvalidParameter:
					if(openears_logging == 1) NSLog(@"Audio Unit render error: kAudioUnitErr_InvalidParameter");
					break;
				case kAudioUnitErr_InvalidElement:
					if(openears_logging == 1) NSLog(@"Audio Unit render error: kAudioUnitErr_InvalidElement");
					break;
				case kAudioUnitErr_NoConnection:
					if(openears_logging == 1) NSLog(@"Audio Unit render error: kAudioUnitErr_NoConnection");
					break;
				case kAudioUnitErr_FailedInitialization:
					if(openears_logging == 1) NSLog(@"Audio Unit render error: kAudioUnitErr_FailedInitialization");
					break;
				case kAudioUnitErr_TooManyFramesToProcess:
					if(openears_logging == 1) NSLog(@"Audio Unit render error: kAudioUnitErr_TooManyFramesToProcess");
					break;
				case kAudioUnitErr_InvalidFile:
					if(openears_logging == 1) NSLog(@"Audio Unit render error: kAudioUnitErr_InvalidFile");
					break;
				case kAudioUnitErr_FormatNotSupported:
					if(openears_logging == 1) NSLog(@"Audio Unit render error: kAudioUnitErr_FormatNotSupported");
					break;
				case kAudioUnitErr_Uninitialized:
					if(openears_logging == 1) NSLog(@"Audio Unit render error: kAudioUnitErr_Uninitialized");
					break;
				case kAudioUnitErr_InvalidScope:
					if(openears_logging == 1) NSLog(@"Audio Unit render error: kAudioUnitErr_InvalidScope");
					break;
				case kAudioUnitErr_PropertyNotWritable:
					if(openears_logging == 1) NSLog(@"Audio Unit render error: kAudioUnitErr_PropertyNotWritable");
					break;
				case kAudioUnitErr_CannotDoInCurrentContext:
					if(openears_logging == 1) NSLog(@"Audio Unit render error: kAudioUnitErr_CannotDoInCurrentContext");
					break;
				case kAudioUnitErr_InvalidPropertyValue:
					if(openears_logging == 1) NSLog(@"Audio Unit render error: kAudioUnitErr_InvalidPropertyValue");
					break;
				case kAudioUnitErr_PropertyNotInUse:
					if(openears_logging == 1) NSLog(@"Audio Unit render error: kAudioUnitErr_PropertyNotInUse");
					break;
				case kAudioUnitErr_InvalidOfflineRender:
					if(openears_logging == 1) NSLog(@"Audio Unit render error: kAudioUnitErr_InvalidOfflineRender");
					break;
				case kAudioUnitErr_Unauthorized:
					if(openears_logging == 1) NSLog(@"Audio Unit render error: kAudioUnitErr_Unauthorized");
					break;
				case -50:
					if(openears_logging == 1) NSLog(@"Audio Unit render error: error in user parameter list (-50)");
					break;														
				default:
					if(openears_logging == 1) NSLog(@"Audio Unit render error %d: unknown error", (int)renderStatus);
					break;
			}
			
			return renderStatus;
			
		} else { // if the render was successful,
			            
            if(audioDriver->takeBuffersFromTestFile == TRUE && inNumberFrames > 0) { // If we're running recognition directly on a test file

                if(audioDriver->recordData == 1) {
                    if (audioDriver->bytesInTestFile > (audioDriver->positionInTestFile + (inNumberFrames * 2))) { // If the file buffer still has some data in it
                        memcpy(ioData->mBuffers[0].mData, audioDriver->testFileBuffer + (audioDriver->positionInTestFile/2), inNumberFrames * 2); // Copy the data to this callback buffer inline
                        audioDriver->positionInTestFile = audioDriver->positionInTestFile + (inNumberFrames * 2); // And advance the position of positionInTestFile.
  
                    } else {
                        memset(ioData->mBuffers[0].mData, 0, ioData->mBuffers[0].mDataByteSize); // If we don't have enough remaining audio we write out silence.
                        audioDriver->positionInTestFile = audioDriver->bytesInTestFile;
                    }
                } else { // If recognition isn't in progress we just write zeroes.
                    
                    if (audioDriver->bytesInTestFile > (audioDriver->positionInTestFile + (inNumberFrames * 2))) { // If the file buffer still has some data in it
                        memset(ioData->mBuffers[0].mData, 0, ioData->mBuffers[0].mDataByteSize); // write zeroes to the buffer
                        audioDriver->positionInTestFile = audioDriver->positionInTestFile + (inNumberFrames * 2); // And advance the position of positionInTestFile.

                    } else {
                        memset(ioData->mBuffers[0].mData, 0, ioData->mBuffers[0].mDataByteSize); // If we don't have enough remaining audio we write out silence.
                        audioDriver->positionInTestFile = audioDriver->bytesInTestFile;

                    }
                    
                }
            }
            
			if (inNumberFrames > 0 && (audioDriver->recordData == 1 && audioDriver->recognitionIsInProgress == 1) && audioDriver->endingLoop == FALSE) {
				
				// let's only do the following when we aren't calibrating for now
				
				if(audioDriver->calibrating == FALSE) {
					
					
					SInt16 chunkToWriteTo;
					// Increment indexOfLastWrittenChunk unless it is equal to numberofchunks in which case loop around and set it to zero. 
					// Then use lastchunkwritten as the indicator of what chunk to do stuff to.
					
					if(audioDriver->indexOfLastWrittenChunk == kNumberOfChunksInRingbuffer-1) { // If we're on the last index, loop around to zero.
						chunkToWriteTo = 0;
					} else { // Otherwise increment indexOfLastWrittenChunk.
						chunkToWriteTo = audioDriver->indexOfLastWrittenChunk+1;
					}
					
					// First of all we'll need to add some extra samples if there are any waiting for us.
					if(audioDriver->extraSamples == TRUE) {
						audioDriver->extraSamples = FALSE;
						// add the extra samples from the buffer
						memcpy((SInt16 *)audioDriver->ringBuffer[chunkToWriteTo].buffer,(SInt16 *)audioDriver->extraSampleBuffer,audioDriver->numberOfExtraSamples*2); // Copy this unit's samples into the ringbuffer
						
						memcpy((SInt16 *)audioDriver->ringBuffer[chunkToWriteTo].buffer + audioDriver->numberOfExtraSamples,(SInt16 *)ioData->mBuffers[0].mData,inNumberFrames*2); // Copy this unit's samples into the ringbuffer
						
						audioDriver->ringBuffer[chunkToWriteTo].numberOfSamples = inNumberFrames + audioDriver->numberOfExtraSamples; // set this ringbuffer chunk's numberOfSamples to the unit's inNumberFrames.
						
						audioDriver->ringBuffer[chunkToWriteTo].writtenTimestamp = CFAbsoluteTimeGetCurrent(); // Timestamp when we wrote this so the read function can decide if it's read this chunk already or not.
						
					} else {
						memcpy(audioDriver->ringBuffer[chunkToWriteTo].buffer,(SInt16 *)ioData->mBuffers[0].mData,inNumberFrames*2); // Copy this unit's samples into the ringbuffer
						
						audioDriver->ringBuffer[chunkToWriteTo].numberOfSamples = inNumberFrames; // set this ringbuffer chunk's numberOfSamples to the unit's inNumberFrames.
						
						audioDriver->ringBuffer[chunkToWriteTo].writtenTimestamp = CFAbsoluteTimeGetCurrent(); // Timestamp when we wrote this so the read function can decide if it's read this chunk already or not.
                        
						
					}
					
					if(audioDriver->indexOfLastWrittenChunk == kNumberOfChunksInRingbuffer-1) { // If we're on the last index, loop around to zero.
						audioDriver->indexOfLastWrittenChunk = 0;
					} else { // Otherwise increment indexOfLastWrittenChunk.
						audioDriver->indexOfLastWrittenChunk++;
					}

					SInt16 *samples = (SInt16 *)ioData->mBuffers[0].mData;
					getDecibels(samples,inNumberFrames); // Get the decibels
					
					// That's it.
					
					
				} else { 
					
					if(audioDriver->roundsOfCalibration == 0 || audioDriver->roundsOfCalibration == 1) {
						// Ignore the first couple of buffers, they are sometimes full of null input.
						audioDriver->roundsOfCalibration++;
					} else {
						
						SInt16 *calibrationSamples = (SInt16 *)(ioData->mBuffers[0].mData);
						
						int i;
						for ( i = 0; i < inNumberFrames; i++ ) {  //So when we get here, we loop through the frames and write the samples there to the calibration buffer starting at the last end index we stopped at
							audioDriver->calibrationBuffer[i + audioDriver->availableSamplesDuringCalibration] = calibrationSamples[i];
						}
						audioDriver->availableSamplesDuringCalibration = audioDriver->availableSamplesDuringCalibration + inNumberFrames;
					}
				}
			}
			
			memset(ioData->mBuffers[0].mData, 0, ioData->mBuffers[0].mDataByteSize); // write out silence to the buffer for no-playback times
            if(audioDriver->recordData == 0) framesOfSilence += inNumberFrames; // Keep track of silence samples.
		}
		
	}
	
	return 0;
}

void getDecibels(SInt16 * samples, UInt32 inNumberFrames) {
	
	Float32 decibels = kDBOffset; // When we have no signal we'll leave this on the lowest setting
	Float32 currentFilteredValueOfSampleAmplitude; 
	Float32 previousFilteredValueOfSampleAmplitude = 0.0; // We'll need these in the low-pass filter
	Float32 peakValue = kDBOffset; // We'll end up storing the peak value here
	
	for (int i=0; i < inNumberFrames; i=i+10) { // We're incrementing this by 10 because there's actually too much info here for us for a conventional UI timeslice and it's a cheap way to save CPU
		
		Float32 absoluteValueOfSampleAmplitude = abs(samples[i]); //Step 2: for each sample, get its amplitude's absolute value.
		
		// Step 3: for each sample's absolute value, run it through a simple low-pass filter
		// Begin low-pass filter
		currentFilteredValueOfSampleAmplitude = kLowPassFilterTimeSlice * absoluteValueOfSampleAmplitude + (1.0 - kLowPassFilterTimeSlice) * previousFilteredValueOfSampleAmplitude;
		previousFilteredValueOfSampleAmplitude = currentFilteredValueOfSampleAmplitude;
		Float32 amplitudeToConvertToDB = currentFilteredValueOfSampleAmplitude;
		// End low-pass filter
		
		Float32 sampleDB = 20.0*log10(amplitudeToConvertToDB) + kDBOffset;
		// Step 4: for each sample's filtered absolute value, convert it into decibels
		// Step 5: for each sample's filtered absolute value in decibels, add an offset value that normalizes the clipping point of the device to zero.
		
		if((sampleDB == sampleDB) && (sampleDB <= DBL_MAX && sampleDB >= -DBL_MAX)) { // if it's a rational number and isn't infinite
			
			if(sampleDB > peakValue) peakValue = sampleDB; // Step 6: keep the highest value you find.
			decibels = peakValue; // final value
		}
	}
	audioDriver->pocketsphinxDecibelLevel = decibels;
}

void setRoute(void) {
	CFStringRef audioRoute;
	UInt32 audioRouteSize = sizeof(CFStringRef);
	OSStatus getAudioRouteStatus = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &audioRouteSize, &audioRoute); // Get the audio route.
	if (getAudioRouteStatus != 0) {
		if(openears_logging == 1) NSLog(@"Error %d: Unable to get the audio route.", (int)getAudioRouteStatus);
	} else {
		if(openears_logging == 1) NSLog(@"Set audio route to %@", (NSString *)audioRoute);	
	}
	
	audioDriver->currentRoute = audioRoute; // Set currentRoute to the audio route.
    //CFRelease(audioRoute); // When I release these things get weird, and when I don't release them they cause tiny one-off leaks. Until there's time for a lot more attention, tiny one-off leak is preferable to weirdness.
}

CFStringRef getRoute(void) {
    CFStringRef audioRoute;
	UInt32 audioRouteSize = sizeof(CFStringRef);
	OSStatus getAudioRouteStatus = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &audioRouteSize, &audioRoute); // Get the audio route.
	if (getAudioRouteStatus != 0) {
		if(openears_logging == 1) NSLog(@"Error %d: Unable to get the audio route.", (int)getAudioRouteStatus);
        return (CFStringRef)@"NoAudioDeviceRoute";
	} else {
        return audioRoute;
	}
}

static char *FormatOSStatusError(char *stringToReturn, OSStatus statuserror);

static char *FormatOSStatusError(char *stringToReturn, OSStatus statuserror)
{
    // see if it appears to be a 4-char-code
    *(UInt32 *)(stringToReturn + 1) = CFSwapInt32HostToBig(statuserror);

#ifdef STATICANALYZEDEPENDENCIES
#define __clang_analyzer__ 1
#endif
#if !defined(__clang_analyzer__) || defined(STATICANALYZEDEPENDENCIES)
#undef __clang_analyzer__
    if (isprint(stringToReturn[1]) && isprint(stringToReturn[2]) && isprint(stringToReturn[3]) && isprint(stringToReturn[4])) { 
#endif        
        stringToReturn[0] = stringToReturn[5] = '\'';
        stringToReturn[6] = '\0';
    } else {
        sprintf(stringToReturn, "%d", (int)statuserror);
        NSError *localerror = [NSError errorWithDomain:NSOSStatusErrorDomain code:statuserror userInfo:nil];
        NSLog(@"Error: %@", localerror);
    }
    return stringToReturn;
}
OSStatus testFileLoad(const char * testFileName);
OSStatus testFileLoad(const char * testFileName) {

    audioDriver->pathToTestFile = testFileName;

    NSString *audioFilePathToRead = [NSString stringWithFormat:@"%s",audioDriver->pathToTestFile]; 
    NSURL *audioURLToRead = [NSURL fileURLWithPath:audioFilePathToRead];  
             

    AudioFileID audioFileToReadID;  
  
    OSStatus statusError = noErr;

    UInt64 numberOfBytes;
    UInt32 propertySize = sizeof(numberOfBytes);

    char *errorString = (char *) malloc(100);

    statusError = AudioFileOpenURL((CFURLRef)audioURLToRead, kAudioFileReadPermission, 0, &audioFileToReadID); 

    if(statusError) {
        
        NSLog(@"AudioFileOpenURL Error: %s", FormatOSStatusError(errorString,statusError)); 
        free(errorString);
        return statusError;
    }

    statusError = AudioFileGetProperty(audioFileToReadID, kAudioFilePropertyAudioDataByteCount, &propertySize, &numberOfBytes);

    if(statusError) {
        NSLog(@"AudioFileGetProperty Error: %s", FormatOSStatusError(errorString,statusError)); 
        free(errorString);
        return statusError;
    }

    audioDriver->bytesInTestFile = (UInt32)numberOfBytes; 
    audioDriver->testFileBuffer = (SInt16 *)malloc(audioDriver->bytesInTestFile);


    statusError = AudioFileReadBytes(audioFileToReadID, false, 0, &audioDriver->bytesInTestFile, audioDriver->testFileBuffer);

    if(statusError) {
        NSLog(@"AudioFileReadBytes Error: %s", FormatOSStatusError(errorString,statusError)); 
        free(errorString);
        return statusError;
    }

    AudioFileClose(audioFileToReadID);
    
    free(errorString);
    return NULL;
}

#pragma mark -
#pragma mark Pocketsphinx driver functionality

PocketsphinxAudioDevice *openAudioDevice(const char *dev, int32 samples_per_sec, BOOL takingBuffersFromTestFile, const char *testfileName) {
    
    char *errorString = (char *) malloc(300);
    
	if(openears_logging == 1) NSLog(@"Starting openAudioDevice on the device.");
					
	if(audioDriver != NULL) { // Audio unit wrapper has already been created
		closeAudioDevice(audioDriver);
	}
	
	if ((audioDriver = (PocketsphinxAudioDevice *) calloc(1, sizeof(PocketsphinxAudioDevice))) == NULL) {
		if(openears_logging == 1) NSLog(@"There was an error while creating the device, returning null device.");
		return NULL;
	} else {
		if(openears_logging == 1) NSLog(@"Audio unit wrapper successfully created.");
	}
	
	audioDriver->audioUnitIsRunning = 0;
	audioDriver->recording = 0;
	audioDriver->samplesPerSecond = kSamplesPerSecond;
	audioDriver->bytesPerSample = 2;
	audioDriver->pocketsphinxDecibelLevel = 0.0;
    
    audioDriver->takeBuffersFromTestFile = takingBuffersFromTestFile;
    
    if(audioDriver->takeBuffersFromTestFile == TRUE) {
     
        OSStatus result = testFileLoad(testfileName);
        if(result != noErr) {
            NSLog(@"AudioFileWriteBytes Error: %s", FormatOSStatusError(errorString,result)); 
        }
    }

    audioDriver->positionInTestFile = 0;
    
	AURenderCallbackStruct audioUnitRenderCallbackStruct;
	audioUnitRenderCallbackStruct.inputProc = AudioUnitRenderCallback; // Proc. Maybe it's programmed random occurrence. Maybe it's process. Maybe it's procedure. Maybe it's maybe. Since everyone worthwhile already knows what a proc is, this struct member quite correctly isn't documented in the struct. But it is a pointer to the AURenderCallback, which is the callback function. SO OBVIOUS GUYS.
	audioUnitRenderCallbackStruct.inputProcRefCon = audioDriver; // Every proc needs a reference context. Have you ever considered that since we don't know exactly what proc is short for, the number of letters saved in this triply-abbreviated, undocumented structure member name might be infinite?
	
	AudioComponentDescription audioUnitDescription;
	
	audioUnitDescription.componentType = kAudioUnitType_Output; // Output is the only unit type we are allowed on this platform. Which is confusing because I only want input in here.
	audioUnitDescription.componentSubType = kAudioUnitSubType_RemoteIO; // RemoteIO is the Output Unit Type in question. It's either this or VoiceProcessingIO which isn't an option for OpenEars because I hate fun.
	audioUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple; // Surprise, it is from Apple.
	audioUnitDescription.componentFlags = 0; // must be set to zero unless a known specific value is requested. i.e. it is a secret flag.
	audioUnitDescription.componentFlagsMask = 0; // Even more secret because it is a secret flag wearing a mask. If you don't know the secret you have to just set this to zero like componentFlags; too bad, so sad.
	
	AudioComponent audioComponent = AudioComponentFindNext(NULL, &audioUnitDescription); // Finding the next component in the audio unit. Or probably also the first component in the audio unit, I guess. NULL means do a complete search.
	
	OSStatus newAudioUnitComponentInstanceStatus = AudioComponentInstanceNew(audioComponent, &audioDriver->audioUnit);
	if(newAudioUnitComponentInstanceStatus != noErr) {
		if(openears_logging == 1) NSLog(@"Error: Couldn't get new audio unit component instance: %s",FormatOSStatusError(errorString,newAudioUnitComponentInstanceStatus));
		audioDriver->unitIsRunning = 0;
		return NULL;
	}

    int globalBus = 0; // All the sample code and documentation for kAudioUnitProperty_MaximumFramesPerSlice uses the AudioUnitElement 0 for the global bus, and none of it explains why it is element zero, and I have no idea why, so I certainly won't.
    
	UInt32 maximumFrames = 4096;
	OSStatus maxFramesStatus = AudioUnitSetProperty(audioDriver->audioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, globalBus, &maximumFrames, sizeof(maximumFrames));
	if(maxFramesStatus != noErr) {
		if(openears_logging == 1) NSLog(@"Error: unable to set maximum frames property: %s. Recognition will continue but this error should be reported to http://www.politepix.com/forums along with the device and iOS version for further testing, thank you.", FormatOSStatusError(errorString,maxFramesStatus));
        // This is not a dealbreaker error because recognition will probably work anyway so we won't exit.
	}
	
	UInt32 enableIOForInputFlag = 1;
	UInt32 inputBusForEnablingIO = 1;
	
	OSStatus setEnableIOStatus = AudioUnitSetProperty(audioDriver->audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, inputBusForEnablingIO, &enableIOForInputFlag, sizeof(enableIOForInputFlag)); // The input bus of the RemoteIO audio unit has to be actively enabled because it is an output unit.
	if(setEnableIOStatus != noErr) {
		if(openears_logging == 1) NSLog(@"Error: Couldn't enable IO for input: %s",FormatOSStatusError(errorString,setEnableIOStatus));
		audioDriver->unitIsRunning = 0;
		return NULL;
	}

    /* // Commented out because this never ever but never works.
     
    UInt32 disableIOForOutputFlag = 0;
	UInt32 outputBus = 0;
	
	OSStatus setDisableIOStatus = AudioUnitSetProperty(audioDriver->audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, outputBus, &disableIOForOutputFlag, sizeof(disableIOForOutputFlag)); // The output bus of the RemoteIO audio unit has to be actively disabled because it is an output unit.
	if(setDisableIOStatus != noErr) {
		if(openears_logging == 1) NSLog(@"Error: Couldn't disable IO for output: %s",FormatOSStatusError(errorString,setDisableIOStatus));
		audioDriver->unitIsRunning = 0;
		return NULL;
	}
    
     */
    
    int inputBus = 0; // I have no idea why this is bus 0. In the call to enable io above, the input bus is 1. Is it not really this input bus in that case? Is it not really the input bus in this case? Are they referring to completely different things? Have I made a mistake that nonetheless allows things to work? How would I ever know? AudioUnitElement isn't the most descriptive name, but it's longer than its documentation.
    
	OSStatus setRenderCallbackStatus = AudioUnitSetProperty(audioDriver->audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, inputBus, &audioUnitRenderCallbackStruct, sizeof(audioUnitRenderCallbackStruct)); // Set the callback.
	if(setRenderCallbackStatus != noErr) {
		if(openears_logging == 1) NSLog(@"Error: Couldn't set render callback: %s",FormatOSStatusError(errorString,setRenderCallbackStatus));
		audioDriver->unitIsRunning = 0;
		return NULL;
	}
	
	audioDriver->audioUnitRecordFormat.mChannelsPerFrame = 1; // Mono
	audioDriver->audioUnitRecordFormat.mSampleRate = kSamplesPerSecond;  // 16000
	audioDriver->audioUnitRecordFormat.mFormatID = kAudioFormatLinearPCM; // Raw
	audioDriver->audioUnitRecordFormat.mBytesPerPacket = audioDriver->audioUnitRecordFormat.mChannelsPerFrame * audioDriver->bytesPerSample; // 2 bytes in a SInt16 sample
	audioDriver->audioUnitRecordFormat.mFramesPerPacket = 1; // 1 frame, 1 packet
	audioDriver->audioUnitRecordFormat.mBytesPerFrame = audioDriver->audioUnitRecordFormat.mBytesPerPacket; // therefore also 2 bytes
	audioDriver->audioUnitRecordFormat.mBitsPerChannel = 16;  // 16 bits
	audioDriver->audioUnitRecordFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked; // I know why this is a signed integer, because I want signed samples. kLinearPCMFormatFlagIsPacked = "Set if the sample bits occupy the entire available bits for the channel, clear if they are high- or low-aligned within the channel." That sounds right to me.
	
    // We are again using bus zero for an input scope.
    
	OSStatus setInputFormatStatus = AudioUnitSetProperty(audioDriver->audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, inputBus, &audioDriver->audioUnitRecordFormat, sizeof(audioDriver->audioUnitRecordFormat));
	if(setInputFormatStatus != noErr) {
		if(openears_logging == 1) NSLog(@"Error: Couldn't set stream input format: %s",FormatOSStatusError(errorString,setInputFormatStatus));
		audioDriver->unitIsRunning = 0;
		return NULL;
	}
	
    // Here we're using kOutputBus which is 1, except that in our commented-out call to disable output above we are advised to use 0.
    
	OSStatus setOutputFormatStatus = AudioUnitSetProperty(audioDriver->audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, kOutputBus, &audioDriver->audioUnitRecordFormat, sizeof(audioDriver->audioUnitRecordFormat));
	if(setOutputFormatStatus != noErr) {
		if(openears_logging == 1) NSLog(@"Error: Couldn't set stream output format: %s",FormatOSStatusError(errorString,setOutputFormatStatus));
		audioDriver->unitIsRunning = 0;
		return NULL;
	}
	
	OSStatus audioUnitInitializeStatus = AudioUnitInitialize(audioDriver->audioUnit);
	if(audioUnitInitializeStatus != noErr) {
		
		if(openears_logging == 1) NSLog(@"Error: Couldn't initialize audio unit: %s", FormatOSStatusError(errorString,audioUnitInitializeStatus));
		audioDriver->unitIsRunning = 0;
		return NULL;
	}
	
	audioDriver->unitIsRunning = 1;			
	audioDriver->deviceIsOpen = 1;
	
	setRoute();

    free(errorString);
    
    return audioDriver;
}

void clear_buffers (void) {

    if(audioDriver == NULL) return; // It can happen that a delayed suspend can call out when there is no driver. In that case we obviously don't clear the buffers.
/*
    int i;
	for ( i = 0; i < kNumberOfChunksInRingbuffer; i++ ) { // zero out all chunks in the ringbuffer (needed when suspending)
        memset(audioDriver->ringBuffer[i].buffer, 0, kChunkSizeInBytes);
	}*/
}

int32 startRecording(PocketsphinxAudioDevice * audioDevice) {
	
	if (audioDriver->recording == 1) {
		if(openears_logging == 1) NSLog(@"This driver is already recording, returning.");
        return -1;
	}
	
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SetAllAudioSessionSettings" object:nil]; // We'll first check that all the audio session settings are correct for recognition and fix them if not.
    
	if(openears_logging == 1) NSLog(@"Setting the variables for the device and starting it.");
	
	audioDriver->roundsOfCalibration = 0;
	audioDriver->endingLoop = FALSE;
	
	audioDriver->extraSamples = FALSE;
	audioDriver->numberOfExtraSamples = 0;
	
	if(audioDriver->extraSampleBuffer == NULL) {
		audioDriver->extraSampleBuffer = (SInt16 *)malloc(kExtraSampleBufferSize);		
	} else {
		audioDriver->extraSampleBuffer = (SInt16 *)realloc(audioDriver->extraSampleBuffer, kExtraSampleBufferSize); // ~16000 is the probable number coming in, x4 for safety and device independence.		
	}

	if(openears_logging == 1) NSLog(@"Looping through ringbuffer sections and pre-allocating them.");

	int i;
	for ( i = 0; i < kNumberOfChunksInRingbuffer; i++ ) { // malloc each individual buffer in the ringbuffer in advance to an overall size with some wiggle room.
		
		if(audioDriver->ringBuffer[i].buffer == NULL) {
			audioDriver->ringBuffer[i].buffer = (SInt16 *)malloc(kChunkSizeInBytes);
		} else {
			audioDriver->ringBuffer[i].buffer = (SInt16 *)realloc(audioDriver->ringBuffer[i].buffer, kChunkSizeInBytes);
		}

		audioDriver->ringBuffer[i].numberOfSamples = 0;
		audioDriver->ringBuffer[i].writtenTimestamp = CFAbsoluteTimeGetCurrent();
	}
	
	int j;
	for ( j = 0; j < kNumberOfChunksInRingbuffer; j++ ) { // set the consumed time stamps to now.
		audioDriver->consumedTimeStamp[j] = CFAbsoluteTimeGetCurrent();
	}
	
	audioDriver->indexOfLastWrittenChunk = kNumberOfChunksInRingbuffer-1;
	audioDriver->indexOfChunkToRead = 0;
	
	audioDriver->calibrating = FALSE;

	int32 startAudioUnitResults = startAudioUnitWithRetries(3,audioDriver->audioUnit);
    
    if(startAudioUnitResults == 0) { // That was successful.
        audioDriver->audioUnitIsRunning = 1; // Set audioUnitIsRunning to true.
        audioDriver->recording = 1;
    }
    
    return startAudioUnitResults; // zero if successful, -1 if not.        

}

int32 startAudioUnitWithRetries(int32 retries, AudioUnit audioUnit) {
    
    int32 results = -1;
    
    for (int i=0; i<retries; i++) {
        OSStatus startAudioUnitOutputStatus = AudioOutputUnitStart(audioUnit);
        if(startAudioUnitOutputStatus != noErr) { // Airplay seems to benefit from the ability to try again.
            if(openears_logging == 1) NSLog(@"Couldn't start audio unit output: %d, try %d...", (int)startAudioUnitOutputStatus,i+1);	
            UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
            AudioSessionSetProperty (kAudioSessionProperty_AudioCategory, sizeof (sessionCategory), &sessionCategory);
            AudioSessionSetActive(NO);
            AudioSessionSetActive(YES);
            
            startAudioUnitOutputStatus = AudioOutputUnitStart(audioUnit);
            
            if(startAudioUnitOutputStatus != noErr) {
                results = -1;
            } else {
                results = 0;
                break;                
            }

        } else {
            if(openears_logging == 1) NSLog(@"Started audio output unit.");
            results = 0;
            break;
        }
    }
    if(results == -1) NSLog(@"Starting audio unit was not possible, no more tries.");
    return results;
}

int32 stopRecording(PocketsphinxAudioDevice * audioDevice) {
	
	if (audioDriver->recording == 0) {
		if(openears_logging == 1) NSLog(@"Can't stop audio device because it isn't currently recording, returning instead.");	
		return -1; // bail if this ad doesn't think it's recording
	}
	
	if(audioDriver->audioUnitIsRunning == 1) { // only stop recording if there is actually a unit
		if(openears_logging == 1) NSLog(@"Stopping audio unit.");	

		OSStatus stopAudioUnitStatus = AudioOutputUnitStop(audioDriver->audioUnit);
		if(stopAudioUnitStatus != noErr) {
			if(openears_logging == 1) NSLog(@"Couldn't stop audio unit: %d", (int)stopAudioUnitStatus);
			return -1;
		} else {
			if(openears_logging == 1) NSLog(@"Audio Output Unit stopped, cleaning up variable states.");	
		}
		
	} else {
		if(openears_logging == 1) NSLog(@"Cleaning up driver variable states.");	
	}

	audioDriver->extraSamples = FALSE;
	audioDriver->numberOfExtraSamples = 0;
	audioDriver->endingLoop = FALSE;
	audioDriver->calibrating = FALSE;
	audioDriver->recording = 0;
	
    return 0;
}

Float32 pocketsphinxAudioDeviceMeteringLevel(PocketsphinxAudioDevice * audioDriver) { // Function which returns the metering level of the AudioUnit input.

	if(audioDriver != NULL && audioDriver->pocketsphinxDecibelLevel && audioDriver->pocketsphinxDecibelLevel > -161 && audioDriver->pocketsphinxDecibelLevel < 1) {
		return audioDriver->pocketsphinxDecibelLevel;
	}
	return 0.0;	
}

int32 closeAudioDevice(PocketsphinxAudioDevice * audioDevice) {
	
	if (audioDriver->recording == 1) {
		if(openears_logging == 1) NSLog(@"This device is recording, so we will first stop it");
		stopRecording(audioDriver);
		audioDriver->recording = 0;

	} else {
		if(openears_logging == 1) NSLog(@"This device is not recording, so first we will set its recording status to 0");
		audioDriver->recording = 0;
	}

	if(audioDriver->audioUnitIsRunning == 1) {
		if(openears_logging == 1) NSLog(@"The audio unit is running so we are going to dispose of its instance");		
		OSStatus instanceDisposeStatus = AudioComponentInstanceDispose(audioDriver->audioUnit);
		
		if(instanceDisposeStatus != noErr) {
			if(openears_logging == 1) NSLog(@"Couldn't dispose of audio unit instance: %d", (int)instanceDisposeStatus);
			return -1;
		}

		audioDriver->audioUnit = nil;
	}
	
	if(audioDriver->extraSampleBuffer != NULL) {
		free(audioDriver->extraSampleBuffer); // Let's free the extra sample buffer now.
		audioDriver->extraSampleBuffer = NULL;
	}
		
	int i;
	for ( i = 0; i < kNumberOfChunksInRingbuffer; i++ ) { // free each individual chunk in the ringbuffer
		if(audioDriver->ringBuffer[i].buffer != NULL) {
			free(audioDriver->ringBuffer[i].buffer);
			audioDriver->ringBuffer[i].buffer = NULL;
		}
	}
	
	if(audioDriver != NULL) {
		audioDriver->deviceIsOpen = 0;	
		free(audioDriver); 	// Finally, free the Sphinx audio device.
		audioDriver = NULL;
	}
	
    return 0;
}

int32 readBufferContents(PocketsphinxAudioDevice * audioDevice, int16 * buffer, int32 maximum) { // Scan the buffer for speech.
	
	// Only read if we're recording.
	
	if(audioDevice->recording == 0 || audioDevice->recognitionIsInProgress == 0) {
		return -1;
	}
	
	// let's only do the following when we aren't calibrating
	
	if(audioDriver->calibrating == FALSE) {
		
		// So, we have a ringbuffer that may or may not have fresh data for us to read.
		// We want to start out with the first read at chunk zero and sample zero, so this has to be set in StartRecording().
		// We will know if there is nothing there yet to read if chunk index zero has a read datestamp that is fresher than its written datestamp. If that happens it should return zero samples.
		// If that doesn't happen it should read the contents of the chunk for the full reported number of its samples (or max, whichever is smaller) and return the number of samples or max, datestamp the chunk 
		// and then increment the current chunk index.  SIMPLES!
		
		// For the current chunk, compare its timestamp to the timestamp of that chunk index in the ringbuffer and see which is fresher:
		
		if(audioDriver->ringBuffer[audioDriver->indexOfChunkToRead].writtenTimestamp>=audioDriver->consumedTimeStamp[audioDriver->indexOfChunkToRead]) { // If this chunk was written to more recently than it was read, it can be read.
			
			// What we're gonna do:
			// Read the whole chunk, return its number of samples, timestamp the index for this chunk.	
			// Put the total number of samples or max, whichever is smaller, in the pointer to the buffer which is an argument of this function.
			// Return the number of samples we put in there or maximum
			// Put the read timestamp in the index of chunk read timestamps.
			// increment indexOfChunkToRead or if it is on the last index, loop it around to zero.
			
			
			
			// OK, if max is bigger than the number of samples in the chunk, set max to the number of samples in the chunk:
			
			if(maximum >= audioDriver->ringBuffer[audioDriver->indexOfChunkToRead].numberOfSamples) {
				maximum = audioDriver->ringBuffer[audioDriver->indexOfChunkToRead].numberOfSamples;
			} else {
				// Put the rest into the extras buffer
				
				SInt16 numberOfUncopiedSamples = audioDriver->ringBuffer[audioDriver->indexOfChunkToRead].numberOfSamples - maximum;
				UInt32 startingSampleIndexForExtraSamples = maximum;
				audioDriver->extraSamples = TRUE;
				audioDriver->numberOfExtraSamples = numberOfUncopiedSamples;				
				memcpy((SInt16 *)audioDriver->extraSampleBuffer, (SInt16 *)audioDriver->ringBuffer[audioDriver->indexOfChunkToRead].buffer + startingSampleIndexForExtraSamples, audioDriver->numberOfExtraSamples * 2);
			}
			
			memcpy(buffer,audioDriver->ringBuffer[audioDriver->indexOfChunkToRead].buffer, maximum * 2); // memcpy copies bytes, so this needs to be max times 2 which is how many bytes are in one of our samples
			
			audioDriver->consumedTimeStamp[audioDriver->indexOfChunkToRead] = CFAbsoluteTimeGetCurrent(); // Timestamp to the current time.
			
			if(audioDriver->indexOfChunkToRead == kNumberOfChunksInRingbuffer - 1) { // If this is the last chunk index, loop around to zero.
				audioDriver->indexOfChunkToRead = 0;
			} else { // Otherwise increment the index of the chunk to read.
				audioDriver->indexOfChunkToRead++;
			}
			
	
			return maximum; // Return max and that's actually it.
			
		} else { // if it was read more recently than it was written to, return 0.
			
			return 0;
		}
		
	} else {
		
		int j;	// next, read the samples starting from the point of already read and going to 256 more, then return 256
		for ( j = 0; j < 256; j++ ) { // until 256 packets have been copied,
			buffer[j] = audioDriver->calibrationBuffer[j + audioDriver->samplesReadDuringCalibration];
            
		}
		
		audioDriver->samplesReadDuringCalibration = audioDriver->samplesReadDuringCalibration + 256; // next, increase samplesReadDuringCalibration by the amount read
		
		maximum = 256; // set max to 256
		
	
		return maximum;
		
	}
	
	return 0;
}

#endif
