//
//  OReCPU147Model.h
//  Orca
//
//  Created by Mark Howe on Tue Mar 25 2003.
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


#pragma mark •••Imported Files
#import "ORVmeIOCard.h"
#import "ORDataTaker.h"
#import "OReCPU147Config.h"
#import "ORCircularBufferTypeDefs.h"

#pragma mark •••Forward Declarations
@class ORCircularBufferReader;
@class ORReadOutList;
@class ORAlarm;

@interface OReCPU147Model : ORVmeIOCard <ORDataTaker> {
	@private
	NSString* fileName;
	unsigned long codeLength;
	ORCircularBufferReader* circularBufferReader;
	ORReadOutList* readOutGroup;
	
    NSTimeInterval	updateInterval;
	NSDate*			lastQueUpdate;
	
	NSArray* dataTakers;	//cache of data takers.
	eCPU_MAC_DualPortComm 	communicationBlock;
	SCBHeader      			cbControlBlockHeader;
	eCPUDualPortControl		dualPortControl;

	unsigned short  missedHeartBeat;
	unsigned long   oldHeartBeat;
	BOOL            isRunning;
	ORAlarm*        eCpuDeadAlarm;
	ORAlarm*        eCpuNoStartAlarm;
    BOOL            startedCode;
    BOOL            powerFailed;
}

#pragma mark •••Accessors
- (NSDate*) lastQueUpdate;
- (void) setLastQueUpdate:(NSDate*)aDate;
- (NSString*) fileName;
- (void) setFileName:(NSString*)aFile;
- (unsigned long)codeLength;
- (ORCircularBufferReader*) circularBufferReader;
- (void) setCircularBufferReader:(ORCircularBufferReader*)cb;
- (ORReadOutList*) readOutGroup;
- (void) setReadOutGroup:(ORReadOutList*)newReadOutGroup;
- (NSMutableArray*) children;

- (NSTimeInterval) updateInterval;
- (void) setUpdateInterval:(NSTimeInterval)newUpdateInterval;
- (eCPU_MAC_DualPortComm) communicationBlock;
- (SCBHeader) cbControlBlockHeader;
- (eCPUDualPortControl) dualPortControl;

//- (void) setCommunicationBlock:(eCPU_MAC_DualPortComm)newCommunicationBlock;

- (void) getQueMinValue:(unsigned long*)aMinValue maxValue:(unsigned long*)aMaxValue head:(unsigned long*)aHeadValue tail:(unsigned long*)aTailValue;

#pragma mark •••Notifications
- (void)vmePowerFailed:(NSNotification*)aNote;

#pragma mark •••Downloading
- (NSData*) codeAsData;
- (void) startUserCodeWithRetries:(int)num;
- (void) stopUserCode;
- (void) downloadUserCode;
- (void) downloadWithRetryAndStart;
- (void) load_HW_Config;

- (NSData*) dumpCodeFrom:(unsigned long)startAddress length:(unsigned long)numBytes;
- (void) verifyCode;

#pragma mark •••DataTaker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) saveReadOutList:(NSFileHandle*)aFile;
- (void) loadReadOutList:(NSFileHandle*)aFile;

#pragma mark •••Updating
- (void) update;
- (void) readDualPortControl;
- (void) writeDualPortControl;
- (void) incDebugLevel;

- (NSString*) messageString:(short) error_index;
- (NSString*) errorString:(short) error_index;
- (void) addParamsToMessage:(NSMutableString*)aString index:(unsigned short) an_Index paramIndex:(unsigned short) aParamIndex;
- (void) addParamsToError:(NSMutableString*)aString index:(unsigned short) an_Index paramIndex:(unsigned short) aParamIndex;


@end

#pragma mark •••External String Definitions
extern NSString* OReCPU147FileNameChanged;
extern NSString* OReCPU147UpdateIntervalChangedNotification;
extern NSString* OReCPU147UpdateEnabledChangedNotification;
extern NSString* OReCPU147StructureUpdated;
extern NSString* OReCPU147QueChanged;
