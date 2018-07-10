/*
 *  ORCVCfdLedModel.h
 *  Orca
 *
 *  Created by Mark Howe on Tuesday, June 7, 2011.
 *  Copyright (c) 2011 CENPA, University of North Carolina. All rights reserved.
 *
 */
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sonsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#import "ORVmeIOCard.h"

typedef struct RegisterNamesStruct {
	NSString*       regName;
	unsigned long 	addressOffset;
} CVCfcLedRegNamesStruct; 

// Class definition
@interface ORCVCfdLedModel : ORVmeIOCard
{
	unsigned short testPulse;
	unsigned short patternInhibit;
	unsigned short majorityThreshold;
	unsigned short deadTime0_7;
	unsigned short deadTime8_15;
	unsigned short outputWidth0_7;
	unsigned short outputWidth8_15;
    unsigned short  thresholds[16];
    BOOL autoInitWithRun;
}

#pragma mark ***Accessors
- (BOOL) autoInitWithRun;
- (void) setAutoInitWithRun:(BOOL)aAutoInitWithRun;
- (void) registerNotificationObservers;

- (unsigned short)	threshold: (unsigned short) anIndex;
- (void)		setThreshold: (unsigned short ) anIndex threshold: (unsigned short) aValue;
- (unsigned short) testPulse;
- (void) setTestPulse:(unsigned short)aTestPulse;
- (unsigned short) patternInhibit;
- (void) setPatternInhibit:(unsigned short)aPatternInhibit;
- (unsigned short) majorityThreshold;
- (void) setMajorityThreshold:(unsigned short)aMajorityThreshold;
- (unsigned short) outputWidth8_15;
- (void) setOutputWidth8_15:(unsigned short)aOutputWidth8_15;
- (unsigned short) outputWidth0_7;
- (void) setOutputWidth0_7:(unsigned short)aOutputWidth0_7;
- (BOOL)inhibitMaskBit:(int)bit;
- (void) setInhibitMaskBit:(int)bit withValue:(BOOL)aValue;
- (void) runABoutToStart:(NSNotification*)aNote;

#pragma mark ***HW Accesss
- (void) writeThreshold:(unsigned short) pChan;
- (void) writeOutputWidth0_7;
- (void) writeOutputWidth8_15;
- (void) writeTestPulse;
- (void) writePatternInhibit;
- (void) writeMajorityThreshold;
- (void) initBoard;
- (void) probeBoard;

#pragma mark ***subclass responsibility
- (unsigned short) numberOfRegisters;
- (unsigned long) regOffset:(int)index;
- (unsigned long) threshold0Offset;
- (unsigned long) outputWidth0_7Offset;
- (unsigned long) outputWidth8_15Offset; 
- (unsigned long) testPulseOffset; 
- (unsigned long) patternInibitOffset; 
- (unsigned long) majorityThresholdOffset; 
- (unsigned long) moduleTypeOffset; 
- (unsigned long) versionOffset; 

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end


extern NSString* ORCVCfdLedModelAutoInitWithRunChanged;
extern NSString* ORCVCfdLedModelSelectedRegIndexChanged;
extern NSString* ORCVCfdLedModelThresholdChanged;
extern NSString* ORCVCfdLedModelTestPulseChanged;
extern NSString* ORCVCfdLedModelPatternInhibitChanged;
extern NSString* ORCVCfdLedModelMajorityThresholdChanged;
extern NSString* ORCVCfdLedModelDeadTime0_7Changed;
extern NSString* ORCVCfdLedModelDeadTime8_15Changed;
extern NSString* ORCVCfdLedModelOutputWidth8_15Changed;
extern NSString* ORCVCfdLedModelOutputWidth0_7Changed;
extern NSString* ORCVCfdLedModelThresholdLock;
