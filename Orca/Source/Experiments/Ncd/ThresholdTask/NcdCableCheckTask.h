
//
//  NcdCableCheckTask.h
//  Orca
//
//  Created by Mark Howe on Oct 8, 2004.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
//

#import <Cocoa/Cocoa.h>
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
    unsigned long startingShaperCounts;
    
    NcdMuxBoxModel* currentMux;
    int currentMuxChannel;
    unsigned long startingMuxCounts;

    NSArray* currentScopes;
    int currentScopeChannel;
    unsigned long startingScopeCounts;

    unsigned short oldMuxThreshold;
    unsigned short muxThreshold;
    unsigned short oldShaperThreshold;
    unsigned short shaperThreshold;
    unsigned short startingCount;
    
    ORAlarm*    failedAlarm;
    BOOL        verbose;
    BOOL           pdsInRange;
    unsigned short shaperResult;
    unsigned short muxResult;
    unsigned short scopeResult;
    
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
- (void)setWidth:(float)aWidth;
- (int) numPulses;
- (void) setNumPulses: (int) aNumPulses;
- (unsigned short) oldMuxThreshold;
- (void) setOldMuxThreshold: (unsigned short) anOldMuxThreshold;
- (unsigned short) muxThreshold;
- (void) setMuxThreshold: (unsigned short) aMuxThreshold;
- (unsigned short) oldShaperThreshold;
- (void) setOldShaperThreshold: (unsigned short) anOldShaperThreshold;
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
- (BOOL)   doWork;
- (void) finishUp;
@end

