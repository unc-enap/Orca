//
//  ORIpeSLTModel.h
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


#pragma mark ¥¥¥Imported Files
#import "ORIpeFireWireCard.h"
#import "ORDataTaker.h"

@class ORFireWireInterface;
@class ORReadOutList;
@class ORDataPacket;
@class TimedWorker;
@class ORIpeFLTModel;

#define SLT_TRIGGER_SW    0x01  // Software
#define SLT_TRIGGER_I_N   0x07  // Internal + Neighbors
#define SLT_TRIGGER_LEFT  0x04  // left neighbor
#define SLT_TRIGGER_RIGHT 0x02  // right neighbor
#define SLT_TRIGGER_INT   0x08  // Internal only
#define SLT_TRIGGER_EXT   0x10  // External

#define SLT_INHIBIT_SW    0x01  // Software
#define SLT_INHIBIT_INT   0x02  // Internal
#define SLT_INHIBIT_EXT   0x04  // External
#define SLT_INHIBIT_ALL   0x07  // Internal + External
#define SLT_INHIBIT_NO    0x01  // None of both (only Software)

// not required any more !
#define SLT_NXPG_INT      0x00   // Internal
#define SLT_NXPG_EXT      0x01   // External
#define SLT_NXPG_SW       0x01   // Software

#define SLT_TESTPULS_NO   0x00   // None
#define SLT_TESTPULS_EXT  0x02   // External
#define SLT_TESTPULS_SW   0x01   // Software

#define SLT_SECSTROBE_INT 0x00   // Internal SecStrobe Signal
#define SLT_SECSTROBE_EXT 0x01   // Extern
#define SLT_SECSTROBE_SW  0x00   // Software - not available -
#define SLT_SECSTROBE_CAR 0x00   // Carry of Subsecond Counter
                                 //   - not available -

// called also watchdog in the slt hardware documentation
#define SLT_WATCHDOGSTART_INT   0x02   // Start with internal second strobe
#define SLT_WATCHDOGSTART_EXT   0x00   // External  - not available -
#define SLT_WATCHDOGSTART_SW    0x01   // Software

// Declaration of reg constants for module.
enum {
    kOutputBuffer,			// 0000
    kFirmWareRevision,		// 1000
    kGeoAddress,			// 1002
    kMCST_CBLTAddress,		// 1004
};

@interface ORIpeSLTModel : ORIpeFireWireCard <ORDataTaker>
{
//	@private
	@protected
		//control reg 
		BOOL veto;
		BOOL extInhibit;
		BOOL nopgInhibit;
		BOOL swInhibit;
		BOOL inhibit;

		//status reg
		BOOL ledInhibit;
		BOOL ledVeto;
		int triggerSource;
		int inhibitSource;
		int testPulseSource;
		int secStrobeSource;
		int watchDogStart;
		int enableDeadTimeCounter;
		NSString*		patternFilePath;

		//page status
		uint32_t pageStatusLow;
		uint32_t pageStatusHigh;
		uint32_t actualPage;
		uint32_t nextPage;

		//interrupts
		uint32_t interruptMask;

		//time management
		uint32_t nextPageDelay;

		//pulser generation
		float pulserAmp;
		float pulserDelay;

		// Register information
		unsigned short  selectedRegIndex;
		uint32_t   writeValue;

		//multiplicity trigger
		unsigned short nHit;
		unsigned short nHitThreshold;
		BOOL		   readAll;
		
		uint32_t	eventDataId;
		uint32_t	multiplicityId;
		uint32_t   eventCounter;
		
		float fpgaVersion;
		int actualPageIndex;
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
		
		
    	BOOL usingPBusSimulation;
		uint32_t   lastSimSec;
		uint32_t   pageSize; //< Length of the ADC data (0..100us)
		
}

#pragma mark ¥¥¥Initialization
- (id)   init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (void) findInterface;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) serviceChanged:(NSNotification*)aNote;
- (void) checkAndLoadFPGAs;
- (void) runIsAboutToStart:(NSNotification*)aNote;
- (void) runIsStopped:(NSNotification*)aNote;

#pragma mark ¥¥¥Accessors
- (NSString*) patternFilePath;
- (void) setPatternFilePath:(NSString*)aPatternFilePath;

- (uint32_t) pageStatusLow;
- (void) setPageStatusLow:(uint32_t)loPart 
					 high:(uint32_t)hiPart 
				   actual:(uint32_t)p0 
					 next:(uint32_t)p1;
- (uint32_t) pageStatusHigh;
- (uint32_t) actualPage;
- (uint32_t) nextPage;
- (uint32_t) nextPageDelay;
- (void) setNextPageDelay:(uint32_t)aDelay;
- (uint32_t) interruptMask;
- (void) setInterruptMask:(uint32_t)aInterruptMask;
- (float) fpgaVersion;
- (void) setFpgaVersion:(float)aFpgaVersion;
- (unsigned short) nHitThreshold;
- (void) setNHitThreshold:(unsigned short)aNHitThreshold;
- (unsigned short) nHit;
- (void) setNHit:(unsigned short)aNHit;
- (float) pulserDelay;
- (void) setPulserDelay:(float)aPulserDelay;
- (float) pulserAmp;
- (void) setPulserAmp:(float)aPulserAmp;
- (short) getNumberRegisters;			
- (NSString*) getRegisterName: (short) anIndex;
- (uint32_t) getAddressOffset: (short) anIndex;
- (short) getAccessType: (short) anIndex;

