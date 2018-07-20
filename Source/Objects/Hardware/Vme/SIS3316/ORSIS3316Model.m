//-------------------------------------------------------------------------
//  ORSIS3316Model.m
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
//
#pragma mark ***Imported Files
#import "ORSIS3316Model.h"
#import "ORDataTypeAssigner.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORVmeCrateModel.h"
#import "ORRateGroup.h"
#import "ORTimer.h"
#import "VME_HW_Definitions.h"
#import "ORVmeTests.h"

NSString* ORSIS3316EnabledChanged                   = @"ORSIS3316EnabledChanged";
NSString* ORSIS3316FormatMaskChanged                = @"ORSIS3316FormatMaskChanged";
NSString* ORSIS3316AcquisitionControlChanged        = @"ORSIS3316AcquisitionControlChanged";
NSString* ORSIS3316NIMControlStatusChanged          = @"ORSIS3316NIMControlStatusChanged";
NSString* ORSIS3316HistogramsEnabledChanged         = @"ORSIS3316HistogramsEnabledChanged";

NSString* ORSIS3316PileUpEnabledChanged             = @"ORSIS3316PileUpEnabledChanged";
NSString* ORSIS3316ClrHistogramWithTSChanged        = @"ORSIS3316ClrHistogramWithTSChanged";
NSString* ORSIS3316WriteHitsIntoEventMemoryChanged  = @"ORSIS3316WriteHitsIntoEventMemoryChanged";

NSString* ORSIS3316ThresholdChanged                 = @"ORSIS3316ThresholdChanged";
NSString* ORSIS3316ThresholdSumChanged              = @"ORSIS3316ThresholdSumChanged";
NSString* ORSIS3316HeSuppressTrigModeChanged        = @"ORSIS3316HeSuppressTrigModeChanged";
NSString* ORSIS3316CfdControlBitsChanged            = @"ORSIS3316CfdControlBitsChanged";

NSString* ORSIS3316EventConfigChanged               = @"ORSIS3316EventConfigChanged";
NSString* ORSIS3316ExtendedEventConfigChanged       = @"ORSIS3316ExtendedEventConfigChanged";
NSString* ORSIS3316EndAddressSuppressionChanged     = @"ORSIS3316EndAddressSuppressionChanged";
NSString* ORSIS3316EndAddressChanged                = @"ORSIS3316EndAddressChanged";

NSString* ORSIS3316TriggerDelayChanged              = @"ORSIS3316TriggerDelayChanged";
NSString* ORSIS3316TriggerDelayTwoChanged           = @"ORSIS3316TriggerDelayTwoChanged";
NSString* ORSIS3316TriggerDelay3Changed             = @"ORSIS3316TriggerDelay3Changed";
NSString* ORSIS3316TriggerDelay4Changed             = @"ORSIS3316TriggerDelay4Changed";

NSString* ORSIS3316EnergyDividerChanged             = @"ORSIS3316EnergyDividerChanged";
NSString* ORSIS3316EnergyOffsetChanged              = @"ORSIS3316EnergyOffsetChanged";
NSString* ORSIS3316TauFactorChanged                 = @"ORSIS3316TauFactorChanged";
NSString* ORSIS3316ExtraFilterBitsChanged           = @"ORSIS3316ExtraFilterBitsChanged";
NSString* ORSIS3316TauTableBitsChanged              = @"ORSIS3316TauTableBitsChanged";
NSString* ORSIS3316PeakingTimeChanged               = @"ORSIS3316PeakingTimeChanged";
NSString* ORSIS3316GapTimeChanged                   = @"ORSIS3316GapTimeChanged";
NSString* ORSIS3316HeTrigThresholdChanged           = @"ORSIS3316HeTrigThresholdChanged";
NSString* ORSIS3316HeTrigThresholdSumChanged        = @"ORSIS3316HeTrigThresholdSumChanged";
NSString* ORSIS3316TrigBothEdgesChanged             = @"ORSIS3316TrigBothEdgesChanged";
NSString* ORSIS3316IntHeTrigOutPulseChanged         = @"ORSIS3316IntHeTrigOutPulseChanged";
NSString* ORSIS3316IntTrigOutPulseBitsChanged       = @"ORSIS3316IntTrigOutPulseBitsChanged";

NSString* ORSIS3316ActiveTrigGateWindowLenChanged   = @"ORSIS3316ActiveTrigGateWindowLenChanged";
NSString* ORSIS3316PreTriggerDelayChanged           = @"ORSIS3316PreTriggerDelayChanged";
NSString* ORSIS3316RawDataBufferLenChanged          = @"ORSIS3316RawDataBufferLenChanged";
NSString* ORSIS3316RawDataBufferStartChanged        = @"ORSIS3316RawDataBufferStartChanged";

NSString* ORSIS3316AccGate1LenChanged               = @"ORSIS3316AccGate1LenChanged";
NSString* ORSIS3316AccGate1StartChanged             = @"ORSIS3316AccGate1StartChanged";
NSString* ORSIS3316AccGate2LenChanged               = @"ORSIS3316AccGate2LenChanged";
NSString* ORSIS3316AccGate2StartChanged             = @"ORSIS3316AccGate2StartChanged";
NSString* ORSIS3316AccGate3LenChanged               = @"ORSIS3316AccGate3LenChanged";
NSString* ORSIS3316AccGate3StartChanged             = @"ORSIS3316AccGate3StartChanged";
NSString* ORSIS3316AccGate4LenChanged               = @"ORSIS3316AccGate4LenChanged";
NSString* ORSIS3316AccGate4StartChanged             = @"ORSIS3316AccGate4StartChanged";
NSString* ORSIS3316AccGate5LenChanged               = @"ORSIS3316AccGate5LenChanged";
NSString* ORSIS3316AccGate5StartChanged             = @"ORSIS3316AccGate5StartChanged";
NSString* ORSIS3316AccGate6LenChanged               = @"ORSIS3316AccGate6LenChanged";
NSString* ORSIS3316AccGate6StartChanged             = @"ORSIS3316AccGate6StartChanged";
NSString* ORSIS3316AccGate7LenChanged               = @"ORSIS3316AccGate7LenChanged";
NSString* ORSIS3316AccGate7StartChanged             = @"ORSIS3316AccGate7StartChanged";
NSString* ORSIS3316AccGate8LenChanged               = @"ORSIS3316AccGate8LenChanged";
NSString* ORSIS3316AccGate8StartChanged             = @"ORSIS3316AccGate8StartChanged";

NSString* ORSIS3316AcqRegChanged                    = @"ORSIS3316AcqRegChanged";

NSString* ORSIS3316ClockSourceChanged               = @"ORSIS3316ClockSourceChanged";

NSString* ORSIS3316RateGroupChangedNotification     = @"ORSIS3316RateGroupChangedNotification";
NSString* ORSIS3316SettingsLock                     = @"ORSIS3316SettingsLock";

NSString* ORSIS3316SampleDone                       = @"ORSIS3316SampleDone";
NSString* ORSIS3316SerialNumberChanged              = @"ORSIS3316SerialNumberChanged";
NSString* ORSIS3316IDChanged                        = @"ORSIS3316IDChanged";
NSString* ORSIS3316TemperatureChanged               = @"ORSIS3316TemperatureChanged";
NSString* ORSIS3316HWVersionChanged                 = @"ORSIS3316HWVersionChanged";
NSString* ORSIS3316ModelGainChanged                 = @"ORSIS3316ModelGainChanged";
NSString* ORSIS3316ModelTerminationChanged          = @"ORSIS3316ModelTerminationChanged";
NSString* ORSIS3316DacOffsetChanged                 = @"ORSIS3316DacOffsetChanged";

NSString* ORSIS3316EnableSumChanged                 = @"ORSIS3316EnableSumChanged";
NSString* ORSIS3316RiseTimeSumChanged               = @"ORSIS3316RiseTimeSumChanged";
NSString* ORSIS3316GapTimeSumChanged                = @"ORSIS3316GapTimeSumChanged";
NSString* ORSIS3316CfdControlBitsSumChanged         = @"ORSIS3316CfdControlBitsSumChanged";
NSString* ORSIS3316SharingChanged                   = @"ORSIS3316SharingChanged";

NSString* ORSIS3316LemoCoMaskChanged                = @"ORSIS3316LemoCoMaskChanged";
NSString* ORSIS3316LemoUoMaskChanged                = @"ORSIS3316LemoUoMaskChanged";
NSString* ORSIS3316LemoToMaskChanged                = @"ORSIS3316LemoToMaskChanged";

NSString* ORSIS3316InternalGateLenChanged           = @"ORSIS3316InternalGateLenChanged";
NSString* ORSIS3316InternalCoinGateLenChanged       = @"ORSIS3316InternalCoinGateLenChanged";
NSString* ORSIS3316MAWBuffLengthChanged             = @"ORSIS3316MAWBuffLengthChanged";
NSString* ORSIS3316MAWPretrigLenChanged             = @"ORSIS3316MAWPretrigLenChanged";

//NSString* ORSIS3316HsDivChanged                     = @"ORSIS3316HsDivChanged";
//NSString* ORSIS3316N1DivChanged                     = @"ORSIS3316N1DivChanged";

NSString* ORSIS3316PileUpWindowLengthChanged        = @"ORSIS3316PileUpWindowLengthChanged";
NSString* ORSIS3316RePileUpWindowLengthChanged      = @"ORSIS3316RePileUpWindowLengthChanged";

#pragma mark - Static Declerations
typedef struct {
    uint32_t  offset;
    NSString*      name;
    BOOL           canRead;
    BOOL           canWrite;
    BOOL           hasChannels;
    unsigned short enumId;
} ORSIS3316RegisterInformation;

//VME FPGA interface registers
static ORSIS3316RegisterInformation singleRegister[kNumberSingleRegs] = {
    {0x00000000,    @"Control/Status",                          YES,    YES,    NO,   kControlStatusReg},
    {0x00000004,    @"Module ID",                               YES,    NO,     NO,   kModuleIDReg},
    {0x00000008,    @"Interrupt Configuration",                 YES,    YES,    NO,   kInterruptConfigReg},
    {0x0000000C,    @"Interrupt Control",                       YES,    YES,    NO,   kInterruptControlReg},
    
    {0x00000010,    @"Interface Access",                        YES,    YES,    NO,   kInterfacArbCntrStatusReg},
    {0x00000014,    @"CBLT/Broadcast Setup",                    YES,    YES,    NO,   kCBLTSetupReg},
    {0x00000018,    @"Internal Test",                           YES,    YES,    NO,   kInternalTestReg},
    {0x0000001C,    @"Hardware Version",                        YES,    YES,    NO,   kHWVersionReg},

    {0x00000020,    @"Temperature",                             YES,    NO,     NO,   kTemperatureReg},
    {0x00000024,    @"Onewire EEPROM",                          YES,    YES,    NO,   k1WireEEPROMcontrolReg},
    {0x00000028,    @"Serial Number",                           YES,    NO,     NO,   kSerialNumberReg},
    {0x0000002C,    @"Internal Data Transfer Speed",            YES,    YES,    NO,   kDataTransferSpdSettingReg},
    
    {0x00000030,    @"ADC FPGAs BOOT Controller",               YES,    YES,    NO,   kAdcFPGAsBootControllerReg},
    {0x00000034,    @"SPI FLASH CONTROL/Status",                YES,    YES,    NO,   kSpiFlashControlStatusReg},
    {0x00000038,    @"SPI Flash Data",                          YES,    YES,    NO,   kSpiFlashData},
    {0x0000003C,    @"External Veto/Gate Delay",                YES,    YES,    NO,   kExternalVetoGateDelayReg},
    
    {0x00000040,    @"ADC Clock",                               YES,    YES,    NO,   kAdcClockI2CReg},
    {0x00000044,    @"MGT1 Clock",                              YES,    YES,    NO,   kMgt1ClockI2CReg},
    {0x00000048,    @"MGT2 CLock",                              YES,    YES,    NO,   kMgt2ClockI2CReg},
    {0x0000004C,    @"DDR3 Clock",                              YES,    YES,    NO,   kDDR3ClockI2CReg},
    
    {0x00000050,    @"ADC Sample CLock distribution control",   YES,    YES,    NO,   kAdcSampleClockDistReg},
    {0x00000054,    @"External NIM Clock Multiplier",           YES,    YES,    NO,   kExtNIMClockMulSpiReg},
    {0x00000058,    @"FP-Bus control ",                         YES,    YES,    NO,   kFPBusControlReg},
    {0x0000005C,    @"NIM-IN Control/status",                   YES,    YES,    NO,   kNimInControlReg},
    
    {0x00000060,    @"Acquisition control/status",              YES,    YES,    NO,   kAcqControlStatusReg},
    {0x00000064,    @"TCLT Control",                            YES,    YES,    NO,   kTrigCoinLUTControlReg},
    {0x00000068,    @"TCLT Address",                            YES,    YES,    NO,   kTrigCoinLUTAddReg},
    {0x0000006C,    @"TCLT Data",                               YES,    YES,    NO,   kTrigCoinLUTDataReg},
    
    {0x00000070,    @"LEMO Out CO",                             YES,    YES,    NO,   kLemoOutCOSelectReg},
    {0x00000074,    @"LMEO Out TO",                             YES,    YES,    NO,   kLemoOutTOSelectReg},
    {0x00000078,    @"LEMO Out UO",                             YES,    YES,    NO,   kLemoOutUOSelectReg},
    {0x0000007C,    @"Internal Trigger Feedback Select",        YES,    YES,    NO,   kIntTrigFeedBackSelReg},
    
    {0x00000080,    @"ADC ch1-ch4 Data Transfer Control",       YES,    YES,    YES,  kAdcCh1_Ch4DataCntrReg},
    {0x00000084,    @"ADC ch5-ch8 Data Transfer Control",       YES,    YES,    YES,  kAdcCh5_Ch8DataCntrReg},
    {0x00000088,    @"ADC ch9-ch12 Data Transfer Control",      YES,    YES,    YES,  kAdcCh9_Ch12DataCntrReg},
    {0x0000008C,    @"ADC ch13-ch16 Data Transfer Control",     YES,    YES,    YES,  kAdcCh13_Ch16DataCntrReg},
    
    {0x00000090,    @"ADC ch1-ch4 Data Transfer STatus",        YES,    NO,     YES,  kAdcCh1_Ch4DataStatusReg},
    {0x00000094,    @"ADC ch5-ch8 Data Transfer STatus",        YES,    NO,     YES,  kAdcCh5_Ch8DataStatusReg},
    {0x00000098,    @"ADC ch9-ch12 Data Transfer STatus",       YES,    NO,     YES,  kAdcCh9_Ch12DataStatusReg},
    {0x0000009C,    @"ADC ch13-ch16 Data Transfer STatus",      YES,    NO,     YES,  kAdcCh13_Ch16DataStatusReg},
    
    {0x000000A0,    @"ADC Data Link Status",                    YES,    YES,    NO,   kAdcDataLinkStatusReg},
    {0x000000A4,    @"ADC SPI Busy Status",                     YES,    YES,    NO,   kAdcSpiBusyStatusReg},
    {0x000000B8,    @"Prescaler output pulse divider",          YES,    YES,    NO,   kPrescalerOutDivReg},
    {0x000000BC,    @"Prescaler output pulse length",           YES,    YES,    NO,   kPrescalerOutLenReg},
    
    {0x000000C0,    @"Channel 1 Internal Trigger Counter",      YES,    NO,     YES,    kChan1TrigCounterReg},
    {0x000000C4,    @"Channel 2 Internal Trigger Counter",      YES,    NO,     YES,    kChan2TrigCounterReg},
    {0x000000C8,    @"Channel 3 Internal Trigger Counter",      YES,    NO,     YES,    kChan3TrigCounterReg},
    {0x000000CC,    @"Channel 4 Internal Trigger Counter",      YES,    NO,     YES,    kChan4TrigCounterReg},
    
    {0x000000D0,    @"Channel 5 Internal Trigger Counter",      YES,    NO,     YES,    kChan5TrigCounterReg},
    {0x000000D4,    @"Channel 6 Internal Trigger Counter",      YES,    NO,     YES,    kChan6TrigCounterReg},
    {0x000000D8,    @"Channel 7 Internal Trigger Counter",      YES,    NO,     YES,    kChan7TrigCounterReg},
    {0x000000DC,    @"Channel 8 Internal Trigger Counter",      YES,    NO,     YES,    kChan8TrigCounterReg},
    
    {0x000000E0,    @"Channel 9 Internal Trigger Counter",      YES,    NO,     YES,    kChan9TrigCounterReg},
    {0x000000E4,    @"Channel 10 Internal Trigger Counter",     YES,    NO,     YES,    kChan10TrigCounterReg},
    {0x000000E8,    @"Channel 11 Internal Trigger Counter",     YES,    NO,     YES,    kChan11TrigCounterReg},
    {0x000000EC,    @"Channel 12 Internal Trigger Counter",     YES,    NO,     YES,    kChan12TrigCounterReg},

    {0x000000F0,    @"Channel 13 Internal Trigger Counter",     YES,    NO,     YES,    kChan13TrigCounterReg},
    {0x000000F4,    @"Channel 14 Internal Trigger Counter",     YES,    NO,     YES,    kChan14TrigCounterReg},
    {0x000000F8,    @"Channel 15 Internal Trigger Counter",     YES,    NO,     YES,    kChan15TrigCounterReg},
    {0x000000FC,    @"Channel 16 Internal Trigger Counter",     YES,    NO,     YES,    kChan16TrigCounterReg},
    
    {0x00000400,    @"Key Register Reset",                      NO,    YES,     NO,     kKeyResetReg},
    {0x00000404,    @"Key User Function",                       NO,    YES,     NO,     kKeyUserFuncReg},
    
    {0x00000410,    @"Key Arm Sample Logic",                    NO,    YES,     NO,     kKeyArmSampleLogicReg},
    {0x00000414,    @"Key Disarm Sample Logic",                 NO,    YES,     NO,     kKeyDisarmSampleLogicReg},
    {0x00000418,    @"Key Trigger",                             NO,    YES,     NO,     kKeyTriggerReg},
    {0x0000041C,    @"Key Timestamp Clear",                     NO,    YES,     NO,     kKeyTimeStampClrReg},
    {0x00000420,    @"Key Dusarm Bankx and Arm Bank1",          NO,    YES,     NO,     kKeyDisarmXArmBank1Reg},
    {0x00000424,    @"Key Dusarm Bankx and Arm Bank2",          NO,    YES,     NO,     kKeyDisarmXArmBank2Reg},
    {0x00000428,    @"Key Enable Bank Swap",                    NO,    YES,     NO,     kKeyEnableBankSwapNimReg},
    {0x0000042C,    @"Key Disable Prescaler Logic",             NO,    YES,     NO,     kKeyDisablePrescalerLogReg},
    
    {0x00000430,    @"Key PPS latch bit clear",                 NO,    YES,     NO,     kKeyPPSLatchBitClrReg},
    {0x00000434,    @"Key Reset ADC-FPGA-Logic",                NO,    YES,     NO,     kKeyResetAdcLogicReg},
    {0x00000438,    @"Key ADC Clock DCM/PLL Reset",             NO,    YES,     NO,     kKeyAdcClockPllResetReg},
};
    

//ADC Group registers Add 0x1000 for each group

static ORSIS3316RegisterInformation groupRegister[kADCGroupRegisters] = {
  
    {0x00001000,    @"ADC Input Tap Delay",                     YES,    YES,    YES,   kAdcInputTapDelayReg},
    {0x00001004,    @"ADC Gain/Termination Control",            YES,    YES,    YES,   kAdcGainTermCntrlReg},
    {0x00001008,    @"ADC Offset Control",                      YES,    YES,    YES,   kAdcOffsetDacCntrlReg},
    {0x0000100C,    @"ADC SPI Control",                         YES,    YES,    YES,   kAdcSpiControlReg},
    
    {0x00001010,    @"Event Configureation",                    YES,    YES,    YES,   kEventConfigReg},
    {0x00001014,    @"Channel Header ID",                       YES,    YES,    YES,   kChanHeaderIdReg},
    {0x00001018,    @"End Address Threshold",                   YES,    YES,    YES,   kEndAddressThresholdReg},
    {0x0000101C,    @"Active Trigger Gate WIndow Length",       YES,    YES,    YES,   kActTriggerGateWindowLenReg},
    
    {0x00001020,    @"Raw Data Buffer COnfiguration",           YES,    YES,    YES,   kRawDataBufferConfigReg},
    {0x00001024,    @"Pileup Configuration",                    YES,    YES,    YES,   kPileupConfigReg},
    {0x00001028,    @"Pre Trigger Delay",                       YES,    YES,    YES,   kPreTriggerDelayReg},
    {0x0000102C,    @"Average Configuration",                   YES,    YES,    YES,   kAveConfigReg},
    
    {0x00001030,    @"Data Format Configuration",               YES,    YES,    YES,   kDataFormatConfigReg},
    {0x00001034,    @"MAW Test Buffer Configuration",           YES,    YES,    YES,   kMawBufferConfigReg},
    {0x00001038,    @"Internal Trigger Delay Configuration",    YES,    YES,    YES,   kInternalTrigDelayConfigReg},
    {0x0000103C,    @"Internal Gate Length Configuration",      YES,    YES,    YES,   kInternalGateLenConfigReg},
    
    {0x00001040,    @"FIR Trigger Setup",                       YES,    YES,    YES,   kFirTrigSetupCh1Reg},
    {0x00001044,    @"Trigger Threshold",                       YES,    YES,    YES,   kTrigThresholdCh1Reg},
    {0x00001048,    @"High Energy Trigger Threshold",           YES,    YES,    YES,   kHiEnergyTrigThresCh1Reg},
    
    {0x00001080,    @"FIR Trigger Setup Sum",                   YES,    YES,    YES,   kFirTrigSetupSumCh1Ch4Reg},
    {0x00001084,    @"Trigger Threshold Sum",                   YES,    YES,    YES,   kTrigThreholdSumCh1Ch4Reg},
    {0x00001088,    @"High Energy Trigger Threshold Sum",       YES,    YES,    YES,   kHiETrigThresSumCh1Ch4Reg},
    
    {0x00001090,    @"Trigger Statistic Counter Mode",          YES,    YES,    YES,   kTrigStatCounterModeCh1Ch4Reg},
    {0x00001094,    @"Peak/Charge Configuration",               YES,    YES,    YES,   kPeakChargeConfigReg},
    {0x00001098,    @"Extended Raw Data Buffer Configuration",  YES,    YES,    YES,   kExtRawDataBufConfigReg},
    {0x0000109C,    @"Extended Event Configuration",            YES,    YES,    YES,   kExtEventConfigCh1Ch4Reg},

    {0x000010A0,    @"Accumulator Gate 1 Configuration",        YES,    YES,    YES,   kAccGate1ConfigReg},
    {0x000010A4,    @"Accumulator Gate 2 Configuration",        YES,    YES,    YES,   kAccGate2ConfigReg},
    {0x000010A8,    @"Accumulator Gate 3 Configuration",        YES,    YES,    YES,   kAccGate3ConfigReg},
    {0x000010AC,    @"Accumulator Gate 4 Configuration",        YES,    YES,    YES,   kAccGate4ConfigReg},
    {0x000010B0,    @"Accumulator Gate 5 Configuration",        YES,    YES,    YES,   kAccGate5ConfigReg},
    {0x000010B4,    @"Accumulator Gate 6 Configuration",        YES,    YES,    YES,   kAccGate6ConfigReg},
    {0x000010B8,    @"Accumulator Gate 7 Configuration",        YES,    YES,    YES,   kAccGate7ConfigReg},
    {0x000010BC,    @"Accumulator Gate 8 Configuration",        YES,    YES,    YES,   kAccGate8ConfigReg},

    {0x000010C0,    @"FIR Energy Setup Ch1",                    YES,    YES,    YES,   kFirEnergySetupCh1Reg},
    {0x000010C4,    @"FIR Energy Setup Ch1",                    YES,    YES,    YES,   kFirEnergySetupCh2Reg},
    {0x000010C8,    @"FIR Energy Setup Ch1",                    YES,    YES,    YES,   kFirEnergySetupCh3Reg},
    {0x000010CC,    @"FIR Energy Setup Ch1",                    YES,    YES,    YES,   kFirEnergySetupCh4Reg},

    {0x000010D0,    @"Gen Histo Config Ch1",                    YES,    YES,    YES,   kGenHistogramConfigCh1Reg},
    {0x000010D4,    @"Gen Histo Config Ch1",                    YES,    YES,    YES,   kGenHistogramConfigCh2Reg},
    {0x000010D8,    @"Gen Histo Config Ch1",                    YES,    YES,    YES,   kGenHistogramConfigCh3Reg},
    {0x000010DC,    @"Gen Histo Config Ch1",                    YES,    YES,    YES,   kGenHistogramConfigCh4Reg},

    {0x000010E0,    @"MAW Start Energy Pickup Config Ch1",      YES,    YES,    YES,   kMAWStartConfigCh1Reg},
    {0x000010E4,    @"MAW Start Energy Pickup Config Ch1",      YES,    YES,    YES,   kMAWStartConfigCh2Reg},
    {0x000010E8,    @"MAW Start Energy Pickup Config Ch1",      YES,    YES,    YES,   kMAWStartConfigCh3Reg},
    {0x000010EC,    @"MAW Start Energy Pickup Config Ch1",      YES,    YES,    YES,   kMAWStartConfigCh4Reg},

    
    {0x00001100,    @"ADC FPGA Version",                        YES,    NO,    YES,   kAdcVersionReg},
    {0x00001104,    @"ADC FPGA Status",                         YES,    NO,    YES,   kAdcStatusReg},
    {0x00001108,    @"ADC Offset (DAC) readback",               YES,    NO,    YES,   kAdcOffsetReadbackReg},
    {0x0000110C,    @"ADC SPI readback",                        YES,    NO,    YES,   kAdcSpiReadbackReg},

    {0x00001110,    @"Actual sample address Ch1",               YES,    NO,    YES,   kActualSampleCh1Reg},
    {0x00001114,    @"Actual sample address Ch2",               YES,    NO,    YES,   kActualSampleCh2Reg},
    {0x00001118,    @"Actual sample address Ch3",               YES,    NO,    YES,   kActualSampleCh3Reg},
    {0x0000111C,    @"Actual sample address Ch4",               YES,    NO,    YES,   kActualSampleCh4Reg},

    {0x00001120,    @"Previous Bank Sample Address Register Ch1",       YES,    NO,    YES,   kPreviousBankSampleCh1Reg},
    {0x00001124,    @"Previous Bank Sample Address Register Ch2",       YES,    NO,    YES,   kPreviousBankSampleCh2Reg},
    {0x00001128,    @"Previous Bank Sample Address Register Ch3",       YES,    NO,    YES,   kPreviousBankSampleCh3Reg},
    {0x0000112C,    @"Previous Bank Sample Address Register Ch4",       YES,    NO,    YES,   kPreviousBankSampleCh4Reg},

    {0x00001130,    @"PPS Timestamp (bits 47-32)",              YES,    NO,    YES,   kPPSTimeStampHiReg},
    {0x00001134,    @"PPS TImestamp (bits 31-0)",               YES,    NO,    YES,   kPPSTimeStampLoReg},
    {0x00001138,    @"Test:readback  0x01018",                  YES,    NO,    YES,   kTestReadback01018Reg},
    {0x0000113C,    @"Test: readback 0x0101C",                  YES,    NO,    YES,   kTestReadback0101CReg},
};

#define I2C_ACK             8
#define I2C_START			9
#define I2C_REP_START		10
#define I2C_STOP			11
#define I2C_WRITE			12
#define I2C_READ			13
#define I2C_BUSY			31
#define OSC_ADR             0x55

#define kSIS3316FpgaAdc1MemBase     0x100000
#define kSIS3316FpgaAdcMemOffset    0x100000
#define kSIS3316FpgaAdcRegOffset    0x1000


// frequency presets setup
unsigned char freqPreset62_5MHz[6] = {0x23,0xC2,0xBC,0x33,0xE4,0xF2};
unsigned char freqPreset125MHz[6]  = {0x21,0xC2,0xBC,0x33,0xE4,0xF2};
unsigned char freqPreset250MHz[6]  = {0x20,0xC2,0xBC,0x33,0xE4,0xF2};

//----------------------------------------------
//Control Status Register Bits
#define kLedUOnBit				(0x1<<0)
#define kLed1OnBit              (0x1<<1)
#define kLed2OnBit              (0x1<<2)
#define kLedUAppModeBit         (0x1<<4)
#define kLed1AppModeBit         (0x1<<5)
#define kLed2AppModeBitBit      (0x1<<6)
#define kRebootFPGA             (0x1<<15)

#define kLedUOffBit				(0x1<<0)
#define kLed1OffBit             (0x1<<1)
#define kLed2OffBit             (0x1<<2)
#define kLedUAppModeClrBit      (0x1<<4)
#define kLed1AppModeClrBit      (0x1<<5)
#define kLed2AppModeVlrBit      (0x1<<6)
#define kRebootFPGAClrBit       (0x1<<15)

@interface ORSIS3316Model (private)
//low level stuff that should never be called by scripts or other objects
- (int) si570FreezeDCO:(int) osc;
- (int) si570ReadDivider:(int) osc values:(unsigned char*)data;
- (int) si570UnfreezeDCO:(int)osc;
- (int) si570NewFreq:(int) osc;
- (int) i2cStop:(int) osc;
- (int) i2cStart:(int) osc;
- (int) i2cWriteByte:(int)osc data:(unsigned char) data ack:(char*)ack;
- (int) i2cReadByte:(int) osc data:(unsigned char*) data ack:(char)ack;
- (int) writeAdcSpiGroup:(unsigned int) adc_fpga_group chip:(unsigned int) adc_chip address:(uint32_t) spi_addr data:(uint32_t) spi_data;
- (int) readAdcSpiGroup:(unsigned int) adc_fpga_group chip:(unsigned int) adc_chip address:(uint32_t) spi_addr data:(uint32_t*) spi_data;
- (void) addCurrentState:(NSMutableDictionary*)dictionary unsignedLongArray:(uint32_t*)anArray   size:(int32_t)numItems forKey:(NSString*)aKey;
- (void) addCurrentState:(NSMutableDictionary*)dictionary unsignedShortArray:(unsigned short*)anArray size:(int32_t)numItems forKey:(NSString*)aKey;
- (void) addCurrentState:(NSMutableDictionary*)dictionary boolArray:(BOOL*)anArray                    size:(int32_t)numItems forKey:(NSString*)aKey;
- (void) configureAdcFpgaIobDelays:(uint32_t) iobDelayValue;
- (void) enableAdcSpiAdcOutputs;
- (int) changeFrequencyHsDivN1Div:(int) osc hsDiv:(NSUInteger) hs_div_val n1Div:( unsigned) n1_div_val;
- (int) writesi5325ClkMultiplier:(uint32_t) addr data:(uint32_t) data;
- (int) adcSpiSetup;
@end

