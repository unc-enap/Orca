//-------------------------------------------------------------------------
//  ORSIS3316Model.h
//  Orca
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2015 CENPA. University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolinaponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORVmeIOCard.h"
#import "ORDataTaker.h"
#import "ORHWWizard.h"
#import "SBC_Config.h"
#import "AutoTesting.h"

@class ORRateGroup;
@class ORAlarm;

#define kNumSIS3316Channels			16
#define kNumSIS3316Groups			4
#define kNumSIS3316ChansPerGroup	4

enum {
    kControlStatusReg,
    kModuleIDReg,
    kInterruptConfigReg ,
    kInterruptControlReg,
    kInterfacArbCntrStatusReg,
    kCBLTSetupReg,
    kInternalTestReg,
    kHWVersionReg,

    kTemperatureReg,
    k1WireEEPROMcontrolReg,
    kSerialNumberReg,
    kDataTransferSpdSettingReg,
    
    kAdcFPGAsBootControllerReg,
    kSpiFlashControlStatusReg,
    kSpiFlashData,
    kExternalVetoGateDelayReg,
    
    kAdcClockI2CReg,
    kMgt1ClockI2CReg,
    kMgt2ClockI2CReg,
    kDDR3ClockI2CReg,
    
    kAdcSampleClockDistReg,
    kExtNIMClockMulSpiReg,
    kFPBusControlReg,
    kNimInControlReg,
    
    kAcqControlStatusReg,
    kTrigCoinLUTControlReg,
    kTrigCoinLUTAddReg,
    kTrigCoinLUTDataReg,
    
    kLemoOutCOSelectReg,
    kLemoOutTOSelectReg,
    kLemoOutUOSelectReg,
    kIntTrigFeedBackSelReg,
    
    kAdcCh1_Ch4DataCntrReg,
    kAdcCh5_Ch8DataCntrReg,
    kAdcCh9_Ch12DataCntrReg,
    kAdcCh13_Ch16DataCntrReg,
    
    kAdcCh1_Ch4DataStatusReg,
    kAdcCh5_Ch8DataStatusReg,
    kAdcCh9_Ch12DataStatusReg,
    kAdcCh13_Ch16DataStatusReg,
    
    kAdcDataLinkStatusReg,
    kAdcSpiBusyStatusReg,
    kPrescalerOutDivReg,
    kPrescalerOutLenReg,
    
    kChan1TrigCounterReg,
    kChan2TrigCounterReg,
    kChan3TrigCounterReg,
    kChan4TrigCounterReg,
    
    kChan5TrigCounterReg,
    kChan6TrigCounterReg,
    kChan7TrigCounterReg,
    kChan8TrigCounterReg,
    
    kChan9TrigCounterReg,
    kChan10TrigCounterReg,
    kChan11TrigCounterReg,
    kChan12TrigCounterReg,
    
    kChan13TrigCounterReg,
    kChan14TrigCounterReg,
    kChan15TrigCounterReg,
    kChan16TrigCounterReg,
    
    kKeyResetReg,
    kKeyUserFuncReg,
    
    kKeyArmSampleLogicReg,
    kKeyDisarmSampleLogicReg,
    kKeyTriggerReg,
    kKeyTimeStampClrReg,
    
    kKeyDisarmXArmBank1Reg,
    kKeyDisarmXArmBank2Reg,
    kKeyEnableBankSwapNimReg,
    kKeyDisablePrescalerLogReg,
    
    kKeyPPSLatchBitClrReg,
    kKeyResetAdcLogicReg,
    kKeyAdcClockPllResetReg,
    
    kNumberSingleRegs //must be last
};

enum {
    
    kAdcInputTapDelayReg,
    kAdcGainTermCntrlReg,
    kAdcOffsetDacCntrlReg,
    kAdcSpiControlReg,
    
    kEventConfigReg,
    kChanHeaderIdReg,
    kEndAddressThresholdReg,
    kActTriggerGateWindowLenReg,
    
    kRawDataBufferConfigReg,
    kPileupConfigReg,
    kPreTriggerDelayReg,
    kAveConfigReg,
    
    kDataFormatConfigReg,
    kMawBufferConfigReg,
    kInternalTrigDelayConfigReg,
    kInternalGateLenConfigReg,
    
    kFirTrigSetupCh1Reg,
    kTrigThresholdCh1Reg,
    kHiEnergyTrigThresCh1Reg,
        
    kFirTrigSetupSumCh1Ch4Reg,
    kTrigThreholdSumCh1Ch4Reg,
    kHiETrigThresSumCh1Ch4Reg,
    
