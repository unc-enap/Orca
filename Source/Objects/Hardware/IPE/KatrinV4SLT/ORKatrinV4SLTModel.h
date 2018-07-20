//
//  ORKatrinV4SLTModel.h
//  Orca
//
//  Created by Mark Howe on Wed Aug 24 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORDataTaker.h"
#import "ORIpeCard.h"
#import "SBC_Linking.h"
#import "SBC_Config.h"
#import "ORKatrinV4SLTRegisters.h"

@class ORReadOutList;
@class ORDataPacket;
@class TimedWorker;
@class PMC_Link;
@class SBC_Link;
@class ORAlarm;

#define IsBitSet(A,B)       (((A) & (B)) == (B))
#define ExtractValue(A,B,C) (((A) & (B)) >> (C))

//control reg bit masks
#define kCtrlTrgEnShift		0
#define kCtrlInhEnShift		6 //SW Inhibit
#define kCtrlPPSShift		10
#define kCtrlTpEnEnShift	11

#define kCtrlLedOffmask	(0x00000001 << 17)               //RW
#define kCtrlIntEnMask	(0x00000001 << 16)               //RW
#define kCtrlTstSltMask	(0x00000001 << 15)               //RW
#define kCtrlRunMask	(0x00000001 << 14)               //RW
#define kCtrlShapeMask	(0x00000001 << 13)               //RW
#define kCtrlTpEnMask	(0x00000003 << kCtrlTpEnEnShift) //RW
#define kCtrlPPSMask	(0x00000001 << kCtrlPPSShift)    //RW
#define kCtrlInhEnMask	(0x0000000F << kCtrlInhEnShift)	 //RW
#define kCtrlTrgEnMask	(0x0000003F << kCtrlTrgEnShift)	 //RW

//status reg bit masks
#define kStatusIrq			(0x00000001 << 31) //R
#define kStatusFltStat		(0x00000001 << 30) //R
#define kStatusGps2			(0x00000001 << 29) //R
#define kStatusGps1			(0x00000001 << 28) //R
#define kStatusInhibitSrc	(0x0000000f << 24) //R
#define kStatusInh			(0x00000001 << 23) //R
#define kStatusSemaphores	(0x00000007 << 16) //R - cleared on W
#define kStatusFltTimeOut	(0x00000001 << 15) //R - cleared on W
#define kStatusPgFull		(0x00000001 << 14) //R - cleared on W
#define kStatusPgRdy		(0x00000001 << 13) //R - cleared on W
#define kStatusEvRdy		(0x00000001 << 12) //R - cleared on W
#define kStatusSwRq			(0x00000001 << 11) //R - cleared on W
#define kStatusFanErr		(0x00000001 << 10) //R - cleared on W
#define kStatusVttErr		(0x00000001 <<  9) //R - cleared on W
#define kStatusGpsErr		(0x00000001 <<  8) //R - cleared on W
#define kStatusClkErr		(0x0000000F <<  4) //R - cleared on W
#define kStatusPpsErr		(0x00000001 <<  3) //R - cleared on W
#define kStatusPixErr		(0x00000001 <<  2) //R - cleared on W
#define kStatusWDog			(0x00000001 <<  1) //R - cleared on W
#define kStatusFltRq		(0x00000001 <<  0) //R - cleared on W

#define kStatusClearAllMask	(0x0007ffff) //R - cleared on W

#define kFIFOcsrResetMask	(0x0000000c) //mres+pres

//Cmd reg bit masks
#define kCmdDisCnt			(0x00000001 << 10) //W - self cleared
#define kCmdEnCnt			(0x00000001 <<  9) //W - self cleared
#define kCmdClrCnt			(0x00000001 <<  8) //W - self cleared
#define kCmdSwRq			(0x00000001 <<  7) //W - self cleared
#define kCmdFltReset		(0x00000001 <<  6) //W - self cleared
#define kCmdSltReset		(0x00000001 <<  5) //W - self cleared
#define kCmdFwCfg			(0x00000001 <<  4) //W - self cleared
#define kCmdTpStart			(0x00000001 <<  3) //W - self cleared
#define kCmdClrInh			(0x00000001 <<  1) //W - self cleared
#define kCmdSetInh			(0x00000001 <<  0) //W - self cleared

