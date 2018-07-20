/*
 *  ORCaen1785Model.h
 *  Orca
 *
 *  Created by Mark Howe on Friday June 19 2009.
 *  Copyright (c) 2009 UNC. All rights reserved.
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

#import "ORCaenCardModel.h"
#import "ORDataTaker.h"
#import "ORHWWizard.h"

@class ORRateGroup;
@class ORReadOutList;

// Declaration of constants for module.
enum {
    kOutputBuffer,		// 0000
    kFirmWareRevision,	// 1000
    kGeoAddress,		// 1002
    kMCST_CBLTAddress,	// 1004
    kBitSet1,			// 1006
    kBitClear1,			// 1008
    kInterrupLevel,		// 100A
    kInterrupVector,	// 100C
    kStatusRegister1,	// 100E
    kControlRegister1,	// 1010
    kADERHigh,			// 1012
    kADERLow,			// 1014
    kSingleShotReset,	// 1016
    kMCST_CBLTCtrl,		// 101A
    kEventTriggerReg,	// 1020
    kStatusRegister2,	// 1022
    kEventCounterL,		// 1024
    kEventCounterH,		// 1026
    kIncrementEvent,	// 1028
    kIncrementOffset,	// 102A
    kLoadTestRegister,	// 102C
    kFCLRWindow,		// 102E
    kBitSet2,			// 1032
    kBitClear2,			// 1034
    kWMemTestAddress,	// 1036
    kMemTestWord_High,	// 1038
    kMemTestWord_Low,	// 103A
    kCrateSelect,		// 103C
    kTestEventWrite,	// 103E
    kEventCounterReset,	// 1040
	kRTestAddress,		// 1064
    kSWComm,			// 1068
	kSlideConstant,		// 106A
    kADD,				// 1070
    kBADD,				// 1072
    kHiThresholds,		// 1080
    kLowThresholds,		// 1084
    kNumRegisters
};

#define kADCOutputBufferSize 0x07FF + 0x0004

// Size of output buffer
#define k1785OutputBufferSize 0x07FF
#define kCV1785NumberChannels 8

// Class definition
@interface ORCaen1785Model : ORVmeIOCard <ORDataTaker,ORHWWizard,ORHWRamping>
{
	ORRateGroup*	adcRateGroup;
	uint32_t 	adcCount[kCV1785NumberChannels];
	BOOL			isRunning;
    unsigned short  lowThresholds[kCV1785NumberChannels];
    unsigned short  highThresholds[kCV1785NumberChannels];
	unsigned short   onlineMask;
	unsigned short  selectedRegIndex;
    unsigned short  selectedChannel;
    uint32_t   writeValue;

	uint32_t dataId;
	ORReadOutList*  trigger1Group;
	NSArray*	dataTakers1;       //cache of data takers.

	//cached values for speed.
	uint32_t statusAddress;
	uint32_t dataBufferAddress;
	uint32_t location;
}

#pragma mark ***Accessors
- (id) init;

#pragma mark ***Accessors
- (uint32_t)	lowThreshold:(unsigned short) aChnl;
- (void)			setLowThreshold:(unsigned short) aChnl withValue:(uint32_t) aValue;
- (uint32_t)	highThreshold:(unsigned short) aChnl;
- (void)			setHighThreshold:(unsigned short) aChnl withValue:(uint32_t) aValue;
- (unsigned short)onlineMask;
- (void)			setOnlineMask:(unsigned short)anOnlineMask;
- (BOOL)			onlineMaskBit:(int)bit;
- (void)			setOnlineMaskBit:(int)bit withValue:(BOOL)aValue;
- (void)			setUpImage;
- (void)			makeMainController;
- (NSRange)			memoryFootprint;
- (unsigned short) 	selectedRegIndex;
- (void)			setSelectedRegIndex: (unsigned short) anIndex;
- (unsigned short) 	selectedChannel;
- (void)			setSelectedChannel: (unsigned short) anIndex;
- (uint32_t) 	writeValue;
- (void)			setWriteValue: (uint32_t) anIndex;

#pragma mark ***Register - General routines
- (void) writeThresholds;
- (void) readThresholds;
- (void) writeLowThreshold:(unsigned short) pChan;
- (void) writeHighThreshold:(unsigned short) pChan;
- (unsigned short) readLowThreshold:(unsigned short) pChan;
- (unsigned short) readHighThreshold:(unsigned short) pChan;
- (int) lowThresholdOffset:(unsigned short)aChan;
- (int) highThresholdOffset:(unsigned short)aChan;
- (short) getNumberRegisters;
- (uint32_t) getBufferOffset;
- (unsigned short) getDataBufferSize;
- (short) getStatusRegisterIndex:(short) aRegister;
- (short) getOutputBufferIndex;

#pragma mark ***Register - Register specific routines
- (NSString*) getRegisterName:(short) anIndex;
- (uint32_t) getAddressOffset:(short) anIndex;
- (short) getAccessType:(short) anIndex;
- (short) getAccessSize:(short) anIndex;
- (BOOL) dataReset:(short) anIndex;
- (BOOL) swReset:(short) anIndex;
- (BOOL) hwReset:(short) anIndex;
- (void) initBoard;
- (void) write;
- (void) read:(unsigned short) pReg returnValue:(void*) pValue;
- (void) clearData;
- (void) resetEventCounter;

#pragma mark ***DataTaker
- (int)  load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherObj;
- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (NSDictionary*) dataRecordDescription;
- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel;
- (void) reset;
- (void) runTaskStarted:(ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo;
- (BOOL) bumpRateFromDecodeStage:(short)channel;
- (uint32_t) adcCount:(int)aChannel;
- (void) startRates;
- (void) clearAdcCounts;
- (uint32_t) getCounter:(int)counterTag forGroup:(int)groupTag;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (NSString*) identifier;
- (ORReadOutList*) trigger1Group;
- (void) setTrigger1Group:(ORReadOutList*)newTrigger1Group;
- (void) saveReadOutList:(NSFileHandle*)aFile;
- (void) loadReadOutList:(NSFileHandle*)aFile;
- (void) readOutChildren:(NSArray*)children dataPacket:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;

#pragma mark ***HWWizard Support
- (BOOL)      hasParmetersToRamp;
- (NSArray*)  wizardSelections;
- (NSArray*)  wizardParameters;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;
- (void)	  logThresholds;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*) aDecoder;
- (void) encodeWithCoder:(NSCoder*) anEncoder;
@end

extern NSString* ORCaen1785BasicLock;
extern NSString* ORCaen1785ModelOnlineMaskChanged;
extern NSString* ORCaen1785LowThresholdChanged;
extern NSString* ORCaen1785HighThresholdChanged;
extern NSString* ORCaen1785SelectedRegIndexChanged;
extern NSString* ORCaen1785SelectedChannelChanged;
extern NSString* ORCaen1785WriteValueChanged;

