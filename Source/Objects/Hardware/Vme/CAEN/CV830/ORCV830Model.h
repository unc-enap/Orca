/*
 *  ORCV830Model.h
 *  Orca
 *
 *  Created by Mark Howe on 06/06/2012
 *  Copyright (c) 2012 University of North Carolina. All rights reserved.
 *
 */
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina,or U.S. Government make any warranty,
//express or implied,or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark •••Imported Files

#import "ORCaenCardModel.h"
#import "VME_eCPU_Config.h"
#import "SBC_Config.h"
#import "ORDataTaker.h"

#define 	kNumCV830Channels 	32

#pragma mark •••Register Definitions
enum {
	kEventBuffer,		 
	kCounter0,
	kCounter1,
	kCounter2,
	kCounter3,
	kCounter4,
	kCounter5,
	kCounter6,
	kCounter7,
	kCounter8,
	kCounter9,
	kCounter10,
	kCounter11,
	kCounter12,
	kCounter13,
	kCounter14,
	kCounter15,
	kCounter16,
	kCounter17,
	kCounter18,
	kCounter19,
	kCounter20,
	kCounter21,
	kCounter22,
	kCounter23,
	kCounter24,	
	kCounter25,
	kCounter26,
	kCounter27,
	kCounter28,
	kCounter29,
	kCounter30,
	kCounter31,
	kTestReg,
	kTestlcntl,
	kTestlcnth,
	kTesthcntl,
	kTesthcnth,
	kChannelEnable,
	kDwellTime,
	kControlReg,
	kBitSetReg,
	kBitClrReg,
	kStatusReg,
	kGEOReg,
	kInterruptLevel,
	kInterruptVector,
	kADER32,
	kADER23,
	kEnableADER,
	kMCSTBaseAdd,
	kMCSTControl,
	kModuleReset,
	kSoftwareClear,
	kSoftwareTrig,
	kTrigCounter,
	kAlmostFull,
	kBLTEventNum,
	kFirmware,
	kMEBEventNum,
	kDummy32,
	kDummy16,
	kConfigROM,
	kNumberOfV830Registers			//must be last
};

#pragma mark •••Forward Declarations
@class ORRateGroup;
@class ORReadOutList;

@interface ORCV830Model :  ORCaenCardModel <ORDataTaker>
{
    @private
		BOOL			pollRunning;
        uint32_t	enabledMask;
		uint32_t	scalerValue[kNumCV830Channels];
		NSTimeInterval	pollingState;
		BOOL			shipRecords;
		time_t			lastReadTime;
		BOOL			scheduledForUpdate;
		uint32_t	dwellTime;
		short			acqMode;
		BOOL			testMode;
		BOOL			clearMeb;
		BOOL			autoReset;
		uint32_t	polledDataId;
		uint32_t	dataRecord[38];
		ORReadOutList*	readOutGroup;
        BOOL            remoteInit;
        int32_t            count0Offset;
        BOOL            resetRollOverInSBC;
    
		//some cached variabled
		NSArray* dataTakers;	//cache of data takers.
		uint32_t numEnabledChannels;
        uint32_t    lastChan0Count;
        uint64_t    chan0RollOverCount;
}

#pragma mark •••Initialization
- (id) init; 
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark •••Accessors
- (int32_t) count0Offset;
- (void) setCount0Offset:(int32_t)aCount0Offset;
- (BOOL) autoReset;
- (void) setAutoReset:(BOOL)aAutoReset;
- (BOOL) clearMeb;
- (void) setClearMeb:(BOOL)aClearMeb;
- (BOOL) testMode;
- (void) setTestMode:(BOOL)aTestMode;
- (short) acqMode;
- (void) setAcqMode:(short)aAcqMode;
- (uint32_t) dwellTime;
- (void) setDwellTime:(uint32_t)aDwellTime;
- (BOOL) shipRecords;
- (void) setShipRecords:(BOOL)aShipRecords;
- (uint32_t) scalerValue:(int)index;
- (void) setScalerValue:(uint32_t)aValue index:(int)index;
- (uint32_t) enabledMask;
- (void) setEnabledMask:(uint32_t)aEnabledMask;
- (void) setPollingState:(NSTimeInterval)aState;
- (NSTimeInterval) pollingState;
- (void) registerNotificationObservers;
- (void) runAboutToStop:(NSNotification*)aNote;

#pragma mark •••Hardware Access
- (void) remoteInitBoard;
- (void) initBoard;
- (void) readStatus;
- (void) readScalers;
- (void) writeEnabledMask;
- (void) softwareTrigger;
- (void) softwareClear;
- (void) softwareReset;
- (void) writeControlReg;
- (void) writeDwellTime;
- (unsigned short) getNumEvents;
- (unsigned short) numEnabledChannels;
- (unsigned short) readControlReg;
- (void) remoteResetCounters;

#pragma mark •••Data Header
- (uint32_t) polledDataId;
- (void) setPolledDataId: (uint32_t) DataId;
- (NSDictionary*) dataRecordDescription;

#pragma mark ***DataTaker
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (int)  load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherObj;
- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (void) reset;
- (void) runTaskStarted:(ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo;

#pragma mark ***Children
- (ORReadOutList*)	readOutGroup;
- (void)			setReadOutGroup:(ORReadOutList*)newReadOutGroup;
- (NSMutableArray*) children;
- (void) saveReadOutList:(NSFileHandle*)aFile;
- (void) loadReadOutList:(NSFileHandle*)aFile;

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

#pragma mark •••External String Definitions
extern NSString* ORCV830ModelCount0OffsetChanged;
extern NSString* ORCV830ModelAutoResetChanged;
extern NSString* ORCV830ModelClearMebChanged;
extern NSString* ORCV830ModelTestModeChanged;
extern NSString* ORCV830ModelAcqModeChanged;
extern NSString* ORCV830ModelDwellTimeChanged;
extern NSString* ORCV830ModelEnabledMaskChanged;
extern NSString* ORCV830ModelScalerValueChanged;
extern NSString* ORCV830ModelPollingStateChanged;
extern NSString* ORCV830ModelShipRecordsChanged;
extern NSString* ORCV830ModelAllScalerValuesChanged;

@interface NSObject (ORCV830)
- (void) resetEventCounter;
@end
