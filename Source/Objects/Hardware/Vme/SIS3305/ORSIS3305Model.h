//-------------------------------------------------------------------------
//  ORSIS3305.h
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


@class ORRateGroup;
@class ORAlarm;
@class ORCommandList;

@interface ORSIS3305Model : ORVmeIOCard <ORDataTaker,ORHWWizard,ORHWRamping,AutoTesting>
{
  @private
	BOOL			isRunning;
    
    BOOL			enabled[kNumSIS3305Channels];
	//clocks and delays (Acquistion control reg)
	int             clockSource;
    short           eventSavingMode[kNumSIS3305Groups];
    BOOL            TDCMeasurementEnabled;
    BOOL            ledApplicationMode;
    BOOL            ledEnable[3];
    BOOL    writeGainPhaseOffset;
    float   temperature;
    
    
    unsigned long   registerWriteValue;
    int             registerIndex;
    unsigned long   spiWriteValue;
    
    
    // event config bits
    BOOL    ADCGateModeEnabled[kNumSIS3305Groups];
    BOOL    globalTriggerEnabled[kNumSIS3305Groups];
    BOOL    internalTriggerEnabled[kNumSIS3305Groups];
    BOOL    startEventSamplingWithExtTrigEnabled[kNumSIS3305Groups];
    BOOL    clearTimestampWhenSamplingEnabledEnabled[kNumSIS3305Groups];
    BOOL    clearTimestampDisabled[kNumSIS3305Groups];
    BOOL    grayCodeEnabled[kNumSIS3305Groups];
    BOOL    directMemoryHeaderDisabled[kNumSIS3305Groups];
    BOOL    waitPreTrigTimeBeforeDirectMemTrig[kNumSIS3305Groups];
    
    
    unsigned short  channelMode[kNumSIS3305Groups];
    unsigned short  bandwidth[kNumSIS3305Groups];
    unsigned short  testMode[kNumSIS3305Groups];
    unsigned long   adcOffset[kNumSIS3305Channels];
    unsigned long   adcGain[kNumSIS3305Channels];
    unsigned long   adcPhase[kNumSIS3305Channels];
    
    short			internalTriggerEnabledMask;
    short			externalTriggerEnabledMask;
    short			internalGateEnabledMask;
    short			externalGateEnabledMask;
    short			inputInvertedMask;
    short			triggerOutEnabledMask;
    
    
    
    BOOL        enableExternalLEMODirectVetoIn;
    BOOL        enableExternalLEMOResetIn;
    BOOL        enableExternalLEMOCountIn;
    BOOL        invertExternalLEMODirectVetoIn;
    BOOL        enableExternalLEMOTriggerIn;
    BOOL        enableExternalLEMOVetoDelayLengthLogic;
    BOOL        edgeSensitiveExternalVetoDelayLengthLogic;
    BOOL        invertExternalVetoInDelayLengthLogic;
    BOOL        gateModeExternalVetoInDelayLengthLogic;
    BOOL        enableMemoryOverrunVeto;
    BOOL        controlLEMOTriggerOut;
    
    BOOL    lemoOutSelectTrigger[kNumSIS3305Channels];
    BOOL    lemoOutSelectTriggerIn;
    BOOL    lemoOutSelectTriggerInPulse;
    BOOL    lemoOutSelectTriggerInPulseWithSampleAndTDC;
    BOOL    lemoOutSelectSampleLogicArmed;
    BOOL    lemoOutSelectSampleLogicEnabled;
    BOOL    lemoOutSelectKeyOutputPulse;
    BOOL    lemoOutSelectControlLemoTriggerOut;
    BOOL    lemoOutSelectExternalVeto;
    BOOL    lemoOutSelectInternalKeyVeto;
    BOOL    lemoOutSelectExternalVetoLength;
    BOOL    lemoOutSelectMemoryOverrunVeto;
    
    
    // temp and temp supervisor
    BOOL   temperatureSupervisorEnable;
    unsigned long   tempThreshRaw;
    float           tempThreshConverted;
	
    unsigned long   ringbufferPreDelay[kNumSIS3305Channels];    // ringbuffer pretrigger delays
    
	unsigned long   dataId;
	


//    short			ltMask;
//    short			gtMask;
	bool			waitingForSomeChannels;
    short			bufferWrapEnabledMask;

    BOOL    LTThresholdEnabled[kNumSIS3305Channels];
    BOOL    GTThresholdEnabled[kNumSIS3305Channels];
    short   thresholdMode[kNumSIS3305Channels];         // this is complicated, since, setting any of these three could change another...
    
    int     tapDelay[kNumSIS3305Channels];
    
//	NSMutableArray*	cfdControls;
	NSMutableArray* thresholds;
    
    unsigned int     GTThresholdOn[kNumSIS3305Channels];
    unsigned int     GTThresholdOff[kNumSIS3305Channels];
    unsigned int     LTThresholdOn[kNumSIS3305Channels];
    unsigned int     LTThresholdOff[kNumSIS3305Channels];
//    int     preTriggerDelays[kNumSIS3305Channels];
    int     gain[kNumSIS3305Channels];
    
    
//	NSMutableArray* highThresholds;
    NSMutableArray* dacOffsets;
	NSMutableArray* gateLengths;
	NSMutableArray* pulseLengths;
//	NSMutableArray* peakingTimes;
	NSMutableArray* internalTriggerDelays;
	NSMutableArray* sampleLengths;
    NSMutableArray* sampleStartIndexes;
//    NSMutableArray* preTriggerDelays;
    NSMutableArray* triggerGateLengths;
//	NSMutableArray*	triggerDecimations;
    NSMutableArray* energyGateLengths;