//Interrupt Request and Mask reg bit masks
//Interrupt Request Read only - cleared on Read
//Interrupt Mask Read/Write only
#define kIrptFtlTmo		(0x00000001 << 15) 
#define kIrptPgFull		(0x00000001 << 14) 
#define kIrptPgRdy		(0x00000001 << 13) 
#define kIrptEvRdy		(0x00000001 << 12) 
#define kIrptSwRq		(0x00000001 << 11) 
#define kIrptFanErr		(0x00000001 << 10) 
#define kIrptVttErr		(0x00000001 <<  9) 
#define kIrptGPSErr		(0x00000001 <<  8) 
#define kIrptClkErr		(0x0000000F <<  4) 
#define kIrptPpsErr		(0x00000001 <<  3) 
#define kIrptPixErr		(0x00000001 <<  2) 
#define kIrptWdog		(0x00000001 <<  1) 
#define kIrptFltRq		(0x00000001 <<  0) 

//Revision Masks
#define kRevisionProject (0x0000000F << 28) //R
#define kDocRevision	 (0x00000FFF << 16) //R
#define kImplemention	 (0x0000FFFF <<  0) //R

//Page Manager Masks
#define kPageMngResetShift			22
#define kPageMngNumFreePagesShift	15
#define kPageMngPgFullShift			14
#define kPageMngNextPageShift		 8
#define kPageMngReadyShift			 7
#define kPageMngOldestPageShift      1
#define kPageMngReleaseShift		 0

#define kPageMngReset			(0x00000001 << kPageMngResetShift)			//W - self cleared
#define kPageMngNumFreePages	(0x0000007F << kPageMngNumFreePagesShift)	//R
#define kPageMngPgFull			(0x00000001 << kPageMngPgFullShift)			//W
#define kPageMngNextPage		(0x0000003F << kPageMngNextPageShift)		//W
#define kPageMngReady			(0x00000001 << kPageMngReadyShift)			//W
#define kPageMngOldestPage		(0x0000003F << kPageMngOldestPageShift)	//W
#define kPageMngRelease			(0x00000001 << kPageMngReleaseShift)		//W - self cleared

//Trigger Timing
#define kTrgTimingTrgWindow		(0x00000007 <<  16) //R/W
#define kTrgEndPageDelay		(0x000007FF <<   0) //R/W


@interface ORKatrinV4SLTModel : ORIpeCard <ORDataTaker,SBC_Linking>
{
	@private
		uint32_t	hwVersion;
		NSString*		patternFilePath;
		uint32_t	interruptMask;
		float			pulserAmp;
		float			pulserDelay;
		unsigned short  selectedRegIndex;
		uint32_t   writeValue;
		uint32_t	eventDataId;
		uint32_t	multiplicityId;
		uint32_t	eventFifoId;
		uint32_t	energyId;
		uint32_t   eventCounter;
		int				actualPageIndex;
        int             pollTime;
		ORReadOutList*	readOutGroup;
		NSArray*		dataTakers;			//< cache of data takers.
		BOOL			first;
        uint32_t   inhibitBeforeRun; //< Saves inhibit state at run start
		uint32_t   lastDisplaySec;
		uint32_t   lastDisplayCounter;
		double          lastDisplayRate;
        uint32_t   runStartSec;
        uint32_t   inhibitLastCheck; //< used in doneTakingData
        bool            callRunIsStopping;
        uint32_t   sltSecondRunStop;
        uint32_t   lastHitrateSec;
    
		uint32_t   lastSimSec;

		PMC_Link*		pmcLink;
        
