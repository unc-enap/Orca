//
//  OREdelweissSLTModel.h
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


#pragma mark ‚Ä¢‚Ä¢‚Ä¢Imported Files
#import "ORDataTaker.h"
#import "ORIpeCard.h"
#import "SBC_Linking.h"
#import "SBC_Config.h"

//for UDP sockets
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>


@class ORReadOutList;
@class ORDataPacket;
@class TimedWorker;
@class ORIpeFLTModel;
@class OREdelweissFLTModel;
@class PMC_Link;
@class SBC_Link;
@class ORSBCLinkJobStatus;

#define IsBitSet(A,B) (((A) & (B)) == (B))
#define ExtractValue(A,B,C) (((A) & (B)) >> (C))

//control reg bit masks
#define kCtrlInvert 	(0x00000001 << 16) //RW
#define kCtrlLedOff 	(0x00000001 << 15) //RW
#define kCtrlOnLine		(0x00000001 << 14) //RW
#define kCtrlNumFIFOs	(0x0000000f << 28) //RW

//status reg bit masks
#define kEWStatusIrq			(0x00000001 << 31) //R - cleared on W
#define kEWStatusPixErr		(0x00000001 << 16) //R - cleared on W
//status low/high new 2013/doc rev. 200 -tb-
#define kEWStatusPixErr2013		(0x00000001 << 16) //R - cleared on W


//Cmd reg bit masks
#define kEWCmdEvRes			(0x00000001 <<  3) //W - self cleared
#define kEWCmdFltReset		(0x00000001 <<  2) //W - self cleared
#define kEWCmdSltReset		(0x00000001 <<  1) //W - self cleared
#define kEWCmdFwCfg			(0x00000001 <<  0) //W - self cleared

#if 0
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
#endif

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


//Trigger Timing
#define kTrgTimingTrgWindow		(0x00000007 <<  16) //R/W
#define kTrgEndPageDelay		(0x000007FF <<   0) //R/W

@interface OREdelweissSLTModel : ORIpeCard <ORDataTaker,SBC_Linking>
{
	@private
		unsigned long	hwVersion;
		NSString*		patternFilePath;
		unsigned long	interruptMask;
		unsigned long	nextPageDelay;
		float			pulserAmp;
		float			pulserDelay;
		unsigned short  selectedRegIndex;
		unsigned long   writeValue;
		unsigned long	eventDataId;//TODO: remove or change -tb-
		unsigned long	multiplicityId;//TODO: remove -tb-
		unsigned long	waveFormId;
		unsigned long	fltEventId;
		unsigned long   eventCounter;
		int				actualPageIndex;
        TimedWorker*    poller;
		BOOL			pollingWasRunning;
		ORReadOutList*	readOutGroup;
		NSArray*		dataTakers;			//cache of data takers.
		BOOL			first;
        BOOL            accessAllowedToHardwareAndSBC;
		// ak, 9.12.07
		BOOL            displayTrigger;    //< Display pixel and timing view of trigger data
		BOOL            displayEventLoop;  //< Display the event loop parameter
		unsigned long   lastDisplaySec;
		unsigned long   lastDisplayCounter;
		double          lastDisplayRate;
		
		unsigned long   lastSimSec;
		unsigned long   pageSize; //< Length of the ADC data (0..100us)

		PMC_Link*		pmcLink;
        
		unsigned long controlReg;
		unsigned long statusReg;//deprecated 2013-06 -tb-
        unsigned long statusLowReg; //was statusRegLow
        unsigned long statusHighReg;//was statusRegHigh
		unsigned long long clockTime;
		
        NSString* sltScriptArguments;
        BOOL secondsSetInitWithHost;
	
    	//UDP KCmd tab
		    //vars in GUI
        int crateUDPCommandPort;
        NSString* crateUDPCommandIP;
        int crateUDPReplyPort;
        NSString* crateUDPCommand;
		    //sender connection (client)
	    int      UDP_COMMAND_CLIENT_SOCKET;
	    uint32_t UDP_COMMAND_CLIENT_IP;
        struct sockaddr_in UDP_COMMAND_sockaddrin_to;
        socklen_t  sockaddrin_to_len;//=sizeof(GLOBAL_sockin_to);
        struct sockaddr sock_to;
        int sock_to_len;//=sizeof(si_other);
		    //reply connection (server/listener)
	    int                UDP_REPLY_SERVER_SOCKET;//=-1;
        struct sockaddr_in UDP_REPLY_servaddr;
        struct sockaddr_in sockaddr_from;
        socklen_t sockaddr_fromLength;
		int isListeningOnServerSocket;
		
		
		
