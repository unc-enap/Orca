/*
 *  ORTrigger32Model.h
 *  Orca
 *
 *  Created by Mark Howe on Tue May 4, 2004.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */
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

#import "ORVmeIOCard.h"
#import "ORDataTaker.h"
#import "ORGTIDGenerator.h"
#import "VME_eCPU_Config.h"

@class ORReadOutList;
@class ORAlarm;
@class ORTimer;


#pragma mark ¥¥¥Register Definitions
enum {
    //read commands
    kTotalLiveTimeReg       = 0x00,     //total livetime reg
    kTrigger1LiveTimeReg    = 0x04,     //trig1 livetime reg
    kTrigger2LiveTimeReg    = 0x08,     //trig2 livetime reg
    kUpperLiveTimeReg       = 0x0C,     //<0..7> top 8 bits of total livetimel, <8..15> top 8 bits trigger1, <16..23> top of trig2 
    kReadBoardID            = 0x10,     //read the board ID
    kReadStatusReg          = 0x14,     //read the status reg
    kReadTrigger2GTID		= 0x18,     //read the trigger2 GTID
    kReadTrigger1GTID		= 0x1C,     //read the trigger1 GTID
    kReadLowerTrigger2TimeReg   = 0x20, //read the lower trigger2 time reg
    kReadUpperTrigger2TimeReg   = 0x24, //read the upper trigger2 time reg
    kReadLowerTrigger1TimeReg	= 0x28, //read the lower trigger1 time reg
    kReadUpperTrigger1TimeReg	= 0x2C,	//read the upper trigger1 time reg
    kReadTestReg            = 0x30,	    //read the test reg
    kReadSoftGTIDReg		= 0x34,	    //read the soft gtid reg
    kScopeLiveTimeReg       = 0x38,     //scope livetime reg
    kAuxGTIDReg             = 0x3C,     //aux gtid reg
    
    //write commands
    kRegisterReset              = 0x00,     //resets most internal registers
    kTrigger2EventInputEnable   = 0x02,     //write 1 to enable Trigger2 Event Input
    kTrigger2BusyOutputEnable   = 0x04,     //write 1 to enable Trigger2 Busy Output
    kTimeClockCounterEnable     = 0x06,     //write 1 to enable the time clock counter
    kTimeClockCounterReset      = 0x08,     //resets the time clock counter to count 0
    kTrigger2GTEventReset       = 0x0A,     //resets trigger2 adc event and trigger2 GT clock status bits
    kTrigger1GTEventReset       = 0x0C,      //reset muix event and valid trigger1 GT clock status bits
    kCountErrorReset		= 0x0E,     //reset the count error status bit
    kTestLatchTrigger2GTID	= 0x10,     //latches GTID count into trigger2 GTID register
    kTestLatchTrigger2Time	= 0x12,     //latches the Time Clock into trigger2 Timer register
    kTestLatchTrigger1GTID  = 0x14,     //latches GTID count into trigger1 GTID register
    kTestLatchTrigger1Time  = 0x16,     //latches the Time Clock into trigger1 Timer register
    kSoftGTRIG              = 0x18,     //simulates a GTRIG pulse on the time bus. Inc GTID.
    kSoftSYNCLR             = 0x1A,     //simulates a SYNCLR pulse on the time bus. resets lower GTID.
    kSoftGTRIGandSYNCLR		= 0x1C,     //simulates GTRIG and SYNCLR pulse on the time bus.
    kSoftSYNCLR24           = 0x1E,     //simulates a SYNCLR24 pulse on the time bus. resets lower GTID.
    kGTOrOutputEnable		= 0x20,     //controls ORing of the Trigger2 and trigger GT outputs
    kMSamEventReset         = 0x22,     //reset the M-SAM status bit.
    kRequestSoftGTID		= 0x24,     //soft gtid into soft gtid register.
    kLiveTimeReset          = 0x26,     //reset livetime counter
    kLiveTimeEnable         = 0x28,     //livetime enable (1=enable, 0=disable)
    kLatchLiveTime          = 0x2A,     //latch the livetime counters
    kLoadTestRegister		= 0x30,     //load test register
    kLoadGTIDCounter		= 0x34,     //load GTID
    kLoadLowerTimeCounter   = 0x38,     //load Lower time register
    kLoadUpperTimeCounter   = 0x3C,     //load Upper time register
};

