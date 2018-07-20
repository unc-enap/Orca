//
//  ORMotorModel.h
//  Orca
//
//  Created by Mark Howe on Mon Feb 10 2003.
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


enum {
	kRaster		  = 0,
	kBackAndForth = 1
};

enum {
	kSyncWithRunOption  = 0,
	kStopRunOption      = 1,
	kShipPositionOption = 2
};

@interface ORMotorModel :  OrcaObject 
{
	@private

        BOOL absoluteMotion;
        int multiplierX;
        int riseFreq;
        int driveFreq;
        int acceleration;
		
        NSString* motorName;
        BOOL risingEdge;
        BOOL absoluteBrkPt;
        int breakPoint;
        int seekAmount;
        int xyPosition;
        int holdCurrent;
        int stepMode;
        int stepCount;

        BOOL useFileForPattern;
        NSString* patternFileName;
        
        //pattern params
        id patternStarter;
        int patternStartCount;
        int patternEndCount;
        int patternDeltaSteps;
        float patternDwellTime;
        int patternNumSweeps;
        int patternType;
        uint32_t optionMask;
		
        //non-persistant
        BOOL motorRunning;
        BOOL homeDetected;
        int32_t motorPosition;
        ORAlarm*    breakPointAlarm;
        id motorWorker;

        uint32_t dataId;
}

#pragma mark ¥¥¥Initialization
- (void) disconnectOtherMotors;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) runStarted:(NSNotification*)aNote;
- (void) runStopped:(NSNotification*)aNote;

#pragma mark ¥¥¥Accessors
- (NSString *)motorName;
- (void)setMotorName:(NSString *)aMotorName;

- (BOOL)useFileForPattern;
- (void)setUseFileForPattern:(BOOL)flag;
- (NSString *)patternFileName;
- (void)setPatternFileName:(NSString *)aPatternFileName;
- (int)  patternStartCount;
- (void) setPatternStartCount:(int)count;
- (int)  patternEndCount;
- (void) setPatternEndCount:(int)count;
- (int)  patternDeltaSteps;
- (void) setPatternDeltaSteps:(int)count;
- (float)  patternDwellTime;
- (void) setPatternDwellTime:(float)aTime;
- (int)  patternNumSweeps;
- (void) setPatternNumSweeps:(int)count;
- (int)  patternType;
- (void) setPatternType:(int)aType;
- (uint32_t)  optionMask;
- (void) setOptionMask:(uint32_t)aMask;
- (void) setOption:(int)anOption;
- (void) clearOption:(int)anOption;
- (BOOL) optionSet:(int)anOption;
- (void) setHomeDetected:(BOOL)flag;
- (void) setMotorRunning:(BOOL)flag;
- (void) setMotorPosition:(int32_t)aValue;
- (int)  holdCurrent;
- (void) setHoldCurrent:(int)aHoldCurrent;
- (int)  stepMode;
- (void) setStepMode:(int)aStepMode;
- (int)  xyPosition;
- (void) setXyPosition:(int)aPosition;
- (int)  seekAmount;
- (void) setSeekAmount:(int)aPosition;
- (BOOL) risingEdge;
- (void) setRisingEdge:(BOOL)flag;
- (int)  multiplierX;
- (void) setMultiplierX:(int)aMultiplier;
- (BOOL) absoluteMotion;
- (void) setAbsoluteMotion:(BOOL)aMotor;
- (int)  riseFreq;
- (void) setRiseFreq:(int)aRiseFreq;
- (int)  driveFreq;
- (void) setDriveFreq:(int)aDriveFreq;
- (int)  acceleration;
- (void) setAcceleration:(int)anAcceleration;
- (BOOL) absoluteBrkPt;
- (void) setAbsoluteBrkPt:(BOOL)flag;
- (int)  breakPoint;
- (void) setBreakPoint:(int)aPosition;
- (int)  stepCount;
- (void) setStepCount:(int)aPosition;
- (id)   motorWorker;
- (void) setMotorWorker:(id)aWorker;
- (void) roundPatternEnd;
- (id)   motorController;
- (BOOL) fourPhase;