    kTrigStatCounterModeCh1Ch4Reg,
    kPeakChargeConfigReg,
    kExtRawDataBufConfigReg,
    kExtEventConfigCh1Ch4Reg,
    
    kAccGate1ConfigReg,
    kAccGate2ConfigReg,
    kAccGate3ConfigReg,
    kAccGate4ConfigReg,
    kAccGate5ConfigReg,
    kAccGate6ConfigReg,
    kAccGate7ConfigReg,
    kAccGate8ConfigReg,

    kFirEnergySetupCh1Reg,
    kFirEnergySetupCh2Reg,
    kFirEnergySetupCh4Reg,
    kFirEnergySetupCh3Reg,
    
    kGenHistogramConfigCh1Reg,
    kGenHistogramConfigCh2Reg,
    kGenHistogramConfigCh3Reg,
    kGenHistogramConfigCh4Reg,
    
    kMAWStartConfigCh1Reg,
    kMAWStartConfigCh2Reg,
    kMAWStartConfigCh3Reg,
    kMAWStartConfigCh4Reg,
    
    kAdcVersionReg,
    kAdcStatusReg,
    kAdcOffsetReadbackReg,
    kAdcSpiReadbackReg,
    
    kActualSampleCh1Reg,
    kActualSampleCh2Reg,
    kActualSampleCh3Reg,
    kActualSampleCh4Reg,
    
    kPreviousBankSampleCh1Reg,
    kPreviousBankSampleCh2Reg,
    kPreviousBankSampleCh3Reg,
    kPreviousBankSampleCh4Reg,
    
    kPPSTimeStampHiReg,
    kPPSTimeStampLoReg,
    kTestReadback01018Reg,
    kTestReadback0101CReg,
    
    kADCGroupRegisters //must be last
};

@interface ORSIS3316Model : ORVmeIOCard <ORDataTaker,ORHWWizard,AutoTesting>
{
  @private
    uint32_t   dataId;
    uint32_t   histoId;
    uint32_t   statId;
    int32_t            enabledMask;
    int32_t            formatMask;
    int32_t            histogramsEnabledMask;
    int32_t			pileupEnabledMask;
    int32_t            acquisitionControlMask;
    int32_t            nimControlStatusMask;
    int32_t            clrHistogramsWithTSMask;
    int32_t            writeHitsToEventMemoryMask;
    int32_t			heSuppressTriggerMask;
    uint32_t   cfdControlBits[kNumSIS3316Channels];
    uint32_t   threshold[kNumSIS3316Channels];
    uint32_t   riseTime[kNumSIS3316Channels];
    uint32_t   gapTime[kNumSIS3316Channels];
    uint32_t   tauFactor[kNumSIS3316Channels];
    uint32_t   extraFilterBits[kNumSIS3316Channels];
    uint32_t   tauTableBits[kNumSIS3316Channels];
    uint32_t   heTrigThreshold[kNumSIS3316Channels];
    uint32_t   endAddress[kNumSIS3316Groups];
    unsigned short  intTrigOutPulseBit[kNumSIS3316Channels];
    unsigned short  triggerDelay[kNumSIS3316Channels];
    unsigned short  dacOffsets[kNumSIS3316Groups];
    int32_t            trigBothEdgesMask;
    int32_t            intHeTrigOutPulseMask;
//    unsigned short  hsDiv;
//    unsigned short  n1Div;
    
    
    uint32_t   eventConfigMask;
    BOOL            extendedEventConfigBit;
    uint32_t   endAddressSuppressionMask;
    unsigned short  activeTrigGateWindowLen[kNumSIS3316Groups];
    unsigned short  preTriggerDelay[kNumSIS3316Groups];
    
    uint32_t   rawDataBufferLen;
    uint32_t   rawDataBufferStart;
    unsigned short  energyDivider[kNumSIS3316Channels];
    unsigned short  energyOffset[kNumSIS3316Channels];

    unsigned short  accGate1Len[kNumSIS3316Groups];
    unsigned short  accGate1Start[kNumSIS3316Groups];
    unsigned short  accGate2Len[kNumSIS3316Groups];
    unsigned short  accGate2Start[kNumSIS3316Groups];
    unsigned short  accGate3Len[kNumSIS3316Groups];
    unsigned short  accGate3Start[kNumSIS3316Groups];
    unsigned short  accGate4Len[kNumSIS3316Groups];
    unsigned short  accGate4Start[kNumSIS3316Groups];
    unsigned short  accGate5Len[kNumSIS3316Groups];
    unsigned short  accGate5Start[kNumSIS3316Groups];
    unsigned short  accGate6Len[kNumSIS3316Groups];
    unsigned short  accGate6Start[kNumSIS3316Groups];
    unsigned short  accGate7Len[kNumSIS3316Groups];
    unsigned short  accGate7Start[kNumSIS3316Groups];
    unsigned short  accGate8Len[kNumSIS3316Groups];
    unsigned short  accGate8Start[kNumSIS3316Groups];
    