		uint32_t       controlReg;
		uint32_t       statusReg;
		uint32_t       secondsSet;
		uint64_t  deadTime;
		uint64_t  vetoTime;
        uint64_t  runTime;
        uint64_t  lostEvents;
        uint64_t  lostFltEvents;
        uint64_t  lostFltEventsTr;
		uint32_t       clockTime;
		BOOL                countersEnabled;
        NSString*           sltScriptArguments;
        BOOL                secondsSetInitWithHost;
        bool                secondsSetSendToFLTs;
        uint32_t       pixelBusEnableReg;
        ORAlarm*            swInhibitDisabledAlarm;
        ORAlarm*            pixelTriggerDisabledAlarm;
        ORAlarm*            noPPSAlarm;
        ORAlarm*            badPPSStatusAlarm;
    
        BOOL                minimizeDecoding;
        bool                activateFltReadout;
    
        uint32_t       savedInhibitStatus;
        BOOL                waitForSubRunStart;
        BOOL                waitForSubRunEnd;
        uint32_t       secondToWaitFor;

}

#pragma mark •••Initialization
- (id)   init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (void) setGuardian:(id)aGuardian;
- (void) setDefaults;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) runIsBetweenSubRuns:(NSNotification*)aNote;
- (void) runIsStartingSubRun:(NSNotification*)aNote;
- (void) cardsChanged:(NSNotification*) aNote;
- (void) runIsAboutToChangeState:(NSNotification*)aNote;

#pragma mark •••Accessors
- (BOOL) minimizeDecoding;
- (void) setMinimizeDecoding:(BOOL)aState;
- (uint32_t) pixelBusEnableReg;
- (void) setPixelBusEnableReg:(uint32_t)aMask;
- (void) enablePixelBus:(int)aStationNumber;
- (void) disablePixelBus:(int)aStationNumber;
- (bool) secondsSetSendToFLTs;
- (void) setSecondsSetSendToFLTs:(bool)aSecondsSetSendToFLTs;
- (BOOL) secondsSetInitWithHost;
- (void) setSecondsSetInitWithHost:(BOOL)aSecondsSetInitWithHost;
- (NSString*) sltScriptArguments;
- (void) setSltScriptArguments:(NSString*)aSltScriptArguments;
- (BOOL) countersEnabled;
- (void) setCountersEnabled:(BOOL)aContersEnabled;
- (uint32_t) clockTime;
- (void) setClockTime:(uint32_t)aClockTime;
- (uint64_t) runTime;
- (void) setRunTime:(uint64_t)aRunTime;
- (uint64_t) vetoTime;
- (void) setVetoTime:(uint64_t)aVetoTime;
- (uint64_t) deadTime;
- (void) setDeadTime:(uint64_t)aDeadTime;
- (uint64_t) lostEvents;
- (void) setLostEvents:(uint64_t)aDeadTime;
- (uint64_t) lostFltEvents;
- (void) setLostFltEvents:(uint64_t)aDeadTime;
- (uint64_t) lostFltEventsTr;
- (void) setLostFltEventsTr:(uint64_t)aDeadTime;
- (uint32_t) secondsSet;
- (void) setSecondsSet:(uint32_t)aSecondsSet;
- (uint32_t) statusReg;
- (void) setStatusReg:(uint32_t)aStatusReg;
- (uint32_t) controlReg;
- (void) setControlReg:(uint32_t)aControlReg;

- (SBC_Link*)sbcLink;
- (bool)sbcIsConnected;
- (uint32_t) projectVersion;
- (uint32_t) documentVersion;
- (uint32_t) implementation;
- (void) setHwVersion:(uint32_t) aVersion;

- (NSString*) patternFilePath;
- (void) setPatternFilePath:(NSString*)aPatternFilePath;

- (uint32_t) interruptMask;
- (void) setInterruptMask:(uint32_t)aInterruptMask;
- (float) pulserDelay;
- (void) setPulserDelay:(float)aPulserDelay;
- (float) pulserAmp;
- (void) setPulserAmp:(float)aPulserAmp;
- (short) getNumberRegisters;			
- (NSString*) getRegisterName: (short) anIndex;
//- (uint32_t) getAddressOffset: (short) anIndex;
- (uint32_t) getAddress: (short) anIndex;
- (short) getAccessType: (short) anIndex;

