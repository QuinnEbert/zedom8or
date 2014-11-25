//  OpenEars 
//  http://www.politepix.com/openears
//
//  LanguageModelGenerator.m
//  OpenEars
//
//  LanguageModelGenerator is a class which creates new grammars
//
//  Copyright Politepix UG (haftungsbeschränkt) 2012. All rights reserved.
//  http://www.politepix.com
//  Contact at http://www.politepix.com/contact
//
//  this file is licensed under the Politepix Shared Source license found 
//  found in the root of the source distribution. Please see the file "Version.txt" in the root of 
//  the source distribution for the version number of this OpenEars package.


#import "LanguageModelGenerator.h"
#import "GrammarGenerator.h"
#import "GraphemeGenerator.h"
#import "CMUCLMTKModel.h"

#import "RuntimeVerbosity.h"
#import "AcousticModel.h"
/**\cond HIDDEN_SYMBOLS*/ 
#import "SScribe.h"
/**\endcond*/
@implementation LanguageModelGenerator

@synthesize verboseLanguageModelGenerator;

@synthesize pathToCachesDirectory;
@synthesize graphemeGenerator;
@synthesize useFallbackMethod;

@synthesize sanitizeDictionaryCharacterSet;
@synthesize ngrams;
@synthesize iterationStorageArray;

extern int verbose_cmuclmtk;

extern int openears_logging;

- (NSMutableArray *)iterationStorageArray {
    if (iterationStorageArray == nil) {
        iterationStorageArray = [[NSMutableArray alloc] init];
    }
    return iterationStorageArray;
};


- (void)dealloc {
    [iterationStorageArray release];
    [pathToCachesDirectory release];
    
    [graphemeGenerator release];
    
    [sanitizeDictionaryCharacterSet release];
    [ngrams release];
    [super dealloc];
}

- (id) init {
    if (self = [super init]) {
        useFallbackMethod = TRUE;
        
    }
    return self;
}

- (NSMutableCharacterSet *)sanitizeDictionaryCharacterSet {
    if (sanitizeDictionaryCharacterSet == nil) {
        sanitizeDictionaryCharacterSet = [[NSMutableCharacterSet alloc] init];
        
        NSMutableCharacterSet *alphanumericPlusApostropheMutableCharacterSet = [[NSMutableCharacterSet alloc] init];
        [alphanumericPlusApostropheMutableCharacterSet formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
        [alphanumericPlusApostropheMutableCharacterSet addCharactersInString:@"\'"];

        [sanitizeDictionaryCharacterSet formUnionWithCharacterSet:[alphanumericPlusApostropheMutableCharacterSet invertedSet]];
        [alphanumericPlusApostropheMutableCharacterSet release];        
        
    }
    return sanitizeDictionaryCharacterSet;
};


- (NSString *)pathToCachesDirectory {
    if (pathToCachesDirectory == nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES); 
        NSString *cachesDirectory = [NSString stringWithFormat:@"%@/",[paths objectAtIndex:0]]; // Get caches directory
        pathToCachesDirectory = [[NSString alloc] initWithString:cachesDirectory];
    }
    return pathToCachesDirectory;
};

- (GraphemeGenerator *)graphemeGenerator {
    if (graphemeGenerator == nil) {
        graphemeGenerator = [[GraphemeGenerator alloc] init];
    }
    return graphemeGenerator;
};

- (NSArray *) compactWhitespaceOfArrayEntries:(NSArray *)array { // Removes all whitespace from an entry other than a single space between words. This prevents any of the subsequent components from being overly-sensitive to spaces.
 
    NSMutableArray *mutableNormalizedArray = [[NSMutableArray alloc] init];
    
    NSCharacterSet *whiteSpaceSet = [NSCharacterSet whitespaceCharacterSet];
    NSPredicate *rejectEmptyStringPredicate = [NSPredicate predicateWithFormat:@"SELF != ''"];
    
    for (NSString *string in array) {
        
        NSArray *stringComponents = [string componentsSeparatedByCharactersInSet:whiteSpaceSet];
        NSArray *cleanedComponents = [stringComponents filteredArrayUsingPredicate:rejectEmptyStringPredicate];
        NSString *reassembledString = [cleanedComponents componentsJoinedByString:@" "];
        if([reassembledString length]>0 && [reassembledString isEqualToString:@""]==FALSE) {
            [mutableNormalizedArray addObject:reassembledString];
        }
    }
    
    NSArray *normalizedArray = [[[NSArray alloc] initWithArray:(NSArray *)mutableNormalizedArray]autorelease];
    
    [mutableNormalizedArray release];
        
    return normalizedArray;
}