#pragma mark ¥¥¥Static Declarations
enum {
    kTrigger1EventMask		    = 1 << 0,
    kValidTrigger1GTClockMask   = 1 << 1,
    kTrigger2EventMask		    = 1 << 2,
    kValidTrigger2GTClockMask   = 1 << 3,
    kCountErrorMask             = 1 << 4,
    kTimeClockCounterEnabledMask  = 1 << 5,
    kTrigger2EventInputEnabledMask= 1 << 6,
    kBusyOutputEnabledMask	    = 1 << 7,
    kTrigger1GTOutputOREnabledMask= 1 << 8,
    kTrigger2GTOutputOREnabledMask= 1 << 9,
    kMSamEventMask              = 1 << 10,
    kEventMask                  = kTrigger1EventMask | kTrigger2EventMask
};

#define 	kNumTriggerChannels 		8

enum {
    kShipEvt1ClkMask    = 1<<0,
    kShipEvt2ClkMask    = 1<<1,
    kUseSoftwareGtIdMask= 1<<2,
    kUseMSAMMask	= 1<<3,
    kUseNoHardwareMask  = 1<<4,
    kClockEnabled       = 1<<5,
    kTrigger1GtXorMask  = 1<<6,
    kTrigger2GtXorMask  = 1<<7,
    kTrigger2EventInputEnableMask = 1<<8,
    kTrigger2BusyEnabledMask      = 1<<9,
    kLiveTimeEnabledMask      = 1<<10
}eTrigger32_Options;

@interface ORTrigger32Model :  ORVmeIOCard <ORDataTaker,ORGTIDGenerator>
{
    @private
	//values that can be loaded to hw
	unsigned long   gtIdValue;
	unsigned long   lowerTimeValue;
	unsigned long   upperTimeValue;
	unsigned long   testRegisterValue;
    unsigned long   clockDataId;
    unsigned long   gtid1DataId;
    unsigned long   gtid2DataId;
    unsigned long   liveTimeDataId;
		
	//hw initialization conditions
	BOOL		trigger2EventInputEnable;
	BOOL		trigger2BusyEnabled;
	
	//data taking variables
	ORReadOutList*  trigger1Group;
	ORReadOutList*  trigger2Group;	
	NSArray*	dataTakers1;       //cache of data takers.
	NSArray*	dataTakers2;       //cache of data takers.
	unsigned long   gtErrorCount;
	int				mSamPrescale;
	
	//used privately in the data taking process
	unsigned long eventPlaceHolder1;
	unsigned long eventPlaceHolder2;
	unsigned long timePlaceHolder1;
	unsigned long timePlaceHolder2;
	ORTimer*	timer;
	
	//run conditions
	BOOL		shipEvt1Clk;
	BOOL		shipEvt2Clk;
	BOOL		useSoftwareGtId;
	BOOL		useMSAM;
	BOOL		useNoHardware;
	BOOL		clockEnabled;
	BOOL		trigger1GtXor;
	BOOL		trigger2GtXor;
	BOOL		liveTimeEnabled;
	
	//trigger labels
	NSString*   trigger1Name;
	NSString*   trigger2Name;
	
	//alarms
	ORAlarm*    softwareGtIdAlarm;
	ORAlarm*    useNoHardwareAlarm;
    

    BOOL        isRunning;
    BOOL        liveTimeCalcRunning;
    long long   total_live;
    long long   trig1_live;
    long long   trig2_live;
    long long   scope_live;

    long long   last_total_live;
    long long   last_trig1_live;
    long long   last_trig2_live;
    long long   last_scope_live;
	long		noDataCount;  
	long		totalDataCount;
    BOOL		restartClkAtRunStart;
}