- (unsigned short) 	selectedRegIndex;
- (void)		setSelectedRegIndex: (unsigned short) anIndex;
- (uint32_t) 	writeValue;
- (void)		setWriteValue: (uint32_t) anIndex;
//- (void) loadPatternFile;

- (void) sendSimulationConfigScriptON;
- (void) sendSimulationConfigScriptOFF;
- (void) sendLinkWithDmaLibConfigScriptON;
- (void) sendLinkWithDmaLibConfigScriptOFF;

- (void) checkPixelTrigger;
- (void) checkSoftwareInhibit;
- (void) checkPPSEnabled;
- (void) checkPPSStatus;

- (void) sendPMCCommandScript: (NSString*)aString;

- (int) numberOfActiveThresholdFinder;
- (void) restoreInhibitStatus;
- (void) saveInhibitStatus;

- (BOOL) compareRegisters:(BOOL)verbose;


#pragma mark ***Polling
- (int) pollTime;
- (void) setPollTime:(int)aPollTime;

#pragma mark ***HW Access
//note that most of these method can raise 
//exceptions either directly or indirectly
- (void)		  readAllStatus;
- (void)		  checkPresence;
- (uint32_t) readControlReg;
- (void)		  writeControlReg;
- (void)		  writeControlRegRunFlagOn:(BOOL) aState;
- (void)		  printControlReg;
- (uint32_t) readStatusReg;
- (void)		  printStatusReg;

- (void) writePixelBusEnableReg;
- (void) readPixelBusEnableReg;
- (void) readSLTEventFifoSingleEvent;

- (void)		loadSecondsReg;
- (void)		writeSetInhibit;
- (void)		writeClrInhibit;
- (void)		writeTpStart;
- (void)		writeFwCfg;
- (void)		writeSltReset;
- (void)		writeFltReset;
- (void)		writeSwRq;
- (void)		writeClrCnt;
- (void)		writeEnCnt;
- (void)		writeDisCnt;
- (void)		clearAllStatusErrorBits;
- (void)		writeFIFOcsrReset;

- (uint64_t) readBoardID;

- (void)		  writeInterruptMask;
- (void)		  readInterruptMask;
- (void)		  readInterruptRequest;
- (void)		  printInterruptRequests;
- (void)		  printInterruptMask;
- (void)		  printInterrupt:(int)regIndex;
//- (void)		  dumpTriggerRAM:(int)aPageIndex;

- (void)		  writeReg:(int)index value:(uint32_t)aValue;
- (void)		  rawWriteReg:(uint32_t) address  value:(uint32_t)aValue;//TODO: FOR TESTING AND DEBUGGING ONLY -tb-
- (uint32_t) rawReadReg:(uint32_t) address; //TODO: FOR TESTING AND DEBUGGING ONLY -tb-
- (uint32_t) readReg:(int) index;
- (id) writeHardwareRegisterCmd:(uint32_t)regAddress value:(uint32_t) aValue;
- (id) readHardwareRegisterCmd:(uint32_t)regAddress;
- (uint32_t) readHwVersion;
- (uint64_t) readDeadTime;
- (uint64_t) readVetoTime;
- (uint64_t) readRunTime;
- (void) clearRunTime;

- (double) readTime;
- (uint32_t) readSecondsCounter;
- (uint32_t) readSubSecondsCounter;
- (uint32_t) getSeconds;
- (uint32_t) getRunStartSecond;
- (uint32_t) getRunEndSecond;

- (void)		reset;
- (void)		hw_config;
- (void)		hw_reset;
//- (void)		loadPulseAmp;
//- (void)		loadPulserValues;
//- (void)		swTrigger;
- (void)        initBoard;
- (void)        initAllBoards;
- (void)		autoCalibrate;
- (int32_t)		getSBCCodeVersion;
- (int32_t)		getFdhwlibVersion;
- (int32_t)		getSltPciDriverVersion;
- (int32_t)		getSltkGetIsLinkedWithPCIDMALib;
- (void)		setHostTimeToFLTsAndSLT;

