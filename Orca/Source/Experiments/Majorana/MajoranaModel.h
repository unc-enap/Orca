//
//  MajoranaModel.h
//  Orca
//
//  Created by Mark Howe on Tue Apr 20, 2010.
//  Copyright (c) 2010  University of North Carolina. All rights reserved.
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
#import "ORExperimentModel.h"
#import "OROrderedObjHolding.h"

#define kUseDetectorView    0
#define kUseCrateView       1
#define kNumDetectors       2*35*2 //2 cryostats of 35 detectors * 2 (low and hi channels)
#define kNumVetoSegments    32
#define kMaxNumStrings      14
#define kNumSpecialChannels 24

//component tag numbers
#define kVacAComponent		 0
#define kVacBComponent		 1

@class ORRemoteSocketModel;
@class ORAlarm;
@class ORMJDInterlocks;
@class ORMJDSource;
@class ORMJDHeaderRecordID;
@class ORRunModel;
@class ORHighRateChecker;

@interface MajoranaModel :  ORExperimentModel <OROrderedObjHolding>
{
	int             viewType;
    int             pollTime;
    NSDate*         lastConstraintCheck;
    NSMutableArray* stringMap;
    NSMutableArray* specialMap;
    ORAlarm*        rampHVAlarm[2];
    ORAlarm*        breakdownAlarm[2];
    BOOL            ignorePanicOnA;
    BOOL            ignorePanicOnB;
    BOOL            ignoreBreakdownPanicOnA;
    BOOL            ignoreBreakdownPanicOnB;
    BOOL            ignoreBreakdownCheckOnA;
    BOOL            ignoreBreakdownCheckOnB;
    unsigned long   runType;
    ORMJDHeaderRecordID* anObjForCouchID;
    ORMJDInterlocks*     mjdInterlocks[2];
    ORMJDSource*         mjdSource[2];
    NSDate*              rateSpikeTime[2];
    BOOL                 rateReportSent[2];
    NSMutableDictionary* rateSpikes[2];
    NSMutableDictionary* baselineExcursions[2];
    float maxNonCalibrationRate;
    ORHighRateChecker*    highRateChecker;
    BOOL scheduledToRunCheckBreakdown;
    BOOL testfillingLN[2];
    BOOL verboseDiagnostics;
    int  minNumDetsToAlertExperts;
    NSString* calibrationStatus;
}

#pragma mark ¥¥¥Accessors
- (BOOL) verboseDiagnostics;
- (void) setVerboseDiagnostics:(BOOL)aState;
- (NSDate*) lastConstraintCheck;
- (void) setLastConstraintCheck:(NSDate*)aDate;
- (BOOL) ignorePanicOnB;
- (void) setIgnorePanicOnB:(BOOL)aIgnorePanicOnB;
- (BOOL) ignorePanicOnA;
- (void) setIgnorePanicOnA:(BOOL)aIgnorePanicOnA;

- (BOOL) ignoreBreakdownPanicOnB;
- (void) setIgnoreBreakdownPanicOnB:(BOOL)aIgnorePanicOnB;
- (BOOL) ignoreBreakdownPanicOnA;
- (void) setIgnoreBreakdownPanicOnA:(BOOL)aIgnorePanicOnA;
- (BOOL) ignoreBreakdownCheckOnB;
- (void) setIgnoreBreakdownCheckOnB:(BOOL)aIgnorePanicOnB;
- (BOOL) ignoreBreakdownCheckOnA;
- (void) setIgnoreBreakdownCheckOnA:(BOOL)aIgnorePanicOnA;

- (void) getRunType:(ORRunModel*)rc;
- (int)  pollTime;
- (void) setPollTime:(int)aPollTime;
- (void) setViewType:(int)aViewType;
- (int) viewType;
- (ORRemoteSocketModel*) remoteSocket:(int)aVMECrate;
- (BOOL) anyHvOnVMECrate:(int)aVMECrate;
- (void) setVmeCrateHVConstraint:(int)aCrate state:(BOOL)aState;

- (id) mjdInterlocks:(int)index;
- (void) runTypeChanged:(NSNotification*) aNote;
- (void) runStarted:(NSNotification*) aNote;
- (void) hvInfoRequest:(NSNotification*)aNote;
- (void) customInfoRequest:(NSNotification*)aNote;
- (void) setDetectorStringPositions;
- (NSString*) detectorLocation:(int)index;
- (NSString*) objectNameForCrate:(NSString*)aCrateName andCard:(NSString*)aCardName;
- (float) maxNonCalibrationRate;
- (void) setMaxNonCalibrationRate:(float)aValue;
- (void) delayedRemoveBaselineExcursion:(NSString*)aBigKey;
- (int) countCommonSpikes:(int)index;
- (void) alertExperts:(int)index;
- (void) resetSpikeDictionaries;
- (int)  minNumDetsToAlertExperts;
- (void)  setMinNumDetsToAlertExperts:(int)aValue;