    int selectedFifoIndex;
    unsigned long pixelBusEnableReg;
    unsigned long eventFifoStatusReg;
	
	
	//UDP Data Packet tab
    int crateUDPDataPort;
        int useStandardUDPDataPorts;
        int fifoForUDPDataPort;
    NSString* crateUDPDataIP;
    int crateUDPDataReplyPort;
		    //reply connection (server/listener)
	    int                UDP_DATA_REPLY_SERVER_SOCKET;//=-1;
        struct sockaddr_in UDP_DATA_REPLY_servaddr;
        struct sockaddr_in sockaddr_data_from;
        socklen_t sockaddr_data_fromLength;
		    //sender connection (client)
	    int      UDP_DATA_COMMAND_CLIENT_SOCKET;
	    uint32_t UDP_DATA_COMMAND_CLIENT_IP;
        struct sockaddr_in UDP_DATA_COMMAND_sockaddrin_to;
    int isListeningOnDataServerSocket;
    int requestStoppingDataServerSocket;
    int numRequestedUDPPackets;
	    //pthread handling
	    pthread_t dataReplyThread;
        pthread_mutex_t dataReplyThread_mutex;
    int sltDAQMode;
    int cmdWArg1;
    int cmdWArg2;
    int cmdWArg3;
    int cmdWArg4;
    uint32_t BBCmdFFMask;
    NSString* crateUDPDataCommand;
    
    //data taking: flags and vars
    int takeUDPstreamData;
    int takeRawUDPData;
    int takeADCChannelData;
    int takeEventData;
    int savedUDPSocketState;
    uint32_t partOfRunFLTMask;
    
    //BB interface
    int idBBforWCommand;
    bool useBroadcastIdBB;
    NSString * chargeBBFile;
    int lowLevelRegInHex;
    
    //BB charging
    OREdelweissFLTModel *fltChargingBB;
    //FIC charging
    OREdelweissFLTModel *fltChargingFIC;
    
    int resetEventCounterAtRunStart;
    BOOL saveIonChanFilterOutputRecords;
}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Initialization
- (id)   init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (void) setGuardian:(id)aGuardian;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Notifications
- (void) registerNotificationObservers;
- (void) runIsAboutToStart:(NSNotification*)aNote;
- (void) runIsStopped:(NSNotification*)aNote;
- (void) runIsBetweenSubRuns:(NSNotification*)aNote;
- (void) runIsStartingSubRun:(NSNotification*)aNote;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Accessors
- (BOOL) saveIonChanFilterOutputRecords;
- (void) setSaveIonChanFilterOutputRecords:(BOOL)aSaveIonChanFilterOutputRecords;
- (int) fifoForUDPDataPort;
- (void) setFifoForUDPDataPort:(int)aFifoForUDPDataPort;
- (int) useStandardUDPDataPorts;
- (void) setUseStandardUDPDataPorts:(int)aUseStandardUDPDataPorts;
- (int) resetEventCounterAtRunStart;
- (void) setResetEventCounterAtRunStart:(int)aResetEventCounterAtRunStart;
- (int) lowLevelRegInHex;
- (void) setLowLevelRegInHex:(int)aLowLevelRegInHex;
- (unsigned long) statusHighReg;
- (void) setStatusHighReg:(unsigned long)aStatusRegHigh;
- (unsigned long) statusLowReg;
- (void) setStatusLowReg:(unsigned long)aStatusRegLow;
- (int) takeADCChannelData;
- (void) setTakeADCChannelData:(int)aTakeADCChannelData;
- (int) takeRawUDPData;
- (void) setTakeRawUDPData:(int)aTakeRawUDPData;
- (NSString *) chargeBBFile;
- (void) setChargeBBFile:(NSString *)aChargeBBFile;
- (bool) useBroadcastIdBB;
- (void) setUseBroadcastIdBB:(bool)aUseBroadcastIdBB;
- (int) idBBforWCommand;
- (void) setIdBBforWCommand:(int)aIdBBforWCommand;
- (int) takeEventData;
- (void) setTakeEventData:(int)aTakeEventData;
- (int) takeUDPstreamData;
- (void) setTakeUDPstreamData:(int)aTakeUDPstreamData;
- (NSString*) crateUDPDataCommand;
- (void) setCrateUDPDataCommand:(NSString*)aCrateUDPDataCommand;
- (uint32_t) BBCmdFFMask;
- (void) setBBCmdFFMask:(uint32_t)aBBCmdFFMask;
- (int) cmdWArg4;
- (void) setCmdWArg4:(int)aCmdWArg4;
- (int) cmdWArg3;
- (void) setCmdWArg3:(int)aCmdWArg3;
- (int) cmdWArg2;
- (void) setCmdWArg2:(int)aCmdWArg2;
- (int) cmdWArg1;
- (void) setCmdWArg1:(int)aCmdWArg1;
- (int) sltDAQMode;
- (void) setSltDAQMode:(int)aSltDAQMode;
- (int) numRequestedUDPPackets;
- (void) setNumRequestedUDPPackets:(int)aNumRequestedUDPPackets;
- (int) isListeningOnDataServerSocket;
- (void) setIsListeningOnDataServerSocket:(int)aIsListeningOnDataServerSocket;
- (int) requestStoppingDataServerSocket;
- (void) setRequestStoppingDataServerSocket:(int)aValue;


