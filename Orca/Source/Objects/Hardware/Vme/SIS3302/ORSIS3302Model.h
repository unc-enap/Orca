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

#define kNumMcaStatusRequests 35 //don't change this unless you know what you are doing....

@class ORRateGroup;
@class ORAlarm;
@class ORCommandList;

@interface ORSIS3302Model : ORVmeIOCard <ORDataTaker,ORHWWizard,ORHWRamping,AutoTesting,ORAdcInfoProviding>
{
  @private
	BOOL			isRunning;
	 	
	//clocks and delays (Acquistion control reg)
	int	 clockSource;
	
	unsigned long   lostDataId;
	unsigned long   dataId;
	unsigned long   mcaId;
	
	unsigned long   mcaStatusResults[kNumMcaStatusRequests];
	short			internalTriggerEnabledMask; 
	short			externalTriggerEnabledMask;
	short			extendedThresholdEnabledMask;
	short			internalGateEnabledMask;
	short			externalGateEnabledMask;
	short			inputInvertedMask;
	short			triggerOutEnabledMask;
	short			highEnergySuppressMask;
	short			adc50KTriggerEnabledMask;
	short			gtMask;
	bool			waitingForSomeChannels;
    short			bufferWrapEnabledMask;
	
	NSMutableArray*	cfdControls;
	NSMutableArray* thresholds;
	NSMutableArray* highThresholds;
    NSMutableArray* dacOffsets;
	NSMutableArray* gateLengths;
	NSMutableArray* pulseLengths;
	NSMutableArray* sumGs;
	NSMutableArray* peakingTimes;
	NSMutableArray* internalTriggerDelays;
	NSMutableArray* sampleLengths;
    NSMutableArray* sampleStartIndexes;
    NSMutableArray* preTriggerDelays;
    NSMutableArray* triggerGateLengths;
	NSMutableArray*	triggerDecimations;
    NSMutableArray* energyGateLengths;
	NSMutableArray* energyPeakingTimes;
    NSMutableArray* energyGapTimes;
    NSMutableArray* energyTauFactors;
	NSMutableArray* energyDecimations;
	NSMutableArray* endAddressThresholds;
	
	ORRateGroup*	waveFormRateGroup;
	unsigned long 	waveFormCount[kNumSIS3302Channels];

	unsigned long location;
	short wrapMaskForRun;
	id theController;
	int currentBank;
	long count;
    short lemoOutMode;
    short lemoInMode;
	BOOL bankOneArmed;
	BOOL firstTime;
	BOOL shipEnergyWaveform;
	BOOL shipSummedWaveform;
	
    int energySampleLength;
    int energySampleStartIndex1;
    int energySampleStartIndex2;
    int energySampleStartIndex3;
	int energyNumberToSum;
    int runMode;
    unsigned short lemoInEnabledMask;
    BOOL internalExternalTriggersOred;
	
	unsigned long* dataRecord[4];
	unsigned long  dataRecordlength[4];
	
	//calculated values
	unsigned long numEnergyValues;
	unsigned long numRawDataLongWords;
	unsigned long rawDataIndex;
	unsigned long eventLengthLongWords;
    unsigned long mcaNofHistoPreset;
    BOOL			mcaLNESetup;
    unsigned long	mcaPrescaleFactor;
    BOOL			mcaAutoClear;
    unsigned long	mcaNofScansPreset;
    int				mcaHistoSize;
    BOOL			mcaPileupEnabled;
    BOOL			mcaScanBank2Flag;
    int				mcaMode;
    int				mcaEnergyDivider;
    int				mcaEnergyMultiplier;
    int				mcaEnergyOffset;
    BOOL			mcaUseEnergyCalculation;
    BOOL			shipTimeRecordAlso;
    float			firmwareVersion;
	time_t			lastBankSwitchTime;
	unsigned long	waitCount;
	unsigned long	channelsToReadMask;
    BOOL pulseMode;
}

- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark ***Accessors
- (BOOL) pulseMode;
- (void) setPulseMode:(BOOL)aPulseMode;
- (float) firmwareVersion;
- (void) setFirmwareVersion:(float)aFirmwareVersion;
- (BOOL) shipTimeRecordAlso;
- (void) setShipTimeRecordAlso:(BOOL)aShipTimeRecordAlso;
- (BOOL) mcaUseEnergyCalculation;
- (void) setMcaUseEnergyCalculation:(BOOL)aMcaUseEnergyCalculation;
- (int) mcaEnergyOffset;
- (void) setMcaEnergyOffset:(int)aMcaEnergyOffset;
- (int) mcaEnergyMultiplier;
- (void) setMcaEnergyMultiplier:(int)aMcaEnergyMultiplier;
- (int) mcaEnergyDivider;
- (void) setMcaEnergyDivider:(int)aMcaEnergyDivider;
- (unsigned long) mcaStatusResult:(int)index;
- (int) mcaMode;
- (void) setMcaMode:(int)aMcaMode;
- (BOOL) mcaPileupEnabled;
- (void) setMcaPileupEnabled:(BOOL)aMcaPileupEnabled;
- (int) mcaHistoSize;
- (void) setMcaHistoSize:(int)aMcaHistoSize;
- (unsigned long) mcaNofScansPreset;
- (void) setMcaNofScansPreset:(unsigned long)aMcaNofScansPreset;
- (BOOL) mcaAutoClear;
- (void) setMcaAutoClear:(BOOL)aMcaAutoClear;
- (unsigned long) mcaPrescaleFactor;
- (void) setMcaPrescaleFactor:(unsigned long)aMcaPrescaleFactor;
- (BOOL) mcaLNESetup;
- (void) setMcaLNESetup:(BOOL)aMcaLNESetup;
- (unsigned long) mcaNofHistoPreset;
- (void) setMcaNofHistoPreset:(unsigned long)aMcaNofHistoPreset;
- (BOOL) internalExternalTriggersOred;
- (void) setInternalExternalTriggersOred:(BOOL)aInternalExternalTriggersOred;
- (unsigned short) lemoInEnabledMask;
- (void) setLemoInEnabledMask:(unsigned short)aLemoInEnableMask;
- (BOOL) lemoInEnabled:(unsigned short)aBit;
- (void) setLemoInEnabled:(unsigned short)aBit withValue:(BOOL)aState;
- (int)  runMode;
- (void) setRunMode:(int)aRunMode;
- (unsigned long) endAddressThreshold:(short)aGroup; 
- (void) setEndAddressThreshold:(short)aGroup withValue:(unsigned long)aValue;
- (int) energyTauFactor:(short)aChannel;
- (void) setEnergyTauFactor:(short)aChannel withValue:(int)aValue;
- (int)  energySampleStartIndex3;
- (void) setEnergySampleStartIndex3:(int)aEnergySampleStartIndex3;
- (int)  energySampleStartIndex2;
- (void) setEnergySampleStartIndex2:(int)aEnergySampleStartIndex2;
- (int)  energySampleStartIndex1;
- (void) setEnergySampleStartIndex1:(int)aEnergySampleStartIndex1;
- (int)	 energyNumberToSum;
- (void) setEnergyNumberToSum:(int)aNumberToSum;
- (int)  energySampleLength;
- (void) setEnergySampleLength:(int)aEnergySampleLength;
- (int) energyGapTime:(short)aGroup;
- (void) setEnergyGapTime:(short)aGroup withValue:(int)aValue;
- (int) energyPeakingTime:(short)aGroup;
- (void) setEnergyPeakingTime:(short)aGroup withValue:(int)aValue;
- (unsigned long) getThresholdRegOffsets:(int) channel;
- (unsigned long) getExtendedThresholdRegOffsets:(int) channel;
- (unsigned long) getTriggerSetupRegOffsets:(int) channel; 
- (unsigned long) getTriggerExtSetupRegOffsets:(int)channel;
- (unsigned long) getSampleAddress:(int)channel;
- (unsigned long) getAdcMemory:(int)channel;
- (unsigned long) getEventConfigOffsets:(int)group;
- (unsigned long) getEnergyGateLengthOffsets:(int)group;
- (unsigned long) getExtendedEventConfigOffsets:(int)group;
- (unsigned long) getEndThresholdRegOffsets:(int)group;
- (unsigned long) getRawDataBufferConfigOffsets:(int)group;
- (unsigned long) getEnergyTauFactorOffset:(int) channel;
- (unsigned long) getEnergySetupGPOffset:(int)group;
- (unsigned long) getPreTriggerDelayTriggerGateLengthOffset:(int) aGroup; 
- (unsigned long) getBufferControlOffset:(int) aGroup; 
- (unsigned long) getPreviousBankSampleRegister:(int)channel;

- (int) energyGateLength:(short)aGroup;
- (void) setEnergyGateLength:(short)aGroup withValue:(int)aEnergyGateLength;

