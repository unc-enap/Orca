//-------------------------------------------------------------------------
//  ORSIS3320Model.h
//
//  Created by Mark A. Howe on Thursday 8/6/09
//  Copyright (c) 2009 Universiy of North Carolina. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORVmeIOCard.h"
#import "ORDataTaker.h"
#import "ORHWWizard.h"
#import "SBC_Config.h"
#import "AutoTesting.h"

@class ORRateGroup;
@class ORAlarm;

#define kNumSIS3320Channels			8

@interface ORSIS3320Model : ORVmeIOCard <ORDataTaker,ORHWWizard,ORHWRamping,AutoTesting>
{
  @private
	BOOL			isRunning;
	BOOL			ledOn;
	unsigned short	moduleID;
	uint32_t   dataId;
	
	NSMutableArray* dacValues;
	NSMutableArray* thresholds;
	NSMutableArray* trigPulseLens;
	NSMutableArray* sumGs;
	NSMutableArray* peakingTimes;
	
 	unsigned char   triggerModeMask;
 	unsigned char   gtMask;
 	unsigned char   ltMask;
    int				clockSource;
    BOOL			multiEvent;
     int32_t			maxNumEvents;

	uint32_t	location;
	id				theController;

	ORRateGroup*	waveFormRateGroup;
	uint32_t 	waveFormCount[kNumSIS3320Channels];

    BOOL autoStartMode;
    BOOL internalTriggerAsStop;
    BOOL lemoStartStopLogic;
    uint32_t startDelay;
    uint32_t stopDelay;
    int pageWrapSize;
    BOOL enablePageWrap;
    BOOL enableSampleLenStop;
    BOOL enableUserInDataStream;
    BOOL enableUserInAccumGate;
    int sampleLength;
    int sampleStartAddress;
	
	uint32_t* data;
}

- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (void) setDefaults;

#pragma mark ***Accessors
- (int) sampleStartAddress;
- (void) setSampleStartAddress:(int)aSampleStartAddress;
- (int) sampleLength;
- (void) setSampleLength:(int)aSampleLength;
- (BOOL) enableUserInAccumGate;
- (void) setEnableUserInAccumGate:(BOOL)aEnableUserInAccumGate;
- (BOOL) enableUserInDataStream;
- (void) setEnableUserInDataStream:(BOOL)aEnableUserInDataStream;
- (BOOL) enableSampleLenStop;
- (void) setEnableSampleLenStop:(BOOL)aEnableSampleLenStop;
- (BOOL) enablePageWrap;
- (void) setEnablePageWrap:(BOOL)aEnablePageWrap;
- (int) pageWrapSize;
- (void) setPageWrapSize:(int)aPageWrapSize;
- (int) pageSize;

- (uint32_t) stopDelay;
- (void) setStopDelay:(uint32_t)aStopDelay;
- (uint32_t) startDelay;
- (void) setStartDelay:(uint32_t)aStartDelay;
- (BOOL) lemoStartStopLogic;
- (void) setLemoStartStopLogic:(BOOL)aLemoStartStopLogic;
- (BOOL) internalTriggerAsStop;
- (void) setInternalTriggerAsStop:(BOOL)aInternalTriggerAsStop;
- (BOOL) autoStartMode;
- (void) setAutoStartMode:(BOOL)aAutoStartMode;

- (unsigned char)   triggerModeMask;
- (void)			setTriggerModeMask:(unsigned char)aMask;
- (BOOL)			triggerModeMaskBit:(int)bit;
- (void)			setTriggerModeMaskBit:(int)bit withValue:(BOOL)aValue;

- (unsigned char)   gtMask;
- (void)			setGtMask:(unsigned char)aMask;
- (BOOL)			gtMaskBit:(int)bit;
- (void)			setGtMaskBit:(int)bit withValue:(BOOL)aValue;

- (unsigned char)   ltMask;
- (void)			setLtMask:(unsigned char)aMask;
- (BOOL)			ltMaskBit:(int)bit;
- (void)			setLtMaskBit:(int)bit withValue:(BOOL)aValue;

- (int32_t) maxNumEvents;
- (void) setMaxNumEvents:(int32_t)aMaxNumEvents;
- (BOOL) multiEvent;
- (void) setMultiEvent:(BOOL)aMultiEvent;
- (int) clockSource;
- (void) setClockSource:(int)aClockSource;
- (NSString*) clockSourceName:(int)aValue;
- (unsigned short) moduleID;


