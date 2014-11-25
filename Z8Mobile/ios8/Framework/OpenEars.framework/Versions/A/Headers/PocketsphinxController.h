//  OpenEars 
//  http://www.politepix.com/openears
//
//  PocketsphinxController.h
//  OpenEars
//
//  PocketsphinxController is a class which controls the creation and management of
//  a continuous speech recognition loop.
//
//  Copyright Politepix UG (haftungsbeschränkt) 2012. All rights reserved.
//  http://www.politepix.com
//  Contact at http://www.politepix.com/contact
//
//  this file is licensed under the Politepix Shared Source license found 
//  found in the root of the source distribution. Please see the file "Version.txt" in the root of 
//  the source distribution for the version number of this OpenEars package.


#import <Foundation/Foundation.h>
#import "OpenEarsEventsObserver.h"
/**\cond HIDDEN_SYMBOLS*/   
#import "ContinuousModel.h"
#import "AudioConstants.h"
#import "OpenEarsNotification.h"
#import <UIKit/UIDevice.h>

#define SYSTEM_VERSION_LESS_THAN(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

/**\endcond */   

/**
 @class  PocketsphinxController
 @brief  The class that controls local speech recognition in OpenEars.
 
 ## Usage examples
 > Preparing to use the class:
 @htmlinclude PocketsphinxController_Preconditions.txt
 > What to add to your header:
 @htmlinclude PocketsphinxController_Header.txt
 > What to add to your implementation:
 @htmlinclude PocketsphinxController_Implementation.txt
 > How to use the class methods:
 @htmlinclude PocketsphinxController_Calls.txt 
 @warning There can only be one PocketsphinxController instance in your app.
 */

