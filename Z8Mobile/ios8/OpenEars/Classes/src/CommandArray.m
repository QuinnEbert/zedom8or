//
//  CommandArray.m
//  OpenEars
//
//
//  Copyright Politepix UG (haftungsbeschränkt) 2012. All rights reserved.
//  http://www.politepix.com
//  Contact at http://www.politepix.com/contact
//
//  this file is licensed under the Politepix Shared Source license found 
//  found in the root of the source distribution. Please see the file "Version.txt" in the root of 
//  the source distribution for the version number of this OpenEars package.

#import "CommandArray.h"


#import "pocketsphinx.h"


#import "PocketsphinxRunConfig.h"

#import "RuntimeVerbosity.h"
#import "AudioConstants.h"



@implementation CommandArray

extern int openears_logging;

- (NSArray *)commandArrayForlanguageModel:(NSString *)languageModelPath dictionaryPath:(NSString *)dictionaryPath acousticModelPath:(NSString *)acousticModelPath isJSGF:(BOOL)languageModelIsJSGF {
	
    
    NSString *languageModelToUse = nil;
    float languageWeight;
    if(languageModelIsJSGF == TRUE) {
        languageModelToUse = @"-jsgf";
        languageWeight = kJSGFLanguageWeight; // I think that the language weight for JSGF was the source of a lot of issues
    } else {
        languageModelToUse = @"-lm";
        languageWeight = 6.5;
    }
    
    
    NSArray *commandArray = [NSArray arrayWithObjects: // This is an array that is used to set up the run arguments for Pocketsphinx. 
                             // Never change any of the values here directly.  They can be changed using the file PocketsphinxRunConfig.h (although you shouldn't 
                             // change anything there unless you are absolutely 100% clear on why you'd want to and what the outcome will be).
                             // See PocketsphinxRunConfig.h for explanations of these constants and the run arguments they correspond to.
                             languageModelToUse, languageModelPath,		 
#ifdef kADCDEV
                             @"-adcdev", kADCDEV,
#endif
                             
#ifdef kAGC
                             @"-agc", kAGC,
#endif
                             
#ifdef kAGCTHRESH
                             @"-agcthresh", kAGCTHRESH,
#endif
                             
#ifdef kALPHA
                             @"-alpha", kALPHA,
#endif
                             
#ifdef kARGFILE
                             @"-argfile", kARGFILE,
#endif
                             
#ifdef kASCALE
                             @"-ascale", kASCALE,
#endif
                             
#ifdef kBACKTRACE
                             @"-backtrace", kBACKTRACE,
#endif
                             
#ifdef kBEAM
                             @"-beam", kBEAM,
#endif
                             
#ifdef kBESTPATH
                             @"-bestpath", kBESTPATH,
#endif
                             
#ifdef kBESTPATHLW
                             @"-bestpathlw", kBESTPATHLW,
#endif
                             
#ifdef kBGHIST
                             @"-bghist", kBGHIST,
#endif
                             
#ifdef kCEPLEN
                             @"-ceplen", kCEPLEN,
#endif
                             
#ifdef kCMN
                             @"-cmn", kCMN,
#endif
                             
#ifdef kCMNINIT
                             @"-cmninit", kCMNINIT,
#endif
                             
#ifdef kCOMPALLSEN
                             @"-compallsen", kCOMPALLSEN,
#endif
                             
#ifdef kDEBUG
                             @"-debug", kDEBUG,
#endif
                             
#ifdef kDICT
                             @"-dict", dictionaryPath,
#endif
                             
#ifdef kDICTCASE
                             @"-dictcase", kDICTCASE,
#endif
                             
#ifdef kDITHER
                             @"-dither", kDITHER,
#endif
                             
#ifdef kDOUBLEBW
                             @"-doublebw", kDOUBLEBW,
#endif
                             
#ifdef kDS
                             @"-ds", kDS,
#endif
                             
#ifdef kFDICT
                             @"-fdict",  [NSString stringWithFormat:@"%@/noisedict",acousticModelPath],
#endif
                             
#ifdef kFEAT
                             @"-feat", kFEAT,
#endif
                             
#ifdef kFEATPARAMS
                             @"-featparams", kFEATPARAMS,
#endif
                             
#ifdef kFILLPROB
                             @"-fillprob", kFILLPROB,
#endif
                             
#ifdef kFRATE
                             @"-frate", kFRATE,
#endif
                             
#ifdef kFSG
                             @"-fsg", kFSG,
#endif
                             
#ifdef kFSGUSEALTPRON
                             @"-fsgusealtpron", kFSGUSEALTPRON,
#endif
                             
#ifdef kFSGUSEFILLER
                             @"-fsgusefiller", kFSGUSEFILLER,
#endif
                             
#ifdef kFWDFLAT
                             @"-fwdflat", kFWDFLAT,
#endif
                             
#ifdef kFWDFLATBEAM
                             @"-fwdflatbeam", kFWDFLATBEAM,
#endif
                             
#ifdef kFWDFLATWID
                             @"-fwdflatefwid", kFWDFLATWID,
#endif
                             
#ifdef kFWDFLATLW
                             @"-fwdflatlw", kFWDFLATLW,
#endif
                             
#ifdef kFWDFLATSFWIN
                             @"-fwdflatsfwin", kFWDFLATSFWIN,
#endif
                             
#ifdef kFWDFLATWBEAM
                             @"-fwdflatwbeam", kFWDFLATWBEAM,
#endif
                             
#ifdef kFWDTREE
                             @"-fwdtree", kFWDTREE,
#endif
                             
#ifdef kHMM
                             @"-hmm", acousticModelPath,
#endif
                             
#ifdef kINPUT_ENDIAN
                             @"-input_endian", kINPUT_ENDIAN,
#endif
                             
#ifdef kKDMAXBBI
                             @"-kdmaxbbi", kKDMAXBBI,
#endif
                             
#ifdef kKDMAXDEPTH
                             @"-kdmaxdepth", kKDMAXDEPTH,
#endif
                             
#ifdef kKDTREE
                             @"-kdtree", kKDTREE,
#endif
                             
#ifdef kLATSIZE
                             @"-latsize", kLATSIZE,
#endif
                             
#ifdef kLDA
                             @"-lda", kLDA,
#endif
                             
#ifdef kLDADIM
                             @"-ldadim", kLDADIM,
#endif
                             
#ifdef kLEXTREEDUMP
                             @"-lextreedump", kLEXTREEDUMP,
#endif
                             
#ifdef kLIFTER
                             @"-lifter",	kLIFTER,
#endif
                             
#ifdef kLMCTL
                             @"-lmctl",	kLMCTL,
#endif
                             
#ifdef kLMNAME
                             @"-lmname",	kLMNAME,
#endif
                             
#ifdef kLOGBASE
                             @"-logbase", kLOGBASE,
#endif
                             
#ifdef kLOGFN
                             @"-logfn", kLOGFN,
#endif
                             
#ifdef kLOGSPEC
                             @"-logspec", kLOGSPEC,
#endif
                             
#ifdef kLOWERF
                             @"-lowerf", kLOWERF,
#endif
                             
#ifdef kLPBEAM
                             @"-lpbeam", kLPBEAM,
#endif
                             
#ifdef kLPONLYBEAM
                             @"-lponlybeam", kLPONLYBEAM,
#endif
                             
                             
                             @"-lw",	[NSString stringWithFormat:@"%f", languageWeight],
                             
                             
#ifdef kMAXHMMPF
                             @"-maxhmmpf", kMAXHMMPF,
#endif
                             
#ifdef kMAXNEWOOV
                             @"-maxnewoov", kMAXNEWOOV,
#endif
                             
#ifdef kMAXWPF
                             @"-maxwpf", kMAXWPF,
#endif
                             
#ifdef kMDEF
                             @"-mdef", kMDEF,
#endif
                             
#ifdef kMEAN
                             @"-mean", kMEAN,
#endif
                             
#ifdef kMFCLOGDIR
                             @"-mfclogdir", kMFCLOGDIR,
#endif
                             
#ifdef kMIXW
                             @"-mixw", kMIXW,
#endif
                             
#ifdef kMIXWFLOOR
                             @"-mixwfloor", kMIXWFLOOR,
#endif
                             
#ifdef kMLLR
                             @"-mllr", kMLLR,
#endif
                             
#ifdef kMMAP
                             @"-mmap", kMMAP,
#endif
                             
#ifdef kNCEP
                             @"-ncep", kNCEP,
#endif
                             
#ifdef kNFFT
                             @"-nfft", kNFFT,
#endif
                             
#ifdef kNFILT
                             @"-nfilt", kNFILT,
#endif
                             
#ifdef kNWPEN
                             @"-nwpen", kNWPEN,
#endif
                             
#ifdef kPBEAM
                             @"-pbeam", kPBEAM,
#endif
                             
#ifdef kPIP
                             @"-pip", kPIP,
#endif
                             
#ifdef kPL_BEAM
                             @"-pl_beam", kPL_BEAM,
#endif
                             
#ifdef kPL_PBEAM
                             @"-pl_pbeam", kPL_PBEAM,
#endif
                             
#ifdef kPL_WINDOW
                             @"-pl_window", kPL_WINDOW,
#endif
                             
#ifdef kRAWLOGDIR
                             @"-rawlogdir", kRAWLOGDIR,
#endif
                             
#ifdef kREMOVE_DC
                             @"-remove_dc", kREMOVE_DC,
#endif
                             
#ifdef kROUND_FILTERS
                             @"-round_filters", kROUND_FILTERS,
#endif
                             
#ifdef kSAMPRATE
                             @"-samprate", kSAMPRATE,
#endif
                             
#ifdef kSEED
                             @"-seed",kSEED,
#endif
                             
#ifdef kSENDUMP
                             @"-sendump", kSENDUMP,
#endif
                             
#ifdef kSENMGAU
                             @"-senmgau", kSENMGAU,
#endif
                             
#ifdef kSILPROB
                             @"-silprob", kSILPROB,
#endif
                             
#ifdef kSMOOTHSPEC
                             @"-smoothspec", kSMOOTHSPEC,
#endif
                             
#ifdef kSVSPEC
                             @"-svspec", kSVSPEC,
#endif
                             
#ifdef kTMAT
                             @"-tmat", kTMAT,
#endif
                             
#ifdef kTMATFLOOR
                             @"-tmatfloor", kTMATFLOOR,
#endif
                             
#ifdef kTOPN
                             @"-topn", kTOPN,
#endif
                             
#ifdef kTOPN_BEAM
                             @"-topn_beam", kTOPN_BEAM,
#endif
                             
#ifdef kTOPRULE
                             @"-toprule", kTOPRULE,
#endif
                             
#ifdef kTRANSFORM
                             @"-transform", kTRANSFORM,
#endif
                             
#ifdef kUNIT_AREA
                             @"-unit_area", kUNIT_AREA,
#endif
                             
#ifdef kUPPERF
                             @"-upperf", kUPPERF,
#endif
                             
#ifdef kUSEWDPHONES
                             @"-usewdphones", kUSEWDPHONES,
#endif
                             
#ifdef kUW
                             @"-uw", kUW,
#endif
                             
#ifdef kVAR
                             @"-var", kVAR,
#endif
                             
#ifdef kVARFLOOR
                             @"-varfloor", kVARFLOOR,
#endif
                             
#ifdef kVARNORM
                             @"-varnorm", kVARNORM,
#endif
                             
#ifdef kVERBOSE
                             @"-verbose", kVERBOSE,
#endif
                             
#ifdef kWARP_PARAMS
                             @"-warp_params", kWARP_PARAMS,
#endif
                             
#ifdef kWARP_TYPE
                             @"-warp_type", kWARP_TYPE,
#endif
                             
#ifdef kWBEAM
                             @"-wbeam", kWBEAM,
#endif
                             
#ifdef kWIP
                             @"-wip", kWIP,
#endif
                             
#ifdef kWLEN
                             @"-wlen", kWLEN,
#endif
                             nil];
	
    
	return commandArray;
}

@end
