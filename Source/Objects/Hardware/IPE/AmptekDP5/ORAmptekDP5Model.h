//
//  ORAmptekDP5Model.h
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


#pragma mark ‚Äö√Ñ¬¢‚Äö√Ñ¬¢‚Äö√Ñ¬¢Imported Files
#import "ORDataTaker.h"
#import "ORAuxHw.h"
#import "ORAdcProcessing.h"
#import "ORIpeCard.h"
#import "SBC_Linking.h"
#import "SBC_Config.h"
#import "ipe4structure.h"

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
@class ORSafeQueue;

#define IsBitSet(A,B) (((A) & (B)) == (B))
#define ExtractValue(A,B,C) (((A) & (B)) >> (C))


//Amptek ASCII Commands
typedef struct AmptekDP5ASCIICommandsStruct {
	NSString*       setpoint;
	NSString*       name;
	NSString*       value;
	int 	        init;
	NSString*       comment;
	int				id;
} AmptekDP5ASCIICommandsStruct; 

enum AmptekDP5ASCIICommandEnum {
	kAmptekMCAC,
	kAmptekGAIA,
	kAmptekGAIF,
	kAmptekGAIN,
	kAmptekNumCommands //must be last
};





//Amptek constants
//status packet
#define kStatusLen 64
#define kFastCountOffset  0
#define kSlowCountOffset  4
#define kGPCounterOffset  8
#define kAccTimeOffset    12
#define kUnusedOffset     16
#define kRealtimeOffset   20
#define kFirmwareVersionOffset   24
#define kFPGAVersionOffset       25
#define kSerialNumberOffset      26
#define kDetectorTemperatureMSB  32
#define kDetectorTemperatureLSB  33
#define kBoardTemperature        34
#define kFlags1Offset            35
#define kFlags2Offset            36
#define kFirmwareBuildNumberOffset            37
#define kFlags4Offset            38
#define kDeviceIDOffset          39

#define D0 0x01
#define D1 0x02
#define D2 0x04
#define D3 0x08
#define D4 0x10
#define D5 0x20
#define D6 0x40
#define D7 0x80


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



//threading
#define kMaxNumUDPDataPackets 100000
#define kMaxNumUDPStatusPackets 100  // currently (2013) we expect max. 9 packets; but size might increase and legacy opera status may appear: use min 30 -tb-
#define kMaxUDPSizeDim 1500     //see comment below
#define kMaxNumADCChan 720      //see comment below
typedef struct{
    int started;
    int stopNow;
    id model;
    struct sockaddr_in sockaddr_data_from;
    int UDP_DATA_REPLY_SERVER_SOCKET;
    int isListeningOnDataServerSocket;

    //status packet buffer (I expect max. 
    char statusBuf[2][kMaxNumUDPStatusPackets][kMaxUDPSizeDim/*1500*/];//store the status UDP packets
    int statusBufSize[2][kMaxNumUDPStatusPackets];//store the size in bytes of the according status UDP packet
    int  numStatusPackets[2];
    TypeIpeCrateStatusBlock  crateStatusBlock[2]; //extra buffer for crate status
    //ADC buffer: 2 seconds buffer; 20 FLT * 36 chan = 720 ADCs -> 2*720=1440 Bytes; 100 000 samples per ADC channel -> 144 000 000 Bytes / 1440 Bytes (UDP Packet Size) = 100000 Pakete bzw. 144 MB
    //increased from 1440 to 1500 (packet size)
    char adcBuf[2][kMaxNumUDPDataPackets][kMaxUDPSizeDim/*1500*/];//store the UDP packets
    int adcBufSize[2][kMaxNumUDPDataPackets];//store the size in bytes of the according UDP packet
    int  numDataPackets[2];
    char adcBufReceivedFlag[2][kMaxNumUDPDataPackets];//flag which marks that this packet was received
    int  hasDataPackets[2];
    int  hasDataBytes[2];
    int  numfifo[2];
    int  numADCsInDataStream[2];
    
    int isSynchronized,wrIndex, rdIndex;
    uint32_t dataPacketCounter;
    //trace buffer: reorganized adcBuf to store all 100000 samples of one ADC channel (of 720 ADC channels)
    uint16_t adcTraceBuf[2][kMaxNumADCChan/*720*/][100000];//TODO: allocate dynamically? (I want to use pure C to be able to use it in Obj-C and C++) -tb-
    int32_t adcTraceBufCount[2][kMaxNumADCChan/*720*/];//count filled in shorts in accordingadcTraceBuf[2][720][100000]  -tb-
    
} THREAD_DATA;


