#import "ViewController.h"
#import <OpenEars/PocketsphinxController.h> // Please note that unlike in previous versions of OpenEars, we now link the headers through the framework.
#import <OpenEars/FliteController.h>
#import <OpenEars/LanguageModelGenerator.h>
#import <OpenEars/OpenEarsLogging.h>
#import <OpenEars/AcousticModel.h>

@implementation ViewController

@synthesize pocketsphinxController;
@synthesize startButton;
@synthesize stopButton;
@synthesize resumeListeningButton;
@synthesize suspendListeningButton;
@synthesize fliteController;
@synthesize statusTextView;
@synthesize heardTextView;
@synthesize pocketsphinxDbLabel;
@synthesize fliteDbLabel;
@synthesize openEarsEventsObserver;
@synthesize usingStartLanguageModel;
@synthesize pathToFirstDynamicallyGeneratedLanguageModel;
@synthesize pathToFirstDynamicallyGeneratedDictionary;
@synthesize pathToSecondDynamicallyGeneratedLanguageModel;
@synthesize pathToSecondDynamicallyGeneratedDictionary;
@synthesize uiUpdateTimer;
@synthesize slt;
@synthesize restartAttemptsDueToPermissionRequests;
@synthesize startupFailedDueToLackOfPermissions;

#define kLevelUpdatesPerSecond 18 // We'll have the ui update 18 times a second to show some fluidity without hitting the CPU too hard.

//#define kGetNbest // Uncomment this if you want to try out nbest

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
	[self stopDisplayingLevels]; // We'll need to stop any running timers before attempting to deallocate here.
	openEarsEventsObserver.delegate = nil;
}

#pragma mark -
#pragma mark Lazy Allocation

// Lazily allocated PocketsphinxController.
- (PocketsphinxController *)pocketsphinxController { 
	if (pocketsphinxController == nil) {
		pocketsphinxController = [[PocketsphinxController alloc] init];
        //pocketsphinxController.verbosePocketSphinx = TRUE; // Uncomment me for verbose debug output
        pocketsphinxController.outputAudio = TRUE;
#ifdef kGetNbest        
        pocketsphinxController.returnNbest = TRUE;
        pocketsphinxController.nBestNumber = 5;
#endif        
	}
	return pocketsphinxController;
}

// Lazily allocated slt voice.
- (Slt *)slt {
	if (slt == nil) {
		slt = [[Slt alloc] init];
	}
	return slt;
}

// Lazily allocated FliteController.
- (FliteController *)fliteController {
	if (fliteController == nil) {
		fliteController = [[FliteController alloc] init];
	}
	return fliteController;
}

// Lazily allocated OpenEarsEventsObserver.
- (OpenEarsEventsObserver *)openEarsEventsObserver {
	if (openEarsEventsObserver == nil) {
		openEarsEventsObserver = [[OpenEarsEventsObserver alloc] init];
	}
	return openEarsEventsObserver;
}