- (uint64_t) readLostFltEvents;
- (uint64_t) readLostFltEventsTr;


#pragma mark •••Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
- (NSDictionary*) dataRecordDescription;

- (uint32_t) eventDataId;
- (void) setEventDataId: (uint32_t) DataId;
- (uint32_t) multiplicityId;
- (void) setMultiplicityId: (uint32_t) DataId;
- (uint32_t) eventFifoId;
- (void) setEventFifoId: (uint32_t) DataId;
- (uint32_t) energyId;
- (void) setEnergyId: (uint32_t) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherCard;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

#pragma mark •••DataTaker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) saveReadOutList:(NSFileHandle*)aFile;
- (void) loadReadOutList:(NSFileHandle*)aFile;
- (BOOL) doneTakingData;

- (void) dumpSltSecondCounter:(NSString*)text;
- (void) shipSecondCounter:(unsigned char)aType sec:(uint32_t)seconds;
- (void) shipSltSecondCounter:(unsigned char)aType;
- (void) shipSltRunCounter:(unsigned char)aType;
- (void) shipSltEvent:(unsigned char)aCounterType withType:(unsigned char)aType eventCt:(uint32_t)c high:(uint32_t)h low:(uint32_t)l;

- (ORReadOutList*)	readOutGroup;
- (void)			setReadOutGroup:(ORReadOutList*)newReadOutGroup;
- (NSMutableArray*) children;

#pragma mark •••SBC_Linking Protocol
- (NSString*) driverScriptName;
- (NSString*) cpuName;
- (NSString*) sbcLockName;
- (NSString*) sbcLocalCodePath;
- (NSString*) codeResourcePath;
						 
#pragma mark •••SBC Data Structure Setup
- (void) load_HW_Config;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;

@end

extern NSString* ORKatrinV4SLTModelPixelBusEnableRegChanged;
extern NSString* ORKatrinV4SLTModelSecondsSetSendToFLTsChanged;
extern NSString* ORKatrinV4SLTModelSecondsSetInitWithHostChanged;
extern NSString* ORKatrinV4SLTModelSltScriptArgumentsChanged;
extern NSString* ORKatrinV4SLTModelCountersEnabledChanged;
extern NSString* ORKatrinV4SLTModelClockTimeChanged;
extern NSString* ORKatrinV4SLTModelRunTimeChanged;
extern NSString* ORKatrinV4SLTModelVetoTimeChanged;
extern NSString* ORKatrinV4SLTModelDeadTimeChanged;
extern NSString* ORKatrinV4SLTModelSecondsSetChanged;
extern NSString* ORKatrinV4SLTModelStatusRegChanged;
extern NSString* ORKatrinV4SLTModelControlRegChanged;
extern NSString* ORKatrinV4SLTModelHwVersionChanged;
extern NSString* ORKatrinV4SLTModelMinimizeDecodingChanged;

extern NSString* ORKatrinV4SLTModelPatternFilePathChanged;
extern NSString* ORKatrinV4SLTModelInterruptMaskChanged;
extern NSString* ORKatrinV4SLTPulserDelayChanged;
extern NSString* ORKatrinV4SLTPulserAmpChanged;
extern NSString* ORKatrinV4SLTSelectedRegIndexChanged;
extern NSString* ORKatrinV4SLTWriteValueChanged;
extern NSString* ORKatrinV4SLTSettingsLock;
extern NSString* ORKatrinV4SLTStatusRegChanged;
extern NSString* ORKatrinV4SLTControlRegChanged;
extern NSString* ORKatrinV4SLTPollTimeChanged;
extern NSString* ORKatrinV4SLTModelReadAllChanged;
extern NSString* ORKatrinV4SLTModelLostEventsChanged;
extern NSString* ORKatrinV4SLTModelLostFltEventsChanged;
extern NSString* ORKatrinV4SLTModelLostFltEventsTrChanged;
extern NSString* ORKatrinV4SLTcpuLock;