- (NSArray *) performDictionaryLookup:(NSArray *)array inString:(NSString *)data forAcousticModelAtPath:(NSString *)acousticModelPath {
    
    NSMutableArray *mutableArrayOfWordsToMatch = [[NSMutableArray alloc] initWithArray:array];
    
    NSUInteger pos = 0;
    
    NSMutableArray * matches = [NSMutableArray array];
    
    while (pos != data.length) {
        
        if([mutableArrayOfWordsToMatch count] <= 0) { // If we're at the top of the loop without any more words, stop.
            break;
        }  
        
        NSRange remaining = NSMakeRange(pos, data.length-pos);
        NSRange next = [data
                        rangeOfString:[NSString stringWithFormat:@"\n%@\t",[mutableArrayOfWordsToMatch objectAtIndex:0]]
                        options:NSLiteralSearch
                        range:remaining
                        ]; // Just search for the first pronunciation.
        if (next.location != NSNotFound) {
            NSRange lineRange = [data lineRangeForRange:NSMakeRange(next.location+1, next.length)];
            [matches addObject:[data substringWithRange:NSMakeRange(lineRange.location, lineRange.length-1)]]; // Grab the whole line of the hit.
            NSInteger rangeLocation = next.location;
            NSInteger rangeLength = 750;
            
            if(data.length - next.location < rangeLength) { // Only use the searchPadding if there is that much room left in the string.
                rangeLength = data.length - next.location;
            } 
            rangeLength = rangeLength/5;
            NSInteger newlocation = rangeLocation;

            for(int i = 2;i < 6; i++) { // We really only need to do this from 2-5.
                NSRange morematches = [data
                                rangeOfString:[NSString stringWithFormat:@"\n%@(%d",[mutableArrayOfWordsToMatch objectAtIndex:0],i]
                                options:NSLiteralSearch
                                range:NSMakeRange(newlocation, rangeLength)
                                ];
                if(morematches.location != NSNotFound) {
                    NSRange moreMatchesLineRange = [data lineRangeForRange:NSMakeRange(morematches.location+1, morematches.length)]; // Plus one because I don't actually want the line break at the beginning.
                     [matches addObject:[data substringWithRange:NSMakeRange(moreMatchesLineRange.location, moreMatchesLineRange.length-1)]]; // Minus one because I don't actually want the line break at the end.
                    newlocation = morematches.location;

                } else {
                    break;   
                }
            }
 
            next.length = next.location - pos;
            next.location = pos;
            [mutableArrayOfWordsToMatch removeObjectAtIndex:0]; // Remove the word.
            pos += (next.length+1);
        } else { // No hits.

            NSString *unmatchedWord = [mutableArrayOfWordsToMatch objectAtIndex:0];
            
            if(openears_logging == 1) NSLog(@"The word %@ was not found in the dictionary %@/LanguageModelGeneratorLookupList.text.",unmatchedWord,acousticModelPath);
            //LanguageModelGeneratorLookupList.text
            if(self.useFallbackMethod == TRUE) { // If the user hasn't overriden the use of the fall back method
                
                
      
                
                if(openears_logging == 1)NSLog(@"Now using the fallback method to look up the word %@",unmatchedWord);
                  NSString *formattedString = nil;
                if([acousticModelPath rangeOfString:@"AcousticModelEnglish"].location != NSNotFound) { // if they are using the english or spanish dictionary 
                    if(openears_logging == 1)NSLog(@"If this is happening more frequently than you would expect, the most likely cause for it is since you are using the English phonetic lookup dictionary is that your words are not in English or aren't dictionary words, or that you are submitting the words in lowercase when they need to be entirely written in uppercase.");
                    
                    NSString *graphemes = [self.graphemeGenerator convertGraphemes:unmatchedWord];
                    NSString *correctedString = [[graphemes stringByReplacingOccurrencesOfString:@"ax" withString:@"ah"]stringByReplacingOccurrencesOfString:@"pau " withString:@""];
                   
                    NSString *uppercasedCorrectedString = [correctedString uppercaseString];
                    formattedString = [NSString stringWithFormat:@"%@\t%@",unmatchedWord,uppercasedCorrectedString]; // output needs to be capitalized if this is for the default phonetic dictionary.

                } else if ([acousticModelPath rangeOfString:@"AcousticModelSpanish"].location != NSNotFound) {
                
                    if(openears_logging == 1)NSLog(@"If this is happening more frequently than you would expect, the most likely cause for it is since you are using the Spanish phonetic lookup dictionary is that your words are not in Spanish or aren't dictionary words, or that you are submitting the words in lowercase when they need to be entirely written in uppercase.");
                    
                    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:unmatchedWord];
                    /**\cond HIDDEN_SYMBOLS*/
                    SScribe *_scribe = [[SScribe alloc] initWithGrammar:nil forText:attributedString sender:self];

                    /**\endcond */
                    
                    NSString *graphemes = [[_scribe renderedText]string];
                    NSCharacterSet *whitespaces = [NSCharacterSet whitespaceCharacterSet];
                    NSPredicate *noEmptyStrings = [NSPredicate predicateWithFormat:@"SELF != ''"];
                    
                    NSArray *parts = [graphemes componentsSeparatedByCharactersInSet:whitespaces];
                    NSArray *filteredArray = [parts filteredArrayUsingPredicate:noEmptyStrings];
                    graphemes = [filteredArray componentsJoinedByString:@" "];
                    graphemes = [graphemes stringByTrimmingCharactersInSet:
                                               [NSCharacterSet whitespaceAndNewlineCharacterSet]];

                 
                    NSString *uppercasedCorrectedString = [graphemes uppercaseString];
                    formattedString = [NSString stringWithFormat:@"%@\t%@",unmatchedWord,uppercasedCorrectedString]; // output needs to be capitalized if this is for the default phonetic dictionary.
                    [_scribe release];
                    [attributedString release];
                
                } else { // if they aren't using the english phonetic dictionary
                    if(openears_logging == 1)NSLog(@"If this is happening more frequently than you would expect, the most likely cause for it is since you are not using the English or Spanish phonetic lookup dictionary is that there is an issue with the phonetic dictionary you are using (for instance, it is not in alphabetical order or it doesn't use the correct formatting) or that the case of the words you are submitting to this method are not the same case as the words in your dictionary. For instance, you are submitting uppercase words or words which begin with a capital letter but your phonetic dictionary has all of its words in lowercase.");
                    NSString *graphemes = [self.graphemeGenerator convertGraphemes:unmatchedWord];
                    NSString *correctedString = [[graphemes stringByReplacingOccurrencesOfString:@"ax" withString:@"ah"]stringByReplacingOccurrencesOfString:@"pau " withString:@""];
                  
                   formattedString = [NSString stringWithFormat:@"%@\t%@",unmatchedWord,correctedString];  // Don't capitalize if not using english dictionary.
                }
                
                NSString *finalizedString = [formattedString stringByReplacingOccurrencesOfString:@" \n" withString:@"\n"];                     

                [matches addObject:finalizedString];
                
            } else {
                
                if(openears_logging == 1)NSLog(@"Since the fallback method has been turned off and the word wasn't found in the phonetic dictionary, we are dropping the word %@ from the dynamically-created phonetic dictionary.",unmatchedWord);
                
                if([acousticModelPath rangeOfString:@"AcousticModelEnglish"].location != NSNotFound || [acousticModelPath rangeOfString:@"AcousticModelSpanish"].location != NSNotFound) { // if they are using the english or spanish phonetic dictionary
                    if(openears_logging == 1)NSLog(@"If this is happening more frequently than you would expect, the most likely cause for it is since you are using the English or the Spanish phonetic lookup dictionary is that your words are not in English/Spanish or aren't dictionary words, or that you are submitting the words in lowercase when they need to be entirely written in uppercase.");
                } else { // if they aren't using the english phonetic dictionary
                    if(openears_logging == 1)NSLog(@"If this is happening more frequently than you would expect, the most likely cause for it is since you are not using the English or the Spanish phonetic lookup dictionary is that there is an issue with the phonetic dictionary you are using (for instance, it is not in alphabetical order or it doesn't use the correct formatting) or that the case of the words you are submitting to this method are not the same case as the words in your dictionary. For instance, you are submitting uppercase words or words which begin with a capital letter but your phonetic dictionary has all of its words in lowercase.");
                }
            }
            
            [mutableArrayOfWordsToMatch removeObjectAtIndex:0]; // Remove from the word list.
        }
    }    
    
    [mutableArrayOfWordsToMatch release];
    return matches;
}
 