#pragma mark ¥¥¥Hardware Access
- (BOOL) motorRunning;
- (int32_t) motorPosition;
- (BOOL) homeDetected;
- (void) incMotor;
- (void) decMotor;
- (void) moveMotor:(id)aMotor amount:(int32_t)amount;
- (void) moveMotor:(id)aMotor to:(int32_t)aPosition;
- (void)  readHome;
- (void) seekHome;
- (int32_t) readMotor;
- (void) startMotor;
- (void) stopMotor;
- (void) loadStepMode;
- (void) loadHoldCurrent;
- (void) loadStepCount;
- (void) loadBreakPoint;

- (BOOL) isMotorMoving;
- (BOOL) patternInProgress;
- (void) postBreakPointAlarm;

#pragma mark ¥¥¥RunControl Ops
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (NSDictionary*) dataRecordDescription;
- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherM361;

- (void) startPatternRun:(id)sender;
- (void) stopPatternRun:(id)sender;
- (void) finishedWork;
- (void) shipMotorState:(id)aWorker;
- (id)   makeWorker;
- (void) motorStarted;
- (void) motorStopped;
- (BOOL) inhibited;
- (void) setInhibited:(BOOL)aFlag;

@end

@interface NSObject (ORMotorModelOrcaObject)
- (int)crateNumber;
- (int)slot;
@end

@interface NSObject (ORMotorModel)
- (void) loadBreakPoint:(int)amount absolute:(BOOL)useAbs motor:(id)aMotor;
- (void) loadStepCount:(int32_t)amount motor:(id)aMotor;
- (void) readMotor:(id)aMotor;
- (BOOL) isMotorMoving:(id)aMotor;
- (void) moveMotor:(id)aMotor amount:(int32_t)amount;
- (void) moveMotor:(id)aMotor to:(int32_t)amount;
- (void) seekHome:(int32_t)amount motor:(id)aMotor;
- (void) readHome:(id)aMotor;
- (void) stopMotor:(id)aMotor;
- (void) startMotor:(id)aMotor;
- (void) loadHoldCurrent:(int32_t)amount motor:(id)aMotor;
- (void) loadStepMode:(int)mode motor:(id)aMotor;
- (void) setMotorPosition:(int32_t)aValue;
- (void) shipMotorState:(id)aWorker index:(int)index;
- (void) setMotorRunning:(BOOL)flag;
- (void) motorStarted;
- (void) motorStopped;
- (void) assignTag:(id)aMotor;
@end

extern NSString* ORMotorRiseFreqChangedNotification;
extern NSString* ORMotorDriveFreqChangedNotification;
extern NSString* ORMotorAccelerationChangedNotification;
extern NSString* ORMotorPositionChangedNotification;
extern NSString* ORMotorWhichMotorChangedNotification;
extern NSString* ORMotorAbsoluteMotionChangedNotification;
extern NSString* ORMotorMultiplierChangedNotification;
extern NSString* ORMotorRisingEdgeChangedNotification;
extern NSString* ORMotorStepModeChangedNotification;
extern NSString* ORMotorHoldCurrentChangedNotification;
extern NSString* ORMotorBreakPointChangedNotification;
extern NSString* ORMotorAbsoluteBrkPtChangedNotification;
extern NSString* ORMotorStepCountChangedNotification;
extern NSString* ORMotorMotorRunningChangedNotification;
extern NSString* ORMotorMotorPositionChangedNotification;
extern NSString* ORMotorHomeDetectedChangedNotification;
extern NSString* ORMotorSeekAmountChangedNotification;
extern NSString* ORMotorPatternChangedNotification;
extern NSString* ORMotorPatternFileNameChangedNotification;
extern NSString* ORMotorUsePatternFileChangedNotification;
extern NSString* ORMotorOptionsMaskChangedNotification;
extern NSString* ORMotorMotorWorkerChangedNotification;
extern NSString* ORMotorPatternTypeChangedNotification;
extern NSString* ORMotorMotorNameChangedNotification;