    BOOL            enableSum[kNumSIS3316Groups];
    uint32_t   thresholdSum[kNumSIS3316Groups];
    uint32_t   heTrigThresholdSum[kNumSIS3316Groups];
    uint32_t   riseTimeSum[kNumSIS3316Groups];
    uint32_t   gapTimeSum[kNumSIS3316Groups];
    uint32_t   cfdControlBitsSum[kNumSIS3316Groups];
    uint32_t   pileUpWindowLength;
    uint32_t   rePileUpWindowLength;

    int             currentBank;
    int             previousBank;
	BOOL			isRunning;
 	
	unsigned short	moduleID;
    uint32_t   clockSource;
    unsigned short  gain;
    unsigned short  termination;
    int             sharing; //clock sharing
    
	//Acquisition control reg
	BOOL bankSwitchMode;
    BOOL autoStart;
    BOOL multiEventMode;    //this is all with the commented out code
	BOOL lemoStartStop;
    BOOL p2StartStop;
    BOOL gateMode;
    BOOL multiplexerMode;

	//clocks and delays (Acquisition control reg)
	
	ORRateGroup*	waveFormRateGroup;
	uint32_t 	waveFormCount[kNumSIS3316Channels];

	uint32_t   location; //cach to speed takedata
	id              theController;       //cach to speed takedata
    unsigned short  waitingOnChannelMask;
    unsigned short  groupDataTransferedMask;
    BOOL            transferDone;
    NSString*       revision;
    unsigned short  majorRev;
    unsigned short  minorRev;
    unsigned short  hwVersion;
    float           temperature;
    unsigned short  mHzType;
    unsigned short  serialNumber;
    uint32_t   lemoCoMask;
    uint32_t   lemoUoMask;
    uint32_t   lemoToMask;
    uint32_t   internalGateLen[kNumSIS3316Groups];       //6.24
    uint32_t   internalCoinGateLen[kNumSIS3316Groups];   //6.24
    uint32_t   mawBufferLength[kNumSIS3316Channels];
    uint32_t   mawPretrigDelay[kNumSIS3316Channels];
    unsigned char   freqSI570_calibrated_value_125MHz[6]; // new 20.11.2013
    unsigned char   freqPreset62_5MHz[6];
    unsigned char   freqPreset125MHz[6];
    unsigned char   freqPreset250MHz[6];
    BOOL            adc125MHzFlag;
    BOOL            firstTime;
    BOOL            clocksProgrammed;
    
    //data buffer if Mac is taking data
    uint32_t*  dataRecord[kNumSIS3316Channels];
    uint32_t*  histoRecord[kNumSIS3316Channels];
    ORTimer*        timer;;

}

- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark ***Accessors
- (void) setDefaults;
- (unsigned short) moduleID;
- (unsigned short) mHzType;
- (unsigned short) hwVersion;
- (float) temperature;
- (unsigned short) gain;
- (void) setGain:(unsigned short)aGain;
- (unsigned short) termination;
- (void) setTermination:(unsigned short)aTermination;

- (void) setSharing:(int)aValue;
- (int) sharing;
//- (unsigned short) hsDiv;
//- (void) setHsDiv:(unsigned short)aValue;
//- (unsigned short) n1Div;
//- (void) setN1Div:(unsigned short)aValue;

- (NSString*) revision;
- (void) setRevision:(NSString*)aString;
- (unsigned short) majorRevision;
- (void) readFirmwareVersion:(BOOL)verbose;
- (void) dumpFPGAStatus;
- (void) dumpFPGAStatus1;
- (void) dumpFPGAStatus2;

- (uint32_t) eventConfigMask;
- (void) setEventConfigMask:(uint32_t)aMask;
- (void) setEventConfigBit:(unsigned short)bit withValue:(BOOL)aValue;

- (BOOL) extendedEventConfigBit;
- (void) setExtendedEventConfigBit:(BOOL)aValue;

- (uint32_t) endAddressSuppressionMask;
- (void) setEndAddressSuppressionMask:(uint32_t)aMask;
- (void) setEndAddressSuppressionBit:(unsigned short)aGroup withValue:(BOOL)aValue;