	NSMutableArray* endAddressThresholds;
	
	ORRateGroup*	waveFormRateGroup;
	unsigned long 	waveFormCount[kNumSIS3305Channels];

	unsigned long location;
	short wrapMaskForRun;
	id theController;
//	int currentBank;
	long count;
    short lemoOutMode;
    short lemoInMode;
//	BOOL bankOneArmed;
	BOOL firstTime;
//	BOOL shipEnergyWaveform;
//	BOOL shipSummedWaveform;
	
//    int energySampleLength;
//    int energySampleStartIndex1;
//    int energySampleStartIndex2;
//    int energySampleStartIndex3;
//	int energyNumberToSum;
    int runMode;
    unsigned short lemoInEnabledMask;
    BOOL internalExternalTriggersOred;
		
	//calculated values
	unsigned long numEnergyValues;
	unsigned long numRawDataLongWords;
	unsigned long rawDataIndex;
	unsigned long eventLengthLongWords[kNumSIS3305Groups];
    
    
    unsigned long sampleStartAddress[kNumSIS3305Groups];
//    unsigned long mcaNofHistoPreset;
//    BOOL			mcaLNESetup;
//    unsigned long	mcaPrescaleFactor;
//    BOOL			mcaAutoClear;
//    unsigned long	mcaNofScansPreset;
//    int				mcaHistoSize;
//    BOOL			mcaPileupEnabled;
//    BOOL			mcaScanBank2Flag;
//    int				mcaMode;
//    int				mcaEnergyDivider;
//    int				mcaEnergyMultiplier;
//    int				mcaEnergyOffset;
//    BOOL			mcaUseEnergyCalculation;
    BOOL			shipTimeRecordAlso;
    float			firmwareVersion;
//	time_t			lastBankSwitchTime;
	unsigned long	waitCount;
	unsigned long	channelsToReadMask;
    BOOL pulseMode;
    
    
    //    The SPI interface uses a particular type for communication, defined in the sis3305.h file from struck
    struct SIS3305_ADC_SPI_Config_Struct {
        unsigned int 	chipID[2]; 		// addr=0, read
        unsigned int 	control[2]; 	// addr=1  write
        unsigned int 	status[2]; 		// addr=2  read
        unsigned int 	testMode[2]; 	// addr=5  write
        unsigned int 	uint_spi_phase_adc[8];
        unsigned int    spi_4chMode_gain_adc[8];	   // 4-channel Mode
        unsigned int 	spi_4chMode_offset_adc[8];	   // 4-channel Mode
        unsigned int 	spi_2chModeAC_gain_adc[8];	   // 2-channel Mode use inputs A,C
        unsigned int 	spi_2chModeAC_offset_adc[8];  // 2-channel Mode use inputs A,C
        unsigned int 	spi_2chModeBD_gain_adc[8];	   // 2-channel Mode use inputs B,D
        unsigned int 	spi_2chModeBD_offset_adc[8];  // 2-channel Mode use inputs B,D
        unsigned int 	spi_1chModeA_gain_adc[8];	   // 1-channel Mode use input A
        unsigned int 	spi_1chModeA_offset_adc[8];   // 1-channel Mode use input A
        unsigned int 	spi_1chModeB_gain_adc[8];	   // 1-channel Mode use input B
        unsigned int 	spi_1chModeB_offset_adc[8];   // 1-channel Mode use input B
        unsigned int 	spi_1chModeC_gain_adc[8];	   // 1-channel Mode use input C
        unsigned int 	spi_1chModeC_offset_adc[8];   // 1-channel Mode use input C
        unsigned int 	spi_1chModeD_gain_adc[8];	   // 1-channel Mode use input D
        unsigned int 	spi_1chModeD_offset_adc[8];   // 1-channel Mode use input D
    } ;
    
    
//    const unsigned short kchannelModeAndEventID[16][8];
    
    
//    struct SIS3305_ADC_SPI_Config_Struct {
//        unsigned int 	uintChipID[2]; 		// addr=0, read
//        unsigned int 	uintControl[2]; 	// addr=1  write
//        unsigned int 	uintStatus[2]; 		// addr=2  read
//        unsigned int 	uintTestMode[2]; 	// addr=5  write
//        unsigned int 	uint_spi_phase_adc[8];
//        unsigned int 	uint_spi_4chMode_gain_adc[8];	   // 4-channel Mode
//        unsigned int 	uint_spi_4chMode_offset_adc[8];	   // 4-channel Mode
//        unsigned int 	uint_spi_2chModeAC_gain_adc[8];	   // 2-channel Mode use inputs A,C
//        unsigned int 	uint_spi_2chModeAC_offset_adc[8];  // 2-channel Mode use inputs A,C
//        unsigned int 	uint_spi_2chModeBD_gain_adc[8];	   // 2-channel Mode use inputs B,D
//        unsigned int 	uint_spi_2chModeBD_offset_adc[8];  // 2-channel Mode use inputs B,D
//        unsigned int 	uint_spi_1chModeA_gain_adc[8];	   // 1-channel Mode use input A
//        unsigned int 	uint_spi_1chModeA_offset_adc[8];   // 1-channel Mode use input A
//        unsigned int 	uint_spi_1chModeB_gain_adc[8];	   // 1-channel Mode use input B
//        unsigned int 	uint_spi_1chModeB_offset_adc[8];   // 1-channel Mode use input B
//        unsigned int 	uint_spi_1chModeC_gain_adc[8];	   // 1-channel Mode use input C
//        unsigned int 	uint_spi_1chModeC_offset_adc[8];   // 1-channel Mode use input C
//        unsigned int 	uint_spi_1chModeD_gain_adc[8];	   // 1-channel Mode use input D
//        unsigned int 	uint_spi_1chModeD_offset_adc[8];   // 1-channel Mode use input D
//    } ;
    