//inherit from ORAuxHw to get info to header -tb-

@interface ORAmptekDP5Model : ORAuxHw /*OrcaObject*/ <ORDataTaker,ORAdcProcessing>  //added ORAdcProcessing 2016-02-11 -tb-
{
	@private
		uint32_t	hwVersion;
		NSString*		patternFilePath;
//TODO: rm   slt 		uint32_t	interruptMask;
		uint32_t	nextPageDelay;
		float			pulserAmp;
		float			pulserDelay;
		unsigned short  selectedRegIndex;
		uint32_t   writeValue;
		uint32_t	eventDataId;//TODO: remove or change -tb-
		uint32_t	multiplicityId;//TODO: remove -tb-
		uint32_t	spectrumEventId;
		uint32_t	waveFormId;
		uint32_t	fltEventId;
		uint32_t   eventCounter;
		int				actualPageIndex;
        TimedWorker*    poller;
		BOOL			pollingWasRunning;
		ORReadOutList*	readOutGroup;
		NSArray*		dataTakers;			//cache of data takers.   //TODO: remove   -tb-   2014 
		BOOL			first;
        BOOL            accessAllowedToHardwareAndSBC;                //TODO: remove -tb-


		BOOL            displayTrigger;    //< Display pixel and timing view of trigger data
		BOOL            displayEventLoop;  //< Display the event loop parameter
		uint32_t   lastDisplaySec;
		uint32_t   lastDisplayCounter;
		double          lastDisplayRate;
		
		uint32_t   lastSimSec;
		uint32_t   pageSize; //< Length of the ADC data (0..100us)

		// PMC_Link*		pmcLink;  //TODO: remove SLT stuff -tb-   2014 
        
		uint32_t controlReg;
        uint32_t statusReg;//deprecated 2013-06 -tb-
//TODO: rm   slt - -         uint32_t statusLowReg; //was statusRegLow
//TODO: rm   slt - -         uint32_t statusHighReg;//was statusRegHigh
		uint64_t clockTime;
		
        NSString* sltScriptArguments;
        BOOL secondsSetInitWithHost;
	
    	//UDP KCmd tab
		    //vars in GUI
        int crateUDPCommandPort;
        NSString* crateUDPCommandIP;
//TODO: rm            int crateUDPReplyPort;
        NSString* crateUDPCommand;//TODO: rename -tb-
        NSString* textCommand;//TODO: rename -tb-


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
		
        #define MAXDP5PACKETLENGTH 32775
		unsigned char dp5Packet[MAXDP5PACKETLENGTH +1000];// according to DP5 manual (+some spares) -tb-
        int currentDP5PacketLen; //current length
        int countReceivedPackets; //current length
        int expectedDP5PacketLen; //for adding up UDP packets ...
        int waitForResponse; //a flag ...
		
        
        
        
        
        
        #if 0
    int selectedFifoIndex;
    uint32_t pixelBusEnableReg;
    uint32_t eventFifoStatusReg;
	#endif
	
	//UDP Data Packet tab
//TODO: from SLT         int crateUDPDataPort;
//TODO: from SLT         NSString* crateUDPDataIP;
//TODO: from SLT     int crateUDPDataReplyPort;
		    //reply connection (server/listener)
//TODO: from SLT  	    int                UDP_DATA_REPLY_SERVER_SOCKET;//=-1;
//TODO: from SLT          struct sockaddr_in UDP_DATA_REPLY_servaddr;
        struct sockaddr_in sockaddr_data_from;
        socklen_t sockaddr_data_fromLength;
		    //sender connection (client)
//TODO: from SLT          	    int      UDP_DATA_COMMAND_CLIENT_SOCKET;
	    uint32_t UDP_DATA_COMMAND_CLIENT_IP;
       struct sockaddr_in UDP_DATA_COMMAND_sockaddrin_to;
    int isListeningOnDataServerSocket;
    int requestStoppingDataServerSocket;
//TODO: from SLT        int numRequestedUDPPackets;
	    //pthread handling
	    //pthread_t dataReplyThread;
        //pthread_mutex_t dataReplyThread_mutex;
    int sltDAQMode;
    
#if 0
    int cmdWArg1;
    int cmdWArg2;
    int cmdWArg3;
    int cmdWArg4;
    
