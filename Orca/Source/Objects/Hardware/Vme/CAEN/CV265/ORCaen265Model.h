/*
 *  ORCaen265Model.h
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
#import "ORDataTaker.h"
#import "VME_eCPU_Config.h"
#import "SBC_Config.h"

#define 	kNumCaen265Channels 		8

#pragma mark •••Register Definitions
enum {
	kStatusControl,
	kClear,
	kDAC,
	kGateGeneration,
	kDataRegister,
	kFixedCode,
	kBoardID,
	kVersion,
	kNumberOfV265Registers			//must be last
};

#pragma mark •••Forward Declarations
@class ORRateGroup;

@interface ORCaen265Model :  ORCaenCardModel <ORDataTaker>
{
    @private
		BOOL isRunning;
        unsigned short enabledMask;
		BOOL suppressZeros;
		
		//cached values for use while running only
		BOOL usingShortForm;
		unsigned long statusAddress;
		unsigned long fifoAddress;
		unsigned long location;
 
}

#pragma mark •••Initialization
- (id) init; 
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark •••Accessors
- (BOOL) suppressZeros;
- (void) setSuppressZeros:(BOOL)aSuppressZeros;
- (unsigned short) enabledMask;
- (void) setEnabledMask:(unsigned short)aEnabledMask;
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherCaen265;



#pragma mark •••Hardware Access
- (void)			initBoard;
- (unsigned short) 	readBoardID;
- (unsigned short) 	readBoardVersion;
- (unsigned short) 	readFixedCode;
- (void)			trigger;

#pragma mark •••Data Header
- (NSDictionary*) dataRecordDescription;
- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel;

#pragma mark •••Data Taking
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) reset;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;
- (BOOL) partOfEvent:(unsigned short)aChannel;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
@end

#pragma mark •••External String Definitions
extern NSString* ORCaen265ModelSuppressZerosChanged;
extern NSString* ORCaen265ModelEnabledMaskChanged;
extern NSString* ORCaen265SettingsLock;