// The last class we're using here is LanguageModelGenerator but I don't think it's advantageous to lazily instantiate it. You can see how it's used below.
- (void) startListening {
    // startListeningWithLanguageModelAtPath:dictionaryAtPath:languageModelIsJSGF always needs to know the grammar file being used,
    // the dictionary file being used, and whether the grammar is a JSGF. You must put in the correct value for languageModelIsJSGF.
    // Inside of a single recognition loop, you can only use JSGF grammars or ARPA grammars, you can't switch between the two types.
    // An ARPA grammar is the kind with a .languagemodel or .DMP file, and a JSGF grammar is the kind with a .gram file.
    // If you wanted to just perform recognition on an isolated wav file for testing, you could do it as follows:
    // NSString *wavPath = [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath], @"test.wav"];
    //[self.pocketsphinxController runRecognitionOnWavFileAtPath:wavPath usingLanguageModelAtPath:self.pathToGrammarToStartAppWith dictionaryAtPath:self.pathToDictionaryToStartAppWith languageModelIsJSGF:FALSE];  // Starts the recognition loop.
    // But under normal circumstances you'll probably want to do continuous recognition as follows:
    [self.pocketsphinxController startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary acousticModelAtPath:[AcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:FALSE]; // Change "AcousticModelEnglish" to "AcousticModelSpanish" in order to perform Spanish recognition instead of English.
}

#pragma mark -
#pragma mark Hypothesis Disposition and Transformation

- (BOOL)isPowerSettingDispositionWithHypothesis:(NSString *)hyp_norm
{
    if ([hyp_norm hasPrefix:@"switch"]&&([hyp_norm hasSuffix:@"power off"]||[hyp_norm hasSuffix:@"power on"]))
        return YES;
    if ([hyp_norm hasPrefix:@"power"]&&([hyp_norm hasSuffix:@"off"]||[hyp_norm hasSuffix:@"on"]))
        return YES;
    if ([hyp_norm hasPrefix:@"turn"]&&([hyp_norm hasSuffix:@"off"]||[hyp_norm hasSuffix:@"on"]))
        return YES;
    if ([hyp_norm hasPrefix:@"set"]&&([hyp_norm hasSuffix:@"power off"]||[hyp_norm hasSuffix:@"power on"]))
        return YES;
    return NO;
}

- (int)getDispositionForHypothesis:(NSString *)hypothesis
{
    NSString *hyp_norm = [[hypothesis lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([self isPowerSettingDispositionWithHypothesis:hyp_norm]) {
        return DISPO_SET_POWER;
    //} else if ([hyp_norm hasPrefix:@""]) {
    //
    }
    return DISPO_INVALID;
}

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
    self.restartAttemptsDueToPermissionRequests = 0;
    self.startupFailedDueToLackOfPermissions = FALSE;
    //[OpenEarsLogging startOpenEarsLogging]; // Uncomment me for OpenEarsLogging
	[self.openEarsEventsObserver setDelegate:self]; // Make this class the delegate of OpenEarsObserver so we can get all of the messages about what OpenEars is doing.
    
    
    
    self.arrFunctions = [NSArray arrayWithObjects:
                         @"SWITCH",
                         @"INPUT",
                         @"TO",
                         @"POWER",
                         @"TURN",
                         @"ON",
                         @"OFF",
                         @"SET",
                         @"VOLUME",
                         nil];
    self.arrOutputs = [NSArray arrayWithObjects:
                       @"PROJECTOR",
                       @"RECEIVER",
                       nil];
    self.arrInputs = [NSArray arrayWithObjects:
                      @"XBOX",
                      @"THREE",
                      @"SIXTY",
                      @"FOUR",
                      @"PLAYSTATION",
                      @"PS2",
                      @"PS3",
                      @"PS4",
                      @"NINTENDO",
                      @"GAMECUBE",
                      @"DREAMCAST",
                      @"SATURN",
                      @"MAC",
                      @"MACINTOSH",
                      @"G4",
                      nil];
    
    
    
    NSMutableArray *vocabularyArray = [[NSMutableArray alloc] init];
    [vocabularyArray addObjectsFromArray:self.arrFunctions];
    [vocabularyArray addObjectsFromArray:self.arrOutputs];
    [vocabularyArray addObjectsFromArray:self.arrInputs];
	LanguageModelGenerator *languageModelGenerator = [[LanguageModelGenerator alloc] init];
	NSError *error = [languageModelGenerator generateLanguageModelFromArray:vocabularyArray withFilesNamed:@"FirstOpenEarsDynamicLanguageModel" forAcousticModelAtPath:[AcousticModel pathToModel:@"AcousticModelEnglish"]]; // Change "AcousticModelEnglish" to "AcousticModelSpanish" in order to create a language model for Spanish recognition instead of English.
	NSDictionary *firstDynamicLanguageGenerationResultsDictionary = nil;
	if([error code] != noErr) {
		NSLog(@"Dynamic language generator reported error %@", [error description]);	
	} else {
		firstDynamicLanguageGenerationResultsDictionary = [error userInfo];
		NSString *lmFile = [firstDynamicLanguageGenerationResultsDictionary objectForKey:@"LMFile"];
		NSString *dictionaryFile = [firstDynamicLanguageGenerationResultsDictionary objectForKey:@"DictionaryFile"];
		NSString *lmPath = [firstDynamicLanguageGenerationResultsDictionary objectForKey:@"LMPath"];
		NSString *dictionaryPath = [firstDynamicLanguageGenerationResultsDictionary objectForKey:@"DictionaryPath"];
		NSLog(@"Dynamic language generator completed successfully, you can find your new files %@\n and \n%@\n at the paths \n%@ \nand \n%@", lmFile,dictionaryFile,lmPath,dictionaryPath);
		self.pathToFirstDynamicallyGeneratedLanguageModel = lmPath;
		self.pathToFirstDynamicallyGeneratedDictionary = dictionaryPath;
	}
	self.usingStartLanguageModel = TRUE; // This is not an OpenEars thing, this is just so I can switch back and forth between the two models in this sample app.
    [self startListening];
	[self startDisplayingLevels];
	self.startButton.hidden = TRUE;
	self.stopButton.hidden = TRUE;
	self.suspendListeningButton.hidden = TRUE;
	self.resumeListeningButton.hidden = TRUE;
}

#pragma mark -
#pragma mark OpenEarsEventsObserver delegate methods

// An optional delegate method of OpenEarsEventsObserver which delivers the text of speech that Pocketsphinx heard and analyzed, along with its accuracy score and utterance ID.
- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
    
	NSLog(@"Received hypothesis is: \"%@\"", [hypothesis lowercaseString]); // Log it.
	self.heardTextView.text = [NSString stringWithFormat:@"Heard: \"%@\"", hypothesis]; // Show it in the status box.
	// This is how to use an available instance of FliteController. We're going to repeat back the command that we heard with the voice we've chosen.
	//[self.fliteController say:[NSString stringWithFormat:@"You said %@",hypothesis] withVoice:self.slt];
}

#ifdef kGetNbest   
- (void) pocketsphinxDidReceiveNBestHypothesisArray:(NSArray *)hypothesisArray { // Pocketsphinx has an n-best hypothesis dictionary.
    NSLog(@"hypothesisArray is %@",hypothesisArray);   
}
#endif

// An optional delegate method of OpenEarsEventsObserver which informs that there was an interruption to the audio session (e.g. an incoming phone call).
- (void) audioSessionInterruptionDidBegin {
	NSLog(@"AudioSession interruption began."); // Log it.
	self.statusTextView.text = @"Status: AudioSession interruption began."; // Show it in the status box.
	[self.pocketsphinxController stopListening]; // React to it by telling Pocketsphinx to stop listening since it will need to restart its loop after an interruption.
}

// An optional delegate method of OpenEarsEventsObserver which informs that the interruption to the audio session ended.
- (void) audioSessionInterruptionDidEnd {
	NSLog(@"AudioSession interruption ended."); // Log it.
	self.statusTextView.text = @"Status: AudioSession interruption ended."; // Show it in the status box.
    // We're restarting the previously-stopped listening loop.
    [self startListening];
}

// An optional delegate method of OpenEarsEventsObserver which informs that the audio input became unavailable.
- (void) audioInputDidBecomeUnavailable {
	NSLog(@"The audio input has become unavailable"); // Log it.
	self.statusTextView.text = @"Status: The audio input has become unavailable"; // Show it in the status box.
	[self.pocketsphinxController stopListening]; // React to it by telling Pocketsphinx to stop listening since there is no available input
}

// An optional delegate method of OpenEarsEventsObserver which informs that the unavailable audio input became available again.
- (void) audioInputDidBecomeAvailable {
	NSLog(@"The audio input is available"); // Log it.
	self.statusTextView.text = @"Status: The audio input is available"; // Show it in the status box.
    [self startListening];
}

// An optional delegate method of OpenEarsEventsObserver which informs that there was a change to the audio route (e.g. headphones were plugged in or unplugged).
- (void) audioRouteDidChangeToRoute:(NSString *)newRoute {
	NSLog(@"Audio route change. The new audio route is %@", newRoute); // Log it.
	self.statusTextView.text = [NSString stringWithFormat:@"Status: Audio route change. The new audio route is %@",newRoute]; // Show it in the status box.
	[self.pocketsphinxController stopListening]; // React to it by telling the Pocketsphinx loop to shut down and then start listening again on the new route
    [self startListening];
}

// An optional delegate method of OpenEarsEventsObserver which informs that the Pocketsphinx recognition loop hit the calibration stage in its startup.
// This might be useful in debugging a conflict between another sound class and Pocketsphinx. Another good reason to know when you're in the middle of
// calibration is that it is a timeframe in which you want to avoid playing any other sounds including speech so the calibration will be successful.
- (void) pocketsphinxDidStartCalibration {
	//NSLog(@"Pocketsphinx calibration has started."); // Log it.
	self.statusTextView.text = @"Status: Pocketsphinx calibration has started."; // Show it in the status box.
}

// An optional delegate method of OpenEarsEventsObserver which informs that the Pocketsphinx recognition loop completed the calibration stage in its startup.
// This might be useful in debugging a conflict between another sound class and Pocketsphinx.
- (void) pocketsphinxDidCompleteCalibration {
	//NSLog(@"Pocketsphinx calibration is complete."); // Log it.
	self.statusTextView.text = @"Status: Pocketsphinx calibration is complete."; // Show it in the status box.
	self.fliteController.duration_stretch = .9; // Change the speed
	self.fliteController.target_mean = 1.2; // Change the pitch
	self.fliteController.target_stddev = 1.5; // Change the variance
    //[self.fliteController say:@"Welcome to OpenEars." withVoice:self.slt];
    // The same statement with the pitch and other voice values changed.
	self.fliteController.duration_stretch = 1.0; // Reset the speed
	self.fliteController.target_mean = 1.0; // Reset the pitch
	self.fliteController.target_stddev = 1.0; // Reset the variance
}

// An optional delegate method of OpenEarsEventsObserver which informs that the Pocketsphinx recognition loop has entered its actual loop.
// This might be useful in debugging a conflict between another sound class and Pocketsphinx.
- (void) pocketsphinxRecognitionLoopDidStart {
	//NSLog(@"Pocketsphinx is starting up."); // Log it.
	self.statusTextView.text = @"Status: Pocketsphinx is starting up."; // Show it in the status box.
}

// An optional delegate method of OpenEarsEventsObserver which informs that Pocketsphinx is now listening for speech.
- (void) pocketsphinxDidStartListening {
	//NSLog(@"Pocketsphinx is now listening."); // Log it.
	self.statusTextView.text = @"Status: Pocketsphinx is now listening."; // Show it in the status box.
	self.startButton.hidden = TRUE; // React to it with some UI changes.
	self.stopButton.hidden = FALSE;
	self.suspendListeningButton.hidden = FALSE;
	self.resumeListeningButton.hidden = TRUE;
}

// An optional delegate method of OpenEarsEventsObserver which informs that Pocketsphinx detected speech and is starting to process it.
- (void) pocketsphinxDidDetectSpeech {
	//NSLog(@"Pocketsphinx has detected speech."); // Log it.
	self.statusTextView.text = @"Status: Pocketsphinx has detected speech."; // Show it in the status box.
}

// An optional delegate method of OpenEarsEventsObserver which informs that Pocketsphinx detected a second of silence, indicating the end of an utterance. 
// This was added because developers requested being able to time the recognition speed without the speech time. The processing time is the time between 
// this method being called and the hypothesis being returned.
- (void) pocketsphinxDidDetectFinishedSpeech {
	//NSLog(@"Pocketsphinx has detected a second of silence, concluding an utterance."); // Log it.
	self.statusTextView.text = @"Status: Pocketsphinx has detected finished speech."; // Show it in the status box.
}


// An optional delegate method of OpenEarsEventsObserver which informs that Pocketsphinx has exited its recognition loop, most 
// likely in response to the PocketsphinxController being told to stop listening via the stopListening method.
- (void) pocketsphinxDidStopListening {
	NSLog(@"Pocketsphinx has stopped listening."); // Log it.
	self.statusTextView.text = @"Status: Pocketsphinx has stopped listening."; // Show it in the status box.
}

// An optional delegate method of OpenEarsEventsObserver which informs that Pocketsphinx is still in its listening loop but it is not
// Going to react to speech until listening is resumed.  This can happen as a result of Flite speech being
// in progress on an audio route that doesn't support simultaneous Flite speech and Pocketsphinx recognition,
// or as a result of the PocketsphinxController being told to suspend recognition via the suspendRecognition method.
- (void) pocketsphinxDidSuspendRecognition {
	NSLog(@"Pocketsphinx has suspended recognition."); // Log it.
	self.statusTextView.text = @"Status: Pocketsphinx has suspended recognition."; // Show it in the status box.
}

// An optional delegate method of OpenEarsEventsObserver which informs that Pocketsphinx is still in its listening loop and after recognition
// having been suspended it is now resuming.  This can happen as a result of Flite speech completing
// on an audio route that doesn't support simultaneous Flite speech and Pocketsphinx recognition,
// or as a result of the PocketsphinxController being told to resume recognition via the resumeRecognition method.
- (void) pocketsphinxDidResumeRecognition {
	NSLog(@"Pocketsphinx has resumed recognition."); // Log it.
	self.statusTextView.text = @"Status: Pocketsphinx has resumed recognition."; // Show it in the status box.
}

// An optional delegate method which informs that Pocketsphinx switched over to a new language model at the given URL in the course of
// recognition. This does not imply that it is a valid file or that recognition will be successful using the file.
- (void) pocketsphinxDidChangeLanguageModelToFile:(NSString *)newLanguageModelPathAsString andDictionary:(NSString *)newDictionaryPathAsString {
	NSLog(@"Pocketsphinx is now using the following language model: \n%@ and the following dictionary: %@",newLanguageModelPathAsString,newDictionaryPathAsString);
}

// An optional delegate method of OpenEarsEventsObserver which informs that Flite is speaking, most likely to be useful if debugging a
// complex interaction between sound classes. You don't have to do anything yourself in order to prevent Pocketsphinx from listening to Flite talk and trying to recognize the speech.
- (void) fliteDidStartSpeaking {
	NSLog(@"Flite has started speaking"); // Log it.
	self.statusTextView.text = @"Status: Flite has started speaking."; // Show it in the status box.
}

// An optional delegate method of OpenEarsEventsObserver which informs that Flite is finished speaking, most likely to be useful if debugging a
// complex interaction between sound classes.
- (void) fliteDidFinishSpeaking {
	NSLog(@"Flite has finished speaking"); // Log it.
	self.statusTextView.text = @"Status: Flite has finished speaking."; // Show it in the status box.
}

- (void) pocketSphinxContinuousSetupDidFail { // This can let you know that something went wrong with the recognition loop startup. Turn on [OpenEarsLogging startOpenEarsLogging] to learn why.
	NSLog(@"Setting up the continuous recognition loop has failed for some reason, please turn on [OpenEarsLogging startOpenEarsLogging] in OpenEarsConfig.h to learn more."); // Log it.
	self.statusTextView.text = @"Status: Not possible to start recognition loop."; // Show it in the status box.	
}

- (void) testRecognitionCompleted { // A test file which was submitted for direct recognition via the audio driver is done.
	NSLog(@"A test file which was submitted for direct recognition via the audio driver is done."); // Log it.
    [self.pocketsphinxController stopListening];
    
}

/** Pocketsphinx couldn't start because it has no mic permissions (will only be returned on iOS7 or later).*/
- (void) pocketsphinxFailedNoMicPermissions {
    NSLog(@"The user has never set mic permissions or denied permission to this app's mic, so listening will not start.");
    self.startupFailedDueToLackOfPermissions = TRUE;
}

/** The user prompt to get mic permissions, or a check of the mic permissions, has completed with a TRUE or a FALSE result  (will only be returned on iOS7 or later).*/
- (void) micPermissionCheckCompleted:(BOOL)result {
    if(result == TRUE) {
        self.restartAttemptsDueToPermissionRequests++;
        if(self.restartAttemptsDueToPermissionRequests == 1 && self.startupFailedDueToLackOfPermissions == TRUE) { // If we get here because there was an attempt to start which failed due to lack of permissions, and now permissions have been requested and they returned true, we restart exactly once with the new permissions.
            [self startListening]; // Only do this once.
            self.startupFailedDueToLackOfPermissions = FALSE;
        }
    }
}

#pragma mark -
#pragma mark UI

// This is not OpenEars-specific stuff, just some UI behavior

- (IBAction) suspendListeningButtonAction { // This is the action for the button which suspends listening without ending the recognition loop
	[self.pocketsphinxController suspendRecognition];
	self.startButton.hidden = TRUE;
	self.stopButton.hidden = FALSE;
	self.suspendListeningButton.hidden = TRUE;
	self.resumeListeningButton.hidden = FALSE;
}

- (IBAction) resumeListeningButtonAction { // This is the action for the button which resumes listening if it has been suspended
	[self.pocketsphinxController resumeRecognition];
	self.startButton.hidden = TRUE;
	self.stopButton.hidden = FALSE;
	self.suspendListeningButton.hidden = FALSE;
	self.resumeListeningButton.hidden = TRUE;	
}

- (IBAction) stopButtonAction { // This is the action for the button which shuts down the recognition loop.
	[self.pocketsphinxController stopListening];
	self.startButton.hidden = FALSE;
	self.stopButton.hidden = TRUE;
	self.suspendListeningButton.hidden = TRUE;
	self.resumeListeningButton.hidden = TRUE;
}

- (IBAction) startButtonAction { // This is the action for the button which starts up the recognition loop again if it has been shut down.
    [self startListening];
	self.startButton.hidden = TRUE;
	self.stopButton.hidden = FALSE;
	self.suspendListeningButton.hidden = FALSE;
	self.resumeListeningButton.hidden = TRUE;
}

#pragma mark -
#pragma mark Example for reading out Pocketsphinx and Flite audio levels without locking the UI by using an NSTimer

// What follows are not OpenEars methods, just an approach for level reading
// that I've included with this sample app. My example implementation does make use of two OpenEars
// methods:	the pocketsphinxInputLevel method of PocketsphinxController and the fliteOutputLevel
// method of fliteController. 
//
// The example is meant to show one way that you can read those levels continuously without locking the UI, 
// by using an NSTimer, but the OpenEars level-reading methods 
// themselves do not include multithreading code since I believe that you will want to design your own 
// code approaches for level display that are tightly-integrated with your interaction design and the  
// graphics API you choose. 
// 
// Please note that if you use my sample approach, you should pay attention to the way that the timer is always stopped in
// dealloc. This should prevent you from having any difficulties with deallocating a class due to a running NSTimer process.

- (void) startDisplayingLevels { // Start displaying the levels using a timer
	[self stopDisplayingLevels]; // We never want more than one timer valid so we'll stop any running timers first.
	self.uiUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/kLevelUpdatesPerSecond target:self selector:@selector(updateLevelsUI) userInfo:nil repeats:YES];
}

- (void) stopDisplayingLevels { // Stop displaying the levels by stopping the timer if it's running.
	if(self.uiUpdateTimer && [self.uiUpdateTimer isValid]) { // If there is a running timer, we'll stop it here.
		[self.uiUpdateTimer invalidate];
		self.uiUpdateTimer = nil;
	}
}

- (void) updateLevelsUI { // And here is how we obtain the levels.  This method includes the actual OpenEars methods and uses their results to update the UI of this view controller.
	self.pocketsphinxDbLabel.text = [NSString stringWithFormat:@"Pocketsphinx Input level:%f",[self.pocketsphinxController pocketsphinxInputLevel]];  //pocketsphinxInputLevel is an OpenEars method of the class PocketsphinxController.
	if(self.fliteController.speechInProgress == TRUE) {
		self.fliteDbLabel.text = [NSString stringWithFormat:@"Flite Output level: %f",[self.fliteController fliteOutputLevel]]; // fliteOutputLevel is an OpenEars method of the class FliteController.
	}
}

@end
