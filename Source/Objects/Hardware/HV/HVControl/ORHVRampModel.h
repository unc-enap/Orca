//
//  ORHVRampModel.h
//  Orca
//
//  Created by Mark Howe on Thu Mar 06 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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

#pragma mark ¥¥¥Forward Declarations
@class ORHVSupply;
@class ORAlarm;
@class ORDataPacket;

@interface ORHVRampModel : OrcaObject  {
    NSMutableArray*	supplies;
    NSTimeInterval	pollingState;
    ORAlarm*		hvPowerCycleAlarm;
    ORAlarm*		hvNoCurrentCheckAlarm;
    ORAlarm*		hvNoLowPowerAlarm;
    NSString* 		dirName;

    NSTimer*		rampTimer;
    BOOL			hasBeenPolled;
    BOOL			saveCurrentToFile;
    NSString*		currentFile;
    NSMutableArray* currentTrends;
	NSDate*			lastTrendSnapShot;
}

#pragma mark ¥¥¥Initialization
- (void) makeSupplies;
- (void) initializeStates;

#pragma mark ¥¥¥Accessors
- (NSMutableArray*) currentTrends;
- (void) setCurrentTrends:(NSMutableArray*)aCurrentTrends;
- (NSString*) currentFile;
- (void) setCurrentFile:(NSString*)aCurrentFile;
- (BOOL) saveCurrentToFile;
- (void) setSaveCurrentToFile:(BOOL)aSaveCurrentToFile;
- (NSMutableArray*) supplies;
- (void) setSupplies:(NSMutableArray*)someSupplies;
- (ORHVSupply*) supply:(int)index;
- (void) setStates:(int)aState onlyControlled:(BOOL)onlyControlled;
- (id) 	interfaceObj;
- (void) setPollingState:(NSTimeInterval)aState;
- (NSTimeInterval) pollingState;
- (void) setDirName:(NSString*)aDirName;
- (NSString*) dirName;
- (NSTimer *) rampTimer;
- (BOOL) hasBeenPolled;

#pragma mark ¥¥¥Hardware Access
- (void) turnOnSupplies:(BOOL)aState;
- (void) resetAdcs;
- (void) doRamp;

#pragma mark ¥¥¥Status
-(unsigned short) relayOnMask;
- (BOOL) anyControlledSupplies;
- (BOOL) anyRelaysSetOnControlledSupplies;
- (BOOL) anyVoltageOnControlledSupplies;
- (BOOL) allRelaysSetOnControlledSupplies;
- (BOOL) allRelaysOffOnControlledSupplies;
- (BOOL) voltageOnAllControlledSupplies;
- (BOOL) anyRelaysSetOn;
- (BOOL) anyVoltageOn;
- (BOOL) powerCycled;

// read/write status access methods
- (BOOL) controlled:(short) aSupplyIndex;
- (void) setControlled:(short) aSupplyIndex value:(BOOL)aState;
- (int)  rampTime:(short) aSupplyIndex;
- (void)  setRampTime:(short) aSupplyIndex value:(int)aValue;
- (int)  targetVoltage:(short) aSupplyIndex;
- (void)  setTargetVoltage:(short) aSupplyIndex value:(int)aValue;
//read only supply methods
- (int)  dacValue:(short) aSupplyIndex;
- (int)  adcVoltage:(short) aSupplyIndex;
- (int)  current:(short) aSupplyIndex;
- (int) rampState:(short) aSupplyIndex;
- (NSString*) stateFileName;



#pragma mark ¥¥¥Archival
- (void)loadHVParams;
- (void)saveHVParams;

#pragma mark ¥¥¥Safety Check
- (BOOL) checkActualVsSetValues;
- (void) resolveActualVsSetValueProblem;
- (void) forceDacToAdc;
- (void) checkAdcDacMismatch:(ORHVSupply*) aSupply;
- (void) checkCurrent:(ORHVSupply*) aSupply;
- (void) panic;

#pragma mark ¥¥¥Run Data
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;


#pragma mark ¥¥¥Ramp
- (void) startRamping;
- (void) stopRamping;

#pragma mark ¥¥¥Polling
- (void) pollHardware:(ORHVRampModel*)theModel;

- (int) currentTrendCount:(int)index;
- (float) currentValue:(int)index supply:(int)aSupplyIndex;

@end

@interface NSObject (HVRampModel)
- (void) readPowerAndRelayState;
@end


#pragma mark ¥¥¥Notification Strings
extern NSString* ORHVRampModelUpdatedTrends;
extern NSString* ORHVRampModelCurrentFileChanged;
extern NSString* ORHVRampModelSaveCurrentToFileChanged;
extern NSString* HVPollingStateChangedNotification;
extern NSString* HVStateFileDirChangedNotification;
extern NSString* HVRampStartedNotification;
extern NSString* HVRampStoppedNotification;
extern NSString* HVRampCalibrationLock;
extern NSString* HVRampLock;