    uint32_t BBCmdFFMask;
    NSString* crateUDPDataCommand;
#endif


    //data taking: flags and vars  //TODO: remove ALL SLT stuff -tb-   2014 
    int takeUDPstreamData;
    int takeRawUDPData;
    int takeADCChannelData;
    int takeEventData;
    int savedUDPSocketState;
    uint32_t partOfRunFLTMask;//TODO: remove SLT stuff -tb-   2014 
    
    //BB interface
//TODO: from SLT         int idBBforWCommand;
//TODO: from SLT         bool useBroadcastIdBB;
//TODO: from SLT         NSString * chargeBBFile;
         int lowLevelRegInHex;
    
    //BB charging
//TODO: REMOVE IT slt        OREdelweissFLTModel *fltChargingBB;
    //FIC charging
//TODO: REMOVE IT slt        OREdelweissFLTModel *fltChargingFIC;
    
    int resetEventCounterAtRunStart;
    int numSpectrumBins;
    int spectrumRequestType;
    int spectrumRequestRate;
    int isPollingSpectrum;
    struct timeval lastRequestTime;//    struct timezone tz; is obsolete ... -tb-
    

    //thread and UDP handling
      //pthread handling
    pthread_t dataReplyThread;
    pthread_mutex_t dataReplyThread_mutex;
    THREAD_DATA dataReplyThreadData;



    NSMutableArray* commandTable;//content of the Amptek Command Table View
    NSMutableArray* savedCommandTable;//saved content of the Amptek Command Table View for undo etc.
    ORSafeQueue*		cmdQueue;
    //NSData*				lastRequest;
    NSString* lastRequest;
    BOOL useCommandQueue;
    BOOL dropFirstSpectrum;
    BOOL autoReadbackSetpoint;
    int acquisitionTime;
    int realTime;
    int fastCounter;
    int slowCounter;
    int boardTemperature;
    int detectorTemperature;
    int deviceId;
    int FirmwareFPGAVersion;
    int serialNumber;
    
    BOOL needToDropFirstSpectrum;
    
    double maxValue[10];
    double minValue[10];
    double lowLimit[10];
    double hiLimit[10];

}

#pragma mark ‚Äö√Ñ¬¢‚Äö√Ñ¬¢‚Äö√Ñ¬¢Initialization
- (id)   init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
// - (void) setGuardian:(id)aGuardian;

#pragma mark ‚Äö√Ñ¬¢‚Äö√Ñ¬¢‚Äö√Ñ¬¢Notifications
- (void) registerNotificationObservers;
- (void) runIsAboutToStart:(NSNotification*)aNote;
- (void) runIsStopped:(NSNotification*)aNote;
- (void) runIsBetweenSubRuns:(NSNotification*)aNote;
- (void) runIsStartingSubRun:(NSNotification*)aNote;


#pragma mark •••Commands
- (void) queueStringCommand:(NSString*)aCommand;

#pragma mark ‚Äö√Ñ¬¢‚Äö√Ñ¬¢‚Äö√Ñ¬¢Accessors
- (int) serialNumber;
- (void) setSerialNumber:(int)aSerialNumber;
- (int) FirmwareFPGAVersion;
- (void) setFirmwareFPGAVersion:(int)aFirmwareFPGAVersion;
- (int) detectorTemperature;
- (void) setDetectorTemperature:(int)aDetectorTemperature;
- (int) deviceId;
- (void) setDeviceId:(int)aDeviceId;
- (int) boardTemperature;
- (void) setBoardTemperature:(int)aBoardTemperature;
- (int) slowCounter;
- (void) setSlowCounter:(int)aSlowCounter;
- (int) fastCounter;
- (void) setFastCounter:(int)aFastCounter;
- (int) realTime;
- (void) setRealTime:(int)aRealTime;
- (int) acquisitionTime;
- (void) setAcquisitionTime:(int)aAcquisitionTime;
- (BOOL) dropFirstSpectrum;
- (void) setDropFirstSpectrum:(BOOL)aDropFirstSpectrum;
- (NSString*) lastRequest;
- (void) setLastRequest:(NSString*)aLastRequest;
//- (NSData*) lastRequest;
//- (void) setLastRequest:(NSData*)aRequest;
- (int) commandQueueCount;
- (ORSafeQueue*) commandQueue;
- (void) clearCommandQueue;
- (void) processOneCommandFromQueue;

