//
//  ORIpeV4SLTModel.h
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

@class ORReadOutList;
@class ORDataPacket;
@class TimedWorker;
@class ORIpeFLTModel;
@class PMC_Link;
@class SBC_Link;

#define IsBitSet(A,B) (((A) & (B)) == (B))
#define ExtractValue(A,B,C) (((A) & (B)) >> (C))

//control reg bit masks
#define kCtrlTrgEnShift		0
#define kCtrlInhEnShift		6
#define kCtrlPPSShift		10
#define kCtrlTpEnEnShift	11

#define kCtrlLedOffmask	(0x00000001 << 17) //RW
#define kCtrlIntEnMask	(0x00000001 << 16) //RW
#define kCtrlTstSltMask	(0x00000001 << 15) //RW
#define kCtrlRunMask	(0x00000001 << 14) //RW
#define kCtrlShapeMask	(0x00000001 << 13) //RW
#define kCtrlTpEnMask	(0x00000003 << kCtrlTpEnEnShift)	//RW
#define kCtrlPPSMask	(0x00000001 << kCtrlPPSShift)		//RW
#define kCtrlInhEnMask	(0x0000000F <<  kCtrlInhEnShift)	//RW
#define kCtrlTrgEnMask	(0x0000003F <<  kCtrlTrgEnShift)	//RW

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
#define kPageMngNextPageShift		8
#define kPageMngReadyShift			7
#define kPageMngOldestPageShift	1
#define kPageMngReleaseShift		0

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


//IPE V4 register definitions
enum IpeV4Enum {
	kSltV4ControlReg,
	kSltV4StatusReg,
	kSltV4CommandReg,
	kSltV4InterruptReguestReg,
	kSltV4InterruptMaskReg,
	kSltV4RequestSemaphoreReg,
	kSltV4HWRevisionReg,
	kSltV4PixelBusErrorReg,
	kSltV4PixelBusEnableReg,
	kSltV4PixelBusTestReg,
	kSltV4AuxBusTestReg,
	kSltV4DebugStatusReg,
	kSltV4VetoCounterHiReg,		//TODO: the LSB and MSB part of this SLT registers is confused (according to the SLT doc 2.13/2010-May) -tb-
	kSltV4VetoCounterLoReg,		//TODO: the LSB and MSB part of this SLT registers is confused (according to the SLT doc 2.13/2010-May) -tb-
	kSltV4DeadTimeCounterHiReg,	//TODO: the LSB and MSB part of this SLT registers is confused (according to the SLT doc 2.13/2010-May) -tb-
	kSltV4DeadTimeCounterLoReg,	//TODO: the LSB and MSB part of this SLT registers is confused (according to the SLT doc 2.13/2010-May) -tb-
								//TODO: and dead time and veto time counter are confused, too -tb-
	kSltV4RunCounterHiReg,		//TODO: the LSB and MSB part of this SLT registers is confused (according to the SLT doc 2.13/2010-May) -tb-
	kSltV4RunCounterLoReg,		//TODO: the LSB and MSB part of this SLT registers is confused (according to the SLT doc 2.13/2010-May) -tb-
	kSltV4SecondSetReg,
	kSltV4SecondCounterReg,
	kSltV4SubSecondCounterReg,
	kSltV4PageManagerReg,
	kSltV4TriggerTimingReg,
	kSltV4PageSelectReg,
	kSltV4NumberPagesReg,
	kSltV4PageNumbersReg,
	kSltV4EventStatusReg,
	kSltV4ReadoutCSRReg,
	kSltV4BufferSelectReg,
	kSltV4ReadoutDefinitionReg,
	kSltV4TPTimingReg,
	kSltV4TPShapeReg,
	kSltV4i2cCommandReg,
	kSltV4epcsCommandReg,
	kSltV4BoardIDLoReg,
	kSltV4BoardIDHiReg,
	kSltV4PROMsControlReg,
	kSltV4PROHiufferReg,
	kSltV4TriggerDataReg,
	kSltV4ADCDataReg,




//TODO: WARNING - ONLY FOR 2013-KATRIN-SLT-FIRMWARE -tb-
//TODO: WARNING - ONLY FOR 2013-KATRIN-SLT-FIRMWARE -tb-
//TODO: WARNING - ONLY FOR 2013-KATRIN-SLT-FIRMWARE -tb-
//TODO: WARNING - ONLY FOR 2013-KATRIN-SLT-FIRMWARE -tb-
//TODO: WARNING - ONLY FOR 2013-KATRIN-SLT-FIRMWARE -tb-
//TODO: WARNING - ONLY FOR 2013-KATRIN-SLT-FIRMWARE -tb-
	kSltV4FIFOCsrReg,
	kSltV4FIFOxRequestReg,
	kSltV4FIFOMaskReg,


