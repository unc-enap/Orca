
//
//  NcdThresholdTask.h
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

@interface NcdThresholdTask : ORTask
{

    IBOutlet NSTextField* timeField;
    IBOutlet NSStepper* timeStepper;
    IBOutlet NSTextField* burstRateField;
    IBOutlet NSStepper* burstRateStepper;
    IBOutlet NSTextField* widthField;
    IBOutlet NSStepper* widthStepper;
    IBOutlet NSTextField* startAmplitudeField;
    IBOutlet NSStepper* startAmplitudeStepper;
    IBOutlet NSTextField* endAmplitudeField;
    IBOutlet NSStepper* endAmplitudeStepper;

    IBOutlet NSTextField* numValuesField;
    IBOutlet NSStepper* numValuesStepper;
    IBOutlet NSPopUpButton* selectionPopUpButton;	
    IBOutlet NSButton* doAllButton;	
    
    id stepTask;
    id thePDSModel;
    id thePulserModel;
    int timeOnOneChannel;
    float startAmplitude;
    float endAmplitude;
    float burstRate;
    float width;
    int numOfValues;
    NSData* pulserMemento;
    NSData* pdsMemento;
        
    NSDate* lastTime;
    int currentStep;
    int selectedWaveform;
    BOOL doAllChannels;
    NSArray* ncdThresholdTaskObjects;
}

- (int) doAllChannels;
- (void) setDoAllChannels:(int)state;
- (int)     selectedWaveform;
- (void)    setSelectedWaveform:(int)newSelectedWaveform;
- (int)     timeOnOneChannel;
- (void)    setTimeOnOneChannel:(int)aTimeOnOneChannel;
- (float)   startAmplitude;
- (void)    setStartAmplitude:(float)anAmplitude;
- (float)   endAmplitude;
- (void)    setEndAmplitude:(float)anAmplitude;
- (float)   burstRate;
- (void)    setBurstRate:(float)aBurstRate;
- (float)   width;
- (void)    setWidth:(CGFloat)aWidth;
- (int)     numOfValues;
- (void)    setNumOfValues:(int)aNumOfValues;
- (void)    setDefaults;

#pragma mark ¥¥¥Actions
- (IBAction) timeAction:(id)sender;
- (IBAction) startAmplitudeAction:(id)sender;
- (IBAction) endAmplitudeAction:(id)sender;
- (IBAction) burstRateAction:(id)sender;
- (IBAction) widthAction:(id)sender;
- (IBAction) numOfValuesAction:(id)sender;
- (IBAction) selectWaveformAction:(id)sender;
- (IBAction) doAllChannelsAction:(id)sender;

#pragma mark ¥¥¥Task Methods
- (void) prepare;
- (BOOL) doWork;
- (void) finishUp;
- (void) cleanUp;
@end