- (int) crateUDPDataReplyPort;
- (void) setCrateUDPDataReplyPort:(int)aCrateUDPDataReplyPort;
- (NSString*) crateUDPDataIP;
- (void) setCrateUDPDataIP:(NSString*)aCrateUDPDataIP;
- (int) crateUDPDataPort;
- (void) setCrateUDPDataPort:(int)aCrateUDPDataPort;
- (unsigned long) eventFifoStatusReg;
- (void) setEventFifoStatusReg:(unsigned long)aEventFifoStatusReg;
- (unsigned long) pixelBusEnableReg;
- (void) setPixelBusEnableReg:(unsigned long)aPixelBusEnableReg;
- (int) selectedFifoIndex;
- (void) setSelectedFifoIndex:(int)aSelectedFifoIndex;
- (int) isListeningOnServerSocket;
- (void) setIsListeningOnServerSocket:(int)aIsListeningOnServerSocket;
- (NSString*) crateUDPCommand;
- (void) setCrateUDPCommand:(NSString*)aCrateUDPCommand;
- (int) crateUDPReplyPort;
- (void) setCrateUDPReplyPort:(int)aCrateUDPReplyPort;
- (NSString*) crateUDPCommandIP;
- (void) setCrateUDPCommandIP:(NSString*)aCrateUDPCommandIP;
- (int) crateUDPCommandPort;
- (void) setCrateUDPCommandPort:(int)aCrateUDPCommandPort;
- (BOOL) secondsSetInitWithHost;
- (void) setSecondsSetInitWithHost:(BOOL)aSecondsSetInitWithHost;
- (NSString*) sltScriptArguments;
- (void) setSltScriptArguments:(NSString*)aSltScriptArguments;
- (unsigned long long) clockTime;
- (void) setClockTime:(unsigned long long)aClockTime;

- (unsigned long) statusReg;
- (void) setStatusReg:(unsigned long)aStatusReg;
- (unsigned long) controlReg;
- (void) setControlReg:(unsigned long)aControlReg;

- (SBC_Link*)sbcLink;
- (bool)sbcIsConnected;
- (bool)crateCPUIsConnected;
- (unsigned long) projectVersion;
- (unsigned long) documentVersion;
- (unsigned long) implementation;
- (unsigned long) hwVersion;//=SLT FPGA version/revision
- (void) setHwVersion:(unsigned long) aVersion;

- (NSString*) patternFilePath;
- (void) setPatternFilePath:(NSString*)aPatternFilePath;

- (unsigned long) nextPageDelay;
- (void) setNextPageDelay:(unsigned long)aDelay;
- (unsigned long) interruptMask;
- (void) setInterruptMask:(unsigned long)aInterruptMask;
- (float) pulserDelay;
- (void) setPulserDelay:(float)aPulserDelay;
- (float) pulserAmp;
- (void) setPulserAmp:(float)aPulserAmp;
- (short) getNumberRegisters;			
- (NSString*) getRegisterName: (short) anIndex;
- (unsigned long) getAddress: (short) anIndex;
//- (unsigned long) getAddressOffset: (short) anIndex;
- (short) getAccessType: (short) anIndex;