- (unsigned short) sampleLength:(short)group;
- (void) setSampleLength:(short)group withValue:(int)aValue;

- (int)  triggerGateLength:(short)group;
- (void) setTriggerGateLength:(short)group withValue:(int)aTriggerGateLength;

- (int)  preTriggerDelay:(short)group;
- (void) setPreTriggerDelay:(short)group withValue:(int)aPreTriggerDelay;

- (int) sampleStartIndex:(int)aGroup;
- (void) setSampleStartIndex:(int)aGroup withValue:(unsigned short)aSampleStartIndex;

- (short) lemoInMode;
- (void) setLemoInMode:(short)aLemoInMode;
- (NSString*) lemoInAssignments;
- (short) lemoOutMode;
- (void) setLemoOutMode:(short)aLemoOutMode;
- (NSString*) lemoOutAssignments;
- (void) setDefaults;

- (int) clockSource;
- (void) setClockSource:(int)aClockSource;

- (short) bufferWrapEnabledMask;
- (void) setBufferWrapEnabledMask:(short)aMask;
- (BOOL) bufferWrapEnabled:(short)chan;
- (void) setBufferWrapEnabled:(short)chan withValue:(BOOL)aValue;

- (short) internalTriggerEnabledMask;
- (void) setInternalTriggerEnabledMask:(short)aMask;
- (BOOL) internalTriggerEnabled:(short)chan;
- (void) setInternalTriggerEnabled:(short)chan withValue:(BOOL)aValue;

- (short) externalTriggerEnabledMask;
- (void) setExternalTriggerEnabledMask:(short)aMask;
- (BOOL) externalTriggerEnabled:(short)chan;
- (void) setExternalTriggerEnabled:(short)chan withValue:(BOOL)aValue;

- (short) extendedThresholdEnabledMask;
- (void) setExtendedThresholdEnabledMask:(short)aMask;
- (BOOL) extendedThresholdEnabled:(short)chan;
- (void) setExtendedThresholdEnabled:(short)chan withValue:(BOOL)aValue;

- (short) internalGateEnabledMask;
- (void) setInternalGateEnabledMask:(short)aMask;
- (BOOL) internalGateEnabled:(short)chan;
- (void) setInternalGateEnabled:(short)chan withValue:(BOOL)aValue;

- (short) externalGateEnabledMask;
- (void) setExternalGateEnabledMask:(short)aMask;
- (BOOL) externalGateEnabled:(short)chan;
- (void) setExternalGateEnabled:(short)chan withValue:(BOOL)aValue;

- (short) inputInvertedMask;
- (void) setInputInvertedMask:(short)aMask;
- (BOOL) inputInverted:(short)chan;
- (void) setInputInverted:(short)chan withValue:(BOOL)aValue;

- (short) triggerOutEnabledMask;
- (void) setTriggerOutEnabledMask:(short)aMask;
- (BOOL) triggerOutEnabled:(short)chan;
- (void) setTriggerOutEnabled:(short)chan withValue:(BOOL)aValue;

- (short) highEnergySuppressMask;
- (void) setHighEnergySuppressMask:(short)aMask;
- (BOOL) highEnergySuppress:(short)chan;
- (void) setHighEnergySuppress:(short)chan withValue:(BOOL)aValue;

- (short) adc50KTriggerEnabledMask;
- (void) setAdc50KTriggerEnabledMask:(short)aMask;
- (BOOL) adc50KTriggerEnabled:(short)chan;
- (void) setAdc50KTriggerEnabled:(short)chan withValue:(BOOL)aValue;

- (BOOL) shipEnergyWaveform;
- (void) setShipEnergyWaveform:(BOOL)aState;

- (BOOL) shipSummedWaveform;
- (void) setShipSummedWaveform:(BOOL)aState;
- (NSString*) energyBufferAssignment;

- (short) gtMask;
- (void) setGtMask:(long)aMask;
- (BOOL) gt:(short)chan;
- (void) setGtBit:(short)chan withValue:(BOOL)aValue;
- (short) internalTriggerDelay:(short)chan;
- (void) setInternalTriggerDelay:(short)chan withValue:(short)aValue;
- (int) triggerDecimation:(short)aGroup;
- (void) setTriggerDecimation:(short)aGroup withValue:(short)aValue;
- (short) energyDecimation:(short)aGroup;
- (void) setEnergyDecimation:(short)aGroup withValue:(short)aValue;
- (short) cfdControl:(short)aChannel;
- (void) setCfdControl:(short)aChannel withValue:(short)aValue;