    int groupToRead;
}

- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark ***Accessors
- (BOOL) enabled:(short)chan;
- (void) setEnabled:(short)chan withValue:(BOOL)aValue;
- (short) tapDelay:(short)chan;
- (void) setTapDelay:(short)chan withValue:(short)aValue;

- (BOOL) pulseMode;
- (void) setPulseMode:(BOOL)aPulseMode;
- (float) firmwareVersion;
- (void) setFirmwareVersion:(float)aFirmwareVersion;
- (float) temperature;
- (float) getTemperature;
- (void) probeBoard;

- (BOOL) shipTimeRecordAlso;
- (void) setShipTimeRecordAlso:(BOOL)aShipTimeRecordAlso;

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


- (unsigned long) getGTThresholdRegOffsets:(int) channel;
- (unsigned long) getLTThresholdRegOffsets:(int) channel;

- (unsigned long) getEndAddressThresholdRegOffsets:(int)group;



- (unsigned long) sampleLength:(short)group;
- (void) setSampleLength:(short)group withValue:(unsigned long)aValue;

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

- (BOOL) writeGainPhaseOffsetEnabled;
- (void) setWriteGainPhaseOffsetEnabled:(BOOL)value;

- (short) eventSavingMode:(short)aGroup;
- (void) setEventSavingModeOf:(short)aGroup toValue:(short)aMode;
- (BOOL) TDCMeasurementEnabled;
- (void) setTDCMeasurementEnabled: (BOOL)aState;

- (short) bufferWrapEnabledMask;
- (void) setBufferWrapEnabledMask:(short)aMask;
- (BOOL) bufferWrapEnabled:(short)chan;
- (void) setBufferWrapEnabled:(short)chan withValue:(BOOL)aValue;

//- (short) internalTriggerEnabledMask;
//- (void) setInternalTriggerEnabledMask:(short)aMask;


// register R/W accessors
- (short) registerIndex;
- (void) setRegisterIndex:(int)aRegisterIndex;
- (unsigned long) registerWriteValue;
- (void) setRegisterWriteValue:(unsigned long)aWriteValue;
- (NSString*) registerNameAt:(unsigned int)index;
- (unsigned short) registerOffsetAt:(unsigned int)index;

// event config accessors
- (BOOL) ADCGateModeEnabled:(unsigned short)group;
- (void) setADCGateModeEnabled:(unsigned short)group toValue:(BOOL)value;
- (BOOL) globalTriggerEnabledOnGroup:(unsigned short)group;
- (void) setGlobalTriggerEnabledOnGroup:(unsigned short)group toValue:(BOOL)value;
- (BOOL) internalTriggerEnabled:(short)chan;
- (void) setInternalTriggerEnabled:(short)chan toValue:(BOOL)aValue;
- (BOOL) startEventSamplingWithExtTrigEnabled:(unsigned short)group;
- (void) setStartEventSamplingWithExtTrigEnabled:(unsigned short)group toValue:(BOOL)value;
- (BOOL) clearTimestampWhenSamplingEnabledEnabled:(unsigned short)group;
- (void) setClearTimestampWhenSamplingEnabledEnabled:(unsigned short)group toValue:(BOOL)value;
- (BOOL) clearTimestampDisabled:(unsigned short)group;
- (void) setClearTimestampDisabled:(unsigned short)group toValue:(BOOL)value;
- (BOOL) grayCodeEnabled:(unsigned short)group;
- (void) setGrayCodeEnabled:(unsigned short)group toValue:(BOOL) value;
- (BOOL) directMemoryHeaderDisabled:(unsigned short)group;
- (void) setDirectMemoryHeaderDisabled:(unsigned short)group toValue:(BOOL)value;
- (BOOL) waitPreTrigTimeBeforeDirectMemTrig:(unsigned short)group;
- (void) setWaitPreTrigTimeBeforeDirectMemTrig:(unsigned short)group toValue:(BOOL)value;



- (unsigned short) channelMode:(unsigned short)group;
- (void) setChannelMode:(unsigned short)group withValue:(unsigned short)mode;
- (unsigned short) bandwidth:(unsigned short)group;
- (void) setBandwidth:(unsigned short)group withValue:(unsigned short)value;
- (unsigned short) testMode:(unsigned short)group;
- (void) setTestMode:(unsigned short)group withValue:(unsigned short)value;