@implementation ORSIS3316Model

#pragma mark •••Static Declarations

static uint32_t eventCountOffset[4][2]={ //group,bank
{0x00200010,0x00200014},
{0x00280010,0x00280014},
{0x00300010,0x00300014},
{0x00380010,0x00380014},
};

static uint32_t eventDirOffset[4][2]={ //group,bank
{0x00201000,0x00202000},
{0x00281000,0x00282000},
{0x00301000,0x00302000},
{0x00381000,0x00382000},
};

static uint32_t addressCounterOffset[4][2]={ //group,bank
{0x00200008,0x0020000C},
{0x00280008,0x0028000C},
{0x00300008,0x0030000C},
{0x00380008,0x0038000C},
};

#define kTriggerEvent1DirOffset 0x101000
#define kTriggerEvent2DirOffset 0x102000

#define kTriggerTime1Offset 0x1000
#define kTriggerTime2Offset 0x2000

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setAddressModifier:0x09];
    [self setBaseAddress:0x01000000];
    [self setDefaults];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc 
{
    [waveFormRateGroup release];
    [revision release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SIS3316Card"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORSIS3316Controller"];
}

//- (NSString*) helpURL
//{
//	return @"VME/SIS3316.html";
//}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x00780000+0x80000);
}
- (BOOL) checkRegList
{
    int i;
    for(i=0;i<kNumberSingleRegs;i++){
        if(singleRegister[i].enumId != i){
            NSLog(@"programmer bug in register list\n");
            NSLog(@"check line: %d\n",i);
            return NO;
        }
    }
    for(i=0;i<kADCGroupRegisters;i++){
        if(groupRegister[i].enumId != i){
            NSLog(@"programmer bug in group registers\n");
            NSLog(@"check line: %d\n",i);
            return NO;
        }
    }
    NSLog(@"Lists OK\n");
    return YES;
}

#pragma mark ***Accessors
- (void) setDefaults
{
    [self setNIMControlStatusMask:0x3];
    [self setLemoToMask:0x0];
    [self setLemoUoMask:0x0];
    [self setLemoCoMask:0x0];
    [self setAcquisitionControlMask:0x05]; //ext timestamp clear enable | ext trig enable
    [self setRawDataBufferLen:2048];
    [self setRawDataBufferStart:0];

    int iadc;
    for(iadc =0; iadc<kNumSIS3316Groups; iadc++) {
        [self setActiveTrigGateWindowLen:iadc   withValue:1000];
        [self setPreTriggerDelay:iadc           withValue:300];
        [self setThreshold:iadc                 withValue:0x1000];
        [self setDacOffset:iadc                 withValue:51500];
        [self setEnableSum:iadc                 withValue:1];
        [self setRiseTimeSum:iadc               withValue:4];
        [self setGapTimeSum:iadc                withValue:4];
        [self setThresholdSum:iadc              withValue:1000];
        [self setCfdControlBitsSum:iadc         withValue:0x3]; //CFD at 50%
        [self setHeSuppressTriggerBit:iadc      withValue:0];
        [self setHeTrigThresholdSum:iadc        withValue:0];
        [self setInternalGateLen:iadc           withValue:0];
        [self setInternalCoinGateLen:iadc       withValue:0];
        [self setTriggerDelay:iadc              withValue:0];
        
        [self setAccGate1Len:  iadc withValue:100];
        [self setAccGate1Start:iadc withValue:100+0*100];
        [self setAccGate2Len:  iadc withValue:100];
        [self setAccGate2Start:iadc withValue:100+1*100];
        [self setAccGate3Len:  iadc withValue:100];
        [self setAccGate3Start:iadc withValue:100+2*100];
        [self setAccGate4Len:  iadc withValue:100];
        [self setAccGate4Start:iadc withValue:100+3*100];
        [self setAccGate5Len:  iadc withValue:100];
        [self setAccGate5Start:iadc withValue:100+4*100];
        [self setAccGate6Len:  iadc withValue:100];
        [self setAccGate6Start:iadc withValue:100+5*100];
        [self setAccGate7Len:  iadc withValue:100];
        [self setAccGate7Start:iadc withValue:100+6*100];
        [self setAccGate8Len:  iadc withValue:100];
        [self setAccGate8Start:iadc withValue:100+7*100];
     }
    [self setEventConfigMask:0x5];
    [self setTermination:1];
    [self setGain:1];
    [self setEnabledMask:0xFFFF];
    [self setFormatMask:0xF];
    [self setHeSuppressTriggerMask:0];
    [self setTrigBothEdgesMask:0];
    [self setIntHeTrigOutPulseMask:0];
    int ichan;
    for(ichan =0; ichan<kNumSIS3316Channels; ichan++){
        [self setTriggerDelay:ichan     withValue:0];
        [self setHeTrigThreshold:ichan  withValue:0];
        [self setRiseTime:ichan         withValue:4];
        [self setGapTime:ichan          withValue:4];
        [self setCfdControlBits:ichan   withValue:0x3];
        [self setThreshold:ichan        withValue:1000];
        [self setHeTrigThreshold:ichan  withValue:0];
        [self setTauFactor:ichan        withValue:0];
        [self setExtraFilterBits:ichan  withValue:0];
    }
}

- (unsigned short) moduleID
{
	return moduleID;
}

- (unsigned short) mHzType
{
    return mHzType;
}

- (float) temperature
{
    return temperature;
}

- (ORRateGroup*) waveFormRateGroup
{
    return waveFormRateGroup;
}

- (void) setWaveFormRateGroup:(ORRateGroup*)newRateGroup
{
    [newRateGroup retain];
    [waveFormRateGroup release];
    waveFormRateGroup = newRateGroup;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORSIS3316RateGroupChangedNotification
	 object:self];    
}

- (id) rateObject:(int)channel
{
    return [waveFormRateGroup rateObject:channel];
}

- (void) initParams
{
	enabledMask = 0xFFFFFFFF;
}

- (void) setRateIntegrationTime:(double)newIntegrationTime
{
	//we this here so we have undo/redo on the rate object.
    [[[self undoManager] prepareWithInvocationTarget:self] setRateIntegrationTime:[waveFormRateGroup integrationTime]];
    [waveFormRateGroup setIntegrationTime:newIntegrationTime];
}

#pragma mark •••Rates
- (uint32_t) getCounter:(int)counterTag forGroup:(int)groupTag
{
	if(groupTag == 0){
		if(counterTag>=0 && counterTag<kNumSIS3316Channels){
			return waveFormCount[counterTag];
		}	
		else return 0;
	}
	else return 0;
}



#pragma mark •••Hardware Access
//Register Array
//comments denote the section from the manual
//------------------------------------------------------------
- (uint32_t) singleRegister: (uint32_t)aRegisterIndex
{
    return [self baseAddress] + singleRegister[aRegisterIndex].offset;
}

- (uint32_t) groupRegister:(uint32_t)aRegisterIndex group:(int)aGroup
{
    return [self baseAddress] + groupRegister[aRegisterIndex].offset + 0x1000*aGroup;
}

- (uint32_t) channelRegister:(uint32_t)aRegisterIndex channel:(int)aChannel
{
    return [self baseAddress] + groupRegister[aRegisterIndex].offset + (0x1000*(aChannel/4)) + (0x10*(aChannel%4));
}

- (uint32_t) channelRegisterVersionTwo:(uint32_t)aRegisterIndex channel:(int)aChannel
{
    return [self baseAddress] + groupRegister[aRegisterIndex].offset + (0x1000*(aChannel/4)) + (0x4*(aChannel%4));
}

- (uint32_t) accumulatorRegisters:(uint32_t)aRegisterIndex channel:(int)aChannel
{
    return [self baseAddress] + groupRegister[aRegisterIndex].offset + (0x4*(aChannel%2)) ;
}

//--------------------------------------------------------------
//4.10 Firmware Version
- (void) dumpFPGAStatus
{
    [self dumpFPGAStatus1];
    [self dumpFPGAStatus2];
}
- (void) dumpFPGAStatus1
{
    int width = 88;
    uint32_t addr = [self groupRegister:kAdcStatusReg group:0];
    NSString* title = [NSString stringWithFormat:@"ADC FPGA Status (0x%08x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"|  chan |   Address  | Hard | Soft | Frame | Chan Up | Lane Up | Hard  | Soft  | Frame |\n");
    NSLogMono(@"|       |            |  Err | Err  |  Err  |   Flag  |  Flag   | Latch | Latch | Latch |\n");
    NSLogDivider(@"-",width);
    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        addr = [self groupRegister:kAdcStatusReg group:group];
        uint32_t aValue =  [self readLongFromAddress:addr];
        NSLogMono(@"| %2d-%-2d | 0x%08x |%@|%@|%@|%@|%@|%@|%@|%@|\n",
                  group*4+1, group*4+4,
                  addr,
                  [(aValue>>0 & 0x1)?@"X":@"-" centered:6],
                  [(aValue>>1 & 0x1)?@"X":@"-" centered:6],
                  [(aValue>>2 & 0x1)?@"X":@"-" centered:7],
                  [(aValue>>3 & 0x1)?@"X":@"-" centered:9],
                  [(aValue>>4 & 0x1)?@"X":@"-" centered:9],
                  [(aValue>>5 & 0x1)?@"X":@"-" centered:7],
                  [(aValue>>6 & 0x1)?@"X":@"-" centered:7],
                  [(aValue>>7 & 0x1)?@"X":@"-" centered:7]
                  );
    }
    NSLogDivider(@"=",width);
}
- (void) dumpFPGAStatus2
{
    int width = 63;
    uint32_t addr = [self groupRegister:kAdcStatusReg group:0];
    NSString* title = [NSString stringWithFormat:@"ADC FPGA Status (0x%08x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"|  chan |   Address  | Data Link | Mem1 | Mem2 |  DCM |  DCM  |\n");
    NSLogMono(@"|       |            |   Speed   |  OK  |  OK  |  OK  | Reset |\n");
    NSLogDivider(@"-",width);
    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        addr = [self groupRegister:kAdcStatusReg group:group];
        uint32_t aValue =  [self readLongFromAddress:addr];
        NSLogMono(@"| %2d-%-2d | 0x%08x |%@|%@|%@|%@|%@|\n",
                  group*4+1, group*4+4,
                  addr,
                  [(aValue>>8 & 0x1)?@"2.5 GHz":@"1.25 GHz" centered:11],
                  [(aValue>>16 & 0x1)?@"X":@"-" centered:6],
                  [(aValue>>17 & 0x1)?@"X":@"-" centered:6],
                  [(aValue>>20 & 0x1)?@"X":@"-" centered:6],
                  [(aValue>>21 & 0x1)?@"X":@"-" centered:7]
                  );
    }
    NSLogDivider(@"=",width);
}

//4.1 ADC FPGA Status
- (void) readFirmwareVersion:(BOOL)verbose
{
    uint32_t addr    = [self groupRegister:kAdcVersionReg group:0];
    uint32_t result  =  [self readLongFromAddress:addr];
    mHzType               = result>>16 & 0xffff;
    
    if(verbose){
        int width = 57;
        NSString* title = [NSString stringWithFormat:@"ADC Firmware (0x%08x)",addr];
        NSLogStartTable(title, width);
        NSLogMono(@"|  Chan |   Type   | Version | Revision | Neutron/Gamma |\n");
        NSLogDivider(@"-",width);
        int group;
        for(group=0;group<kNumSIS3316Groups;group++){
            uint32_t result =  [self readLongFromAddress:addr];
            NSLogMono(@"| %2d-%2d |  0x%04x  |   0x%02x  |   0x%02x   |%@|\n",group*4+1, group*4+4, result>>16 & 0xffff,result>>8 & 0xff,result&0xff,[result>>8 ==0x02?@"YES":@"NO" centered:15]);
        }
        NSLogDivider(@"=",width);
    }
}
//6.1 Control/Status Register(0x0, write/read)

- (void) writeControlStatusReg:(uint32_t)aValue
{
    [self writeLong:aValue toAddress:[self singleRegister:kControlStatusReg]];
}

- (uint32_t) readControlStatusReg
{
    return [self readLongFromAddress:[self singleRegister:kControlStatusReg]];
}

- (void) setLed:(BOOL)state
{
    uint32_t aValue = state ? 0x1:(0x1<<16);
    [self writeLong:aValue toAddress:[self singleRegister:kControlStatusReg]];
}
//------------------------------------------------------------
//6.2 Module Id. and Firmware Revision Register
- (NSString*) revision
{
    if(revision)return revision;
    else        return nil;
}

- (void) setRevision:(NSString*)aString;
{
    [revision autorelease];
    revision = [aString copy];
}

- (unsigned short) majorRevision;
{
    return majorRev;
}

- (unsigned short) minorRevision;
{
    return minorRev;
}

- (void) readModuleID:(BOOL)verbose //*** readModuleID method ***//
{
    mHzType  =  ([self readLongFromAddress:[self groupRegister:kAdcVersionReg group:0]]>>16) & 0xffff;

    uint32_t addr = [self singleRegister:kModuleIDReg];
    uint32_t result =  [self readLongFromAddress:addr];
    moduleID = result >> 16;
    majorRev = (result >> 8) & 0xff;
    minorRev = result & 0xff;
    [self setRevision:[NSString stringWithFormat:@"%x.%x",majorRev,minorRev]];
    if(verbose){
        int width = 31;
        NSLog(@"\n");
        NSString* title = [NSString stringWithFormat:@"Module ID (0x%x)",addr];
        NSLogStartTable(title, width);
        NSLogMono(@"|  ID   |  Firmware  |  Gamma  |\n");
        NSLogDivider(@"-",width);
        NSLogMono(@"| %05x | %5d.%-4d |  %@  |\n",moduleID,majorRev,minorRev,majorRev == 0x20?@" YES ":@"  NO ");
        NSLogDivider(@"=",width);
        NSLog(@"\n");
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316IDChanged object:self]; //changes name if BOOL = true
}
//----------------------------------------------------------

//6.3 Intterupt Configureation register (0x8)

//6.4 Interrupt control register (0xC)

//6.5 Interface Access Arbitration Control Register

//6.6 Broadcast setup register

//6.7 Hardware Version Register
- (void) readHWVersion:(BOOL)verbose
{
    uint32_t addr   = [self singleRegister:kHWVersionReg];
    uint32_t result = [self readLongFromAddress:addr];
    result &= 0xf;
    if(verbose){
        int width = 30;
        NSLog(@"\n");
        NSString* title = [NSString stringWithFormat:@"HW Version(0x%x)",addr];
        NSLogStartTable(title, width);
        NSLogMono(@"|            %2d              |\n",result);
        NSLogDivider(@"=",width);
        NSLog(@"\n");
    }
    
    hwVersion = result;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316HWVersionChanged object:self];
}

- (unsigned short) hwVersion;
{
    return hwVersion;
}
//-----------------------------------------------------

//6.8 Temperature Register
- (void) readTemperature:(BOOL)verbose
{
    uint32_t addr = [self singleRegister:kTemperatureReg];
    temperature =  [self readLongFromAddress:addr]/4.0;
    
    if(verbose){
        int width = 32;
        NSString* title = [NSString stringWithFormat:@"Temperature (0x%x)",addr];
        NSLog(@"\n");
        NSLogStartTable(title, width);
        NSLogMono(@"|          %4.1f C              |\n",temperature);
        NSLogDivider(@"=",width);
        NSLog(@"\n");
   }

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316TemperatureChanged object:self];
}

//6.9 Onewire EEPROM Control register

//6.10 Serial Number register  (ethernet mac address)
- (void) readSerialNumber:(BOOL)verbose
{
    uint32_t addr   = [self singleRegister:kSerialNumberReg];
    uint32_t result =  [self readLongFromAddress:addr];
    BOOL isValid         = (result >> 16) & 0x1;
    serialNumber                 = result & 0xFFFF;  //gives serial number
    unsigned short dhcpOption    = (result >> 24) & 0xFF;
    unsigned short memoryFlag512 =   (result >> 23);
    
    if(verbose){
        NSString* mem = memoryFlag512?@"512 MB":@"256 MB";
        int width = 36;
        NSString* title = [NSString stringWithFormat:@"Serial Number (0x%x)",addr];
        NSLogStartTable(title, width);
        NSLogMono(@"| DHCP | Memory | Serial # | Valid |\n");
        NSLogDivider(@"-",width);
      NSLogMono(@"| 0x%02x |%@|  0x%04x  |  %@ |\n",dhcpOption,[mem centered:8],serialNumber,isValid?@"YES ":@" NO ");
        NSLogDivider(@"=",width);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316SerialNumberChanged object:self];
}

- (unsigned short) serialNumber
{
    return serialNumber;
}

//6.11 Internal Transfer Speed register(not often needed)

//6.12 Event Configuration
- (void) dumpEventConfiguration
{
    int width = 95;
    NSLog(@"\n");
    uint32_t addr   = [self groupRegister:kEventConfigReg group:0];
    NSString* title = [NSString stringWithFormat:@"Event Configuration (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| group | chan |   Address  |  Pol | SUM |    Type    | Int G1 | Int G2 | Ext Gate | Ext Veto |\n");
    NSLogDivider(@"-",width);
    NSString* type[4] = {
        @"None",
        @"Internal",
        @"External",
        @"Int OR Ext"
    };
    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        addr   = [self groupRegister:kEventConfigReg group:group];
        uint32_t aValue = [self readLongFromAddress:addr];
        int i;
        for(i=0;i<4;i++){
            int c1 = group*4 + i;
            NSLogMono(@"|   %d   |  %2d  | 0x%08x |%@|%@|%@|%@|%@|%@|%@|\n",
                      group,
                      c1 ,
                      addr,
                      [aValue>>(i*8)  &0x1 ? @"Neg":@"Pos" centered:6],
                      [aValue>>(i*8+1)&0x1 ? @"Yes":@"No"  centered:5],
                      [type[aValue>>(i*8+2)&0x3]  centered:12],
                      [aValue>>(i*8+4)&0x1 ? @"Yes":@"No"  centered:8],
                      [aValue>>(i*8+5)&0x1 ? @"Yes":@"No"  centered:8],
                      [aValue>>(i*8+6)&0x1 ? @"Yes":@"No"  centered:10],
                      [aValue>>(i*8+7)&0x1 ? @"Yes":@"No"  centered:10]
                      );
        }
        if(group!=3) NSLogDivider(@"-",width);
        
    }
    
    NSLogDivider(@"=",width);
    NSLog(@"\n");
}
//6.13 Extended Config
- (void) dumpExtendedEventConfiguration
{
    int width =43;
    NSLog(@"\n");
    uint32_t addr   = [self groupRegister:kExtEventConfigCh1Ch4Reg group:0];
    NSString* title = [NSString stringWithFormat:@"Extended Event Config (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| group | chan |   Address  |  Int Pileup |\n");
    NSLogDivider(@"-",width);

    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        addr   = [self groupRegister:kExtEventConfigCh1Ch4Reg group:group];
        uint32_t aValue = [self readLongFromAddress:addr];
        int i;
        for(i=0;i<4;i++){
            int c1 = group*4 + i;
            NSLogMono(@"|   %d   |  %2d  | 0x%08x |%@|\n",
                      group,
                      c1 ,
                      addr,
                      [aValue>>(i*8)&0x1 ? @"Enabled":@"Disabled" centered:13]
                       );
        }
        if(group!=3) NSLogDivider(@"-",width);
        
    }
    
    NSLogDivider(@"=",width);
    NSLog(@"\n");
}
//6.14 Channel Header ID
- (void) dumpChannelHeaderID
{
    int width =47;
    NSLog(@"\n");
    uint32_t addr   = [self groupRegister:kChanHeaderIdReg group:0];
    NSString* title = [NSString stringWithFormat:@"Channel Header ID (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| group |    chan   |   Address  |    Value   |\n");
    NSLogDivider(@"-",width);
    
    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        addr   = [self groupRegister:kChanHeaderIdReg group:group];
        uint32_t aValue = [self readLongFromAddress:addr];
        int c1 = group*4;
        int c2 = group*4+3;
        NSLogMono(@"|   %d   |  %2d - %-2d  | 0x%08x | 0x%08x |\n",
                  group,
                  c1 , c2,
                  addr,
                  aValue>>20 & 0xF
                  );
    }
    
    NSLogDivider(@"=",width);
    NSLog(@"\n");
}
//6.15
- (void) dumpEndAddressThreshold
{
    int width =58;
    NSLog(@"\n");
    uint32_t addr   = [self groupRegister:kEndAddressThresholdReg group:0];
    NSString* title = [NSString stringWithFormat:@"End Address (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| group |   chan    |   Address  |  Single  |    Value   |\n");
    NSLogDivider(@"-",width);
    
    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        addr   = [self groupRegister:kEndAddressThresholdReg group:group];
        uint32_t aValue = [self readLongFromAddress:addr];
        int c1 = group*4;
        int c2 = group*4+3;
        NSLogMono(@"|   %d   |  %2d - %-2d  | 0x%08x | %@ | 0x%08x |\n",
                  group,
                  c1 ,
                  c2 ,
                  addr,
                  [aValue>>31 & 0x1 ? @"Yes":@" No" centered:8],
                  aValue & 0xFFFFF
                  );
        
    }
    
    NSLogDivider(@"=",width);
    NSLog(@"\n");
}
//6.16
- (void) dumpActiveTrigGateWindowLen
{
    int width =46;
    NSLog(@"\n");
    uint32_t addr   = [self groupRegister:kActTriggerGateWindowLenReg group:0];
    NSString* title = [NSString stringWithFormat:@"Active Trig Gate Window (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| group |   chan    |   Address  |    Value   |\n");
    NSLogDivider(@"-",width);
    
    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        addr   = [self groupRegister:kActTriggerGateWindowLenReg group:group];
        uint32_t aValue = [self readLongFromAddress:addr];
        int c1 = group*4;
        int c2 = group*4+3;
        NSLogMono(@"|   %d   |  %2d - %-2d  | 0x%08x | 0x%08x |\n",
                  group,
                  c1 ,
                  c2 ,
                  addr,
                  aValue & 0xFFFF
                  );
        
    }
    
    NSLogDivider(@"=",width);
    NSLog(@"\n");
}

//6.18
- (void) dumpPileupConfig
{
    int width =60;
    NSLog(@"\n");
    uint32_t addr   = [self groupRegister:kPileupConfigReg group:0];
    NSString* title = [NSString stringWithFormat:@"Pileup Config (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| group |   chan    |   Address  |   Pileup   |  re-Pileup |\n");
    NSLogDivider(@"-",width);
    
    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        addr   = [self groupRegister:kPileupConfigReg group:group];
        uint32_t aValue = [self readLongFromAddress:addr];
        int c1 = group*4;
        int c2 = group*4+3;
        NSLogMono(@"|   %d   |  %2d - %-2d  | 0x%08x | 0x%08x | 0x%08x |\n",
                  group,
                  c1 ,
                  c2 ,
                  addr,
                  aValue & 0xFFFF,
                  aValue>>16 & 0xFFFF
                  );
        
    }
    
    NSLogDivider(@"=",width);
    NSLog(@"\n");
}
//6.19
- (void) dumpPreTriggerDelay
{
    int width =64;
    NSLog(@"\n");
    uint32_t addr   = [self groupRegister:kPreTriggerDelayReg group:0];
    NSString* title = [NSString stringWithFormat:@"Pre-Trigger Delay (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| group |   chan    |   Address  | FIR P+G Bit | PreTrig Delay |\n");
    NSLogDivider(@"-",width);
    
    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        addr   = [self groupRegister:kPreTriggerDelayReg group:group];
        uint32_t aValue = [self readLongFromAddress:addr];
        int c1 = group*4;
        int c2 = group*4+3;
        NSLogMono(@"|   %d   |  %2d - %-2d  | 0x%08x |%@|   0x%08x  |\n",
                  group,
                  c1 ,
                  c2 ,
                  addr,
                  [(aValue>>15 & 0x1)?@"Yes":@"No" centered:13],
                  aValue>>16 & 0xFFFF
                  );
        
    }
    
    NSLogDivider(@"=",width);
    NSLog(@"\n");
}
//6.20
- (void) dumpAveConfig
{
    int width =62;
    NSLog(@"\n");
    uint32_t addr   = [self groupRegister:kAveConfigReg group:0];
    NSString* title = [NSString stringWithFormat:@"Average Config (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| group |   chan    |   Address  | Ave Mode | Ave Sample Len |\n");
    NSLogDivider(@"-",width);
    NSString* mode[8]={@"Disabled",@"4",@"8",@"16",@"32",@"64",@"128",@"256"};
    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        addr   = [self groupRegister:kAveConfigReg group:group];
        uint32_t aValue = [self readLongFromAddress:addr];
        int c1 = group*4;
        int c2 = group*4+3;
        NSLogMono(@"|   %d   |  %2d - %-2d  | 0x%08x |%@|    0x%08x  |\n",
                  group,
                  c1 ,
                  c2 ,
                  addr,
                  [mode[(aValue>>28 & 0x7)] centered:10],
                  aValue& 0xFFFFFF
                  );
        
    }
    
    NSLogDivider(@"=",width);
    NSLog(@"\n");
}
//6.21
- (void) dumpDataFormatConfig
{
    int width = 105;
    NSLog(@"\n");
    uint32_t addr   = [self groupRegister:kDataFormatConfigReg group:0];
    NSString* title = [NSString stringWithFormat:@"Data Format(0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| group | chan |   Address  |  Peak Hi | 2 x Acc | 3 x Acc | Start & Max MAW | Test Buffer | Energy MAW |\n");
    NSLogDivider(@"-",width);
    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        addr   = [self groupRegister:kDataFormatConfigReg group:group];
        uint32_t aValue = [self readLongFromAddress:addr];
        int i;
        for(i=0;i<4;i++){
            int c1 = group*4 + i;
            NSLogMono(@"| %4d  |  %2d  | 0x%08x |%@|%@|%@|%@|%@|%@|\n",
                        group,
                        c1 ,
                        addr,
                        [aValue >> ((i*8)+0) & 0x1?@"X":@"-" centered:10],
                        [aValue >> ((i*8)+1) & 0x1?@"X":@"-" centered:9],
                        [aValue >> ((i*8)+2) & 0x1?@"X":@"-" centered:9],
                        [aValue >> ((i*8)+3) & 0x1?@"X":@"-" centered:17],
                        [aValue >> ((i*8)+4) & 0x1?@"X":@"-" centered:13],
                        [aValue >> ((i*8)+5) & 0x1?@"X":@"-" centered:12]
                      );
        }
        if(group!=3) NSLogDivider(@"-",width);
        
    }
    
    NSLogDivider(@"=",width);
    NSLog(@"\n");
}

//6.22
- (uint32_t) mawBufferLength:(unsigned short)aGroup
{
    if(aGroup <4){
        return mawBufferLength[aGroup];
    }
    else return 0;
}
- (void) setMawBufferLength:(unsigned short)aGroup withValue:(uint32_t)aValue
{
    if(aGroup <4){
        if(aValue>0xfff)aValue = 0xfff;
        aValue &= 0xffe;
        [[[self undoManager] prepareWithInvocationTarget:self] setMawBufferLength:aGroup withValue:mawBufferLength[aGroup]];
        mawBufferLength[aGroup] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316MAWBuffLengthChanged object:self];
    }
}
- (uint32_t) mawPretrigDelay:(unsigned short)aGroup
{
    if(aGroup <4){
        return mawPretrigDelay[aGroup];
    }
    else return 0;
}
- (void) setMawPretrigDelay:(unsigned short)aGroup withValue:(uint32_t)aValue
{
    if(aGroup <4){
        if(aValue>0x3ff)aValue = 0x3ff;
        aValue &= 0xffe;
        [[[self undoManager] prepareWithInvocationTarget:self] setMawPretrigDelay:aGroup withValue:mawPretrigDelay[aGroup]];
        mawPretrigDelay[aGroup] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316MAWPretrigLenChanged object:self];
    }
}
- (void) writeMawBufferConfig
{
    int i;
    for(i = 0; i < kNumSIS3316Groups; i++) {
        uint32_t valueToWrite1 = ((mawBufferLength[i]  & 0xFFE) |
                                      ((mawPretrigDelay[i]  & 0x3FFE) << 16 ));
        [self writeLong:valueToWrite1 toAddress:[self groupRegister:kMawBufferConfigReg group:i]];
    }
}

