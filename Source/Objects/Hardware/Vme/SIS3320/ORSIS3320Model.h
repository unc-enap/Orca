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
@class ORCommandList;

#define kNumSIS3320Channels			8
#define kNumSIS3320Groups           (kNumSIS3320Channels/2)

@interface ORSIS3320Model : ORVmeIOCard <ORDataTaker,ORHWWizard,ORHWRamping,AutoTesting>
{
  @private
	unsigned long   dataId;
	BOOL			isRunning;
	BOOL			ledOn;
	unsigned short	moduleID;
	unsigned short	majorRev;
	unsigned short	minorRev;
    BOOL            internalTriggerEnabled;
    BOOL            lemoTriggerEnabled;
    BOOL            lemoTimeStampClrEnabled;
	int				clockSource;
    BOOL            bank1Armed;
    
	unsigned char   triggerMode[2];
    BOOL            saveFirstEvent[2];
    BOOL            saveFIRTrigger[2];
    BOOL            saveIfPileUp[2];
    BOOL            saveAlways[2];
    BOOL            enableErrorCorrection[2];
    BOOL            invertInput[2];
    
    unsigned long   bufferLength[4];
    unsigned long   bufferStart[4];
    unsigned long   accGate1StartIndex[4];
    unsigned long   accGate1Length[4];
    unsigned long   accGate2StartIndex[4];
    unsigned long   accGate2Length[4];
    unsigned long   accGate3StartIndex[4];
    unsigned long   accGate3Length[4];
    unsigned long   accGate4StartIndex[4];
    unsigned long   accGate4Length[4];
    unsigned long   accGate5StartIndex[4];
    unsigned long   accGate5Length[4];
    unsigned long   accGate6StartIndex[4];
    unsigned long   accGate6Length[4];
    unsigned long   accGate7StartIndex[4];
    unsigned long   accGate7Length[4];
    unsigned long   accGate8StartIndex[4];
    unsigned long   accGate8Length[4];
  
 	unsigned char   gtMask;
 	unsigned char   triggerOutMask;
 	unsigned char   extendedTriggerMask;
	
	NSMutableArray* dacValues;
	NSMutableArray* preTriggerDelays;
	NSMutableArray* triggerGateLengths;
	NSMutableArray* trigPulseLens;
	NSMutableArray* sumGs;
	NSMutableArray* peakingTimes;
    NSMutableArray* endAddressThresholds;
	NSMutableArray* thresholds;

	ORRateGroup*	waveFormRateGroup;
	unsigned long 	waveFormCount[kNumSIS3320Channels];
    unsigned long	onlineMask;
    ORAlarm*        dataRateAlarm;
	//cached when taking data from Mac
	unsigned long	location;
	id				theController;
 }

#pragma mark ***Initialization
- (id) init; 
- (void) dealloc; 
- (void) setUpImage;
- (void) makeMainController;
- (NSString*) helpURL;
- (NSRange)	memoryFootprint;
- (void) initParams;

#pragma mark ***Accessors
- (unsigned char)   onlineMask;
- (void)	    setOnlineMask:(unsigned char)anOnlineMask;
- (BOOL)	    onlineMaskBit:(int)bit;
- (void)	    setOnlineMaskBit:(int)bit withValue:(BOOL)aValue;
- (unsigned long) accGate1Length:(int)anIndex;
- (void) setAccGate1Length:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long) accGate2Length:(int)anIndex;
- (void) setAccGate2Length:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long) accGate3Length:(int)anIndex;
- (void) setAccGate3Length:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long) accGate4Length:(int)anIndex;
- (void) setAccGate4Length:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long) accGate5Length:(int)anIndex;
- (void) setAccGate5Length:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long) accGate6Length:(int)anIndex;
- (void) setAccGate6Length:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long) accGate7Length:(int)anIndex;
- (void) setAccGate7Length:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long) accGate8Length:(int)anIndex;
- (void) setAccGate8Length:(int)anIndex withValue:(unsigned long)aValue;

- (unsigned long) accGate1StartIndex:(int)anIndex;
- (void) setAccGate1StartIndex:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long) accGate2StartIndex:(int)anIndex;
- (void) setAccGate2StartIndex:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long) accGate3StartIndex:(int)anIndex;
- (void) setAccGate3StartIndex:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long) accGate4StartIndex:(int)anIndex;
- (void) setAccGate4StartIndex:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long) accGate5StartIndex:(int)anIndex;
- (void) setAccGate5StartIndex:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long) accGate6StartIndex:(int)anIndex;
- (void) setAccGate6StartIndex:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long) accGate7StartIndex:(int)anIndex;
- (void) setAccGate7StartIndex:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long) accGate8StartIndex:(int)anIndex;
- (void) setAccGate8StartIndex:(int)anIndex withValue:(unsigned long)aValue;