	kSltV4NumRegs //must be last
};

extern IpeRegisterNamesStruct regSLTV4[kSltV4NumRegs];

#if 0
//this is in .m file
static IpeRegisterNamesStruct regSLTV4[kSltV4NumRegs] = {
{@"Control",			0xa80000,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Status",				0xa80004,		1,			kIpeRegReadable },
{@"Command",			0xa80008,		1,			kIpeRegWriteable },
{@"Interrupt Reguest",	0xA8000C,		1,			kIpeRegReadable },
{@"Interrupt Mask",		0xA80010,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Request Semaphore",	0xA80014,		3,			kIpeRegReadable },
{@"HWRevision",			0xa80020,		1,			kIpeRegReadable },
{@"Pixel Bus Error",	0xA80024,		1,			kIpeRegReadable },			
{@"Pixel Bus Enable",	0xA80028,		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Pixel Bus Test",		0xA8002C, 		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Aux Bus Test",		0xA80030, 		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Debug Status",		0xA80034,  		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Veto Counter (MSB)",	0xA80080, 		1,			kIpeRegReadable },	
{@"Veto Counter (LSB)",	0xA80084,		1,			kIpeRegReadable },	
{@"Dead Counter (MSB)",	0xA80088, 		1,			kIpeRegReadable },	
{@"Dead Counter (LSB)",	0xA8008C, 		1,			kIpeRegReadable },	
{@"Run Counter  (MSB)",	0xA80090,		1,			kIpeRegReadable },	
{@"Run Counter  (LSB)",	0xA80094, 		1,			kIpeRegReadable },	
{@"Second Set",			0xB00000,  		1, 			kIpeRegReadable | kIpeRegWriteable }, 
{@"Second Counter",		0xB00004, 		1,			kIpeRegReadable },
{@"Sub-second Counter",	0xB00008, 		1,			kIpeRegReadable }, 
{@"Page Manager",		0xB80000,  		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Trigger Timing",		0xB80004,  		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Page Select",		0xB80008, 		1,			kIpeRegReadable },
{@"Number of Pages",	0xB8000C, 		1,			kIpeRegReadable },
{@"Page Numbers",		0xB81000,		64, 		kIpeRegReadable | kIpeRegWriteable },
{@"Event Status",		0xB82000,		64,			kIpeRegReadable },
{@"Readout CSR",		0xC00000,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Buffer Select",		0xC00004,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Readout Definition",	0xC10000,	  2048,			kIpeRegReadable | kIpeRegWriteable },			
{@"TP Timing",			0xC80000,	   128,			kIpeRegReadable | kIpeRegWriteable },	
{@"TP Shape",			0xC81000,	   512,			kIpeRegReadable | kIpeRegWriteable },	
{@"I2C Command",		0xD00000,		1,			kIpeRegReadable },
{@"EPC Command",		0xD00004,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Board ID (LSB)",		0xD00008,		1,			kIpeRegReadable },
{@"Board ID (MSB)",		0xD0000C,		1,			kIpeRegReadable },
{@"PROMs Control",		0xD00010,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"PROMs Buffer",		0xD00100,		256,		kIpeRegReadable | kIpeRegWriteable },
{@"Trigger Data",		0xD80000,	  14000,		kIpeRegReadable | kIpeRegWriteable },
{@"ADC Data",			0xE00000,	 0x8000,		kIpeRegReadable | kIpeRegWriteable },
//{@"Data Block RW",		0xF00000 Data Block RW
//{@"Data Block Length",	0xF00004 Data Block Length 
//{@"Data Block Address",	0xF00008 Data Block Address
};
#endif


@interface ORIpeV4SLTModel : ORIpeCard <ORDataTaker,SBC_Linking>
{
	@private
		uint32_t	hwVersion;
		NSString*		patternFilePath;
		uint32_t	interruptMask;
		uint32_t	nextPageDelay;
		float			pulserAmp;
		float			pulserDelay;
		unsigned short  selectedRegIndex;
		uint32_t   writeValue;
		uint32_t	eventDataId;
		uint32_t	multiplicityId;
		uint32_t   eventCounter;
		int				actualPageIndex;
        TimedWorker*    poller;
		BOOL			pollingWasRunning;
		ORReadOutList*	readOutGroup;
		NSArray*		dataTakers;			//cache of data takers.
		BOOL			first;
		// ak, 9.12.07
		BOOL            displayTrigger;    //< Display pixel and timing view of trigger data
		BOOL            displayEventLoop;  //< Display the event loop parameter
		uint32_t   lastDisplaySec;
		uint32_t   lastDisplayCounter;
		double          lastDisplayRate;
		
		uint32_t   lastSimSec;
		uint32_t   pageSize; //< Length of the ADC data (0..100us)

		PMC_Link*		pmcLink;
        
		uint32_t controlReg;
		uint32_t statusReg;
		uint32_t secondsSet;
		uint64_t deadTime;
		uint64_t vetoTime;
		uint64_t runTime;
		uint32_t clockTime;
		BOOL countersEnabled;
    NSString* sltScriptArguments;
    BOOL secondsSetInitWithHost;
    bool secondsSetSendToFLTs;
}

#pragma mark •••Initialization
- (id)   init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (void) setGuardian:(id)aGuardian;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) runIsAboutToStart:(NSNotification*)aNote;
- (void) runStarted:(NSNotification*)aNote;
- (void) runIsStopped:(NSNotification*)aNote;
- (void) runIsBetweenSubRuns:(NSNotification*)aNote;
- (void) runIsStartingSubRun:(NSNotification*)aNote;

- (void) runIsAboutToChangeState:(NSNotification*)aNote;

- (void) viewChanged:(NSNotification*)aNotification;

#pragma mark •••Accessors
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

- (uint32_t) nextPageDelay;
- (void) setNextPageDelay:(uint32_t)aDelay;
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

- (BOOL) displayTrigger; //< Staus of dispaly of trigger information
- (void) setDisplayTrigger:(BOOL) aState; 
- (BOOL) displayEventLoop; //< Status of display of event loop performance information
- (void) setDisplayEventLoop:(BOOL) aState;
- (uint32_t) pageSize; //< Length of the ADC data (0..100us)
- (void) setPageSize: (uint32_t) pageSize;   
- (void) sendSimulationConfigScriptON;
- (void) sendSimulationConfigScriptOFF;
- (void) sendLinkWithDmaLibConfigScriptON;
- (void) sendLinkWithDmaLibConfigScriptOFF;



- (void) sendPMCCommandScript: (NSString*)aString;

#pragma mark ***Polling
- (TimedWorker *) poller;
- (void) setPoller: (TimedWorker *) aPoller;
- (void) setPollingInterval:(float)anInterval;
- (void) makePoller:(float)anInterval;

#pragma mark ***HW Access
//note that most of these method can raise 
//exceptions either directly or indirectly
- (void)		  readAllStatus;
- (void)		  checkPresence;
- (uint32_t) readControlReg;
- (uint32_t) readPageSelectReg;
- (void)		  writeControlReg;
- (void)		  printControlReg;
- (uint32_t) readStatusReg;
- (void)		  printStatusReg;
- (void)		  loadSecondsReg;
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
- (void)		writeReleasePage;		
- (void)		writePageManagerReset;
- (void)		clearAllStatusErrorBits;

- (uint64_t) readBoardID;
- (void) readEventStatus:(uint32_t*)eventStatusBuffer;

- (void)		  writePageSelect:(uint32_t)aPageNum;
- (void)		  writeInterruptMask;
- (void)		  readInterruptMask;
- (void)		  readInterruptRequest;
- (void)		  printInterruptRequests;
- (void)		  printInterruptMask;
- (void)		  printInterrupt:(int)regIndex;
//- (void)		  dumpTriggerRAM:(int)aPageIndex;

- (void)		  writeReg:(short)index value:(uint32_t)aValue;
- (void)		  rawWriteReg:(uint32_t) address  value:(uint32_t)aValue;//TODO: FOR TESTING AND DEBUGGING ONLY -tb-
- (uint32_t) rawReadReg:(uint32_t) address; //TODO: FOR TESTING AND DEBUGGING ONLY -tb-
- (uint32_t) readReg:(short) index;
- (id) writeHardwareRegisterCmd:(uint32_t)regAddress value:(uint32_t) aValue;
- (id) readHardwareRegisterCmd:(uint32_t)regAddress;
- (uint32_t) readHwVersion;
- (uint64_t) readDeadTime;
- (uint64_t) readVetoTime;
- (uint64_t) readRunTime;
- (uint32_t) readSecondsCounter;
- (uint32_t) readSubSecondsCounter;
- (uint32_t) getSeconds;

- (void)		reset;
- (void)		hw_config;
- (void)		hw_reset;
//- (void)		loadPulseAmp;
//- (void)		loadPulserValues;
//- (void)		swTrigger;
- (void)		initBoard;
- (void)		autoCalibrate;
- (int32_t)		getSBCCodeVersion;
- (int32_t)		getFdhwlibVersion;
- (int32_t)		getSltPciDriverVersion;
- (int32_t)		getSltkGetIsLinkedWithPCIDMALib;
- (void)		setHostTimeToFLTsAndSLT;

#pragma mark •••Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
- (NSDictionary*) dataRecordDescription;

- (uint32_t) eventDataId;
- (void) setEventDataId: (uint32_t) DataId;
- (uint32_t) multiplicityId;
- (void) setMultiplicityId: (uint32_t) DataId;
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
- (void) shipSltSecondCounter:(unsigned char)aType;
- (void) shipSltRunCounter:(unsigned char)aType;
- (void) shipSltEvent:(unsigned char)aCounterType withType:(unsigned char)aType eventCt:(uint32_t)c high:(uint32_t)h low:(uint32_t)l;

- (ORReadOutList*)	readOutGroup;
- (void)			setReadOutGroup:(ORReadOutList*)newReadOutGroup;
- (NSMutableArray*) children;
- (uint32_t) calcProjection:(uint32_t *)pMult  xyProj:(uint32_t *)xyProj  tyProj:(uint32_t *)tyProj;

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

extern NSString* ORIpeV4SLTModelSecondsSetSendToFLTsChanged;
extern NSString* ORIpeV4SLTModelSecondsSetInitWithHostChanged;
extern NSString* ORIpeV4SLTModelSltScriptArgumentsChanged;
extern NSString* ORIpeV4SLTModelCountersEnabledChanged;
extern NSString* ORIpeV4SLTModelClockTimeChanged;
extern NSString* ORIpeV4SLTModelRunTimeChanged;
extern NSString* ORIpeV4SLTModelVetoTimeChanged;
extern NSString* ORIpeV4SLTModelDeadTimeChanged;
extern NSString* ORIpeV4SLTModelSecondsSetChanged;
extern NSString* ORIpeV4SLTModelStatusRegChanged;
extern NSString* ORIpeV4SLTModelControlRegChanged;
extern NSString* ORIpeV4SLTModelHwVersionChanged;

extern NSString* ORIpeV4SLTModelPatternFilePathChanged;
extern NSString* ORIpeV4SLTModelInterruptMaskChanged;
extern NSString* ORIpeV4SLTModelPageSizeChanged;
extern NSString* ORIpeV4SLTModelDisplayEventLoopChanged;
extern NSString* ORIpeV4SLTModelDisplayTriggerChanged;
extern NSString* ORIpeV4SLTPulserDelayChanged;
extern NSString* ORIpeV4SLTPulserAmpChanged;
extern NSString* ORIpeV4SLTSelectedRegIndexChanged;
extern NSString* ORIpeV4SLTWriteValueChanged;
extern NSString* ORIpeV4SLTSettingsLock;
extern NSString* ORIpeV4SLTStatusRegChanged;
extern NSString* ORIpeV4SLTControlRegChanged;
extern NSString* ORIpeV4SLTModelNextPageDelayChanged;
extern NSString* ORIpeV4SLTModelPollRateChanged;
extern NSString* ORIpeV4SLTModelReadAllChanged;

extern NSString* ORSLTV4cpuLock;	

