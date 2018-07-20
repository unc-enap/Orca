/*
 *  ORCaen260Model.h
 *  Orca
 *
 *  Created by Mark Howe on 12/7/07.
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

#pragma mark •••Imported Files

#import "ORCaenCardModel.h"
#import "VME_eCPU_Config.h"
#import "SBC_Config.h"
#import "ORDataTaker.h"

#define 	kNumCaen260Channels 		16

#pragma mark •••Register Definitions
enum {
	kVersion,
	kModualType,
	kFixedCode,
	kInterruptJumpers,
	kScalerIncrease,
	kInhibitReset,
	kInhibitSet,
	kClear,
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
	kClearVMEInterrupt,
	kDisableVMEInterrupt,
	kEnableVMEInterrupt,
	kInterruptLevel,
	kInterruptVector,
	kNumberOfV260Registers			//must be last
};

#pragma mark •••Forward Declarations
@class ORRateGroup;

@interface ORCaen260Model :  ORCaenCardModel <ORDataTaker>
{
    @private
		BOOL			pollRunning;
        unsigned short	enabledMask;
		uint32_t	scalerValue[kNumCaen260Channels];
		NSTimeInterval	pollingState;
		BOOL			shipRecords;
		time_t			lastReadTime;
		BOOL			autoInhibit;
		BOOL			isRunning;
		BOOL			scheduledForUpdate;
		BOOL			shipOnChange;
		int				channelForTriggeredShip;
		uint32_t	lastScalerValue;
}

#pragma mark •••Initialization
- (id) init; 
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark •••Accessors
- (int) channelForTriggeredShip;
- (void) setChannelForTriggeredShip:(int)aChannelForTriggeredShip;
- (BOOL) shipOnChange;
- (void) setShipOnChange:(BOOL)aShipOnChange;
- (BOOL) autoInhibit;
- (void) setAutoInhibit:(BOOL)aAutoInhibit;
- (BOOL) shipRecords;
- (void) setShipRecords:(BOOL)aShipRecords;
- (uint32_t) scalerValue:(int)index;
- (void) setScalerValue:(uint32_t)aValue index:(int)index;
- (unsigned short) enabledMask;
- (void) setEnabledMask:(unsigned short)aEnabledMask;
- (void) setPollingState:(NSTimeInterval)aState;
- (NSTimeInterval) pollingState;
- (void) registerNotificationObservers;
- (void) runAboutToStart:(NSNotification*)aNote;
- (void) runAboutToStop:(NSNotification*)aNote;

#pragma mark •••Hardware Access
- (unsigned short) 	readBoardVersion;
- (unsigned short) 	readFixedCode;
- (void)			setInhibit;
- (void)			resetInhibit;
- (void)			clearScalers;
- (void)			incScalers;
- (void)			readScalers;

#pragma mark •••Data Header
- (NSDictionary*) dataRecordDescription;

#pragma mark ***DataTaker
- (int)  load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherObj;
- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel;
- (void) reset;
- (void) runTaskStarted:(ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo;

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

#pragma mark •••External String Definitions
extern NSString* ORCaen260ModelChannelForTriggeredShipChanged;
extern NSString* ORCaen260ModelShipOnChangeChanged;
extern NSString* ORCaen260ModelAutoInhibitChanged;
extern NSString* ORCaen260ModelEnabledMaskChanged;
extern NSString* ORCaen260ModelScalerValueChanged;
extern NSString* ORCaen260ModelPollingStateChanged;
extern NSString* ORCaen260ModelShipRecordsChanged;
extern NSString* ORCaen260ModelAllScalerValuesChanged;

