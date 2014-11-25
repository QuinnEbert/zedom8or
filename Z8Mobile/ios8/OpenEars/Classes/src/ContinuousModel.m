//  OpenEars 
//  http://www.politepix.com/openears
//
//  ContinuousModel.mm
//  OpenEars
//
//  ContinuousModel is a class which consists of the continuous listening loop used by Pocketsphinx.
//
//  This is a Pocketsphinx continuous listening loop based on modifications to the Pocketsphinx file continuous.c.
//
//  Copyright Politepix UG (hatfungsbeschränkt) 2012 excepting that which falls under the copyright of Carnegie Mellon University as part
//  of their file continuous.c.
//  http://www.politepix.com
//  Contact at http://www.politepix.com/contact
//
//  this file is licensed under the Politepix Shared Source license found 
//  found in the root of the source distribution. Please see the file "Version.txt" in the root of 
//  the source distribution for the version number of this OpenEars package.
//  Removed the references to the CMU code because this source doesn't have any overlap with it anymore.

#import "ContinuousModel.h"
#import "pocketsphinx.h"
#import "unistd.h"
#import "PocketsphinxRunConfig.h"
#import "fsg_search_internal.h"
#import "RuntimeVerbosity.h"
#import "AudioConstants.h"
#import "CommandArray.h"
#import "PocketsphinxRunConfig.h"
#import "cmd_ln.h"
#import "OpenEarsStaticAnalysisToggle.h"
#import "OpenEarsNotification.h"
#import "SmartCMN.h"

@implementation ContinuousModel

@synthesize inMainRecognitionLoop; // Have we entered the main part of the loop yet?
@synthesize exitListeningLoop; // Should we be breaking out of the loop at the nearest opportunity?
@synthesize thereIsALanguageModelChangeRequest;
@synthesize languageModelFileToChangeTo;
@synthesize dictionaryFileToChangeTo;
@synthesize secondsOfSilenceToDetect;
@synthesize returnNbest;
@synthesize nBestNumber;
@synthesize calibrationTime;
@synthesize outputAudio;
@synthesize processSpeechLocally;
@synthesize returnNullHypotheses;
@synthesize delegate;
@synthesize pathToTestFile;
@synthesize useSmartCMNWithTestFiles;
@synthesize continuousListener;
@synthesize longRecognition;
@synthesize firstEntryIntoOuterLoopAfterResuming;
@synthesize firstEntryIntoInnerLoopAfterResuming;
@synthesize smartCMN;
@synthesize listeningStarts;
@synthesize utteranceTimer;
@synthesize usingRejecto;

extern int openears_logging;
extern int verbose_pocketsphinx;
extern int returner;
extern int perform_request;

#define kExcessiveUtterancePeriod 13.0 // This in combination with a search buffer resize probably indicates a stuck voice activity detector.

#pragma mark -
#pragma mark Memory Management
#pragma mark -

- (id) init {
    if (self = [super init]) {
        longRecognition = FALSE;
        outputAudio = FALSE;
        exitListeningLoop = 0;
        thereIsALanguageModelChangeRequest = FALSE;
        returnNullHypotheses = FALSE;
        listeningStarts = 0;
        usingRejecto = FALSE;
    }
    return self;
}

- (void)dealloc {
	[languageModelFileToChangeTo release];
	[dictionaryFileToChangeTo release];
    [pathToTestFile release];
    [super dealloc];
}

- (SmartCMN *)smartCMN {
    if (smartCMN == nil) {
        smartCMN = [[SmartCMN alloc] init];
    }
    return smartCMN;
};

#pragma mark -
#pragma mark Audio Device Functions
#pragma mark -

- (CFStringRef) getCurrentRoute {
    
	if(audioDevice != NULL) {
        return getRoute();
    }   
	return (CFStringRef)@"NoAudioDeviceRoute";
}

- (void) setCurrentRouteTo:(NSString *)newRoute {
	if(audioDevice != NULL && audioDevice->currentRoute != NULL) {
		audioDevice->currentRoute = (CFStringRef)newRoute;
	}
}

- (int) getRecognitionIsInProgress {
	if(audioDevice != NULL) {
		return audioDevice->recognitionIsInProgress;
	}
	return 0;
}

- (void) setRecognitionIsInProgressTo:(int)recognitionIsInProgress {
	if(audioDevice != NULL) {
		audioDevice->recognitionIsInProgress = recognitionIsInProgress;
	}
}

- (int) getRecordData {
	if(audioDevice != NULL) {
		return audioDevice->recordData;
	}
	return 0;
}

- (void) setRecordDataTo:(int)recordData {
	if(audioDevice != NULL) {
		audioDevice->recordData = recordData;
	}
}

- (Float32) getMeteringLevel {
	if(audioDevice != NULL) {	
		return pocketsphinxAudioDeviceMeteringLevel(audioDevice);
	}
	return 0.0;
}

- (void) clearBuffers {
    if(audioDevice != NULL) {
        clear_buffers();    
    }
}

#pragma mark -
#pragma mark Language Model Management Methods
#pragma mark -

- (NSString *)languageModelFileToChangeTo {
	if (languageModelFileToChangeTo == nil) {
		languageModelFileToChangeTo = [[NSString alloc] init];
	}
	return languageModelFileToChangeTo;
}