#pragma mark ¥¥¥Accessors
- (BOOL) restartClkAtRunStart;
- (void) setRestartClkAtRunStart:(BOOL)aRestartClkAtRunStart;
- (BOOL) isRunning;
- (int) mSamPrescale;
- (void) setMSamPrescale:(int)aValue;
- (unsigned long)testRegisterValue;
- (void)setTestRegisterValue:(unsigned long)aTestRegisterValue;
- (unsigned long) gtIdValue;
- (void) setGtIdValue:(unsigned long)newGtidValue;
- (unsigned long)lowerTimeValue;
- (void)setLowerTimeValue:(unsigned long)aLowerTimeValue;
- (unsigned long)upperTimeValue;
- (void)setUpperTimeValue:(unsigned long)anUpperTimeValue;
- (unsigned long) clockDataId;
- (void) setClockDataId: (unsigned long) ClockDataId;
- (unsigned long) gtid1DataId;
- (void) setGtid1DataId: (unsigned long) GtidDataId;
- (unsigned long) gtid2DataId;
- (void) setGtid2DataId: (unsigned long) GtidDataId;
- (unsigned long) liveTimeDataId;
- (void) setLiveTimeDataId: (unsigned long) aLiveTimeDataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherObj;
- (unsigned long) optionMask;
- (BOOL) liveTimeCalcRunning;
- (void) setLiveTimeCalcRunning: (BOOL) flag;

- (ORReadOutList*) trigger1Group;
- (void) setTrigger1Group:(ORReadOutList*)newTrigger1Group;
- (ORReadOutList*) trigger2Group;
- (void) setTrigger2Group:(ORReadOutList*)newTrigger2Group;
- (NSMutableArray*) children;
- (BOOL) shipEvt1Clk;
- (BOOL) shipEvt2Clk;
- (void) setShipEvt1Clk:(BOOL)state;
- (void) setShipEvt2Clk:(BOOL)state;
- (unsigned long) gtErrorCount;
- (void) setGtErrorCount:(unsigned long)count;
- (BOOL) trigger2EventInputEnable;
- (void) setTrigger2EventInputEnable:(BOOL)state;
- (BOOL) trigger2BusyEnabled;
- (void) setTrigger2BusyEnabled:(BOOL)state;
- (BOOL) useSoftwareGtId;
- (void) setUseSoftwareGtId:(BOOL)newUseSoftwareGtId;
- (BOOL) trigger1GtXor;
- (void) setTrigger1GtXor:(BOOL)flag;
- (BOOL) trigger2GtXor;
- (void) setTrigger2GtXor:(BOOL)flag;

- (BOOL) useNoHardware;
- (void) setUseNoHardware:(BOOL)newUseNoHardware;
- (BOOL) useMSAM;
- (void) setUseMSAM:(BOOL)flag;
- (BOOL) clockEnabled;
- (void) setClockEnabled:(BOOL)flag;
- (BOOL) liveTimeEnabled;
- (void) setLiveTimeEnabled:(BOOL)flag;

- (NSString *) trigger1Name;
- (void) setTrigger1Name: (NSString *) aTrigger1Name;

- (NSString *) trigger2Name;
- (void) setTrigger2Name: (NSString *) aTrigger2Name;

#pragma mark ***HW Access Read commands
- (unsigned long) 	readBoardID;
- (unsigned long) 	readStatus;  
- (unsigned long) 	readTrigger1GTID; 
- (unsigned long) 	readTrigger2GTID; 
- (unsigned long)   readLowerTrigger2Time;
- (unsigned long)   readUpperTrigger2Time;
- (unsigned long)   readLowerTrigger1Time;
- (unsigned long)   readUpperTrigger1Time;
- (unsigned long)   readTestRegister;
- (unsigned long)   readSoftGTIDRegister;
- (void)            readLiveTimeCounters;
- (unsigned long)   readAuxGTIDReg;

