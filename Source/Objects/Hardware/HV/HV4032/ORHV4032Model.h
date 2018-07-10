//
//  ORHV4032Model.h
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
@class ORHV4032Supply;
@class ORAlarm;
@class ORDataPacket;

#define kHV4032NumberSupplies 32


@interface ORHV4032Model : OrcaObject  {
    NSMutableArray*	supplies;
    NSTimeInterval	pollingState;
    ORAlarm*		hvNoPollingAlarm;

    NSTimer*		rampTimer;
    BOOL			hasBeenPolled;
    BOOL			hvState;
}

#pragma mark ¥¥¥Initialization
- (void) makeSupplies;
- (void) initializeStates;
- (void) registerNotificationObservers;
- (void) wakeUp;
- (void) sleep;
- (void) voltageChangedAtController:(NSNotification*)aNote;
- (void) onOffStateChangedAtController:(NSNotification*)aNote;

#pragma mark ¥¥¥Accessors
- (BOOL) hvState;
- (void) setHvState:(BOOL)aHvState;
- (NSMutableArray*) supplies;
- (void) setSupplies:(NSMutableArray*)someSupplies;
- (ORHV4032Supply*) supply:(int)index;
- (void) setStates:(int)aState onlyControlled:(BOOL)onlyControlled;
- (void) setPollingState:(NSTimeInterval)aState;
- (NSTimeInterval) pollingState;
- (NSTimer *) rampTimer;
- (BOOL) hasBeenPolled;
- (id) getHVController;
- (void) setMainFrameID:(unsigned long)anIdNumber;
- (unsigned long) mainFrameID;

#pragma mark ¥¥¥Hardware Access
- (void) turnHVOn:(BOOL)aState;

#pragma mark ¥¥¥Status
- (BOOL) hvOn;
- (BOOL) anyControlledSupplies;
- (BOOL) significantVoltagePresent;

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
- (int) rampState:(short) aSupplyIndex;
- (void) readAdc:(ORHV4032Supply*)aSupply;
- (void) setVoltage:(int)aVoltage supply:(ORHV4032Supply*)aSupply;



#pragma mark ¥¥¥Archival
- (void)saveHVParams;
- (void)loadHVParams;

#pragma mark ¥¥¥Safety Check
- (BOOL) checkActualVsSetValues;
- (void) resolveActualVsSetValueProblem;
- (void) forceDacToAdc;
- (void) checkAdcDacMismatch:(ORHV4032Supply*) aSupply;
- (void) panic;

#pragma mark ¥¥¥Run Data
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;


#pragma mark ¥¥¥Ramp
- (void) startRamping;
- (void) stopRamping;
- (void) doRamp;

#pragma mark ¥¥¥Polling
- (void) pollHardware;

@end

@interface NSObject (HV4032Model)
- (void) readPowerState;
- (void) setHV:(BOOL)state mainFrame:(int)aMainFrame;
- (void) readStatus:(int*) aValue failedMask:(unsigned short*)failed mainFrame:(int) aMainFrame;
- (void) readVoltage:(int*) aValue mainFrame:(int) aMainFrame channel:(int) aChannel;
- (void) setVoltage:(int) aValue mainFrame:(int) aMainFrame channel:(int) aChannel;

@end


#pragma mark ¥¥¥Notification Strings
extern NSString* ORHV4032ModelHvStateChanged;
extern NSString* HV4032PollingStateChangedNotification;
extern NSString* HV4032StartedNotification;
extern NSString* HV4032StoppedNotification;
extern NSString* HV4032CalibrationLock;
extern NSString* HV4032Lock;