- (int32_t) enabledMask;
- (void) setEnabledMask:(uint32_t)aMask;
- (BOOL) enabled:(unsigned short)chan;
- (void) setEnabledBit:(unsigned short)chan withValue:(BOOL)aValue;

- (int32_t) formatMask;
- (BOOL) formatBit:(unsigned short)bit;
- (void) setFormatMask:(uint32_t)aMask;
- (void) setFormatBit:(unsigned short)bit withValue:(BOOL)aValue;
- (short) headerLen;


///////
- (int32_t) acquisitionControlMask;
- (void) setAcquisitionControlMask:(uint32_t)aMask;
//////
- (int32_t) nimControlStatusMask;
- (void) setNIMControlStatusMask:(uint32_t)aMask;
- (void) setNIMControlStatusBit:(uint32_t)aChan withValue:(BOOL)aValue;
//////
- (int32_t) histogramsEnabledMask;
- (void) setHistogramsEnabledMask:(uint32_t)aMask;
- (BOOL) histogramsEnabled:(unsigned short)chan;
- (void) setHistogramsEnabled:(unsigned short)chan withValue:(BOOL)aValue;

- (int32_t) pileupEnabledMask;
- (void) setPileupEnabledMask:(uint32_t)aMask;
- (BOOL) pileupEnabled:(unsigned short)chan;
- (void) setPileupEnabled:(unsigned short)chan withValue:(BOOL)aValue;

- (int32_t) clrHistogramsWithTSMask;
- (void) setClrHistogramsWithTSMask:(uint32_t)aMask;
- (BOOL) clrHistogramsWithTS:(unsigned short)chan;
- (void) setClrHistogramsWithTS:(unsigned short)chan withValue:(BOOL)aValue;

- (int32_t) writeHitsToEventMemoryMask;
- (void) setWriteHitsToEventMemoryMask:(uint32_t)aMask;
- (BOOL) writeHitsToEventMemory:(unsigned short)chan;
- (void) setWriteHitsToEventMemory:(unsigned short)chan withValue:(BOOL)aValue;
///////
- (void) setTriggerDelay:(unsigned short)aChan withValue: (unsigned short)aValue;
- (unsigned short) triggerDelay: (unsigned short)aChan;

- (int32_t) heSuppressTriggerMask;
- (void) setHeSuppressTriggerMask:(uint32_t)aMask;
- (BOOL) heSuppressTriggerBit:(unsigned short)chan;
- (void) setHeSuppressTriggerBit:(unsigned short)chan withValue:(BOOL)aValue;

- (void) setEndAddress:(unsigned short)aGroup withValue: (uint32_t)aValue;
- (uint32_t) endAddress: (unsigned short)aGroup;

- (void) setThreshold:(unsigned short)chan withValue:(int32_t)aValue;
- (int32_t) threshold:(unsigned short)chan;

- (unsigned short) cfdControlBits:(unsigned short)aChan;
- (void) setCfdControlBits:(unsigned short)aChan withValue:(unsigned short)aValue;

- (uint32_t)   pileUpWindowLength;
- (void) setPileUpWindow:(uint32_t)aValue;
- (uint32_t)   rePileUpWindowLength;
- (void) setRePileUpWindow:(uint32_t)aValue;
- (void) writePileUpRegisters;


- (BOOL) enableSum:(unsigned short)aGroup;
- (void) setEnableSum:(unsigned short)aGroup withValue:(BOOL)aValue;

- (uint32_t) riseTimeSum:(unsigned short)aGroup;
- (void)          setRiseTimeSum:(unsigned short)aGroup withValue:(unsigned short)aValue;

- (uint32_t) gapTimeSum:(unsigned short)aGroup;
- (void)          setGapTimeSum:(unsigned short)aGroup withValue:(unsigned short)aValue;

- (void) setThresholdSum:(unsigned short)aGroup withValue: (uint32_t)aValue;
- (uint32_t) thresholdSum: (unsigned short)aGroup;

- (unsigned short) dacOffset:(unsigned short)aGroup;
- (void) setDacOffset:(unsigned short)aGroup withValue:(int)aValue;

- (unsigned short) cfdControlBitsSum:(unsigned short)aChan;
- (void) setCfdControlBitsSum:(unsigned short)aChan withValue:(unsigned short)aValue;

- (int32_t)clockSource;
- (void) setClockSource:(int32_t)aValue;

- (int32_t)extraFilterBits:(unsigned short)aChan;
- (void) setExtraFilterBits:(unsigned short)aChan withValue:(int32_t)aValue;