- (unsigned short) 	selectedRegIndex;
- (void)		setSelectedRegIndex: (unsigned short) anIndex;
- (unsigned long) 	writeValue;
- (void)		setWriteValue: (unsigned long) anIndex;
//- (void) loadPatternFile;

- (BOOL) displayTrigger; //< Staus of dispaly of trigger information
- (void) setDisplayTrigger:(BOOL) aState; 
- (BOOL) displayEventLoop; //< Status of display of event loop performance information
- (void) setDisplayEventLoop:(BOOL) aState;
- (unsigned long) pageSize; //< Length of the ADC data (0..100us)
- (void) setPageSize: (unsigned long) pageSize;   
- (void) sendSimulationConfigScriptON;
- (void) sendSimulationConfigScriptOFF;
- (void) installIPE4reader;
- (void) installAndCompileIPE4reader;
- (void) sendPMCCommandScript: (NSString*)aString;

#pragma mark ***Polling
- (TimedWorker *) poller;
- (void) setPoller: (TimedWorker *) aPoller;
- (void) setPollingInterval:(float)anInterval;
- (void) makePoller:(float)anInterval;

#pragma mark ***UDP Communication
//  UDP K command connection
//reply socket (server)
- (int) startListeningServerSocket;
- (void) stopListeningServerSocket;
- (int) openServerSocket;
- (void) closeServerSocket;
- (int) receiveFromReplyServer;

//command socket (client)
- (int) openCommandSocket;
- (int) isOpenCommandSocket;
- (void) closeCommandSocket;
- (int) sendUDPCommand;
- (int) sendUDPCommandString:(NSString*)aString;


//  UDP data packet connection
//reply socket (server)
- (int) startListeningDataServerSocket;
- (void) stopListeningDataServerSocket;
- (int) receiveFromDataReplyServer;
//command socket (client)
- (int) openDataCommandSocket;
- (void) closeDataCommandSocket;
- (int) isOpenDataCommandSocket;
- (int) sendUDPDataCommand:(char*)data length:(int) len;
- (int) sendUDPDataCommandString:(NSString*)aString;
- (int) sendUDPDataCommandRequestPackets:(int8_t) num;
- (int) sendUDPDataCommandRequestUDPData;
- (int) sendUDPDataCommandChargeBBFile;
- (void) loopCommandRequestUDPData;
- (int) sendUDPDataWCommandRequestPacketArg1:(int) arg1 arg2:(int) arg2 arg3:(int) arg3  arg4:(int) arg4; 
  //BB commands
- (int) sendUDPDataWCommandRequestPacket;

- (int) sendUDPDataTab0x0ACommand:(uint32_t) aBBCmdFFMask;//send 0x0A  Command
- (int) sendUDPDataTabBloqueCommand;
- (int) sendUDPDataTabDebloqueCommand;
- (int) sendUDPDataTabDemarrageCommand;


#pragma mark ***HW Access
//note that most of these method can raise 
//exceptions either directly or indirectly
- (int)           chargeBBWithFile:(char*)data numBytes:(int) numBytes;
- (int)           chargeBBusingSBCinBackgroundWithData:(NSData*)theData   forFLT:(OREdelweissFLTModel*) aFLT;
- (void)          chargeBBStatus:(ORSBCLinkJobStatus*) jobStatus;
- (int)           chargeFICusingSBCinBackgroundWithData:(NSData*)theData   forFLT:(OREdelweissFLTModel*) aFLT;
- (void)          chargeFICStatus:(ORSBCLinkJobStatus*) jobStatus;
- (void)          killSBCJob;
- (int)           writeToCmdFIFO:(char*)data numBytes:(int) numBytes;
- (void)		  readAllControlSettingsFromHW;

- (void)		  readAllStatus;
- (void)		  checkPresence;
- (unsigned long) readControlReg;
- (void)		  writeControlReg;
- (void)		  printControlReg;
- (unsigned long) readStatusReg;
- (unsigned long) readStatusLowReg;
- (unsigned long) readStatusHighReg;
- (void)		  printStatusReg;
- (void)          printStatusLowHighReg;

