//-------------------------------------------------------------------------
//  ORSIS3302.h
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2008 CENPA. University of Washington. All rights reserved.
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

#pragma mark ***Imported Files
#import "ORVmeIOCard.h"
#import "ORDataTaker.h"
#import "ORHWWizard.h"
#import "SBC_Config.h"
#import "AutoTesting.h"
#import "ORSISRegisterDefs.h"
#import "ORAdcInfoProviding.h"

@class ORRateGroup;
@class ORAlarm;
@class ORCommandList;

#define kMaxSIS3302SingleMaxRecord 0x3FFFF

#define ORCA_GEN_NOTIFY_FORM(PREPENDVAR, CMD) \
PREPENDVAR ## CMD ## Changed

#define ORCA_GEN_DECLARE_NOTIFY_FORM(PREPENDVAR, CMD) \
extern NSString* ORCA_GEN_NOTIFY_FORM(PREPENDVAR, CMD);


#define STRINGIFY2( x) #x
#define STRINGIFY(x) STRINGIFY2(x)
#define NSSTRINGIFY(b) @b

#define ORCA_NOTIFY_STRING(X)     \
NSString* X = NSSTRINGIFY( STRINGIFY(X));

#define ORCA_IMPLEMENT_NOTIFY(PREPENDVAR, CMD)     \
ORCA_NOTIFY_STRING( ORCA_GEN_NOTIFY_FORM(PREPENDVAR, CMD))


#define ORSIS3302_NOTIFY_FORM(CMD) \
ORCA_GEN_DECLARE_NOTIFY_FORM(ORSIS3302Generic, CMD)
#define ORSIS3302_IMPLEMENT_NOTIFY(CMD)     \
ORCA_IMPLEMENT_NOTIFY(ORSIS3302Generic, CMD)


typedef enum {
    kNone = 0,
    k2Clks,
    k4Clks,
    k8Clks,
    k16Clks,
    k32Clks,
    k64Clks,
    k128Clks
} EORSIS3302GenericAveraging;

typedef enum {
    k16M = 0,
    k4M,
    k1M,    
    k256K,
    k64K,
    k16K, 
    k4k,
    k1K,
    k512,
    k256,    
    k128,    
    k64        
} EORSIS3302PageSize;

typedef enum {
    k16Bit = 0,
    k32Bit
} EORSIS3302TestDataType;

@interface ORSIS3302GenericModel : ORVmeIOCard <ORDataTaker,ORHWWizard,ORHWRamping,AutoTesting,ORAdcInfoProviding>
{
  @private
	BOOL			isRunning;
	 	
	//clocks and delays (Acquistion control reg)
	int	 clockSource;
	
	unsigned long   lostDataId;
	unsigned long   dataId;

	short			gtMask;
	short           useTrapTriggerMask;
	NSMutableArray* thresholds;
    NSMutableArray* dacOffsets;
	NSMutableArray* pulseLengths;
	NSMutableArray* sumGs;
	NSMutableArray* peakingTimes;
    NSMutableArray* preTriggerDelays;

    NSMutableArray* sampleLengths;
    NSMutableArray* averagingSettings;
    short           stopAtEventLengthMask;
    short           enablePageWrapMask;    
    NSMutableArray* pageWrapSize;    
    short           enableTestDataMask;        
    NSMutableArray* testDataType;  
    
    // Trigger/Lemo configuration
    int startDelay;
    int stopDelay;    
    int maxEvents;
    BOOL lemoTimestampEnabled;
    BOOL lemoStartStopEnabled;    
    BOOL internalTrigStartEnabled;
    BOOL internalTrigStopEnabled;    
    BOOL multiEventModeEnabled;
    BOOL autostartModeEnabled;    
	
	ORRateGroup*	waveFormRateGroup;
	unsigned long 	waveFormCount[kNumSIS3302Channels];

	unsigned long location;
	id theController;
	long count;

	unsigned long  dataRecord[kMaxSIS3302SingleMaxRecord];
	
    float			firmwareVersion;
}

- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark ***Accessors

- (float) firmwareVersion;
- (void) setFirmwareVersion:(float)aFirmwareVersion;

- (unsigned long) getThresholdRegOffsets:(int) channel;
- (unsigned long) getTriggerSetupRegOffsets:(int) channel; 

- (unsigned long) getEventConfigOffsets:(int)group;
- (unsigned long) getEventLengthOffsets:(int)group;
- (unsigned long) getSampleStartOffsets:(int)group;
- (unsigned long) getAdcInputModeOffsets:(int)group;
- (unsigned long) getEventDirectoryForChannel:(int) channel; 
- (unsigned long) getNextSampleAddressForChannel:(int) channel;

- (void) setDefaults;

- (int) clockSource;
- (void) setClockSource:(int)aClockSource;

// Trigger
- (short) gtMask;
- (void) setGtMask:(long)aMask;
- (BOOL) gt:(short)chan;
- (void) setGtBit:(short)chan withValue:(BOOL)aValue;

- (short) useTrapTriggerMask;
- (void) setUseTrapTriggerMask:(short)aMask;
- (BOOL) useTrapTrigger:(short)chan;
- (void) setUseTrapTriggerMask:(short)chan withValue:(BOOL)aValue;

- (int) threshold:(short)chan;
- (void) setThreshold:(short)chan withValue:(int)aValue;
- (unsigned short) dacOffset:(short)chan;
- (void) setDacOffset:(short)aChan withValue:(int)aValue;
- (short) sumG:(short)chan;
- (void) setSumG:(short)aChan withValue:(short)aValue;
- (short) peakingTime:(short)aChan;
- (void) setPeakingTime:(short)aChan withValue:(short)aValue;
- (void) setPulseLength:(short)aChan withValue:(short)aValue;
- (short) pulseLength:(short)chan;
- (int)  preTriggerDelay:(short)group;
- (void) setPreTriggerDelay:(short)group withValue:(int)aPreTriggerDelay;

