//  OpenEars 
//  http://www.politepix.com/openears
//
//  ContinuousModel.h
//  OpenEars
//
//  ContinuousModel is a class which consists of the continuous listening loop used by Pocketsphinx.
//
//  Copyright Politepix UG (haftungsbeschränkt) 2012. All rights reserved.
//  http://www.politepix.com
//  Contact at http://www.politepix.com/contact
//
//  this file is licensed under the Politepix Shared Source license found 
//  found in the root of the source distribution. Please see the file "Version.txt" in the root of 
//  the source distribution for the version number of this OpenEars package.


//  This class is _never_ directly accessed by a project making use of OpenEars.
/**\cond HIDDEN_SYMBOLS*/

#import "ContinuousAudioUnit.h"
#import "ContinuousADModule.h"
@class SmartCMN;

#define kConditionExitListeningLoop 0
#define kConditionExitListeningLoopOrLanguageModelChangeRequest 1

#define kno_search_false FALSE
#define kfull_utt_process_raw_false FALSE

#define kVadBufferSize 32368

@protocol ContinuousModelDelegate;

@interface ContinuousModel : NSObject {

	BOOL exitListeningLoop; // Should we break out of the loop?
	BOOL inMainRecognitionLoop; // Have we entered the recognition loop or are we still setting up or in a state of having exited?
	BOOL thereIsALanguageModelChangeRequest;
	NSString *languageModelFileToChangeTo;
	NSString *dictionaryFileToChangeTo;
    float secondsOfSilenceToDetect;
    PocketsphinxAudioDevice *audioDevice; // The "device", which is actually a struct containing an Audio Unit.
    BOOL returnNbest;
    int nBestNumber;
    int calibrationTime;
    BOOL outputAudio;
    BOOL processSpeechLocally;
    BOOL returnNullHypotheses;
    NSString *pathToTestFile;
    BOOL useSmartCMNWithTestFiles;
    id<ContinuousModelDelegate> delegate;
    cont_ad_t *continuousListener;
    BOOL longRecognition;
    int firstEntryIntoOuterLoopAfterResuming;
    int firstEntryIntoInnerLoopAfterResuming;
    SmartCMN *smartCMN;
    int listeningStarts;
    NSTimeInterval utteranceTimer;
    BOOL usingRejecto;
}

