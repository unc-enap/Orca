//
//  ODetectorRamper.h
//  Orca
//
//  Created by Mark Howe on Friday May 25,2012
//  Copyright (c) 2012 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
@class ORAlarm;
@class ORiSegHVCard;

@interface ORDetectorRamper : NSObject {
	ORiSegHVCard*		delegate;
	short				channel;
    
    //user parameters
	short	stepWait;
	short	lowVoltageWait;
	int		lowVoltageThreshold;
	int		voltageStep;
	int		lowVoltageStep;
	int		maxVoltage;
	int		minVoltage;
	BOOL	enabled;
    ORAlarm* rampFailedAlarm;
	
	//ramp state variables
	float   lastVoltage;
	int		target;
	BOOL    running;
	int     state;
	NSDate* lastStepWaitTime;
	NSDate* lastVoltageWaitTime;
}

- (id) initWithDelegate:(id)aDelegate channel:(int)aChannel;
- (void) startRamping;
- (void) stopRamping;
- (void) emergencyOff;
- (void) setStepWait:(short)aValue;
- (void) setLowVoltageWait:(short)aValue;
- (void) setLowVoltageThreshold:(int)aValue;
- (void) setLowVoltageStep:(int)aValue;
- (void) setMaxVoltage:(int)aValue;
- (void) setMinVoltage:(int)aValue;
- (void) setVoltageStep:(int)aValue;
- (void) setEnabled:(BOOL)aValue;
- (NSString*) stateString;
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
- (NSString*) hwGoalString;
- (void) execute;
- (void) setRunning:(BOOL)aValue;
- (void) setState:(int)aValue;

@property (nonatomic,assign) ORiSegHVCard* delegate;
@property (nonatomic,assign) short channel;
@property (nonatomic,assign) short stepWait;
@property (nonatomic,assign) int target;
@property (nonatomic,assign) int lowVoltageThreshold;
@property (nonatomic,assign) int voltageStep;
@property (nonatomic,assign) short lowVoltageWait;
@property (nonatomic,assign) int lowVoltageStep;
@property (nonatomic,assign) int maxVoltage;
@property (nonatomic,assign) int minVoltage;
@property (nonatomic,assign) BOOL enabled;
@property (nonatomic,assign) BOOL running;
@property (nonatomic,assign) int state;
@property (nonatomic,retain) NSDate* lastStepWaitTime;
@property (nonatomic,retain) NSDate* lastVoltageWaitTime;
@end

extern NSString* ORDetectorRamperStepWaitChanged;
extern NSString* ORDetectorRamperLowVoltageWaitChanged;
extern NSString* ORDetectorRamperLowVoltageThresholdChanged;
extern NSString* ORDetectorRamperLowVoltageStepChanged;
extern NSString* ORDetectorRamperMaxVoltageChanged;
extern NSString* ORDetectorRamperMinVoltageChanged;
extern NSString* ORDetectorRamperVoltageStepChanged;
extern NSString* ORDetectorRamperEnabledChanged;
extern NSString* ORDetectorRamperStateChanged;
extern NSString* ORDetectorRamperRunningChanged;

