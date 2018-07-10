//
//  ORMotionNodeModel.h
//  Orca
//
//  Created by Mark Howe on Fri Apr 24, 2009.
//  Copyright (c) 2009 CENPA, University of Washington. All rights reserved.
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
#import "ORSerialPortModel.h"

@class ORAlarm;
@class ORSafeQueue;

enum {
	kMotionNodeConnectResponse,
	kMotionNodeMemoryContents,
	kMotionNodeStop,
	kMotionNodeStart,
	kMotionNodeClosePort,
	kNumMotionNodeCommands
};

typedef struct MotionNodeCommands {
	int			cmdNumber;
	NSString*   command;
	int			expectedLength;
	BOOL		okToTimeOut;
} MotionNodeCommands; 

typedef struct MotionNodeCalibrations {
	float  intercept;
	float  slope;
} MotionNodeCalibrations; 

typedef struct MotionNodeHistoryData {
     short x;
     short y;
     short z;
}MotionNodeHistoryData;

typedef struct MotionNodeHistoryHeader {
    unsigned long           moduleID;
    double                  endTime;
    double                  startTime;
    MotionNodeCalibrations  calibrations[3];
    unsigned long numDataPoints;
    //numDataPoints * MotionNodeData structs to follow
} MotionNodeHistoryHeader;

#define kModeNodeTraceLength        1500
#define kModeNodeLongTraceLength    1000
#define kModeNodePtsToCombine       (6000/kModeNodeLongTraceLength)
#define kNumMin                     60

@interface ORMotionNodeModel : ORSerialPortModel {
	unsigned long	dataId;
    BOOL			nodeRunning;
	NSMutableData*	inComingData;
	ORSafeQueue*	cmdQueue;
	id				lastRequest;
    NSString*		serialNumber;
	NSLock*			localLock;
	ORAlarm*		noDriverAlarm;
    int				nodeVersion;
    BOOL			isAccelOnly;
    int				packetLength;
    float			ax;
    float			ay;
    float			az;
    float           amean;
    int				traceIndex;
    int				longTraceIndex;
    int				longTraceMinIndex;
	float			xTrace[kModeNodeTraceLength];
	float			yTrace[kModeNodeTraceLength];
	float			zTrace[kModeNodeTraceLength];
	float			xyzTrace[kModeNodeTraceLength];
    NSMutableArray* specialTrace;
	float**			longTermTrace;
	int				throttle;
	float			temperatureAverage;
    float			temperature;
    float			totalxyz;
	BOOL			displayComponents;
    BOOL			showDeltaFromAve;
	BOOL			longTermValid;
    NSDate*			startTime;
    int				longTermSensitivity;
	BOOL			cycledOnce;
    BOOL			showLongTermDelta;
	BOOL			scheduledToShip;
    BOOL			autoStart; //with Run
    BOOL			autoStartWithOrca;
    float			shipThreshold;
    BOOL			shipExcursions;
    BOOL			outOfBand;
    NSDate*			lastRecordShipped;
    int				totalShipped;
	int				excursionIndex;
	float			longTraceValueToKeep;
    BOOL            keepHistory;
    NSString*		historyFolder;
    NSMutableData*  historyTrace;
    int             historyIndex;
    int             averageIndex;
    NSDate*         specialStartTime;
    BOOL            eventInProgress;
    int             postEventCount;
    int             averageCount;

    MotionNodeHistoryData*  historyPtr;
    
    NSData*         oldHistoryData;
    
    
    NSString*       serialID;
}

#pragma mark ***Initialization
- (void) registerNotificationObservers;
- (void) orcaIsTerminating:(NSNotification*)aNote;
- (void) runStarting:(NSNotification*)aNote;
- (void) runStopping:(NSNotification*)aNote;
- (void) delayedOpen;
- (void) delayedStart;

