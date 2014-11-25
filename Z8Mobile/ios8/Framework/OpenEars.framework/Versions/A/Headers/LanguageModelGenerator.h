//  OpenEars 
//  http://www.politepix.com/openears
//
//  LanguageModelGenerator.h
//  OpenEars
//
//  LanguageModelGenerator is a class which creates new language models and grammars
//
//  Copyright Politepix UG (haftungsbeschränkt) 2012. All rights reserved.
//  http://www.politepix.com
//  Contact at http://www.politepix.com/contact
//
//  This file is licensed under the Politepix Shared Source license found in the root of the source distribution.


/**
 @class  LanguageModelGenerator
 @brief  The class that generates the vocabulary the PocketsphinxController is able to understand.
 
 ## Usage examples
 > What to add to your implementation:
 @htmlinclude LanguageModelGenerator_Implementation.txt
 > How to use the class methods:
 @htmlinclude LanguageModelGenerator_Calls.txt 
 */

@class GraphemeGenerator;

#import "GrammarDefinitions.h"


@interface LanguageModelGenerator : NSObject {
    
    /**Set this to TRUE to get verbose output*/
    BOOL verboseLanguageModelGenerator;



    /**Advanced: if you are using your own acoustic model or an custom dictionary contained within an acoustic model and these don't use the same phonemes as the English or Spanish acoustic models, you will need to set useFallbackMethod to FALSE so that no attempt is made to use the English or Spanish fallback method for finding pronunciations of words which don't appear in the custom acoustic model's phonetic dictionary.*/    
    BOOL useFallbackMethod;
        
    /**\cond HIDDEN_SYMBOLS*/ 
    NSMutableCharacterSet *sanitizeDictionaryCharacterSet;
  
    NSString *pathToCachesDirectory;
    GraphemeGenerator *graphemeGenerator;
    NSMutableArray *iterationStorageArray;
    /**\endcond*/ 
    
    NSNumber *ngrams;
  
}
@property(nonatomic,assign)    BOOL verboseLanguageModelGenerator;
@property(nonatomic,assign) BOOL useFallbackMethod;


/**\cond HIDDEN_SYMBOLS*/ 

@property(nonatomic,retain) NSMutableCharacterSet *sanitizeDictionaryCharacterSet;
@property(nonatomic,copy) NSString * pathToCachesDirectory;
@property(nonatomic,retain) GraphemeGenerator *graphemeGenerator;
@property(nonatomic,retain) NSNumber *ngrams;
@property(nonatomic, retain) NSMutableArray *iterationStorageArray;

- (NSError *) writeOutCorpusForArray:(NSArray *)normalizedLanguageModelArray toFilename:(NSString *)fileName;
- (NSDictionary *) assembleUserInfoDictionaryForLanguageModelsForFilename:(NSString *)fileName withSuffix:(NSString *)suffix;
- (NSDictionary *) assembleUserInfoDictionaryForLanguageModelsForFilename:(NSString *)fileName;
- (void) createLanguageModelFromFilename:(NSString *)fileName;
/**\endcond*/  


/**Generate a language model from an array of NSStrings which are the words and phrases you want PocketsphinxController or PocketsphinxController+RapidEars to understand, using your chosen acoustic model. Putting a phrase in as a string makes it somewhat more probable that the phrase will be recognized as a phrase when spoken. fileName is the way you want the output files to be named, for instance if you enter "MyDynamicLanguageModel" you will receive files output to your Caches directory titled MyDynamicLanguageModel.dic, MyDynamicLanguageModel.arpa, and MyDynamicLanguageModel.DMP. The error that this method returns contains the paths to the files that were created in a successful generation effort in its userInfo when NSError == noErr. The words and phrases in languageModelArray must be written with capital letters exclusively, for instance "word" must appear in the array as "WORD". */

- (NSError *) generateLanguageModelFromArray:(NSArray *)languageModelArray withFilesNamed:(NSString *)fileName forAcousticModelAtPath:(NSString *)acousticModelPath;

