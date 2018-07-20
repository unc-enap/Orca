//
//  SBC_Link.h
//  OrcaIntel
//
//  Created by Mark Howe on 9/11/07.
//  Copyright 2007 CENPA, University of Washington. All rights reserved.
//
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

#import "SBC_Config.h"
#import "SBC_Cmds.h"
#import "ORGroup.h"

@class ORCommandList;
@class ORPingTask;

typedef  enum eSBC_CrateStates{
	kIdle,
    kPing,
    kWaitForPing,
    kAfterPing,
    kTryToConnect,
	kTryToStartCode,
	kWaitingForStart,
	kReloadCode,
	kWaitingForReload,
	kTryToConnect2,
	kDone,
	kNumStates //must be last
}eSBC_CrateStates;

typedef enum eSBC_ThrottleConsts{
    kShrinkThrottleBy = 50,           // We shrink the throttle by this much
    kAmountInBufferThreshold = 20 // if the amount in the buffer exceeds this percent
}eSBC_ThrottleConsts;

@class  ORFileMover;
@class  ORCard;
@class ORSafeQueue;
@class ORSBCLinkJobStatus;

@interface SBC_Link : ORGroup {
	id				delegate;
    ORAlarm*        errorsAlarm;
    ORAlarm*        eCpuDeadAlarm;
	ORAlarm*        eRunFailedAlarm;
	ORAlarm*        eCpuCBFillingAlarm;
	ORAlarm*		eCpuCBLostDataAlarm;
    ORAlarm*        connectionDroppedAlarm;

	//setttings
	NSString*		IPNumber;
    NSString*		passWord;
    NSString*		userName;
    NSString*		filePath;
    int				portNumber;
	
	ORFileMover*	SBCFileMover;
	ORFileMover*	driverScriptFileMover;
	NSMutableData*	theDataBuffer;
	unsigned short  missedHeartBeat;
	uint32_t   oldCycleCount;
	BOOL            isRunning;
    BOOL            startedCode;
    NSTimeInterval	updateInterval;
    uint32_t	writeAddress;
    uint32_t	writeValue;
	unsigned int   addressModifier;
    SBC_info_struct runInfo;
    SBC_error_struct errorInfo;
    NSString*       sbcMacAddress;
    uint32_t   lastErrorCount;
    float           errorRate;
	NSDate*			lastQueUpdate;
    BOOL			reloading;
	BOOL			goScriptFailed;
	NSData*			leftOverData;
	BOOL			isConnected;
    NSDate*         timeConnected;
	int				socketfd;
	int				irqfd;
	int				startCrateState;
	int				waitCount;
	BOOL			tryingTostartCrate;
	int				compilerErrors;
	int				compilerWarnings;
	BOOL			verbose;
	BOOL			forceReload;
    BOOL			initAfterConnect;
	uint32_t		payloadSize;
	uint32_t        bytesReceived;
	uint32_t        bytesSent;
	float			byteRateReceived;
	float			byteRateSent;
    int				loadMode;
	uint32_t	throttleCount;
    int32_t            throttle;
    BOOL            disableThrottle;
	unsigned int	readWriteType;
	BOOL			doRange;
	unsigned short	range;
	int				infoType;
	NSLock*			socketLock;
	BOOL			irqThreadRunning;
	ORSafeQueue*    lamsToAck;
	BOOL			stopWatchingIRQ;

	ORPingTask*			pingTask;
    BOOL            pingedSuccessfully;
    BOOL            permissionDenied;
    
	//cbTest varibles
	int				numTestPoints;
	int				cbTestCount;
	uint32_t			startBlockSize;
	uint32_t			endBlockSize;
	uint32_t			deltaBlockSize;
	uint32_t		currentBlockSize;
	BOOL			cbTestRunning;
	BOOL			exitCBTest;
	NSDate*			lastInfoUpdate;
	double			totalTime;
	double			totalPayload;
	int32_t			totalMeasurements;
	int32_t			totalRecordsChecked;
	int32_t			totalErrors;
	BOOL			doingProductionTest;
	BOOL			productionSpeedValueValid;
	float			productionSpeed;
	NSPoint         cbPoints[100];
	int				recordSizeHisto[1000];
	uint32_t	lastAmountInBuffer;
	id				jobDelegate;
	SEL				statusSelector;
	ORSBCLinkJobStatus* jobStatus;
	int				errorTimeOut;
	NSMutableArray* connectionHistory;
	NSUInteger 		ipNumberIndex;
	NSString*		mainStagingFolder;
	int32_t			sbcCodeVersion;
    NSDate*         lastRateUpdate;
	unsigned int	sbcPollingRate;
    int             updateCount;
    int32_t            timeSkew;
    BOOL            timeSkewValid;
}