- (unsigned long) adcOffset:(unsigned short)chan;
- (void) setAdcOffset:(unsigned short)chan toValue:(unsigned long)value;
- (unsigned long) adcGain:(unsigned short)chan;
- (void) setAdcGain:(unsigned short)chan toValue:(unsigned long)value;
- (unsigned long) adcPhase:(unsigned short)chan;
- (void) setAdcPhase:(unsigned short)chan toValue:(unsigned long)value;



- (short) externalTriggerEnabledMask;
- (void) setExternalTriggerEnabledMask:(short)aMask;
- (BOOL) externalTriggerEnabled:(short)chan;
- (void) setExternalTriggerEnabled:(short)chan withValue:(BOOL)aValue;

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

//- (BOOL) shipEnergyWaveform;
//- (void) setShipEnergyWaveform:(BOOL)aState;

//- (BOOL) shipSummedWaveform;
//- (void) setShipSummedWaveform:(BOOL)aState;
//- (NSString*) energyBufferAssignment;

//- (short) ltMask;
//- (short) gtMask;
//- (void) setLtMask:(long)aMask;
//- (void) setGtMask:(long)aMask;
//- (BOOL) lt:(short)chan;
//- (BOOL) gt:(short)chan;
//- (void) setLtBit:(short)chan withValue:(BOOL)aValue;
//- (void) setGtBit:(short)chan withValue:(BOOL)aValue;

- (short) internalTriggerDelay:(short)chan;
- (void) setInternalTriggerDelay:(short)chan withValue:(short)aValue;
//- (int) triggerDecimation:(short)aGroup;
//- (void) setTriggerDecimation:(short)aGroup withValue:(short)aValue;
//- (short) energyDecimation:(short)aGroup;
//- (void) setEnergyDecimation:(short)aGroup withValue:(short)aValue;
//- (short) cfdControl:(short)aChannel;
//- (void) setCfdControl:(short)aChannel withValue:(short)aValue;

//- (int) threshold:(short)chan;                  // should be properly removed
//- (void) setThreshold:(short)chan withValue:(int)aValue;    // should be properly removed

// control status reg
- (void) setLed:(unsigned short)ledNum to:(BOOL)state;


- (void) setEnableExternalLEMODirectVetoIn:(BOOL)state;
- (void) setEnableExternalLEMOResetIn:(BOOL)state;
- (void) setEnableExternalLEMOCountIn:(BOOL)state;
- (void) setInvertExternalLEMODirectVetoIn:(BOOL)state;
- (void) setEnableExternalLEMOTriggerIn:(BOOL)state;
- (void) setInvertExternalLEMODirectVetoIn:(BOOL)state;
- (void) setEnableExternalLEMOVetoDelayLengthLogic:(BOOL)state;
- (void) setEdgeSensitiveExternalVetoDelayLengthLogic:(BOOL)state;
- (void) setInvertExternalVetoInDelayLengthLogic:(BOOL)state;
- (void) setGateModeExternalVetoInDelayLengthLogic:(BOOL)state;
- (void) setEnableMemoryOverrunVeto:(BOOL)state;
- (void) setControlLEMOTriggerOut:(BOOL)state;
- (BOOL) enableExternalLEMODirectVetoIn;
- (BOOL) enableExternalLEMOTriggerIn;
- (BOOL) enableExternalLEMOResetIn;
- (BOOL) enableExternalLEMOCountIn;
- (BOOL) invertExternalLEMODirectVetoIn;
- (BOOL) invertExternalLEMODirectVetoIn;
- (BOOL) invertExternalLEMODirectVetoIn;
- (BOOL) enableExternalLEMOVetoDelayLengthLogic;
- (BOOL) edgeSensitiveExternalVetoDelayLengthLogic;
- (BOOL) invertExternalVetoInDelayLengthLogic;
- (BOOL) gateModeExternalVetoInDelayLengthLogic;
- (BOOL) enableMemoryOverrunVeto;
- (BOOL) controlLEMOTriggerOut;



- (BOOL) lemoOutSelectTrigger:(unsigned short)chan;
- (void) setLemoOutSelectTrigger:(unsigned short)chan toState:(BOOL)state;
- (BOOL) lemoOutSelectTriggerIn;
- (void) setLemoOutSelectTriggerIn:(BOOL)state;
- (BOOL) lemoOutSelectTriggerInPulse;
- (void) setLemoOutSelectTriggerInPulse:(BOOL)state;
- (BOOL) lemoOutSelectTriggerInPulseWithSampleAndTDC;
- (void) setLemoOutSelectTriggerInPulseWithSampleAndTDC:(BOOL)state;
- (BOOL) lemoOutSelectSampleLogicArmed;
- (void) setLemoOutSelectSampleLogicArmed:(BOOL)state;
- (BOOL) lemoOutSelectSampleLogicEnabled;
- (void) setLemoOutSelectSampleLogicEnabled:(BOOL)state;
- (BOOL) lemoOutSelectKeyOutputPulse;
- (void) setLemoOutSelectKeyOutputPulse:(BOOL)state;
- (BOOL) lemoOutSelectControlLemoTriggerOut;
- (void) setLemoOutSelectControlLemoTriggerOut:(BOOL)state;
- (BOOL) lemoOutSelectExternalVeto;
- (void) setLemoOutSelectExternalVeto:(BOOL)state;
- (BOOL) lemoOutSelectInternalKeyVeto;
- (void) setLemoOutSelectInternalKeyVeto:(BOOL)state;
- (BOOL) lemoOutSelectExternalVetoLength;
- (void) setLemoOutSelectExternalVetoLength:(BOOL)state;
- (BOOL) lemoOutSelectMemoryOverrunVeto;
- (void) setLemoOutSelectMemoryOverrunVeto:(BOOL)state;





