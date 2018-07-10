//
//  ORDataTaskModel.h
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
#import "ORSafeQueue.h"
#import "ORDataChainObject.h"

#pragma mark ¥¥¥Forward Declarations
@class ORDataPacket;
@class ORReadOutList;
@class ORDataSet;
@class ORTimer;
@class ORDecoder;
@class ORDataChainObject;

#define kTimeHistoSize 4000

@class ORAlarm;

@interface ORDataTaskModel : ORDataChainObject  {
    ORReadOutList*  readOutList;
    ORDataChainObject*  nextObject;     //cache for alittle bit more speed.
    NSArray*        dataTakers;     //cache of data takers.
    unsigned long   queueCount;
    
    ORSafeQueue*    transferQueue;
    ORDecoder*      theDecoder;
	
    ORAlarm*	    queueFullAlarm;
    NSString*       lastFile;
    ORSafeQueue*	recordsPending;
	BOOL			areRecordsPending;
    
    ORTimer* dataTimer;
    ORTimer* mainTimer;
    unsigned long dataTimeHist[kTimeHistoSize];
    unsigned long processingTimeHist[kTimeHistoSize];
     
    clock_t			runStartTime;
	struct tms		runStartTmsTime;
	short			timeScaler;
	BOOL			enableTimer;
	unsigned long	cycleCount;
	unsigned long	cycleRate;
    unsigned long   cachedNumberDataTakers;
	id*				cachedDataTakers;
	
    BOOL timeToStopProcessThread;
	BOOL processThreadRunning;
	
    NSLock*			 timerLock;
	//hints
	unsigned long queAddCount;
	unsigned long lastqueAddCount;
    int refreshRate;
}

-(void)registerNotificationObservers;

#pragma mark ¥¥¥Accessors
- (int) refreshRate;
- (void) setRefreshRate:(int)aRefreshRate;
- (ORReadOutList*) readOutList;
- (void) setReadOutList:(ORReadOutList*)someDataTakers;
- (unsigned long)queueCount;
- (void)setQueueCount:(unsigned long)aQueueCount;
- (unsigned long) queueMaxSize;
- (NSString *)lastFile;
- (void)setLastFile:(NSString *)aLastFile;
- (unsigned long) dataTimeHist:(int)index;
- (unsigned long) processingTimeHist:(int)index;
- (short) timeScaler;
- (void) setTimeScaler:(short)aValue;
- (void) clearTimeHistogram;
- (BOOL) timerEnabled;
- (void) setEnableTimer:(int)aState;
- (unsigned long)cycleRate;
- (void) setCycleRate:(unsigned long)aRate;
- (void) setRunMode:(int)runMode;
- (void) removeOrcaObject:(id)anObject;

#pragma mark ¥¥¥Run Management
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStarted:(NSDictionary*)userInfo;
- (void) runIsStopping:(NSDictionary*)userInfo;
- (BOOL) doneTakingData;
- (void) runTaskStopped:(NSDictionary*)userInfo;
- (void) putDataInQueue:(ORDataPacket*)aDataPacket force:(BOOL)forceAdd;
- (void) queueRecordForShipping:(NSNotification*)aNote;
- (void) preCloseOut:(NSDictionary*)userInfo;
- (void) closeOutRun:(NSDictionary*)userInfo;
- (void) doCycleRate;
- (void) processData:(NSArray*)dataArray decoder:(ORDecoder*)aDecoder;

#pragma mark ¥¥¥Save/Restore
- (void) saveReadOutListTo:(NSString*)fileName;
- (void) loadReadOutListFrom:(NSString*)fileName;
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end


extern NSString* ORDataTaskModelRefreshRateChanged;
extern NSString* ORDataTakerAdded;
extern NSString* ORDataTakerRemoved;
extern NSString* ORDataTaskQueueCountChangedNotification;
extern NSString* ORDataTaskListLock;
extern NSString* ORDataTaskTimeScalerChangedNotification;
extern NSString* ORDataTaskCycleRateChangedNotification;
extern NSString* ORDataTaskModelTimerEnableChanged;

@interface NSObject (ORDataTaskModel)
- (int) stationNumber;
- (int) slot;
- (int) crateNumber;
- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
@end