- (void) writePixelBusEnableReg;
- (void) readPixelBusEnableReg;

- (void)		writeFwCfg;
- (void)		writeSltReset;
- (void)		writeFltReset;
- (void)		writeEvRes;
- (unsigned long long) readBoardID;
- (void) readEventStatus:(unsigned long*)eventStatusBuffer;
- (void) readEventFifoStatusReg;

#if 0 //deprecated 2013-06 -tb-
- (void)		  writeInterruptMask;
- (void)		  readInterruptMask;
- (void)		  readInterruptRequest;
- (void)		  printInterruptRequests;
- (void)		  printInterruptMask;
- (void)		  printInterrupt:(int)regIndex;
#endif


//- (void)		  dumpTriggerRAM:(int)aPageIndex;

- (void)		  writeReg:(int)index value:(unsigned long)aValue;
- (void)          writeReg:(int)index  forFifo:(int)fifoIndex value:(unsigned long)aValue;
- (void)		  rawWriteReg:(unsigned long) address  value:(unsigned long)aValue;//TODO: FOR TESTING AND DEBUGGING ONLY -tb-
- (unsigned long) rawReadReg:(unsigned long) address; //TODO: FOR TESTING AND DEBUGGING ONLY -tb-
- (unsigned long) readReg:(int) index;
- (unsigned long) readReg:(int) index forFifo:(int)fifoIndex;
- (id) writeHardwareRegisterCmd:(unsigned long)regAddress value:(unsigned long) aValue;
- (id) readHardwareRegisterCmd:(unsigned long)regAddress;
- (unsigned long) readHwVersion;
- (unsigned long) readTimeLow;
- (unsigned long) readTimeHigh;
- (unsigned long long) getTime;

- (void)		reset;
- (void)		hw_config;
- (void)		hw_reset;
//- (void)		loadPulseAmp;
//- (void)		loadPulserValues;
//- (void)		swTrigger;
- (void)		initBoard;
- (void)		autoCalibrate;
- (long)		getSBCCodeVersion;
- (long)		getFdhwlibVersion;
- (long)		getSltPciDriverVersion;
- (long)		getPresentFLTsMap;

#pragma mark *** Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

- (unsigned long) fltEventId;
- (void) setFltEventId: (unsigned long) DataId;
- (unsigned long) waveFormId;
- (void) setWaveFormId: (unsigned long) DataId;
- (unsigned long) eventDataId;
- (void) setEventDataId: (unsigned long) DataId;
- (unsigned long) multiplicityId;
- (void) setMultiplicityId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherCard;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢DataTaker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) shipUDPPacket:(ORDataPacket*)aDataPacket data:(char*)udpPacket len:(int)len index:(int)aIndex type:(int)t;
- (void) saveReadOutList:(NSFileHandle*)aFile;
- (void) loadReadOutList:(NSFileHandle*)aFile;
- (BOOL) doneTakingData;

- (void) shipSltSecondCounter:(unsigned char)aType;
- (void) shipSltEvent:(unsigned char)aCounterType withType:(unsigned char)aType eventCt:(unsigned long)c high:(unsigned long)h low:(unsigned long)l;

- (ORReadOutList*)	readOutGroup;
- (void)			setReadOutGroup:(ORReadOutList*)newReadOutGroup;
- (NSMutableArray*) children;
- (unsigned long) calcProjection:(unsigned long *)pMult  xyProj:(unsigned long *)xyProj  tyProj:(unsigned long *)tyProj;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢SBC_Linking Protocol
- (NSString*) driverScriptName;
- (NSString*) cpuName;
- (NSString*) sbcLockName;
- (NSString*) sbcLocalCodePath;
- (NSString*) codeResourcePath;
						 
#pragma mark ‚Ä¢‚Ä¢‚Ä¢SBC Data Structure Setup
- (void) load_HW_Config;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;

@end