- (unsigned long) bufferStart:(int)aGroup;
- (void) setBufferStart:(int)aGroup withValue:(unsigned long)aValue;
- (unsigned long) bufferLength:(int)aGroup;
- (void) setBufferLength:(int)aGroup withValue:(unsigned long)aValue;
- (unsigned short) moduleID;
- (NSString*) firmwareVersion;
- (BOOL) lemoTimeStampClrEnabled;
- (void) setLemoTimeStampClrEnabled:(BOOL)aLemoTimeStampClrEnabled;
- (BOOL) lemoTriggerEnabled;
- (void) setLemoTriggerEnabled:(BOOL)aLemoTriggerEnabled;
- (BOOL) internalTriggerEnabled;
- (void) setInternalTriggerEnabled:(BOOL)aInternalTriggerEnabled;
- (int) clockSource;
- (void) setClockSource:(int)aClockSource;
- (NSString*) clockSourceName:(int)aValue;
- (long) dacValue:(int)aChan;
- (void) setDacValue:(int)aChan withValue:(long)aValue ;
- (unsigned char) triggerMode:(int)aGroup;
- (void) setTriggerMode:(int)aGroup withValue:(unsigned char)aValue;
- (BOOL) saveAlways:(int)aGroup;
- (void) setSaveAlways:(int)aGroup withValue:(BOOL)aSaveAlways;
- (BOOL) saveIfPileUp:(int)aGroup;
- (void) setSaveIfPileUp:(int)aGroup withValue:(BOOL)aSaveIfPileUp;
- (BOOL) saveFIRTrigger:(int)aGroup;
- (void) setSaveFIRTrigger:(int)aGroup withValue:(BOOL)aSaveFIRTrigger;
- (BOOL) saveFirstEvent:(int)aGroup;
- (void) setSaveFirstEvent:(int)aGroup withValue:(BOOL)aSaveFirstEvent;
- (BOOL) invertInput:(int)aGroup;
- (void) setInvertInput:(int)aGroup withValue:(BOOL)aInvertInput;
- (BOOL) enableErrorCorrection:(int)aGroup;
- (void) setEnableErrorCorrection:(int)aGroup withValue:(BOOL)aEnableErrorCorrection;
- (int)  triggerGateLength:(short)group;
- (void) setTriggerGateLength:(short)group withValue:(int)aTriggerGateLength;
- (int) preTriggerDelay:(short)aGroup;
- (void) setPreTriggerDelay:(short)aGroup withValue:(int)aPreTriggerDelay;
- (int) trigPulseLen:(short)aChan;
- (void) setTrigPulseLen:(short)aChan withValue:(int)aValue ;
- (int) sumG:(short)aChan;
- (void) setSumG:(short)aChan withValue:(int)aValue;
- (int) peakingTime:(short)aChan;
- (void) setPeakingTime:(short)aChan withValue:(int)aValue;
- (int) threshold:(short)aChan;
- (void) setThreshold:(short)aChan withValue:(int)aValue ;
- (unsigned long) endAddressThreshold:(short)aGroup;
- (void) setEndAddressThreshold:(short)aGroup withValue:(unsigned long)aValue;

- (void) setDefaults;
- (unsigned char) gtMask;
- (void) setGtMask:(unsigned char)aMask;
- (BOOL) gtMaskBit:(int)bit;
- (void) setGtMaskBit:(int)bit withValue:(BOOL)aValue;
- (unsigned char) triggerOutMask;
- (void) setTriggerOutMask:(unsigned char)aMask;
- (BOOL) triggerOutMaskBit:(int)bit;
- (void) setTriggerOutMaskBit:(int)bit withValue:(BOOL)aValue;
- (unsigned char) extendedTriggerMask;
- (void) setExtendedTriggerMask:(unsigned char)aMask;
- (BOOL) extendedTriggerMaskBit:(int)bit;
- (void) setExtendedTriggerMaskBit:(int)bit withValue:(BOOL)aValue;

- (ORRateGroup*) waveFormRateGroup;
- (void) setWaveFormRateGroup:(ORRateGroup*)newRateGroup;
- (id) rateObject:(int)channel;
- (void) setRateIntegrationTime:(double)newIntegrationTime;
- (int) limitIntValue:(int)aValue min:(int)aMin max:(int)aMax;
- (void) executeCommandList:(ORCommandList*) aList;

#pragma mark •••Rates
- (unsigned long) getCounter:(int)counterTag forGroup:(int)groupTag;

#pragma mark •••Hardware Access
- (void) reset;
- (void) disarmSamplingLogic;
- (void) trigger;
- (void) clearTimeStamp;
- (void) armBank1;
- (void) armBank2;


- (void) initBoard;
- (void) writePageRegister:(int)aPage;
- (void) writeControlStatusRegister;
- (void) readModuleID:(BOOL)verbose;
- (void) writeAcquisitionRegister;
- (unsigned long) readAcqRegister;
- (void) writeAdcMemoryPage:(unsigned long)aPage;
- (unsigned long) readAdcMemoryPage;
- (void) writeDacOffsets;
- (void) writeEventConfiguration;
- (unsigned long) readEventConfigRegister;
- (void) writePreTriggerDelayAndTriggerGateDelay;
- (void) writeRawDataBufferConfiguration;
- (unsigned long) readPreviousAdcAddress:(int)aChannel;
- (unsigned long) readNextAdcAddress:(int)aChannel;