#pragma mark ¥¥¥Breakdown Methods
- (BOOL) matchingRateAndBaselineIssues:(unsigned short)index;
- (void) rateSpike:(NSNotification*) aNote;
- (NSDictionary*) rateSpikes:(unsigned short)index;
- (void) baselineSpike:(NSNotification*) aNote;
- (void) setRateSpikeTime:(unsigned short) index time:(NSDate*)aDate;
- (BOOL) breakdownConditionsMet:(unsigned short)index;
- (void) rampDownChannelsWithBreakdown:(int)module vac:(int)aVacSystem;
- (BOOL) vacuumSpike:(unsigned short)index;
- (BOOL) fillingLN:(unsigned short)index;
- (NSTimeInterval) pollingTimeForLN:(unsigned short)index;
- (void) constraintCheckFinished:(int)index;
- (NSString*) checkForBreakdown:(unsigned short)module vacSystem:(unsigned short)aVacSystem;
- (NSDictionary*) baselineExcursions:(unsigned short)index;
- (BOOL) breakdownAlarmPosted:(unsigned short)alarmIndex;
- (void) clearBreakdownAlarm:(unsigned short)index;
- (BOOL) calibrationRun:(unsigned short)index;
- (BOOL) rateSpikesValid:(unsigned short)index;
- (NSString*) rateSpikeReport:(unsigned short)index;
- (NSString*) baselineExcursionReport:(unsigned short)index;
- (void) rampDownHV:(int)aCrate vac:(int)aVacSystem;
- (void) printBreakDownReport;
- (NSString*) fullBreakDownReport:(unsigned short)index;
- (void) scheduleConstraintCheck;
- (void) forceConstraintCheck;

#pragma mark ¥¥¥Segment Group Methods
- (void) makeSegmentGroups;
- (NSString*) getValueForPartStartingWith:(NSString*)aLabel parts:(NSArray*)parts;
- (id)   stringMap:(int)i objectForKey:(id)aKey;
- (void) stringMap:(int)i setObject:(id)anObject forKey:(id)aKey;
- (BOOL) validateSegmentParam:(NSString*)aParam;
- (NSString*) stringMapFileAsString;
- (NSString*) specialMapFileAsString;
- (BOOL) validateDetector:(int)aDetectorIndex;
- (id)   specialMap:(int)i objectForKey:(id)aKey;
- (void) specialMap:(int)i setObject:(id)anObject forKey:(id)aKey;
- (void) initDigitizers;
- (void) initVeto;

#pragma mark ¥¥¥Specific Dialog Lock Methods
- (NSString*) experimentMapLock;
- (NSString*) vetoMapLock;
- (NSString*) experimentDetectorLock;
- (NSString*) experimentDetailsLock;
- (NSString*) calibrationLock;

#pragma mark ¥¥¥OROrderedObjHolding Protocol
- (int) maxNumberOfObjects;
- (int) objWidth;
- (int) groupSeparation;
- (NSString*) nameForSlot:(int)aSlot;
- (NSRange) legalSlotsForObj:(id)anObj;
- (int) slotAtPoint:(NSPoint)aPoint;
- (NSPoint) pointForSlot:(int)aSlot;
- (void) place:(id)anObj intoSlot:(int)aSlot;
- (int) slotForObj:(id)anObj;
- (int) numberSlotsNeededFor:(id)anObj;

#pragma mark ¥¥¥Source
- (id)   mjdSource:(int)index;
- (void) deploySource:(int)index;
- (void) retractSource:(int)index;
- (void) stopSource:(int)index;
- (void) checkSourceGateValve:(int)index;
- (NSString*) calibrationStatus;
- (void) setCalibrationStatus:(NSString*)aString;

#pragma mark ¥¥¥Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* MajoranaModelIgnoreBreakdownPanicOnBChanged;
extern NSString* MajoranaModelIgnoreBreakdownPanicOnAChanged;
extern NSString* MajoranaModelIgnoreBreakdownCheckOnBChanged;
extern NSString* MajoranaModelIgnoreBreakdownCheckOnAChanged;
extern NSString* MajoranaModelIgnorePanicOnBChanged;
extern NSString* MajoranaModelIgnorePanicOnAChanged;
extern NSString* ORMajoranaModelViewTypeChanged;
extern NSString* ORMajoranaModelPollTimeChanged;
extern NSString* ORMJDAuxTablesChanged;
extern NSString* ORMajoranaModelLastConstraintCheckChanged;
extern NSString* ORMajoranaModelUpdateSpikeDisplay;
extern NSString* ORMajoranaModelMaxNonCalibrationRate;
extern NSString* ORMajoranaModelVerboseDiagnosticsChanged;
extern NSString* ORMajoranaModelMinNumDetsToAlertExperts;
extern NSString* ORMajoranaModelCalibrationStatusChanged;

@interface ORMJDHeaderRecordID : NSObject
- (NSString*) fullID;
@end
