
//
//  NcdLinearityTask.h
//  Orca
//
//  Created by Mark Howe on July 1, 2004.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------



#import "ORTask.h"

@interface NcdLinearityTask : ORTask
{

    IBOutlet NSTextField*   timeField;
    IBOutlet NSStepper*     timeStepper;
    IBOutlet NSTextField*   startAmplitudeField;
    IBOutlet NSStepper*     startAmplitudeStepper;
    IBOutlet NSTextField*   endAmplitudeField;
    IBOutlet NSStepper*     endAmplitudeStepper;
    IBOutlet NSTextField*   burstRateField;
    IBOutlet NSStepper*     burstRateStepper;
    IBOutlet NSTextField*   widthField;
    IBOutlet NSStepper*     widthStepper;
    IBOutlet NSTextField*   numAmpValuesField;
    IBOutlet NSStepper*     numAmpValuesStepper;
    IBOutlet NSPopUpButton* selectionPopUpButton;	
    IBOutlet NSButton*      extendedLinearityButton;	

    IBOutlet NSButton*      cycleWidthButton;
    IBOutlet NSTextField*   startWidthField;
    IBOutlet NSStepper*     startWidthStepper;
    IBOutlet NSTextField*   endWidthField;
    IBOutlet NSStepper*     endWidthStepper;
    IBOutlet NSTextField*   numWidthValuesField;
    IBOutlet NSStepper*     numWidthValuesStepper;
    IBOutlet NSButton*      useFileButton;
    IBOutlet NSButton*      chooseFileButton;
    IBOutlet NSTextField*   fileNameField;
    IBOutlet NSButton*      doAllChannelsButton;

    
    id stepTask;
    id thePDSModel;
    id thePulserModel;
    BOOL startedStepTask;
    BOOL extendedLinearity;
    BOOL doAllChannels;
    
    int timeOnOneChannel[2];
    int selectedWaveform[2];
    float startAmplitude[2];
    float endAmplitude[2];
    float burstRate[2];
    float width[2];
    int numAmpValues[2];

    NSData* pulserMemento;
    NSData* stepTaskMemento;
    NSData* pdsMemento;
    int currentAmpStep;
    int currentWidthStep;
    int currentFileStep;
    
    BOOL cycleWidth[2];
	float startWidth[2];
	float endWidth[2];
	int numWidthValues[2];
	BOOL useFile[2];
	NSString* fileName[2];
    NSArray* fileLines;
    int lastWaveForm;
    NSArray* ncdLinearityTaskObjects;
}

- (void)  updateWindow;

#pragma mark ¥¥¥Accessors
- (NSArray*) fileLines;
- (void) setFileLines:(NSArray*)someLines;
- (NSString*) fileName;
- (void) setFileName:(NSString*)aFileName;
- (BOOL) useFile;
- (void) setUseFile:(BOOL)aUseFile;
- (BOOL) cycleWidth;
- (void) setCycleWidth:(BOOL)aState;
- (int) numWidthValues;
- (void) setNumWidthValues:(int)aNumWidthValues;
- (float) endWidth;
- (void) setEndWidth:(float)aEndWidth;
- (float) startWidth;
- (void) setStartWidth:(float)aStartWidth;
- (int)   timeOnOneChannel;
- (void)  setTimeOnOneChannel:(int)aTimeOnOneChannel;
- (float) startAmplitude;
- (void)  setStartAmplitude:(float)anAmplitude;
- (float) burstRate;
- (void)  setBurstRate:(float)aBurstRate;
- (float) width;
- (void)  setWidth:(CGFloat)aWidth;
- (int)   numAmpValues;
- (void)  setNumAmpValues:(int)aNumAmpValues;
- (float) endAmplitude;
- (void)  setEndAmplitude:(float)aEndAmplitude;
- (void)  setDefaults;
- (int)	  selectedWaveform;
- (void)  setSelectedWaveform:(int)newSelectedWaveform;
- (BOOL)  extendedLinearity;
- (void)  setExtendedLinearity: (BOOL) flag;


#pragma mark ¥¥¥Actions
- (IBAction) timeAction:(id)sender;
- (IBAction) startAmplitudeAction:(id)sender;
- (IBAction) burstRateAction:(id)sender;
- (IBAction) widthAction:(id)sender;
- (IBAction) numAmpValuesAction:(id)sender;
- (IBAction) endAmplitudeAction:(id)sender;
- (IBAction) selectWaveformAction:(id)sender;
- (IBAction) extendedLinearityAction:(id)sender;

- (IBAction) cycleWidthAction:(id)sender;
- (IBAction) useFileAction:(id)sender;
- (IBAction) selectFileAction:(id)sender;
- (IBAction) startWidthAction:(id)sender;
- (IBAction) endWidthAction:(id)sender;
- (IBAction) numWidthValuesAction:(id)sender;

#pragma mark ¥¥¥Task Methods
- (void) prepare;
- (BOOL) doWork;
- (void) finishUp;
- (void) cleanUp;

@end