/**Dynamically generate a JSGF grammar using OpenEars' natural language system for defining a speech recognition ruleset. The NSDictionary you submit to the argument generateGrammarFromDictionary: is a key-value pair consisting of an NSArray of words stored in NSStrings indicating the vocabulary to be listened for, and an NSString key which is one of the following #defines from GrammarDefinitions.h, indicating the rule for the vocabulary in the NSArray:

ThisWillBeSaidOnce
ThisCanBeSaidOnce
ThisWillBeSaidWithOptionalRepetitions
ThisCanBeSaidWithOptionalRepetitions
OneOfTheseWillBeSaidOnce
OneOfTheseCanBeSaidOnce
OneOfTheseWillBeSaidWithOptionalRepetitions
OneOfTheseCanBeSaidWithOptionalRepetitions

Breaking them down one at a time for their specific meaning in defining a rule:
 
ThisWillBeSaidOnce // This indicates that the word or words in the array must be said (in sequence, in the case of multiple words), one time.
ThisCanBeSaidOnce // This indicates that the word or words in the array can be said (in sequence, in the case of multiple words), one time, but can also be omitted as a whole from the utterance.
ThisWillBeSaidWithOptionalRepetitions // This indicates that the word or words in the array must be said (in sequence, in the case of multiple words), one time or more.
ThisCanBeSaidWithOptionalRepetitions // This indicates that the word or words in the array can be said (in sequence, in the case of multiple words), one time or more, but can also be omitted as a whole from the utterance.
OneOfTheseWillBeSaidOnce // This indicates that exactly one selection from the words in the array must be said one time.
OneOfTheseCanBeSaidOnce // This indicates that exactly one selection from the words in the array can be said one time, but that all of the words can also be omitted from the utterance.
OneOfTheseWillBeSaidWithOptionalRepetitions // This indicates that exactly one selection from the words in the array must be said, one time or more.
OneOfTheseCanBeSaidWithOptionalRepetitions // This indicates that exactly one selection from the words in the array can be said, one time or more, but that all of the words can also be omitted from the utterance.

Since an NSString in these NSArrays can also be a phrase, references to words above should also be understood to apply to complete phrases when they are contained in a single NSString.
 
A key-value pair can also have NSDictionaries in the NSArray instead of NSStrings, or a mix of NSStrings and NSDictionaries, meaning that you can nest rules in other rules.

Here is an example of a complex rule which can be submitted to the generateGrammarFromDictionary: argument followed by an explanation of what it means:
 
 @{
     ThisWillBeSaidOnce : @[
         @{ OneOfTheseCanBeSaidOnce : @[@"HELLO COMPUTER", @"GREETINGS ROBOT"]},
         @{ OneOfTheseWillBeSaidOnce : @[@"DO THE FOLLOWING", @"INSTRUCTION"]},
         @{ OneOfTheseWillBeSaidOnce : @[@"GO", @"MOVE"]},
         @{ThisWillBeSaidWithOptionalRepetitions : @[
             @{ OneOfTheseWillBeSaidOnce : @[@"10", @"20",@"30"]}, 
             @{ OneOfTheseWillBeSaidOnce : @[@"LEFT", @"RIGHT", @"FORWARD"]}
         ]},
         @{ OneOfTheseWillBeSaidOnce : @[@"EXECUTE", @"DO IT"]},
         @{ ThisCanBeSaidOnce : @[@"THANK YOU"]}
     ]
 };

 Breaking it down step by step to explain exactly what the contents mean:
 
 @{
     ThisWillBeSaidOnce : @[ // This means that a valid utterance for this ruleset will obey all of the following rules in sequence in a single complete utterance:
         @{ OneOfTheseCanBeSaidOnce : @[@"HELLO COMPUTER", @"GREETINGS ROBOT"]}, // At the beginning of the utterance there is an optional statement. The optional statement can be either "HELLO COMPUTER" or "GREETINGS ROBOT" or it can be omitted.
         @{ OneOfTheseWillBeSaidOnce : @[@"DO THE FOLLOWING", @"INSTRUCTION"]}, // Next, an utterance will have exactly one of the following required statements: "DO THE FOLLOWING" or "INSTRUCTION".
         @{ OneOfTheseWillBeSaidOnce : @[@"GO", @"MOVE"]}, // Next, an utterance will have exactly one of the following required statements: "GO" or "MOVE"
         @{ThisWillBeSaidWithOptionalRepetitions : @[ // Next, an utterance will have a minimum of one statement of the following nested instructions, but can also accept multiple valid versions of the nested instructions:
             @{ OneOfTheseWillBeSaidOnce : @[@"10", @"20",@"30"]}, // Exactly one utterance of either the number "10", "20" or "30",
             @{ OneOfTheseWillBeSaidOnce : @[@"LEFT", @"RIGHT", @"FORWARD"]} // Followed by exactly one utterance of either the word "LEFT", "RIGHT", or "FORWARD".
         ]},
         @{ OneOfTheseWillBeSaidOnce : @[@"EXECUTE", @"DO IT"]}, // Next, an utterance must contain either the word "EXECUTE" or the phrase "DO IT",
         @{ ThisCanBeSaidOnce : @[@"THANK YOU"]} and there can be an optional single statement of the phrase "THANK YOU" at the end.
     ]
 };
 
So as examples, here are some sentences that this ruleset will report as hypotheses from user utterances:

"HELLO COMPUTER DO THE FOLLOWING GO 20 LEFT 30 RIGHT 10 FORWARD EXECUTE THANK YOU"
"GREETINGS ROBOT DO THE FOLLOWING MOVE 10 FORWARD DO IT"
"INSTRUCTION 20 LEFT 20 LEFT 20 LEFT 20 LEFT EXECUTE"

But it will not report hypotheses for sentences such as the following which are not allowed by the rules:

"HELLO COMPUTER HELLO COMPUTER"
"MOVE 10"
"GO RIGHT"

Since you as the developer are the designer of the ruleset, you can extract the behavioral triggers from your app from hypotheses which observe your rules.

The words and phrases in languageModelArray must be written with capital letters exclusively, for instance "word" must appear in the array as "WORD".

The last two arguments of the method work identically to the equivalent language model method. The withFilesNamed: argument takes an NSString which is the naming you would like for the files output by this method. The argument acousticModelPath takes the path to the relevant acoustic model.

This method returns an NSError, which will either return an error code or it will return noErr with an attached userInfo NSDictionary containing the paths to your newly-generated grammar (a .gram file) and corresponding phonetic dictionary (a .dic file). Remember that when you are passing .gram files to the Pocketsphinx method:

- (void) startListeningWithLanguageModelAtPath:(NSString *)languageModelPath dictionaryAtPath:(NSString *)dictionaryPath acousticModelAtPath:(NSString *)acousticModelPath languageModelIsJSGF:(BOOL)languageModelIsJSGF;

you will now set the argument languageModelIsJSGF: to TRUE.
 
*/
- (NSError *) generateGrammarFromDictionary:(NSDictionary *)grammarDictionary withFilesNamed:(NSString *)fileName forAcousticModelAtPath:(NSString *)acousticModelPath;

/**Generate a language model from a text file containing words and phrases you want PocketsphinxController to understand, using your chosen acoustic model. The file should be formatted with every word or contiguous phrase on its own line with a line break afterwards. Putting a phrase in on its own line makes it somewhat more probable that the phrase will be recognized as a phrase when spoken. Give the correct full path to the text file as a string. fileName is the way you want the output files to be named, for instance if you enter "MyDynamicLanguageModel" you will receive files output to your Caches directory titled MyDynamicLanguageModel.dic, MyDynamicLanguageModel.arpa, and MyDynamicLanguageModel.DMP. The error that this method returns contains the paths to the files that were created in a successful generation effort in its userInfo when NSError == noErr. The words and phrases in languageModelArray must be written with capital letters exclusively, for instance "word" must appear in the array as "WORD". */

- (NSError *) generateLanguageModelFromTextFile:(NSString *)pathToTextFile withFilesNamed:(NSString *)fileName forAcousticModelAtPath:(NSString *)acousticModelPath;




@end
