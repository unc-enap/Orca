/*
 *  ORTriggerModel.h
 *  Orca
 *
 *  Created by Mark Howe on Sat Nov 16 2002.
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
#import "VME_eCPU_Config.h"

@class ORReadOutList;
@class ORAlarm;
@class ORTimer;

#pragma mark ¥¥¥Register Definitions
enum {
    kResetRegister              = 0x00,
    kBusyEnable			= 0x02,
    kCountErrReset              = 0x04,
    kEvent1Reset                = 0x06,
    kEvent2Reset                = 0x08,
    kMultiBoardOutputEnable     = 0x0a,
    kClrMSAMEnable		= 0x0c,
    kBoardIDRegister 		= 0x10,
    kStatusRegister 		= 0x12,
    kLowerEvent2GtIdRegister 	= 0x14,
    kUpperEvent2GtIdRegister	= 0x16,
    kLowerEvent1GtIdRegister	= 0x18,
    kUpperEvent1GtIdRegister	= 0x1A,
    kLoadLowerGtId              = 0x14,
    kLoadUpperGtId              = 0x16,
    kSoftGtTrig			= 0x20,
    kSoftSynClr			= 0x22,
    kSoftGtTrigSynClr		= 0x24,
    kSoftSynClr24               = 0x26,
    kTestLatchGtId1             = 0x28,
    kTestLatchGtId2             = 0x2a
};

#pragma mark ¥¥¥Static Declarations
enum {
    kEvent1Mask         = 0x01,	//<0>
    kEvent2Mask         = 0x02,	//<1>
    kValidEvent2GtMask  = 0x04,	//<2>
    kCountErrorMask 	= 0x08,	//<3?
                                //kClockEnabledMask = 0x10,	//<4>
    kValidEvent1GtMask  = 0x20,	//<5>
    kMSAM_Mask			= 0x10, //<4>
    kEventMask          = kEvent1Mask | kEvent2Mask,
};

#define 	kNumTriggerChannels 		8

@interface ORTriggerModel :  ORVmeIOCard <ORDataTaker>
{
    @private
	unsigned short gtidLower;
	unsigned short gtidUpper;
	
	//unsigned short vmeClkLower;
	//unsigned short vmeClkMiddle;
	//unsigned short vmeClkUpper;
	
	BOOL shipEvt1Clk;
	BOOL shipEvt2Clk;
	
	BOOL initWithMultiBoardEnabled;
	BOOL initWithTrig2InhibitEnabled;
	
	
	ORReadOutList* trigger1Group;
	ORReadOutList* trigger2Group;
	
	NSArray* dataTakers1;	//cache of data takers.
	NSArray* dataTakers2;	//cache of data takers.
	
	uint32_t gtErrorCount;
	
	BOOL useSoftwareGtId;
	uint32_t softwareGtId;
	BOOL useMSAM;
	
	BOOL useNoHardware;
	
	ORAlarm*    softwareGtIdAlarm;
	ORAlarm*    useNoHardwareAlarm;
     
	NSString*   trigger1Name;
	NSString*   trigger2Name;

	//private
	uint32_t eventPlaceHolder1;
	uint32_t eventPlaceHolder2;
	uint32_t timePlaceHolder1;
	uint32_t timePlaceHolder2;
	ORTimer* timer;
    
    uint32_t   clockDataId;
    uint32_t   gtidDataId;
    
}

#pragma mark ¥¥¥Accessors
- (unsigned short) gtidLower;
- (void) setGtidLower:(unsigned short)newGtidLower;
- (unsigned short) gtidUpper;
- (void) setGtidUpper:(unsigned short)newGtidUpper;
    //- (unsigned short) vmeClkLower;
    //- (void) setVmeClkLower:(unsigned short)newVmeClkLower;
    //- (unsigned short) vmeClkMiddle;
    //- (void) setVmeClkMiddle:(unsigned short)newVmeClkMiddle;
    //- (unsigned short) vmeClkUpper;
    //- (void) setVmeClkUpper:(unsigned short)newVmeClkUpper;
- (ORReadOutList*) trigger1Group;
- (void) setTrigger1Group:(ORReadOutList*)newTrigger1Group;
- (ORReadOutList*) trigger2Group;
- (void) setTrigger2Group:(ORReadOutList*)newTrigger2Group;
- (NSMutableArray*) children;
- (BOOL) shipEvt1Clk;
- (BOOL) shipEvt2Clk;
- (void) setShipEvt1Clk:(BOOL)state;
- (void) setShipEvt2Clk:(BOOL)state;
- (uint32_t) gtErrorCount;
- (void) setGtErrorCount:(uint32_t)count;
- (BOOL) initWithMultiBoardEnabled;
- (void) setInitWithMultiBoardEnabled:(BOOL)newInitWithMultiBoardEnabled;
- (BOOL) initWithTrig2InhibitEnabled;
- (void) setInitWithTrig2InhibitEnabled:(BOOL)newInitWithTrig2InhibitEnabled;
- (BOOL) useSoftwareGtId;
- (void) setUseSoftwareGtId:(BOOL)newUseSoftwareGtId;

- (BOOL) useNoHardware;
- (void) setUseNoHardware:(BOOL)newUseNoHardware;
- (BOOL) useMSAM;
- (void) setUseMSAM:(BOOL)flag;
- (uint32_t) softwareGtId;
- (void) setSoftwareGtId:(uint32_t)newSoftwareGtId;
- (void) incrementSoftwareGtId;

- (NSString *) trigger1Name;
- (void) setTrigger1Name: (NSString *) aTrigger1Name;

- (NSString *) trigger2Name;
- (void) setTrigger2Name: (NSString *) aTrigger2Name;

- (uint32_t) clockDataId;
- (void) setClockDataId: (uint32_t) ClockDataId;
- (uint32_t) gtidDataId;
- (void) setGtidDataId: (uint32_t) GtidDataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherObj;


#pragma mark ¥¥¥Hardware Access
- (unsigned short) 	readBoardID;
- (unsigned short) 	readStatus;  

- (void) reset;  
- (void) resetGtEvent1;
- (void) resetGtEvent2;
- (void) enableMultiBoardOutput:(BOOL) enable;
	 //- (void) enableClock:(BOOL) enable;
- (void) enableBusyOutput:(BOOL)enable;

    //- (void) resetClock;  
- (unsigned short) 	readLowerEvent1GtId; 
- (unsigned short) 	readUpperEvent1GtId; 
- (unsigned short) 	readLowerEvent2GtId; 
- (unsigned short) 	readUpperEvent2GtId; 
- (void) loadLowerGtId:(unsigned short)  aVal;
- (void) loadUpperGtId:(unsigned short)  aVal;
- (uint32_t) getGtId1;
- (uint32_t) getGtId2;
    /*
     - (unsigned short) 	readLowerVmeClock; 
     - (unsigned short) 	readMiddleVmeClock; 
     - (unsigned short) 	readUpperVmeClock;
     - (void) loadLowerVmeClock:(unsigned short)  aVal;
     - (void) loadMiddleVmeClock:(unsigned short)  aVal;
     - (void) loadUpperVmeClock:(unsigned short)  aVal;
     */
