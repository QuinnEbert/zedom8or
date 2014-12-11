#import <UIKit/UIKit.h>
#import <Slt/Slt.h>

@class PocketsphinxController;
@class FliteController;

#import <OpenEars/OpenEarsEventsObserver.h> // We need to import this here in order to use the delegate.

// Dispositions that can be arrived at by way of parsing input speech and transcribing
#define DISPO_INVALID       0
#define DISPO_SET_POWER     1
#define DISPO_SWITCH_INPUT  2
#define DISPO_SET_VOLUME    4

@interface ViewController : UIViewController <OpenEarsEventsObserverDelegate> {
	Slt *slt;

	// These three are important OpenEars classes that ViewController demonstrates the use of. There is a fourth important class (LanguageModelGenerator) demonstrated
	// inside the ViewController implementation in the method viewDidLoad.
	
	OpenEarsEventsObserver *openEarsEventsObserver; // A class whose delegate methods which will allow us to stay informed of changes in the Flite and Pocketsphinx statuses.
	PocketsphinxController *pocketsphinxController; // The controller for Pocketsphinx (voice recognition).
	FliteController *fliteController; // The controller for Flite (speech).
    
	// Some UI, not specifically related to OpenEars.
	IBOutlet UIButton *stopButton;
	IBOutlet UIButton *startButton;	
	IBOutlet UIButton *suspendListeningButton;	
	IBOutlet UIButton *resumeListeningButton;
	IBOutlet UITextView *statusTextView;
	IBOutlet UITextView *heardTextView;
	IBOutlet UILabel *pocketsphinxDbLabel;
	IBOutlet UILabel *fliteDbLabel;
	BOOL usingStartLanguageModel;
	int restartAttemptsDueToPermissionRequests;
    BOOL startupFailedDueToLackOfPermissions;
	// Strings which aren't required for OpenEars but which will help us show off the dynamic language features in this sample app.
	NSString *pathToFirstDynamicallyGeneratedLanguageModel;
	NSString *pathToFirstDynamicallyGeneratedDictionary;
	
	NSString *pathToSecondDynamicallyGeneratedLanguageModel;
	NSString *pathToSecondDynamicallyGeneratedDictionary;

	
	// Our NSTimer that will help us read and display the input and output levels without locking the UI
	NSTimer *uiUpdateTimer;
    
    NSArray *arrFunctions;
    NSArray *arrOutputs;
    NSArray *arrInputs;
}

@property (strong,retain) NSArray *arrFunctions;
@property (strong,retain) NSArray *arrOutputs;
@property (strong,retain) NSArray *arrInputs;

// UI actions, not specifically related to OpenEars other than the fact that they invoke OpenEars methods.
- (IBAction) stopButtonAction;
- (IBAction) startButtonAction;
- (IBAction) suspendListeningButtonAction;
- (IBAction) resumeListeningButtonAction;

// Example for reading out the input audio levels without locking the UI using an NSTimer

- (void) startDisplayingLevels;
- (void) stopDisplayingLevels;

// These three are the important OpenEars objects that this class demonstrates the use of.
@property (nonatomic, strong) Slt *slt;

@property (nonatomic, strong) OpenEarsEventsObserver *openEarsEventsObserver;
@property (nonatomic, strong) PocketsphinxController *pocketsphinxController;
@property (nonatomic, strong) FliteController *fliteController;
// Some UI, not specifically related to OpenEars.
@property (nonatomic, strong) IBOutlet UIButton *stopButton;
@property (nonatomic, strong) IBOutlet UIButton *startButton;
@property (nonatomic, strong) IBOutlet UIButton *suspendListeningButton;	
@property (nonatomic, strong) IBOutlet UIButton *resumeListeningButton;	
@property (nonatomic, strong) IBOutlet UITextView *statusTextView;
@property (nonatomic, strong) IBOutlet UITextView *heardTextView;
@property (nonatomic, strong) IBOutlet UILabel *pocketsphinxDbLabel;
@property (nonatomic, strong) IBOutlet UILabel *fliteDbLabel;

@property (nonatomic, assign) BOOL usingStartLanguageModel;
@property (nonatomic, assign) int restartAttemptsDueToPermissionRequests;
@property (nonatomic, assign) BOOL startupFailedDueToLackOfPermissions;
// Things which help us show off the dynamic language features.
@property (nonatomic, copy) NSString *pathToFirstDynamicallyGeneratedLanguageModel;
@property (nonatomic, copy) NSString *pathToFirstDynamicallyGeneratedDictionary;
@property (nonatomic, copy) NSString *pathToSecondDynamicallyGeneratedLanguageModel;
@property (nonatomic, copy) NSString *pathToSecondDynamicallyGeneratedDictionary;

// Our NSTimer that will help us read and display the input and output levels without locking the UI
@property (nonatomic, strong) 	NSTimer *uiUpdateTimer;

@end