- (int) threshold:(short)chan;
- (void) setThreshold:(short)chan withValue:(int)aValue;
- (int) highThreshold:(short)chan;
- (void) setHighThreshold:(short)chan withValue:(int)aValue;
- (unsigned short) dacOffset:(short)chan;
- (void) setDacOffset:(short)aChan withValue:(int)aValue;
- (void) setPulseLength:(short)aChan withValue:(short)aValue;
- (short) pulseLength:(short)chan;
- (void) setGateLength:(short)aChan withValue:(short)aValue;
- (short) gateLength:(short)chan;
- (void) setSumG:(short)aChan withValue:(short)aValue;
- (short) sumG:(short)chan;
- (short) peakingTime:(short)aChan;
- (void) setPeakingTime:(short)aChan withValue:(short)aValue;

- (void) initParams;

- (ORRateGroup*)    waveFormRateGroup;
- (void)			setWaveFormRateGroup:(ORRateGroup*)newRateGroup;
- (id)              rateObject:(int)channel;
- (void)            setRateIntegrationTime:(double)newIntegrationTime;
- (BOOL)			bumpRateFromDecodeStage:(short)channel;

- (void) calculateSampleValues;
- (void) calculateEnergyGateLength;

#pragma mark •••Hardware Access
- (int) limitIntValue:(int)aValue min:(int)aMin max:(int)aMax;
- (void) initBoard;
- (void) readModuleID:(BOOL)verbose;
- (void) writeAcquistionRegister;
- (void) writeEventConfiguration;
- (void) writeThresholds;
- (void) writeHighThresholds;
- (void) readThresholds:(BOOL)verbose;
- (void) readHighThresholds:(BOOL)verbose;
- (void) setLed:(BOOL)state;
- (void) briefReport;
- (void) regDump;
- (void) resetSamplingLogic;
- (void) writePageRegister:(int) aPage;
- (void) writePreTriggerDelayAndTriggerGateDelay;
- (void) writeEnergyGP;
- (void) writeRawDataBufferConfiguration;
- (void) writeEndAddressThresholds;
- (void) writeEndAddressThreshold:(int)aGroup;
- (void) writeEnergyGateLength;
- (void) writeEnergyTauFactor;
- (void) writeEnergySampleLength;
- (void) writeEnergySampleStartIndexes;
- (void) writeEnergyNumberToSum;
- (void) writeBufferControl;

- (void) disarmSampleLogic;
- (void) clearTimeStamp;
- (void) writeTriggerSetups;

- (void) writeMcaLNESetupAndPrescalFactor;
- (void) writeMcaScanControl;
- (void) writeMcaNofHistoPreset;
- (void) writeMcaLNEPulse;
- (void) writeMcaArm;
- (void) writeMcaScanEnable;
- (void) writeMcaScanDisable;
- (void) writeMcaMultiScanStartReset;
- (void) writeMcaMultiScanArmScanArm;
- (void) writeMcaMultiScanArmScanEnable;
- (void) writeMcaMultiScanDisable;
- (void) writeHistogramParams;
- (void) writeMcaMultiScanNofScansPreset;
- (void) writeMcaArmMode;
- (void) writeMcaCalculationFactors;

- (void) executeCommandList:(ORCommandList*) aList;

- (unsigned long) acqReg;
- (unsigned long) getPreviousBankSampleRegisterOffset:(int) channel;
- (unsigned long) getADCBufferRegisterOffset:(int) channel;
- (void) disarmAndArmBank:(int) bank;
- (void) disarmAndArmNextBank;
- (void) forceTrigger;
- (NSString*) runSummary;