- (int32_t) dacValue:(int)aChannel;
- (void) setDacValue:(int)aChannel withValue:(int32_t)aValue;

- (void) setThreshold:(short)chan withValue:(int)aValue;
- (int) threshold:(short)chan;
- (int) trigPulseLen:(short)aChan;
- (void) setTrigPulseLen:(short)aChan withValue:(int)aValue;
- (int) sumG:(short)aChan;
- (void) setSumG:(short)aChan withValue:(int)aValue;
- (int) peakingTime:(short)aChan;
- (void) setPeakingTime:(short)aChan withValue:(int)aValue;

- (ORRateGroup*)    waveFormRateGroup;
- (void)			setWaveFormRateGroup:(ORRateGroup*)newRateGroup;
- (id)              rateObject:(int)channel;
- (void)            setRateIntegrationTime:(double)newIntegrationTime;
- (BOOL)			bumpRateFromDecodeStage:(short)channel;

#pragma mark •••Hardware Access
- (void) printReport;
- (void) initBoard;
- (uint32_t) readEventCounter;
- (void) readModuleID:(BOOL)verbose;
- (void) writeStartDelay:(uint32_t)aValue;
- (void) writeStopDelay:(uint32_t)aValue;
- (void) startSampling;
- (void) stopSampling;
- (void) writeEventConfigRegister;
- (uint32_t) readEventDir:(int)aChannel;

- (void) writeAcquisitionRegister;
- (uint32_t) readAcquisitionRegister;
- (void) writeControlStatusRegister;
- (void) writeValue:(uint32_t)aValue offset:(int32_t)anOffset;
- (void) writeTriggerSetupRegisters;
- (void) armSamplingLogic;
- (void) disarmSamplingLogic;
- (uint32_t) readAcqRegister;
- (void) writeAdcMemoryPage:(uint32_t)aPage;
- (void) writeSampleStartAddress:(uint32_t)aValue;
- (void) writeDacOffsets;
- (void) writeAdcTestMode;
- (void) writeGainControlRegister;
- (void) writeTriggerClearCounter;

#pragma mark •••Data Taker
- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*) dataRecordDescription;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (uint32_t) waveFormCount:(int)aChannel;
- (void)   startRates;
- (void) clearWaveFormCounts;
- (uint32_t) getCounter:(int)counterTag forGroup:(int)groupTag;
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
@end

extern NSString* ORSIS3320ModelSampleStartAddressChanged;
extern NSString* ORSIS3320ModelSampleLengthChanged;
extern NSString* ORSIS3320ModelEnableUserInAccumGateChanged;
extern NSString* ORSIS3320ModelEnableUserInDataStreamChanged;
extern NSString* ORSIS3320ModelEnableSampleLenStopChanged;
extern NSString* ORSIS3320ModelEnablePageWrapChanged;
extern NSString* ORSIS3320ModelPageWrapSizeChanged;
extern NSString* ORSIS3320ModelStopDelayChanged;
extern NSString* ORSIS3320ModelStartDelayChanged;
extern NSString* ORSIS3320ModelLemoStartStopLogicChanged;
extern NSString* ORSIS3320ModelInternalTriggerAsStopChanged;
extern NSString* ORSIS3320ModelAutoStartModeChanged;
extern NSString* ORSIS3320ModelGtMaskChanged;
extern NSString* ORSIS3320ModelLtMaskChanged;
extern NSString* ORSIS3320ModelTriggerModeMaskChanged;

extern NSString* ORSIS3320ModelMaxNumEventsChanged;
extern NSString* ORSIS3320ModelMultiEventChanged;
extern NSString* ORSIS3320ModelClockSourceChanged;
extern NSString* ORSIS3320ModelTriggerModeChanged;
extern NSString* ORSIS3320ModelThresholdChanged;
extern NSString* ORSIS3320ModelTrigPulseLenChanged;
extern NSString* ORSIS3320ModelSumGChanged;
extern NSString* ORSIS3320ModelPeakingTimeChanged;
extern NSString* ORSIS3320SettingsLock;
extern NSString* ORSIS3320RateGroupChangedNotification;
extern NSString* ORSIS3320ModelIDChanged;
extern NSString* ORSIS3320ModelDacValueChanged;