- (id)   initWithDelegate:(ORCard*)anDelegate;
- (void) dealloc;
- (void) wakeUp; 
- (void) sleep ;	
- (void) initConnectionHistory;
- (void) clearHistory;

#pragma mark ¥¥¥Accessors
- (unsigned int)sbcPollingRate;
- (void) setSbcPollingRate:(unsigned int)aValue;
- (int32_t) sbcCodeVersion;
- (void) setSbcCodeVersion:(int32_t)aVersion;
- (NSUInteger) ipNumberIndex;
- (int) slot;
- (NSUndoManager*) undoManager;
- (void) setErrorTimeOut:(int)aValue;
- (int) errorTimeOut;
- (int) numTestPoints;
- (void) setNumTestPoints:(int)num;
- (int) infoType;
- (void) setInfoType:(int)aType;
- (void) setDelegate:(ORCard*)anDelegate;
- (id) delegate;
- (int) loadMode;
- (void) setLoadMode:(int)aLoadMode;
- (BOOL) initAfterConnect;
- (void) setInitAfterConnect:(BOOL)aInitAfterConnect;
- (BOOL) tryingToStartCrate;
- (void) setTryingToStartCrate:(BOOL)flag;
- (BOOL) verbose;
- (void) setVerbose:(BOOL)flag;
- (BOOL) forceReload;
- (void) setForceReload:(BOOL)flag;
- (BOOL) reloading;
- (void) setReloading:(BOOL)aReloading;
- (BOOL) goScriptFailed;
- (void) setGoScriptFailed:(BOOL)aGoScriptFailed;
- (void) setCompilerErrors:(int)aValue;
- (int) compilerErrors;
- (void) setCompilerWarnings:(int)aValue;
- (int) compilerWarnings;
- (NSDate*) lastQueUpdate;
- (void) setLastQueUpdate:(NSDate*)aDate;
- (SBC_info_struct) runInfo;
- (uint32_t) writeValue;
- (void) setWriteValue:(uint32_t)aWriteValue;
- (uint32_t) writeAddress;
- (void) setWriteAddress:(uint32_t)aAddress;
- (NSString*) filePath;
- (void) setFilePath:(NSString*)aPath;
- (NSString*) userName;
- (void) setUserName:(NSString*)aUserName;
- (NSString*) passWord;
- (void) setPassWord:(NSString*)aPassWord;
- (int) portNumber;
- (BOOL) isConnected;
- (void) setIsConnected:(BOOL)aNewIsConnected;
- (NSDate*) timeConnected;
- (void) setTimeConnected:(NSDate*)newTimeConnected;
- (void) setPortNumber:(int)aPort;
- (NSString*) IPNumber;
- (void) setIPNumber:(NSString*)aIPNumber;
- (unsigned short) range;
- (void) setRange:(unsigned short)aRange;
- (BOOL) doRange;
- (void) setDoRange:(BOOL)aDoRange;
- (unsigned int) readWriteType;
- (void) setReadWriteType:(unsigned int)aValue;
- (unsigned int) addressModifier;
- (void) setAddressModifier:(unsigned int)aValue;
- (uint32_t) payloadSize;
- (void) setPayloadSize:(uint32_t)aValue;
- (ORSBCLinkJobStatus*) jobStatus;
- (void) setJobStatus:(ORSBCLinkJobStatus*)theJobStatus;
- (NSUInteger) connectionHistoryCount;
- (id) connectionHistoryItem:(NSUInteger)index;
- (BOOL) pingInProgress;
- (BOOL) pingedSuccessfully;
- (uint32_t) totalErrorCount;

- (void) clearRates;
- (void) calculateRates;
- (void) setByteRateSent:(float)aRate;
- (float)byteRateSent;
- (void) setByteRateReceived:(float)aRate;
- (float)byteRateReceived;
- (void) checkErrorRates;

- (void) fileMoverIsDone:(NSNotification*)aNote;

- (void) tasksCompleted:(id)sender;

- (int) connectToPort:(unsigned short) aPort;
- (void) getRunInfoBlock;
- (void) getErrorInfoBlock;
- (void) reloadClient;
- (void) killCrate;
- (void) taskData:(NSDictionary*)taskData;
- (void) taskFinished:(ORPingTask*)aTask;
- (void) toggleCrate;
- (void) startCrate;
- (void) stopCrate;
- (void) startCrateCode;
- (void) shutDown:(NSString*)rootPwd reboot:(BOOL)reboot;
- (void) connect;
- (void) disconnect;
- (NSString*) crateProcessState;
- (void) installDriver:(NSString*)rootPwd; 