- (void) dumpMawBufferConfig
{
    int width =69;
    NSLog(@"\n");
    uint32_t addr   = [self groupRegister:kMawBufferConfigReg group:0];
    NSString* title = [NSString stringWithFormat:@"MAW Test Buffer Config (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| group |   chan    |   Address  | PreTrigger Delay | Buffer Length |\n");
    NSLogDivider(@"-",width);
    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        addr   = [self groupRegister:kMawBufferConfigReg group:group];
        uint32_t aValue = [self readLongFromAddress:addr];
        int c1 = group*4;
        int c2 = group*4+3;
        NSLogMono(@"|   %d   |  %2d - %-2d  | 0x%08x |     0x%08x   |   0x%08x  |\n",
                  group,
                  c1 ,
                  c2 ,
                  addr,
                  (aValue>>16 & 0x3FF),
                  aValue & 0xFFF
                  );
        
    }
    
    NSLogDivider(@"=",width);
    NSLog(@"\n");
}
//6.23
- (void) dumpInternalTriggerDelayConfig
{
    int width = 47;
    NSLog(@"\n");
    uint32_t addr   = [self groupRegister:kInternalTrigDelayConfigReg group:0];
    NSString* title = [NSString stringWithFormat:@"Int Trig Delay Config (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| group | chan |   Address  |  Int Trig Delay |\n");
    NSLogDivider(@"-",width);
    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        addr   = [self groupRegister:kInternalTrigDelayConfigReg group:group];
        uint32_t aValue = [self readLongFromAddress:addr];
        int i;
        for(i=0;i<4;i++){
            int c1 = group*4 + i;
            NSLogMono(@"| %4d  |  %2d  | 0x%08x |      0x%04x     |\n",
                      group,
                      c1 ,
                      addr,
                      aValue >> (i*8) & 0xFF
                      );
        }
        if(group!=3) NSLogDivider(@"-",width);
        
    }
    
    NSLogDivider(@"=",width);
    NSLog(@"\n");
}
//6.24
- (void) dumpInternalGateLengthConfig
{
    int width =100;
    NSLog(@"\n");
    uint32_t addr   = [self groupRegister:kInternalGateLenConfigReg group:0];
    NSString* title = [NSString stringWithFormat:@"Internal Gate Len Config (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| group |   chan    |   Address  |   Internal  | Internal Gate |  Gate 1 Enable  |  Gate 2 Enable  |\n");
    NSLogMono(@"|       |           |            | Coincidence |     Length    | Ch4 Ch3 Ch2 Ch1 | Ch4 Ch3 Ch2 Ch1 |\n");
    NSLogDivider(@"-",width);
    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        addr   = [self groupRegister:kInternalGateLenConfigReg group:group];
        uint32_t aValue = [self readLongFromAddress:addr];
        int c1 = group*4;
        int c2 = group*4+3;
        NSLogMono(@"|   %d   |  %2d - %-2d  | 0x%08x |      0x%01x    |      0x%02x     |       0x%02x      |       0x%01x       |\n",
                  group,
                  c1 ,
                  c2 ,
                  addr,
                  (aValue & 0xF),
                  aValue>>8 & 0xFF,
                  aValue>>16 & 0xFF,
                  aValue>>20 & 0xF
                  );
        
    }
    
    NSLogDivider(@"=",width);
    NSLog(@"\n");
}
//6.25
- (void) dumpFirTriggerSetup
{
    int width =56;
    NSLog(@"\n");
    uint32_t addr   = [self channelRegister:kFirTrigSetupCh1Reg channel:0];
    NSString* title = [NSString stringWithFormat:@"FIR Trigger Setup (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| chan |   Address  |   Rise  |  Gap  |  Ext NIM Out   |\n");
    NSLogMono(@"|      |            |   Time  |  Time | Trig Pulse Len |\n");
    NSLogDivider(@"-",width);
    int i;
    for(i=0;i<kNumSIS3316Channels;i++){
        addr   = [self channelRegister:kFirTrigSetupCh1Reg channel:i];
        uint32_t aValue = [self readLongFromAddress:addr];
        NSLogMono(@"|  %2d  | 0x%08x |  0x%03x  | 0x%03x |       0x%02x     |\n",
                  i ,
                  addr,
                  (aValue & 0xFFF),
                  aValue>>12 & 0xFFF,
                  aValue>>16 & 0xFF
                  );
        
    }
    
    NSLogDivider(@"=",width);
    NSLog(@"\n");
}
//6.25.1
- (void) dumpSumFirTriggerSetup
{
    int width =69;
    NSLog(@"\n");
    uint32_t addr   = [self groupRegister:kFirTrigSetupSumCh1Ch4Reg group:0];
    NSString* title = [NSString stringWithFormat:@"SUM FIR Trigger Setup (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| group |   chan    |   Address  |   Rise  |  Gap  |  Ext NIM Out   |\n");
    NSLogMono(@"|       |           |            |   Time  |  Time | Trig Pulse Len |\n");
    NSLogDivider(@"-",width);
    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        addr   = [self groupRegister:kFirTrigSetupSumCh1Ch4Reg group:group];
        uint32_t aValue = [self readLongFromAddress:addr];
        int c1 = group*4;
        int c2 = group*4+3;
        NSLogMono(@"|   %d   |  %2d - %-2d  | 0x%08x |  0x%03x  | 0x%03x |       0x%02x     |\n",
                  group,
                  c1 ,
                  c2 ,
                  addr,
                  (aValue & 0xFFF),
                  aValue>>12 & 0xFFF,
                  aValue>>16 & 0xFF
                  );
        
    }
    
    NSLogDivider(@"=",width);
    NSLog(@"\n");
}

//6.26
- (void) dumpTriggerThreshold
{
    int width =72;
    NSLog(@"\n");
    uint32_t addr   = [self channelRegister:kTrigThresholdCh1Reg channel:0];
    NSString* title = [NSString stringWithFormat:@"FIR Trigger Threshold (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| chan |   Address  |   Trig   | HE Suppress |  CFD Cntrl |  Trigger   |\n");
    NSLogMono(@"|      |            |  Enabled |     Mode    |     Bits   |  Threshold |\n");
    NSLogDivider(@"-",width);
    NSString* cfd[4] = {@"Disabled",@"Disabled",@"Zero Cross",@"50%"};
    int i;
    for(i=0;i<kNumSIS3316Channels;i++){
        addr   = [self channelRegister:kTrigThresholdCh1Reg channel:i];
        uint32_t aValue = [self readLongFromAddress:addr];
        NSLogMono(@"|  %2d  | 0x%08x |%@|%@|%@| 0x%08x |\n",
                  i ,
                  addr,
                  [(aValue>>31 & 0x1)?@"YES":@"NO" centered:10],
                  [(aValue>>30 & 0x1)?@"YES":@"NO" centered:13],
                   [cfd[aValue>>28 & 0x3] centered:12],
                  aValue & 0xFFFFFFF
                  );
        
    }
    
    NSLogDivider(@"=",width);
    NSLog(@"\n");
}

//6.26.1
- (void) dumpSumTriggerThreshold
{
    int width =81;
    NSLog(@"\n");
    uint32_t addr   = [self groupRegister:kTrigThreholdSumCh1Ch4Reg group:0];
    NSString* title = [NSString stringWithFormat:@"SUM FIR Trigger Threshold (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| group |  chan   |   Address  |  Trig   | HE Suppress |  CFD Cntrl | Trigger   |\n");
    NSLogMono(@"|       |         |            | Enabled |     Mode    |     Bits   | Threshold |\n");
    NSLogDivider(@"-",width);
    NSString* cfd[4] = {@"Disabled",@"Disabled",@"Zero Cross",@"50%"};
    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        addr   = [self groupRegister:kTrigThreholdSumCh1Ch4Reg group:group];
        uint32_t aValue = [self readLongFromAddress:addr];
        int c1 = group*4;
        int c2 = group*4+3;
        NSLogMono(@"|   %d   | %2d - %-2d | 0x%08x |%@|%@|%@| 0x%07x |\n",
                  group,
                  c1 ,
                  c2 ,
                  addr,
                  [(aValue>>31 & 0x1)?@"YES":@"NO" centered:9],
                  [(aValue>>30 & 0x1)?@"YES":@"NO" centered:13],
                  [cfd[aValue>>28 & 0x3] centered:12],
                  aValue & 0xFFFFFFF
                  );
        
    }
    
    NSLogDivider(@"=",width);
    NSLog(@"\n");
}

//6.27
- (void) dumpHeTriggerThreshold
{
    int width =70;
    NSLog(@"\n");
    uint32_t addr   = [self channelRegister:kHiEnergyTrigThresCh1Reg channel:0];
    NSString* title = [NSString stringWithFormat:@"FIR HE Trigger Threshold (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| chan |   Address  |  Both  | Int HE Trig |  Int Trig  | HE Trigger |\n");
    NSLogMono(@"|      |            |  Edges |  Out Pulse  |  Out Pulse | Threshold  |\n");
    NSLogDivider(@"-",width);
    NSString* intTrigOut[4] = {@"Internal",@"HE Trigger",@"Pileup",@"Reserved"};
    int i;
    for(i=0;i<kNumSIS3316Channels;i++){
        addr   = [self channelRegister:kHiEnergyTrigThresCh1Reg channel:i];
        uint32_t aValue = [self readLongFromAddress:addr];
        NSLogMono(@"|  %2d  | 0x%08x |%@|%@|%@|  0x%07x |\n",
                  i ,
                  addr,
                  [(aValue>>31 & 0x1)?@"YES":@"NO" centered:8],
                  [(aValue>>30 & 0x1)?@"YES":@"NO" centered:13],
                  [intTrigOut[aValue>>28 & 0x3] centered:12],
                  aValue & 0xFFFFFFF
                  );
        
    }
    
    NSLogDivider(@"=",width);
    NSLog(@"\n");
}

//6.27.1
- (void) dumpHeSumTriggerThreshold
{
    int width =81;
    NSLog(@"\n");
    uint32_t addr   = [self groupRegister:kHiETrigThresSumCh1Ch4Reg group:0];
    NSString* title = [NSString stringWithFormat:@"SUM FIR HE Trigger Threshold (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| group |  chan   |   Address  |  Both  | Int HE Trig |  Int Trig  | HE Trigger |\n");
    NSLogMono(@"|       |         |            |  Edges |  Out Pulse  |  Out Pulse | Threshold  |\n");
    NSLogDivider(@"-",width);
    NSString* intTrigOut[4] = {@"Internal",@"HE Trigger",@"Pileup",@"Reserved"};
    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        addr   = [self groupRegister:kHiETrigThresSumCh1Ch4Reg group:group];
        uint32_t aValue = [self readLongFromAddress:addr];
        int c1 = group*4;
        int c2 = group*4+3;
        NSLogMono(@"|   %d   | %2d - %-2d | 0x%08x |%@|%@|%@|  0x%07x |\n",
                  group,
                  c1 ,
                  c2 ,
                  addr,
                  [(aValue>>31 & 0x1)?@"YES":@"NO" centered:8],
                  [(aValue>>30 & 0x1)?@"YES":@"NO" centered:13],
                  [intTrigOut[aValue>>28 & 0x3] centered:12],
                  aValue & 0xFFFFFFF
                  );
        
    }
    
    NSLogDivider(@"=",width);
    NSLog(@"\n");
}

//6.28
- (void) dumpStatisticCounterMode
{
    int width =48;
    NSLog(@"\n");
    uint32_t addr   = [self groupRegister:kTrigStatCounterModeCh1Ch4Reg group:0];
    NSString* title = [NSString stringWithFormat:@"Trig Statistic Counter Mode (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| group |  chan   |   Address  |   Mode  |\n");
    NSLogDivider(@"-",42);
    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        addr   = [self groupRegister:kTrigStatCounterModeCh1Ch4Reg group:group];
        uint32_t aValue = [self readLongFromAddress:addr];
        int c1 = group*4;
        int c2 = group*4+3;
        NSLogMono(@"|   %d   | %2d - %-2d | 0x%08x |%@|\n",
                  group,
                  c1 ,
                  c2 ,
                  addr,
                  [(aValue & 0x1)?@"Actual":@"Latched" centered:9]
                  );
        
    }
    
    NSLogDivider(@"=",42);
    NSLog(@"\n");
}
//6.29
- (void) dumpPeakChargeConfig
{
    int width =64;
    NSLog(@"\n");
    uint32_t addr   = [self groupRegister:kPeakChargeConfigReg group:0];
    NSString* title = [NSString stringWithFormat:@"Peak/Charge Config (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| group |  chan   |   Address  |    Mode  |   Ave   | Baseline |\n");
    NSLogMono(@"|       |         |            |          | Samples |   Delay  |\n");
    NSLogDivider(@"-",width);
    NSString* mode[4] = {@"32",@"64",@"128",@"256"};
    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        addr   = [self groupRegister:kPeakChargeConfigReg group:group];
        uint32_t aValue = [self readLongFromAddress:addr];
        int c1 = group*4;
        int c2 = group*4+3;
        NSLogMono(@"|   %d   | %2d - %-2d | 0x%08x |%@|%@|   0x%03x  |\n",
                  group,
                  c1 ,
                  c2 ,
                  addr,
                  [(aValue & 0x1)?@"Enabled":@"Disabled" centered:10],
                  [mode[(aValue>>28 & 0x3)] centered:9],
                  aValue>>16 & 0xFFF
                  );
        
    }
    
    NSLogDivider(@"=",width);
    NSLog(@"\n");
}

//6.30
- (void) dumpExtededRawDataBufferConfig
{
    int width =44;
    NSLog(@"\n");
    uint32_t addr   = [self groupRegister:kExtRawDataBufConfigReg group:0];
    NSString* title = [NSString stringWithFormat:@"Extended Raw Buffer Len (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| group |  chan   |   Address  |   Value   |\n");
    NSLogDivider(@"-",width);
    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        addr   = [self groupRegister:kExtRawDataBufConfigReg group:group];
        uint32_t aValue = [self readLongFromAddress:addr];
        int c1 = group*4;
        int c2 = group*4+3;
        NSLogMono(@"|   %d   | %2d - %-2d | 0x%08x | 0x%07x |\n",
                  group,
                  c1 ,
                  c2 ,
                  addr,
                  aValue & 0x1FFFFFF
                  );
        
    }
    
    NSLogDivider(@"=",width);
    NSLog(@"\n");
}

//6.31
- (void) dumpAccumulatorGates
{
    int width =87;
    NSLog(@"\n");
    uint32_t addr1   = [self groupRegister:kAccGate1ConfigReg group:0];
    uint32_t addr2   = [self groupRegister:kAccGate2ConfigReg group:0];
    uint32_t addr3   = [self groupRegister:kAccGate3ConfigReg group:0];
    uint32_t addr4   = [self groupRegister:kAccGate4ConfigReg group:0];
    NSString* title = [NSString stringWithFormat:@"Accumulator Gates (0x%x,0x%x,0x%x,0x%x)",addr1,addr2,addr3,addr4];
    NSLogStartTable(title, width);
    NSLogMono(@"| group |  chan   |     Gate1      |     Gate2      |     Gate3      |     Gate4      |\n");
    NSLogMono(@"|       |         | Start |   Len  | Start |   Len  | Start |   Len  | Start |   Len  |\n");
    NSLogDivider(@"-",width);
    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        addr1   = [self groupRegister:kAccGate1ConfigReg group:group];
        addr2   = [self groupRegister:kAccGate2ConfigReg group:group];
        addr3   = [self groupRegister:kAccGate3ConfigReg group:group];
        addr4   = [self groupRegister:kAccGate4ConfigReg group:group];
        uint32_t aValue1 = [self readLongFromAddress:addr1];
        uint32_t aValue2 = [self readLongFromAddress:addr2];
        uint32_t aValue3 = [self readLongFromAddress:addr3];
        uint32_t aValue4 = [self readLongFromAddress:addr4];
        int c1 = group*4;
        int c2 = group*4+3;
        NSLogMono(@"|   %d   | %2d - %-2d | 0x%03x | 0x%04x | 0x%03x | 0x%04x | 0x%03x | 0x%04x | 0x%03x | 0x%04x |\n",
                  group,
                  c1 ,
                  c2 ,
                  aValue1>>16 & 0x1FF,
                  aValue1 & 0xFFFF,
                  aValue2>>16 & 0x1FF,
                  aValue2 & 0xFFFF,
                  aValue3>>16 & 0x1FF,
                  aValue3 & 0xFFFF,
                  aValue4>>16 & 0x1FF,
                  aValue4 & 0xFFFF
                  );
        
    }
    
    NSLogDivider(@"=",width);
    NSLog(@"\n");
    addr1   = [self groupRegister:kAccGate5ConfigReg group:0];
    addr2   = [self groupRegister:kAccGate6ConfigReg group:0];
    addr3   = [self groupRegister:kAccGate7ConfigReg group:0];
    addr4   = [self groupRegister:kAccGate8ConfigReg group:0];
    title = [NSString stringWithFormat:@"Accumulator Gates (0x%x,0x%x,0x%x,0x%x)",addr1,addr2,addr3,addr4];
    NSLogStartTable(title, width);
    NSLogMono(@"| group |  chan   |     Gate5      |     Gate6      |     Gate7      |     Gate8      |\n");
    NSLogMono(@"|       |         | Start |   Len  | Start |   Len  | Start |   Len  | Start |   Len  |\n");
    NSLogDivider(@"-",width);
    for(group=0;group<kNumSIS3316Groups;group++){
        addr1   = [self groupRegister:kAccGate5ConfigReg group:group];
        addr2   = [self groupRegister:kAccGate6ConfigReg group:group];
        addr3   = [self groupRegister:kAccGate7ConfigReg group:group];
        addr4   = [self groupRegister:kAccGate8ConfigReg group:group];
        uint32_t aValue1 = [self readLongFromAddress:addr1];
        uint32_t aValue2 = [self readLongFromAddress:addr2];
        uint32_t aValue3 = [self readLongFromAddress:addr3];
        uint32_t aValue4 = [self readLongFromAddress:addr4];
        int c1 = group*4;
        int c2 = group*4+3;
        NSLogMono(@"|   %d   | %2d - %-2d | 0x%03x | 0x%04x | 0x%03x | 0x%04x | 0x%03x | 0x%04x | 0x%03x | 0x%04x |\n",
                  group,
                  c1 ,
                  c2 ,
                  aValue1>>16 & 0x1FF,
                  aValue1 & 0xFFFF,
                  aValue2>>16 & 0x1FF,
                  aValue2 & 0xFFFF,
                  aValue3>>16 & 0x1FF,
                  aValue3 & 0xFFFF,
                  aValue4>>16 & 0x1FF,
                  aValue4 & 0xFFFF
                  );
        
    }
    
    NSLogDivider(@"=",width);
    NSLog(@"\n");
    
}

//6.15 External Veto/Gate Delay register
- (void) readVetoGateDelayReg:(BOOL)verbose
{
    uint32_t addr   = [self singleRegister:kExternalVetoGateDelayReg];
    uint32_t result =  [self readLongFromAddress:addr] & 0xFFFF;
    
    if(verbose){
        int width = 40;
        NSLog(@"\n");
        NSString* title = [NSString stringWithFormat:@"Ext Veto/Gate Delay (0x%x)",addr];
        NSLogStartTable(title, width);
        NSLogMono(@"|                0x%04x                |\n",result);
        NSLogDivider(@"=",width);
        NSLog(@"\n");
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316SerialNumberChanged object:self];
}
//6.16 Programmable Clock I2C registers

//- (unsigned short) hsDiv
//{
//    return hsDiv;
//}
//
//- (void) setHsDiv:(unsigned short)aValue
//{
//    [[[self undoManager] prepareWithInvocationTarget:self] setHsDiv:hsDiv];
//    if(aValue==0)aValue = 4;
//    else if(aValue>11)aValue = 11;
//    hsDiv = aValue;
//    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316HsDivChanged object:self];
//}
//- (unsigned short) n1Div;
//{
//    return n1Div;
//}
//
//- (void) setN1Div:(unsigned short)aValue
//{
//    [[[self undoManager] prepareWithInvocationTarget:self] setN1Div:n1Div];
//    if(aValue<2)aValue = 2;
//    else if(aValue>126)aValue = 126;
//    n1Div = aValue/2*2;
//    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316N1DivChanged object:self];
//}

//6.17 ADC Sample Clock distribution control register (0x50)
- (int32_t) clockSource
{
    return clockSource;
}

- (void) setClockSource:(int32_t)aClockSource
{
    if(aClockSource<0)aClockSource = 0;
    if(aClockSource>0x3)aClockSource = 0x3;
    [[[self undoManager] prepareWithInvocationTarget:self] setClockSource:clockSource];
    clockSource = aClockSource;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316ClockSourceChanged object:self];
}

- (void) writeClockSource
{
    uint32_t aValue = clockSource;
    [self writeLong:aValue toAddress:[self singleRegister:kAdcSampleClockDistReg]];
    if(clockSource==0)[ORTimer delay:10*1E-3]; //required to let clock stablize
}

- (void) readClockSource:(BOOL)verbose
{
    NSString* clockSourceString[4] = {
        @"Internal",
        @"VXS",
        @"External from LVDS",
        @"External from NIM "
    };

    uint32_t addr   = [self singleRegister:kAdcSampleClockDistReg];
    uint32_t result =  [self readLongFromAddress:addr] & 0x3;
    
    if(verbose){
        int width = 38;
        NSLog(@"\n");
        NSString* title = [NSString stringWithFormat:@"Clock Distribution (0x%x)",addr];
        NSLogStartTable(title, width);
        NSLogMono(@"|%@|\n",[clockSourceString[result] centered:36]);
        NSLogDivider(@"=",width);
        NSLog(@"\n");
    }
}

//6.18 External NIM Clock Multiplier SPI register

//6.19 FP-Bus control register
- (void) readFpBusControl:(BOOL)verbose
{
    uint32_t addr   = [self singleRegister:kFPBusControlReg];
    uint32_t result = [self readLongFromAddress:addr];
    
    if(verbose){
        NSString* mux;
        if(result>>5 & 0x1) mux = @"Onboard Osc ";
        else                mux = @"Ext Clk From NIM";
        NSString* en        = (result>>4 & 0x1)?@"Enabled":@"Disabled";
        NSString* fpStatus  = (result>>4 & 0x1)?@"Enabled":@"Disabled";
        NSString* fpControl = (result>>0 & 0x1)?@"Enabled":@"Disabled";
        int width = 56;
        NSLog(@"\n");
        NSString* title = [NSString stringWithFormat:@"FP-Bus Control (0x%x)",addr];
        NSLogStartTable(title, width);
        NSLogMono(@"| Sample Clk Out Mux | Clk Out | Status Out | Ctrl Out |\n");
        NSLogDivider(@"-",width);
        NSLogMono(@"|%@|%@|%@|%@|\n",[mux centered:20],[en centered:9],[fpStatus centered:12],[fpControl centered:10]);
        NSLogDivider(@"=",width);
        NSLog(@"\n");
    }
}
//6.20 NIM Input Control/Status register
- (int32_t)  nimControlStatusMask                     {return nimControlStatusMask;         }

- (void) setNIMControlStatusMask:(uint32_t)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNIMControlStatusMask:nimControlStatusMask];
    nimControlStatusMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316NIMControlStatusChanged object:self];
}

- (void) setNIMControlStatusBit:(uint32_t)aChan withValue:(BOOL)aValue
{
    int32_t aMask                      = nimControlStatusMask;
    if(aValue)                      aMask |= (0x1<<aChan);
    else                            aMask &= ~(0x1<<aChan);
    [self setNIMControlStatusMask:aMask];
}

- (void) writeNIMControlStatus
{
    [self writeLong:nimControlStatusMask toAddress:[self singleRegister:kNimInControlReg]];
}

- (void) readNIMControlStatus:(BOOL)verbose
{
    uint32_t addr   = [self singleRegister:kNimInControlReg];
    uint32_t aValue =  [self readLongFromAddress:addr];
    
    if(verbose){
        NSString* nimControlStatusString[14] = {
            @"Input CI Enable",
            @"Input CI Invert",
            @"Input CI Level sensitive",
            @"Set NIM Input CI Function",
            @"Input TI as Trigger Enable",
            @"Input TI Invert",
            @"Input TI Level sensitive",
            @"Set NIM Input TI Function",
            @"Input UI as Timestamp Clear",
            @"Input UI Invert",
            @"Input UI Level sensitive",
            @"Set NIM Input UI Function",
            @"Input UI as Veto Enable",
            @"Input UI as PPS Enable"
        };
        int width = 44;
        NSLog(@"\n");
        NSString* title = [NSString stringWithFormat:@"NIM Control (0x%x)",addr];
        NSLogStartTable(title, width);
        NSLogMono(@"| Bit |           Function           | Set |\n");
        NSLogDivider(@"-",width);

        int i;
        for(i =0; i < 14; i++) {
            uint32_t theNIMControlStatus  = ((aValue >> (i)) & 0x1);
            NSLogMono(@"|  %2d | %@ | %@ |\n",i,[nimControlStatusString[i] leftJustified:28],theNIMControlStatus?@"YES":@" NO");
        }
        NSLogDivider(@"=",width);
        NSLog(@"\n");
    }
}

//6.21 Acquisition control/status register (0x60, read/write)

- (int32_t)  acquisitionControlMask                     {return acquisitionControlMask;         }
- (void) setAcquisitionControlMask:(uint32_t)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAcquisitionControlMask:acquisitionControlMask];
    acquisitionControlMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AcquisitionControlChanged object:self];
}

- (BOOL) addressThresholdFlag
{
    uint32_t aValue =  [self readLongFromAddress:[self singleRegister:kAcqControlStatusReg]];
    return (aValue >> 19) & 0x1;
}

- (BOOL) sampleLogicIsBusy
{
    uint32_t aValue =  [self readLongFromAddress:[self singleRegister:kAcqControlStatusReg]];
    return (aValue & (0x1<<18)) != 0;
}

- (void) writeAcquisitionRegister
{
    [self writeLong:acquisitionControlMask toAddress:[self singleRegister:kAcqControlStatusReg]];
}

- (uint32_t) readAcquisitionRegister:(BOOL)verbose
{
    uint32_t addr   = [self singleRegister:kAcqControlStatusReg];
    uint32_t aValue =  [self readLongFromAddress:addr];

    if(verbose){
        NSString* acquisitionString[32] = {
            @"Single Bank Mode (reserved)",
            @"Reserved",
            @"Reserved",
            @"Reserved",
            @"FP-Bus-In Control 1 as Trigger Enable ",
            @"FP-Bus-In Control 1 as Veto Enable",
            @"FP-Bus–In Control 2 Enable",
            @"FP-Bus-In Sample Control Enable",
            @"External Trigger function as Trigger Enable",
            @"External Trigger function as Veto Enable ",
            @"External Timestamp-Clear function Enable ",
            @"Local Veto function as Veto Enable",
            @"NIM Input TI as Switch Banks Enable",
            @"NIM Input UI as Switch Banks Enable",
            @"Feedback Selected Internal Trigger as Ext Trigger Enable",
            @"External Trigger Disable with Int Busy select",
            @"ADC Sample Logic Armed",
            @"ADC Sample Logic Armed On Bank2 flag",
            @"Sample Logic Busy (OR)",
            @"Memory Address Threshold flag (OR)",
            @"FP-Bus-In Status 1: Sample Logic busy",
            @"FP-Bus-In Status 2: Address Threshold flag",
            @"Sample Bank Swap Control with NIM Input TI/UI Logic Enabled",
            @"PPS Latch Bit",
            @"Sample Logic Busy Ch 1-4",
            @"Memory Address Threshold Flag Ch 1-4",
            @"Sample Logic Busy Ch 5-8",
            @"Memory Address Threshold Flag Ch 5-8",
            @"Sample Logic Busy Ch 9-12",
            @"Memory Address Threshold Flag Ch 9-12",
            @"Sample Logic Busy Ch 13-16",
            @"Memory Address Threshold Flag Ch 13-16",
        };
        int width = 75;
        NSLog(@"\n");
        NSString* title = [NSString stringWithFormat:@"Acquistion Control (0x%x)",addr];
        NSLogStartTable(title, width);
        NSLogMono(@"| Bit |                           Function                          | Set |\n");
        NSLogDivider(@"-",width);
        
        int i;
        for(i =0; i < 32; i++) {
            uint32_t theBit  = ((aValue >> (i)) & 0x1);
            NSLogMono(@"|  %2d | %@ | %@ |\n",i,[acquisitionString[i] leftJustified:59],theBit?@"YES":@" NO");
        }
        NSLogDivider(@"=",width);
        NSLog(@"\n");

    }
    return aValue;
}

//6.22 Trigger Copincidence Lookup Table Control
- (uint32_t) readTrigCoinLUControl:(BOOL)verbose
{
    uint32_t addr = [self singleRegister:kTrigCoinLUTControlReg];
    uint32_t aValue =  [self readLongFromAddress:addr];
    
    if(verbose){
        NSString* name[3] = {
            @"Table 2 Out Pulse Len",
            @"Table 1 Out Pulse Len",
            @"Status Clear Busy",
        };
        int width = 41;
        NSLog(@"\n");
        NSString* title = [NSString stringWithFormat:@"Trig Coin LU Table (0x%x)",addr];
        NSLogStartTable(title, width);
        NSLogMono(@"| Bits |          Name         | Value  |\n");
        NSLogDivider(@"-",width);
        
        NSLogMono(@"| 0-7  | %@ | 0x%04x |\n",[name[0] leftJustified:21],(aValue>>0&0xf));
        NSLogMono(@"| 8-15 | %@ | 0x%04x |\n",[name[1] leftJustified:21],(aValue>>8&0xf));
        NSLogMono(@"|  31  | %@ | 0x%04x |\n",[name[2] leftJustified:21],(aValue>>31&0x1));
        NSLogDivider(@"=",width);
        NSLog(@"\n");
        
    }
    return aValue;
}

//6.23 Trigger Copincidence Lookup Table Address
- (uint32_t) readTrigCoinLUAddress:(BOOL)verbose
{
    uint32_t addr = [self singleRegister:kTrigCoinLUTAddReg];
    uint32_t aValue =  [self readLongFromAddress:addr];
    
    if(verbose){
        NSString* name[2] = {
            @"Table R/W Address",
            @"Table Chan Trig Mask",
        };
        int width = 46;
        NSLog(@"\n");
        NSString* title = [NSString stringWithFormat:@"Trig Coin LU Addr (0x%x)",addr];
        NSLogStartTable(title, width);
        NSLogMono(@"| Bits  |          Name         |   Value    |\n");
        NSLogDivider(@"-",width);
        
        NSLogMono(@"| 0-15  | %@ | 0x%08x |\n",[name[0] leftJustified:21],(aValue>>0&0xff));
        NSLogMono(@"| 16-31 | %@ | 0x%08x |\n",[name[1] leftJustified:21],(aValue>>16&0xff));
        NSLogDivider(@"=",width);
        NSLog(@"\n");
        
    }
    return aValue;
}
//6.24 Trig Coin LU Table Data
- (uint32_t) readTrigCoinLUData:(BOOL)verbose
{
    uint32_t addr   = [self singleRegister:kTrigCoinLUTAddReg];
    uint32_t aValue =  [self readLongFromAddress:addr];
    
    if(verbose){
        NSString* name[2] = {
            @"Table 1 Coin Validation",
            @"Table 2 Coin Validation",
        };
        int width = 42;
        NSLog(@"\n");
        NSString* title = [NSString stringWithFormat:@"Trig Coin LU Addr (0x%x)",addr];
        NSLogStartTable(title, width);
        NSLogMono(@"| Bit |           Name          | Value |\n");
        NSLogDivider(@"-",width);
        NSLogMono(@"|  0  | %@ |   0x%01x |\n",[name[0] leftJustified:21],(aValue>>0&0x1));
        NSLogMono(@"|  1  | %@ |   0x%01x |\n",[name[1] leftJustified:21],(aValue>>16&0x1));
        NSLogDivider(@"=",width);
        NSLog(@"\n");
        
    }
    return aValue;
}