- (unsigned long) nextSampleAddress:(int)aChannel;
- (unsigned long) actualSampleValue:(int)aGroup;
- (void) writeTriggerSetupRegisters;
- (void) writeTriggerSetupRegister:(int)aChannel;
- (void) writeThresholds;
- (void) writeThreshold:(int)aChannel;
- (void) writeEndAddressThresholds;
- (void) writeEndAddressThreshold:(int)aGroup;
- (void) writeValue:(unsigned long)aValue offset:(long)anOffset;
- (void) writeAccumulators;
- (void) printReport;
- (void) regDump;
- (unsigned long) readActualAdcSample:(int)aGroup;

#pragma mark •••Data Taker
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherCard;
- (NSDictionary*) dataRecordDescription;

#pragma mark •••HW Wizard
- (BOOL) hasParmetersToRamp;
- (int) numberOfChannels;
- (NSArray*) wizardParameters;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;
- (NSArray*) wizardSelections;

#pragma mark •••Data Taker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;
- (BOOL) bumpRateFromDecodeStage:(short)channel;

// bump the decoded event count by a number specified by nDecodedEvents
- (BOOL) bumpRateFromDecodeStage:(short)channel nDecodedEvents:(int)bumpNumber;


- (unsigned long) waveFormCount:(int)aChannel;
-(void) startRates;
- (void) clearWaveFormCounts;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

#pragma mark •••AutoTesting
- (NSArray*) autoTests ;
@end

extern NSString* ORSIS3320ModelOnlineChanged;
extern NSString* ORSIS3320ModelAccGate1LengthChanged;
extern NSString* ORSIS3320ModelAccGate1StartIndexChanged;
extern NSString* ORSIS3320ModelAccGate2LengthChanged;
extern NSString* ORSIS3320ModelAccGate2StartIndexChanged;
extern NSString* ORSIS3320ModelAccGate3LengthChanged;
extern NSString* ORSIS3320ModelAccGate3StartIndexChanged;
extern NSString* ORSIS3320ModelAccGate4LengthChanged;
extern NSString* ORSIS3320ModelAccGate4StartIndexChanged;
extern NSString* ORSIS3320ModelAccGate5LengthChanged;
extern NSString* ORSIS3320ModelAccGate5StartIndexChanged;
extern NSString* ORSIS3320ModelAccGate6LengthChanged;
extern NSString* ORSIS3320ModelAccGate6StartIndexChanged;
extern NSString* ORSIS3320ModelAccGate7LengthChanged;
extern NSString* ORSIS3320ModelAccGate7StartIndexChanged;
extern NSString* ORSIS3320ModelAccGate8LengthChanged;
extern NSString* ORSIS3320ModelAccGate8StartIndexChanged;
extern NSString* ORSIS3320ModelBufferStartChanged;
extern NSString* ORSIS3320ModelBufferLengthChanged;
extern NSString* ORSIS3320ModelInvertInputChanged;
extern NSString* ORSIS3320ModelEnableErrorCorrectionChanged;
extern NSString* ORSIS3320ModelIDChanged;
extern NSString* ORSIS3320ModelLemoTimeStampClrEnabledChanged;
extern NSString* ORSIS3320ModelLemoTriggerEnabledChanged;
extern NSString* ORSIS3320ModelInternalTriggerEnabledChanged;
extern NSString* ORSIS3320ModelClockSourceChanged;
extern NSString* ORSIS3320ModelDacValueChanged;
extern NSString* ORSIS3320ModelTriggerModeChanged;
extern NSString* ORSIS3320ModelSaveAlwaysChanged;
extern NSString* ORSIS3320ModelSaveIfPileUpChanged;
extern NSString* ORSIS3320ModelSaveFIRTriggerChanged;
extern NSString* ORSIS3320ModelSaveFirstEventChanged;
extern NSString* ORSIS3320ModelTriggerGateLengthChanged;
extern NSString* ORSIS3320ModelPreTriggerDelayChanged;
extern NSString* ORSIS3320ModelTrigPulseLenChanged;
extern NSString* ORSIS3320ModelSumGChanged;
extern NSString* ORSIS3320ModelPeakingTimeChanged;
extern NSString* ORSIS3320ModelThresholdChanged;


extern NSString* ORSIS3320ModelEnableSampleLenStopChanged;
extern NSString* ORSIS3320ModelStopDelayChanged;
extern NSString* ORSIS3320ModelStartDelayChanged;
extern NSString* ORSIS3320ModelLemoStartStopLogicChanged;
extern NSString* ORSIS3320ModelInternalTriggerAsStopChanged;
extern NSString* ORSIS3320ModelGtMaskChanged;
extern NSString* ORSIS3320ModelTriggerOutMaskChanged;
extern NSString* ORSIS3320ModelExtendedTriggerMaskChanged;

extern NSString* ORSIS3320SettingsLock;
extern NSString* ORSIS3320RateGroupChangedNotification;
extern NSString* ORSIS3320ModelEndAddressThresholdChanged;