- (BOOL) useCommandQueue;
- (void) setUseCommandQueue:(BOOL)aValue;


- (NSMutableArray*) commandTable;
- (void) setCommandTable:(NSMutableArray*)aArray;
- (NSDictionary*) commandTableRow:(int)row;
- (int) commandTableCount;
- (void) initCommandTable;
- (int) setCommandTableItem:(NSString*)itemName setObject:(id)object forKey:(NSString*)key;
- (int) setCommandTableRow:(int)row setObject:(id)object forKey:(NSString*)key;

- (BOOL) loadCommandTableFile:(NSString*) filename;
- (BOOL) saveAsCommandTableFile:(NSString*) filename; 
- (NSString*) getCommandTableAsString; 


#pragma mark •••Main Scripting Methods
- (NSString*) commonScriptMethods;
- (void) commonScriptMethodSectionBegin;

//Scripts really shouldn't call any other methods unless you -REALLY- know what you're doing!
- (int) spectrumRequestRate;
- (void) setSpectrumRequestRate:(int)aSpectrumRequestRate;
- (int) spectrumRequestType;
- (void) setSpectrumRequestType:(int)aSpectrumRequestType;

- (BOOL) autoReadbackSetpoint;
- (void) setAutoReadbackSetpoint:(BOOL)aAutoReadbackSetpoint;



- (void) commonScriptMethodSectionEnd;

//-------------end of common script methods---------------------------------

//dont use in scripts:


- (int) isPollingSpectrum;
- (void) setIsPollingSpectrum:(int)aIsPollingSpectrum;
- (void) requestSpectrumTimedWorker;
- (int) numSpectrumBins;
- (void) setNumSpectrumBins:(int)aNumSpectrumBins;
- (NSString*) textCommand;
- (void) setTextCommand:(NSString*)aTextCommand;
- (int) resetEventCounterAtRunStart;
- (void) setResetEventCounterAtRunStart:(int)aResetEventCounterAtRunStart;
- (int) lowLevelRegInHex;
- (void) setLowLevelRegInHex:(int)aLowLevelRegInHex;

//TODO: rm   slt - - - (uint32_t) statusHighReg;
//TODO: rm   slt - - - (void) setStatusHighReg:(uint32_t)aStatusRegHigh;
//TODO: rm   slt - - - (uint32_t) statusLowReg;
//TODO: rm   slt - - - (void) setStatusLowReg:(uint32_t)aStatusRegLow;


- (int) takeADCChannelData;
- (void) setTakeADCChannelData:(int)aTakeADCChannelData;
- (int) takeRawUDPData;
- (void) setTakeRawUDPData:(int)aTakeRawUDPData;



//TODO: rm
#if 0
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
#endif




- (int) sltDAQMode;
- (void) setSltDAQMode:(int)aSltDAQMode;
//TODO: rm   slt - - - (int) numRequestedUDPPackets;
//TODO: rm   slt - - - (void) setNumRequestedUDPPackets:(int)aNumRequestedUDPPackets; 
- (int) isListeningOnDataServerSocket;
- (void) setIsListeningOnDataServerSocket:(int)aIsListeningOnDataServerSocket;
- (int) requestStoppingDataServerSocket;
- (void) setRequestStoppingDataServerSocket:(int)aValue;


//TODO: rm   slt - - - (int) crateUDPDataReplyPort;
//TODO: rm   slt - - - (void) setCrateUDPDataReplyPort:(int)aCrateUDPDataReplyPort;
//TODO: rm   slt - - - (NSString*) crateUDPDataIP;
//TODO: rm   slt - - - (void) setCrateUDPDataIP:(NSString*)aCrateUDPDataIP;
//TODO: rm   slt - - - (int) crateUDPDataPort;
//TODO: rm   slt - - - (void) setCrateUDPDataPort:(int)aCrateUDPDataPort;


