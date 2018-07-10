//
//  ORContainerModel.h
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
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
#import "ORContainerModel.h"

@class ORAlarm;

@interface ORProcessModel : ORContainerModel  
{
    BOOL		inTestMode;
    BOOL		processRunning;
    ORAlarm*	testModeAlarm;
    NSString*   comment;
    NSString*   shortName;
    float		sampleRate;
	NSDate*		lastSampleTime;
	BOOL		sampleGateOpen;
	BOOL		useAltView;
	BOOL		wasRunning;
	BOOL		writeHeader;
    BOOL		keepHistory;
	time_t		lastHistorySample;
    NSString*	historyFile;
    NSMutableArray* emailList;
    int			heartBeatIndex;
    BOOL		sendOnStart;
    BOOL		sendOnStop;
	NSDate*		nextHeartbeat;
	BOOL		sendStartNoticeNextRead;
    BOOL        masterProcess;
    BOOL        updateImageForMasterChange;
    int         outOfRangeLowCount;
    int         outOfRangeHiCount;
    int         lastOutOfRangeLowCount;
    int         lastOutOfRangeHiCount;
    NSString*   lastReportContent;
    NSDate*     lastReportTime;
}

@property (retain) NSString* lastReportContent;
@property (retain) NSDate* lastReportTime;

- (NSString*) report;

#pragma mark ***Accessors
- (BOOL) masterProcess;
- (void) setMasterProcess:(BOOL)aMasterProcess;
- (void) runNow:(NSNotification*)aNote;
- (void) pollNow;
- (BOOL) sendOnStop;
- (void) setSendOnStop:(BOOL)aSendOnStop;
- (BOOL) sendOnStart;
- (void) setSendOnStart:(BOOL)aSendOnStart;
- (int) heartBeatIndex;
- (void) setHeartBeatIndex:(int)aHeartBeatIndex;
- (NSMutableArray*) emailList;
- (void) setEmailList:(NSMutableArray*)aEmailList;
- (void) addAddress:(id)anAddress atIndex:(int)anIndex;
- (void) removeAddressAtIndex:(int) anIndex;
- (NSMutableDictionary*) processDictionary;
- (NSString*) historyFile;
- (void) setHistoryFile:(NSString*)aHistoryFile;
- (BOOL) keepHistory;
- (void) setKeepHistory:(BOOL)aKeepHistory;
- (void) setProcessIDs;
- (BOOL) useAltView;
- (void) setUseAltView:(BOOL)aState;
- (void) startProcessCycle;
- (BOOL) sampleGateOpen;
- (void) endProcessCycle;

- (float) sampleRate;
- (void) setSampleRate:(float)aSampleRate;
- (void) checkForAchival;

- (NSString*) elementName;
- (id) stateValue;
- (NSString*) fullHwName;
- (BOOL) processRunning;
- (void) setProcessRunning:(BOOL)aState;
- (NSString*) comment;
- (void) setComment:(NSString*)aComment;
- (NSString*) shortName;
- (void) setShortName:(NSString*)aComment;
- (void) putInTestMode;
- (void) putInRunMode;
- (NSDate*)	lastSampleTime;

- (BOOL) inTestMode;
- (void) setInTestMode:(BOOL)aState;
- (void) postTestAlarm;
- (void) clearTestAlarm;

- (void) setUpImage;
- (void) makeMainController;
- (void) startRun;
- (void) stopRun;
- (void) startStopRun;
- (BOOL) changesAllowed;
- (int) compareStringTo:(id)anElement usingKey:(NSString*)aKey;
- (void)assignProcessID:(OrcaObject*)objToGetID;
- (int) heartbeatSeconds;

- (void) sendHeartbeatShutOffWarning;
- (void) sendHeartbeat;
- (void) mailSent:(NSString*)address;
- (void) sendMail:(NSDictionary*)userInfo;
- (void) setNextHeartbeatString;
- (NSDate*) nextHeartbeat;
- (void) sendStartStopNotice:(BOOL)state;
- (void) incrementProcessRunNumber;
- (int) processRunNumber;
- (NSString*) cleanupAddresses:(NSArray*)aListOfAddresses;
- (void) outOfRangeLowChanged:(NSNotification*)aNote;
- (void) outOfRangeHiChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
@end


@interface OrcaObject (ProcessModel)
- (void) setUseAltView:(BOOL)aState; 
- (void) askForProcessID:(id)fromObj;
- (id)valueDictionary;
- (BOOL) isTrueEndNode;
- (void) resetReportValues;
@end

extern NSString* ORProcessModelMasterProcessChanged;
extern NSString* ORForceProcessPollNotification;
extern NSString* ORProcessModelRunNumberChanged;
extern NSString* ORProcessModelNextHeartBeatChanged;
extern NSString* ORProcessModelSendOnStopChanged;
extern NSString* ORProcessModelSendOnStartChanged;
extern NSString* ORProcessModelHeartBeatIndexChanged;
extern NSString* ORProcessModelEmailListChanged;
extern NSString* ORProcessModelHistoryFileChanged;
extern NSString* ORProcessModelKeepHistoryChanged;
extern NSString* ORProcessModelUseAltViewChanged;
extern NSString* ORProcessModelSampleRateChanged;
extern NSString* ORProcessModelShortNameChangedNotification;
extern NSString* ORProcessTestModeChangedNotification;
extern NSString* ORProcessRunningChangedNotification ;
extern NSString* ORProcessModelCommentChangedNotification;