- (BOOL) LTThresholdEnabled:(short)aChan;
- (BOOL) GTThresholdEnabled:(short)aChan;
- (void) setLTThresholdEnabled:(short)aChan withValue:(BOOL)aValue;
- (void) setGTThresholdEnabled:(short)aChan withValue:(BOOL)aValue;

- (short) thresholdMode:(short)chan;
- (void) setThresholdMode:(short)chan withValue:(short)aValue;

- (int) GTThresholdOn:(short)aChan;
- (void) setGTThresholdOn:(short)aChan withValue:(int)aValue;
- (int) GTThresholdOff:(short)aChan;
- (void) setGTThresholdOff:(short)aChan withValue:(int)aValue;
- (int) LTThresholdOn:(short)aChan;
- (void) setLTThresholdOn:(short)aChan withValue:(int)aValue;
- (int) LTThresholdOff:(short)aChan;
- (void) setLTThresholdOff:(short)aChan withValue:(int)aValue;

//- (int) highThreshold:(short)chan;
//- (void) setHighThreshold:(short)chan withValue:(int)aValue;
- (unsigned short) dacOffset:(short)chan;
- (void) setDacOffset:(short)aChan withValue:(int)aValue;
- (void) setPulseLength:(short)aChan withValue:(short)aValue;
- (short) pulseLength:(short)chan;
- (void) setGateLength:(short)aChan withValue:(short)aValue;
- (short) gateLength:(short)chan;

- (void) initParams;

- (ORRateGroup*)    waveFormRateGroup;
- (void)			setWaveFormRateGroup:(ORRateGroup*)newRateGroup;
- (id)              rateObject:(int)channel;
- (void)            setRateIntegrationTime:(double)newIntegrationTime;
- (BOOL)			bumpRateFromDecodeStage:(short)channel;


- (unsigned short) digitizationRate:(unsigned short) group;
- (unsigned long) longsInSample:(unsigned short)group;

//- (void) calculateSampleValues;









#pragma mark - Hardware Access

- (unsigned long) readRegister:(unsigned int)index;
- (void) writeRegister:(unsigned int)index withValue:(unsigned long)value;
- (void) writeToAddress:(unsigned long)anAddress aValue:(unsigned long)aValue;
- (unsigned long) readFromAddress:(unsigned long)anAddress;
- (BOOL) canReadRegister:(unsigned int)index;
- (BOOL) canWriteRegister:(unsigned int)index;



- (void) writeControlStatus;

- (void) writeLed:(short)ledNum to:(BOOL)state;
- (void) writeLedApplicationMode;

- (void) readModuleID:(BOOL)verbose;
- (unsigned long) readInterruptConfig:(BOOL)verbose;
- (void) writeInterruptConfig:(unsigned long)value;
- (unsigned long) readInterruptControl:(BOOL)verbose;
- (void) writeInterruptControl:(unsigned long)value;

// acquisition control methods
- (unsigned long) readAcquisitionControl:(BOOL)verbose;
- (void) writeAcquisitionControl;
- (void) writeClockSource:(unsigned long)aState;

- (unsigned long) readVetoLength:(BOOL)verbose;
- (void) writeVetoLength:(unsigned long)timeInNS;
- (unsigned long) readVetoDelay:(BOOL)verbose;
- (void) writeVetoDelay:(unsigned long)timeInNS;

- (unsigned long) EEPROMControlwithCommand:(short)command andAddress:(short)addr andData:(unsigned int)data;
- (unsigned long) onewireControlwithCommand:(short)command andData:(unsigned int)data;

- (unsigned long) readBroadcastSetup:(bool)verbose;
- (unsigned long) readLEMOTriggerOutSelect;
- (void) writeLEMOTriggerOutSelect:(unsigned long)value;
- (void) writeLEMOTriggerOutSelect;
- (unsigned long) readExternalTriggerCounter;

#pragma mark --- TDC Regs

- (unsigned long) readTDCWrite:(BOOL)verbose;
- (void) writeTDCWriteWithData:(unsigned long)data atAddress:(unsigned short)addr;
- (unsigned long) readTDCRead:(BOOL)verbose;
- (void) writeTDCReadatAddress:(unsigned short)addr;
- (unsigned long) readTDCStartStopEnable:(BOOL)verbose;
- (void) writeTDCStartStopEnable:(unsigned long)value;
- (void) writeXilinxJTAGTestWithTDI:(char)tdi andTMS:(char)tms;
- (unsigned long) readXilinxJTAGDataIn;

#pragma mark -- Other regs

- (unsigned long) readTemperature:(BOOL)verbose;
- (void) writeTemperatureThreshold:(unsigned long)thresh;