- (void) tellClientToStartRun;
- (void) tellClientToStopRun;
- (void) pauseRun;
- (void) resumeRun;
- (void) setPollingDelay:(uint32_t)numMicroseconds;
- (void) checkSBCTime;
- (void) checkSBCTime:(BOOL)verbose;
- (void) checkSBCAccurateTime;
- (void) checkSBCAccurateTime:(BOOL)aVerbose;
- (void) setSBCTime:(NSString*)rootPwd;
- (int32_t) timeSkew;
- (BOOL) timeSkewValid;

- (void) sendCommand:(uint32_t)aCmd withOptions:(SBC_CmdOptionStruct*)optionBlock expectResponse:(BOOL)askForResponse;
- (void) sendPayloadSize:(uint32_t)aSize;

/* For the read*Block functions, the address space is used in VME 
   to determine if the block read is incrementing or not.  
   Use usingAddSpace:0x1 for incrementing addresses.
       usingAddSpace:0xFF for non-incrementing addresses.  
       usingAddSpace:oxFFFF accesses the control registers
                            of the bridge chip.  */

- (void) readLongBlock:(int32_t*) buffer
			 atAddress:(uint32_t) anAddress
			 numToRead:(uint32_t) numberLongs;

- (void) writeLongBlock:(int32_t*) buffer
			  atAddress:(uint32_t) anAddress
			 numToWrite:(uint32_t)  numberLongs;

- (void) readLongBlock:(uint32_t *) readAddress
			 atAddress:(uint32_t) vmeAddress
			 numToRead:(uint32_t) numberLongs
			withAddMod:(unsigned short) anAddressModifier
		 usingAddSpace:(unsigned short) anAddressSpace;

- (void) writeLongBlock:(uint32_t *) writeAddress
			  atAddress:(uint32_t) vmeAddress
			 numToWrite:(uint32_t) numberLongs
			 withAddMod:(unsigned short) anAddressModifier
		  usingAddSpace:(unsigned short) anAddressSpace;

- (void) readByteBlock:(unsigned char *) readAddress
			 atAddress:(uint32_t) vmeAddress
			 numToRead:(uint32_t) numberBytes
			withAddMod:(unsigned short) anAddressModifier
		 usingAddSpace:(unsigned short) anAddressSpace;

- (void) writeByteBlock:(unsigned char *) writeAddress
			  atAddress:(uint32_t) vmeAddress
			 numToWrite:(uint32_t) numberBytes
			 withAddMod:(unsigned short) anAddressModifier
		  usingAddSpace:(unsigned short) anAddressSpace;

- (void) readWordBlock:(unsigned short *) readAddress
			 atAddress:(uint32_t) vmeAddress
			 numToRead:(uint32_t) numberWords
			withAddMod:(unsigned short) anAddressModifier
		 usingAddSpace:(unsigned short) anAddressSpace;

- (void) writeWordBlock:(unsigned short *) writeAddress
			  atAddress:(uint32_t) vmeAddress
			 numToWrite:(uint32_t) numberWords
			 withAddMod:(unsigned short) anAddressModifier
		  usingAddSpace:(unsigned short) anAddressSpace;

- (void) executeCommandList:(ORCommandList*)aList;

- (void) send:(SBC_Packet*)aSendPacket receive:(SBC_Packet*)aReceivePacket;

- (void) update;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (BOOL) doneTakingData;
- (void) waitForPingTask; //SV
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) load_HW_Config:(SBC_crate_config*)aConfig;
- (uint32_t) throttle;
- (BOOL) disableThrottle;
- (void) setDisableThrottle:(BOOL)aFlag;
- (void)reportErrorsByCard;

- (NSString*) sbcLockName;
- (NSString*) crateName;

- (void) ping;
- (void) pingVerbose:(BOOL)aFlag;
- (BOOL) pingTaskRunning;
- (void) disconnectFromPingFailure;
- (void) startCBTransferTest;
- (BOOL) cbTestRunning;
- (int) cbTestCount;
- (NSPoint) cbPoint:(NSUInteger)i;
- (double) cbTestProgress;
- (int32_t) totalRecordsChecked;
- (int32_t) totalErrors;
- (int) recordSizeHisto:(int)aChannel;
- (int) numHistoChannels;
- (BOOL) productionSpeedValueValid;
- (float) productionSpeed;