- (uint32_t) internalGateLen:(unsigned short)aGroup;
{
    if(aGroup<kNumSIS3316Groups) return internalGateLen[aGroup];
    else                         return 0;
}

- (void) setInternalGateLen:(unsigned short)aGroup withValue:(uint32_t)aValue
{
    if(aGroup<kNumSIS3316Groups){
        [[[self undoManager] prepareWithInvocationTarget:self] setInternalGateLen:aGroup withValue:internalGateLen[aGroup]];
        internalGateLen[aGroup] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316InternalGateLenChanged object:self];
    }
}

- (uint32_t) internalCoinGateLen:(unsigned short)aGroup;
{
    if(aGroup<kNumSIS3316Groups)return internalCoinGateLen[aGroup];
    else                         return 0;
}

- (void) setInternalCoinGateLen:(unsigned short)aGroup withValue:(uint32_t)aValue
{
    if(aGroup<kNumSIS3316Groups){
        [[[self undoManager] prepareWithInvocationTarget:self] setInternalCoinGateLen:aGroup withValue:internalCoinGateLen[aGroup]];
        internalCoinGateLen[aGroup] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316InternalCoinGateLenChanged object:self];
    }
}

//6.25 LEMO Out “CO” Select register
- (uint32_t) lemoCoMask { return lemoCoMask; }
- (void) setLemoCoMask:(uint32_t)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoCoMask:lemoCoMask];
    lemoCoMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316LemoCoMaskChanged object:self];
}

- (void) writeLemoCoMask
{
    [self writeLong:lemoCoMask toAddress: [self singleRegister:kLemoOutCOSelectReg]];
}
- (uint32_t) readLemoOutCOSelect:(BOOL)verbose
{
    uint32_t addr = [self singleRegister:kLemoOutCOSelectReg];
    uint32_t aValue =  [self readLongFromAddress:addr];
    
    if(verbose){
        NSString* name[9] = {
            @"Sample Clock",
            @"Int HE Trig Stretched Pulse ch0-3",
            @"Int HE Trig Stretched Pulse ch4-7",
            @"Int HE Trig Stretched Pulse ch8-11",
            @"Int HE Trig Stretched Pulse ch12-16",
            @"Bank Swap Cntrl NIM In TI/UI Logic",
            @"Sample Logic Bankx Armed",
            @"Sample Logic Bank2 Flag",
            @"Set",
        };
        int bit[9] ={0,16,17,18,19,20,21,22,30};
        int width = 58;
        NSLog(@"\n");
        NSString* title = [NSString stringWithFormat:@"LEMO Out CO Select (0x%x)",addr];
        NSLogStartTable(title, width);
        NSLogMono(@"| Bit |               Functtion             |    Value   |\n");
        NSLogDivider(@"-",width);
        
        int i;
        for(i =0; i < 9; i++) {
            uint32_t theBit  = ((aValue >> bit[i]) & 0x1);
            if(i != 8)NSLogMono(@"|  %2d | %@ | %@ |\n",bit[i],[name[i] leftJustified:35],[theBit?@"Selected":@" -- " centered:10]);
            else      NSLogMono(@"|  %2d | %@ | %@ |\n",bit[i],[name[i] leftJustified:35],[theBit?@"Set     ":@" -- " centered:10]);
        }
        NSLogDivider(@"=",width);
        NSLog(@"\n");
        
    }
    return aValue;
}
//6.26 LEMO Out “TO” Select register
- (uint32_t) lemoToMask { return lemoToMask; }
- (void) setLemoToMask:(uint32_t)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoToMask:lemoToMask];
    lemoToMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316LemoToMaskChanged object:self];
}

- (void) writeLemoToMask
{
    [self writeLong:lemoToMask toAddress: [self singleRegister:kLemoOutTOSelectReg]];
}
- (uint32_t) readLemoOutTOSelect:(BOOL)verbose
{
    uint32_t addr = [self singleRegister:kLemoOutTOSelectReg];
    uint32_t aValue =  [self readLongFromAddress:addr];
    
    if(verbose){
        NSString* name[27] = {
            @"Int Trig Stretched Pulse ch0",
            @"Int Trig Stretched Pulse ch1",
            @"Int Trig Stretched Pulse ch2",
            @"Int Trig Stretched Pulse ch3",
            @"Int Trig Stretched Pulse ch4",
            @"Int Trig Stretched Pulse ch5",
            @"Int Trig Stretched Pulse ch6",
            @"Int Trig Stretched Pulse ch7",
            @"Int Trig Stretched Pulse ch8",
            @"Int Trig Stretched Pulse ch9",
            @"Int Trig Stretched Pulse ch10",
            @"Int Trig Stretched Pulse ch11",
            @"Int Trig Stretched Pulse ch12",
            @"Int Trig Stretched Pulse ch13",
            @"Int Trig Stretched Pulse ch14",
            @"Int Trig Stretched Pulse ch15",
            @"Int Sum-Trig Stretched Pulse 0-3",
            @"Int Sum-Trig Stretched Pulse 4-7",
            @"Int Sum-Trig Stretched Pulse 8-11",
            @"Int Sum-Trig Stretched Pulse 12-15",
            @"Sample Bank Swap Cntrl NIM TI/UI Logic",
            @"Sample Logic Bankx Armed",
            @"Sample Logic Bank2 flag",
            @"LU Table 1 Coin Stretched OUt Pulse",
            @"Ext Trig to ADC FPGA ",
            @"Set",
            @"Select and Generate Pulse",
        };
        int bit[27] ={0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,24,25,30,31};
        int width = 61;
        NSLog(@"\n");
        NSString* title = [NSString stringWithFormat:@"LEMO Out TO Select (0x%x)",addr];
        NSLogStartTable(title, width);
        NSLogMono(@"| Bit |                Functtion               |    Value   |\n");
        NSLogDivider(@"-",width);
        
        int i;
        for(i =0; i < 27; i++) {
            uint32_t theBit  = ((aValue >> bit[i]) & 0x1);
            if(bit[i] != 30)NSLogMono(@"|  %2d | %@ | %@ |\n",bit[i],[name[i] leftJustified:38],[theBit?@"Selected":@" -- " centered:10]);
            else      NSLogMono(@"|  %2d | %@ | %@ |\n",bit[i],[name[i] leftJustified:38],[theBit?@"Set":@" -- " centered:10]);
        }
        NSLogDivider(@"=",width);
        NSLog(@"\n");
        
    }
    return aValue;
}
//6.27 LEMO Out “UO” Select register
- (uint32_t) lemoUoMask { return lemoUoMask; }
- (void) setLemoUoMask:(uint32_t)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoUoMask:lemoUoMask];
    lemoUoMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316LemoUoMaskChanged object:self];
}

- (void) writeLemoUoMask
{
    [self writeLong:lemoUoMask toAddress: [self singleRegister:kLemoOutUOSelectReg]];
}
- (uint32_t) readLemoOutUOSelect:(BOOL)verbose
{
    uint32_t addr = [self singleRegister:kLemoOutUOSelectReg];
    uint32_t aValue =  [self readLongFromAddress:addr];
    
    if(verbose){
        NSString* name[17] = {
            @"Sample Logic Bankx Armed",
            @"Sample Logic Busy",
            @"Address Thres Flag",
            @"Sample Event Active",
            @"Sample Logic Ready (Gate)",
            @"Sample Logic NOT Ready (Veto)",
            @"OR Int HE-Trig Stretchd Pulse ch0-3",
            @"OR Int HE-Trig Stretchd Pulse ch4-7",
            @"OR Int HE-Trig Stretchd Pulse ch8-11",
            @"OR Int HE-Trig Stretchd Pulse ch12-15",
            @"Sample Bankx Swap Cntrl NIM TI/UI Logic",
            @"Sample Logic Bankx Armed",
            @"Sample Logic Bank2 Flag",
            @"LU Table 2 Coin stretched Out Pulse",
            @"Prescaler Output Pulse",
            @"Set",
            @"Select and Generate Pulse",
        };
        int bit[17] ={1,2,3,4,8,9,16,17,18,19,20,21,22,24,25,30,31};
        int width = 62;
        NSLog(@"\n");
        NSString* title = [NSString stringWithFormat:@"LEMO Out UO Select (0x%x)",addr];
        NSLogStartTable(title, width);
        NSLogMono(@"| Bit |                 Function                |    Value   |\n");
        NSLogDivider(@"-",width);
        
        int i;
        for(i =0; i < 17; i++) {
            uint32_t theBit  = ((aValue >> bit[i]) & 0x1);
            if(bit[i] != 30)NSLogMono(@"|  %2d | %@ | %@ |\n",bit[i],[name[i] leftJustified:39],[theBit?@"Selected":@" -- " centered:10]);
            else            NSLogMono(@"|  %2d | %@ | %@ |\n",bit[i],[name[i] leftJustified:39],[theBit?@"Set":@" -- " centered:10]);
        }
        NSLogDivider(@"=",width);
        NSLog(@"\n");
        
    }
    return aValue;
}
//6.28 Internal Trigger Feedback Select register
- (uint32_t) readIntTrigFeedBackSelect:(BOOL)verbose
{
    uint32_t addr = [self singleRegister:kIntTrigFeedBackSelReg];
    uint32_t aValue =  [self readLongFromAddress:addr];
    
    if(verbose){
        NSString* name[21] = {
            @"Internal Trig Stretched Pulse Ch0",
            @"Internal Trig Stretched Pulse Ch1",
            @"Internal Trig Stretched Pulse Ch2",
            @"Internal Trig Stretched Pulse Ch3",
            @"Internal Trig Stretched Pulse Ch4",
            @"Internal Trig Stretched Pulse Ch5",
            @"Internal Trig Stretched Pulse Ch6",
            @"Internal Trig Stretched Pulse Ch7",
            @"Internal Trig Stretched Pulse Ch8",
            @"Internal Trig Stretched Pulse Ch9",
            @"Internal Trig Stretched Pulse Ch10",
            @"Internal Trig Stretched Pulse Ch11",
            @"Internal Trig Stretched Pulse Ch12",
            @"Internal Trig Stretched Pulse Ch13",
            @"Internal Trig Stretched Pulse Ch14",
            @"Internal Trig Stretched Pulse Ch15",
            @"Internal SUM-Trig Stretched Pulse Ch0-3",
            @"Internal SUM-Trig Stretched Pulse Ch4-7",
            @"Internal SUM-Trig Stretched Pulse Ch8-11",
            @"Internal SUM-Trig Stretched Pulse Ch12-15",
            @"LU Table 1 Coin Stretched Output Pulse",
         };
        int bit[21] ={0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,24};
        int width = 60;
        NSLog(@"\n");
        NSString* title = [NSString stringWithFormat:@"Internal Trig Feedback Select (0x%x)",addr];
        NSLogStartTable(title, width);
        NSLogMono(@"| Bit |                   Function                 |  Set  |\n");
        NSLogDivider(@"-",width);
        
        int i;
        for(i =0; i < 21; i++) {
            uint32_t theBit  = ((aValue >> bit[i]) & 0x1);
            NSLogMono(@"|  %2d | %@ | %@ |\n",bit[i],[name[i] leftJustified:42],[theBit?@"X":@"-" centered:5]);
        }
        NSLogDivider(@"=",width);
        NSLog(@"\n");
        
    }
    return aValue;
}
//6.29 ADC FPGA Data Transfer Control registers

//6.30 ADC FPGA Data Transfer Status registers
- (void) dumpFPGADataTransferStatus
{
    
    int width = 94;
    NSLog(@"\n");
    uint32_t addr = [self singleRegister:kAdcCh1_Ch4DataStatusReg];
    NSString* title = [NSString stringWithFormat:@"Internal Trig Feedback Select (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| Channels | Transfer Address | Pending | Max Pending | FIFO Almost Full |  Direction | Busy |\n");
    NSLogDivider(@"-",width);
    int i;
    for(i=0;i<4;i++){
        uint32_t addr = [self singleRegister:kAdcCh1_Ch4DataStatusReg + i*4];
        uint32_t aValue =  [self readLongFromAddress:addr];
        
        NSLogMono(@"|  %2d -%2d  |    0x%07x    |%@|%@|%@|%@|%@|\n",
                  i*4,i*4+3,
                  aValue&0x3FFF,
                  [aValue>>26&0x1 ? @"None":@"Yes"            centered:10],//pending
                  [aValue>>27&0x1 ? @"Yes":@"No"              centered:13],//max
                  [aValue>>28&0x1 ? @"Yes":@"No"              centered:18],//almost full
                  [aValue>>30&0x1 ? @"FPGA->Mem":@"Mem->FPGA" centered:12],//direction
                  [aValue>>31&0x1 ? @"YES":@"NO"              centered:6] //busy
                  );
        
    }
    NSLogDivider(@"=",width);
    NSLog(@"\n");
}
//pg 119 and on. section 2

//6.1 VME FPGA – ADC FPGA Data Link Status register (page 119 and on)
- (uint32_t) readVmeFpgaAdcDataLinkStatus:(BOOL)verbose
{
    uint32_t addr = [self singleRegister:kAdcDataLinkStatusReg];
    uint32_t aValue =  [self readLongFromAddress:addr];
    
    if(verbose){
        NSString* name[32] = {
            @"ADC FPGA 1 : Hard Error",
            @"ADC FPGA 1 : Soft Error",
            @"ADC FPGA 1 : Frame Error",
            @"ADC FPGA 1 : Chan up Error",
            @"ADC FPGA 1 : Lane up Error",
            @"ADC FPGA 1 : Hard Error Latch",
            @"ADC FPGA 1 : Soft Error Latch",
            @"ADC FPGA 1 : Frame Error Latch",
            @"ADC FPGA 2 : Hard Error",
            @"ADC FPGA 2 : Soft Error",
            @"ADC FPGA 2 : Frame Error",
            @"ADC FPGA 2 : Chan up Error",
            @"ADC FPGA 2 : Lane up Error",
            @"ADC FPGA 2 : Hard Error Latch",
            @"ADC FPGA 2 : Soft Error Latch",
            @"ADC FPGA 2 : Frame Error Latch",
            @"ADC FPGA 3 : Hard Error",
            @"ADC FPGA 3 : Soft Error",
            @"ADC FPGA 3 : Frame Error",
            @"ADC FPGA 3 : Chan up Error",
            @"ADC FPGA 3 : Lane up Error",
            @"ADC FPGA 3 : Hard Error Latch",
            @"ADC FPGA 3 : Soft Error Latch",
            @"ADC FPGA 3 : Frame Error Latch",
            @"ADC FPGA 4 : Hard Error",
            @"ADC FPGA 4 : Soft Error",
            @"ADC FPGA 4 : Frame Error",
            @"ADC FPGA 4 : Chan up Error",
            @"ADC FPGA 4 : Lane up Error",
            @"ADC FPGA 4 : Hard Error Latch",
            @"ADC FPGA 4 : Soft Error Latch",
            @"ADC FPGA 4 : Frame Error Latch"
        };
        int width = 51;
        NSLog(@"\n");
        NSString* title = [NSString stringWithFormat:@"VME FPGA-ADC Data Link Status (0x%x)",addr];
        NSLogStartTable(title, width);
        NSLogMono(@"| Bit |             Name               |   Flag   |\n");
        NSLogDivider(@"-",width);
        
        int i;
        for(i =0; i < 32; i++) {
            uint32_t theBit  = ((aValue >> i) & 0x1);
            NSLogMono(@"|  %2d | %@ |%@|\n",i,[name[i] leftJustified:30],[theBit?@"X":@"-" centered:10]);
        }
        NSLogDivider(@"=",width);
        NSLog(@"\n");
        
    }
    return aValue;
}
//6.2 ADC FPGA SPI BUSY Status register

//6.3 Prescaler Output Pulse Divider register
- (uint32_t) readPrescalerOutPulseDivider:(BOOL)verbose
{
    uint32_t addr   = [self singleRegister:kPrescalerOutDivReg];
    uint32_t aValue =  [self readLongFromAddress:addr];
    
    if(verbose){
        int width = 51;
        NSLog(@"\n");
        NSString* title = [NSString stringWithFormat:@"Prescaler Output Pulse Divider (0x%x)",addr];
        NSLogStartTable(title, width);
        NSString* s;
        if(aValue ==0) s = @"Disabled";
        else           s = [NSString stringWithFormat:@"0x%08X",aValue];
        NSLogMono(@" Divider Value : %@\n",s);
        NSLogDivider(@"=",width);
        NSLog(@"\n");
        
    }
    return aValue;
}
//6.4 Prescaler Output Pulse Length register
- (uint32_t) readPrescalerOutPulseLength:(BOOL)verbose
{
    uint32_t addr   = [self singleRegister:kPrescalerOutLenReg];
    uint32_t aValue =  [self readLongFromAddress:addr];
    
    if(verbose){
        int width = 51;
        NSLog(@"\n");
        NSString* title = [NSString stringWithFormat:@"Prescaler Output Pulse Length (0x%x)",addr];
        NSLogStartTable(title, width);
        NSString* s = [NSString stringWithFormat:@"0x%08X",aValue];
        NSLogMono(@" Output Pulse Length : %@\n",s);
        NSLogDivider(@"=",width);
        NSLog(@"\n");
    }
    return aValue;
}
//6.5 Channel 1 to 16 Internal Trigger Counters
- (void) dumpInternalTriggerCounters
{
    uint32_t offset[16] =
    {
        kChan1TrigCounterReg, kChan2TrigCounterReg,  kChan3TrigCounterReg,  kChan4TrigCounterReg,
        kChan5TrigCounterReg, kChan6TrigCounterReg,  kChan7TrigCounterReg,  kChan8TrigCounterReg,
        kChan9TrigCounterReg, kChan10TrigCounterReg, kChan11TrigCounterReg, kChan12TrigCounterReg,
        kChan13TrigCounterReg ,kChan14TrigCounterReg,kChan15TrigCounterReg, kChan16TrigCounterReg
    };
    int width = 46;
    NSLog(@"\n");
    uint32_t addr   = [self singleRegister:kChan1TrigCounterReg];
    NSString* title = [NSString stringWithFormat:@"Internal Trigger Counters (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| chan |   Address  |    Count   |\n");
    NSLogDivider(@"-",34);
    int i;
    for(i=0;i<16;i++){
        uint32_t aValue =  [self readLongFromAddress:[self singleRegister:offset[i]]];
        NSLogMono(@"| %4d | 0x%08x | 0x%08x |\n",i,[self singleRegister:offset[i]],aValue);
    }
    NSLogDivider(@"=",34);
    NSLog(@"\n");
}

//6.6 ADC Input tap delay registers
- (void) writeTapDelayRegister
{
    uint32_t aValue = 0x7F;
    aValue |= (0x3<<8);
    int iadc;
    for (iadc=0;iadc<kNumSIS3316Groups;iadc++) {
        [self writeLong:aValue toAddress:[self groupRegister:kAdcInputTapDelayReg group:iadc]];
        uint32_t r = [self readLongFromAddress:[self groupRegister:kAdcInputTapDelayReg group:iadc]];
        NSLog(@"%d: 0x%08x\n",iadc,r);
    }
}

- (void) dumpTapDelayRegister
{
    int width = 87;
    NSLog(@"\n");
    NSLogStartTable([NSString stringWithFormat:@"Tap Delay Registers"], width);
    NSLogMono(@"|       |             | 1/2 Clock  |     | Clear Link | Ch3-Ch4 | Ch1-Ch2 | Tap Delay |\n");
    NSLogMono(@"| group |   Address   | Delay Bit  | Cal | Err Latch  | Select  | Select  |   Value   |\n");
    NSLogDivider(@"-",width);
    int iadc;
    for (iadc=0;iadc<kNumSIS3316Groups;iadc++) {
        uint32_t addr = [self groupRegister:kAdcInputTapDelayReg group:iadc];
        uint32_t aValue =  [self readLongFromAddress:addr];
        NSLogMono(@"| %4d  | 0x%08x |%@|%@|%@|%@|%@|    0x%02x   |\n",
                  iadc,
                  addr,
                  [(aValue>>12 & 0x1)?@"X":@"-"  centered:13],
                  [(aValue>>11 & 0x1)?@"X":@"-"  centered:5],
                  [(aValue>>10 & 0x1)?@"X":@"-"  centered:12],
                  [(aValue>> 9 & 0x1)?@"X":@"-"  centered:8],
                  [(aValue>> 8 & 0x1)?@"X":@"-"  centered:10],
                  (aValue>> 0 & 0xff)
                  );
    }
    NSLogDivider(@"=",width);
    NSLog(@"\n");
}

- (void) setSharing:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSharing:sharing];
    sharing = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316SharingChanged object:self];
}

- (int) sharing
{
    return sharing;
}


//6.7 ADC Gain and Termination Control register
- (unsigned short) gain
{
    return gain;
}

- (void) setGain:(unsigned short)aGain
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGain:gain];
    gain = aGain & 0x3;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316ModelGainChanged object:self];
}

- (unsigned short) termination
{
    return termination;
}

- (void) setTermination:(unsigned short)aTermination
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTermination:termination];
    termination = aTermination & 0x1;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316ModelTerminationChanged object:self];
}
- (void) dumpGainTerminationControl
{
    int width = 51;
    NSLog(@"\n");
    uint32_t addr   = [self groupRegister:kAdcGainTermCntrlReg group:0];
    NSString* title = [NSString stringWithFormat:@"Gain & Termination (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| group | chan |   Address  |  Gain | Termination |\n");
    NSLogDivider(@"-",width);
    NSString* gain[4] = {
        @"5 V",
        @"2 V",
        @"1.9 V",
        @"1.9 V"
    };
    NSString* term[2] = {@"1K Ohm",@"50 Ohm"};
    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        addr   = [self groupRegister:kAdcGainTermCntrlReg group:group];
        uint32_t aValue = [self readLongFromAddress:addr];
        int i;
        for(i=0;i<4;i++){
            int c1 = group*4 + i;
            NSLogMono(@"| %4d  |  %2d  | 0x%08x |%@|%@|\n",group,c1 ,addr,[gain[aValue >> (i*8) & 0x3] centered:7],[term[aValue >> ((i*8)+2) & 0x1] centered:13]);
        }
       if(group!=3) NSLogDivider(@"-",width);

    }
    
    NSLogDivider(@"=",width);
    NSLog(@"\n");
}
//6.8 ADC Offset (DAC) Control registers
- (unsigned short) dacOffset:(unsigned short)aGroup
{
    if(aGroup>=kNumSIS3316Groups) return 0;
    else return dacOffsets[aGroup]&0xffff;
}

- (void) setDacOffset:(unsigned short)aGroup withValue:(int)aValue
{
    if(aGroup>=kNumSIS3316Groups) return;
    if(aValue<0)aValue      = 0;
    if(aValue>0xffff)aValue = 0xFFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setDacOffset:aGroup withValue:[self dacOffset:aGroup]];
    dacOffsets[aGroup] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316DacOffsetChanged object:self];
}

- (void) writeDacRegisters
{
    //  set ADC offsets (DAC)
    //dacoffset[iadc] = 0x8000; //2V Range: -1 to 1V 0x8000, -2V to 0V 13000
    int iadc;
   for (iadc=0;iadc<kNumSIS3316Groups;iadc++) {
        [self writeLong:0x88f00001
              toAddress:[self groupRegister:kAdcOffsetDacCntrlReg group:iadc]]; // set internal Reference
        usleep(1);
        [self writeLong:0x82f00000  + ([self dacOffset:iadc] << 4)
              toAddress:[self groupRegister:kAdcOffsetDacCntrlReg group:iadc]];// clear error Latch bits
        usleep(1);
        [self writeLong:0xC0000000
              toAddress:[self groupRegister:kAdcOffsetDacCntrlReg group:iadc]]; // clear error Latch bits
        usleep(1);
    }
}

- (void) dumpAdcOffsetReadback
{
    int width = 45;
    NSLog(@"\n");
    uint32_t addr   = [self groupRegister:kAdcOffsetReadbackReg group:0];
    NSString* title = [NSString stringWithFormat:@"ADC Offset (DAC) (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| group |   chan  |   Address  |   Offset   |\n");
    NSLogDivider(@"-",width);
    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        addr   = [self groupRegister:kAdcOffsetReadbackReg group:group];
        uint32_t aValue = [self readLongFromAddress:addr];
        int c1 = group*4;
        int c2 = group*4+3;
        NSLogMono(@"| %4d  | %2d - %-2d | 0x%08x | 0x%08x |\n",group, c1,c2 ,addr,aValue  & 0xFFFF);
    }

    NSLogDivider(@"=",width);
    NSLog(@"\n");
}
//6.10 ADC SPI Control register

//6.11 ADC SPI Readback registers

//6.12 Event configuration registers
- (uint32_t) eventConfigMask             { return eventConfigMask;                        }
- (void) setEventConfigMask:(uint32_t)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEventConfigMask:eventConfigMask];
    eventConfigMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316EventConfigChanged object:self];
}

- (void) setEventConfigBit:(unsigned short)bit withValue:(BOOL)aValue
{
    if(bit == 0)aValue = !aValue;
    int32_t  aMask = eventConfigMask;
    if(aValue)      aMask |= (0x1<<bit);
    else            aMask &= ~(0x1<<bit);
    [self setEventConfigMask:aMask];
}

- (void) writeEventConfig
{
    int i;
    uint32_t valueToWrite = 0;
    for(i = 0; i < 4; i++) {
        valueToWrite |= (eventConfigMask << (i*8));
    }
    
    for(i = 0; i < 4; i++) {
        [self writeLong:valueToWrite toAddress:[self groupRegister:kEventConfigReg group:i]];
    }
}
    
- (void) readEventConfig:(BOOL)verbose
{
    NSString* eventConfigString[3] = {
        @"Input Invert Bit ",
        @"Internal Trigger Enable bit",
        @"External Trigger Enable bit",
    };
    
    if(verbose){
        NSLog(@"Reading EventConfig:\n");
    }
    
    uint32_t aValue =  [self readLongFromAddress:[self groupRegister:kEventConfigReg group:0]];

    int j;
    for(j =0; j < 3; j++) {
        if(verbose){
            uint32_t e1  = ((aValue >> j)   & 0x1);
            NSLog(@"%2d: %@ %@  \n",j, eventConfigString[j],e1?@"YES":@" NO");
        }
    }
    
}


//6.13 Extended Event configuration registers
- (BOOL) extendedEventConfigBit                 { return extendedEventConfigBit;}
- (void) setExtendedEventConfigBit:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setExtendedEventConfigBit:extendedEventConfigBit];
    extendedEventConfigBit = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316ExtendedEventConfigChanged object:self];
}

- (void) writeExtendedEventConfig
{
    int i;
    uint32_t valueToWrite = 0;
    for(i = 0; i < 4; i++) {
        valueToWrite |= extendedEventConfigBit << (i*8);
    }
    
    for(i = 0; i < 4; i++) {
        [self writeLong:valueToWrite toAddress:[self groupRegister:kExtEventConfigCh1Ch4Reg group:i]];
     }
}

- (void) readExtendedEventConfig:(BOOL)verbose
{
    uint32_t aValue =  [self readLongFromAddress:[self groupRegister:kExtEventConfigCh1Ch4Reg group:1]];
    
    if(verbose){
        uint32_t e1  = ((aValue >> 8)   & 0x1);
        NSLog(@"%2d: %@ \n",8, e1?@"Internal Pileup Trigger Enable     YES":@"Internal Pileup Trigger Enable     NO");
    }
}

//6.14 Channel Header ID registers

//6.15 End Address Threshold register
- (uint32_t) endAddress:(unsigned short)aGroup {if(aGroup<kNumSIS3316Groups)return endAddress[aGroup]; else return 0;}

- (void) setEndAddress:(unsigned short)aGroup withValue:(uint32_t)aValue
{
    if(aValue>0xFFFFFF)aValue = 0xFFFFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setEndAddress:aGroup withValue:endAddress[aGroup]];
    endAddress[aGroup] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName: ORSIS3316EndAddressChanged object:self userInfo:userInfo];
}

- (uint32_t) endAddressSuppressionMask { return endAddressSuppressionMask; }

- (void) setEndAddressSuppressionMask:(uint32_t)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEndAddressSuppressionMask:endAddressSuppressionMask];
    endAddressSuppressionMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316EndAddressSuppressionChanged object:self];
}

- (void) setEndAddressSuppressionBit:(unsigned short)aGroup withValue:(BOOL)aValue
{
    int32_t  aMask = endAddressSuppressionMask;
    if(aValue)      aMask |= (0x1<<aGroup);
    else            aMask &= ~(0x1<<aGroup);
    [self setEndAddressSuppressionMask:aMask];
}

- (void) writeEndAddress
{
    int i;
    for(i = 0; i <kNumSIS3316Groups; i++){
        uint32_t valueToWrite =   (endAddress[i]                 & 0xFFFFFF) |
                                     (((endAddressSuppressionMask>>i) & 0x1) << 31);

        [self writeLong:valueToWrite toAddress:[self groupRegister:kEndAddressThresholdReg group:i]];
    }
}

- (void) readEndAddress:(BOOL)verbose
{
    int i;
    if(verbose){
        NSLog(@"Reading EndAddress:\n");
    }
    for(i = 0; i < kNumSIS3316Groups; i++){
        uint32_t aValue =  [self readLongFromAddress:[self groupRegister:kEndAddressThresholdReg group:i]];
        if(verbose){
            uint32_t theEndAddress      = ((aValue)      & 0xFFFFFF) ;
            NSLog(@"%2d: 0x%06x\n ", i, theEndAddress);
        }
    }
}