#pragma mark ***HW Access Write commands
- (void) reset;  
- (void) enableTrigger2EventInput:(BOOL) enable;
- (void) enableBusyOutput:(BOOL)enable;
- (void) enableTimeClockCounter:(BOOL)enable;
- (void) resetTimeClockCounter;
- (void) resetTrigger2GTStatusBit;
- (void) resetTrigger1GTStatusBit;
- (void) resetCountError;
- (void) resetClock;
- (void) testLatchTrigger1GTID;
- (void) testLatchTrigger2GTID;
- (void) testLatchTrigger2Time;
- (void) testLatchTrigger1Time;
- (void) softGT;
- (void) requestSoftGTID; 
- (void) syncClear; 
- (void) softGTSyncClear;
- (void) syncClear24;
- (void) enableGTOrEnable:(unsigned short)aValue;
- (void) clearMSAM;
- (void) loadTestRegister:(unsigned long)aValue;
- (void) loadGTID:(unsigned long)  aVal;
- (void) loadLowerTimerCounter:(unsigned long)  aVal;
- (void) loadUpperTimerCounter:(unsigned long)  aVal;
- (void) enableLiveTime:(BOOL)enable;
- (void) resetLiveTime;
- (void) latchLiveTime;
- (void) dumpLiveTimeCounters;
- (void) shipLiveTimeRecords:(short)start;
- (void) shipLiveTimeMidRun;

- (unsigned long) getGtId1;
- (unsigned long) getGtId2;

- (void) initBoard;
- (void) initBoardPart1;
- (void) initBoardPart2;
- (void) standAloneMode:(BOOL)state;

//- (void) testLatchVmeClockCount;
- (BOOL) anEvent:(unsigned short)  aVal;
- (BOOL) eventBit1Set:(unsigned short)aVal;
- (BOOL) eventBit2Set:(unsigned short)aVal;
- (BOOL) validEvent1GtBitSet:(unsigned short)  aVal;
- (BOOL) validEvent2GtBitSet:(unsigned short)  aVal;
- (BOOL) countErrorBitSet:(unsigned short)  aVal;
//- (BOOL) clockEnabledBitSet:(unsigned short)  aVal;

- (NSString*) 		boardIdString;
- (unsigned short) 	decodeBoardId:(unsigned short) aValue;
- (unsigned short) 	decodeBoardType:(unsigned short) aValue;
- (unsigned short) 	decodeBoardRev:(unsigned short) aValue;
- (NSString *)		decodeBoardName:(unsigned short) aValue;
- (void) checkSoftwareGtIdAlarm;
- (void) checkUseNoHardwareAlarm;

#pragma mark ¥¥¥DataTaker
- (NSDictionary*) dataRecordDescription;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (int) load_eCPU_HW_Config_Structure:(VME_crate_config*)configStruct index:(int)index;
- (void) saveReadOutList:(NSFileHandle*)aFile;
- (void) loadReadOutList:(NSFileHandle*)aFile;

#pragma mark ¥¥¥GTID Generator
- (unsigned long)  requestGTID;

#pragma mark ¥¥¥Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end


#pragma mark ¥¥¥External String Definitions
extern NSString* ORTrigger32ModelRestartClkAtRunStartChanged;
extern NSString* ORTrigger32TestValueChangedNotification;
extern NSString* ORTrigger32GtIdValueChangedNotification;
extern NSString* ORTrigger32LowerTimeValueChangedNotification;
extern NSString* ORTrigger32UpperTimeValueChangedNotification;

extern NSString* ORTrigger32ShipEvt1ClkChangedNotification;
extern NSString* ORTrigger32ShipEvt2ClkChangedNotification;
extern NSString* ORTrigger32GtErrorCountChangedNotification;
extern NSString* ORTrigger32Trigger2EventEnabledNotification;
extern NSString* ORTrigger32Trigger2BusyEnabledNotification;

extern NSString* ORTrigger32UseSoftwareGtIdChangedNotification;
extern NSString* ORTrigger32UseNoHardwareChangedNotification;
extern NSString* ORTrigger321NameChangedNotification;
extern NSString* ORTrigger322NameChangedNotification;
extern NSString* ORTrigger32MSAMChangedNotification;

extern NSString* ORTrigger32SettingsLock;
extern NSString* ORTrigger32SpecialLock;
extern NSString* ORTrigger32Trigger1GTXorChangedNotification;
extern NSString* ORTrigger32Trigger2GTXorChangedNotification;

extern NSString* ORTrigger32ClockEnabledChangedNotification;
extern NSString* ORTrigger32LiveTimeEnabledChangedNotification;

extern NSString* ORTrigger32MSamPrescaleChangedNotification;
extern NSString* ORTrigger32LiveTimeCalcRunningChangedNotification;