#pragma mark ¥¥¥DataSource
- (void) getQueMinValue:(uint32_t*)aMinValue maxValue:(uint32_t*)aMaxValue head:(uint32_t*)aHeadValue tail:(uint32_t*)aTailValue;

#pragma mark ¥¥¥Archival
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;


- (void) throwError:(int)anError address:(uint32_t)anAddress;
- (void) fillInScript:(NSString*)theScript;
- (void) runFailed;
- (void) sbcConnectionDropped;
- (void) startCrateProcess;
- (void) watchIrqSocket;
- (void) write:(int)aSocket buffer:(SBC_Packet*)aPacket;
- (void) read:(int)aSocket buffer:(SBC_Packet*)aPacket;
- (BOOL) dataAvailable:(int) sck;
- (BOOL) canWriteTo:(int) sck;
- (void) readSocket:(int)aSocket buffer:(SBC_Packet*)aPacket;
- (void) sampleCBTransferSpeed;
- (void) doOneCBTransferTest:(uint32_t)payloadSize;
- (void) doCBTransferTest;
- (void) monitorJobFor:(id)aDelegate statusSelector:(SEL)aSelector;
- (void) monitorJob;
- (NSString*) sbcMacAddress;

- (void) writeGeneral:(int32_t*) buffer
			operation:(uint32_t) anOperationID
			numToWrite:(uint32_t) numberLongs;
			
- (void) readGeneral:(int32_t*) buffer
		   operation:(uint32_t) anOperationID
		   numToRead:(uint32_t) numberLongs;

- (void) postCouchDBRecord;
@end

@interface ORSBCLinkJobStatus : NSObject
{
	SBC_JobStatusStruct status;
	NSString* message;
}
+ (id) jobStatus:(SBC_JobStatusStruct*) p message:(char*)aPacketMessage;
- (id) initWith:(SBC_JobStatusStruct*)p message:(char*)aPacketMessage;
- (void) dealloc;
- (NSString*) message;
- (int32_t) running;	
- (int32_t) finalStatus;
- (int32_t) progress;	
@end


@interface NSObject (SBC_Link)
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;
- (NSString*) sbcLockName;
- (SBC_Link*) sbcLink;
@end

extern NSString* SBC_LinkReloadingChanged;
extern NSString* SBC_LinkLoadModeChanged;
extern NSString* SBC_LinkInitAfterConnectChanged;	
extern NSString* SgBC_LinkReloadingChanged;
extern NSString* SBC_LinkWriteValueChanged;	
extern NSString* SBC_LinkWriteAddressChanged;
extern NSString* SBC_LinkPathChanged;	
extern NSString* SBC_LinkUserNameChanged;
extern NSString* SBC_LinkPassWordChanged;
extern NSString* SBC_LinkPortChanged;	
extern NSString* SBC_LinkIPNumberChanged;
extern NSString* SBC_LinkRunInfoChanged;
extern NSString* SBC_LinkTimeConnectedChanged;
extern NSString* SBC_LinkConnectionChanged;	
extern NSString* SBC_LinkCompilerErrorsChanged;	
extern NSString* SBC_LinkCompilerWarningsChanged;
extern NSString* SBC_LinkVerboseChanged;	
extern NSString* SBC_LinkForceReloadChanged;	
extern NSString* SBC_LinkCrateStartStatusChanged;
extern NSString* SBC_LinkTryingToStartCrateChanged;
extern NSString* SBC_LinkByteRateChanged;	
extern NSString* SBC_LinkRangeChanged;
extern NSString* SBC_LinkDoRangeChanged;
extern NSString* SBC_LinkAddressModifierChanged;
extern NSString* SBC_LinkRWTypeChanged;
extern NSString* SBC_LinkInfoTypeChanged;
extern NSString* SBC_LinkPingTask;
extern NSString* SBC_LinkCBTest;
extern NSString* SBC_LinkNumCBTextPointsChanged;
extern NSString* SBC_LinkNumPayloadSizeChanged;
extern NSString* SBC_LinkJobStatus;
extern NSString* SBC_LinkErrorTimeOutChanged;
extern NSString* SBC_CodeVersionChanged;
extern NSString* SBC_SocketDroppedUnexpectedly;
extern NSString* SBC_LinkSbcPollingRateChanged;
extern NSString* SBC_LinkErrorInfoChanged;
extern NSString* SBC_LinkMacAddressChanged;
extern NSString* SBC_LinkTimeSkewChanged;
extern NSString* SBC_LinkSbcDisableThrottleChanged;

