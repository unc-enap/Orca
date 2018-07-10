//
//  NcdMuxBoxModel.h
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files

#import "ORHWWizard.h"
#import "ThresholdCalibrationTask.h"

#pragma mark ¥¥¥Forward Declarations

#define kNumMuxChannels 13

@class ORRateGroup;

@interface NcdMuxBoxModel : OrcaObject <ORHWWizard,ORHWRamping,ThresholdCalibration> {
    @private
        NSMutableArray*  thresholdDacs;
        NSMutableArray*  thresholdAdcs;
        
        ORRateGroup*	rateGroup;
        unsigned long 	rateCount[kNumMuxChannels];
        
        NSMutableDictionary* rateAttributes;
        NSMutableDictionary* totalRateAttributes;
        NSMutableDictionary* timeRateXAttributes;
        NSMutableDictionary* timeRateYAttributes;
        unsigned short  busNumber;
	
		unsigned short dacValue;
		unsigned short selectedChannel;
		short scopeChan;
		
		unsigned short calibrationEnabledMask;
		int calibrationFinalDelta;
		ThresholdCalibrationTask* calibrationTask;
		NSMutableArray*  thresholdCalibrationStates;
        
        short oldThresholdDacs[kNumMuxChannels];
}

#pragma mark ¥¥¥Accessors
- (NSMutableArray*) 	thresholdDacs;
- (void) 		setThresholdDacs:(NSMutableArray*)someThresholds;
- (NSMutableArray*) 	thresholdAdcs;
- (void) 		setThresholdAdcs:(NSMutableArray*)someThresholds;
- (void) 		setThresholdAdc:(unsigned short) aChan withValue:(short) aValue;
- (unsigned short)  	thresholdDac:(unsigned short) aChan;
- (unsigned short)  	thresholdAdc:(unsigned short) aChan;
- (void) 		setThresholdDac:(unsigned short) aChan withValue:(unsigned short) aThreshold;
- (int)			muxID;
- (ORRateGroup*) 	rateGroup;
- (void)                setRateGroup:(ORRateGroup*)newrateGroup;
- (NSMutableDictionary*) rateAttributes;
- (void)                 setRateAttributes:(NSMutableDictionary*)newRateAttributes;
- (NSMutableDictionary*) totalRateAttributes;
- (void)                 setTotalRateAttributes:(NSMutableDictionary*)newTotalRateAttributes;
- (NSMutableDictionary*) timeRateXAttributes;
- (void)                 setTimeRateXAttributes:(NSMutableDictionary*)newTimeRateXAttributes;
- (NSMutableDictionary*) timeRateYAttributes;
- (void)                 setTimeRateYAttributes:(NSMutableDictionary*)newTimeRateYAttributes;
- (unsigned long)        rateCount:(unsigned short)index;
- (unsigned short)       busNumber;
- (void)                 setBusNumber:(unsigned short)newBusNumber;
- (int)			 scopeChan;
- (void)		 setScopeChan:(int)aNewScopeChan;

- (unsigned short)       calibrationEnabledMask;
- (void)		 setCalibrationEnabledMask:(unsigned short)aCalibrationEnabledMask;
- (int)			 calibrationFinalDelta;
- (void)		 setCalibrationFinalDelta:(int)aCalibrationFinalDelta;
- (ThresholdCalibrationTask *)calibrationTask;
- (void)		 setCalibrationTask:(ThresholdCalibrationTask *)aCalibrationTask;
- (NSMutableArray *)     thresholdCalibrationStates;
- (void)		 setThresholdCalibrationStates:(NSMutableArray *)aThresholdCalibrationStates;
- (void) saveAllThresholds;
- (void) restoreAllThresholds;
- (void) setAllThresholdsTo:(NSNumber*)aThresholdNumber;

#pragma mark ¥¥¥Hardware Access
- (void) loadThresholdDacs;
- (void) writeThresholdDac:(unsigned short)chan withValue:(unsigned short)aValue;
- (void) initMux;
- (void) readThresholds;
- (void) readThreshold:(unsigned short) aChannel;
- (void) runMuxBitTest;
- (void) statusQuery;
- (void) ping;
- (void) reArm;
- (void) readEventReg;
- (void) readAdcValue;
- (void) readAdcValue;
- (void) writeDacValue;
- (void) checkThresholds;

#pragma mark ¥¥¥Rates
- (void)	  startRates;
- (void)	  stopRates;
- (void)	  incChanCounts:(unsigned short)chanMask;
- (unsigned long) getCounter:(int)tag forGroup:(int)groupTag;

#pragma mark ¥¥¥Testing
- (unsigned short)dacValue;
- (void)setDacValue:(unsigned short)aDacValue;

- (unsigned short)selectedChannel;
- (void)setSelectedChannel:(unsigned short)aSelectedChannel; 

#pragma mark ¥¥¥Calibration
- (void) loadCalibrationValues;
- (void) calibrate;
- (void) setThresholdCalibration:(int)channel state:(NSString*)aString;
- (NSString*) thresholdCalibration:(int)channel;

#pragma mark ¥¥¥HW Wizard
- (NSArray*) wizardSelections;
- (NSArray*) wizardParameters;
- (int) numberOfChannels;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

#pragma mark ¥¥¥Archival
- (id)      initWithCoder:(NSCoder*)aDecoder;
- (void)    encodeWithCoder:(NSCoder*)anEncoder;
- (void)    loadMemento:(NSCoder*)decoder;
- (void)    saveMemento:(NSCoder*)anEncoder;
- (NSData*) memento;
- (void)    restoreFromMemento:(NSData*)aMemento;

@end

#pragma mark ¥¥¥External Strings
extern NSString* NcdMuxChan;
extern NSString* NcdThresholdDacChangedNotification;
extern NSString* NcdMuxDacArrayChangedNotification;
extern NSString* NcdMuxAdcThresChangedNotification;
extern NSString* ORMuxBoxRateChangedNotification;
extern NSString* ORMuxBoxTotalRateChangedNotification;
extern NSString* ORMuxBoxTimeRateXChangedNotification;
extern NSString* ORMuxBoxTimeRateYChangedNotification;

extern NSString* ORMuxBoxRateGroupChangedNotification;
extern NSString* ORMuxBoxRateGroupChangedNotification;
extern NSString* ORMuxBoxBusNumberChangedNotification;

extern NSString* ORMuxBoxChannelSelectionChangedNotification;
extern NSString* ORMuxBoxDacValueChangedNotification;
extern NSString* ORNcdMuxBoxScopeChanChangedNotification;

extern NSString* ORMuxBoxCalibrationEnabledMaskChanged;
extern NSString* ORMuxBoxCalibrationFinalDeltaChanged;
extern NSString* ORMuxBoxCalibrationTaskChanged;
extern NSString* NcdMuxCalibrationStateChanged;

extern NSString* NcdMuxStateChannel;

extern NSString* NcdMuxBoxSettingsLock;
extern NSString* NcdMuxBoxCalibrationLock;
extern NSString* NcdMuxBoxTestLock;