#if 0
- (uint32_t) eventFifoStatusReg;
- (void) setEventFifoStatusReg:(uint32_t)aEventFifoStatusReg;
- (uint32_t) pixelBusEnableReg;
- (void) setPixelBusEnableReg:(uint32_t)aPixelBusEnableReg;
- (int) selectedFifoIndex;
- (void) setSelectedFifoIndex:(int)aSelectedFifoIndex;
#endif



- (int) isListeningOnServerSocket;
- (void) setIsListeningOnServerSocket:(int)aIsListeningOnServerSocket;
- (NSString*) crateUDPCommand;
- (void) setCrateUDPCommand:(NSString*)aCrateUDPCommand;

#if 0
- (int) crateUDPReplyPort;
- (void) setCrateUDPReplyPort:(int)aCrateUDPReplyPort;
#endif



- (NSString*) crateUDPCommandIP;
- (void) setCrateUDPCommandIP:(NSString*)aCrateUDPCommandIP;
- (int) crateUDPCommandPort;
- (void) setCrateUDPCommandPort:(int)aCrateUDPCommandPort;
- (BOOL) secondsSetInitWithHost;
- (void) setSecondsSetInitWithHost:(BOOL)aSecondsSetInitWithHost;
- (NSString*) sltScriptArguments;
- (void) setSltScriptArguments:(NSString*)aSltScriptArguments;
- (uint64_t) clockTime;
- (void) setClockTime:(uint64_t)aClockTime;

- (uint32_t) statusReg;
- (void) setStatusReg:(uint32_t)aStatusReg;
- (uint32_t) controlReg;
- (void) setControlReg:(uint32_t)aControlReg;

- (uint32_t) projectVersion;
- (uint32_t) documentVersion;
- (uint32_t) implementation;
- (uint32_t) hwVersion;//=SLT FPGA version/revision
- (void) setHwVersion:(uint32_t) aVersion;

- (NSString*) patternFilePath;
- (void) setPatternFilePath:(NSString*)aPatternFilePath;

- (uint32_t) nextPageDelay;
- (void) setNextPageDelay:(uint32_t)aDelay;
//TODO: rm   slt - (uint32_t) interruptMask;
//TODO: rm   slt - (void) setInterruptMask:(uint32_t)aInterruptMask;
- (float) pulserDelay;
- (void) setPulserDelay:(float)aPulserDelay;
- (float) pulserAmp;
- (void) setPulserAmp:(float)aPulserAmp;
- (short) getNumberRegisters;			
- (NSString*) getRegisterName: (short) anIndex;
- (uint32_t) getAddress: (short) anIndex;
//- (uint32_t) getAddressOffset: (short) anIndex;
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
- (int) parseReceivedDP5Packet;

//command socket (client)
- (int) openCommandSocket;
- (int) isOpenCommandSocket;
- (void) closeCommandSocket;


- (int) requestSpectrum;
- (int) requestSpectrumOfType:(int)pid2;
- (int) sendTextCommand;
- (int) shipSendTextCommandString:(NSString*)cmd;
- (int) sendTextCommandString:(NSString*)aString;
- (int) readbackTextCommand;
- (int) shipReadbackTextCommandString:(NSString*)cmd;
- (int) readbackTextCommandString:(NSString*)aString;
- (int) readbackCommandTableAsTextCommand;
- (int) parseReadbackCommandTableResponse:(int)length;
- (int) writeCommandTableSettingsAsTextCommand;
- (int) writeCommandTableInitSettingsAsTextCommand;

- (int) readbackCommandOfRow:(int)row;
- (int) writeCommandOfRow:(int)row;

- (int) sendUDPCommand;
- (int) sendUDPCommandString:(NSString*)aString;
- (int) sendUDPPacket:(unsigned char*)packet length:(int) aLength;
- (int) sendBinaryString:(NSString*)aString;

- (int) sendUDPCommandBinary;




#if 0
//TODO: UNUSED:
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
#endif