- (int32_t)tauTableBits:(unsigned short)aChan;
- (void) setTauTableBits:(unsigned short)aChan withValue:(int32_t)aValue;

- (unsigned short) energyDivider:(unsigned short)aChan;
- (void) setEnergyDivider:(unsigned short)aChan withValue:(unsigned short)aValue;

- (unsigned short) energyOffset:(unsigned short)aChan;
- (void) setEnergyOffset:(unsigned short)aChan withValue:(unsigned short)aValue;

- (void) setTauFactor:(unsigned short)chan withValue:(unsigned short)aValue;
- (unsigned short) tauFactor:(unsigned short)chan;

- (void) setGapTime:(unsigned short)chan withValue:(unsigned short)aValue;
- (unsigned short) gapTime:(unsigned short)chan;

- (void) setRiseTime:(unsigned short)chan withValue:(unsigned short)aValue;
- (unsigned short) riseTime:(unsigned short)chan;

- (void) setHeTrigThreshold:(unsigned short)chan withValue:(uint32_t)aValue;
- (uint32_t) heTrigThresholdSum:(unsigned short)aGroup;

- (void) setHeTrigThresholdSum:(unsigned short)aGroup withValue:(uint32_t)aValue;
- (uint32_t) heTrigThreshold:(unsigned short)chan;

- (int32_t) trigBothEdgesMask;
- (void) setTrigBothEdgesMask:(uint32_t)aMask;
- (BOOL) trigBothEdgesBit:(unsigned short)chan;
- (void) setTrigBothEdgesBit:(unsigned short)chan withValue:(BOOL)aValue;

- (int32_t) intHeTrigOutPulseMask;
- (void) setIntHeTrigOutPulseMask:(uint32_t)aMask;
- (BOOL) intHeTrigOutPulseBit:(unsigned short)chan;
- (void) setIntHeTrigOutPulseBit:(unsigned short)chan withValue:(BOOL)aValue;

- (unsigned short) intTrigOutPulseBit:(unsigned short)aChan;
- (void)           setIntTrigOutPulseBit:(unsigned short)aChan withValue:(unsigned short)aValue;

- (unsigned short) activeTrigGateWindowLen:(unsigned short)group;
- (void)           setActiveTrigGateWindowLen:(unsigned short)group withValue:(uint32_t)aValue;

- (unsigned short)  preTriggerDelay:(unsigned short)group;
- (void)            setPreTriggerDelay:(unsigned short)group withValue:(unsigned short)aValue;

- (uint32_t)  rawDataBufferLen;
- (void)            setRawDataBufferLen:(uint32_t)aValue;

- (uint32_t)  rawDataBufferStart;
- (void)           setRawDataBufferStart:(uint32_t)aValue;

- (unsigned short)  accGate1Start:(unsigned short)aGroup;
- (void)            setAccGate1Start:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate1Len:(unsigned short)aGroup;
- (void)            setAccGate1Len:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate2Start:(unsigned short)aGroup;
- (void)            setAccGate2Start:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate2Len:(unsigned short)aGroup;
- (void)            setAccGate2Len:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate3Start:(unsigned short)aGroup;
- (void)            setAccGate3Start:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate3Len:(unsigned short)aGroup;
- (void)            setAccGate3Len:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate4Start:(unsigned short)aGroup;
- (void)            setAccGate4Start:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate4Len:(unsigned short)aGroup;
- (void)            setAccGate4Len:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate5Start:(unsigned short)aGroup;
- (void)            setAccGate5Start:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate5Len:(unsigned short)aGroup;
- (void)            setAccGate5Len:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate6Start:(unsigned short)aGroup;
- (void)            setAccGate6Start:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate6Len:(unsigned short)aGroup;
- (void)            setAccGate6Len:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate7Start:(unsigned short)aGroup;
- (void)            setAccGate7Start:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate7Len:(unsigned short)aGroup;
- (void)            setAccGate7Len:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate8Start:(unsigned short)aGroup;
- (void)            setAccGate8Start:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate8Len:(unsigned short)aGroup;
- (void)            setAccGate8Len:(unsigned short)group withValue:(unsigned short)aValue;


- (uint32_t)   lemoCoMask;
- (void)            setLemoCoMask:(uint32_t)aMask;
- (uint32_t)   lemoUoMask;
- (void)            setLemoUoMask:(uint32_t)aMask;
- (uint32_t)   lemoToMask;
- (void)             setLemoToMask:(uint32_t)aMask;

- (uint32_t) internalGateLen:(unsigned short)aGroup;
- (void) setInternalGateLen:(unsigned short)aGroup withValue:(uint32_t)aValue;