- (void) softGT; 
- (void) syncClear; 
- (void) softGTSyncClear;
- (void) syncClear24;
- (void) testLatchGtId1;
- (void) testLatchGtId2;
- (void) clearMSAM;

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
- (uint32_t)  requestGTID;
@end


#pragma mark ¥¥¥External String Definitions
extern NSString* ORTriggerGtidLowerChangedNotification;
extern NSString* ORTriggerGtidUpperChangedNotification;
extern NSString* ORTriggerShipEvt1ClkChangedNotification;
extern NSString* ORTriggerShipEvt2ClkChangedNotification;
extern NSString* ORTriggerShipGtErrorCountChangedNotification;
extern NSString* ORTriggerInitMultiBoardChangedNotification;
extern NSString* ORTriggerInitTrig2ChangedNotification;

//extern NSString* ORTriggerVmeClkLowerChangedNotification;
//extern NSString* ORTriggerVmeClkMiddleChangedNotification;
//extern NSString* ORTriggerVmeClkUpperChangedNotification;
extern NSString* ORTriggerUseSoftwareGtIdChangedNotification;
extern NSString* ORTriggerUseNoHardwareChangedNotification;
extern NSString* ORTriggerSoftwareGtIdChangedNotification;
extern NSString* ORTrigger1NameChangedNotification;
extern NSString* ORTrigger2NameChangedNotification;
extern NSString* ORTriggerMSAMChangedNotification;

extern NSString* ORTriggerSettingsLock;
extern NSString* ORTriggerSpecialLock;