//6.16 Active Trigger Gate Window Length registers
- (unsigned short) activeTrigGateWindowLen:(unsigned short)aGroup {
    if(aGroup<kNumSIS3316Groups)return activeTrigGateWindowLen[aGroup];
    else return 0;
}

- (void) setActiveTrigGateWindowLen:(unsigned short)aGroup withValue:(uint32_t)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue>0xffff)aValue = 0xffff;
    aValue &= ~0x0001;
    [[[self undoManager] prepareWithInvocationTarget:self] setActiveTrigGateWindowLen:aGroup withValue:[self activeTrigGateWindowLen:aGroup]];
    activeTrigGateWindowLen[aGroup] = aValue & 0xffff;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316ActiveTrigGateWindowLenChanged object:self userInfo:userInfo];
}

- (void) writeActiveTrigGateWindowLen
{
    int i;
    for(i = 0; i < kNumSIS3316Groups; i++) {
        uint32_t valueToWrite = (activeTrigGateWindowLen[i] & 0xffff);
        [self writeLong:valueToWrite toAddress:[self groupRegister:kActTriggerGateWindowLenReg group:i]];
    }
}

- (void) readActiveTrigGateWindowLen:(BOOL)verbose
{
    int i;
    if(verbose){
        NSLog(@"Reading Active Trigger Gate Window Length:\n");
        NSLog(@"(bit 0 not used)\n");
    }
    for(i=0; i < kNumSIS3316Groups; i++){
        uint32_t aValue =  [self readLongFromAddress:[self groupRegister:kActTriggerGateWindowLenReg group:i]];
        if(verbose){
            uint32_t gateLength = (aValue  & 0xffff) ;
            NSLog(@"%2d: 0x%08x\n", i, gateLength);
        }
    }
}

//6.17 Raw Data Buffer Configuration registers
- (uint32_t) rawDataBufferLen
{
    return rawDataBufferLen+1 & 0xfffe;
}

- (void) setRawDataBufferLen:(uint32_t)aValue
{
    aValue = aValue+1 & 0xfffe;
    if(aValue > 0xFFFe) aValue = 0xFFFe;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setRawDataBufferLen:[self rawDataBufferLen]];
    rawDataBufferLen=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316RawDataBufferLenChanged object:self];
}

- (uint32_t) rawDataBufferStart
{
    return rawDataBufferStart & 0xffff;
}

- (void) setRawDataBufferStart:(uint32_t)aValue
{
    if(aValue > 0xFFFF) aValue = 0xFFFF;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setRawDataBufferStart:[self rawDataBufferStart]];
    rawDataBufferStart=aValue;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316RawDataBufferStartChanged object:self];
}

- (void) writeRawDataBufferConfig
{
    int i;
    for(i = 0; i < kNumSIS3316Groups; i++) {
        uint32_t valueToWrite = ([self rawDataBufferLen] << 16) | ([self rawDataBufferStart] << 0);
        [self writeLong:valueToWrite toAddress:[self groupRegister:kRawDataBufferConfigReg group:i]];
    }
}


//6.16
- (void) dumpRawDataBufferConfig
{
    int width =60;
    NSLog(@"\n");
    uint32_t addr   = [self groupRegister:kRawDataBufferConfigReg group:0];
    NSString* title = [NSString stringWithFormat:@"Active Trig Gate Window (0x%x)",addr];
    NSLogStartTable(title, width);
    NSLogMono(@"| group |   chan    |   Address  |    Start   |    Length   |\n");
    NSLogDivider(@"-",width);
    
    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        addr   = [self groupRegister:kRawDataBufferConfigReg group:group];
        uint32_t aValue = [self readLongFromAddress:addr];
        int c1 = group*4;
        int c2 = group*4+3;
        NSLogMono(@"|   %d   |  %2d - %-2d  | 0x%08x | 0x%08x |  0x%08x |\n",
                  group,
                  c1 ,
                  c2 ,
                  addr,
                  aValue     & 0xFFFF,
                  aValue>>16 & 0xFFFF
                  );
        
    }
    
    NSLogDivider(@"=",width);
    NSLog(@"\n");
}
//6.18 Pileup Configuration registers
- (uint32_t)   pileUpWindowLength
{
    return pileUpWindowLength;
}

- (void) setPileUpWindow:(uint32_t)aValue
{
    aValue &= 0xFFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setPileUpWindow:pileUpWindowLength];
    pileUpWindowLength = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName: ORSIS3316PileUpWindowLengthChanged object:self];
}

- (uint32_t)   rePileUpWindowLength
{
    return rePileUpWindowLength;
}

- (void) setRePileUpWindow:(uint32_t)aValue
{
    aValue &= 0xFFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setRePileUpWindow:rePileUpWindowLength];
    rePileUpWindowLength = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName: ORSIS3316RePileUpWindowLengthChanged object:self];
}

- (void) writePileUpRegisters
{
    int group;
    for(group=0;group<kNumSIS3316Groups;group++){
        uint32_t aValue = rePileUpWindowLength<<16 | pileUpWindowLength;
        [self writeLong:aValue toAddress:[self groupRegister:kPileupConfigReg group:group]];
    }
}

//6.19 Pre Trigger Delay registers
- (unsigned short) preTriggerDelay:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return preTriggerDelay[aGroup];
}

- (void) setPreTriggerDelay:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<2)aValue = 2;
    if(aValue> 0x7FA)aValue = 0x7FA;
    aValue &= ~0x0001;
    [[[self undoManager] prepareWithInvocationTarget:self] setPreTriggerDelay:aGroup withValue:[self preTriggerDelay:aGroup]];
    preTriggerDelay[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316PreTriggerDelayChanged object:self userInfo:userInfo];
}

- (void) writePreTriggerDelays
{
    uint32_t preTriggerDelayPGBit = 0x1; //hardcoded for now
    int i;
    for(i = 0; i < kNumSIS3316Groups; i++) {
        uint32_t data = ([self preTriggerDelay:i] & 0x7FF) | (preTriggerDelayPGBit << 15);
        [self writeLong:data toAddress:[self groupRegister:kPreTriggerDelayReg group:i]];
    }
}

- (void) readPreTriggerDelays:(BOOL)verbose
{
    int i;
    if(verbose){
        NSLog(@"Reading Pre Trigger Delays:\n");
    }
    for(i =0; i < kNumSIS3316Groups; i++) {
        uint32_t aValue =  [self readLongFromAddress:[self groupRegister:kPreTriggerDelayReg group:i]];
         if(verbose){
            uint32_t thePreTriggerDelays   = ((aValue >> 0x1) & 0x7FA)  ;
            NSLog(@"%2d: 0x%08x\n",i, thePreTriggerDelays);
        }
    }
}

//6.20 Average Configuration registers

//6.21 Data Format Configuration registers
- (void) writeDataFormat
{
    uint32_t aValue = formatMask | (formatMask<<8) | (formatMask<<16) | (formatMask<<24);

    int i;
    for(i=0;i<kNumSIS3316Groups;i++){
        [self writeLong:aValue toAddress:[self groupRegister:kDataFormatConfigReg group:i]];
     }
}

//6.22 MAW Test Buffer Configuration registers

//6.23 Internal Trigger Delay Configuration registers
- (unsigned short) triggerDelay:(unsigned short)aChan {if(aChan<kNumSIS3316Channels)return triggerDelay[aChan]; else return 0;}


- (void) setTriggerDelay:(unsigned short)aChan withValue:(unsigned short)aValue
{
    if(aChan>kNumSIS3316Channels)return;
    if(aValue>0xFF)aValue = 0xFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerDelay:aChan withValue:triggerDelay[aChan]];
    triggerDelay[aChan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName: ORSIS3316TriggerDelayChanged object:self userInfo:userInfo];
}

- (void) writeTriggerDelay
{
    int i;
    for(i = 0; i <kNumSIS3316Groups; i++){
        uint32_t aValue =    (triggerDelay[i*4]     & 0xFF)          |
                                        ((triggerDelay[i*4+1]  & 0xFF) << 8 )   |
                                        ((triggerDelay[i*4+2]  & 0xFF) << 16)   |
                                        ((triggerDelay[i*4+3]  & 0xFF) << 24)   ;
        
        [self writeLong:aValue toAddress:[self groupRegister:kInternalTrigDelayConfigReg group:i]];
    }
}

- (void) readTriggerDelay:(BOOL)verbose
{
    int i;
    if(verbose){
        NSLog(@"Reading Trigger Delay:\n");
        NSLog(@"Ch 1-4     5-8     9-12    13-16:\n");
    }
    for(i = 0; i < kNumSIS3316Groups; i++){
        uint32_t aValue =  [self readLongFromAddress:[self groupRegister:kInternalTrigDelayConfigReg group:i]];
        if(verbose){
            uint32_t theTriggerDelay    = ((aValue >> 0 ) & 0xFF);
            uint32_t theTriggerDelayTwo = ((aValue >> 8 ) & 0xFF);
            uint32_t theTriggerDelay3   = ((aValue >> 16) & 0xFF);
            uint32_t theTriggerDelay4   = ((aValue >> 24) & 0xFF);
            NSLog(@"%2d: 0x%03x 0x%03x 0x%03x 0x%03x\n", i, theTriggerDelay, theTriggerDelayTwo, theTriggerDelay3, theTriggerDelay4);
        }
    }
}

//6.24 Internal Gate Length Configuration registers



//6.26 Trigger Threshold registers

NSString* cfdCntrlString[4] = {
    @"Disabled",
    @"Disabled",
    @"Zero Crossing",
    @"50%"
};

- (int32_t) enabledMask                                { return enabledMask;                              }
- (BOOL) enabled:(unsigned short)chan               { return (enabledMask & (0x1<<chan)) != 0;           }
- (void) setEnabledMask:(uint32_t)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabledMask:enabledMask];
    enabledMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316EnabledChanged object:self];
}

- (void) setEnabledBit:(unsigned short)chan withValue:(BOOL)aValue
{
    int32_t  aMask = enabledMask;
    if(aValue) aMask |=  (0x1<<chan);
    else       aMask &= ~(0x1<<chan);
    [self setEnabledMask:aMask];
}
- (int32_t) formatMask                                { return formatMask;                              }
- (BOOL) formatBit:(unsigned short)bit               { return (formatMask & (0x1<<bit)) != 0;           }
- (void) setFormatMask:(uint32_t)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFormatMask:formatMask];
    formatMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316FormatMaskChanged object:self];
}

- (void) setFormatBit:(unsigned short)bit withValue:(BOOL)aValue
{
    int32_t  aMask = formatMask;
    if(aValue) aMask |=  (0x1<<bit);
    else       aMask &= ~(0x1<<bit);
    [self setFormatMask:aMask];
}

- (int32_t) heSuppressTriggerMask                      { return heSuppressTriggerMask;                    }
- (BOOL) heSuppressTriggerBit:(unsigned short)chan  { return (heSuppressTriggerMask & (0x1<<chan)) != 0; }

- (unsigned short) cfdControlBits:(unsigned short)aChan       { if(aChan<kNumSIS3316Channels)return cfdControlBits[aChan]; else return 0; }

- (void) setCfdControlBits:(unsigned short)aChan withValue:(unsigned short)aValue
{
    if(aValue>0x2)aValue = 0x2;
    [[[self undoManager] prepareWithInvocationTarget:self] setCfdControlBits:aChan withValue:[self cfdControlBits:aChan]];
    cfdControlBits[aChan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316CfdControlBitsChanged object:self userInfo:userInfo];
}

- (int32_t) threshold:(unsigned short)aChan            { if(aChan<kNumSIS3316Channels)return threshold[aChan];      else return 0;}
- (uint32_t) thresholdSum:(unsigned short)aGroup {if(aGroup<kNumSIS3316Groups)return thresholdSum[aGroup]; else return 0;}

- (void) setHeSuppressTriggerMask:(uint32_t)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHeSuppressTriggerMask:heSuppressTriggerMask];
    heSuppressTriggerMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316HeSuppressTrigModeChanged object:self];
}

- (void) setHeSuppressTriggerBit:(unsigned short)chan withValue:(BOOL)aValue
{
    unsigned short aMask = heSuppressTriggerMask;
    if(aValue) aMask |= (0x1<<chan);
    else       aMask &= ~(0x1<<chan);
    [self setHeSuppressTriggerMask:aMask];
}

- (void) setThreshold:(unsigned short)aChan withValue:(int32_t)aValue
{
    if(aValue<0)aValue = 0;
    if(aValue>0xFFFFFFF)aValue = 0xFFFFFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChan withValue:threshold[aChan]];
    threshold[aChan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316ThresholdChanged object:self userInfo:userInfo];
    
}

- (void) setThresholdSum:(unsigned short)aGroup withValue:(uint32_t)aValue
{
    if(aValue>0xFFFFFFFF)aValue = 0xFFFFFFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setThresholdSum:aGroup withValue:thresholdSum[aGroup]];
    thresholdSum[aGroup] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName: ORSIS3316ThresholdSumChanged object:self userInfo:userInfo];
}


- (BOOL) enableSum:(unsigned short)aGroup
{
    if(aGroup < kNumSIS3316Groups){
        return enableSum[aGroup];
    }
    else return 0;
}

- (void) setEnableSum:(unsigned short)aGroup withValue:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnableSum:aGroup withValue:enableSum[aGroup]];
    enableSum[aGroup] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName: ORSIS3316EnableSumChanged object:self userInfo:userInfo];
}

- (uint32_t) riseTimeSum:(unsigned short)aGroup
{
    if(aGroup < kNumSIS3316Groups){
        return riseTimeSum[aGroup];
    }
    else return 0;
}

- (void) setRiseTimeSum:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aValue>0xFFF)aValue = 0xFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setRiseTimeSum:aGroup withValue:riseTimeSum[aGroup]];
    riseTimeSum[aGroup] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName: ORSIS3316RiseTimeSumChanged object:self userInfo:userInfo];
}

- (uint32_t) gapTimeSum:(unsigned short)aGroup
{
    if(aGroup < kNumSIS3316Groups){
        return gapTimeSum[aGroup];
    }
    else return 0;
}

- (void) setGapTimeSum:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aValue>0xFFF)aValue = 0xFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setGapTimeSum:aGroup withValue:gapTimeSum[aGroup]];
    gapTimeSum[aGroup] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName: ORSIS3316GapTimeSumChanged object:self userInfo:userInfo];
}

- (unsigned short) cfdControlBitsSum:(unsigned short)aGroup
{
    if(aGroup < kNumSIS3316Groups){
        return cfdControlBitsSum[aGroup];
    }
    else return 0;
}

- (void) setCfdControlBitsSum:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aValue>2)aValue = 0xFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setCfdControlBitsSum:aGroup withValue:cfdControlBitsSum[aGroup]];
    cfdControlBitsSum[aGroup] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName: ORSIS3316CfdControlBitsSumChanged object:self userInfo:userInfo];
}

//Configure FIR
//peakingtime and gaptime
//6.25 FIR Trigger Setup registers
- (void) configureFIR
{
    [self writeThresholds];
    [self writeHeTrigThresholds];
    [self writeHeTrigThresholdSum];
    [self writeThresholdSum];
    [self writeFirTriggerSetup];
}

- (void) writeFirTriggerSetup
{
    int i;
    for(i = 0; i < kNumSIS3316Channels; i++) {
        uint32_t aValue =  ([self gapTime:i] << 12) |
                                 [self riseTime:i];
        [self writeLong:aValue toAddress:[self channelRegister:kFirTrigSetupCh1Reg channel:i]];
    }
}

- (void) writeThresholds
{
    int i;
    for(i = 0; i < kNumSIS3316Channels; i++) {
        uint32_t aValue =  ((uint32_t)((enabledMask>>i) & 0x1) << 31)  |
                                ((uint32_t)((heSuppressTriggerMask>>i) & 0x1) << 30)  |
                                ((cfdControlBits[i]+1        & 0x3) << 28)  |
                                // (0x08000000 + (riseTime[i] * threshold[i]));
                                (0x08000000 + [self threshold:i]);
        [self writeLong:aValue toAddress:[self channelRegister:kTrigThresholdCh1Reg channel:i]];
    }
}

- (void) writeHeTrigThresholds
{
    int i;
    for(i = 0; i < kNumSIS3316Channels; i++) {
        uint32_t aValue  = ((uint32_t)((trigBothEdgesMask>>i) & 0x1) << 31)  |
        (((intHeTrigOutPulseMask>>i)  & 0x1) << 30)  |
        (([self intTrigOutPulseBit:i] & 0x3) << 28)  |
        ([self heTrigThreshold:i]);
        [self writeLong:aValue toAddress:[self channelRegister:kHiEnergyTrigThresCh1Reg channel:i]];
    }
}

- (void) writeHeTrigThresholdSum
{
    int i;
    for( i = 0; i<kNumSIS3316Groups; i++){
        uint32_t aValue = ([self heTrigThresholdSum:i] & 0xFFF);
        [self writeLong:aValue toAddress:[self groupRegister:kHiETrigThresSumCh1Ch4Reg group:i]];
    }
}
//??????????
//-----------------------------

- (void) writeThresholdSum
{
    int i;
    for(i = 0; i <kNumSIS3316Groups; i++){
        uint32_t data= ((0x1 & enableSum[i]) << 31)                   |
                            ((0x1 & [self heSuppressTriggerBit:i]) << 30)  |
                            ((0x3 & cfdControlBitsSum[i]) << 28 )          |
                            //(0x08000000 + (riseTimeSum[i] * thresholdSum[i]) );
                            (0x08000000 + [self thresholdSum:i]);
        [self writeLong:data toAddress:[self groupRegister:kTrigThreholdSumCh1Ch4Reg group:i]];
    }
}



//6.27 High Energy Trigger Threshold registers
NSString* intTrigOutPulseString[3] = {
    @"Internal",
    @"High Energy ",
    @"Pileup Pulse"
};

- (uint32_t) heTrigThreshold:(unsigned short)aChan
{
    if(aChan<kNumSIS3316Channels) return heTrigThreshold[aChan] & 0xFFFFFFF;
    else return 0;
}

- (uint32_t) heTrigThresholdSum:(unsigned short)aGroup  {if(aGroup<kNumSIS3316Groups)return heTrigThresholdSum[aGroup]; else return 0;}

- (int32_t) trigBothEdgesMask                                  { return trigBothEdgesMask;                         }
- (BOOL) trigBothEdgesBit:(unsigned short)chan              { return (trigBothEdgesMask     & (0x1<<chan)) != 0;}

- (int32_t) intHeTrigOutPulseMask                              { return intHeTrigOutPulseMask;                     }
- (BOOL) intHeTrigOutPulseBit:(unsigned short)chan          { return (intHeTrigOutPulseMask & (0x1<<chan)) != 0;}

- (unsigned short) intTrigOutPulseBit:(unsigned short)aChan { return intTrigOutPulseBit[aChan];                 }

- (void) setHeTrigThreshold:(unsigned short)aChan withValue:(uint32_t)aValue
{
    if(aChan>kNumSIS3316Channels)return;
    if(aValue>0xFFFFFFF)aValue = 0xFFFFFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setHeTrigThreshold:aChan withValue:[self heTrigThreshold:aChan]];
    heTrigThreshold[aChan] =aValue;
    
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316HeTrigThresholdChanged object:self userInfo:userInfo];
}

- (void) setHeTrigThresholdSum:(unsigned short)aGroup withValue:(uint32_t)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue>0xFFFFFFFF)aValue = 0xFFFFFFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setHeTrigThresholdSum:aGroup withValue:[self heTrigThresholdSum:aGroup]];
    heTrigThresholdSum[aGroup] = aValue;
    
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316HeTrigThresholdSumChanged object:self userInfo:userInfo];
}

- (void) setTrigBothEdgesMask:(uint32_t)aMask
{
    if(trigBothEdgesMask == aMask)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setTrigBothEdgesMask:trigBothEdgesMask];
    trigBothEdgesMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316TrigBothEdgesChanged object:self];
}

- (void) setTrigBothEdgesBit:(unsigned short)aChan withValue:(BOOL)aValue
{
    if(aChan>kNumSIS3316Channels)return;
    unsigned short  aMask  = trigBothEdgesMask;
    if(aValue)      aMask |= (0x1<<aChan);
    else            aMask &= ~(0x1<<aChan);
    [self setTrigBothEdgesMask:aMask];
}

- (void) setIntHeTrigOutPulseMask:(uint32_t)aMask
{
    if(intHeTrigOutPulseMask == aMask)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setIntHeTrigOutPulseMask:intHeTrigOutPulseMask];
    intHeTrigOutPulseMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316IntHeTrigOutPulseChanged object:self];
}

- (void) setIntHeTrigOutPulseBit:(unsigned short)aChan withValue:(BOOL)aValue
{
    if(aChan>kNumSIS3316Channels)return;
    unsigned short   aMask  = intHeTrigOutPulseMask;
    if(aValue)      aMask |= (0x1<<aChan);
    else            aMask &= ~(0x1<<aChan);
    [self setIntHeTrigOutPulseMask:aMask];
}

- (void) setIntTrigOutPulseBit:(unsigned short)aChan withValue:(unsigned short)aValue
{
    if(aChan>kNumSIS3316Channels)return;
    
    if(aValue>0x3)aValue = 0x3;
    if(intTrigOutPulseBit[aChan] == aValue)return;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setIntTrigOutPulseBit:aChan withValue:[self intTrigOutPulseBit:aChan]];
    intTrigOutPulseBit[aChan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316IntTrigOutPulseBitsChanged object:self userInfo:userInfo];
}

- (void) readHeTrigThresholds:(BOOL)verbose
{
    int i;
    if(verbose){
        NSLog(@"Reading High Energy Thresholds:\n");
        NSLog(@"Chan BothEdges IntHETrigOut IntTrigOut HEThreshold \n");
    }
    for(i =0; i < kNumSIS3316Channels; i++) {
        uint32_t aValue =  [self readLongFromAddress:[self channelRegister:kHiEnergyTrigThresCh1Reg channel:i]];
        if(verbose){
            uint32_t heThres  = (aValue & 0x0FFFFFFF);
            unsigned short intTrigOut = ((aValue>>28) & 0x3);
            unsigned short intHETrigOut  = ((aValue>>30) & 0x1);
            unsigned short both  = ((aValue>>31) & 0x1);
            if(intTrigOut>2)NSLogFont([NSFont fontWithName:@"Monaco" size:12],@"%2d: %@ %@ %@ 0x%08x\n",i, both?@"YES":@" NO",intHETrigOut?@"YES":@" NO",@"reserved",heThres);
            else NSLogFont([NSFont fontWithName:@"Monaco" size:12],@"%2d: %@ %@ %@ 0x%08x\n",i, both?@"YES":@" NO",intHETrigOut?@"YES":@" NO",intTrigOutPulseString[intTrigOut],heThres);
        }
    }
}

- (void) readHeTrigThresholdSum:(BOOL)verbose
{
    int i;
    if(verbose){
        NSLog(@"Reading High Energy Threshold Sum:\n");
    }
    for(i = 0; i < kNumSIS3316Groups; i++){
        uint32_t aValue =  [self readLongFromAddress:[self groupRegister:kHiETrigThresSumCh1Ch4Reg group:i]];
        if(verbose){
            unsigned short heTrigThreshSum = (aValue & 0xFFFFFFFF);
            NSLog(@"%2d:  0x%08x\n",i, heTrigThreshSum);
        }
    }
}

//6.28 Trigger Statistic Counter Mode register

//6.29 Peak/Charge Configuration registers

//6.30 Extended Raw Data Buffer Configuration registers

//6.31 Accumulator Gate X Configuration registers
//----Accumlator gate1
- (unsigned short) accGate1Start:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate1Start[aGroup];
}

- (void) setAccGate1Start:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<1)aValue = 1;
    if(aValue>0xffff)aValue = 0xffff;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate1Start:aGroup withValue:[self accGate1Start:aGroup]];
    accGate1Start[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate1StartChanged object:self userInfo:userInfo];
}

- (unsigned short) accGate1Len:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate1Len[aGroup];
}

- (void) setAccGate1Len:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<0)aValue = 0;
    if(aValue>0x1FF)aValue = 0x1FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate1Len:aGroup withValue:[self accGate1Len:aGroup]];
    accGate1Len[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate1LenChanged object:self userInfo:userInfo];
}

//----Accumlator gate2
- (unsigned short) accGate2Start:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate2Start[aGroup];
}

- (void) setAccGate2Start:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<1)aValue = 1;
    if(aValue>0xffff)aValue = 0xffff;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate2Start:aGroup withValue:[self accGate2Start:aGroup]];
    accGate2Start[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate2StartChanged object:self userInfo:userInfo];
}

- (unsigned short) accGate2Len:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate2Len[aGroup];
}

- (void) setAccGate2Len:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<0)aValue = 0;
    if(aValue>0x1FF)aValue = 0x1FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate2Len:aGroup withValue:[self accGate2Len:aGroup]];
    accGate2Len[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate2LenChanged object:self userInfo:userInfo];
}

//----Accumlator gate3
- (unsigned short) accGate3Start:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate3Start[aGroup];
}

- (void) setAccGate3Start:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<1)aValue = 1;
    if(aValue>0xffff)aValue = 0xffff;

    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate3Start:aGroup withValue:[self accGate3Start:aGroup]];
    accGate3Start[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate3StartChanged object:self userInfo:userInfo];
}

- (unsigned short) accGate3Len:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate3Len[aGroup];
}

- (void) setAccGate3Len:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<0)aValue = 0;
    if(aValue>0x1FF)aValue = 0x1FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate3Len:aGroup withValue:[self accGate3Len:aGroup]];
    accGate3Len[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate3LenChanged object:self userInfo:userInfo];
}

//----Accumlator gate4
- (unsigned short) accGate4Start:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate4Start[aGroup];
}

- (void) setAccGate4Start:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<1)aValue = 1;
    if(aValue>0xffff)aValue = 0xffff;

    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate4Start:aGroup withValue:[self accGate4Start:aGroup]];
    accGate4Start[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate4StartChanged object:self userInfo:userInfo];
}

- (unsigned short) accGate4Len:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate4Len[aGroup];
}

- (void) setAccGate4Len:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<0)aValue = 0;
    if(aValue>0x1FF)aValue = 0x1FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate4Len:aGroup withValue:[self accGate4Len:aGroup]];
    accGate4Len[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate4LenChanged object:self userInfo:userInfo];
}

//----Accumlator gate5
- (unsigned short) accGate5Start:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate5Start[aGroup];
}

- (void) setAccGate5Start:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<1)aValue = 1;
    if(aValue>0xffff)aValue = 0xffff;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate5Start:aGroup withValue:[self accGate5Start:aGroup]];
    accGate5Start[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate5StartChanged object:self userInfo:userInfo];
}

- (unsigned short) accGate5Len:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate5Len[aGroup];
}

- (void) setAccGate5Len:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<0)aValue = 0;
    if(aValue>0x1FF)aValue = 0x1FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate5Len:aGroup withValue:[self accGate5Len:aGroup]];
    accGate5Len[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate5LenChanged object:self userInfo:userInfo];
}

//----Accumlator Gate6
- (unsigned short) accGate6Start:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate6Start[aGroup];
}

- (void) setAccGate6Start:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<1)aValue = 1;
    if(aValue>0xffff)aValue = 0xffff;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate6Start:aGroup withValue:[self accGate6Start:aGroup]];
    accGate6Start[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate6StartChanged object:self userInfo:userInfo];
}

- (unsigned short) accGate6Len:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate6Len[aGroup];
}

- (void) setAccGate6Len:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<0)aValue = 0;
    if(aValue>0x1FF)aValue = 0x1FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate6Len:aGroup withValue:[self accGate6Len:aGroup]];
    accGate6Len[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate6LenChanged object:self userInfo:userInfo];
}

//----Accumlator gate7
- (unsigned short) accGate7Start:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate7Start[aGroup];
}

- (void) setAccGate7Start:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<1)aValue = 1;
    if(aValue>0xffff)aValue = 0xffff;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate7Start:aGroup withValue:[self accGate7Start:aGroup]];
    accGate7Start[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate7StartChanged object:self userInfo:userInfo];
}

- (unsigned short) accGate7Len:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate7Len[aGroup];
}

- (void) setAccGate7Len:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<0)aValue = 0;
    if(aValue>0x1FF)aValue = 0x1FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate7Len:aGroup withValue:[self accGate7Len:aGroup]];
    accGate7Len[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate7LenChanged object:self userInfo:userInfo];
}

//----Accumlator gate8
- (unsigned short) accGate8Start:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate8Start[aGroup];
}

- (void) setAccGate8Start:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<1)aValue = 1;
    if(aValue>0xffff)aValue = 0xffff;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate8Start:aGroup withValue:[self accGate8Start:aGroup]];
    accGate8Start[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate8StartChanged object:self userInfo:userInfo];
}

- (unsigned short) accGate8Len:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate8Len[aGroup];
}

- (void) setAccGate8Len:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<0)aValue = 0;
    if(aValue>0x1FF)aValue = 0x1FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate8Len:aGroup withValue:[self accGate8Len:aGroup]];
    accGate8Len[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate8LenChanged object:self userInfo:userInfo];
}
//--------------------------------------------------------------