- (uint32_t) internalCoinGateLen:(unsigned short)aGroup;
- (void) setInternalCoinGateLen:(unsigned short)aGroup withValue:(uint32_t)aValue;

- (void) initParams;

- (ORRateGroup*)    waveFormRateGroup;
- (void)			setWaveFormRateGroup:(ORRateGroup*)newRateGroup;
- (id)              rateObject:(int)channel;
- (void)            setRateIntegrationTime:(double)newIntegrationTime;
- (BOOL)			bumpRateFromDecodeStage:(unsigned short)channel;

- (BOOL) checkRegList;
- (unsigned short) serialNumber;

#pragma mark •••Hardware Access
- (void) writeLong:(uint32_t)aValue toAddress:(uint32_t)anAddress;
- (uint32_t) readLongFromAddress:(uint32_t)anAddress;

//Comments denote section of the manual 
- (uint32_t) singleRegister:           (uint32_t)aRegisterIndex;
- (uint32_t) groupRegister:            (uint32_t)aRegisterIndex  group:(int)aGroup;
- (uint32_t) channelRegister:          (uint32_t)aRegisterIndex channel:(int)aChannel;
- (uint32_t) channelRegisterVersionTwo:(uint32_t)aRegisterIndex channel:(int)aChannel;
- (uint32_t) accumulatorRegisters:     (uint32_t)aRegisterIndex channel:(int)aChannel;
- (uint32_t)readControlStatusReg;          //6.1
- (void) writeControlStatusReg:             (uint32_t)aValue;
- (void) setLed:(BOOL)state;                    //6.1'
- (void) readModuleID:(BOOL)verbose;            //6.2
- (void) readHWVersion:(BOOL)verbose;           //6.7
- (unsigned short) hwVersion;                   //6.7'
- (void) readTemperature:(BOOL)verbose;         //6.8
- (void) readSerialNumber:(BOOL)verbose;        //6.10
- (void) writeClockSource;                      //6.17
- (void) readFpBusControl:(BOOL)verbose;        //6.19
- (void) readClockSource:(BOOL)verbose;
- (void) writeNIMControlStatus;                 //6.20
- (void) readNIMControlStatus:(BOOL)verbose;
- (void) writeAcquisitionRegister;              //6.21
- (void) dumpAdcOffsetReadback;                 //6.9
- (uint32_t) readAcquisitionRegister:(BOOL)verbose;
- (BOOL) sampleLogicIsBusy;                     //6.21      //pg 119 and on
- (void) writeEventConfig;                      //6.12 (section 2)
- (void) dumpEventConfiguration;
- (void) readEventConfig:(BOOL)verbose;
- (void) writeExtendedEventConfig;              //6.13 (section 2)
- (void) dumpExtendedEventConfiguration;
- (void) dumpChannelHeaderID;                   //6.14
- (void) dumpEndAddressThreshold;               //6.15
- (void) dumpActiveTrigGateWindowLen;           //6.16
- (void) dumpRawDataBufferConfig;               //6.17
- (void) dumpPileupConfig;                      //6.18
- (void) dumpPreTriggerDelay;                   //6.19
- (void) dumpAveConfig;                         //6.20
- (void) dumpDataFormatConfig;                  //6.21
- (void) dumpMawBufferConfig;               //6.22
- (uint32_t) mawBufferLength:(unsigned short)aGroup;
- (void) setMawBufferLength:(unsigned short)aGroup withValue:(uint32_t)aValue;
- (uint32_t) mawPretrigDelay:(unsigned short)aGroup;
- (void) setMawPretrigDelay:(unsigned short)aGroup withValue:(uint32_t)aValue;
- (void) readTimeStamp:(BOOL) verbose;

- (void) dumpInternalTriggerDelayConfig;        //6.23
- (void) dumpInternalGateLengthConfig;          //6.24
- (void) dumpFirTriggerSetup;                   //6.25
- (void) dumpSumFirTriggerSetup;                //6.25-1
- (void) dumpTriggerThreshold;                  //6.26
- (void) dumpSumTriggerThreshold;               //6.26-1
- (void) dumpHeTriggerThreshold;                //6.27
- (void) dumpHeSumTriggerThreshold;             //6.27-1
- (void) dumpStatisticCounterMode;              //6.28
- (void) dumpPeakChargeConfig;                  //6.29
- (void) dumpExtededRawDataBufferConfig;        //6.30
- (void) dumpAccumulatorGates;                  //6.31
- (void) writeTapDelayRegister;

