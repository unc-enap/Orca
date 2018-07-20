
//
//  NcdCableCheckTask.h
//  Orca
//
//  Created by Mark Howe on Oct 8, 2004.
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

@class ORAlarm;
@class NcdTube;
@class ORShaperModel;
@class NcdMuxBoxModel;

@interface NcdCableCheckTask : ORTask
{

    IBOutlet NSTextField* widthField;
    IBOutlet NSStepper* widthStepper;
    IBOutlet NSTextField* amplitudeField;
    IBOutlet NSStepper* amplitudeStepper;
    IBOutlet NSTextField* numPulsesField;
    IBOutlet NSStepper* numPulsesStepper;
    IBOutlet NSTextField* shaperThresholdField;
    IBOutlet NSStepper* shaperThresholdStepper;
    IBOutlet NSTextField* muxThresholdField;
    IBOutlet NSStepper* muxThresholdStepper;
    IBOutlet NSButton* verboseButton;
    
    id thePDSModel;
    id thePulserModel;
    float amplitude;
    float width;
    int numPulses;
    NSData* pulserMemento;
    NSData* pdsMemento;
    NSDate* lastTime;
    NSMutableArray* tubeArray;
    NcdTube* currentTube;
    int phase;
    int pulseCount;
    BOOL passed;
    ORShaperModel* currentShaper;
    int currentShaperChannel;
    uint32_t startingShaperCounts;
    
    NcdMuxBoxModel* currentMux;
    int currentMuxChannel;
    uint32_t startingMuxCounts;

    NSArray* currentScopes;
    int currentScopeChannel;
    uint32_t startingScopeCounts;

    unsigned short oldMuxThreshold[13];
    unsigned short muxThreshold;
    unsigned short oldShaperThreshold[8];
    unsigned short shaperThreshold;
    
    ORAlarm*    failedAlarm;
    BOOL        verbose;
    BOOL           pdsInRange;
    unsigned short shaperResult;
    unsigned short muxResult;
    unsigned short scopeResult;
    unsigned short tubeIndex;
    NSArray* ncdCableCheckTaskObjects;
}

- (BOOL) verbose;
- (void) setVerbose: (BOOL) flag;
- (NSDate *) lastTime;
- (void) setLastTime: (NSDate *) aLastTime;
- (id) thePDSModel;
- (void) setThePDSModel: (id) aThePDSModel;
- (id) thePulserModel;
- (void) setThePulserModel: (id) aThePulserModel;
- (NcdTube *) currentTube;
- (void) setCurrentTube: (NcdTube *) aCurrentTube;
- (NSArray *) currentScopes;
- (void) setCurrentScopes: (NSArray *) aCurrentScopes;
- (NcdMuxBoxModel *) currentMux;
- (void) setCurrentMux: (NcdMuxBoxModel *) aCurrentMux;
- (ORShaperModel *) currentShaper;
- (void) setCurrentShaper: (ORShaperModel *) aCurrentShaper;
- (NSData *) pulserMemento;
- (void) setPulserMemento: (NSData *) aPulserMemento;
- (NSData *) pdsMemento;
- (void) setPdsMemento: (NSData *) aPdsMemento;
- (NSMutableArray *) tubeArray;
- (void) setTubeArray: (NSMutableArray *) aTubeArray;



- (float)amplitude;
- (void)setAmplitude:(float)anAmplitude;
- (float)width;
- (void)setWidth:(CGFloat)aWidth;
- (int) numPulses;
- (void) setNumPulses: (int) aNumPulses;
- (unsigned short) muxThreshold;
- (void) setMuxThreshold: (unsigned short) aMuxThreshold;
- (unsigned short) shaperThreshold;
- (void) setShaperThreshold: (unsigned short) aShaperThreshold;

- (void) setDefaults;

#pragma mark ¥¥¥Actions
- (IBAction) amplitudeAction:(id)sender;
- (IBAction) widthAction:(id)sender;
- (IBAction) numPulsesAction:(id)sender;
- (IBAction) shaperThresholdAction:(id)sender;
- (IBAction) muxThresholdAction:(id)sender;
- (IBAction) verboseAction:(id)sender;

#pragma mark ¥¥¥Task Methods
- (void) prepare;
- (BOOL) doWork;
- (void) finishUp;
- (void) cleanUp;

@end