- (void) writeAccumulatorGates
{
    int i;
    
    for(i = 0; i < kNumSIS3316Groups; i++) {
        uint32_t valueToWrite1 = (([self accGate1Len:i]     & 0x1FF) << 16 )     |
                                      (([self accGate1Start:i]   & 0xFFFF) << 0 );
        [self writeLong:valueToWrite1 toAddress:[self groupRegister:kAccGate1ConfigReg group:i]];
        
        uint32_t valueToWrite2 = (([self accGate2Len:i]     & 0x1FF) << 16 )     |
                                      (([self accGate2Start:i]   & 0xFFFF) << 0 );
        [self writeLong:valueToWrite2 toAddress:[self groupRegister:kAccGate2ConfigReg group:i]];
       
        uint32_t valueToWrite3 = (([self accGate3Len:i]     & 0x1FF) << 16 )     |
                                      (([self accGate3Start:i]   & 0xFFFF) << 0 );
        [self writeLong:valueToWrite3 toAddress:[self groupRegister:kAccGate3ConfigReg group:i]];
        
        uint32_t valueToWrite4 = (([self accGate4Len:i]     & 0x1FF) << 16 )     |
                                      (([self accGate4Start:i]   & 0xFFFF) << 0 );
        [self writeLong:valueToWrite4 toAddress:[self groupRegister:kAccGate4ConfigReg group:i]];

        uint32_t valueToWrite5 = (([self accGate5Len:i]     & 0x1FF) << 16 )     |
        (([self accGate5Start:i]   & 0xFFFF) << 0 );
        [self writeLong:valueToWrite5 toAddress:[self groupRegister:kAccGate5ConfigReg group:i]];

        uint32_t valueToWrite6 = (([self accGate6Len:i]     & 0x1FF) << 16 )     |
        (([self accGate6Start:i]   & 0xFFFF) << 0 );
        [self writeLong:valueToWrite6 toAddress:[self groupRegister:kAccGate6ConfigReg group:i]];

        uint32_t valueToWrite7 = (([self accGate7Len:i]     & 0x1FF) << 16 )     |
        (([self accGate7Start:i]   & 0xFFFF) << 0 );
        [self writeLong:valueToWrite7 toAddress:[self groupRegister:kAccGate7ConfigReg group:i]];

        uint32_t valueToWrite8 = (([self accGate8Len:i]     & 0x1FF) << 16 )     |
        (([self accGate8Start:i]   & 0xFFFF) << 0 );
        [self writeLong:valueToWrite8 toAddress:[self groupRegister:kAccGate8ConfigReg group:i]];

    }
}


//6.32 FIR Energy Setup registers
NSString* extraFilter[4] = {
    @"None          ",
    @"Average of 4  ",
    @"Average of 8  ",
    @"Average of 16 "
};

NSString* tauTable[4] ={
    @"0",
    @"1",
    @"2",
    @"3",
};

- (int32_t) extraFilterBits:(unsigned short)aChan       { if(aChan<kNumSIS3316Channels)return extraFilterBits[aChan] & 0x3; else return 0; }

- (int32_t) tauTableBits:(unsigned short)aChan       { if(aChan<kNumSIS3316Channels)return tauTableBits[aChan] & 0x3; else return 0; };

- (void) setExtraFilterBits:(unsigned short)aChan withValue:(int32_t)aValue
{
    if(aValue<0)aValue = 0;
    if(aValue>0x3)aValue = 0x3;
    [[[self undoManager] prepareWithInvocationTarget:self] setExtraFilterBits:aChan withValue:[self extraFilterBits:aChan]];
    extraFilterBits[aChan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316ExtraFilterBitsChanged object:self userInfo:userInfo];
}

- (void) setTauTableBits:(unsigned short)aChan withValue:(int32_t)aValue
{
    if(aValue<0)aValue = 0;
    if(aValue>0x3)aValue = 0x3;
    [[[self undoManager] prepareWithInvocationTarget:self] setTauTableBits:aChan withValue:[self tauTableBits:aChan]];
    tauTableBits[aChan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316TauTableBitsChanged object:self userInfo:userInfo];
}

- (unsigned short) tauFactor:(unsigned short)aChan
{
    if(aChan>kNumSIS3316Channels)return 0;
    else return tauFactor[aChan] & 0x3F;
}

- (void) setTauFactor:(unsigned short)aChan withValue:(unsigned short)aValue
{
    if(aChan>kNumSIS3316Channels)return;
    if(aValue>0x3f)aValue = 0x3f;
    [[[self undoManager] prepareWithInvocationTarget:self] setTauFactor:aChan withValue:[self tauFactor:aChan]];
    tauFactor[aChan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316TauFactorChanged object:self userInfo:userInfo];
}

- (unsigned short) riseTime:(unsigned short)aChan
{
    if(aChan>kNumSIS3316Channels)return 0;
    else return riseTime[aChan] & 0xFFFF;
}

- (void) setRiseTime:(unsigned short)aChan withValue:(unsigned short)aValue
{
    if(aChan>kNumSIS3316Channels)return;
    if(aValue>0xFFFF)aValue = 0xFFFF;
    if(aValue<2)     aValue = 2;
    aValue &= ~0x0001;
    [[[self undoManager] prepareWithInvocationTarget:self] setRiseTime:aChan withValue:riseTime[aChan]];
    riseTime[aChan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316PeakingTimeChanged object:self userInfo:userInfo];
}

- (unsigned short) gapTime:(unsigned short)aChan
{
    if(aChan>kNumSIS3316Channels)return 0;
    else return gapTime[aChan] & 0xfff;
}

- (void) setGapTime:(unsigned short)aChan withValue:(unsigned short)aValue
{
    if(aChan>kNumSIS3316Channels)return;
    if(aValue>0x3ff)aValue = 0xfff;
    if(aValue<2)aValue = 2;
    aValue &= ~0x0001; //bit zero is always zero
    
    [[[self undoManager] prepareWithInvocationTarget:self] setGapTime:aChan withValue:[self gapTime:aChan]];
    gapTime[aChan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316GapTimeChanged object:self userInfo:userInfo];
}

//6.33 Energy Histogram Configuration registers
- (int32_t) histogramsEnabledMask                       { return histogramsEnabledMask;                          }
- (BOOL) histogramsEnabled:(unsigned short)chan      { return (histogramsEnabledMask     & (0x1<<chan)) != 0; }
- (int32_t) pileupEnabledMask                           { return pileupEnabledMask;                              }
- (BOOL) pileupEnabled:(unsigned short)chan          { return (pileupEnabledMask         & (0x1<<chan)) != 0; }
- (int32_t) clrHistogramsWithTSMask                     { return clrHistogramsWithTSMask;                        }
- (BOOL) clrHistogramsWithTS:(unsigned short)chan    { return (clrHistogramsWithTSMask   & (0x1<<chan)) != 0; }
- (int32_t) writeHitsToEventMemoryMask                  { return writeHitsToEventMemoryMask;                     }
- (BOOL) writeHitsToEventMemory:(unsigned short)chan { return (writeHitsToEventMemoryMask& (0x1<<chan)) != 0; }

- (void) setHistogramsEnabledMask:(uint32_t)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHistogramsEnabledMask:histogramsEnabledMask];
    histogramsEnabledMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316HistogramsEnabledChanged object:self];
}

- (void) setHistogramsEnabled:(unsigned short)chan withValue:(BOOL)aValue
{
    int32_t            aMask  = histogramsEnabledMask;
    if(aValue)      aMask |= (0x1<<chan);
    else            aMask &= ~(0x1<<chan);
    [self setHistogramsEnabledMask:aMask];
}

- (void) setPileupEnabledMask:(uint32_t)aMask
{
    if(pileupEnabledMask==aMask)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setPileupEnabledMask:pileupEnabledMask];
    pileupEnabledMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316PileUpEnabledChanged object:self];
}

- (void) setPileupEnabled:(unsigned short)chan withValue:(BOOL)aValue
{
    int32_t            aMask  = pileupEnabledMask;
    if(aValue)      aMask |= (0x1<<chan);
    else            aMask &= ~(0x1<<chan);
    [self setPileupEnabledMask:aMask];
}

- (void) setClrHistogramsWithTSMask:(uint32_t)aMask
{
    if(clrHistogramsWithTSMask==aMask)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setClrHistogramsWithTSMask:clrHistogramsWithTSMask];
    clrHistogramsWithTSMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316ClrHistogramWithTSChanged object:self];
}

- (void) setClrHistogramsWithTS:(unsigned short)chan withValue:(BOOL)aValue
{
    int32_t            aMask = clrHistogramsWithTSMask;
    if(aValue)      aMask |= (0x1<<chan);
    else            aMask &= ~(0x1<<chan);
    [self setClrHistogramsWithTSMask:aMask];
}

- (void) setWriteHitsToEventMemoryMask:(uint32_t)aMask
{
    if(writeHitsToEventMemoryMask==aMask)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteHitsToEventMemoryMask:writeHitsToEventMemoryMask];
    writeHitsToEventMemoryMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316WriteHitsIntoEventMemoryChanged object:self];
}

- (void) setWriteHitsToEventMemory:(unsigned short)chan withValue:(BOOL)aValue
{
    int32_t            aMask = writeHitsToEventMemoryMask;
    if(aValue)      aMask |= (0x1<<chan);
    else            aMask &= ~(0x1<<chan);
    [self setWriteHitsToEventMemoryMask:aMask];
}

- (unsigned short) energyDivider:(unsigned short)aChan
{
    if(aChan>kNumSIS3316Channels)return 1;
    if(energyDivider[aChan]==0)energyDivider[aChan] = 1;
    return energyDivider[aChan];
}

- (void) setEnergyDivider:(unsigned short)aChan withValue:(unsigned short)aValue
{
    if(aChan>kNumSIS3316Channels)return;
    if(aValue<1)aValue = 1;
    if(aValue>0xFFF)aValue = 0xfff;
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergyDivider:aChan withValue:[self energyDivider:aChan]];
    energyDivider[aChan]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316EnergyDividerChanged object:self userInfo:userInfo];
}

- (unsigned short) energyOffset:(unsigned short)aChan
{
    if(aChan>kNumSIS3316Channels)return 0;
    else return energyOffset[aChan] & 0xfe;
}

- (void) setEnergyOffset:(unsigned short)aChan withValue:(unsigned short)aValue
{
    if(aChan>kNumSIS3316Channels)return;
    if(aValue>0xff)aValue = 0xff;
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergyOffset:aChan withValue:[self energyOffset:aChan]];
    energyOffset[aChan] = aValue & 0xfe;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316EnergyOffsetChanged object:self userInfo:userInfo];
}

- (void) writeHistogramConfiguration
{
    int iChan;
    for(iChan=0;iChan<kNumSIS3316Channels;iChan++){
        uint32_t aValue =  (((writeHitsToEventMemoryMask>>iChan) & 0x1) << 31) |
                                (((clrHistogramsWithTSMask   >>iChan) & 0x1) << 30) |
                                ((energyDivider[iChan] & 0xfff)              << 16) |
                                ((energyOffset[iChan] & 0xff)                <<  8) |
                                (((pileupEnabledMask      >>iChan) & 0x1)    <<  1) |
                                (((histogramsEnabledMask  >>iChan) & 0x1)    <<  0);
        uint32_t addr = [self channelRegisterVersionTwo:kGenHistogramConfigCh1Reg channel:iChan];
        [self writeLong:aValue toAddress:addr];
    }
}


//6.34 MAW Start Index and Energy Pickup Configuration registers

//6.35 ADC FPGA Firmware Version Register

//6.36 ADC FPGA Status register

//6.37 Actual Sample address registers

//6.38 Previous Bank Sample address registers
//** under #pragma mark •••Data Taker **//

//6.39 Key addresses (0x400 – 0x43C write only)
//6.39.1 Key address: Register Reset
- (void) reset
{
    [self writeLong:0 toAddress:[self singleRegister:kKeyResetReg]];
}

//6.39.3 Key address: Disarm sample logic ...NOT implemented in firmware yet.
- (void) disarmSampleLogic
{
    if(![[ORGlobal sharedGlobal] runInProgress]){
        [self writeLong:1 toAddress:[self singleRegister:kKeyDisarmSampleLogicReg]];
    }
}

//6.39.4 Key address: arm sample logic **** not implemented in the firmware yet....
- (void) armSampleLogic
{
    [self writeLong:1 toAddress:[self singleRegister:kKeyArmSampleLogicReg]];
}

//6.39.5Keyaddress: Trigger
- (void) trigger
{
    [self writeLong:1 toAddress:[self singleRegister:kKeyTriggerReg]];
}

//6.39.6 Key address: Timestamp Clear
- (void) clearTimeStamp
{
    if(![[ORGlobal sharedGlobal] runInProgress]){
        [self writeLong:1 toAddress:[self singleRegister:kKeyTimeStampClrReg]];
    }
    else NSLog(@"%@: Can not clear timestamp if run in progress\n",[self fullID]);
}

//6.39.7 Key address: Disarm Bankx and Arm Bank1
- (void) armBank1
{
    previousBank = 2;
    [self writeLong:1 toAddress:[self singleRegister:kKeyDisarmXArmBank1Reg]];
    currentBank = 1;
}

//6.39.8 Key address: Disarm Bankx and Arm Bank2
- (void) armBank2
{
    previousBank = 1;
    [self writeLong:1 toAddress:[self singleRegister:kKeyDisarmXArmBank2Reg]];
    currentBank = 2;
}

- (int) currentBank
{
    return currentBank;
}

- (void) readTimeStamp:(BOOL) verbose
{
    uint32_t hiTS  = [self readLongFromAddress:[self singleRegister:kPPSTimeStampHiReg]];
    uint32_t lowTS = [self readLongFromAddress:[self singleRegister:kPPSTimeStampLoReg]];
    if(verbose){
        int cLen = 27;
        NSLogStartTable(@"Time Stamp", cLen);
        NSLogMono(@"|     Hi     |     Low    |\n");
        NSLogDivider(@"-",cLen);
        NSLogMono(@"| 0x%08x | 0x%08x |\n",hiTS,lowTS);
        NSLogDivider(@"=",cLen);
    }
}


//6.39.11 Key address: PPS_Latch_Bit_clear
- (void) clearPPSLatchBit
{
    [self writeLong:1 toAddress:[self singleRegister:kKeyPPSLatchBitClrReg]];
}

//6.39.13 Key address: ADC Clock DCM/PLL Reset
- (void) resetADCClockDCM
{
    [self writeLong:1 toAddress:[self singleRegister:kKeyAdcClockPllResetReg]];
    [ORTimer delay:5*1E-3];//required wait for stablization
}

- (uint32_t) eventNumberGroup:(int)group bank:(int) bank
{
	//Note, here banks are 0,1,2,3 NOT 1,2,3,4
    return  [self readLongFromAddress:[self baseAddress] + eventCountOffset[group][bank]];
}

- (uint32_t) eventTriggerGroup:(int)group bank:(int) bank
{
	//Note, here banks are 0,1,2,3 NOT 1,2,3,4
    return  [self readLongFromAddress:[self baseAddress] + eventDirOffset[group][bank]];
}

- (void) readAddressCounts
{
	int i;
	for(i=0;i<4;i++){
        uint32_t aValue  = [self readLongFromAddress:[self baseAddress] + addressCounterOffset[i][0]];
        uint32_t aValue1 = [self readLongFromAddress:[self baseAddress] + addressCounterOffset[i][1]];
		NSLog(@"Group %d Address Counters:  0x%04x   0x%04x\n",i,aValue,aValue1);
	}
}

- (int) set_frequency:(int) osc values:(unsigned char*)values
{
    
    if(values == nil)     return -100;
    if(osc > 3 || osc < 0)return -100;
    
    int rc = [self si570FreezeDCO:osc];
    if(rc){
        NSLog(@"%@ : si570FreezeDCO Error(%d)\n",[self fullID],rc);
        return rc;
    }
    
    rc = [self si570ReadDivider:osc values:values];
    if(rc){
        NSLog(@"%@ : si570Divider Error(%d)\n",[self fullID],rc);
        return rc;
    }

    rc = [self si570UnfreezeDCO:osc];
    if(rc){
        NSLog(@"%@ : si570UnfreezeDCO Error(%d)\n",[self fullID],rc);
        return rc;
    }
    
    rc = [self si570NewFreq:osc];
    if(rc){
        NSLog(@"%@ : si570NewFreq Error(%d)\n",[self fullID],rc);
        return rc;
    }
    
    // min. 10ms wait
    usleep(20);
    
    [self resetADCClockDCM];

    return rc;
}

- (void) switchBanks
{
    if(currentBank == 1)    [self armBank2];
    else                    [self armBank1];
}

- (uint32_t) readTriggerTime:(int)bank index:(int)index
{   		
    return  [self readLongFromAddress:[self baseAddress] + (bank?kTriggerTime2Offset:kTriggerTime1Offset) + index*sizeof(int32_t)];
}

- (uint32_t) readTriggerEventBank:(int)bank index:(int)index
{   		
    return  [self readLongFromAddress:[self baseAddress] + (bank?kTriggerEvent2DirOffset:kTriggerEvent1DirOffset) + index*sizeof(int32_t)];
}

- (void) writeGateLengthConfiguration
{
    uint32_t internalGateConfigRegisterAddresses[kNumSIS3316Groups] = {
        kInternalGateLenConfigReg,
        kInternalGateLenConfigReg,
        kInternalGateLenConfigReg,
        kInternalGateLenConfigReg
    };
    int group;
    uint32_t data = 0x0;
    for( group = 0; group < kNumSIS3316Groups; group++ ) {
        uint32_t gate1Mask = 0x0;
        uint32_t gate2Mask = 0x0;
        int i;
        for(i=0;i<4;i++){
            if(eventConfigMask & 0x02) gate1Mask |= (0x1 << i);
            if(eventConfigMask & 0x04) gate2Mask |= (0x1 << i);
        }
        
        data =  ((0xF & gate1Mask)                << 20)   |
                ((0xF & gate2Mask)                << 16)   |
                ((0xFF & internalGateLen[group])  <<  8)   |
                 (0xFF & internalGateConfigRegisterAddresses[group]);
        
        [self writeLong:data toAddress:[self groupRegister:kInternalGateLenConfigReg group:group]];
    }
}

- (void) initBoard
{
    [self reset];
    [self adcSpiSetup];
    [self setupSharing];
    
    //if(!clocksProgrammed){
        //very involved... no need to do more than once
        [self setupClock];
        clocksProgrammed = YES;
    //}
    
    [self writeDacRegisters];
    [self writeGainTerminationValues];
    
    //[self setClockFreq];
    [self writePileUpRegisters];
    [self writeActiveTrigGateWindowLen];
    [self writePreTriggerDelays];
    [self writeRawDataBufferConfig];
    [self writeDataFormat];
    [self writeEventConfig];
    [self writeAccumulatorGates];
    [self writeEndAddress];
    [self writeAcquisitionRegister];
    [self configureFIR];
    [self writeTriggerDelay];
    [self writeNIMControlStatus];
    [self writeExtendedEventConfig];
    [self writeLemoCoMask];
    [self writeLemoToMask];
    [self writeLemoUoMask];
    [self writeMawBufferConfig];
    [self writeGateLengthConfiguration];
    [self write_channel_header_IDs] ;
    [self writeHistogramConfiguration];

}
#pragma mark •••Setup Utilities

- (void) write_channel_header_IDs
{
    // Channel Header ID register
    uint32_t data =   0x0;
    [self writeLong:data | (0x0<<22) toAddress:[self groupRegister:kChanHeaderIdReg group:0]];
    [self writeLong:data | (0x1<<22) toAddress:[self groupRegister:kChanHeaderIdReg group:1]];
    [self writeLong:data | (0x2<<22) toAddress:[self groupRegister:kChanHeaderIdReg group:2]];
    [self writeLong:data | (0x3<<22) toAddress:[self groupRegister:kChanHeaderIdReg group:3]];
    uint32_t aValue = [self readLongFromAddress:[self groupRegister:kChanHeaderIdReg group:0]];
    NSLog(@"chan id: 0x%08x\n",aValue);
    
}

- (void) poll_on_adc_dac_offset_busy
{
    unsigned int poll_counter = 1000 ;
    uint32_t data;
    do {
        poll_counter-- ;
        data = [self readLongFromAddress:[self singleRegister:kAdcSpiBusyStatusReg]];
    } while ( ((data & 0xf) != 0) && (poll_counter > 0)) ;
}

- (void) writeGainTerminationValues
{
    int iGroup;
    uint32_t all    = termination<<2 | gain;
    uint32_t aValue = all | (all<<8) | (all<<16) | (all<<24);
    for (iGroup=0; iGroup < kNumSIS3316Groups; iGroup++) {
        [self writeLong:aValue toAddress:[self groupRegister:kAdcGainTermCntrlReg group:iGroup]];
    }
}

#pragma mark •••Data Taker
- (uint32_t) dataId                     { return dataId;     }
- (void) setDataId: (uint32_t) aDataId  { dataId = aDataId;  }
- (uint32_t) histoId                    { return histoId;    }
- (void) setHistoId: (uint32_t) aDataId { histoId = aDataId; }
- (uint32_t) statId                     { return statId;     }
- (void) setStatId: (uint32_t) aDataId  { statId = aDataId;  }

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
    histoId      = [assigner assignDataIds:kLongForm];
    statId      = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId: [anotherCard dataId]];
    [self setHistoId:[anotherCard histoId]];
    [self setStatId: [anotherCard statId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary;
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORSIS3316WaveformDecoder",            @"decoder",
								 [NSNumber numberWithLong:dataId],       @"dataId",
								 [NSNumber numberWithBool:YES],          @"variable",
								 [NSNumber numberWithLong:-1],			 @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Waveform"];
    
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                   @"ORSIS3316HistogramDecoder",          @"decoder",
                   [NSNumber numberWithLong:histoId],     @"dataId",
                   [NSNumber numberWithBool:YES],         @"variable",
                   [NSNumber numberWithLong:-1],          @"length",
                   nil];
    [dataDictionary setObject:aDictionary forKey:@"Histogram"];

    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                   @"ORSIS3316StatisticsDecoder",         @"decoder",
                   [NSNumber numberWithLong:statId],      @"dataId",
                   [NSNumber numberWithBool:YES],         @"variable",
                   [NSNumber numberWithLong:-1],          @"length",
                   nil];
    [dataDictionary setObject:aDictionary forKey:@"Statistics"];

    return dataDictionary;
}

#pragma mark •••HW Wizard
-(BOOL) hasParmetersToRamp
{
	return YES;
}
- (int) numberOfChannels
{
    return kNumSIS3316Channels;
}

- (NSArray*) wizardParameters   //*****IN ALPHABETICAL ORDER*****//
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;

//    [a addObject:[ORHWWizParam boolParamWithName:@"AutoStart"        setter:@selector(setAutoStart:)        getter:@selector(autoStart)]];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Both Edges"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setTrigBothEdgesBit:withValue:) getMethod:@selector(trigBothEdgesBit:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"CFD Control Bits"];
    [p setFormat:@"##0" upperLimit:2 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setCfdControlBits:withValue:) getMethod:@selector(cfdControlBits:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Clock Source"];
    [p setFormat:@"##0" upperLimit:3 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setClockSource:) getMethod:@selector(clockSource)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
  //-=**
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setEnabledBit:withValue:) getMethod:@selector(enabled:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Extra Filter"];
    [p setFormat:@"##0" upperLimit:3 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setExtraFilterBits:withValue:) getMethod:@selector(extraFilterBits:)];
    [p setCanBeRamped:YES];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"HE"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setHeSuppressTriggerBit:withValue:) getMethod:@selector(heSuppressTriggerBit:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"HE Trig Out"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setIntHeTrigOutPulseBit:withValue:) getMethod:@selector(intHeTrigOutPulseBit:)];
    [p setCanBeRamped:YES];
    [a addObject:p];

    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Gap Time"];
    [p setFormat:@"##0" upperLimit:0x3f lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setGapTime:withValue:) getMethod:@selector(gapTime:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"HE Trig Threshold"];
    [p setFormat:@"##0" upperLimit:0xfffffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setHeTrigThreshold:withValue:) getMethod:@selector(heTrigThreshold:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Dac Offset"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setDacOffset:withValue:) getMethod:@selector(dacOffset:)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Int Trig Out Pulse"];
    [p setFormat:@"##0" upperLimit:2 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setIntTrigOutPulseBit:withValue:) getMethod:@selector(intTrigOutPulseBit:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Peaking Time"];
    [p setFormat:@"##0" upperLimit:0x3f lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setRiseTime:withValue:) getMethod:@selector(riseTime:)];
    [a addObject:p];
    
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Tau Factor"];
    [p setFormat:@"##0" upperLimit:0x3f lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setTauFactor:withValue:) getMethod:@selector(tauFactor:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Tau Table"];
    [p setFormat:@"##0" upperLimit:3 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setTauTableBits:withValue:) getMethod:@selector(tauTableBits:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0" upperLimit:0xfffffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setThreshold:withValue:) getMethod:@selector(threshold:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
   
//    p = [[[ORHWWizParam alloc] init] autorelease];
//    [p setName:@"Threshold Sum"];
//    [p setFormat:@"##0" upperLimit:0xFFFFFFFF lowerLimit:0 stepSize:1 units:@""];
//    [p setSetMethod:@selector(setThresholdSum:withValue:) getMethod:@selector(thresholdSum:)];
//    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease]; //MUST BE LAST
    [p setUseValue:NO];
    [p setName:@"Init"];
    [p setSetMethodSelector:@selector(initBoard)];
    [a addObject:p];

    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel  name:@"Crate"   className:@"ORVmeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel     name:@"Card"    className:@"ORSIS3316Model"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel    name:@"Channel" className:@"ORSIS3316Model"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
	if([param isEqualToString:      @"Threshold"])          return [[cardDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel];
    else if([param isEqualToString: @"Enabled"])            return [cardDictionary objectForKey: @"enabledMask"];
    else if([param isEqualToString: @"Histogram Enabled"])  return [cardDictionary objectForKey: @"histogramsEnabledMask"];
    else if([param isEqualToString: @"Clock Source"])       return [cardDictionary objectForKey: @"clockSource"];
    else if([param isEqualToString: @"P2StartStop"])        return [cardDictionary objectForKey: @"p2StartStop"];
    else if([param isEqualToString: @"LemoStartStop"])      return [cardDictionary objectForKey: @"lemoStartStop"];
    else if([param isEqualToString: @"GateMode"])           return [cardDictionary objectForKey: @"gateMode"];
    else if([param isEqualToString: @"MultiEvent"])         return [cardDictionary objectForKey: @"multiEventMode"];
    else return nil;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORSIS3316Model"];    
    
    //cache some stuff
    location        = (([self crateNumber]&0x0000000f)<<21) | (([self slot]& 0x0000001f)<<16);
    theController   = [self adapter];
    
    if(!moduleID){
        [self readModuleID:NO];
        [self readHWVersion:NO];
        [self readSerialNumber:NO];
        [self readTemperature:NO];
    }
    [self startRates];
    [self initBoard];
    [self clearTimeStamp];
	[self armBank2];
	[self setLed:YES];
    [timer release];
    timer = nil;
	isRunning = NO;
     waitingOnChannelMask = 0x0; //not waiting on any channel
    firstTime    = YES;

}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    uint32_t orcaHeaderLen = 10;
    uint32_t dataHeaderLen =  [self headerLen];

    @try {
        if(firstTime){
            timer = [[ORTimer alloc]init];
            [timer start];
            firstTime = NO;
        }
        isRunning = YES;
        
        uint32_t acqRegValue =  [self readLongFromAddress:[self singleRegister:kAcqControlStatusReg]];
        if((acqRegValue >> 19) & 0x1){ //checks the OR of the address threshold flags
            uint32_t bit[4] = {25,27,29,31};
            [self switchBanks];
            usleep(2); //up to 2µs to for bank switch
            int chan;
            for(chan=0;chan<16;chan++){
                if(enabledMask & (0x1<<chan)){
                    int iGroup    = chan/4;
                    if((acqRegValue>>bit[iGroup] & 0x1)){

                        uint32_t prevBankEndingAddress = [self readLongFromAddress:[self channelRegisterVersionTwo:kPreviousBankSampleCh1Reg channel:chan]];
                       if((((prevBankEndingAddress & 0x1000000) >> 24 )  != (previousBank-1))){
                           NSLog(@"BANK switch error: bank %d bit: %d\n",currentBank, (prevBankEndingAddress & 0x1000000) >> 24);
                        }
                        uint32_t expectedNumberOfWords     = prevBankEndingAddress & 0x00FFFFFF;
                        if(expectedNumberOfWords>0 ){
                            //first must transfer data from ADC FIFO to VME FIFO
                            uint32_t prevBankReadBeginAddress  = (prevBankEndingAddress & 0x03000000) + 0x10000000*((chan/2)%2);
                            uint32_t data                      = 0x80000000 + prevBankReadBeginAddress; //read, memory for ch1 & ch2
                            [self writeLong:data toAddress: baseAddress + 0x80 + iGroup*0x4];
                            usleep(2); //up to 2 µs for transfer to take place

                             expectedNumberOfWords = ((expectedNumberOfWords + 1) & 0xfffffE);
                            //expectedNumberOfWords -= 8;
                            if(expectedNumberOfWords > rawDataBufferLen+dataHeaderLen){
                                expectedNumberOfWords = rawDataBufferLen+dataHeaderLen; //slow here, so limit to one waveform
                            }
                            if(!dataRecord[chan]){
                                dataRecord[chan]  = malloc((rawDataBufferLen+dataHeaderLen)*sizeof(uint32_t));
                            }
                            dataRecord[chan][0] = dataId | (expectedNumberOfWords+orcaHeaderLen);
                            dataRecord[chan][1] = location | ((chan & 0xff)<<8); //add in the channel
                            dataRecord[chan][2] = 1;
                            dataRecord[chan][3] = expectedNumberOfWords;
                            dataRecord[chan][4] = 0;
                            dataRecord[chan][5] = 0;
                            dataRecord[chan][6] = 0;
                            dataRecord[chan][7] = 0;
                            dataRecord[chan][8] = 0;
                            dataRecord[chan][9] = 0;
                            [[self adapter] readLongBlock:&dataRecord[chan][orcaHeaderLen]
                                                atAddress:baseAddress + kSIS3316FpgaAdc1MemBase + iGroup*kSIS3316FpgaAdcMemOffset
                                                numToRead:expectedNumberOfWords
                                               withAddMod:0x09
                                            usingAddSpace:0x01];
                            
                            [aDataPacket addLongsToFrameBuffer:dataRecord[chan] length:expectedNumberOfWords+orcaHeaderLen];
                            ++waveFormCount[chan];
                        }
                    }
                }
            }
            if(histogramsEnabledMask && ([timer seconds]>=5)){
                [timer reset];
                for(chan=0;chan<16;chan++){
                    int iGroup    = chan/4;
                    if(((histogramsEnabledMask>>chan)&0x1)){
                        uint32_t memory_bank_offset_addr[4] ={
                            0x00FF0000,
                            0x02FF0000,
                            0x00FF0000|(0x1<<28),
                            0x02FF0000|(0x1<<28)
                        };
                        uint32_t data = 0x80000000 | memory_bank_offset_addr[chan%4]; //OR in the
                        NSLog(@"Transfer: %d 0x%08x 0x%08x\n",chan, data, baseAddress +0x80+iGroup*0x4);
                        [self writeLong:data toAddress: baseAddress + 0x80 + iGroup*0x4];
                        usleep(2); //up to 2 µs for transfer to take place
                        if(!histoRecord[chan]){
                            histoRecord[chan] = malloc((0xffff+dataHeaderLen)*sizeof(uint32_t));
                        }
                        histoRecord[chan][0] = histoId | (0xFFFF+orcaHeaderLen);
                        histoRecord[chan][1] = location | ((chan & 0xff)<<8); //add in the channel
                        histoRecord[chan][2] = [self headerLen];
                        histoRecord[chan][3] = 0;
                        histoRecord[chan][4] = 0;
                        histoRecord[chan][5] = 0;
                        histoRecord[chan][6] = 0;
                        histoRecord[chan][7] = 0;
                        histoRecord[chan][8] = 0;
                        histoRecord[chan][9] = 0;
                        [[self adapter] readLongBlock:&histoRecord[chan][orcaHeaderLen]
                                            atAddress:baseAddress + kSIS3316FpgaAdc1MemBase + iGroup*kSIS3316FpgaAdcMemOffset
                                            numToRead:0xFFF
                                           withAddMod:0x09
                                        usingAddSpace:0x01];
                    
                        [aDataPacket addLongsToFrameBuffer:histoRecord[chan] length:0xffff+orcaHeaderLen];
                    }
                }
            }
        }
    }
    @catch(NSException* localException) {
        [self incExceptionCount];
        [localException raise];
    }
}

- (void) readStatistics
{
    if(![[ORGlobal sharedGlobal] runInProgress]){

        // start readout FSM
        int cLen = 95;
        NSLogStartTable(@"Stats",cLen);
        NSLogMono(@"| ch |     All    |  Hits/Events |    Deadtime  |    Pileup    |      Veto    | HE Suppressed |\n");
        NSLogDivider(@"-",cLen);
        int iGroup;
        for(iGroup=0;iGroup<4;iGroup++){
            // Space = Statistic counter
            [self writeLong:0x80000000 + 0x30000000  toAddress: [self singleRegister:kAdcCh1_Ch4DataCntrReg] + (iGroup*4)];
            
            // read from FIFO
            uint32_t dataBuffer[6*4];
            [[self adapter] readLongBlock:dataBuffer
                                atAddress:[self baseAddress] + 0x100000 + (iGroup*0x100000)
                                numToRead:6*4
                               withAddMod:[self addressModifier]
                            usingAddSpace:0x01];
            int i_ch;
            for (i_ch = 0; i_ch < 4;i_ch++) {
                NSLogMono(@"| %2d | %10lu |  %10lu  |  %10lu  |  %10lu  |  %10lu  |   %10lu  |\n",
                      i_ch+ iGroup*4,
                          dataBuffer[(i_ch*6) + 0],
                          dataBuffer[(i_ch*6) + 1],
                          dataBuffer[(i_ch*6) + 2],
                          dataBuffer[(i_ch*6) + 3],
                          dataBuffer[(i_ch*6) + 4],
                          dataBuffer[(i_ch*6) + 5]
                          );
              }
        }
        NSLogDivider(@"=",cLen);
    }
    else {
        NSLog(@"%@: Can not read statistics while run in progress\n",[self fullID]);
    }
}
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    [timer stop];
    [timer release];
    timer = nil;
    isRunning = NO;
    [waveFormRateGroup stop];
	[self setLed:NO];
    [self disarmSampleLogic];
    int chan;
    for(chan=0;chan<kNumSIS3316Channels;chan++){
        if(dataRecord[chan]){
            free(dataRecord[chan]);
            dataRecord[chan] = nil;
        }
        if(histoRecord[chan]){
            free(histoRecord[chan]);
            histoRecord[chan] = nil;
        }
    }

}
- (short) headerLen
{
    short headerLen = 3;
    if((formatMask >> 0) & 0x1) headerLen += 7;
    if((formatMask >> 1) & 0x1) headerLen += 2;
    if((formatMask >> 2) & 0x1) headerLen += 3;
    if((formatMask >> 3) & 0x1) headerLen += 2;
    return headerLen;
}
//this is the data structure for the new SBCs (i.e. VX704 from Concurrent)
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id				= kSIS3316; //should be unique
    configStruct->card_info[index].hw_mask[0]                = dataId;  //better be unique
    configStruct->card_info[index].hw_mask[1]                = histoId; //better be unique
    configStruct->card_info[index].hw_mask[2]                = statId; //better be unique
	configStruct->card_info[index].slot						= [self slot];
	configStruct->card_info[index].crate					= [self crateNumber];
	configStruct->card_info[index].add_mod					= [self addressModifier];
	configStruct->card_info[index].base_add					= [self baseAddress];
    configStruct->card_info[index].deviceSpecificData[0]    = [self rawDataBufferLen];
    configStruct->card_info[index].deviceSpecificData[1]    = [self headerLen];
    configStruct->card_info[index].deviceSpecificData[2]    = [self writeHitsToEventMemoryMask]<<16 | [self histogramsEnabledMask];
    configStruct->card_info[index].deviceSpecificData[3]    = [self enabledMask];
	configStruct->card_info[index].num_Trigger_Indexes		= 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
}