- (unsigned long) readADCSerialInterface:(BOOL)verbose;
- (unsigned long) readADCSerialInterfaceOnADC:(char)adcSelect fromAddress:(unsigned int)addr;
- (void) writeADCSerialInterface:(unsigned int)data onADC:(char)adcSelect toAddress:(unsigned int)addr viaSPI:(char)spiOn;
- (void) writeADCSerialInterface:(unsigned int)data onADC:(char)adcSelect toAddress:(unsigned int)addr;
- (void) writeADCSerialInterface;
- (unsigned long) readADCChipID;
- (unsigned long) readADCControlReg:(bool)verbose;
- (void) writeADCSerialChannelSelect:(unsigned short)cardChan;
- (unsigned long) readADCSerialChannelSelect:(unsigned short)adc;

- (unsigned long) readADCOffset:(unsigned short)chan;
- (void) writeADCOffsets;
- (unsigned long) readADCGain:(unsigned short)chan;
- (void) writeADCGains;
- (unsigned long) readADCPhase:(unsigned short)chan;
- (void) writeADCPhase;

- (unsigned long) readADCCalibrationMailbox:(unsigned short)adc;
- (BOOL) checkADCCalibrationMailboxReady:(unsigned short)adc;
- (void) applyADCGainCalibration:(unsigned short)chan;


- (void) applyADCCalibration:(unsigned short)adc;
- (BOOL) checkADCSerialInterfaceBusy;
- (unsigned long) waitUntilADCSerialInterfaceNotBusy:(unsigned long)maxReads;
- (void) waitUntilADCSerialInterfaceNotBusy;
- (unsigned long) validateSerialADCCalibration;
- (unsigned long) validateSerialADCCalibrationOnChannel:(unsigned short)chan;







- (unsigned long) readDataTransferControlRegister:(short)group;
- (void) writeDataTransferControlRegister:(short)group withCommand:(short)command withAddress:(unsigned long)value;

- (unsigned long) readDataTransferStatusRegister:(short)group;

- (unsigned long) readAuroraProtocolStatus;
- (void) writeAuroraProtocolStatus:(unsigned long)value;
- (unsigned long) readAuroraDataStatus;
- (void) writeAuroraDataStatus:(unsigned long)value;

#pragma mark -- Key Addresses
- (void) reset;
- (void) armSampleLogic;
- (void) disarmSampleLogic;
- (void) forceTrigger;
- (void) enableSampleLogic;
- (void) setVeto;
- (void) clearVeto;
- (void) ADCSynchReset;
- (void) ADCFPGAReset;
- (void) pulseExternalTriggerOut;

- (unsigned long) getEventConfigOffsets:(int)group;
- (unsigned long) readEventConfigurationOfGroup:(short)group;
- (void) writeEventConfiguration;

- (unsigned long) readSampleStartAddressOfGroup:(short)group;
- (void) writeSampleStartAddressOfGroup:(short)group toValue:(unsigned long)value;

- (unsigned long) readSampleLength:(short) group;

- (unsigned long) readActualSampleAddress:(short)group;
- (void) writeSampleLengthOfGroup:(short)group toValue:(unsigned long)value;
- (void) writeSampleLengths;
- (unsigned long) readSamplePretriggerLengthOfGroup:(short)group;
- (void) writeSamplePretriggerLengthOfGroup:(short)group toValue:(unsigned long)value;
- (unsigned long) readRingbufferPretriggerDelayOnChannel:(short)chan;
//- (void) writeRingbufferPretriggerDelayOnChannel:(unsigned short)chan toValue:(unsigned long)value;
- (void) writeRingbufferPretriggerDelays;

- (unsigned long) readMaxNumOfEventsInGroup:(short)group;
- (void) writeMaxNumOfEventsInGroup:(short)group toValue:(unsigned int)maxValue;

- (unsigned long) getEndAddressThresholdRegOffsets:(int)group;
- (unsigned long) readEndAddressThresholdOfGroup:(short)group;
- (void) writeEndAddressThresholds;
- (void) writeEndAddressThresholdOfGroup:(int)aGroup;
- (void) writeEndAddressThresholdOfGroup:(short)group toValue:(unsigned long)value;


- (unsigned long) readLTThresholdOnChannel:(short)chan;
- (void) readLTThresholds:(BOOL)verbose;
- (unsigned long) readGTThresholdOnChannel:(short)chan;
- (void) readGTThresholds:(BOOL)verbose;
- (void) readThresholds:(BOOL)verbose;
- (void) writeThresholds;
- (void) writeLTThresholds;
- (void) writeGTThresholds;

- (unsigned long) getSamplingStatusAddressForGroup:(short)group;
- (unsigned long) readSamplingStatusForGroup:(short)group;
- (unsigned long) readActualSampleAddress:(short)group;








- (int) limitIntValue:(int)aValue min:(int)aMin max:(int)aMax;
- (void) initBoard;








- (unsigned long) readEndAddressThresholdOfGroup:(short)group;




//- (unsigned long) getSampleStartAddress:(short)group;

- (void) briefReport;
- (void) regDump;
//- (void) resetSamplingLogic;
//- (void) writePageRegister:(int) aPage;


//- (void) clearTimeStamp;
- (void) writeTapDelays;