extern NSString* OREdelweissSLTModelSaveIonChanFilterOutputRecordsChanged;
extern NSString* OREdelweissSLTModelFifoForUDPDataPortChanged;
extern NSString* OREdelweissSLTModelUseStandardUDPDataPortsChanged;
extern NSString* OREdelweissSLTModelResetEventCounterAtRunStartChanged;
extern NSString* OREdelweissSLTModelLowLevelRegInHexChanged;
extern NSString* OREdelweissSLTModelStatusRegHighChanged;
extern NSString* OREdelweissSLTModelStatusRegLowChanged;
extern NSString* OREdelweissSLTModelTakeADCChannelDataChanged;
extern NSString* OREdelweissSLTModelTakeRawUDPDataChanged;
extern NSString* OREdelweissSLTModelChargeBBFileChanged;
extern NSString* OREdelweissSLTModelUseBroadcastIdBBChanged;
extern NSString* OREdelweissSLTModelIdBBforWCommandChanged;
extern NSString* OREdelweissSLTModelTakeEventDataChanged;
extern NSString* OREdelweissSLTModelTakeUDPstreamDataChanged;
extern NSString* OREdelweissSLTModelCrateUDPDataCommandChanged;
extern NSString* OREdelweissSLTModelBBCmdFFMaskChanged;
extern NSString* OREdelweissSLTModelCmdWArg4Changed;
extern NSString* OREdelweissSLTModelCmdWArg3Changed;
extern NSString* OREdelweissSLTModelCmdWArg2Changed;
extern NSString* OREdelweissSLTModelCmdWArg1Changed;
extern NSString* OREdelweissSLTModelSltDAQModeChanged;
extern NSString* OREdelweissSLTModelNumRequestedUDPPacketsChanged;
extern NSString* OREdelweissSLTModelIsListeningOnDataServerSocketChanged;
extern NSString* OREdelweissSLTModelCrateUDPDataReplyPortChanged;
extern NSString* OREdelweissSLTModelCrateUDPDataIPChanged;
extern NSString* OREdelweissSLTModelCrateUDPDataPortChanged;
extern NSString* OREdelweissSLTModelEventFifoStatusRegChanged;
extern NSString* OREdelweissSLTModelOpenCloseDataCommandSocketChanged;
extern NSString* OREdelweissSLTModelPixelBusEnableRegChanged;
extern NSString* OREdelweissSLTModelSelectedFifoIndexChanged;
extern NSString* OREdelweissSLTModelIsListeningOnServerSocketChanged;
extern NSString* OREdelweissSLTModelCrateUDPCommandChanged;
extern NSString* OREdelweissSLTModelCrateUDPReplyPortChanged;
extern NSString* OREdelweissSLTModelCrateUDPCommandIPChanged;
extern NSString* OREdelweissSLTModelCrateUDPCommandPortChanged;
extern NSString* OREdelweissSLTModelSecondsSetInitWithHostChanged;
extern NSString* OREdelweissSLTModelSltScriptArgumentsChanged;

extern NSString* OREdelweissSLTModelClockTimeChanged;
extern NSString* OREdelweissSLTModelRunTimeChanged;
extern NSString* OREdelweissSLTModelVetoTimeChanged;
extern NSString* OREdelweissSLTModelDeadTimeChanged;
extern NSString* OREdelweissSLTModelSecondsSetChanged;
extern NSString* OREdelweissSLTModelStatusRegChanged;
extern NSString* OREdelweissSLTModelControlRegChanged;
extern NSString* OREdelweissSLTModelHwVersionChanged;

extern NSString* OREdelweissSLTModelPatternFilePathChanged;
extern NSString* OREdelweissSLTModelInterruptMaskChanged;
extern NSString* OREdelweissSLTModelPageSizeChanged;
extern NSString* OREdelweissSLTModelDisplayEventLoopChanged;
extern NSString* OREdelweissSLTModelDisplayTriggerChanged;
extern NSString* OREdelweissSLTPulserDelayChanged;
extern NSString* OREdelweissSLTPulserAmpChanged;
extern NSString* OREdelweissSLTSelectedRegIndexChanged;
extern NSString* OREdelweissSLTWriteValueChanged;
extern NSString* OREdelweissSLTSettingsLock;
extern NSString* OREdelweissSLTStatusRegChanged;
extern NSString* OREdelweissSLTControlRegChanged;
extern NSString* OREdelweissSLTModelNextPageDelayChanged;
extern NSString* OREdelweissSLTModelPollRateChanged;
extern NSString* OREdelweissSLTModelReadAllChanged;

extern NSString* OREdelweissSLTV4cpuLock;	