// Buffer
- (unsigned int) sampleLength:(short)group;
- (void) setSampleLength:(short)group withValue:(int)aValue;
- (EORSIS3302GenericAveraging) averagingType:(short)group;
- (void) setAveragingType:(short)group withValue:(EORSIS3302GenericAveraging)aValue;
- (BOOL) stopEventAtLength:(short)group;
- (void) setStopEventAtLength:(short)group withValue:(BOOL)aValue;
- (BOOL) pageWrap:(short)group;
- (void) setPageWrap:(short)group withValue:(BOOL)aValue;
- (EORSIS3302PageSize) pageWrapSize:(short)group;
- (void) setPageWrapSize:(short)group withValue:(EORSIS3302PageSize)aValue;
- (BOOL) enableTestData:(short)group;
- (void) setEnableTestData:(short)group withValue:(BOOL)aValue;
- (EORSIS3302TestDataType) testDataType:(short)group;
- (void) setTestDataType:(short)group withValue:(EORSIS3302TestDataType)aValue;

// Trigger/Lemo configuration
@property (nonatomic) int startDelay;
@property (nonatomic) int stopDelay;    
@property (nonatomic) int maxEvents;
@property (nonatomic) BOOL lemoTimestampEnabled;
@property (nonatomic) BOOL lemoStartStopEnabled;    
@property (nonatomic) BOOL internalTrigStartEnabled;
@property (nonatomic) BOOL internalTrigStopEnabled;    
@property (nonatomic) BOOL multiEventModeEnabled;
@property (nonatomic) BOOL autostartModeEnabled;    
	
- (void) initParams;

- (ORRateGroup*)    waveFormRateGroup;
- (void)			setWaveFormRateGroup:(ORRateGroup*)newRateGroup;
- (id)              rateObject:(int)channel;
- (void)            setRateIntegrationTime:(double)newIntegrationTime;
- (BOOL)			bumpRateFromDecodeStage:(short)channel;

#pragma mark •••Hardware Access
- (int) limitIntValue:(int)aValue min:(int)aMin max:(int)aMax;
- (void) initBoard;
- (void) readModuleID:(BOOL)verbose;

- (void) readThresholds:(BOOL)verbose;
- (void) setLed:(BOOL)state;
- (void) briefReport;
- (void) regDump;
- (void) resetSamplingLogic;

- (void) clearTimeStamp;
- (void) forceTrigger;

- (unsigned long) acqReg;

#pragma mark •••Data Taker
- (unsigned long) lostDataId;
- (void) setLostDataId: (unsigned long) anId;
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*) dataRecordDescription;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (unsigned long) waveFormCount:(int)aChannel;
- (void)   startRates;
- (void) clearWaveFormCounts;
- (unsigned long) getCounter:(int)counterTag forGroup:(int)groupTag;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;

#pragma mark •••HW Wizard
- (int) numberOfChannels;
- (NSArray*) wizardParameters;
- (NSArray*) wizardSelections;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

#pragma mark •••AutoTesting
- (NSArray*) autoTests; 
@end

//CSRg

ORSIS3302_NOTIFY_FORM(FirmwareVersion);

ORSIS3302_NOTIFY_FORM(PreTriggerDelay);

ORSIS3302_NOTIFY_FORM(SampleLength);

ORSIS3302_NOTIFY_FORM(ClockSource);
ORSIS3302_NOTIFY_FORM(TriggerOutEnabled);
ORSIS3302_NOTIFY_FORM(Threshold);
ORSIS3302_NOTIFY_FORM(Gt);
ORSIS3302_NOTIFY_FORM(DacOffset);
ORSIS3302_NOTIFY_FORM(TrapFilterTrigger);

ORSIS3302_NOTIFY_FORM(SettingsLock);
ORSIS3302_NOTIFY_FORM(RateGroup);
ORSIS3302_NOTIFY_FORM(SampleDone);
ORSIS3302_NOTIFY_FORM(ID);

ORSIS3302_NOTIFY_FORM(PulseLength);
ORSIS3302_NOTIFY_FORM(SumG);
ORSIS3302_NOTIFY_FORM(PeakingTime);
ORSIS3302_NOTIFY_FORM(InternalTriggerDelay);

ORSIS3302_NOTIFY_FORM(Averaging);
ORSIS3302_NOTIFY_FORM(StopAtEvent);
ORSIS3302_NOTIFY_FORM(EnablePageWrap);
ORSIS3302_NOTIFY_FORM(PageWrapSize);
ORSIS3302_NOTIFY_FORM(TestDataEnable);
ORSIS3302_NOTIFY_FORM(TestDataType);

ORSIS3302_NOTIFY_FORM(StartDelay);
ORSIS3302_NOTIFY_FORM(StopDelay);
ORSIS3302_NOTIFY_FORM(MaxEvents);
ORSIS3302_NOTIFY_FORM(LemoTimestamp);
ORSIS3302_NOTIFY_FORM(LemoStartStop);
ORSIS3302_NOTIFY_FORM(InternalTrigStart);
ORSIS3302_NOTIFY_FORM(InternalTrigStop);
ORSIS3302_NOTIFY_FORM(MultiEventMode);
ORSIS3302_NOTIFY_FORM(AutostartMode);

ORSIS3302_NOTIFY_FORM(CardInited);