- (unsigned long) getFIFOAddressOfGroup:(unsigned short)group;



#pragma mark other
- (void) executeCommandList:(ORCommandList*) aList;

//- (unsigned long) acqReg;
- (unsigned long) getADCTapDelayOffsets:(int)group;

//- (void) disarmAndArmBank:(int) bank;
//- (void) disarmAndArmNextBank;
- (NSString*) runSummary;

#pragma mark --- Data Taker
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

#pragma mark --- HW Wizard
- (int) numberOfChannels;
- (NSArray*) wizardParameters;
- (NSArray*) wizardSelections;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;

#pragma mark --- Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

#pragma mark --- AutoTesting
- (NSArray*) autoTests; 
@end

//CSRg
#pragma mark --- CSR
extern NSString* ORSIS3305ModelPulseModeChanged;
extern NSString* ORSIS3305ModelFirmwareVersionChanged;
extern NSString* ORSIS3305TemperatureChanged;
extern NSString* ORSIS3305WriteGainPhaseOffsetChanged;

extern NSString* ORSIS3305ModelBufferWrapEnabledChanged;
//extern NSString* ORSIS3305ModelCfdControlChanged;
extern NSString* ORSIS3305ModelShipTimeRecordAlsoChanged;
extern NSString* ORSIS3305ModelMcaUseEnergyCalculationChanged;
extern NSString* ORSIS3305ModelMcaEnergyOffsetChanged;
extern NSString* ORSIS3305ModelMcaEnergyMultiplierChanged;
extern NSString* ORSIS3305ModelMcaEnergyDividerChanged;
extern NSString* ORSIS3305ModelMcaModeChanged;
extern NSString* ORSIS3305ModelMcaPileupEnabledChanged;
extern NSString* ORSIS3305ModelMcaHistoSizeChanged;
extern NSString* ORSIS3305ModelMcaNofScansPresetChanged;
extern NSString* ORSIS3305ModelMcaAutoClearChanged;
extern NSString* ORSIS3305ModelMcaPrescaleFactorChanged;
extern NSString* ORSIS3305ModelMcaLNESetupChanged;
extern NSString* ORSIS3305ModelMcaNofHistoPresetChanged;
extern NSString* ORSIS3305ModelInternalExternalTriggersOredChanged;
extern NSString* ORSIS3305ModelLemoInEnabledMaskChanged;
//extern NSString* ORSIS3305ModelEnergyGateLengthChanged;
extern NSString* ORSIS3305ModelRunModeChanged;
extern NSString* ORSIS3305ModelEndAddressThresholdChanged;

//extern NSString* ORSIS3305ModelEnergySampleLengthChanged;
//extern NSString* ORSIS3305ModelEnergyGapTimeChanged;
extern NSString* ORSIS3305ModelTriggerGateLengthChanged;
extern NSString* ORSIS3305ModelPreTriggerDelayChanged;
extern NSString* ORSIS3305SampleStartIndexChanged;
extern NSString* ORSIS3305SampleLengthChanged;
extern NSString* ORSIS3305SampleStartAddressChanged;
extern NSString* ORSIS3305DacOffsetChanged;
extern NSString* ORSIS3305LemoInModeChanged;
extern NSString* ORSIS3305LemoOutModeChanged;

//extern NSString* ORSIS3305AcqRegEnableMaskChanged;

//extern NSString* ORSIS3305AcqRegChanged;
extern NSString* ORSIS3305EventConfigChanged;
extern NSString* ORSIS3305TDCMeasurementEnabledChanged;

extern NSString* ORSIS3305ChannelEnabledChanged;
extern NSString* ORSIS3305ThresholdModeChanged;
extern NSString* ORSIS3305TapDelayChanged;

extern NSString* ORSIS3305LTThresholdEnabledChanged;
extern NSString* ORSIS3305GTThresholdEnabledChanged;
extern NSString* ORSIS3305GTThresholdOnChanged;
extern NSString* ORSIS3305GTThresholdOffChanged;
extern NSString* ORSIS3305LTThresholdOnChanged;
extern NSString* ORSIS3305LTThresholdOffChanged;

extern NSString* ORSIS3305ClockSourceChanged;
extern NSString* ORSIS3305TriggerOutEnabledChanged;
extern NSString* ORSIS3305HighEnergySuppressChanged;
extern NSString* ORSIS3305ThresholdChanged;
extern NSString* ORSIS3305ThresholdArrayChanged;
//extern NSString* ORSIS3305HighThresholdChanged;
//extern NSString* ORSIS3305HighThresholdArrayChanged;
extern NSString* ORSIS3305GtChanged;

extern NSString* ORSIS3305SettingsLock;
extern NSString* ORSIS3305RateGroupChangedNotification;
extern NSString* ORSIS3305SampleDone;
extern NSString* ORSIS3305IDChanged;
extern NSString* ORSIS3305GateLengthChanged;
extern NSString* ORSIS3305PulseLengthChanged;
extern NSString* ORSIS3305InternalTriggerDelayChanged;
extern NSString* ORSIS3305TriggerDecimationChanged;
extern NSString* ORSIS3305EnergyDecimationChanged;
extern NSString* ORSIS3305LEDEnabledChanged;
extern NSString* ORSIS3305SetShipWaveformChanged;
//extern NSString* ORSIS3305SetShipSummedWaveformChanged;
extern NSString* ORSIS3305InputInvertedChanged;