#pragma mark ***HW Access
//note that most of these method can raise 
//exceptions either directly or indirectly
//TODO: REMOVE IT slt- (int)           chargeBBWithFile:(char*)data numBytes:(int) numBytes;
//TODO: REMOVE IT slt- (int)           chargeBBusingSBCinBackgroundWithData:(NSData*)theData   forFLT:(OREdelweissFLTModel*) aFLT;
//TODO: REMOVE IT slt- (void)          chargeBBStatus:(ORSBCLinkJobStatus*) jobStatus;
//TODO: REMOVE IT slt- (int)           chargeFICusingSBCinBackgroundWithData:(NSData*)theData   forFLT:(OREdelweissFLTModel*) aFLT;
//TODO: REMOVE IT slt- (void)          chargeFICStatus:(ORSBCLinkJobStatus*) jobStatus;
- (int)           writeToCmdFIFO:(char*)data numBytes:(int) numBytes;  
- (void)		  readAllControlSettingsFromHW;

- (void)		  readAllStatus;
- (void)		  checkPresence;
//TODO: rm   slt - -- (uint32_t) readControlReg;
//TODO: rm   slt - -- (void)		  writeControlReg;
//TODO: rm   slt - -- (void)		  printControlReg;
//TODO: rm   slt - - - (uint32_t) readStatusReg;
//TODO: rm   slt - - - (uint32_t) readStatusLowReg;
//TODO: rm   slt - - - (uint32_t) readStatusHighReg;
//TODO: rm   slt - - - (void)		  printStatusReg;
//TODO: rm   slt - - - (void)          printStatusLowHighReg;

//TODO: rm   slt - - - (void) writePixelBusEnableReg;
//TODO: rm   slt - -- (void) readPixelBusEnableReg;

- (void)		writeFwCfg;
- (void)		writeSltReset;
- (void)		writeFltReset;
- (void)		writeEvRes;
- (uint64_t) readBoardID;
//TODO: rm   slt - - - (void) readEventFifoStatusReg;

#if 0 //deprecated 2013-06 -tb-
- (void)		  writeInterruptMask;
- (void)		  readInterruptMask;
- (void)		  readInterruptRequest;
- (void)		  printInterruptRequests;
- (void)		  printInterruptMask;
- (void)		  printInterrupt:(int)regIndex;
#endif


//- (void)		  dumpTriggerRAM:(int)aPageIndex;

- (void)		  writeReg:(int)index value:(uint32_t)aValue;
- (void)          writeReg:(int)index  forFifo:(int)fifoIndex value:(uint32_t)aValue;
- (void)		  rawWriteReg:(uint32_t) address  value:(uint32_t)aValue;//TODO: FOR TESTING AND DEBUGGING ONLY -tb-
- (uint32_t) rawReadReg:(uint32_t) address; //TODO: FOR TESTING AND DEBUGGING ONLY -tb-
- (uint32_t) readReg:(int) index;
- (uint32_t) readReg:(int) index forFifo:(int)fifoIndex;
- (id) writeHardwareRegisterCmd:(uint32_t)regAddress value:(uint32_t) aValue;
- (id) readHardwareRegisterCmd:(uint32_t)regAddress;
- (uint32_t) readHwVersion;
- (uint32_t) readTimeLow;
- (uint32_t) readTimeHigh;
- (uint64_t) getTime;

- (void)		reset;
- (void)		hw_config;
- (void)		hw_reset;
//- (void)		loadPulseAmp;
//- (void)		loadPulserValues;
//- (void)		swTrigger;
- (void)		initBoard;
- (int32_t)		getSBCCodeVersion;
- (int32_t)		getFdhwlibVersion;
- (int32_t)		getSltPciDriverVersion;
- (int32_t)		getPresentFLTsMap;

#pragma mark *** Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

- (uint32_t) spectrumEventId;
- (void) setSpectrumEventId: (uint32_t) DataId;
- (uint32_t) fltEventId;
- (void) setFltEventId: (uint32_t) DataId;
- (uint32_t) waveFormId;
- (void) setWaveFormId: (uint32_t) DataId;
- (uint32_t) eventDataId;
- (void) setEventDataId: (uint32_t) DataId;
- (uint32_t) multiplicityId;
- (void) setMultiplicityId: (uint32_t) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherCard;


#pragma mark •••Related to Adc or Bit Processing Protocol
// methods for setting LoAlarm, HiAlarm, LoLimit (=minValue), HiLimit (=maxValue) (from IPESlowControlModel -tb-)
//- (void) setLoAlarmForChan:(int)channel value:(double)aValue;
//- (void) setHiAlarmForChan:(int)channel value:(double)aValue;
//- (void) setLoLimitForChan:(int)channel value:(double)aValue;
//- (void) setHiLimitForChan:(int)channel value:(double)aValue;