- (void) readExtendedEventConfig:(BOOL)verbose;
- (void) writeEndAddress;                       //6.15 (section 2)
- (void) readEndAddress:(BOOL)verbose;
- (void) writeActiveTrigGateWindowLen;          //6.16 (section 2)
- (void) readActiveTrigGateWindowLen:(BOOL)verbose;
- (void) writeRawDataBufferConfig;              //6.17 (section 2)
- (void) writePreTriggerDelays;                 //6.19 (section 2)
- (void) readPreTriggerDelays:(BOOL)verbose;
- (void) writeDataFormat;                       //6.21 (section 2)
- (uint32_t) readTrigCoinLUControl:(BOOL)verbose; //6.22
- (uint32_t) readTrigCoinLUAddress:(BOOL)verbose; //6.23
- (uint32_t) readTrigCoinLUData:(BOOL)verbose;  //6.24
- (uint32_t) readLemoOutCOSelect:(BOOL)verbose;  //6.25
- (uint32_t) readLemoOutTOSelect:(BOOL)verbose; //6.26
- (uint32_t) readLemoOutUOSelect:(BOOL)verbose; //6.27
- (uint32_t) readIntTrigFeedBackSelect:(BOOL)verbose;//6.28
- (uint32_t) readVmeFpgaAdcDataLinkStatus:(BOOL)verbose;//6.1
- (uint32_t) readPrescalerOutPulseDivider:(BOOL)verbose;//6.3
- (uint32_t) readPrescalerOutPulseLength:(BOOL)verbose; //6.4
- (void) dumpGainTerminationControl;//6.7
- (void) dumpInternalTriggerCounters;//6.5
- (void) dumpFPGADataTransferStatus; //6:30
- (void) writeTriggerDelay;                     //6.23 (section 2)
- (void) readTriggerDelay:(BOOL)verbose;
- (void) writeFirTriggerSetup;                  //6.25 (section 2)
- (void) initBoard;
- (void) writeThresholds;                       //6.26 (section 2)
- (void) writeThresholdSum;
- (void) writeHeTrigThresholds;                 //6.27 (section 2)
- (void) writeHeTrigThresholdSum;
- (void) readHeTrigThresholds:(BOOL)verbose;    //6.27 (section 2)
- (void) readHeTrigThresholdSum:(BOOL)verbose;
- (void) writeAccumulatorGates;                 //6.31 (section 2)
- (void) writeDacRegisters;
- (void) clearPPSLatchBit;                      //6.39

- (uint32_t) eventNumberGroup:(int)group bank:(int) bank;
- (uint32_t) eventTriggerGroup:(int)group bank:(int) bank; 
- (uint32_t) readTriggerTime:(int)bank index:(int)index;


- (void) clearTimeStamp;
- (void) trigger;
- (void) armSampleLogic;
- (void) disarmSampleLogic;
- (void) switchBanks;
- (void) armBank1;
- (void) armBank2;
- (int) currentBank;
- (void) resetADCClockDCM;
//- (int) setFrequency:(int) osc values:(unsigned char*)values;
//- (void) si570ReadDivider:(int) osc data:(unsigned char*)data;

//some test functions
- (uint32_t) readTriggerEventBank:(int)bank index:(int)index;
- (void) readAddressCounts;

- (void) poll_on_adc_dac_offset_busy;
- (void) write_channel_header_IDs;
- (int) set_frequency:(int)osc  values:(unsigned char*)values;

- (void) writeGainTerminationValues;
- (void) dumpChan0;
#pragma mark •••Data Taker
- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (void) setDataIds:(id)assigner;
- (uint32_t) histoId;
- (void) setHistoId: (uint32_t) DataId;
- (uint32_t) statId;
- (void) setStatId: (uint32_t) DataId;
- (void) syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*) dataRecordDescription;
- (void) reset;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
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

#pragma mark •••Reporting
- (void) settingsTable;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (void) setUpEmptyArray:(SEL)aSetter numItems:(int)n;
- (void) setUpArray:(SEL)aSetter intValue:(int)aValue numItems:(int)n;

#pragma mark •••AutoTesting
- (NSArray*) autoTests;

#pragma mark •••Clock Setup
- (void) setupSharing;
- (void) setupClock;

@end

extern NSString* ORSIS3316EnabledChanged;
extern NSString* ORSIS3316FormatMaskChanged;
extern NSString* ORSIS3316EventConfigChanged;
extern NSString* ORSIS3316ExtendedEventConfigChanged;
extern NSString* ORSIS3316AcquisitionControlChanged;
extern NSString* ORSIS3316NIMControlStatusChanged;
extern NSString* ORSIS3316HistogramsEnabledChanged;
extern NSString* ORSIS3316PileUpEnabledChanged;
extern NSString* ORSIS3316ClrHistogramWithTSChanged;
extern NSString* ORSIS3316WriteHitsIntoEventMemoryChanged;