@interface PocketsphinxController : NSObject <OpenEarsEventsObserverDelegate,ContinuousModelDelegate> {
/**\cond HIDDEN_SYMBOLS*/ 
	NSThread *voiceRecognitionThread; // The loop would lock if run on the main thread so it has a background thread in which it always runs.
	ContinuousModel *continuousModel; // The continuous model is the actual recognition loop.
	OpenEarsEventsObserver *openEarsEventsObserver; // We use an OpenEarsEventsObserver here to get important information from other objects which may be instantiated.
    /**\endcond */ 
    /**This is how long PocketsphinxController should wait after speech ends to attempt to recognize speech. This defaults to .7 seconds.*/
    float secondsOfSilenceToDetect;
    /**Advanced: set this to TRUE to receive n-best results.*/    
    BOOL returnNbest;
    /**Advanced: the number of n-best results to return. This is a maximum number to return -- if there are null hypotheses fewer than this number will be returned.*/
    int nBestNumber;
    /**How long to calibrate for. This can only be one of the values '1', '2', or '3'. Defaults to 1.*/
    int calibrationTime;
    /**Turn on verbose output. Do this any time you encounter an issue and any time you need to report an issue on the forums.*/
    BOOL verbosePocketSphinx;
    /**By default, PocketsphinxController won't return a hypothesis if for some reason the hypothesis is null (this can happen if the perceived sound was just noise). If you need even empty hypotheses to be returned, you can set this to TRUE before starting PocketsphinxController.*/
    BOOL returnNullHypotheses;
    /**Set this to true in order to allow audio session mixing*/
    BOOL audioSessionMixing;
    /**Check if the listening loop is suspended*/
    BOOL isSuspended; 
    /**Check if the listening loop is in progress*/
    BOOL isListening;     
    /**
     If you are using 5.0 or greater, you can set audio modes for the audio session manager to use.
     This can be set to the following:
     
     @"Default" to use kAudioSessionMode_Default = ‘dflt’,
     @"VoiceChat" to use kAudioSessionMode_VoiceChat = ‘vcct’,
     @"VideoRecording" kAudioSessionMode_VideoRecording = ‘vrcd’,
     @"Measurement" kAudioSessionMode_Measurement = ‘msmt’
     
     If you don't set it to anything, default will automatically be used.
     
     */
    NSString *audioMode; 
    /**By setting pathToTestFile to point to a recorded audio file you can run the main Pocketsphinx listening loop (not runRecognitionOnWavFileAtPath but the main loop invoked by using startListeningWithLanguageModelAtPath:) over a pre-recorded audio file instead of using it with live input. In contrast with using the method runRecognitionOnWavFileAtPath to receive a single recognition from a file, with this approach the audio file will have its buffers injected directly into the audio driver circular buffer for maximum fidelity to the goal of testing the entire codebase that is in use when doing a live recognition, including the whole driver, the calibration code, and the listening loop including all of its features. This is for creating tests for yourself and for sharing automatically replicable issue reports with Politepix. To use this, make an audio recording on the same device (i.e., if you are testing PocketsphinxController on an iPhone 5 with the internal microphone, make a recording on an iPhone 5 with the internal microphone, for instance using Apple's Voice Memos app) and then convert the resulting file to a 16-bit, 16000 sample rate, mono WAV file. You can do this with the output of Apple's Voice Memos app by taking the .m4a file that Voice Memos outputs and run it through this command in Terminal.app: "afconvert -f WAVE -d LEI16@16000 -c 1 ~/Desktop/Memo.m4a ~/Desktop/Memo.wav" Then add the WAV file to your app, and right before sending the call to startListeningWithLanguageModelAtPath, set this property pathToTestFile to the path to your audio file in your app as an NSString (e.g. [[NSBundle mainBundle] pathForResource:@"Memo" ofType:@"wav"]). Note: when you record the audio file you will be using to test with, <b>always</b> make sure to have 5 seconds of silence at the beginning so there is enough time for calibration to be performed on your recording environment, since calibration is also part of the test. SmartCMN is disabled during testing so that the test gets the same results when run for different people. Please keep in mind that there are some settings in Pocketsphinx which may prevent a deterministic outcome from a recognition, meaning that you should expect a <b>similar</b> score over multiple runs of a test but you may not always see the <b>identical</b> score. For this reason and the fact that PocketsphinxController is asynchronous and results in real practice are delivered via uncoupled callback it has not been designed as a purely automated test, but as an observed practical test. If it were designed as a purely automated test it would be testing something other than the way PocketsphinxController/OpenEarsEventsObserver works in an app, which is designed for good speech implementations rather than tests.*/
    NSString *pathToTestFile;
    /**If you are using a test file, you can set playbackTestFileDuringTest to TRUE in order to hear the test file playing back out of the device as it is run. This is an early experimental version of this functionality, implemented as simply as possibly, and it might not work very well yet. It is unlikely to be perfectly synchronized with the actual engine head position in the test file, but it should be off by less than a quarter-second so you should be able to understand where you are in the recording when turning this on. There is a big warning when using this, which is that it will be emitted with an AVAudioPlayer, which means that if what you are testing also uses AVAudioPlayers or things which conflict with them, and/or you are reading AVAudioPlayer delegates for particular events, this setting is almost certainly incompatible with your test case and you should run your test file silently.*/
    BOOL playbackTestFileDuringTest;
    /**If you are doing testing, you can toggle SmartCMN on or off (it defaults to off and should usually be left off since using it can lead to nondeterministic results on the first runs with new devices).*/
    BOOL useSmartCMNWithTestFiles;
/**\cond HIDDEN_SYMBOLS*/ 
    BOOL processSpeechLocally;
    BOOL outputAudio;
    int sampleRate;
    BOOL stopping;
    NSDictionary *queuedStart;
    BOOL micPermission;  
    BOOL doNotWarnAboutPermissions;    
    BOOL usingRejecto;
/**\endcond*/     
}

// These are the OpenEars methods for controlling Pocketsphinx. You should use these.

/**Start the speech recognition engine up. You provide the full paths to a language model and a dictionary file which are created using LanguageModelGenerator and the acoustic model you want to use (for instance [AcousticModel pathToModel:@"AcousticModelEnglish"]).*/
- (void) startListeningWithLanguageModelAtPath:(NSString *)languageModelPath dictionaryAtPath:(NSString *)dictionaryPath acousticModelAtPath:(NSString *)acousticModelPath languageModelIsJSGF:(BOOL)languageModelIsJSGF;  // Starts the recognition loop.
/**Shut down the engine. You must do this before releasing a parent view controller that contains PocketsphinxController.*/
- (void) stopListening; // Exits from the recognition loop.
/**Keep the engine going but stop listening to speech until resumeRecognition is called. Takes effect instantly.*/
- (void) suspendRecognition; // Stops interpreting sounds as speech without exiting from the recognition loop. You do not need to call these methods on behalf of Flite.
/**Resume listening for speech after suspendRecognition has been called.*/
- (void) resumeRecognition; // Starts interpreting sounds as speech after suspending recognition with the preceding method. You do not need to call these methods on behalf of Flite.
/**Change from one language model to another. This lets you change which words you are listening for depending on the context in your app. If you have already started the recognition loop and you want to switch to a different language model, you can use this and the model will be changed at the earliest opportunity. Will not have any effect unless recognition is already in progress. It isn't possible to change acoustic models in the middle of an already-started listening loop, just language model and dictionary.*/
- (void) changeLanguageModelToFile:(NSString *)languageModelPathAsString withDictionary:(NSString *)dictionaryPathAsString; 
/**Gives the volume of the incoming speech. This is a UI hook. You can't read it on the main thread or it will block.*/
- (Float32) pocketsphinxInputLevel; // This gives the input metering levels. This can only be run in a background thread that you create, otherwise it will block recognition
- (void) removeCmnPlist; // You can use this to remove the SmartCMN plist if you want to reset it.