#pragma mark •••Adc or Bit Processing Protocol
//- (void)processIsStarting;
//- (void)processIsStopping;
- (void) startProcessCycle;
- (void) endProcessCycle;
- (BOOL) processValue:(int)channel;
- (void) setProcessOutput:(int)channel value:(int)value; //not usually used, but needed for easy compatibility with the bit protocol
- (NSString*) processingTitle;
- (double) convertedValue:(int)channel;
- (double) maxValueForChan:(int)channel;
- (double) minValueForChan:(int)channel;
- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit  channel:(int)channel;

//custom script methods
- (double) setMaxValue:(double)val forChan:(int)channel;
- (double) setMinValue:(double)val forChan:(int)channel;
- (void) setAlarmRangeLow:(double)theLowLimit high:(double)theHighLimit  forChan:(int)channel;

#pragma mark •••Helpers
- (NSString*) identifier;


#pragma mark ‚Äö√Ñ¬¢‚Äö√Ñ¬¢‚Äö√Ñ¬¢DataTaker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) shipUDPPacket:(ORDataPacket*)aDataPacket data:(char*)udpPacket len:(int)len index:(int)aIndex type:(int)t;
- (void) saveReadOutList:(NSFileHandle*)aFile;
- (void) loadReadOutList:(NSFileHandle*)aFile;
- (BOOL) doneTakingData;

- (void) shipSltSecondCounter:(unsigned char)aType;
- (void) shipSltEvent:(unsigned char)aCounterType withType:(unsigned char)aType eventCt:(uint32_t)c high:(uint32_t)h low:(uint32_t)l;

- (ORReadOutList*)	readOutGroup;
- (void)			setReadOutGroup:(ORReadOutList*)newReadOutGroup;
- (NSMutableArray*) children;
- (uint32_t) calcProjection:(uint32_t *)pMult  xyProj:(uint32_t *)xyProj  tyProj:(uint32_t *)tyProj;

#pragma mark ‚Äö√Ñ¬¢‚Äö√Ñ¬¢‚Äö√Ñ¬¢SBC_Linking Protocol
- (NSString*) driverScriptName;
- (NSString*) sbcLockName;
- (NSString*) sbcLocalCodePath;
- (NSString*) codeResourcePath;
						 

@end

extern NSString* ORAmptekDP5ModelSerialNumberChanged;
extern NSString* ORAmptekDP5ModelFirmwareFPGAVersionChanged;
extern NSString* ORAmptekDP5ModelDetectorTemperatureChanged;
extern NSString* ORAmptekDP5ModelDeviceIDChanged;
extern NSString* ORAmptekDP5ModelBoardTemperatureChanged;
extern NSString* ORAmptekDP5ModelSlowCounterChanged;
extern NSString* ORAmptekDP5ModelFastCounterChanged;
extern NSString* ORAmptekDP5ModelRealTimeChanged;
extern NSString* ORAmptekDP5ModelAcquisitionTimeChanged;
extern NSString* ORAmptekDP5ModelDropFirstSpectrumChanged;
extern NSString* ORAmptekDP5ModelAutoReadbackSetpointChanged;
extern NSString* ORAmptekDP5ModelCommandTableChanged;
extern NSString* ORAmptekDP5ModelCommandQueueCountChanged;
extern NSString* ORAmptekDP5ModelIsPollingSpectrumChanged;
extern NSString* ORAmptekDP5ModelSpectrumRequestRateChanged;
extern NSString* ORAmptekDP5ModelSpectrumRequestTypeChanged;
extern NSString* ORAmptekDP5ModelNumSpectrumBinsChanged;
extern NSString* ORAmptekDP5ModelTextCommandChanged;
extern NSString* ORAmptekDP5ModelResetEventCounterAtRunStartChanged;
extern NSString* ORAmptekDP5ModelLowLevelRegInHexChanged;
extern NSString* ORAmptekDP5ModelStatusRegHighChanged;
extern NSString* ORAmptekDP5ModelStatusRegLowChanged;
extern NSString* ORAmptekDP5ModelTakeADCChannelDataChanged;
extern NSString* ORAmptekDP5ModelTakeRawUDPDataChanged;
extern NSString* ORAmptekDP5ModelChargeBBFileChanged;
extern NSString* ORAmptekDP5ModelUseBroadcastIdBBChanged;
extern NSString* ORAmptekDP5ModelIdBBforWCommandChanged;
extern NSString* ORAmptekDP5ModelTakeEventDataChanged;
extern NSString* ORAmptekDP5ModelTakeUDPstreamDataChanged;
extern NSString* ORAmptekDP5ModelCrateUDPDataCommandChanged;
extern NSString* ORAmptekDP5ModelBBCmdFFMaskChanged;
extern NSString* ORAmptekDP5ModelCmdWArg4Changed;
extern NSString* ORAmptekDP5ModelCmdWArg3Changed;
extern NSString* ORAmptekDP5ModelCmdWArg2Changed;
extern NSString* ORAmptekDP5ModelCmdWArg1Changed;
extern NSString* ORAmptekDP5ModelSltDAQModeChanged;
extern NSString* ORAmptekDP5ModelNumRequestedUDPPacketsChanged;
extern NSString* ORAmptekDP5ModelIsListeningOnDataServerSocketChanged;
extern NSString* ORAmptekDP5ModelCrateUDPDataReplyPortChanged;
extern NSString* ORAmptekDP5ModelCrateUDPDataIPChanged;
extern NSString* ORAmptekDP5ModelCrateUDPDataPortChanged;
extern NSString* ORAmptekDP5ModelEventFifoStatusRegChanged;
   //TODO: extern NSString* ORAmptekDP5ModelOpenCloseDataCommandSocketChanged;