extern NSString* ORSIS3316ThresholdChanged;
extern NSString* ORSIS3316ThresholdSumChanged;
extern NSString* ORSIS3316EndAddressSuppressionChanged;
extern NSString* ORSIS3316EndAddressChanged;
extern NSString* ORSIS3316TriggerDelayChanged;
extern NSString* ORSIS3316HeSuppressTrigModeChanged;
extern NSString* ORSIS3316CfdControlBitsChanged;
extern NSString* ORSIS3316ExtraFilterBitsChanged;
extern NSString* ORSIS3316TauTableBitsChanged;
extern NSString* ORSIS3316EnergyDividerChanged ;
extern NSString* ORSIS3316EnergyOffsetChanged;
extern NSString* ORSIS3316TauFactorChanged;
extern NSString* ORSIS3316GapTimeChanged;
extern NSString* ORSIS3316PeakingTimeChanged;
extern NSString* ORSIS3316HeTrigThresholdChanged;
extern NSString* ORSIS3316HeTrigThresholdSumChanged;
extern NSString* ORSIS3316TrigBothEdgesChanged;
extern NSString* ORSIS3316IntHeTrigOutPulseChanged;
extern NSString* ORSIS3316IntTrigOutPulseBitsChanged;
extern NSString* ORSIS3316ActiveTrigGateWindowLenChanged;
extern NSString* ORSIS3316PreTriggerDelayChanged;
extern NSString* ORSIS3316RawDataBufferLenChanged;
extern NSString* ORSIS3316RawDataBufferStartChanged;
extern NSString* ORSIS3316AccGate1LenChanged;
extern NSString* ORSIS3316AccGate1StartChanged;
extern NSString* ORSIS3316AccGate2LenChanged;
extern NSString* ORSIS3316AccGate2StartChanged;
extern NSString* ORSIS3316AccGate3LenChanged;
extern NSString* ORSIS3316AccGate3StartChanged;
extern NSString* ORSIS3316AccGate4LenChanged;
extern NSString* ORSIS3316AccGate4StartChanged;
extern NSString* ORSIS3316AccGate5LenChanged;
extern NSString* ORSIS3316AccGate5StartChanged;
extern NSString* ORSIS3316AccGate6LenChanged;
extern NSString* ORSIS3316AccGate6StartChanged;
extern NSString* ORSIS3316AccGate7LenChanged;
extern NSString* ORSIS3316AccGate7StartChanged;
extern NSString* ORSIS3316AccGate8LenChanged;
extern NSString* ORSIS3316AccGate8StartChanged;

extern NSString* ORSIS3316TemperatureChanged;

//CSR
extern NSString* ORSIS3316CSRRegChanged;
extern NSString* ORSIS3316AcqRegChanged;

extern NSString* ORSIS3316ClockSourceChanged;

extern NSString* ORSIS3316SettingsLock;
extern NSString* ORSIS3316RateGroupChangedNotification;
extern NSString* ORSIS3316SampleDone;
extern NSString* ORSIS3316IDChanged;
extern NSString* ORSIS3316HWVersionChanged;
extern NSString* ORSIS3316SerialNumberChanged;
extern NSString* ORSIS3316ModelGainChanged;
extern NSString* ORSIS3316ModelTerminationChanged;
extern NSString* ORSIS3316DacOffsetChanged;

extern NSString* ORSIS3316EnableSumChanged;
extern NSString* ORSIS3316RiseTimeSumChanged;
extern NSString* ORSIS3316GapTimeSumChanged;
extern NSString* ORSIS3316CfdControlBitsSumChanged;
extern NSString* ORSIS3316SharingChanged;

extern NSString* ORSIS3316LemoCoMaskChanged;
extern NSString* ORSIS3316LemoUoMaskChanged;
extern NSString* ORSIS3316LemoToMaskChanged;

extern NSString* ORSIS3316InternalGateLenChanged;
extern NSString* ORSIS3316InternalCoinGateLenChanged;
//extern NSString* ORSIS3316HsDivChanged;
//extern NSString* ORSIS3316N1DivChanged;
extern NSString* ORSIS3316MAWBuffLengthChanged;
extern NSString* ORSIS3316MAWPretrigLenChanged;

extern NSString* ORSIS3316PileUpWindowLengthChanged;
extern NSString* ORSIS3316RePileUpWindowLengthChanged;


