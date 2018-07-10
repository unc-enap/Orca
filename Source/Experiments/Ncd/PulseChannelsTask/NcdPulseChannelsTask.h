
//
//  NcdPulseChannelsTask.h
//  Orca
//
//  Created by Mark Howe on June 5, 2006.
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


@interface NcdPulseChannelsTask : ORTask
{

    IBOutlet NSMatrix*		neutrinoTextMatrix;
    IBOutlet NSMatrix*		neutrinoStepperMatrix;
    IBOutlet NSMatrix*		sourceTextMatrix;
    IBOutlet NSMatrix*		sourceStepperMatrix;
    IBOutlet NSPopUpButton* neutrinoWaveformPopUpButton;	
    IBOutlet NSPopUpButton* sourceWaveformPopUpButton;	
    IBOutlet NSButton*		autoStartButton;	
	IBOutlet NSButton*      autoStartForSourceRunButton;
	IBOutlet NSButton*      pulseOneOnlyButton;
	IBOutlet NSTextField*   cardToPulseField;
	IBOutlet NSTextField*   channelToPulseField;
	
	BOOL useNeutrinoRun;
	BOOL autoStart;
	BOOL autoStartForSourceRun;
	
    id thePDSModel;
    id thePulserModel;
    
	float neutrinoParam[4];
	float sourceParam[4];
	int   neutrinoWaveform;
	int   sourceWaveform;
	
    NSData* pulserMemento;
    NSData* pdsMemento;
    
	NSMutableArray* onlineTubes;
	int tubeIndex;
	NSDate* lastTime;
	
	//special one pulse case
	BOOL pulseOneOnly;
	int  cardToPulse;
	int  channelToPulse;
    NSArray* ncdPulseChannelsTaskObjects;
}

- (void)  updateWindow;

#pragma mark ¥¥¥Accessors
- (void) setPulseOneOnly:(BOOL)state;
- (void) channelToPulseAction:(id)sender;
- (void) cardToPulseAction:(id)sender;
- (void) setCardToPulse:(BOOL)state;
- (void) setChannelToPulse:(BOOL)state;
- (void) setAutoStart:(BOOL)state;
- (BOOL) autoStart;
- (void) setAutoStartForSourceRun:(BOOL)state;
- (BOOL) autoStartForSourceRun;

- (void) setUseNeutrinoRun:(BOOL)state;
- (BOOL) useNeutrinoRun;
- (float) neutrinoParam:(int)index;
- (void)setNeutrinoParam:(int)index value:(float)aValue; 
- (float) sourceParam:(int)index; 
- (void)setSourceParam:(int)index value:(float)aValue; 
- (int) neutrinoWaveform;
- (void) setNeutrinoWaveform:(int)aWaveform;
- (int) sourceWaveform;
- (void) setSourceWaveform:(int)aWaveform;

- (void)  setDefaults;

#pragma mark ¥¥¥Actions
- (void) pulseOneOnlyAction:(id)sender;
- (IBAction) neutrinoMatrixAction:(id)sender;
- (IBAction) sourceMatrixAction:(id)sender;
- (IBAction) neutrinoWaveformAction:(id)sender;
- (IBAction) sourceWaveformAction:(id)sender;
- (IBAction) autoStartAction:(id)sender;
- (IBAction) autoStartForSourceRunAction:(id)sender;

#pragma mark ¥¥¥Task Methods
- (void) prepare;
- (BOOL) doWork;
- (void) finishUp;
- (void) cleanUp;

@end

