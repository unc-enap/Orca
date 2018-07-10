//
//  ORCaen419Model.h
//  Orca
//
//  Created by Mark Howe on 2/20/09
//  Copyright (c) 2009 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nug Physics and 
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

#import "ORVmeIOCard.h"
#import "ORDataTaker.h"
#import "ORHWWizard.h"
#import "SBC_Config.h"

@class ORRateGroup;

// Declaration of constants for module.
enum {
	kCh0DataRegister,
	kCh1DataRegister,
	kCh2DataRegister,
	kCh3DataRegister,
	kCh0ControlStatus,
	kCh1ControlStatus,
	kCh2ControlStatus,
	kCh3ControlStatus,
	kCh0LowThreshold,
	kCh0HighThreshold,
	kCh1LowThreshold,
	kCh1HighThreshold,
	kCh2LowThreshold,
	kCh2HighThreshold,
	kCh3LowThreshold,
	kCh3HighThreshold,
	kNumRegisters
};
typedef struct Caen419Registers {
	NSString*       regName;
	unsigned long 	addressOffset;
} Caen419Registers; 

#define kCV419NumberChannels 4

// Class definition
@interface ORCaen419Model : ORVmeIOCard <ORDataTaker,ORHWWizard,ORHWRamping>
{
    unsigned short  lowThresholds[kCV419NumberChannels];
    unsigned short  highThresholds[kCV419NumberChannels];
    unsigned short linearGateMode[kCV419NumberChannels];
    short riseTimeProtection[kCV419NumberChannels];
    unsigned long dataId;
    unsigned long auxAddress;
    short resetMask;
    short enabledMask;
	unsigned long slotMask;
	BOOL isRunning;
	ORRateGroup*	adcRateGroup;
	unsigned long 	adcCount[kCV419NumberChannels];
}

#pragma mark ***Accessors
- (void) setReset:(short)aChan withValue:(BOOL)aValue;
- (BOOL) reset:(short)aChan;
- (void) setEnabled:(short)aChan withValue:(BOOL)aValue;
- (BOOL) enabled:(short)aChan;

- (short) enabledMask;
- (void) setEnabledMask:(short)aMask;
- (short) resetMask;
- (void) setResetMask:(short)aResetMask;
- (short) riseTimeProtection:(short)chan;
- (void) setRiseTimeProtection:(short)chan withValue:(short)aRiseTimeProtection;
- (short) linearGateMode:(short)chan;
- (void) setLinearGateMode:(short)chan withValue:(short)aLinearGateMode;
- (unsigned long) auxAddress;
- (void) setAuxAddress:(unsigned long)aAuxAddress;
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherObj;
- (void) startRates;
- (BOOL) bumpRateFromDecodeStage:(short)chan;
- (ORRateGroup*)    adcRateGroup;
- (void)	    setAdcRateGroup:(ORRateGroup*)newAdcRateGroup;

- (unsigned long)	lowThreshold: (unsigned short) anIndex;
- (void) setLowThreshold:(unsigned short) aChnl withValue:(unsigned long) aValue;
- (unsigned long)	highThreshold: (unsigned short) anIndex;
- (void) setHighThreshold:(unsigned short) aChnl withValue:(unsigned long) aValue;
- (NSString*) 		getRegisterName: (short) anIndex;
- (unsigned long) 	getAddressOffset: (short) anIndex;

#pragma mark ***Support Hardware Functions
- (int) lowThresholdOffset:(unsigned short)aChan;
- (int) highThresholdOffset:(unsigned short)aChan;
- (unsigned short) readLowThreshold: (unsigned short) pChan; 
- (unsigned short) readHighThreshold: (unsigned short) pChan; 
- (void) writeLowThreshold: (unsigned short) pChan;
- (void) writeHighThreshold: (unsigned short) pChan;
- (void) writeThresholds;
- (void) readThresholds;
- (void) logThresholds;
- (void) writeControlStatusRegisters;
- (void) writeControlStatusRegister:(int)aChan;
- (void) initBoard;
- (void) fire;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;

#pragma mark •••Rates
- (void)		clearAdcCounts;
- (unsigned long) adcCount:(int)aChannel;
- (unsigned long) getCounter:(int)tag forGroup:(int)groupTag;
- (id) rateObject:(int)channel;
- (void) setIntegrationTime:(double)newIntegrationTime;

#pragma mark •••Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORCaen419ModelEnabledMaskChanged;
extern NSString* ORCaen419ModelResetMaskChanged;
extern NSString* ORCaen419ModelRiseTimeProtectionChanged;
extern NSString* ORCaen419ModelLinearGateModeChanged;
extern NSString* ORCaen419ModelAuxAddressChanged;
extern NSString* ORCaen419LowThresholdChanged;
extern NSString* ORCaen419HighThresholdChanged;
extern NSString* ORCaen419BasicLock;
extern NSString* ORCaen419RateGroupChangedNotification;