- (BOOL) bumpRateFromDecodeStage:(unsigned short)channel
{
    if(isRunning)return NO;
    
    ++waveFormCount[channel];
    return YES;
}

- (uint32_t) waveFormCount:(int)aChannel
{
    return waveFormCount[aChannel];
}

-(void) startRates
{
    [self clearWaveFormCounts];
    [waveFormRateGroup start:self];
}

- (void) clearWaveFormCounts
{
    int i;
    for(i=0;i<kNumSIS3316Channels;i++){
        waveFormCount[i]=0;
    }
}
#pragma mark •••Reporting
- (void) settingsTable
{
    NSLogStartTable(@"Settings",80);
    NSLogMono(@"|Chan|Enabled|HESupp| CFD |\n");
    NSLogDivider(@"-",80);

    int i;
    for(i=0;i<kNumSIS3316Channels;i++){
        uint32_t rootAdd = [self baseAddress] + ((i/kNumSIS3316ChansPerGroup) + 1)*kSIS3316FpgaAdcRegOffset + 0x10*(i%kNumSIS3316ChansPerGroup);
        uint32_t firData = [self readLongFromAddress:rootAdd + 0x44];
        NSString* isEnabled   = ((firData>>31) & 0x1)?@"X":@"";
        NSString* isHeSupp    = ((firData>>30) & 0x1)?@"X":@"";
        NSString* cfdControl  = [NSString stringWithFormat:@"0x%01x", ((firData>>28) & 0x3)];
        NSString* thres       = [NSString stringWithFormat:@"0x%08x", (firData & 0xffffff)];
        NSLogMono(@"|%3d |%@|%@|%@|%@\n",i,[isEnabled centered:7],[isHeSupp centered:6],[cfdControl centered:5],thres);
    }
    NSLogDivider(@"=",80);

}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setEnabledMask:               [decoder decodeIntForKey: @"enabledMask"]];
    [self setFormatMask:                [decoder decodeIntForKey: @"formatMask"]];
    [self setEventConfigMask:           [decoder decodeIntForKey: @"eventConfigMask"]];
    [self setExtendedEventConfigBit:    [decoder decodeIntForKey: @"extendedEventConfigBit"]];
    [self setEndAddressSuppressionMask: [decoder decodeIntForKey: @"endAddressSuppressionMask"]];
    [self setHistogramsEnabledMask:     [decoder decodeIntForKey: @"histogramsEnabledMask"]];
    [self setHeSuppressTriggerMask:     [decoder decodeIntForKey: @"heSuppressTriggerMask"]];
    [self setGain:                      [decoder decodeIntegerForKey:   @"gain"]];
    [self setTermination:               [decoder decodeIntegerForKey:   @"termination"]];
    [self setTrigBothEdgesMask:         [decoder decodeIntForKey: @"trigBothEdgesMask"]];
    [self setIntHeTrigOutPulseMask:     [decoder decodeIntForKey: @"intHeTrigOutPulseMask"]];
    [self setLemoCoMask:                [decoder decodeIntForKey: @"lemoCoMask"]];
    [self setLemoUoMask:                [decoder decodeIntForKey: @"lemoUoMask"]];
    [self setLemoToMask:                [decoder decodeIntForKey: @"lemoToMask"]];
    [self setAcquisitionControlMask:    [decoder decodeIntForKey: @"acquisitionControlMask"]];
    [self setNIMControlStatusMask:      [decoder decodeIntForKey: @"nimControlStatusMask"]];
    [self setSharing:                   [decoder decodeIntForKey:   @"sharing"]];
//    [self setHsDiv:                     [decoder decodeIntegerForKey:   @"hsDiv"]];
//    [self setN1Div:                     [decoder decodeIntegerForKey:   @"n1Div"]];
    [self setRawDataBufferLen:          [decoder decodeIntForKey: @"rawDataBufferLen"]];
    [self setRawDataBufferStart:        [decoder decodeIntForKey: @"rawDataBufferStart"]];
    [self setPileUpWindow:              [decoder decodeIntForKey: @"pileUpWindowLength"]];
    [self setRePileUpWindow:            [decoder decodeIntForKey: @"rePileUpWindowLength"]];

    //load up all the C Arrays
    [[decoder decodeObjectForKey: @"mawBufferLength"]   loadULongCArray:mawBufferLength      size:kNumSIS3316Channels];
    [[decoder decodeObjectForKey: @"mawPretrigDelay"]   loadULongCArray:mawPretrigDelay      size:kNumSIS3316Channels];
    [[decoder decodeObjectForKey: @"cfdControlBits"]    loadULongCArray:cfdControlBits      size:kNumSIS3316Channels];
    [[decoder decodeObjectForKey: @"threshold"]         loadULongCArray:threshold           size:kNumSIS3316Channels];
    [[decoder decodeObjectForKey: @"riseTime"]          loadULongCArray:riseTime            size:kNumSIS3316Channels];
    [[decoder decodeObjectForKey: @"gapTime"]           loadULongCArray:gapTime             size:kNumSIS3316Channels];
    [[decoder decodeObjectForKey: @"tauFactor"]         loadULongCArray:tauFactor           size:kNumSIS3316Channels];
    [[decoder decodeObjectForKey: @"extraFilterBits"]   loadULongCArray:extraFilterBits     size:kNumSIS3316Channels];
    [[decoder decodeObjectForKey: @"tauTableBits"]      loadULongCArray:tauTableBits        size:kNumSIS3316Channels];
    [[decoder decodeObjectForKey: @"intTrigOutPulseBit"]loadUShortCArray:intTrigOutPulseBit size:kNumSIS3316Channels];
    [[decoder decodeObjectForKey: @"heTrigThreshold"]   loadULongCArray:heTrigThreshold     size:kNumSIS3316Channels];
    [[decoder decodeObjectForKey: @"energyOffsets"] loadUShortCArray:energyOffset   size:kNumSIS3316Channels];
    [[decoder decodeObjectForKey: @"energyDivider"]     loadUShortCArray:energyDivider      size:kNumSIS3316Channels];

    [[decoder decodeObjectForKey: @"dacOffsets"]                loadUShortCArray:dacOffsets                 size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"activeTrigGateWindowLen"]   loadUShortCArray:activeTrigGateWindowLen    size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"endAddress"]                loadULongCArray:endAddress                  size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"triggerDelay"]              loadUShortCArray:triggerDelay               size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"enableSum"]                 loadBoolCArray:enableSum                    size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"thresholdSum"]              loadULongCArray:thresholdSum                size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"heTrigThresholdSum"]        loadULongCArray:heTrigThresholdSum          size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"gapTimeSum"]                loadULongCArray:gapTimeSum                  size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"riseTimeSum"]               loadULongCArray:riseTimeSum                 size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"cfdControlBitsSum"]         loadULongCArray:cfdControlBitsSum           size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"preTriggerDelay"]           loadUShortCArray:preTriggerDelay            size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate1Start"]             loadUShortCArray:accGate1Start              size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate2Start"]             loadUShortCArray:accGate2Start              size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate3Start"]             loadUShortCArray:accGate3Start              size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate4Start"]             loadUShortCArray:accGate4Start              size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate5Start"]             loadUShortCArray:accGate5Start              size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate6Start"]             loadUShortCArray:accGate6Start              size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate7Start"]             loadUShortCArray:accGate7Start              size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate8Start"]             loadUShortCArray:accGate8Start              size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate1Len"]               loadUShortCArray:accGate1Len                size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate2Len"]               loadUShortCArray:accGate2Len                size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate3Len"]               loadUShortCArray:accGate3Len                size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate4Len"]               loadUShortCArray:accGate4Len                size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate5Len"]               loadUShortCArray:accGate5Len                size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate6Len"]               loadUShortCArray:accGate6Len                size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate7Len"]               loadUShortCArray:accGate7Len                size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate8Len"]               loadUShortCArray:accGate8Len                size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"internalGateLen"]           loadULongCArray:internalGateLen             size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"internalCoinGateLen"]       loadULongCArray:internalCoinGateLen         size:kNumSIS3316Groups];

	//clocks
    [self setClockSource:			[decoder decodeIntForKey:@"clockSource"]];
			
    [self setWaveFormRateGroup:     [decoder decodeObjectForKey:@"waveFormRateGroup"]];
    
    if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:kNumSIS3316Channels groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];


    [[self undoManager] enableUndoRegistration];
    
    return self;
}


- (void) setUpEmptyArray:(SEL)aSetter numItems:(int)n
{
    NSMutableArray* anArray = [NSMutableArray arrayWithCapacity:n];
    int i;
    for(i=0;i<n;i++)[anArray addObject:[NSNumber numberWithInt:0]];
    NSMethodSignature* signature = [[self class] instanceMethodSignatureForSelector:aSetter];
    NSInvocation* invocation     = [NSInvocation invocationWithMethodSignature: signature];
    [invocation setTarget:   self];
    [invocation setSelector: aSetter];
    [invocation setArgument: &anArray atIndex: 2];
    [invocation invoke];

}

- (void) setUpArray:(SEL)aSetter intValue:(int)aValue numItems:(int)n
{
    NSMutableArray* anArray = [NSMutableArray arrayWithCapacity:n];
    int i;
    for(i=0;i<n;i++)[anArray addObject:[NSNumber numberWithInt:aValue]];
    NSMethodSignature* signature = [[self class] instanceMethodSignatureForSelector:aSetter];
    NSInvocation* invocation     = [NSInvocation invocationWithMethodSignature: signature];
    [invocation setTarget:   self];
    [invocation setSelector: aSetter];
    [invocation setArgument: &anArray atIndex: 2];
    [invocation invoke];
    
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];

    [encoder encodeInteger: gain                       forKey:@"gain"];
    [encoder encodeInteger: termination                forKey:@"termination"];
    [encoder encodeInt:     enabledMask                forKey:@"enabledMask"];
    [encoder encodeInt:     formatMask                 forKey:@"formatMask"];
    [encoder encodeInt:     eventConfigMask            forKey:@"eventConfigMask"];
    [encoder encodeInt:     extendedEventConfigBit     forKey:@"extendedEventConfigBit"];
    [encoder encodeInt: endAddressSuppressionMask  forKey:@"endAddressSuppressionMask"];
    [encoder encodeInt: histogramsEnabledMask      forKey:@"histogramsEnabledMask"];
    [encoder encodeInteger: pileupEnabledMask          forKey:@"pileupEnabledMask"];
    [encoder encodeInteger: clrHistogramsWithTSMask    forKey:@"clrHistogramsWithTSMask"];
    [encoder encodeInteger: writeHitsToEventMemoryMask forKey:@"writeHitsToEventMemoryMask"];
    [encoder encodeInt: heSuppressTriggerMask      forKey:@"heSuppressTriggerMask"];
    [encoder encodeInt: trigBothEdgesMask          forKey:@"trigBothEdgesMask"];
    [encoder encodeInt: intHeTrigOutPulseMask      forKey:@"intHeTrigOutPulseMask"];
    [encoder encodeInt: lemoToMask                 forKey:@"lemoToMask"];
    [encoder encodeInt: lemoUoMask                 forKey:@"lemoUoMask"];
    [encoder encodeInt: acquisitionControlMask     forKey:@"acquisitionControlMask"];
    [encoder encodeInt: rawDataBufferLen           forKey:@"rawDataBufferLen"];
    [encoder encodeInt: rawDataBufferStart         forKey:@"rawDataBufferStart"];

    //clocks
    [encoder encodeInt:   clockSource                forKey:@"clockSource"];
    [encoder encodeInteger:   sharing                    forKey:@"sharing"];
//    [encoder encodeInteger:   hsDiv                      forKey:@"hsDiv"];
//    [encoder encodeInteger:   n1Div                      forKey:@"n1Div"];
    [encoder encodeObject:waveFormRateGroup          forKey:@"waveFormRateGroup"];
    [encoder encodeInt: nimControlStatusMask       forKey:@"nimControlStatusMask"];
    [encoder encodeInt: pileUpWindowLength         forKey:@"pileUpWindowLength"];
    [encoder encodeInt: rePileUpWindowLength       forKey:@"rePileUpWindowLength"];

    //handle all the C Arrays
    [encoder encodeObject: [NSArray arrayFromULongCArray:mawBufferLength            size:kNumSIS3316Channels] forKey:@"mawBufferLength"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:mawPretrigDelay            size:kNumSIS3316Channels] forKey:@"mawPretrigDelay"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:cfdControlBits             size:kNumSIS3316Channels] forKey:@"cfdControlBits"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:extraFilterBits            size:kNumSIS3316Channels] forKey:@"extraFilterBits"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:tauTableBits               size:kNumSIS3316Channels] forKey:@"tauTableBits"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:threshold                  size:kNumSIS3316Channels] forKey:@"threshold"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:gapTime                    size:kNumSIS3316Channels] forKey:@"gapTime"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:tauFactor                  size:kNumSIS3316Channels] forKey:@"tauFactor"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:heTrigThreshold            size:kNumSIS3316Channels] forKey:@"heTrigThreshold"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:dacOffsets                size:kNumSIS3316Groups]   forKey:@"dacOffsets"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:endAddress                 size:kNumSIS3316Groups]   forKey:@"endAddress"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:triggerDelay              size:kNumSIS3316Groups]   forKey:@"triggerDelay"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:activeTrigGateWindowLen   size:kNumSIS3316Groups]   forKey:@"activeTrigGateWindowLen"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:preTriggerDelay           size:kNumSIS3316Groups]   forKey:@"preTriggerDelay"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate1Len               size:kNumSIS3316Groups]   forKey:@"accGate1Len"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate2Len               size:kNumSIS3316Groups]   forKey:@"accGate2Len"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate3Len               size:kNumSIS3316Groups]   forKey:@"accGate3Len"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate4Len               size:kNumSIS3316Groups]   forKey:@"accGate4Len"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate5Len               size:kNumSIS3316Groups]   forKey:@"accGate5Len"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate6Len               size:kNumSIS3316Groups]   forKey:@"accGate6Len"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate7Len               size:kNumSIS3316Groups]   forKey:@"accGate7Len"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate8Len               size:kNumSIS3316Groups]   forKey:@"accGate8Len"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate1Start             size:kNumSIS3316Groups]   forKey:@"accGate1Start"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate2Start             size:kNumSIS3316Groups]   forKey:@"accGate2Start"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate3Start             size:kNumSIS3316Groups]   forKey:@"accGate3Start"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate4Start             size:kNumSIS3316Groups]   forKey:@"accGate4Start"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate5Start             size:kNumSIS3316Groups]   forKey:@"accGate5Start"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate6Start             size:kNumSIS3316Groups]   forKey:@"accGate6Start"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate7Start             size:kNumSIS3316Groups]   forKey:@"accGate7Start"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate8Start             size:kNumSIS3316Groups]   forKey:@"accGate8Start"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:thresholdSum               size:kNumSIS3316Groups]   forKey:@"thresholdSum"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:heTrigThresholdSum         size:kNumSIS3316Groups]   forKey:@"heTrigThresholdSum"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:gapTimeSum                 size:kNumSIS3316Groups]   forKey:@"gapTimeSum"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:riseTime                   size:kNumSIS3316Groups]   forKey:@"riseTime"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:cfdControlBitsSum          size:kNumSIS3316Groups]   forKey:@"cfdControlBitsSum"];
    [encoder encodeObject: [NSArray arrayFromBoolCArray:enableSum                   size:kNumSIS3316Groups]   forKey:@"enableSum"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:internalGateLen            size:kNumSIS3316Groups]   forKey:@"internalGateLen"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:internalCoinGateLen        size:kNumSIS3316Groups]   forKey:@"internalCoinGateLen"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:energyOffset              size:kNumSIS3316Channels] forKey:@"energyOffset"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:energyDivider             size:kNumSIS3316Channels] forKey:@"energyDivider"];

}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];

    [objDictionary setObject: [NSNumber numberWithLong:enabledMask]                 forKey:@"enabledMask"];
    [objDictionary setObject: [NSNumber numberWithLong:formatMask]                  forKey:@"formatMask"];
    [objDictionary setObject: [NSNumber numberWithLong:eventConfigMask]             forKey:@"eventConfigMask"];
    [objDictionary setObject: [NSNumber numberWithLong:extendedEventConfigBit]      forKey:@"extendedEventConfigBit"];
    [objDictionary setObject: [NSNumber numberWithLong:endAddressSuppressionMask]   forKey:@"endAddressSuppressionMask"];

    [objDictionary setObject: [NSNumber numberWithLong:histogramsEnabledMask]       forKey:@"histogramsEnabledMask"];
    [objDictionary setObject: [NSNumber numberWithLong:pileupEnabledMask    ]       forKey:@"pileupEnabledMask"];
    [objDictionary setObject: [NSNumber numberWithLong:clrHistogramsWithTSMask]     forKey:@"clrHistogramsWithTSMask"];
    [objDictionary setObject: [NSNumber numberWithLong:writeHitsToEventMemoryMask]  forKey:@"writeHitsToEventMemoryMask"];
    [objDictionary setObject: [NSNumber numberWithLong:heSuppressTriggerMask]       forKey:@"heSuppressTriggerMask"];
    [objDictionary setObject: [NSNumber numberWithLong:trigBothEdgesMask]           forKey:@"trigBothEdgesMask"];
    [objDictionary setObject: [NSNumber numberWithLong:intHeTrigOutPulseMask]       forKey:@"intHeTrigOutPulseMask"];
    [objDictionary setObject: [NSNumber numberWithLong:rawDataBufferLen]            forKey:@"rawDataBufferLen"];
    [objDictionary setObject: [NSNumber numberWithLong:rawDataBufferStart]          forKey:@"rawDataBufferStart"];
    [objDictionary setObject: [NSNumber numberWithLong:pileUpWindowLength]          forKey:@"pileUpWindowLength"];
    [objDictionary setObject: [NSNumber numberWithLong:rePileUpWindowLength]        forKey:@"rePileUpWindowLength"];


    [self addCurrentState:objDictionary unsignedLongArray:mawBufferLength           size:kNumSIS3316Channels forKey:@"mawBufferLength"];
    [self addCurrentState:objDictionary unsignedLongArray:mawPretrigDelay           size:kNumSIS3316Channels forKey:@"mawPretrigDelay"];
    [self addCurrentState:objDictionary unsignedLongArray:cfdControlBits            size:kNumSIS3316Channels forKey:@"cfdControlBits"];
    [self addCurrentState:objDictionary unsignedLongArray:extraFilterBits           size:kNumSIS3316Channels forKey:@"extraFilterBits"];
    [self addCurrentState:objDictionary unsignedLongArray:tauTableBits              size:kNumSIS3316Channels forKey:@"tauTableBits"];
    [self addCurrentState:objDictionary unsignedLongArray:threshold                 size:kNumSIS3316Channels forKey:@"threshold"];
    [self addCurrentState:objDictionary unsignedLongArray:riseTime                  size:kNumSIS3316Channels forKey:@"riseTime"];
    [self addCurrentState:objDictionary unsignedLongArray:gapTime                   size:kNumSIS3316Channels forKey:@"gapTime"];
    [self addCurrentState:objDictionary unsignedLongArray:tauFactor                 size:kNumSIS3316Channels forKey:@"tauFactor"];
    [self addCurrentState:objDictionary unsignedShortArray:intTrigOutPulseBit       size:kNumSIS3316Channels forKey:@"intTrigOutPulseBit"];
    [self addCurrentState:objDictionary unsignedLongArray:heTrigThreshold           size:kNumSIS3316Channels forKey:@"heTrigThreshold"];
    [self addCurrentState:objDictionary unsignedShortArray:energyDivider            size:kNumSIS3316Channels forKey:@"energyDivider"];

    [self addCurrentState:objDictionary unsignedShortArray:activeTrigGateWindowLen  size:kNumSIS3316Groups   forKey:@"activeTrigGateWindowLen" ];
    [self addCurrentState:objDictionary unsignedShortArray:preTriggerDelay          size:kNumSIS3316Groups   forKey:@"preTriggerDelay"];
    
    [self addCurrentState:objDictionary unsignedLongArray:heTrigThresholdSum        size:kNumSIS3316Groups   forKey:@"heTrigThresholdSum"];
    [self addCurrentState:objDictionary unsignedLongArray:thresholdSum              size:kNumSIS3316Groups   forKey:@"ThresholdSum"];

    [self addCurrentState:objDictionary unsignedShortArray:triggerDelay             size:kNumSIS3316Groups   forKey:@"triggerDelay"];

    [self addCurrentState:objDictionary unsignedShortArray:accGate1Start            size:kNumSIS3316Groups   forKey:@"accGate1Start"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate2Start            size:kNumSIS3316Groups   forKey:@"accGate2Start"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate3Start            size:kNumSIS3316Groups   forKey:@"accGate3Start"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate4Start            size:kNumSIS3316Groups   forKey:@"accGate4Start"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate5Start            size:kNumSIS3316Groups   forKey:@"accGate5Start"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate6Start            size:kNumSIS3316Groups   forKey:@"accGate6Start"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate7Start            size:kNumSIS3316Groups   forKey:@"accGate7Start"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate8Start            size:kNumSIS3316Groups   forKey:@"accGate8Start"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate1Len              size:kNumSIS3316Groups   forKey:@"accGate1Len"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate2Len              size:kNumSIS3316Groups   forKey:@"accGate2Len"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate3Len              size:kNumSIS3316Groups   forKey:@"accGate3Len"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate4Len              size:kNumSIS3316Groups   forKey:@"accGate4Len"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate5Len              size:kNumSIS3316Groups   forKey:@"accGate5Len"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate6Len              size:kNumSIS3316Groups   forKey:@"accGate6Len"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate7Len              size:kNumSIS3316Groups   forKey:@"accGate7Len"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate8Len              size:kNumSIS3316Groups   forKey:@"accGate8Len"];
    [self addCurrentState:objDictionary unsignedShortArray:energyOffset             size:kNumSIS3316Channels forKey:@"energyOffset"];
    [self addCurrentState:objDictionary unsignedShortArray:dacOffsets               size:kNumSIS3316Groups   forKey:@"daqOffsets"];
	
	//acq
	[objDictionary setObject: [NSNumber numberWithBool:bankSwitchMode]		forKey:@"bankSwitchMode"];
	[objDictionary setObject: [NSNumber numberWithBool:autoStart]			forKey:@"autoStart"];
	[objDictionary setObject: [NSNumber numberWithBool:multiEventMode]		forKey:@"multiEventMode"];
	[objDictionary setObject: [NSNumber numberWithBool:multiplexerMode]		forKey:@"multiplexerMode"];
	[objDictionary setObject: [NSNumber numberWithBool:lemoStartStop]		forKey:@"lemoStartStop"];
	[objDictionary setObject: [NSNumber numberWithBool:p2StartStop]			forKey:@"p2StartStop"];
	[objDictionary setObject: [NSNumber numberWithBool:gateMode]			forKey:@"gateMode"];

 	//clocks
	[objDictionary setObject: [NSNumber numberWithInteger:clockSource]			forKey:@"clockSource"];
	
    return objDictionary;
}