#pragma mark •••Data Taker
- (unsigned long) lostDataId;
- (void) setLostDataId: (unsigned long) anId;
- (unsigned long) mcaId;
- (void) setMcaId: (unsigned long) anId;
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
- (BOOL) isEvent;
- (void) setUpPageReg;

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
extern NSString* ORSIS3302ModelPulseModeChanged;
extern NSString* ORSIS3302ModelFirmwareVersionChanged;
extern NSString* ORSIS3302ModelBufferWrapEnabledChanged;
extern NSString* ORSIS3302ModelCfdControlChanged;
extern NSString* ORSIS3302ModelShipTimeRecordAlsoChanged;
extern NSString* ORSIS3302ModelMcaUseEnergyCalculationChanged;
extern NSString* ORSIS3302ModelMcaEnergyOffsetChanged;
extern NSString* ORSIS3302ModelMcaEnergyMultiplierChanged;
extern NSString* ORSIS3302ModelMcaEnergyDividerChanged;
extern NSString* ORSIS3302ModelMcaModeChanged;
extern NSString* ORSIS3302ModelMcaPileupEnabledChanged;
extern NSString* ORSIS3302ModelMcaHistoSizeChanged;
extern NSString* ORSIS3302ModelMcaNofScansPresetChanged;
extern NSString* ORSIS3302ModelMcaAutoClearChanged;
extern NSString* ORSIS3302ModelMcaPrescaleFactorChanged;
extern NSString* ORSIS3302ModelMcaLNESetupChanged;
extern NSString* ORSIS3302ModelMcaNofHistoPresetChanged;
extern NSString* ORSIS3302ModelInternalExternalTriggersOredChanged;
extern NSString* ORSIS3302ModelLemoInEnabledMaskChanged;
extern NSString* ORSIS3302ModelEnergyGateLengthChanged;
extern NSString* ORSIS3302ModelRunModeChanged;
extern NSString* ORSIS3302ModelEndAddressThresholdChanged;
extern NSString* ORSIS3302ModelEnergySampleStartIndex3Changed;
extern NSString* ORSIS3302ModelEnergyTauFactorChanged;
extern NSString* ORSIS3302ModelEnergySampleStartIndex2Changed;
extern NSString* ORSIS3302ModelEnergySampleStartIndex1Changed;
extern NSString* ORSIS3302ModelEnergyNumberToSumChanged;
extern NSString* ORSIS3302ModelEnergySampleLengthChanged;
extern NSString* ORSIS3302ModelEnergyGapTimeChanged;
extern NSString* ORSIS3302ModelEnergyPeakingTimeChanged;
extern NSString* ORSIS3302ModelTriggerGateLengthChanged;
extern NSString* ORSIS3302ModelPreTriggerDelayChanged;
extern NSString* ORSIS3302SampleStartIndexChanged;
extern NSString* ORSIS3302SampleLengthChanged;
extern NSString* ORSIS3302DacOffsetChanged;
extern NSString* ORSIS3302LemoInModeChanged;
extern NSString* ORSIS3302LemoOutModeChanged;
extern NSString* ORSIS3302AcqRegEnableMaskChanged;

extern NSString* ORSIS3302AcqRegChanged;
extern NSString* ORSIS3302EventConfigChanged;

extern NSString* ORSIS3302ClockSourceChanged;
extern NSString* ORSIS3302TriggerOutEnabledChanged;
extern NSString* ORSIS3302HighEnergySuppressChanged;
extern NSString* ORSIS3302ThresholdChanged;
extern NSString* ORSIS3302ThresholdArrayChanged;
extern NSString* ORSIS3302HighThresholdChanged;
extern NSString* ORSIS3302HighThresholdArrayChanged;
extern NSString* ORSIS3302GtChanged;

extern NSString* ORSIS3302SettingsLock;
extern NSString* ORSIS3302RateGroupChangedNotification;
extern NSString* ORSIS3302SampleDone;
extern NSString* ORSIS3302IDChanged;
extern NSString* ORSIS3302GateLengthChanged;
extern NSString* ORSIS3302PulseLengthChanged;
extern NSString* ORSIS3302SumGChanged;
extern NSString* ORSIS3302PeakingTimeChanged;
extern NSString* ORSIS3302InternalTriggerDelayChanged;
extern NSString* ORSIS3302TriggerDecimationChanged;
extern NSString* ORSIS3302EnergyDecimationChanged;
extern NSString* ORSIS3302SetShipWaveformChanged;
extern NSString* ORSIS3302SetShipSummedWaveformChanged;
extern NSString* ORSIS3302Adc50KTriggerEnabledChanged;
extern NSString* ORSIS3302InputInvertedChanged;

extern NSString* ORSIS3302InternalTriggerEnabledChanged;
extern NSString* ORSIS3302ExternalTriggerEnabledChanged;
extern NSString* ORSIS3302ExtendedThresholdEnabledChanged;
extern NSString* ORSIS3302InternalGateEnabledChanged;
extern NSString* ORSIS3302ExternalGateEnabledChanged;
extern NSString* ORSIS3302McaStatusChanged;
extern NSString* ORSIS3302CardInited;