- (void) createLanguageModelFromFilename:(NSString *)fileName {
    if(openears_logging == 1) NSLog(@"Starting dynamic language model generation"); 
    
    NSTimeInterval start = 0.0;
    
    if(openears_logging == 1) {
        start = [NSDate timeIntervalSinceReferenceDate]; // If logging is on, let's time the language model processing time so the developer can profile it.
    }
    
    CMUCLMTKModel *cmuCLMTKModel = [[CMUCLMTKModel alloc]init]; // First, use the CMUCLMTK port to create a language model
    // -linear | -absolute | -good_turing | -witten_bell
    cmuCLMTKModel.algorithmType = @"-witten_bell";
    
    if(self.ngrams != nil) {
        cmuCLMTKModel.ngrams = self.ngrams;
    }
    
	[cmuCLMTKModel runCMUCLMTKOnCorpusFile:[self.pathToCachesDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.corpus",fileName]] withDMP:TRUE];
	[cmuCLMTKModel release];
    self.ngrams = nil;

#ifdef KEEPFILES
#else    
	NSError *deleteCorpusError = nil;
	NSFileManager *fileManager = [NSFileManager defaultManager]; // Let's make a best effort to erase the corpus now that we're done with it, but we'll carry on if it gives an error.
	[fileManager removeItemAtPath:[self.pathToCachesDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.corpus",fileName]] error:&deleteCorpusError];
	if(deleteCorpusError != 0) {
		if(openears_logging == 1) NSLog(@"Error while deleting language model corpus: %@", deleteCorpusError);
	}

#endif
    
    if(openears_logging == 1) {
        NSLog(@"Done creating language model with CMUCLMTK in %f seconds.",[NSDate timeIntervalSinceReferenceDate]-start);
    }
}

- (NSError *) checkModelForContent:(NSArray *)normalizedLanguageModelArray {
    if([normalizedLanguageModelArray count] < 1 || [[[normalizedLanguageModelArray componentsJoinedByString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]length] < 1) {

		return [NSError errorWithDomain:0 code:6000 userInfo:[NSDictionary dictionaryWithObject:@"Language model has no content." forKey:NSLocalizedDescriptionKey]];
	} 
    return nil;
}

- (NSError *) writeOutCorpusForArray:(NSArray *)normalizedLanguageModelArray toFilename:(NSString *)fileName {
    NSMutableString *mutableCorpusString = [[NSMutableString alloc] initWithString:[normalizedLanguageModelArray componentsJoinedByString:@" </s>\n<s> "]];
    
    [mutableCorpusString appendString:@" </s>\n"];
    [mutableCorpusString insertString:@"<s> " atIndex:0];
    NSString *corpusString = [[NSString alloc]initWithString:(NSString *)mutableCorpusString];
    [mutableCorpusString release];
    NSError *error = nil;
    [corpusString writeToFile:[self.pathToCachesDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.corpus",fileName]] atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error){
        // Handle error here
        if(openears_logging == 1) NSLog(@"Error: file was not written out due to error %@", error);
        [corpusString release];

        return error;
    }
    
    [corpusString release];
    return nil;
}

- (NSArray *) cleanDictionaryWordArray:(NSArray *)normalizedLanguageModelArray {
    
    NSMutableArray *mutableDictionaryArray = [NSMutableArray array]; // Now create a dictionary file from the same array
    
	int index = 0;
	for(NSString *string in normalizedLanguageModelArray) {  // For every array entry, if...
		if([string rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location == NSNotFound) { // ...the string contains no spaces or returns of any variety, i.e. it's a single word, put it into a mutable array entry by itself
			[mutableDictionaryArray addObject:[[string componentsSeparatedByCharactersInSet:self.sanitizeDictionaryCharacterSet]componentsJoinedByString:@""]]; // only add letters and numbers
			
		} else { // ...otherwise create a temporary array which consists of all the whitespace-separated stuff, separated by its whitespace, and append that array's contents to the end of the mutable array
			NSArray *temporaryExplosionArray = [[NSArray alloc] initWithArray:[string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
            
			for(NSString *wordString in temporaryExplosionArray) {
				[mutableDictionaryArray addObject:[[wordString componentsSeparatedByCharactersInSet:self.sanitizeDictionaryCharacterSet]componentsJoinedByString:@""]]; // only add letters and numbers; if there's something else in there, toss it.
			}
			[temporaryExplosionArray release];
		}
        
		index++;
	}

    return [NSArray arrayWithArray:mutableDictionaryArray];
}

- (void) checkPhoneticDictionaryAtAcousticModelPath:(NSString *)acousticModelPath {

    if(![[NSFileManager defaultManager] isReadableFileAtPath:acousticModelPath]) {
        NSLog(@"Error: the default phonetic dictionary %@ can't be found in the app bundle but the app is attempting to access it, most likely there will be a crash now.",acousticModelPath);
    }
}

- (NSDictionary *) assembleUserInfoDictionaryForLanguageModelsForFilename:(NSString *)fileName {
    return [self assembleUserInfoDictionaryForLanguageModelsForFilename:fileName withSuffix:@"DMP"];
}

- (NSDictionary *) assembleUserInfoDictionaryForLanguageModelsForFilename:(NSString *)fileName withSuffix:(NSString *)suffix {
    
    NSArray *objectsArray = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%@.%@",fileName,suffix],[NSString stringWithFormat:@"%@.dic",fileName],[self.pathToCachesDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",fileName,suffix]],[self.pathToCachesDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dic",fileName]],nil];
	
    NSArray *keysArray = [NSArray arrayWithObjects:@"LMFile",@"DictionaryFile",@"LMPath",@"DictionaryPath",nil];

    return [NSDictionary dictionaryWithObjects:objectsArray forKeys:keysArray];
}

- (void) checkCaseOfWords:(NSArray *)languageModelArray forAcousticModelAtPath:(NSString *)acousticModelPath {
    NSString *wordsString = [languageModelArray componentsJoinedByString:@""];
    if(([acousticModelPath rangeOfString:@"AcousticModelEnglish"].location != NSNotFound || [acousticModelPath rangeOfString:@"AcousticModelSpanish"].location != NSNotFound) && ([wordsString isEqualToString:[wordsString uppercaseString]]==FALSE)) {
        NSLog(@"WARNING: you are using the English or Spanish phonetic dictionary, which is in capital letters, but the words in your array use some lowercase letters. This means that those words will not successfully look up their pronunciation in the phonetic dictionary and they will either not end up in your pronunciation dictionary or the time required to create your dynamic dictionary will be very slow. If you don't override the default phonetic dictionary, any dynamically-created language model words given to the generateLanguageModelFromArray:withFilesNamed: method need to be in capital letters only.");
    }
}

- (NSError *) generateLanguageModelFromTextFile:(NSString *)pathToTextFile withFilesNamed:(NSString *)fileName  forAcousticModelAtPath:(NSString *)acousticModelPath{
    
    NSString *textFile = nil;
    
    // Return an error if we can't read a file at that location at all.
    
    if(![[NSFileManager defaultManager] isReadableFileAtPath:pathToTextFile]) {
        if(openears_logging == 1)NSLog(@"Error: you are trying to generate a language model from a text file at the path %@ but there is no file at that location which can be opened.", pathToTextFile);
    
        return [NSError errorWithDomain:@"LanguageModelErrorDomain" code:10020 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Error: you are trying to generate a language model from a text file at the path %@ but there is no file at that location which can be opened.",pathToTextFile] forKey:NSLocalizedDescriptionKey]];
    } else { // Try to read in the file
        NSError *error = nil;
        textFile = [NSString stringWithContentsOfFile:pathToTextFile encoding:NSUTF8StringEncoding error:&error];
        if(error) return error; // Die if we can't read in this particular file as a string.

    }
    
    NSMutableArray *mutableArrayToReturn = [[NSMutableArray alloc]init];
    
    NSArray *corpusArray = [textFile componentsSeparatedByCharactersInSet:
                            [NSCharacterSet newlineCharacterSet]]; // Create an array from the corpus that is separated by any variety of newlines.
    
    for(NSString *string in corpusArray) { // Fast enumerate through this array
        if ([[string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] length] != 0) { // Only keep strings which consist of more than whitespace or newlines only
            // This string has something in it besides whitespace or newlines
            NSString *trimmedString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]; // If we find a string that possesses content, remove whitespace and newlines from its very beginning and very end.

            [mutableArrayToReturn addObject:trimmedString]; // Add it to the array
        } 
    }
    
    NSArray *arrayToReturn = [NSArray arrayWithArray:mutableArrayToReturn]; // Set this to an immutable object to return
    
    [mutableArrayToReturn release]; // release the mutable object
    
    return [self generateLanguageModelFromArray:arrayToReturn withFilesNamed:fileName forAcousticModelAtPath:acousticModelPath]; // hand off this string to the real method.

}


- (NSError *) generateLanguageModelFromArray:(NSArray *)languageModelArray withFilesNamed:(NSString *)fileName forAcousticModelAtPath:(NSString *)acousticModelPath {
    NSLog(@"acousticModelPath is %@",acousticModelPath);
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    NSString *completePathToPhoneticDictionary  = [NSString stringWithFormat:@"%@/%@",acousticModelPath,@"LanguageModelGeneratorLookupList.text"];
    acousticModelPath = completePathToPhoneticDictionary;
    
    [self checkCaseOfWords:languageModelArray forAcousticModelAtPath:acousticModelPath];
    
    if(self.verboseLanguageModelGenerator == TRUE) verbose_cmuclmtk = 1; 
    
    NSArray *normalizedLanguageModelArray = [self compactWhitespaceOfArrayEntries:languageModelArray]; // We are normalizing the array first to get rid of any whitespace other than one single space between two words.
 
    NSError *error = nil; // Used throughout the method

    error = [self checkModelForContent:normalizedLanguageModelArray]; // Make sure this language model has something in it.
    if(error) {

        return error;   
    }

    error = [self writeOutCorpusForArray:normalizedLanguageModelArray toFilename:fileName]; // Write the corpus out to the filesystem.
    
    if(error) {
        return error;   
    }

    [self createLanguageModelFromFilename:fileName]; // Generate the language model using CMUCLMTK.
	
    NSMutableArray *dictionaryResultsArray = [[NSMutableArray alloc] init];
    
    error = [self createDictionaryFromWordArray:normalizedLanguageModelArray intoDictionaryArray:dictionaryResultsArray usingAcousticModelAtPath:acousticModelPath];
    
    if(!error) {
        // Write out the results array as a dictionary file in the caches directory
        BOOL writeOutSuccess = [[dictionaryResultsArray componentsJoinedByString:@"\n"] writeToFile:[self.pathToCachesDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dic",fileName]] atomically:YES encoding:NSUTF8StringEncoding error:&error];
        
        [dictionaryResultsArray release];
        if (!writeOutSuccess){ // If this fails, return an error.
            if(openears_logging == 1) NSLog(@"Error writing out dictionary: %@", error);		
            return error;
        } 
        
    } else {
        [dictionaryResultsArray release];
        return [NSError errorWithDomain:0 code:6001 userInfo:[NSDictionary dictionaryWithObject:@"Not possible to create a dictionary for this wordset." forKey:NSLocalizedDescriptionKey]];    
    }
    
    
    if(openears_logging == 1) NSLog(@"I'm done running dynamic language model generation and it took %f seconds", [NSDate timeIntervalSinceReferenceDate] - start); // Deliver the timing info if logging is on.
    
    // When this process succeeds, it returns a userInfo dictionary with its NSError that contains the locations of the newly-created files, just so you can verify where they ought to be if you are having issues. We'll return it below.
    
	return [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:[self assembleUserInfoDictionaryForLanguageModelsForFilename:fileName withSuffix:@"DMP"]]; // Return the code-0 error with the paths in the userInfo dictionary.
}



- (NSDictionary *) renameKey:(id)originalKey to:(id)newKey inDictionary:(NSDictionary *)dictionary {
    
    NSMutableDictionary *tempMutableDictionary = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
    
    id value = [tempMutableDictionary objectForKey:originalKey];
    [tempMutableDictionary removeObjectForKey:originalKey];
    [tempMutableDictionary setObject:value forKey:newKey];
    
    NSDictionary *dictionaryToReturn = [[NSDictionary alloc] initWithDictionary:(NSDictionary *)tempMutableDictionary];
    
    [tempMutableDictionary release];
    
    [dictionaryToReturn autorelease];
    
    return dictionaryToReturn;
}

- (NSError *) createDictionaryFromWordArray:(NSArray *)normalizedLanguageModelArray intoDictionaryArray:(NSMutableArray *)dictionaryResultsArray usingAcousticModelAtPath:(NSString *)acousticModelPath {
    
    NSError *error = nil; // Used throughout the method
    
    NSArray *dictionaryArray = [self cleanDictionaryWordArray:normalizedLanguageModelArray]; // Get rid of some wrong formatting in the dictionary word set.
    
    NSArray *arrayWithNoDuplicates = [[NSSet setWithArray:dictionaryArray] allObjects]; // Remove duplicate words through the magic of NSSet
    
    NSArray *sortedArray = [arrayWithNoDuplicates sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]; // Alphabetic sort
        
    [self checkPhoneticDictionaryAtAcousticModelPath:acousticModelPath]; // Give some helpful logging depending on the phonetic dictionary situation and assign the correct dictionary where needed.
    
    
    // load the dictionary file, whatever it is.
    NSString *pronunciationDictionary = [[NSString alloc] initWithContentsOfFile:acousticModelPath encoding:NSUTF8StringEncoding error:&error];
    
    
    if (error) { // If we can't load it, return an error immediately
        NSLog(@"Error while trying to load the pronunciation dictionary: %@", error);  
        [pronunciationDictionary release]; // This uses a lot of memory and should be memory managed and released as early as possible.
        return error;
    }
    
    NSTimeInterval performDictionaryLookupTime = 0.0; // We'll time this operation since it's critical.
    
    if(openears_logging == 1) {
        performDictionaryLookupTime = [NSDate timeIntervalSinceReferenceDate];
    }
    
    [dictionaryResultsArray addObjectsFromArray:[self performDictionaryLookup:sortedArray inString:pronunciationDictionary forAcousticModelAtPath:acousticModelPath]];// Do the dictionary pronunciation lookup
    
    if(openears_logging == 1) NSLog(@"I'm done running performDictionaryLookup and it took %f seconds", [NSDate timeIntervalSinceReferenceDate] - performDictionaryLookupTime);
    
    [pronunciationDictionary release]; // This uses a lot of memory and should be memory managed and released as early as possible.
    
    return nil;
    
}

- (NSError *) generateGrammarFromDictionary:(NSDictionary *)grammarDictionary withFilesNamed:(NSString *)fileName forAcousticModelAtPath:(NSString *)acousticModelPath {
    
    NSDictionary *fixedGrammarDictionary = [self renameKey:[[grammarDictionary allKeys] firstObject] to:[NSString stringWithFormat:@"PublicRule%@",[[grammarDictionary allKeys] firstObject]] inDictionary:grammarDictionary];
    
    NSMutableArray *phoneticDictionaryArray = [[[NSMutableArray alloc] init] autorelease];
    
    GrammarGenerator *grammarGenerator = [[GrammarGenerator alloc] init];
    
    NSString *completePathToPhoneticDictionary  = [NSString stringWithFormat:@"%@/%@",acousticModelPath,@"LanguageModelGeneratorLookupList.text"];
    acousticModelPath = completePathToPhoneticDictionary;
    
    grammarGenerator.delegate = (id)self;
    grammarGenerator.acousticModelPath = acousticModelPath;
    
    NSError *error = [grammarGenerator createGrammarFromDictionary:fixedGrammarDictionary withRequestedName:fileName creatingPhoneticDictionaryArray:phoneticDictionaryArray];
    
    if(error) {
        NSLog(@"It wasn't possible to create this grammar: %@", grammarDictionary);
        error = [NSError errorWithDomain:@"LanguageModelErrorDomain" code:10040 userInfo:[NSDictionary dictionaryWithObject:@"It wasn't possible to generate a grammar for this dictionary, please turn on OpenEarsLogging for more information" forKey:NSLocalizedDescriptionKey]];
    } else {
        error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:[self assembleUserInfoDictionaryForLanguageModelsForFilename:fileName withSuffix:@"gram"]]; // Return the code-0 error with the paths in the userInfo dictionary.
    }
    
    grammarGenerator.delegate = nil;
    
    [grammarGenerator release];
    
    return error;
}



@end