extern NSString* ORAmptekDP5ModelPixelBusEnableRegChanged;
extern NSString* ORAmptekDP5ModelSelectedFifoIndexChanged;
extern NSString* ORAmptekDP5ModelIsListeningOnServerSocketChanged;
extern NSString* ORAmptekDP5ModelCrateUDPCommandChanged;
extern NSString* ORAmptekDP5ModelCrateUDPReplyPortChanged;
extern NSString* ORAmptekDP5ModelCrateUDPCommandIPChanged;
extern NSString* ORAmptekDP5ModelCrateUDPCommandPortChanged;
extern NSString* ORAmptekDP5ModelSecondsSetInitWithHostChanged;
extern NSString* ORAmptekDP5ModelSltScriptArgumentsChanged;

extern NSString* ORAmptekDP5ModelClockTimeChanged;
extern NSString* ORAmptekDP5ModelRunTimeChanged;
extern NSString* ORAmptekDP5ModelVetoTimeChanged;
extern NSString* ORAmptekDP5ModelDeadTimeChanged;
extern NSString* ORAmptekDP5ModelSecondsSetChanged;
extern NSString* ORAmptekDP5ModelStatusRegChanged;
extern NSString* ORAmptekDP5ModelControlRegChanged;
extern NSString* ORAmptekDP5ModelHwVersionChanged;

extern NSString* ORAmptekDP5ModelPatternFilePathChanged;
extern NSString* ORAmptekDP5ModelInterruptMaskChanged;
extern NSString* ORAmptekDP5ModelPageSizeChanged;
extern NSString* ORAmptekDP5ModelDisplayEventLoopChanged;
extern NSString* ORAmptekDP5ModelDisplayTriggerChanged;
extern NSString* ORAmptekDP5PulserDelayChanged;
extern NSString* ORAmptekDP5PulserAmpChanged;
extern NSString* ORAmptekDP5SelectedRegIndexChanged;
extern NSString* ORAmptekDP5WriteValueChanged;
extern NSString* ORAmptekDP5SettingsLock;
extern NSString* ORAmptekDP5StatusRegChanged;
extern NSString* ORAmptekDP5ControlRegChanged;
extern NSString* ORAmptekDP5ModelNextPageDelayChanged;
extern NSString* ORAmptekDP5ModelPollRateChanged;
extern NSString* ORAmptekDP5ModelReadAllChanged;

extern NSString* ORAmptekDP5V4cpuLock;	





//not necessary to declare ->							
//#pragma mark •••Other Categories
//@interface NSString (ParsingExtensions)
//-(NSArray *)csvRows;
//@end