#pragma mark ***Accessors
- (int) totalShipped;
- (void) setTotalShipped:(int)aTotalShipped;
- (NSDate*) lastRecordShipped;
- (void) setLastRecordShipped:(NSDate*)aLastRecordShipped;
- (BOOL) outOfBand;
- (void) setOutOfBand:(BOOL)aOutOfBand;
- (BOOL) shipExcursions;
- (void) setShipExcursions:(BOOL)aShipExcursions;
- (float) shipThreshold;
- (void) setShipThreshold:(float)aShipThreshold;
- (BOOL) autoStart;
- (void) setAutoStart:(BOOL)aAutoStart;
- (BOOL) autoStartWithOrca;
- (void) setAutoStartWithOrca:(BOOL)aAutoStart;
- (BOOL) showLongTermDelta;
- (void) setShowLongTermDelta:(BOOL)aShowLongTermDelta;
- (int) longTermSensitivity;
- (void) setLongTermSensitivity:(int)aLongTermSensitivity;
- (NSDate*) startTime;
- (void) setStartTime:(NSDate*)aStartTime;
- (BOOL) showDeltaFromAve;
- (void) setShowDeltaFromAve:(BOOL)aShowDeltaFromAve;
- (float) displayComponents;
- (void) setDisplayComponents:(BOOL)aState;
- (float) temperature;
- (void) setTemperature:(float)aTemperature;
- (BOOL) nodeRunning;
- (void) setNodeRunning:(BOOL)aNodeRunning;
- (float) totalxyzAt:(int)i;
- (float) axAt:(int)i;
- (float) ayAt:(int)i;
- (float) azAt:(int)i;
- (float) axDeltaAveAt:(int)i;
- (float) ayDeltaAveAt:(int)i;
- (float) azDeltaAveAt:(int)i;
- (float) xyzDeltaAveAt:(int)i;
- (float) ax;
- (float) ay;
- (float) az;


- (int) packetLength;
- (void) setPacketLength:(int)aPacketLength;
- (BOOL) isAccelOnly;
- (void) setIsAccelOnly:(BOOL)aIsAccelOnly;
- (int) nodeVersion;
- (void) setNodeVersion:(int)aVersion;
- (NSString*) serialNumber;
- (void) setSerialNumber:(NSString*)aSerialNumber;
- (id) lastRequest;
- (void) setLastRequest:(id)aCmd;

- (NSString*) historyFolder;
- (void) setHistoryFolder:(NSString*)aHistoryFolder;
- (void) viewPastHistory:(NSString*)filePath;
- (int) numPointsInOldHistory;
- (int) numPointsInOldHistory;
- (float) oldHistoryValue:(int)index;
- (NSTimeInterval) oldHistoryStartTime;
- (NSTimeInterval) oldHistoryEndTime;
- (unsigned long)maxHistoryLength;
- (BOOL) keepHistory;
- (void) setKeepHistory:(BOOL)aFlag;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ***HW Commands
- (void) initDevice;
- (void) stopDevice;
- (void) startDevice;
- (void) readOnboardMemory;
- (void) readConnect;

#pragma mark •••Port Methods
- (void) dataReceived:(NSNotification*)note;

#pragma mark •••Data Records
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (NSDictionary*) dataRecordDescription;
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherPDcu;
- (void) shipXYZTrace;

#pragma mark •••Data Source
- (int) maxLinesInLongTermView;
- (int) startingLine;
- (int) numLinesInLongTermView;
- (int) numPointsPerLineInLongTermView;
- (float)longTermDataAtLine:(int)m point:(int)i;

@end

extern NSString* ORMotionNodeModelTotalShippedChanged;
extern NSString* ORMotionNodeModelLastRecordShippedChanged;
extern NSString* ORMotionNodeModelOutOfBandChanged;
extern NSString* ORMotionNodeModelShipExcursionsChanged;
extern NSString* ORMotionNodeModelShipThresholdChanged;
extern NSString* ORMotionNodeModelAutoStartChanged;
extern NSString* ORMotionNodeModelAutoStartWithOrcaChanged;
extern NSString* ORMotionNodeModelShowLongTermDeltaChanged;
extern NSString* ORMotionNodeModelLongTermSensitivityChanged;
extern NSString* ORMotionNodeModelStartTimeChanged;
extern NSString* ORMotionNodeModelShowDeltaFromAveChanged;
extern NSString* ORMotionNodeModelTemperatureChanged;
extern NSString* ORMotionNodeModelNodeRunningChanged;
extern NSString* ORMotionNodeModelTraceIndexChanged;
extern NSString* ORMotionNodeModelPacketLengthChanged;
extern NSString* ORMotionNodeModelIsAccelOnlyChanged;
extern NSString* ORMotionNodeModelVersionChanged;
extern NSString* ORMotionNodeModelLock;
extern NSString* ORMotionNodeModelSerialNumberChanged;
extern NSString* ORMotionNodeModelDisplayComponentsChanged;
extern NSString* ORMotionNodeModelUpdateLongTermTrace;
extern NSString* ORMotionNodeModelHistoryFolderChanged;
extern NSString* ORMotionNodeModelUpdateHistoryPlot;
extern NSString* ORMotionNodeModelKeepHistoryChanged;