// event config
extern NSString* ORSIS3305EventSavingModeChanged;
extern NSString* ORSIS3305ADCGateModeEnabledChanged;
extern NSString* ORSIS3305GlobalTriggerEnabledChanged;
extern NSString* ORSIS3305InternalTriggerEnabledChanged;
extern NSString* ORSIS3305StartEventSamplingWithExtTrigEnabledChanged;
extern NSString* ORSIS3305ClearTimestampWhenSamplingEnabledEnabledChanged;
extern NSString* ORSIS3305ClearTimestampDisabledChanged;
extern NSString* ORSIS3305GrayCodeEnabledChanged;
extern NSString* ORSIS3305DirectMemoryHeaderDisabledChanged;
extern NSString* ORSIS3305WaitPreTrigTimeBeforeDirectMemTrigChanged;


extern NSString* ORSIS3305ChannelModeChanged;
extern NSString* ORSIS3305BandwidthChanged;
extern NSString* ORSIS3305TestModeChanged;
extern NSString* ORSIS3305AdcOffsetChanged;
extern NSString* ORSIS3305AdcGainChanged;
extern NSString* ORSIS3305AdcPhaseChanged;


//extern NSString* ORSIS3305ControlLemoTriggerOut;
//extern NSString* ORSIS3305LemoOutSelectTriggerChanged;
//extern NSString* ORSIS3305LemoOutSelectTriggerInChanged;
//extern NSString* ORSIS3305LemoOutSelectTriggerInPulseChanged;
//extern NSString* ORSIS3305LemoOutSelectTriggerInPulseWithSampleAndTDCChanged;
//extern NSString* ORSIS3305LemoOutSelectSampleLogicArmedChanged;
//extern NSString* ORSIS3305LemoOutSelectSampleLogicEnabledChanged;
//extern NSString* ORSIS3305LemoOutSelectKeyOutputPulseChanged;
//extern NSString* ORSIS3305LemoOutSelectControlLemoTriggerOutChanged;
//extern NSString* ORSIS3305LemoOutSelectExternalVetoChanged;
//extern NSString* ORSIS3305LemoOutSelectInternalKeyVetoChanged;
//extern NSString* ORSIS3305LemoOutSelectExternalVetoLengthChanged;
//extern NSString* ORSIS3305LemoOutSelectMemoryOverrunVetoChanged;

extern NSString* ORSIS3305LemoOutSelectTriggerChanged;
extern NSString* ORSIS3305LemoOutSelectTriggerInChanged;
extern NSString* ORSIS3305LemoOutSelectTriggerInPulseChanged;
extern NSString* ORSIS3305LemoOutSelectTriggerInPulseWithSampleAndTDCChanged;
extern NSString* ORSIS3305LemoOutSelectSampleLogicArmedChanged;
extern NSString* ORSIS3305LemoOutSelectSampleLogicEnabledChanged;
extern NSString* ORSIS3305LemoOutSelectKeyOutputPulseChanged;
extern NSString* ORSIS3305LemoOutSelectControlLemoTriggerOutChanged;
extern NSString* ORSIS3305LemoOutSelectExternalVetoChanged;
extern NSString* ORSIS3305LemoOutSelectInternalKeyVetoChanged;
extern NSString* ORSIS3305LemoOutSelectExternalVetoLengthChanged;
extern NSString* ORSIS3305LemoOutSelectMemoryOverrunVetoChanged;
extern NSString* ORSIS3305EnableLemoInputTriggerChanged;
extern NSString* ORSIS3305EnableLemoInputCountChanged;
extern NSString* ORSIS3305EnableLemoInputResetChanged;
extern NSString* ORSIS3305EnableLemoInputDirectVetoChanged;




extern NSString* ORSIS3305ExternalTriggerEnabledChanged;
extern NSString* ORSIS3305InternalGateEnabledChanged;
extern NSString* ORSIS3305ExternalGateEnabledChanged;
extern NSString* ORSIS3305McaStatusChanged;
extern NSString* ORSIS3305CardInited;



// control status
extern NSString* ORSIS3305LEDApplicationModeChanged;
//extern NSString* ORSIS3305EnableExternalLEMODirectVetoInChanged;
//extern NSString* ORSIS3305EnableExternalLEMOResetInChanged;
//extern NSString* ORSIS3305EnableExternalLEMOCountIn;
extern NSString* ORSIS3305InvertExternalLEMODirectVetoIn;
//extern NSString* ORSIS3305EnableExternalLEMOTriggerIn;
extern NSString* ORSIS3305EnableExternalLEMOVetoDelayLengthLogic;
extern NSString* ORSIS3305EdgeSensitiveExternalVetoDelayLengthLogic;
extern NSString* ORSIS3305InvertExternalVetoInDelayLengthLogic;
extern NSString* ORSIS3305GateModeExternalVetoInDelayLengthLogic;
extern NSString* ORSIS3305EnableMemoryOverrunVeto;
extern NSString* ORSIS3305EControlLEMOTriggerOut;

extern NSString* ORSIS3305ModelRegisterIndexChanged;
extern NSString* ORSIS3305ModelRegisterWriteValueChanged;