- (NSArray*) autoTests
{
	NSMutableArray* myTests = [NSMutableArray array];
//	[myTests addObject:[ORVmeReadOnlyTest test:kControlStatus wordSize:4 name:@"Control Status"]];
//	[myTests addObject:[ORVmeReadOnlyTest test:kModuleIDReg wordSize:4 name:@"Module ID"]];
//	[myTests addObject:[ORVmeReadOnlyTest test:kAcquisitionControlReg wordSize:4 name:@"Acquisition Reg"]];
//	[myTests addObject:[ORVmeReadWriteTest test:kStartDelay wordSize:4 validMask:0x000000ff name:@"Start Delay"]];
//	[myTests addObject:[ORVmeWriteOnlyTest test:kGeneralReset wordSize:4 name:@"Reset"]];
//	[myTests addObject:[ORVmeWriteOnlyTest test:kStartSampling wordSize:4 name:@"Start Sampling"]];
//	[myTests addObject:[ORVmeWriteOnlyTest test:kStopSampling wordSize:4 name:@"Stop Sampling"]];
//	[myTests addObject:[ORVmeWriteOnlyTest test:kStartAutoBankSwitch wordSize:4 name:@"Stop Auto Bank Switch"]];
//	[myTests addObject:[ORVmeWriteOnlyTest test:kStopAutoBankSwitch wordSize:4 name:@"Start Auto Bank Switch"]];
//	[myTests addObject:[ORVmeWriteOnlyTest test:kClearBank1FullFlag wordSize:4 name:@"Clear Bank1 Full"]];
//	[myTests addObject:[ORVmeWriteOnlyTest test:kClearBank2FullFlag wordSize:4 name:@"Clear Bank2 Full"]];
//	
//	int i;
//	for(i=0;i<4;i++){
//		[myTests addObject:[ORVmeReadWriteTest test:thresholdRegOffsets[i] wordSize:4 validMask:0xffffffff name:@"Threshold"]];
//		int j;
//		for(j=0;j<2;j++){
//			[myTests addObject:[ORVmeReadOnlyTest test:bankMemory[i][j] length:64*1024 wordSize:4 name:@"Adc Memory"]];
//		}
//	}
	return myTests;
}
- (void) writeLong:(uint32_t)aValue toAddress:(uint32_t)anAddress
{
    [[self adapter] writeLongBlock: &aValue
                         atAddress: anAddress
                        numToWrite: 1
                        withAddMod: [self addressModifier]
                     usingAddSpace: 0x01];
}
- (uint32_t) readLongFromAddress:(uint32_t)anAddress
{
    uint32_t aValue = 0;
    [[self adapter] readLongBlock:&aValue
                        atAddress:anAddress
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return aValue;
}

#pragma mark •••Reporting
- (void) dumpChan0
{
    [self readModuleID:YES];
    [self readFirmwareVersion:YES];
    [self readHWVersion:YES];
    [self readTemperature:YES];
    [self readSerialNumber:YES];
    [self readVetoGateDelayReg:YES];
    [self readClockSource:YES];
    [self readFpBusControl:YES];
    [self readNIMControlStatus:YES];
    [self readAcquisitionRegister:YES];
    [self readTrigCoinLUControl:YES];
    [self readTrigCoinLUAddress:YES];
    [self readTrigCoinLUData:YES];
    [self readLemoOutCOSelect:YES];
    [self readLemoOutTOSelect:YES];
    [self readLemoOutUOSelect:YES];
    [self readIntTrigFeedBackSelect:YES];
    
    [self dumpFPGADataTransferStatus];
    [self readVmeFpgaAdcDataLinkStatus:YES];
    [self readPrescalerOutPulseDivider:YES];
    [self readPrescalerOutPulseLength:YES];
    [self dumpInternalTriggerCounters];
    [self dumpTapDelayRegister];
    [self dumpGainTerminationControl];
    [self dumpAdcOffsetReadback];
    [self dumpEventConfiguration];
    [self dumpExtendedEventConfiguration];
    [self dumpChannelHeaderID];
    [self dumpEndAddressThreshold];
    [self dumpActiveTrigGateWindowLen];
    [self dumpRawDataBufferConfig];
    [self dumpPileupConfig];
    [self dumpPreTriggerDelay];
    [self dumpAveConfig];
    [self dumpDataFormatConfig];
    [self dumpMawBufferConfig];
    [self dumpInternalTriggerDelayConfig];
    [self dumpInternalGateLengthConfig];
    [self dumpFirTriggerSetup];
    [self dumpSumFirTriggerSetup];
    [self dumpTriggerThreshold];
    [self dumpSumTriggerThreshold];
    [self dumpHeTriggerThreshold];
    [self dumpHeSumTriggerThreshold];
    [self dumpStatisticCounterMode];
    [self dumpPeakChargeConfig];
    [self dumpExtededRawDataBufferConfig];
    [self dumpAccumulatorGates];
    [self dumpFPGAStatus];
}
- (void) setupSharing
{
    int sharing = 0; //no sharing for now.. move to GUI selection
    int fp_lvds_bus_control_value = 0 ;
    if (sharing == 1) {
        fp_lvds_bus_control_value = fp_lvds_bus_control_value + 0x10  ;
    }
    if (sharing == 2) {
        fp_lvds_bus_control_value = fp_lvds_bus_control_value + 0x20  ;
    }
    [self writeLong:fp_lvds_bus_control_value toAddress:[self singleRegister:kFPBusControlReg]];
}

- (void) setupClock
{
    //----------------------------------------------------------
    //clock setup from Matthias example code...
    uint32_t addr = [self singleRegister:kAdcDataLinkStatusReg];
    [self writeLong:0xE0E0E0E0 toAddress:addr];  // clear error Latch bits
    uint32_t aValue =  [self readLongFromAddress:addr];
    if (aValue != 0x18181818) {
        NSLogColor([NSColor redColor],@"Error: SIS3316_VME_FPGA_LINK_ADC_PROT_STATUS: data = 0x%08x\n", aValue);
    }

    //bypass the external clock multiplier
    [self writesi5325ClkMultiplier: 0 data: 0x2]; // Bypass
    [self writesi5325ClkMultiplier:11 data:0x02]; //  PowerDown clk2
    //end bypass
    
    [self writeClockSource];
    
    uint32_t adcFpgaFirmwareVersion = [self readLongFromAddress:[self singleRegister:kAdcVersionReg]];
    adcFpgaFirmwareVersion &= 0xFFFF;
    unsigned int clock_N1div_array[16]    ;
    unsigned int clock_HSdiv_array[16]    ;
    unsigned int iob_delay_14bit_array[16];
    unsigned int iob_delay_16bit_array[16];
    double double_fft_frequency_array[16] ;
    
    if (adcFpgaFirmwareVersion < 4) {
        // 250.000 MHz
        iob_delay_14bit_array[0]  =  0x48  ;
        iob_delay_16bit_array[0]  =  0x00  ;
        // 125.000 MHz
        iob_delay_14bit_array[6]  =  0x50  ;
        iob_delay_16bit_array[6]  =  0x7F  ;
        // 119.048 MHz
        iob_delay_14bit_array[7]  =  0x60  ;
        iob_delay_16bit_array[7]  =  0x7F  ;
        
        // 113.636 MHz
        iob_delay_14bit_array[8]  =  0x1010  ;
        iob_delay_16bit_array[8]  =  0x7F ;
        // 71.429 MHz
        iob_delay_14bit_array[12] =  0x1060  ;
        iob_delay_16bit_array[12] =  0x0000 ;
    }
    else {
        // 250.000 MHz
        iob_delay_14bit_array[0]  =  0x1002;
        iob_delay_16bit_array[0]  =  0x00  ;
        // 125.000 MHz
        iob_delay_14bit_array[6]  =  0x50  ;
        iob_delay_16bit_array[6]  =  0x1020  ;
        // 119.048 MHz
        iob_delay_14bit_array[7]  =  0x60  ;
        iob_delay_16bit_array[7]  =  0x1020  ;
        
        // 113.636 MHz
        iob_delay_14bit_array[8]  =  0x1010  ;
        iob_delay_16bit_array[8]  =  0x1020  ;
        // 71.429 MHz
        iob_delay_14bit_array[12] =  0x1060  ;
        iob_delay_16bit_array[12] =  0x1060 ;
    }
    // 227.273
    iob_delay_14bit_array[1]  =  0x101f ;
    iob_delay_16bit_array[1]  =  0x000  ;
    // 208,333 MHz
    iob_delay_14bit_array[2]  =  0x1035  ;
    iob_delay_16bit_array[2]  =  0x000  ;
    // 178,571 MHz
    iob_delay_14bit_array[3]  =  0x12  ;
    iob_delay_16bit_array[3]  =  0x000  ;
    
    // 166.667 MHz
    iob_delay_14bit_array[4]  =  0x20  ;
    iob_delay_16bit_array[4]  =  0x000  ;
    // 138.889 MHz
    iob_delay_14bit_array[5]  =  0x35  ;
    iob_delay_16bit_array[5]  =  0x000  ;
    
    // 104.167 MHz
    iob_delay_14bit_array[9]  =  0x1020  ;
    iob_delay_16bit_array[9]  =  0x1030  ;
    // 100.000 MHz
    iob_delay_14bit_array[10] =  0x1020  ;
    iob_delay_16bit_array[10] =  0x1030  ;
    // 83.333 MHz
    iob_delay_14bit_array[11] =  0x1030  ;
    iob_delay_16bit_array[11] =  0x1040  ;
    
    // 62.500 MHz
    iob_delay_14bit_array[13] =  0x1060  ;
    iob_delay_16bit_array[13] =  0x20  ;
    // 50.000 MHz
    iob_delay_14bit_array[14] =  0x20  ;
    iob_delay_16bit_array[14] =  0x30  ;
    // 25.000 MHz
    iob_delay_14bit_array[15] =  0x20  ;
    iob_delay_16bit_array[15] =  0x30  ;
    
    // 250.000 MHz
    clock_N1div_array[0]      =  4  ;
    clock_HSdiv_array[0]      =  5  ;
    double_fft_frequency_array[0]  =  250000000.0  ;
    
    // 227.273
    clock_N1div_array[1]      =  2  ;
    clock_HSdiv_array[1]      =  11  ;
    double_fft_frequency_array[1]  =  227273000.0  ;
    
    // 208,333 MHz
    clock_N1div_array[2]      =  4  ;
    clock_HSdiv_array[2]      =  6  ;
    double_fft_frequency_array[2]  =  208333000.0  ;
    
    // 178,571 MHz
    clock_N1div_array[3]      =  4  ;
    clock_HSdiv_array[3]      =  7  ;
    double_fft_frequency_array[3]  =  178571000.0  ;
    
    // 166.667 MHz
    clock_N1div_array[4]      =  6  ;
    clock_HSdiv_array[4]      =  5  ;
    double_fft_frequency_array[4]  =  166667000.0  ;
    
    // 138.889 MHz
    clock_N1div_array[5]      =  6  ;
    clock_HSdiv_array[5]      =  6  ;
    double_fft_frequency_array[5]  =  138889000.0  ;
    
    // 125.000 MHz
    clock_N1div_array[6]      =  8  ;
    clock_HSdiv_array[6]      =  5  ;
    double_fft_frequency_array[6]  =  125000000.0  ;
    
    // 119.048 MHz
    clock_N1div_array[7]      =  6  ;
    clock_HSdiv_array[7]      =  7  ;
    double_fft_frequency_array[7]  =  119048000.0  ;
    
    // 113.636 MHz
    clock_N1div_array[8]      =  4  ;
    clock_HSdiv_array[8]      =  11  ;
    double_fft_frequency_array[8]  =  113636000.0  ;
    
    // 104.167 MHz
    clock_N1div_array[9]      =  8  ;
    clock_HSdiv_array[9]      =  6  ;
    double_fft_frequency_array[9]  =  104167000.0  ;
    
    // 100.000 MHz
    clock_N1div_array[10]     =  10  ;
    clock_HSdiv_array[10]     =  5  ;
    double_fft_frequency_array[10]  =  100000000.0  ;
    
    // 83.333 MHz
    clock_N1div_array[11]     =  12  ;
    clock_HSdiv_array[11]     =  5  ;
    double_fft_frequency_array[11]  =  83333000.0  ;
    
    
    // 71.429 MHz
    clock_N1div_array[12]     =  14  ;
    clock_HSdiv_array[12]     =  5  ;
    double_fft_frequency_array[12]  =  71429000.0  ;
    
    
    // 62.500 MHz
    clock_N1div_array[13]     =  16  ;
    clock_HSdiv_array[13]     =  5  ;
    double_fft_frequency_array[13]  =  62500000.0  ;
    
    
    // 50.000 MHz
    clock_N1div_array[14]     =  20  ;
    clock_HSdiv_array[14]     =  5  ;
    double_fft_frequency_array[14]  =  50000000.0  ;
    
    // 25.000 MHz
    clock_N1div_array[15]     =  40  ;
    clock_HSdiv_array[15]     =  5  ;
    double_fft_frequency_array[15]  =  25000000.0  ;
    
    // set internal Frequency
    uint32_t clock_freq_choice=0;
    //    if (clock_freq_choice >= 16) {
    //        clock_freq_choice = 0 ;
    //        fCombo_SetInternalClockFreq->Select(clock_freq_choice, kTRUE); //  set frequency to 250 MHz
    //    }
    if (adc125MHzFlag == 1) {
        clock_freq_choice = 6 ;
    }
    
    //double double_clock_configure_fft_frequency = double_fft_frequency_array[clock_freq_choice] ;
    int clock_N1div_val = clock_N1div_array[clock_freq_choice] ;
    int clock_HSdiv_val = clock_HSdiv_array[clock_freq_choice] ;
    int iobDelayValue ;
    
    if (adc125MHzFlag == 1) iobDelayValue = iob_delay_16bit_array[clock_freq_choice];
    else                    iobDelayValue = iob_delay_14bit_array[clock_freq_choice];
    
    [self changeFrequencyHsDivN1Div:0 hsDiv:clock_HSdiv_val n1Div:clock_N1div_val]; // reprogram internal Osc.
    [self resetADCClockDCM];
    [self configureAdcFpgaIobDelays:iobDelayValue];
    [self enableAdcSpiAdcOutputs]; //enable ADC outputs (bit was cleared with Key-reset !)
}
@end

@implementation ORSIS3316Model (private)

#define kSi5325MaxSpiPollCounter   100
- (int) writesi5325ClkMultiplier:(uint32_t) addr data:(uint32_t) data
{
    // write address
    uint32_t write_data = 0x0000 + (addr & 0xff) ; // write ADDR Instruction + register addr
    [self writeLong:write_data toAddress:[self singleRegister:kExtNIMClockMulSpiReg]];
    usleep(10000) ;
    
    uint32_t  read_data ;
    uint32_t poll_counter = 0 ;
    do {
        poll_counter++;
        read_data = [self readLongFromAddress:[self singleRegister:kExtNIMClockMulSpiReg]];
    } while (((read_data & 0x80000000) == 0x80000000) && (poll_counter < kSi5325MaxSpiPollCounter)) ;
    if (poll_counter == kSi5325MaxSpiPollCounter) {    return -2 ;    }
    usleep(10000) ;
    
    // write data
    write_data = 0x4000 + (data & 0xff) ; // write Instruction + data
    [self writeLong:write_data toAddress:[self singleRegister:kExtNIMClockMulSpiReg]];
    usleep(10000) ;
    
    poll_counter = 0 ;
    do {
        poll_counter++;
        read_data = [self readLongFromAddress:[self singleRegister:kExtNIMClockMulSpiReg]];
    } while (((read_data & 0x80000000) == 0x80000000) && (poll_counter < kSi5325MaxSpiPollCounter)) ;
    if (poll_counter == kSi5325MaxSpiPollCounter) {    return -2 ;    }
    
    return 0 ;
}
- (int) adcSpiSetup
{
    uint32_t  data;
    unsigned iGroup;
    
    // disable ADC output
    for (iGroup = 0; iGroup < kNumSIS3316Groups; iGroup++) {
        [self writeLong:0x0 toAddress:[self groupRegister:kAdcSpiControlReg group:iGroup]];
    }
    
    // dummy loop to access each adc chip one time after power up -- add 12.02.2015
    unsigned iChip;
    for (iGroup = 0; iGroup < kNumSIS3316Groups; iGroup++) {
        for (iChip = 0; iChip < 2; iChip++) {
            [self readAdcSpiGroup:iGroup chip:iChip address:1 data:&data];
        }
    }
    
    // reset
    for (iGroup = 0; iGroup < kNumSIS3316Groups; iGroup++) {
        for (iChip = 0; iChip < 2; iChip++) {
            [self writeAdcSpiGroup:iGroup chip:iChip address: 0x0 data:0x24]; // soft reset
        }
        usleep(10) ; // after reset
    }
    
    uint32_t adcChipId;
    [self readAdcSpiGroup:0 chip:0 address:1 data:&adcChipId]; // read chip Id from adc chips ch1/2
    
    for (iGroup = 0; iGroup < kNumSIS3316Groups; iGroup++) {
        for (iChip = 0; iChip < 2; iChip++) {
            [self readAdcSpiGroup:iGroup chip: iChip address: 1 data:&data];
            if (data != adcChipId) {
                NSLog(@"iGroup = %d   iChip = %d    data = 0x%08x     adcChipId = 0x%08x     \n", iGroup, iChip, data, adcChipId);
                return -1 ;
            }
        }
    }
    
    adc125MHzFlag = 0;
    if ((adcChipId&0xff) == 0x32) {
        adc125MHzFlag = 1;
    }
    
    
    // reg 0x14 : Output mode
    if (adc125MHzFlag == 0) { // 250 MHz chip AD9643
        data = 0x04 ;     //  Output inverted (bit2 = 1)
    }
    else { // 125 MHz chip AD9268
        data = 0x40 ;     // Output type LVDS (bit6 = 1), Output inverted (bit2 = 0) !
    }
    for (iGroup = 0; iGroup < kNumSIS3316Groups; iGroup++) {
        for (iChip = 0; iChip < 2; iChip++) {
            [self writeAdcSpiGroup:iGroup chip:iChip address: 0x14 data: data];
        }
    }
    
    // reg 0x18 : Reference Voltage / Input Span
    if (adc125MHzFlag == 0) { // 250 MHz chip AD9643
        data = 0x0 ;     //  1.75V
    }
    else { // 125 MHz chip AD9268
        //data = 0x8 ;     //  1.75V
        data = 0xC0 ;     //  2.0V
    }
    for (iGroup = 0; iGroup < kNumSIS3316Groups; iGroup++) {
        for (iChip = 0; iChip < 2; iChip++) {
            [self writeAdcSpiGroup: iGroup chip:iChip address: 0x18 data: data];
        }
    }
    
    // reg 0xff : register update
    data = 0x01 ;     // update
    for (iGroup = 0; iGroup < kNumSIS3316Groups; iGroup++) {
        for (iChip = 0; iChip < 2; iChip++) {
            [self writeAdcSpiGroup:iGroup chip: iChip address: 0xff data: data];
        }
    }
    
    // enable ADC output
    for (iGroup = 0; iGroup < kNumSIS3316Groups; iGroup++) {
        [self writeLong:0x1000000 toAddress:[self groupRegister:kAdcSpiControlReg group:iGroup]];
    }
    
    
    return 0 ;
}
- (void) enableAdcSpiAdcOutputs
{
    unsigned iGroup;
    for (iGroup = 0; iGroup < kNumSIS3316Groups; iGroup++) {
        [self writeLong:0x1000000 toAddress:[self groupRegister:kAdcSpiControlReg group:iGroup]]; //  set bit 24
    }
}

- (int) changeFrequencyHsDivN1Div:(int) osc hsDiv:(NSUInteger) hs_div_val n1Div:( unsigned) n1_div_val
{
    int rc;
    unsigned i ;
    unsigned N1div ;
    unsigned HSdiv ;
    unsigned HSdiv_reg[6] = {0,1,2,3,5,7};
    unsigned HSdiv_val[6] = {4,5,6,7,9,11};
    unsigned char freqSI570_high_speed_rd_value[6];
    unsigned char freqSI570_high_speed_wr_value[6];
    
    if(osc > 3 || osc < 0){
        return -100;
    }
    
    HSdiv = 0xff ;
    for (i=0;i<6;i++){
        if (HSdiv_val[i] == hs_div_val) {
            HSdiv = HSdiv_reg[i] ;
        }
    }
    if (HSdiv > 11) {
        return -101;
    }
    
    // gt than 127 or odd then return
    if((n1_div_val > 127) || ((n1_div_val & 0x1) == 1) || (n1_div_val == 0) ) {
        return -102;
    }
    N1div = n1_div_val - 1 ;
    
    rc = [self si570ReadDivider:osc values:freqSI570_high_speed_rd_value];
    if(rc){
        NSLog(@"Si570ReadDivider = %d \n",rc);
        return rc;
    }
    freqSI570_high_speed_wr_value[0] = ((HSdiv & 0x7) << 5) + ((N1div & 0x7c) >> 2);
    freqSI570_high_speed_wr_value[1] = ((N1div & 0x3) << 6) + (freqSI570_high_speed_rd_value[1] & 0x3F);
    freqSI570_high_speed_wr_value[2] = freqSI570_high_speed_rd_value[2];
    freqSI570_high_speed_wr_value[3] = freqSI570_high_speed_rd_value[3];
    freqSI570_high_speed_wr_value[4] = freqSI570_high_speed_rd_value[4];
    freqSI570_high_speed_wr_value[5] = freqSI570_high_speed_rd_value[5];
    
    rc = [self set_frequency:osc values: freqSI570_high_speed_wr_value];
    if(rc){
        NSLog(@"set_frequency = %d \n",rc);
        return rc;
    }
    return 0;
}

- (void) configureAdcFpgaIobDelays:(uint32_t) iobDelayValue
{
    [self writeLong:0xf00 toAddress:[self groupRegister:kAdcInputTapDelayReg group:0]];
    [self writeLong:0xf00 toAddress:[self groupRegister:kAdcInputTapDelayReg group:1]];
    [self writeLong:0xf00 toAddress:[self groupRegister:kAdcInputTapDelayReg group:2]];
    [self writeLong:0xf00 toAddress:[self groupRegister:kAdcInputTapDelayReg group:3]];
    usleep(10) ;
    [self writeLong:0x300 + iobDelayValue toAddress:[self groupRegister:kAdcInputTapDelayReg group:0]];
    [self writeLong:0x300 + iobDelayValue toAddress:[self groupRegister:kAdcInputTapDelayReg group:1]];
    [self writeLong:0x300 + iobDelayValue toAddress:[self groupRegister:kAdcInputTapDelayReg group:2]];
    [self writeLong:0x300 + iobDelayValue toAddress:[self groupRegister:kAdcInputTapDelayReg group:3]];
    usleep(100) ;
}

- (int) readAdcSpiGroup:(unsigned int) adc_fpga_group chip:(unsigned int) adc_chip address:(uint32_t) spi_addr data:(uint32_t*) spi_data
{
    unsigned int pollcounter = 1000;
    
    if (adc_fpga_group > 4) {return -1;}
    if (adc_chip > 2)       {return -1;}
    if (spi_addr > 0x1fff)  {return -1;}
    
    uint32_t uint_adc_mux_select;
    if (adc_chip == 0)  uint_adc_mux_select = 0 ;    // adc chip ch1/ch2
    else                uint_adc_mux_select = 0x400000 ; // adc chip ch3/ch4
    
    // read register to get the information of bit 24 (adc output enabled)
    uint32_t data = [self readLongFromAddress:[self groupRegister:kAdcSpiControlReg group:adc_fpga_group]];
    data = data & 0x01000000 ; // save bit 24
    
    data =  data + 0xC0000000 + uint_adc_mux_select + ((spi_addr & 0x1fff) << 8);
    [self writeLong:data toAddress:[self groupRegister:kAdcSpiControlReg group:adc_fpga_group]];
    
    uint32_t addr = [self singleRegister: kAdcSpiBusyStatusReg] ;
    do { // the logic is appr. 20us busy
        data = [self readLongFromAddress:addr];
        pollcounter--;
    } while (((data & 0x0000000f) != 0x00000000) && (pollcounter > 0));
    
    if (pollcounter == 0) return -2 ;
    
    usleep(20) ; //
    
    data = [self readLongFromAddress:[self groupRegister:kAdcSpiReadbackReg group:adc_fpga_group]];
    
    *spi_data = data & 0xff ;
    return 0 ;
}
- (int) writeAdcSpiGroup:(unsigned int) adc_fpga_group chip:(unsigned int) adc_chip address:(uint32_t) spi_addr data:(uint32_t) spi_data
{
    unsigned int  pollcounter = 1000;
    
    if (adc_fpga_group > 4) {return -1;}
    if (adc_chip > 2)       {return -1;}
    if (spi_addr > 0xffff)  {return -1;}
    
    unsigned int uint_adc_mux_select;
    if (adc_chip == 0)  uint_adc_mux_select = 0 ;    // adc chip ch1/ch2
    else                uint_adc_mux_select = 0x400000 ; // adc chip ch3/ch4
    
    // read register to get the information of bit 24 (adc output enabled)
    uint32_t data = [self readLongFromAddress:[self groupRegister:kAdcSpiControlReg group:adc_fpga_group]];
    data = data & 0x01000000 ; // save bit 24
    data =  data + 0x80000000 + uint_adc_mux_select + ((spi_addr & 0xffff) << 8) + (spi_data & 0xff) ;
    [self writeLong:data toAddress:[self groupRegister:kAdcSpiControlReg group:adc_fpga_group]];
    
    uint32_t addr = [self singleRegister: kAdcSpiBusyStatusReg] ;
    do { // the logic is appr. 20us busy
        data = [self readLongFromAddress:addr];
        pollcounter--;
    } while (((data & 0x0000000f) != 0x00000000) && (pollcounter > 0));
    
    if (pollcounter == 0) {return -2 ; }
    return 0 ;
}

- (int) i2cStart:(int) osc
{
    if(osc > 3)return -101;
    // start
    uint32_t aValue = 0x1<<I2C_START;
    [self writeLong:aValue toAddress:[self singleRegister:kAdcClockI2CReg] +  (4 * osc)];
    
    int i = 0;
    aValue = 0;
    do {
        // poll i2c fsm busy
        aValue =  [self readLongFromAddress:[self singleRegister:kAdcClockI2CReg] + (4 * osc)];
        i++;
    } while((aValue & (1UL<<I2C_BUSY)) && (i < 1000));
    
    // register access problem
    if(i == 1000){
        NSLog(@"i2cStart3 too many tries \n");
        return -100;
    }
    return 0;
}

- (int) i2cStop:(int) osc
{
    if(osc > 3)return -101;
    
    // stop
    usleep(20000);
    uint32_t aValue = 0x1<<I2C_STOP;
    [self writeLong:aValue toAddress:[self singleRegister:kAdcClockI2CReg] +  (4 * osc)];
    
    int i = 0;
    aValue = 0;
    do {
        // poll i2c fsm busy
        usleep(20000);
        aValue =  [self readLongFromAddress:[self singleRegister:kAdcClockI2CReg] + (4 * osc)];
    } while((aValue & (1UL<<I2C_BUSY)) && (++i < 1000));
    
    // register access problem
    if(i == 1000)return -100;
    
    return 0;
}

- (int) i2cWriteByte:(int)osc data:(unsigned char) data ack:(char*)ack
{
    if(osc > 3)return -101;
    
    // write byte, receive ack
    uint32_t aValue = 0x1<<I2C_WRITE ^ data;
    [self writeLong:aValue toAddress:[self singleRegister:kAdcClockI2CReg] +  (4 * osc)];
    
    int i = 0;
    uint32_t tmp = 0;
    do {
        // poll i2c fsm busy
        tmp =  [self readLongFromAddress:[self singleRegister:kAdcClockI2CReg] + (4 * osc)];
    }while((tmp & (1UL<<I2C_BUSY)) && (++i < 1000));
    
    // register access problem
    if(i == 1000)return -100;
    
    // return ack value?
    if(ack){
        // yup
        *ack = tmp & 0x1<<I2C_ACK ? 1 : 0;
    }
    
    return 0;
}

- (int) i2cReadByte:(int) osc data:(unsigned char*) data ack:(char)ack
{
    if(osc > 3)return -101;
    
    // read byte, put ack
    uint32_t aValue = 0x1<<I2C_READ;
    aValue |= ack ? 1UL<<I2C_ACK : 0;
    usleep(20000);
    [self writeLong:aValue toAddress:[self singleRegister:kAdcClockI2CReg] +  (4 * osc)];
    
    int i = 0;
    do {
        // poll i2c fsm busy
        usleep(20000);
        aValue =  [self readLongFromAddress:[self singleRegister:kAdcClockI2CReg] + (4 * osc)];
    } while((aValue & (1UL<<I2C_BUSY)) && (++i < 1000));
    
    // register access problem
    if(i == 1000)return -100;
    
    return 0;
}

- (int) si570FreezeDCO:(int) osc
{
    // start
    int rc = [self i2cStart:osc];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    // address
    char ack;
    rc = [self i2cWriteByte:osc data:OSC_ADR<<1 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // register offset
    rc = [self i2cWriteByte:osc data:0x89 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // write data
    rc = [self i2cWriteByte:osc data:0x10 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // stop
    rc = [self i2cStop:osc];
    return rc;
}

- (int) si570ReadDivider:(int) osc values:(unsigned char*)data
{
    int rc;
    char ack;
    int i;
    
    // start
    rc = [self i2cStart:osc];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    // address
    rc = [self i2cWriteByte:osc data:OSC_ADR<<1 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // register offset
    rc = [self i2cWriteByte:osc data:0x0D ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // write data
    for(i = 0;i < 2;i++){
        rc = [self i2cWriteByte:osc data:data[i] ack:&ack];
        if(rc){
            [self i2cStop:osc];
            return rc;
        }
        
        if(!ack){
            [self i2cStop:osc];
            return -101;
        }
    }
    
    // stop
    rc = [self i2cStop:osc];
    return rc;
}

- (int) si570UnfreezeDCO:(int)osc {
    int rc;
    char ack;
    
    // start
    rc = [self i2cStart:osc];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    // address
    rc = [self i2cWriteByte:osc data:OSC_ADR<<1 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // register offset
    
    rc = [self i2cWriteByte:osc data:0x89 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // write data
    rc = [self i2cWriteByte:osc data:0x00 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // stop
    rc = [self i2cStop:osc];
    return rc;
}

- (int) si570NewFreq:(int) osc {
    
    // start
    int rc = [self i2cStart:osc];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    // address
    char ack;
    rc = [self i2cWriteByte:osc data:OSC_ADR<<1 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // register offset
    rc = [self i2cWriteByte:osc data:0x87 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // write data
    rc = [self i2cWriteByte:osc data:0x40 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // stop
    
    rc = [self i2cStop:osc];
    return rc;
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary unsignedLongArray:(uint32_t*)anArray size:(int32_t)numItems forKey:(NSString*)aKey
{
    NSMutableArray* ar = [NSMutableArray array];
    int i;
    for(i=0;i<numItems;i++){
        [ar addObject:[NSNumber numberWithLong:anArray[i]]];
    }
    [dictionary setObject:ar forKey:aKey];
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary unsignedShortArray:(unsigned short*)anArray size:(int32_t)numItems forKey:(NSString*)aKey
{
    NSMutableArray* ar = [NSMutableArray array];
    int i;
    for(i=0;i<numItems;i++){
        [ar addObject:[NSNumber numberWithUnsignedShort:anArray[i]]];
    }
    [dictionary setObject:ar forKey:aKey];
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary boolArray:(BOOL*)anArray size:(int32_t)numItems forKey:(NSString*)aKey
{
    NSMutableArray* ar = [NSMutableArray array];
    int i;
    for(i=0;i<numItems;i++){
        [ar addObject:[NSNumber numberWithBool:anArray[i]]];
    }
    [dictionary setObject:ar forKey:aKey];
}

@end