/**\cond HIDDEN_SYMBOLS*/ 
// Here are all the multithreading methods, you should never do anything with any of these.
- (void) startVoiceRecognitionThreadWithLanguageModelAtPath:(NSString *)languageModelPath dictionaryAtPath:(NSString *)dictionaryPath acousticModelAtPath:(NSString *)acousticModelPath languageModelIsJSGF:(BOOL)languageModelIsJSGF;
- (void) stopVoiceRecognitionThread;
- (void) waitForVoiceRecognitionThreadToFinish;
- (void) startVoiceRecognitionThreadAutoreleasePoolWithArray:(NSArray *)arrayOfLanguageModelItems; // This is the autorelease pool in which the actual business of our loop is handled.

// Suspend and resume that is initiated by Flite. Do not call these directly.
- (void) suspendRecognitionForFliteSpeech;
- (void) resumeRecognitionForFliteSpeech;

// Do not call this directly, set it by assigning a float value to secondsOfSilenceToDetect
- (void) setSecondsOfSilence;
/**\endcond */ 

// Run one synchronous recognition pass on a recording from its beginning to its end and stop.
/**You can use this to run recognition on an already-recorded WAV file for testing. The WAV file has to be 16-bit and 16000 samples per second.*/
- (void) runRecognitionOnWavFileAtPath:(NSString *)wavPath usingLanguageModelAtPath:(NSString *)languageModelPath dictionaryAtPath:(NSString *)dictionaryPath acousticModelAtPath:(NSString *)acousticModelPath languageModelIsJSGF:(BOOL)languageModelIsJSGF;
/**You can use this to request mic permission in advance of running speech recognition.*/
- (void) requestMicPermission;
/**Returns whether your app has record permission. This is expected to be used after the user has at some point been prompted with requestMicPermission and the result has come back in the permission results OpenEarsEventsObserver delegate methods. If this is used before that point, accuracy of results are not guaranteed. If the user has either granted or denied permission in the past, this will return a boolean indicating the permission state.*/
- (BOOL) micPermissionIsGranted;

/**\cond HIDDEN_SYMBOLS*/ 
@property (nonatomic, assign) BOOL stopping;
@property (nonatomic, assign) BOOL micPermission;
@property (nonatomic, retain) NSThread *voiceRecognitionThread; // The loop would lock if run on the main thread so it has a background thread in which it always runs.
@property (nonatomic, retain) ContinuousModel *continuousModel; // The continuous model is the actual recognition loop.
@property (nonatomic, retain) OpenEarsEventsObserver *openEarsEventsObserver; // We use an OpenEarsEventsObserver here to get important information from other objects which may be instantiated.
/**\endcond */ 
@property (nonatomic, assign) float secondsOfSilenceToDetect;
@property (nonatomic, assign) BOOL returnNbest;
@property (nonatomic, assign) int nBestNumber;
@property (nonatomic, assign) int calibrationTime; // This can only be one of the values '1', '2', or '3'. Defaults to 1.
@property (nonatomic, assign) BOOL verbosePocketSphinx;
@property (nonatomic, assign) BOOL processSpeechLocally;
@property (nonatomic, assign) BOOL returnNullHypotheses;
@property (nonatomic, assign) BOOL outputAudio;
@property (nonatomic, assign) int sampleRate;
@property (nonatomic, retain) NSDictionary *queuedStart;
@property (nonatomic, copy) NSString *pathToTestFile;
@property (nonatomic, assign) BOOL playbackTestFileDuringTest;
@property (nonatomic, assign) BOOL useSmartCMNWithTestFiles;
@property (nonatomic, assign)BOOL audioSessionMixing;
@property (nonatomic, copy) NSString *audioMode;
@property (nonatomic, assign) BOOL isSuspended; 
@property (nonatomic, assign) BOOL isListening;  
@property (nonatomic, assign) BOOL doNotWarnAboutPermissions;
@property (nonatomic, assign) BOOL usingRejecto;
@end