- (NSString *) compileKnownWordsFromFileAtPath:(NSString *)filePath {
	NSArray *dictionaryArray = [[NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	NSMutableString *allWords = [[[NSMutableString alloc] init]autorelease];
    int cutoff = 0;
	for(NSString *string in dictionaryArray) {
        if(cutoff > 30) {
#if __LP64__           
            [allWords appendString:[NSString stringWithFormat:@"...and %lu more.\n",[dictionaryArray count]-30]];
#else
            [allWords appendString:[NSString stringWithFormat:@"...and %d more.\n",[dictionaryArray count]-30]];            
#endif            
            break;
        } else {
            NSArray *lineArray = [string componentsSeparatedByString:@"\t"];
            [allWords appendString:[NSString stringWithFormat:@"%@\n",[[lineArray objectAtIndex:0]stringByReplacingOccurrencesOfString:@"#^#" withString:@" "]]];
            cutoff++;
        }
	}
	return allWords;
}

- (void) changeLanguageModelForDecoder:(ps_decoder_t *)pocketsphinxDecoder languageModelIsJSGF:(BOOL)languageModelIsJSGF {

    if(openears_logging == 1) NSLog(@"there is a request to change to the language model file %@", self.languageModelFileToChangeTo);
    
    int fatalErrors = 0;
    
    if(languageModelIsJSGF == TRUE) {
        
		NSArray *dictionaryArray = [[NSString stringWithContentsOfFile:self.dictionaryFileToChangeTo encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        
		int updateValue = 0;
		int count = 1;
		int add_word_result = 0;
        
        NSCharacterSet *nonWhitespaceCharacterSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
        
        NSMutableArray *mutableCleaningArray = [[NSMutableArray alloc] init];

        for(NSString *string in dictionaryArray) {
            
            if(([string length] > 0) && [string rangeOfCharacterFromSet:nonWhitespaceCharacterSet].location != NSNotFound) { // This string has a length of at least one and it doesn't exclusively consist of whitespace or newlines, so it can be parsed by what follows.
                [mutableCleaningArray addObject:string];
            }
            
        }
        
        NSArray *dictionaryProcessingArray = [[NSArray alloc] initWithArray:(NSArray *)mutableCleaningArray];
        [mutableCleaningArray release];
        
		for(NSString *string in dictionaryProcessingArray) {
           
            NSArray *lineArray = [string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            NSMutableString *mutablePhonesString = [[NSMutableString alloc] init];
            int i;
            for ( i = 0; i < [lineArray count]; i++ ) {
                if(i > 0) [mutablePhonesString appendString:[NSString stringWithFormat:@"%@ ",[lineArray objectAtIndex:i]]];
            }
            
            NSRange deletionRange = {[mutablePhonesString length]-1,1};
            [mutablePhonesString deleteCharactersInRange:deletionRange];
            
            if(count < [dictionaryProcessingArray count]) {
                updateValue = 0;
            } else {
                updateValue = 1;
            }
 
            add_word_result = ps_add_word(pocketsphinxDecoder,(char *)[[lineArray objectAtIndex:0] UTF8String], (char *)[mutablePhonesString UTF8String],updateValue);
            [mutablePhonesString release];
            
            if(add_word_result > -1) {
                if(openears_logging == 1) NSLog(@"%@ was added to dictionary",[lineArray objectAtIndex:0]);
            } else {
                if(openears_logging == 1) NSLog(@"%@ was not added to dictionary, perhaps because it is already in the dictionary",[lineArray objectAtIndex:0]);
            }
            
            count++;
            
		}
        
        [dictionaryProcessingArray release];
        
        
		if(openears_logging == 1) NSLog(@"A request has been made to change a JSGF grammar on the fly.");
		fsg_set_t *fsgs = ps_get_fsgset(pocketsphinxDecoder);
        
         fsg_set_remove_byname(fsgs, fsg_model_name(fsgs->fsg));
        
		jsgf_t *jsgf;
		fsg_model_t *fsg;
        jsgf_rule_t *rule;
		char const *path = (char *)[self.languageModelFileToChangeTo UTF8String];
        
        if ((jsgf = jsgf_parse_file(path, NULL)) == NULL) {
			if(openears_logging == 1) NSLog(@"Error: no JSGF file at path.");
            fatalErrors++;
		}
        rule = NULL;
        
		jsgf_rule_iter_t *itor;
        
		for (itor = jsgf_rule_iter(jsgf); itor;
			 itor = jsgf_rule_iter_next(itor)) {
			rule = jsgf_rule_iter_rule(itor);
			if (jsgf_rule_public(rule))
				break;
            
            if (rule == NULL) {
                if(openears_logging == 1) NSLog(@"Error: No public rules found in %s", path);
                fatalErrors++;
            }
        }
        
        if(openears_logging == 1)NSLog(@"current language weight is %d",fsgs->lw);
        
        int languageWeight = kJSGFLanguageWeight; // For some reason this value is a) lost and b) now an int instead of a float. Resetting it manually at this time helps a lot with recognition quality.
        
		fsg = jsgf_build_fsg(jsgf, rule, pocketsphinxDecoder->lmath, languageWeight);
      
        if (fsg_set_add(fsgs, fsg_model_name(fsg), fsg) != fsg) {
			if(openears_logging == 1) NSLog(@"Error: could not add finite state grammar to set.");
            fatalErrors++;
        } else {
            
		}
        
        if (fsg_set_select(fsgs, fsg_model_name(fsg)) == NULL) {
			if(openears_logging == 1) NSLog(@"Error: could not select new grammar.");
            fatalErrors++;
		}
        
		ps_update_fsgset(pocketsphinxDecoder);
        
	} else {
        
		if(openears_logging == 1) NSLog(@"A request has been made to change an ARPA grammar on the fly. The language model to change to is %@", self.languageModelFileToChangeTo);
		NSNumber *languageModelID = [NSNumber numberWithInt:999];
		NSFileManager *fileManager = [[NSFileManager alloc] init];
		NSError *error = nil;
		NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:self.languageModelFileToChangeTo error:&error];
		if(error) {
			if(openears_logging == 1) NSLog(@"Error: couldn't get attributes of language model file.");
            fatalErrors++;
		} else {
			if(openears_logging == 1) NSLog(@"In this session, the requested language model will be known to Pocketsphinx as id %@.",[fileAttributes valueForKey:NSFileSystemFileNumber]);
			languageModelID = [fileAttributes valueForKey:NSFileSystemFileNumber];
		}
        
		[fileManager release];
        
		ngram_model_t *baseLanguageModel, *newLanguageModelToAdd;
        
		newLanguageModelToAdd = ngram_model_read(pocketsphinxDecoder->config, (char *)[self.languageModelFileToChangeTo UTF8String], NGRAM_AUTO, pocketsphinxDecoder->lmath);
        
		baseLanguageModel = ps_get_lmset(pocketsphinxDecoder);
        
		if(openears_logging == 1) NSLog(@"languageModelID is %s",(char *)[[languageModelID stringValue] UTF8String]);
		ngram_model_set_add(baseLanguageModel, newLanguageModelToAdd, (char *)[[languageModelID stringValue] UTF8String], 1.0, TRUE);
		ngram_model_set_select(baseLanguageModel, (char *)[[languageModelID stringValue] UTF8String]);
        
		ps_update_lmset(pocketsphinxDecoder, baseLanguageModel);
        
		int loadingDictionaryResult = ps_load_dict(pocketsphinxDecoder, (char *)[self.dictionaryFileToChangeTo UTF8String],NULL, NULL);
        
		if(loadingDictionaryResult > -1) {
			if(openears_logging == 1) NSLog(@"Success loading the dictionary file %@.",self.dictionaryFileToChangeTo);
		} else {
			if(openears_logging == 1) NSLog(@"Error: could not load the specified dictionary file.");
            fatalErrors++;
		}
        
	}
    
    if(fatalErrors > 0) { // Language model or grammar switch wasn't successful, report the failure and reset the variables.

        if(openears_logging == 1) NSLog(@"There were too many errors to switch the language model or grammar, please search the console for the word 'error' to investigate the issues.");
        
        self.languageModelFileToChangeTo = nil;
		self.thereIsALanguageModelChangeRequest = FALSE;
        
    } else { // Language model or grammar switch appears to have been successful.

        [OpenEarsNotification performOpenEarsNotificationOnMainThread:@"PocketsphinxDidChangeLanguageModel" withOptionalObjects:[NSArray arrayWithObjects:self.languageModelFileToChangeTo, self.dictionaryFileToChangeTo,nil] andKeys:[NSArray arrayWithObjects:@"LanguageModelFilePath",@"DictionaryFilePath",nil]];

		self.languageModelFileToChangeTo = nil;
		self.thereIsALanguageModelChangeRequest = FALSE;
        
		if(openears_logging == 1) NSLog(@"Changed language model. Project has these words or phrases in its dictionary:\n%@", [self compileKnownWordsFromFileAtPath:self.dictionaryFileToChangeTo]);
    }
}

- (void) changeLanguageModelToFile:(NSString *)languageModelPathAsString withDictionary:(NSString *)dictionaryPathAsString {
	self.thereIsALanguageModelChangeRequest = TRUE;
	self.languageModelFileToChangeTo = languageModelPathAsString;
	self.dictionaryFileToChangeTo = dictionaryPathAsString;
}

- (void) checkWhetherJSGFSettingOf:(BOOL)languageModelIsJSGF LooksCorrectForThisFilename:(NSString *)languageModelPath {
    
    if([languageModelPath hasSuffix:@".gram"] || [languageModelPath hasSuffix:@".GRAM"] || [languageModelPath hasSuffix:@".grammar"] || [languageModelPath hasSuffix:@".GRAMMAR"] || [languageModelPath hasSuffix:@".jsgf"] || [languageModelPath hasSuffix:@".JSGF"]) {
        
        // This is probably a JSGF file. Let's see if the languageModelIsJSGF seems correct for that case.
        if(!languageModelIsJSGF) { // Probable JSGF file with the ARPA bit set
            if(openears_logging == 1) NSLog(@"The file you've sent to the decoder appears to be a JSGF grammar based on its naming, but you have not set languageModelIsJSGF: to TRUE. If you are experiencing recognition issues, there is a good chance that this is the reason for it.");
        }
        
    } else if([languageModelPath hasSuffix:@".lm"] || [languageModelPath hasSuffix:@".LM"] || [languageModelPath hasSuffix:@".languagemodel"] || [languageModelPath hasSuffix:@".LANGUAGEMODEL"] || [languageModelPath hasSuffix:@".arpa"] || [languageModelPath hasSuffix:@".ARPA"] || [languageModelPath hasSuffix:@".dmp"] || [languageModelPath hasSuffix:@".DMP"]) {
        
        // This is probably an ARPA file. Let's see if the languageModelIsJSGF seems correct for that case.        
        if(languageModelIsJSGF) { // Probable ARPA file with the JSGF bit set
            if(openears_logging == 1) NSLog(@"The file you've sent to the decoder appears to be an ARPA-style language model based on its naming, but you have set languageModelIsJSGF: to TRUE. If you are experiencing recognition issues, there is a good chance that this is the reason for it.");
        }
        
    } else { // It isn't clear from the suffix what kind of file this is, which could easily be a bad sign so let's mention it.
        if(openears_logging == 1) NSLog(@"The LanguageModelAtPath filename that was submitted to listeningLoopWithLanguageModelAtPath: doesn't have a suffix that is usually seen on an ARPA model or a JSGF model, which are the only two kinds of models that OpenEars supports. If you are having difficulty with your project, you should probably take a look at the language model or grammar file you are trying to submit to the decoder and/or its naming.");
    }
}

#pragma mark -
#pragma mark Test File Management
#pragma mark -

- (void) stopTestFile {
    if(audioDevice->positionInTestFile == audioDevice->bytesInTestFile) { // This is called when it's time to check if the test file has ended.
        audioDevice->takeBuffersFromTestFile = FALSE;
        [OpenEarsNotification performOpenEarsNotificationOnMainThread:@"TestRecognitionCompleted" withOptionalObjects:nil andKeys:nil];
        audioDevice->pathToTestFile = "";
        audioDevice->bytesInTestFile = 0;
        audioDevice->positionInTestFile = 0;
        free(audioDevice->testFileBuffer);
    }
}

- (int) prepareTestAndOpenAudioDevice {
        
    BOOL runTest = FALSE;
    
    const char *localPathToTestFile = NULL;
    
    if(self.listeningStarts < 2) { // Testing only happens on the first start.
            
        if(self.pathToTestFile && ([self.pathToTestFile length] > 10)) { // There is a test file request.
            if([[NSFileManager defaultManager]fileExistsAtPath:self.pathToTestFile]==TRUE) {
                runTest = TRUE;
                localPathToTestFile = [self.pathToTestFile UTF8String];        
            } else {
                NSLog(@"Warning: There is a request to use pathToTestFile but there isn't a usable file at the location given (\"%@\") so the live microphone will be used instead.", self.pathToTestFile);
            }
        }
    }
    
    if ((audioDevice = openAudioDevice("device",kSamplesPerSecond,runTest,localPathToTestFile)) == NULL) { // Open the audio device (actually the struct containing the Audio Unit).
		if(openears_logging == 1) {
            NSLog(@"openAudioDevice failed, stopping.");
        }
        [OpenEarsNotification performOpenEarsNotificationOnMainThread:@"PocketsphinxContinuousSetupDidFail" withOptionalObjects:nil andKeys:nil];
        return -1;
        
	}
    return 0;
}

- (FILE *) checkForBeginning {
    
    if(perform_request == 1) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-method-access"
        return (FILE *)[self beginning];
#pragma clang diagnostic pop        
    }
    
    return NULL;
}

#pragma mark -
#pragma mark SmartCMN Management
#pragma mark -

- (void) removeCmnPlist {
    [self.smartCMN removeCmnPlist];
}

- (void) setDecoder:(ps_decoder_t *)pocketSphinxDecoder toCmnValue:(float)previouscmn {
    if (pocketSphinxDecoder->acmod->fcb->cmn_struct) {
        
        NSString *previousCmnAsString = [[NSNumber numberWithFloat:previouscmn]stringValue];
        const char *floatAsChar = [previousCmnAsString UTF8String];
        char *c, *cc, *vallist;
        int32 nvals;
        
        vallist = ckd_salloc(floatAsChar);
        c = vallist;
        nvals = 0;
        while (nvals < pocketSphinxDecoder->acmod->fcb->cmn_struct->veclen
               && (cc = strchr(c, ',')) != NULL) {
            *cc = '\0';
            pocketSphinxDecoder->acmod->fcb->cmn_struct->cmn_mean[nvals] = FLOAT2MFCC(atof(c));
            c = cc + 1;
            ++nvals;
        }
        if (nvals < pocketSphinxDecoder->acmod->fcb->cmn_struct->veclen && *c != '\0') {
            pocketSphinxDecoder->acmod->fcb->cmn_struct->cmn_mean[nvals] = FLOAT2MFCC(atof(c));
        }
        ckd_free(vallist);
    }
}

#pragma mark -
#pragma mark Listening Loop Methods
#pragma mark -

- (void) setupCalibrationBuffer {
	
	int numberOfRounds = 25; // This is the minimum number of rounds that appear to be required to be available under normal usage;
	int numberOfSamples = kPredictedSizeOfRenderFramesPerCallbackRound; // This is the current number of samples that is called in a single callback buffer round but this could change based on hardware, etc so keep an eye on it
	int safetyMultiplier = audioDevice->bytesPerSample * 3; // this is the safety multiplier so that under normal usage we don't overrun this buffer, bps * 3 for device independence.
    
	if(audioDevice->calibrationBuffer == NULL) {
		audioDevice->calibrationBuffer = (SInt16*) malloc(audioDevice->bytesPerSample * numberOfSamples * numberOfRounds * safetyMultiplier); // this only needs to be the size of the amount of data used to calibrate, and then some		
	} else {
		audioDevice->calibrationBuffer = (SInt16*) realloc(audioDevice->calibrationBuffer, audioDevice->bytesPerSample * numberOfSamples * numberOfRounds * safetyMultiplier); // this only needs to be the size of the amount of data used to calibrate, and then some				
	}	
	audioDevice->availableSamplesDuringCalibration = 0;
	audioDevice->samplesReadDuringCalibration = 0;
	audioDevice->calibrating = TRUE;
    audioDevice->roundsOfCalibration = 0;
}

- (void) putAwayCalibrationBuffer {
	if(audioDevice->calibrationBuffer != NULL) {
		free(audioDevice->calibrationBuffer);
		audioDevice->calibrationBuffer = NULL;
	}
	audioDevice->availableSamplesDuringCalibration = 0;
	audioDevice->samplesReadDuringCalibration = 0;
    audioDevice->calibrating = FALSE;
	audioDevice->roundsOfCalibration = 0;
}

- (void) availableBuffer:(SInt16 *)buffer withLength:(int)length {
    NSData *data =[[NSData alloc] initWithBytes:buffer length:length];
    NSArray *objectsArray = [[NSArray alloc] initWithObjects:data,nil];
    NSArray *keysArray = [[NSArray alloc] initWithObjects:@"Buffer", nil];
    [OpenEarsNotification performOpenEarsNotificationOnMainThread:@"AvailableBuffer" withOptionalObjects:objectsArray andKeys:keysArray];
    [objectsArray release];
    [keysArray release];
    [data release];
}

- (NSDictionary *) setUpCommandArray:(id)commandArrayModel secondItemIsEmpty:(BOOL)secondItemIsEmpty forlanguageModel:(NSString *)languageModelPath dictionaryPath:(NSString *)dictionaryPath acousticModelPath:(NSString *)acousticModelPath isJSGF:(BOOL)isJSGF {
    
    if([[self compileKnownWordsFromFileAtPath:dictionaryPath]rangeOfString:@"___REJ_"].location != NSNotFound) {
        self.usingRejecto = TRUE;
    }

    NSArray *commandArray = [commandArrayModel commandArrayForlanguageModel:languageModelPath dictionaryPath:dictionaryPath acousticModelPath:acousticModelPath isJSGF:isJSGF];
    
    char* argv[[commandArray count]]; // We're simulating the command-line run arguments for Pocketsphinx.
    
    if(secondItemIsEmpty) {
        argv[1] = (char *)"";
    }
    
    int indexOfBestpathBool = 0;
    
    for (int i = 0; i < [commandArray count]; i++ ) { // Grab all the set arguments.
        
        char *argument = (char *) ([[commandArray objectAtIndex:i]UTF8String]);
        if([@(argument) rangeOfString:@"-bestpath"].location != NSNotFound && (self.usingRejecto == TRUE)) {
            indexOfBestpathBool = i + 1;
        }
        argv[i] = argument;
    }
    
    if(indexOfBestpathBool != 0) {
        argv[indexOfBestpathBool] = "no";
    }
    
    arg_t cont_args_def[] = { // Grab any extra arguments.
        POCKETSPHINX_OPTIONS,
        { "-argfile", ARG_STRING, NULL, "Argument file giving extra arguments." },
        CMDLN_EMPTY_OPTION
    };
    
    if ([commandArray count] < 3) { // Fail if there aren't enough arguments.
        if(openears_logging == 1) {
            NSLog(@"Initial Pocketsphinx command failed because there aren't any arguments in the command, stopping.");
        }
        [OpenEarsNotification performOpenEarsNotificationOnMainThread:@"PocketsphinxContinuousSetupDidFail" withOptionalObjects:nil andKeys:nil];
        return NULL;
    }
    return @{ 
             @"CommandArray" : commandArray,
             @"argv" : [NSData dataWithBytes:&argv length:sizeof(argv)], 
             @"cont_args_def" : [NSData dataWithBytes:&cont_args_def length:sizeof(cont_args_def)]
             };
}

- (int) recalibrate {
    
    if(audioDevice == NULL) return -1;
        
    SInt16 *recalibrationBuffer = (SInt16 *)malloc(sizeof(SInt16) * kNumberOfChunksInRingbuffer * kChunkSizeInBytes);
    
    int overallsamples = 0;
    
    int i;
    for ( i = 0; i < kNumberOfChunksInRingbuffer; i++ ) { 
        if(audioDevice->ringBuffer[i].buffer != NULL) {
            memcpy(recalibrationBuffer + overallsamples, audioDevice->ringBuffer[i].buffer, (audioDevice->ringBuffer[i].numberOfSamples * 2));
            overallsamples = overallsamples + audioDevice->ringBuffer[i].numberOfSamples;
        }
    }

    int recalibrateResults = cont_ad_calib_loop(self.continuousListener, recalibrationBuffer, overallsamples);
    
    if(recalibrateResults < 0) {
        free(recalibrationBuffer);
        if(openears_logging == 1) NSLog(@"cont_ad_calib_loop failed, stopping.");
        [OpenEarsNotification performOpenEarsNotificationOnMainThread:@"PocketsphinxContinuousSetupDidFail" withOptionalObjects:nil andKeys:nil];
        return -1;   
    }
    
    free(recalibrationBuffer);    
    
    return 0;
}

- (int) initializeVADAndStartRecordingWithOptionalCalibration:(BOOL)performCalibration withFP:(FILE *)file {
    
    self.continuousListener = NULL;
    
    if ((self.continuousListener = cont_ad_init(audioDevice, readBufferContents)) == NULL) { // Initialize the continuous recognition module.
        if(openears_logging == 1) NSLog(@"cont_ad_init failed, stopping.");
        [OpenEarsNotification performOpenEarsNotificationOnMainThread:@"PocketsphinxContinuousSetupDidFail" withOptionalObjects:nil andKeys:nil];
        return -1;
	}
   
    file = [self checkForBeginning];
    
    audioDevice->recordData = 1; // Set the device to record data rather than ignoring it (it will ignore data when PocketsphinxController receives the suspendRecognition method).
	audioDevice->recognitionIsInProgress = 1;
	
    if (startRecording(audioDevice) < 0) { // Start recording, return if failure.
        if(openears_logging == 1) NSLog(@"startRecording failed, stopping.");
        [OpenEarsNotification performOpenEarsNotificationOnMainThread:@"PocketsphinxContinuousSetupDidFail" withOptionalObjects:nil andKeys:nil];
        return -1;
	}
    
    if(performCalibration == TRUE) {
     
        [self setupCalibrationBuffer];
        
        [OpenEarsNotification performOpenEarsNotificationOnMainThread:@"PocketsphinxDidStartCalibration" withOptionalObjects:nil andKeys:nil];
        
        // Forward notification that calibration is starting to OpenEarsEventsObserver.
        if(openears_logging == 1) NSLog(@"Calibration has started");
        
        if(self.calibrationTime != 1 && self.calibrationTime != 2 && self.calibrationTime != 3) {
            self.calibrationTime = 1;
        }
        
        [NSThread sleepForTimeInterval:self.calibrationTime + 1.2]; // Getting some samples in the buffer is necessary before we start calibrating.
        
        self.continuousListener->calibration_time = self.calibrationTime;
        
        int calibrationResults = cont_ad_calib(self.continuousListener);
        
        if(calibrationResults < 0) {
            
            [self putAwayCalibrationBuffer];
            if(openears_logging == 1) NSLog(@"cont_ad_calib failed, stopping.");
            [OpenEarsNotification performOpenEarsNotificationOnMainThread:@"PocketsphinxContinuousSetupDidFail" withOptionalObjects:nil andKeys:nil];
            return -1;
        }
        
        [OpenEarsNotification performOpenEarsNotificationOnMainThread:@"PocketsphinxDidCompleteCalibration" withOptionalObjects:nil andKeys:nil];
        
        // Forward notification that calibration finished to OpenEarsEventsObserver.
        if(openears_logging == 1) NSLog(@"Calibration has completed");
        
        [self putAwayCalibrationBuffer];
        
    }
    
    [self resetFirstEntryAfterResuming];
    
    return 0;
}

- (BOOL) shouldBreakForCondition:(int)condition {

    switch (condition) {
        case kConditionExitListeningLoop:
            if(self.exitListeningLoop == 1)return TRUE;
            else return FALSE;
            break;

        case kConditionExitListeningLoopOrLanguageModelChangeRequest:
            if(self.exitListeningLoop == 1 || self.thereIsALanguageModelChangeRequest == TRUE)return TRUE;
            else return FALSE;
            break;
            
        default:
            return FALSE;
    }
    return FALSE;
}

- (void) clearBuffer:(int16 *)audioDeviceBuffer {
    //memset(audioDeviceBuffer, 0, kVadBufferSize * sizeof(int16)); // Under examination HLW
}

- (void) checkAndStopTestFile {
    if(audioDevice->takeBuffersFromTestFile == TRUE) {
        [self stopTestFile];
    }
}

- (void) performContinuousFailureStopForIssue:(NSString *)issue {
    if(openears_logging == 1) NSLog(@"%@", issue);
    [self setPocketsphinxDoneListening];
    [OpenEarsNotification performOpenEarsNotificationOnMainThread:@"PocketsphinxContinuousSetupDidFail" withOptionalObjects:nil andKeys:nil];
}

- (void) announceSpeechDetection {
    self.utteranceTimer = [NSDate timeIntervalSinceReferenceDate];
    if(openears_logging == 1) NSLog(@"Speech detected...");
    [OpenEarsNotification performOpenEarsNotificationOnMainThread:@"PocketsphinxDidDetectSpeech" withOptionalObjects:nil andKeys:nil];
}

- (int) getFirstFrameStateForBuffer:(int16 *)audioDeviceBuffer {

    if(audioDevice->recordData == 0) { // If we have looped back here in a suspended state, we exit.
       // [self clearBuffer:audioDeviceBuffer]; // Under examination HLW
        self.firstEntryIntoInnerLoopAfterResuming = 1;
        return -1;
    }
    
    if(self.firstEntryIntoInnerLoopAfterResuming == 1) {            
        self.firstEntryIntoInnerLoopAfterResuming = 0;
        return 1;
    } else {
        return 0;
    }
    return 0;
}

- (void) detectSpeechInBuffer:(SInt16 *)audioDeviceBuffer usingSpeechData:(int32 *)speechData withSleepTime:(int)sleepTime {
    for (;;) { // This has been moved into its own loop so that more selective behavior is available.
        if(audioDevice->takeBuffersFromTestFile == TRUE) { // First check to see if the test file is done, if we have one.
            [self stopTestFile];
        }
        
        if(audioDevice->recordData == 0 || audioDevice->recognitionIsInProgress == 0) { // If we have looped back here in a suspended state, we sleep and loop (or break if we need to).
          //  [self clearBuffer:audioDeviceBuffer];// If we aren't recording, erase the buffer so we never have a buffer with old data in it upon resuming. // Under examination HLW
            self.firstEntryIntoOuterLoopAfterResuming = 1; // Note that the next time this loop is entered without hitting this condition, it will be the first recognition after resuming (which is handled in a particular way to exclude bad noise values)
            if([self shouldBreakForCondition:kConditionExitListeningLoopOrLanguageModelChangeRequest]) return; // Break if we have a break condition.
            usleep(sleepTime); // Sleep if we don't have a break condition
            continue; // then continue back to the top to try again.
        }
        
        if(self.firstEntryIntoOuterLoopAfterResuming == 1) {
            self.firstEntryIntoOuterLoopAfterResuming = 0;
           // [self clearBuffer:audioDeviceBuffer]; // Under examination HLW
            if([self shouldBreakForCondition:kConditionExitListeningLoopOrLanguageModelChangeRequest]) {
                return;
            } else {
                continue; // If we have just come back from a resume, we have to wait until the subsequent frame to start cont_ad_read again.   
            }
        }
        if(audioDevice->recording == 0 || audioDevice->recognitionIsInProgress == 0) { // If we're suspended, don't call cont_ad_read
            continue;   
        }
        
        if([self shouldBreakForCondition:kConditionExitListeningLoopOrLanguageModelChangeRequest]) { // If we need to leave for some reason, return
            return;
        }
        
        // Otherwise
        
        if((*speechData = cont_ad_read(self.continuousListener, audioDeviceBuffer, kVadBufferSize)) == 0) {
            if([self shouldBreakForCondition:kConditionExitListeningLoopOrLanguageModelChangeRequest]) return;
            usleep(sleepTime);
            if([self shouldBreakForCondition:kConditionExitListeningLoopOrLanguageModelChangeRequest]) return;
            continue;
        } else {
            return;   
        }
    }
}

- (int) checkForEndOfSpeechForBuffer:(int16 *)audioDeviceBuffer andFirstFrame:(int)firstFrame withSpeechData:(int32 *)speechData andTimeStamp:(int32 *)timestamp {

    *speechData = cont_ad_read(self.continuousListener, audioDeviceBuffer, kVadBufferSize); // Read the available data.
    
    if([self shouldBreakForCondition:kConditionExitListeningLoopOrLanguageModelChangeRequest]) return 1; // Break if we have a break condition.
    
    if (*speechData < 0) { // If a negative returns, that's an error.
        [self performContinuousFailureStopForIssue:@"cont_ad_read failed, stopping."];
        return -1;
   
    } else if (*speechData == 0 || self.longRecognition == TRUE) { // No speech data, could be the end of a statement if it's been more than a second since the last received speech. Mostly we will hit this because of silence detected, but every once in a while there can be a randomly bad value in the VAD due to a weird audio event and we will get here via a poor recognition round being caught and exited early. In that rare case, the next thing that happens in a continuousListener reset so it will not carry through the rest of the session.
                
        float utteranceTime = [NSDate timeIntervalSinceReferenceDate]-self.utteranceTimer;

        if (((self.continuousListener->read_ts - *timestamp) > (kSamplesPerSecond * self.secondsOfSilenceToDetect)) || (self.longRecognition == TRUE && (utteranceTime > kExcessiveUtterancePeriod))) { // We will recalibrate if we got the flag AND if it is an objectively long utterance.
            if(self.longRecognition == TRUE && (utteranceTime > kExcessiveUtterancePeriod)) { // If we're here due to a long recognition we need to recalibrate as quickly as possible.
                
                if(openears_logging == 1) NSLog(@"There is reason to suspect the VAD of being out of sync with the current background noise levels in the environment so we will recalibrate.");
                
                if([self recalibrate] < 0) { // Return error if our recalibration didn't work out.
                    [self performContinuousFailureStopForIssue:@"cont_ad_read failed, stopping."];
                    return -1;
                }
            }
            [OpenEarsNotification performOpenEarsNotificationOnMainThread:@"PocketsphinxDidDetectFinishedSpeech" withOptionalObjects:nil andKeys:nil];
            self.longRecognition = FALSE;
            return 1;
        } else {
            return 0;  
        } 
        
        return 0;        
        
    } else { // New speech data.
        
        *timestamp = self.continuousListener->read_ts;
        return 0;
    }
    return 0;
}

- (int) stopRecordingAndResetWithBuffer:(int16 *)audioDeviceBuffer {
    
    if([self shouldBreakForCondition:kConditionExitListeningLoop]) {
        return -1; // Break immediately if we have a break condition.
    }
    
    audioDevice->endingLoop = TRUE;
    int i;
    for ( i = 0; i < 10; i++ ) {
        readBufferContents(audioDevice, audioDeviceBuffer, kVadBufferSize); // Make several attempts to read anything remaining in the buffer.
    }
    
    stopRecording(audioDevice); // Stop recording.
    audioDevice->endingLoop = FALSE;
    
    cont_ad_reset(self.continuousListener); // Reset the continuous module.
    
    if([self shouldBreakForCondition:kConditionExitListeningLoop]) {
        return -1; // Break if we have a break condition.
    } else {
        if(openears_logging == 1) NSLog(@"Processing speech, please wait...");
        return 0;
    }
    return 0;
}

- (void) getAndReturnHypothesisForDecoder:(ps_decoder_t *)pocketSphinxDecoder {
    
    int32 recognitionScore;
    char const *hypothesis;
    char const *utteranceID;
    
    hypothesis = ps_get_hyp(pocketSphinxDecoder, &recognitionScore, &utteranceID); // Return the hypothesis.
    int32 probability = ps_get_prob(pocketSphinxDecoder, &utteranceID);
    
    if(hypothesis == NULL) { // We don't pass a truly null hyp through here because we can't use it to initialize an NSString from a UTF8 string. If we have received a null hyp we convert it to a zero-length string.
        hypothesis = "";
    }
    
    NSString *hypothesisString = nil;
    
    if(returner == 0) {
        
        NSMutableString *builtUpHypString = [[NSMutableString alloc] init];
        
        NSArray *array = [[NSString stringWithFormat:@"%s",hypothesis] componentsSeparatedByString:@" "];
        
        for(NSString *string in array) {
            if([string rangeOfString:@"___"].location == NSNotFound) {
                [builtUpHypString appendString:[NSString stringWithFormat:@"%@ ",string]];
            }
        }
        
        if([builtUpHypString length] >= 1) {
            
            NSString *finalString = [builtUpHypString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            if([finalString length] > 0) {
                hypothesisString = [[NSString alloc] initWithString:finalString];
                
            } else {
                hypothesisString = [[NSString alloc] initWithString:@" "];  
            }
            
        } else {
            hypothesisString = [[NSString alloc] initWithString:@" "]; 
        }
        [builtUpHypString release];
        
    } else {
        hypothesisString = [[NSString alloc] initWithUTF8String:hypothesis];
    }
    
    NSString *detokenizedHypothesisString = [hypothesisString stringByReplacingOccurrencesOfString:@"#^#" withString:@" "];
    if(openears_logging == 1) NSLog(@"Pocketsphinx heard \"%@\" with a score of (%d) and an utterance ID of %s.", detokenizedHypothesisString, probability, utteranceID);
    
    NSString *probabilityString = [[NSString alloc] initWithFormat:@"%d",probability];
    NSString *uttidString = [[NSString alloc] initWithFormat:@"%s",utteranceID];
    NSArray *hypothesisObjectsArray = [[NSArray alloc] initWithObjects:detokenizedHypothesisString,probabilityString,uttidString,nil];
    NSArray *hypothesisKeysArray = [[NSArray alloc] initWithObjects:@"Hypothesis",@"RecognitionScore",@"UtteranceID",nil];
    
    if(self.returnNullHypotheses == TRUE) { // We have been asked to return all null hyps
        [OpenEarsNotification performOpenEarsNotificationOnMainThread:@"PocketsphinxDidReceiveHypothesis" withOptionalObjects:hypothesisObjectsArray andKeys:hypothesisKeysArray]; 

    } else if(([detokenizedHypothesisString length] > 0) && ([detokenizedHypothesisString isEqualToString:@" "] == FALSE)) { // We haven't been asked to return all null hyps but this hyp isn't null
        
        [OpenEarsNotification performOpenEarsNotificationOnMainThread:@"PocketsphinxDidReceiveHypothesis" withOptionalObjects:hypothesisObjectsArray andKeys:hypothesisKeysArray]; 
        
    } else {
        if(openears_logging == 1) NSLog(@"Hypothesis was null so we aren't returning it. If you want null hypotheses to also be returned, set PocketsphinxController's property returnNullHypotheses to TRUE before starting PocketsphinxController."); // Hyp is null, don't return.
    }
    
    [hypothesisObjectsArray release];
    [hypothesisKeysArray release];
    [hypothesisString release];
    [probabilityString release];
    [uttidString release];
    
    if(self.returnNbest == TRUE) { // Let's get n-best if needed
        [self getNbestForDecoder:pocketSphinxDecoder withHypothesis:hypothesis andRecognitionScore:recognitionScore];
    }

}

- (void) endUtteranceAndReturnHypothesisForDecoder:(ps_decoder_t *)pocketSphinxDecoder andBuffer:(int16 *)audioDeviceBuffer {
        
    ps_end_utt(pocketSphinxDecoder); // The utterance is ended
    
    if(audioDevice->recordData == 1) { // If we are suspended we don't want to get a hypothesis, just to return to the top of the loop ASAP.
        
        [self getAndReturnHypothesisForDecoder:pocketSphinxDecoder];
        
      //  [self clearBuffer:audioDeviceBuffer]; // Under examination HLW
    }
}

- (void) getNbestForDecoder:(ps_decoder_t *)pocketSphinxDecoder withHypothesis:(char const *)hypothesis andRecognitionScore:(int32)recognitionScore {
    
    NSMutableArray *nbestMutableArray = [[NSMutableArray alloc] init];
    
    ps_nbest_t *nbest = ps_nbest(pocketSphinxDecoder, 0, -1, NULL, NULL);
    
    ps_nbest_t *next = NULL;
    
    for (int i=0; i < self.nBestNumber; i++) {
        next = ps_nbest_next(nbest);
        if (next) {
            
            hypothesis = ps_nbest_hyp(nbest, &recognitionScore);
            //                fprintf(fh, "%s %dn", hypothesis, recognitionScore);
            if(hypothesis == NULL) {
                hypothesis = "";
            }
            
            NSString *hypothesisString = [[NSString alloc] initWithUTF8String:hypothesis];
            
            NSString *detokenizedHypothesisString = [hypothesisString stringByReplacingOccurrencesOfString:@"#^#" withString:@" "];
            [nbestMutableArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:detokenizedHypothesisString,[NSNumber numberWithInt:recognitionScore],nil] forKeys:[NSArray arrayWithObjects:@"Hypothesis",@"Score",nil]]];
            
            //                
            //                for (seg = ps_nbest_seg(nbest, &recognitionScore); seg; seg = ps_seg_next(seg)) { // Probably not needed by most developers.
            //
            //                    char const *word;
            //                    int sf, ef;
            //
            //                    word = ps_seg_word(seg);
            //                    ps_seg_frames(seg, &sf, &ef);
            //                    printf("%s %d %d\n", word, sf, ef);
            //                }
            
            [hypothesisString release];
            
        } else {
            
            break;
        }
    }
    
    if (next) {
        ps_nbest_free(nbest);
    }
    NSArray *nBesthypothesisObjectsArray = [[NSArray alloc] initWithObjects:nbestMutableArray,nil];
    NSArray *nBesthypothesisKeysArray = [[NSArray alloc] initWithObjects:@"NbestHypothesisArray",nil];
    
    [OpenEarsNotification performOpenEarsNotificationOnMainThread:@"PocketsphinxDidReceiveNbestHypothesisArray" withOptionalObjects:(NSArray *)nBesthypothesisObjectsArray andKeys:(NSArray *)nBesthypothesisKeysArray];
    
    [nBesthypothesisObjectsArray release];
    [nBesthypothesisKeysArray release];
    
    [nbestMutableArray release];
}

- (void)checkForEndingWithFile:(FILE *)file {
    if(perform_request == 1) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-method-access"
        [self ending:file]; 
#pragma clang diagnostic pop        
    }
}

- (ps_decoder_t *) initializeDecoder:(ps_decoder_t *)pocketSphinxDecoder forLanguageModelAtPath:(NSString *)languageModelPath dictionaryAtPath:(NSString *)dictionaryPath acousticModelAtPath:(NSString *)acousticModelPath languageModelIsJSGF:(BOOL)languageModelIsJSGF {
    
    if(self.processSpeechLocally) {
        [self checkWhetherJSGFSettingOf:languageModelIsJSGF LooksCorrectForThisFilename:languageModelPath];
    }
    
    FILE *err_set_logfp(FILE *logfp); // This function will allow us to make Pocketsphinx run quietly.

    if(verbose_pocketsphinx == 0) {
        err_set_logfp(NULL); // If verbose_pocketsphinx isn't defined, this will quiet the output from Pocketsphinx.
    }
    
    CommandArray *commandArrayModel = [[[CommandArray alloc] init] autorelease];
    
    NSDictionary *commandDictionary = [self setUpCommandArray:commandArrayModel secondItemIsEmpty:FALSE forlanguageModel:languageModelPath dictionaryPath:dictionaryPath acousticModelPath:acousticModelPath isJSGF:languageModelIsJSGF];
    
    if(commandDictionary == NULL) {
        if(openears_logging == 1) NSLog(@"Something was wrong with the commands for this PocketsphinxController session, returning.");
        return NULL;
    }
    // Since we got this far, set the PocketsphinxController run configuration to the selected arguments and values.
    cmd_ln_t *configuration = cmd_ln_parse_r(NULL, [commandDictionary[@"cont_args_def"]bytes], [commandDictionary[@"CommandArray"] count], (char **)[commandDictionary[@"argv"]bytes], FALSE);
    
    pocketSphinxDecoder = ps_init(configuration); // Initialize the decoder.
    
    cmd_ln_free_r(configuration); // Free the configuration
    
    return pocketSphinxDecoder;
}

- (void) announceLoopHasStartedWithDictionaryAtPath:(NSString *)dictionaryPath {
    if(openears_logging == 1 && self.processSpeechLocally) NSLog(@"Project has these words or phrases in its dictionary:\n%@", [self compileKnownWordsFromFileAtPath:dictionaryPath]);
    [OpenEarsNotification performOpenEarsNotificationOnMainThread:@"PocketsphinxRecognitionLoopDidStart" withOptionalObjects:nil andKeys:nil];
	if(openears_logging == 1) NSLog(@"Recognition loop has started");
}

- (void) announceLoopHasEnded {
    if(openears_logging == 1) NSLog(@"No longer listening.");	
    [OpenEarsNotification performOpenEarsNotificationOnMainThread:@"PocketsphinxDidStopListening" withOptionalObjects:nil andKeys:nil];
}

- (void) announceListening {
    if(openears_logging == 1) NSLog(@"Listening.");
    [OpenEarsNotification performOpenEarsNotificationOnMainThread:@"PocketsphinxDidStartListening" withOptionalObjects:nil andKeys:nil];
}

- (void) shutDownDeviceAndVAD {
    stopRecording(audioDevice); // Stop recording if necessary.
    cont_ad_close(self.continuousListener); // Close the continuous module.    
    closeAudioDevice(audioDevice); // Close the device, i.e. stop and dispose of the Audio Unit.
}

- (BOOL) shouldUseSmartCMN {
    
    if(self.pathToTestFile == NULL || (self.pathToTestFile != NULL && self.useSmartCMNWithTestFiles == TRUE))   {
        return TRUE;
    } else {
        return FALSE;
    }
    return TRUE;
}
     
- (void) resetFirstEntryAfterResuming {
    self.firstEntryIntoOuterLoopAfterResuming = 0;
    self.firstEntryIntoInnerLoopAfterResuming = 0;
}

- (int) restartRecordingAfterRecognition {
    if (startRecording(audioDevice) < 0) { // Start over, return if start fails.
        [self performContinuousFailureStopForIssue:@"startRecording failed, stopping."];
        return -1;
    }
    return 0;
}

- (void) setPocketsphinxListening {
    
    self.listeningStarts++;
    
    if ([delegate respondsToSelector:@selector(listeningLoopHasStarted)]) {
        [delegate listeningLoopHasStarted];
    }
}

- (void) setPocketsphinxDoneListening {
    if ([delegate respondsToSelector:@selector(listeningLoopHasEnded)]) {
        [delegate listeningLoopHasEnded];
    }
}

- (void) shutDownLoop:(FILE *)file {
    self.inMainRecognitionLoop = FALSE; // We broke out of the loop.
	self.exitListeningLoop = 0; // We don't want to prompt further exiting attempts since we're out.
    [self shutDownDeviceAndVAD];
    [self checkForEndingWithFile:file];
}

#pragma mark -
#pragma mark Listening Loop
#pragma mark -

- (void) listeningLoopWithLanguageModelAtPath:(NSString *)languageModelPath dictionaryAtPath:(NSString *)dictionaryPath acousticModelAtPath:(NSString *)acousticModelPath languageModelIsJSGF:(BOOL)languageModelIsJSGF { // The big recognition loop.

    [self setPocketsphinxListening];
    ps_decoder_t *pocketSphinxDecoder = NULL; // The Pocketsphinx decoder which will perform the actual speech recognition on recorded speech.	
	int16 audioDeviceBuffer[kVadBufferSize]; // The following are all used by Pocketsphinx.
    int32 timestamp = 0, speechData = 0, remainingSpeechData = 0;
	
    [self announceLoopHasStartedWithDictionaryAtPath:dictionaryPath];
    
    if(self.processSpeechLocally) {
        if((pocketSphinxDecoder = [self initializeDecoder:pocketSphinxDecoder forLanguageModelAtPath:languageModelPath dictionaryAtPath:dictionaryPath acousticModelAtPath:acousticModelPath languageModelIsJSGF:languageModelIsJSGF]) == NULL) {
            return; // Initialize the decoder and if it returns null, return.
        }
    }

    if([self prepareTestAndOpenAudioDevice] == -1) {
        return; // Prepare test and open the audio device, return if it fails
    }
	if([self shouldUseSmartCMN] == TRUE) { // If we're testing we don't use SmartCMN unless specifically asked to.
        [self setDecoder:pocketSphinxDecoder toCmnValue:[self.smartCMN smartCmnValuesForRoute:[self getCurrentRoute] forAcousticModelAtPath:acousticModelPath withModelName:NSStringFromClass([self class])]]; // If we have previous cmn init values for this app, device, route and acoustic model, let's use them since they generally have to be more accurate than a naive init value
    }  
    FILE *file = NULL;
    if([self initializeVADAndStartRecordingWithOptionalCalibration:TRUE withFP:file] == -1) {
        return; // Initialize continuous listener, start recording and calibrate, and return if it fails
    }
    
    int sleepTime = 30000;
    
    for (;;) { // This is the main loop.
        
        [self checkAndStopTestFile];
		self.inMainRecognitionLoop = TRUE; // Note that we're in the main loop.
        if([self shouldBreakForCondition:kConditionExitListeningLoop]) break; // Break if we're trying to exit the loop. After here we're now listening for speech.
        
        if(audioDevice->recordData == 1) { // We only do this notification if we didn't end up here due to a suspension.
            if(self.thereIsALanguageModelChangeRequest == TRUE && self.processSpeechLocally == TRUE) [self changeLanguageModelForDecoder:pocketSphinxDecoder languageModelIsJSGF:languageModelIsJSGF]; // Change model.
            [self announceListening];
        } //else { // If we are suspended here, zero out the buffer.
            //[self clearBuffer:audioDeviceBuffer]; // Under examination HLW
        //}
 
        [self detectSpeechInBuffer:audioDeviceBuffer usingSpeechData:&speechData withSleepTime:sleepTime]; // Check for speech

        if([self shouldBreakForCondition:kConditionExitListeningLoop]) break; // If we returned from the speech-check method due to a need to break out, do so.

        if(self.thereIsALanguageModelChangeRequest == TRUE) { // If we returned from the speech-check method because we need to change models, continue back to the top of the loop so we can do that.
            continue;
        }
        
        if(speechData < 0) { // Otherwise if we get here, speech was found or the VAD returned an error so we'll set speechData to the results and also check for a VAD error
            [self performContinuousFailureStopForIssue:@"cont_ad_read failed, stopping."];
            return;
        }
        
        [self announceSpeechDetection]; // We have speech if we get here.
        
        if(self.processSpeechLocally) {
            if (ps_start_utt(pocketSphinxDecoder, NULL) < 0) { // Data has been received and recognition is starting as we mark the beginning of the utterance, or if less than zero was returned an error was encountered and we need to stop.
                [self performContinuousFailureStopForIssue:@"ps_start_utt() failed, stopping."];
                return;
            }
            ps_process_raw(pocketSphinxDecoder, audioDeviceBuffer, speechData, kno_search_false, kfull_utt_process_raw_false); // Process the data.
        }
                
        if(self.outputAudio == TRUE && speechData > 0) [self availableBuffer:audioDeviceBuffer withLength:speechData * 2];
		
		timestamp = self.continuousListener->read_ts;
		
		if([self shouldBreakForCondition:kConditionExitListeningLoop]) break; // Break if we have a break condition.
		
        for (;;) { // An inner loop in which the received speech will be decoded up to the point of a silence longer than a second.
            
            if([self shouldBreakForCondition:kConditionExitListeningLoopOrLanguageModelChangeRequest]) break; // Break if we have a break condition.
            
            int firstFrame = [self getFirstFrameStateForBuffer:audioDeviceBuffer];
            if(firstFrame == -1) break; // If this comes back -1 that means there was a break request, otherwise the result will be 0 if it isn't the first frame and 1 if it is.
            
            int checkForEndOfSpeechResult = [self checkForEndOfSpeechForBuffer:audioDeviceBuffer andFirstFrame:firstFrame withSpeechData:&speechData andTimeStamp:&timestamp];
            
            if(checkForEndOfSpeechResult == -1) { // Error state, returning.
                return;
            } else if (checkForEndOfSpeechResult == 1 || [self shouldBreakForCondition:kConditionExitListeningLoopOrLanguageModelChangeRequest]) { // End utterance and break, there was enough silence to call the utterance complete.
                break;
            } // Otherwise keep going
                        
            if(self.processSpeechLocally) remainingSpeechData = ps_process_raw(pocketSphinxDecoder, audioDeviceBuffer, speechData, kno_search_false, kfull_utt_process_raw_false); // Decode the remaining data.
            if(self.outputAudio == TRUE && speechData > 0) [self availableBuffer:audioDeviceBuffer withLength:speechData * 2];
            
            if ((remainingSpeechData == 0) && (speechData == 0)) { // If nothing more to be done for now, sleep.
				usleep(5000);
				if([self shouldBreakForCondition:kConditionExitListeningLoopOrLanguageModelChangeRequest]) break; // Break if we have a break condition.
			}
        }
		        
        if([self stopRecordingAndResetWithBuffer:audioDeviceBuffer] == -1) break; // Break if there is an early break condition, or stop the device and break if there is a later break condition, otherwise keep going.
        if(self.processSpeechLocally) [self endUtteranceAndReturnHypothesisForDecoder:pocketSphinxDecoder andBuffer:audioDeviceBuffer]; // End utterance and decode/announce hypothesis

        if([self shouldBreakForCondition:kConditionExitListeningLoop]) break; // Break if we have a break condition.
        if([self restartRecordingAfterRecognition] < 0) {
            return; // Start over, return if start fails. Further break testing not necessary since we'll check at the top of the loop.
        }
    }
    
    if([self shouldUseSmartCMN] == TRUE && pocketSphinxDecoder != NULL) { // We don't do smart cmn when testing unless specifically asked to.
        [self.smartCMN finalizeCmn:MFCC2FLOAT(pocketSphinxDecoder->acmod->fcb->cmn_struct->cmn_mean[0]) atRoute:[self getCurrentRoute] forAcousticModelAtPath:acousticModelPath withModelName:NSStringFromClass([self class])]; // If we have a cmn value here at the end, it is always going to be a better value for this particular device, user and route than the naive init value, so we will save it for the next session run with this route and acoustic model and use it as the init value
    }
    [self shutDownLoop:file];
    if(self.processSpeechLocally) ps_free(pocketSphinxDecoder); // Free the decoder.
    [self announceLoopHasEnded];
    [self setPocketsphinxDoneListening];
}

#pragma mark -
#pragma mark Perform Recognition On WAV
#pragma mark -

- (void) runRecognitionOnWavFileAtPath:(NSString *)wavPath usingLanguageModelAtPath:(NSString *)languageModelPath dictionaryAtPath:(NSString *)dictionaryPath acousticModelAtPath:(NSString *)acousticModelPath languageModelIsJSGF:(BOOL)languageModelIsJSGF { // Listen to a single recording which already exists.
    
    ps_decoder_t *pocketSphinxDecoder = NULL; // The Pocketsphinx decoder which will perform the actual speech recognition on recorded speech.

    if((pocketSphinxDecoder = [self initializeDecoder:pocketSphinxDecoder forLanguageModelAtPath:languageModelPath dictionaryAtPath:dictionaryPath acousticModelAtPath:acousticModelPath languageModelIsJSGF:languageModelIsJSGF]) == NULL) return; // Init and return if null.
	
    ps_start_utt(pocketSphinxDecoder, NULL); // Start the utterance.
        
    NSData *wavData = [NSData dataWithContentsOfFile:wavPath]; // WAV to data, we'll process it below without its header.

    ps_process_raw(pocketSphinxDecoder, (SInt16 *)[[wavData subdataWithRange:NSMakeRange(44, ([wavData length] - 44))] bytes], ([wavData length]-44)/2, kno_search_false, kfull_utt_process_raw_false); // Process the data.
    
    ps_end_utt(pocketSphinxDecoder); // Stop the utterance.
    
    [self getAndReturnHypothesisForDecoder:pocketSphinxDecoder]; // Get the hypothesis
 
    ps_free(pocketSphinxDecoder); // Free the decoder.
}

#pragma mark -
#pragma mark VAD Logging
#pragma mark -

- (void) setContinuousListenerLogFPToNull {
    if(self.continuousListener!=NULL) {
        self.continuousListener->logfp = NULL;   
    }
}

- (void) setContinuousListenerLogFPToStdOut {
    if(self.continuousListener!=NULL) {
        self.continuousListener->logfp = stdout;   
    }
}

#pragma mark -
#pragma mark ContinuousModel Delegate Methods
#pragma mark -

- (void) listeningLoopHasEnded {}
- (void) listeningLoopHasStarted {}

@end