- (void) listeningLoopWithLanguageModelAtPath:(NSString *)languageModelPath dictionaryAtPath:(NSString *)dictionaryPath acousticModelAtPath:(NSString *)acousticModelPath languageModelIsJSGF:(BOOL)languageModelIsJSGF; // Start the loop.
- (void) changeLanguageModelToFile:(NSString *)languageModelPathAsString withDictionary:(NSString *)dictionaryPathAsString;
- (void) removeCmnPlist;
- (void) runRecognitionOnWavFileAtPath:(NSString *)wavPath usingLanguageModelAtPath:(NSString *)languageModelPath dictionaryAtPath:(NSString *)dictionaryPath acousticModelAtPath:(NSString *)acousticModelPath languageModelIsJSGF:(BOOL)languageModelIsJSGF;
- (CFStringRef) getCurrentRoute;
- (void) setCurrentRouteTo:(NSString *)newRoute;
- (int) getRecognitionIsInProgress;
- (void) setRecognitionIsInProgressTo:(int)recognitionIsInProgress;
- (int) getRecordData;
- (void) setRecordDataTo:(int)recordData;
- (float) getMeteringLevel;
- (void) setupCalibrationBuffer;
- (void) putAwayCalibrationBuffer;
- (void) clearBuffers;
- (void) setContinuousListenerLogFPToNull;
- (void) setContinuousListenerLogFPToStdOut;
- (NSDictionary *) setUpCommandArray:(id)commandArrayModel secondItemIsEmpty:(BOOL)secondItemIsEmpty forlanguageModel:(NSString *)languageModelPath dictionaryPath:(NSString *)dictionaryPath acousticModelPath:(NSString *)acousticModelPath isJSGF:(BOOL)isJSGF;
- (void) stopTestFile;
- (BOOL) shouldBreakForCondition:(int)condition;
- (void) detectSpeechInBuffer:(SInt16 *)audioDeviceBuffer usingSpeechData:(int32 *)speechData withSleepTime:(int)sleepTime;
- (void) performContinuousFailureStopForIssue:(NSString *)issue;
- (int) getFirstFrameStateForBuffer:(int16 *)audioDeviceBuffer;
- (FILE *) checkForBeginning;
- (int) initializeVADAndStartRecordingWithOptionalCalibration:(BOOL)performCalibration withFP:(FILE *)fp;
- (int) prepareTestAndOpenAudioDevice;
- (NSString *) compileKnownWordsFromFileAtPath:(NSString *)filePath;
- (void) checkAndStopTestFile;
- (void) announceSpeechDetection;
- (int) checkForEndOfSpeechForBuffer:(int16 *)audioDeviceBuffer andFirstFrame:(int)firstFrame withSpeechData:(int32 *)speechData andTimeStamp:(int32 *)timestamp;
- (int) stopRecordingAndResetWithBuffer:(int16 *)audioDeviceBuffer;
- (void) checkForEndingWithFile:(FILE *)file;
- (void) clearBuffer:(int16 *)audioDeviceBuffer;
- (void) announceLoopHasStartedWithDictionaryAtPath:(NSString *)dictionaryPath;
- (void) announceLoopHasEnded;
- (void) announceListening;
- (void) shutDownDeviceAndVAD;
- (BOOL) shouldUseSmartCMN;
- (void) resetFirstEntryAfterResuming;
- (int) restartRecordingAfterRecognition;
- (void) setPocketsphinxListening;
- (void) setPocketsphinxDoneListening;
- (void) shutDownLoop:(FILE *)file;
- (int) recalibrate;

@property (nonatomic, assign) BOOL exitListeningLoop; // Should we break out of the loop?
@property (nonatomic, assign) BOOL inMainRecognitionLoop; // Have we entered the recognition loop or are we still setting up or in a state of having exited?
@property (nonatomic, assign) BOOL thereIsALanguageModelChangeRequest;
@property (nonatomic, retain) NSString *languageModelFileToChangeTo;
@property (nonatomic, retain) NSString *dictionaryFileToChangeTo;
@property (nonatomic, assign) float secondsOfSilenceToDetect;
@property (nonatomic, assign) BOOL returnNbest;
@property (nonatomic, assign) int nBestNumber;
@property (nonatomic, assign) int calibrationTime;
@property (nonatomic, assign) BOOL outputAudio;
@property (nonatomic, assign) BOOL processSpeechLocally;
@property (nonatomic, assign) BOOL returnNullHypotheses;
@property (nonatomic, copy) NSString *pathToTestFile;
@property (nonatomic, assign) BOOL useSmartCMNWithTestFiles;
@property (nonatomic, assign) cont_ad_t *continuousListener;
@property (nonatomic, assign) BOOL longRecognition;
@property (assign) id<ContinuousModelDelegate> delegate; // the delegate will be sent events.
@property (nonatomic, assign) int firstEntryIntoOuterLoopAfterResuming;
@property (nonatomic, assign) int firstEntryIntoInnerLoopAfterResuming;
@property (nonatomic, retain) SmartCMN *smartCMN;
@property (nonatomic, assign) int listeningStarts;
@property (nonatomic, assign) NSTimeInterval utteranceTimer;
@property (nonatomic, assign) BOOL usingRejecto;
@end


@protocol ContinuousModelDelegate <NSObject>

@optional 

// Delegate Methods for Continuous Model.


/** Listening loop has ended.*/
- (void) listeningLoopHasEnded; 
- (void) listeningLoopHasStarted; 
- (void) listeningIsSuspended; 
- (void) listeningIsResumed; 
@end
/**\endcond */