- (unsigned short) 	selectedRegIndex;
- (void)		setSelectedRegIndex: (unsigned short) anIndex;
- (uint32_t) 	writeValue;
- (void)		setWriteValue: (uint32_t) anIndex;
- (BOOL)	readAll;
- (void)    setReadAll:(BOOL)aState;
- (void) loadPatternFile;

- (BOOL) displayTrigger; //< Staus of dispaly of trigger information
- (void) setDisplayTrigger:(BOOL) aState; 
- (BOOL) displayEventLoop; //< Status of display of event loop performance information
- (void) setDisplayEventLoop:(BOOL) aState;
- (uint32_t) pageSize; //< Length of the ADC data (0..100us)
- (void) setPageSize: (uint32_t) pageSize;   
 
//status reg assess
- (BOOL) inhibit;
- (void) setInhibit:(BOOL)aInhibit;
- (BOOL) swInhibit;
- (void) setSwInhibit:(BOOL)aSwInhibit;
- (BOOL) nopgInhibit;
- (void) setNopgInhibit:(BOOL)aNopgInhibit;
- (BOOL) extInhibit;
- (void) setExtInhibit:(BOOL)aExtInhibit;
- (BOOL) veto;
- (void) setVeto:(BOOL)aVeto;

//control reg access
- (BOOL) ledInhibit;
- (void) setLedInhibit:(BOOL)aState;
- (BOOL) ledVeto;
- (void) setLedVeto:(BOOL)aState;
- (BOOL) enableDeadTimeCounter;
- (void) setEnableDeadTimeCounter:(BOOL)aState;
- (int) watchDogStart;
- (void) setWatchDogStart:(int)aWatchDogStart;
- (int) secStrobeSource;
- (void) setSecStrobeSource:(int)aSecStrobeSource;
- (int) testPulseSource;
- (void) setTestPulseSource:(int)aTestPulseSource;
- (int) inhibitSource;
- (void) setInhibitSource:(int)aInhibitSource;
- (int) triggerSource;
- (void) setTriggerSource:(int)aTriggerSource;
- (void) releaseSwInhibit;
- (void) setSwInhibit;
- (BOOL) usingNHitTriggerVersion;

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
- (void)		  writeControlReg;
- (void)		  printControlReg;
- (uint32_t) readStatusReg;
- (void)		  printStatusReg;
- (void)		  writeNextPageDelay;
- (void)		  writeStatusReg;
- (void)		  writeInterruptMask;
- (void)		  readInterruptMask;
- (void)		  printInterruptMask;
- (void)		  readPageStatus;
- (void)		  releaseAllPages;
- (void)		  dumpTriggerRAM:(int)aPageIndex;

- (void)		  writeReg:(unsigned short)index value:(uint32_t)aValue;
- (uint32_t) readReg:(unsigned short) index;
- (float)		  readVersion;
- (uint64_t) readDeadTime;
- (uint64_t) readVetoTime;
- (void)		reset;
- (void)		hw_config;
- (void)		hw_reset;
- (void)		loadPulseAmp;
- (void)		pulseOnce;
- (void)		loadPulserValues;
- (void)		swTrigger;
- (void)		initBoard;
- (void)		autoCalibrate;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

- (uint32_t) eventDataId;
- (void) setEventDataId: (uint32_t) DataId;
- (uint32_t) multiplicityId;
- (void) setMultiplicityId: (uint32_t) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherCard;

#pragma mark ¥¥¥DataTaker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) saveReadOutList:(NSFileHandle*)aFile;
- (void) loadReadOutList:(NSFileHandle*)aFile;
- (ORReadOutList*)	readOutGroup;
- (void)			setReadOutGroup:(ORReadOutList*)newReadOutGroup;
- (NSMutableArray*) children;
- (uint32_t) calcProjection:(uint32_t *)pMult  xyProj:(uint32_t *)xyProj  tyProj:(uint32_t *)tyProj;

@end

extern NSString* ORIpeSLTModelPatternFilePathChanged;
extern NSString* ORIpeSLTModelInterruptMaskChanged;
extern NSString* ORIpeSLTModelFpgaVersionChanged;
extern NSString* ORIpeSLTModelNHitThresholdChanged;
extern NSString* ORIpeSLTModelNHitChanged;
extern NSString* ORIpeSLTModelPageSizeChanged;
extern NSString* ORIpeSLTModelDisplayEventLoopChanged;
extern NSString* ORIpeSLTModelDisplayTriggerChanged;
extern NSString* ORIpeSLTPulserDelayChanged;
extern NSString* ORIpeSLTPulserAmpChanged;
extern NSString* ORIpeSLTSelectedRegIndexChanged;
extern NSString* ORIpeSLTWriteValueChanged;
extern NSString* ORIpeSLTSettingsLock;
extern NSString* ORIpeSLTStatusRegChanged;
extern NSString* ORIpeSLTControlRegChanged;
extern NSString* ORIpeSLTModelNextPageDelayChanged;
extern NSString* ORIpeSLTModelPageStatusChanged;
extern NSString* ORIpeSLTModelPollRateChanged;
extern NSString* ORIpeSLTModelReadAllChanged;
extern NSString* ORIpeSLTModelHW_ResetChanged;

