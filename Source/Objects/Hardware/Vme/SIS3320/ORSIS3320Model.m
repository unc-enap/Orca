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

#pragma mark ***Imported Files
#import "ORSIS3320Model.h"
#import "ORDataTypeAssigner.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORVmeCrateModel.h"
#import "ORRateGroup.h"
#import "ORTimer.h"
#import "VME_HW_Definitions.h"
#import "ORVmeTests.h"
#import "ORVmeReadWriteCommand.h"
#import "ORCommandList.h"

NSString* ORSIS3320ModelOnlineChanged                  = @"ORSIS3320ModelOnlineChanged";
NSString* ORSIS3320ModelAccGate1LengthChanged          = @"ORSIS3320ModelAccGate1LengthChanged";
NSString* ORSIS3320ModelAccGate1StartIndexChanged        = @"ORSIS3320ModelAccGate1StartIndexChanged";
NSString* ORSIS3320ModelAccGate2LengthChanged          = @"ORSIS3320ModelAccGate2LengthChanged";
NSString* ORSIS3320ModelAccGate2StartIndexChanged        = @"ORSIS3320ModelAccGate2StartIndexChanged";
NSString* ORSIS3320ModelAccGate3LengthChanged          = @"ORSIS3320ModelAccGate3LengthChanged";
NSString* ORSIS3320ModelAccGate3StartIndexChanged        = @"ORSIS3320ModelAccGate3StartIndexChanged";
NSString* ORSIS3320ModelAccGate4LengthChanged          = @"ORSIS3320ModelAccGate4LengthChanged";
NSString* ORSIS3320ModelAccGate4StartIndexChanged        = @"ORSIS3320ModelAccGate4StartIndexChanged";
NSString* ORSIS3320ModelAccGate5LengthChanged          = @"ORSIS3320ModelAccGate5LengthChanged";
NSString* ORSIS3320ModelAccGate5StartIndexChanged        = @"ORSIS3320ModelAccGate5StartIndexChanged";
NSString* ORSIS3320ModelAccGate6LengthChanged          = @"ORSIS3320ModelAccGate6LengthChanged";
NSString* ORSIS3320ModelAccGate6StartIndexChanged        = @"ORSIS3320ModelAccGate6StartIndexChanged";
NSString* ORSIS3320ModelAccGate7LengthChanged          = @"ORSIS3320ModelAccGate7LengthChanged";
NSString* ORSIS3320ModelAccGate7StartIndexChanged        = @"ORSIS3320ModelAccGate7StartIndexChanged";
NSString* ORSIS3320ModelAccGate8LengthChanged          = @"ORSIS3320ModelAccGate8LengthChanged";
NSString* ORSIS3320ModelAccGate8StartIndexChanged        = @"ORSIS3320ModelAccGate8StartIndexChanged";
NSString* ORSIS3320ModelBufferStartChanged              = @"ORSIS3320ModelBufferStartChanged";
NSString* ORSIS3320ModelBufferLengthChanged             = @"ORSIS3320ModelBufferLengthChanged";
NSString* ORSIS3320ModelInvertInputChanged              = @"ORSIS3320ModelInvertInputChanged";
NSString* ORSIS3320ModelEnableErrorCorrectionChanged    = @"ORSIS3320ModelEnableErrorCorrectionChanged";
NSString* ORSIS3320ModelLemoTimeStampClrEnabledChanged  = @"ORSIS3320ModelLemoTimeStampClrEnabledChanged";
NSString* ORSIS3320ModelLemoTriggerEnabledChanged       = @"ORSIS3320ModelLemoTriggerEnabledChanged";
NSString* ORSIS3320ModelInternalTriggerEnabledChanged   = @"ORSIS3320ModelInternalTriggerEnabledChanged";
NSString* ORSIS3320ModelDacValueChanged					= @"ORSIS3320ModelDacValueChanged";
NSString* ORSIS3320ModelClockSourceChanged				= @"ORSIS3320ModelClockSourceChanged";
NSString* ORSIS3320ModelTriggerModeChanged              = @"ORSIS3320ModelTriggerModeChanged";
NSString* ORSIS3320ModelSaveAlwaysChanged               = @"ORSIS3320ModelSaveAlwaysChanged";
NSString* ORSIS3320ModelSaveIfPileUpChanged             = @"ORSIS3320ModelSaveIfPileUpChanged";
NSString* ORSIS3320ModelSaveFIRTriggerChanged           = @"ORSIS3320ModelSaveFIRTriggerChanged";
NSString* ORSIS3320ModelSaveFirstEventChanged           = @"ORSIS3320ModelSaveFirstEventChanged";
NSString* ORSIS3320ModelTriggerGateLengthChanged        = @"ORSIS3320ModelTriggerGateLengthChanged";
NSString* ORSIS3320ModelPreTriggerDelayChanged          = @"ORSIS3320ModelPreTriggerDelayChanged";
NSString* ORSIS3320ModelThresholdChanged				= @"ORSIS3320ModelThresholdChanged";
NSString* ORSIS3320ModelTrigPulseLenChanged				= @"ORSIS3320ModelTrigPulseLenChanged";
NSString* ORSIS3320ModelSumGChanged						= @"ORSIS3320ModelSumGChanged";
NSString* ORSIS3320ModelPeakingTimeChanged				= @"ORSIS3320ModelPeakingTimeChanged";

NSString* ORSIS3320ModelGtMaskChanged					= @"ORSIS3320ModelGtMaskChanged";
NSString* ORSIS3320ModelTriggerOutMaskChanged		    = @"ORSIS3320ModelTriggerOutMaskChanged";
NSString* ORSIS3320ModelExtendedTriggerMaskChanged		= @"ORSIS3320ModelExtendedTriggerMaskChanged";


NSString* ORSIS3320RateGroupChangedNotification			= @"ORSIS3320RateGroupChangedNotification";

NSString* ORSIS3320ModelIDChanged						= @"ORSIS3320ModelIDChanged";
NSString* ORSIS3320SettingsLock							= @"ORSIS3320SettingsLock";
NSString* ORSIS3320ModelEndAddressThresholdChanged		= @"ORSIS3320ModelEndAddressThresholdChanged";

#define kAdcSamplingLogicArmedBit           0x40000
#define kEndAddressThresholdFlag            0x80000

//general register offsets
#define kControlStatus                      0x00        /* read/write*/
#define kModuleIDReg                        0x04        /* read only*/
#define kInterruptConfigReg                 0x08        /* read/write*/
#define kInterruptControlReg                0x0C        /* read/write*/
#define kAcquisitionControlReg				0x10        /* read/write*/
#define kCBLTBroadcastSetup					0x30        /*read/write*/
#define kAdcMemoryPageReg					0x34        /*read/write*/
#define kDacStatusReg						0x50        /*read/write*/
#define kDacDataReg							0x54        /*read/write*/
#define kXilinxJtagTestReg					0x60        /*read/write*/
#define kXilinxJtagControl					0x64        /*write only*/

#define kResetRegister						0x0400      /*write only*/
#define kDisarmSamplingLogic				0x0414      /*write only*/

#define kVMETrigger                         0x0418      /*write only*/
#define kTimeStampClear                     0x041C      /*write only*/
#define kDisarmAndArmBank1                  0x0420      /*write only*/
#define kDisarmAndArmBank2                  0x0424      /*write only*/


#define kEventConfigAll						0x01000000  /*write only*/
#define kEndAddressThresholdAll             0x01000004  /*write only*/
#define kPreTriggerDelayTriggerGateLengthAll 0x01000008  /*write only*/
#define kRawDataBufferConfigAll             0x0100000C  /*write only*/
#define kAccumGate1All                      0x01000040  /*write only*/
#define kAccumGate2All                      0x01000044  /*write only*/
#define kAccumGate3All                      0x01000048  /*write only*/
#define kAccumGate4All                      0x0100004c  /*write only*/
#define kAccumGate5All                      0x01000050  /*write only*/
#define kAccumGate6All                      0x01000054  /*write only*/
#define kAccumGate7All                      0x01000058  /*write only*/
#define kAccumGate8All                      0x0100005c  /*write only*/

//ADC Group 1
#define kEventConfigAdc12					0x02000000 /*read/write*/
#define kEndAddressThreshold12              0x02000004 /*read/write*/
#define kPreTriggerDelayTriggerGateLength12 0x02000008 /*read/write*/
#define kRawDataBufferConfig12				0x0200000C /*read/write*/
#define kNextSampleAddressAdc1				0x02000010 /*read only*/
#define kNextSampleAddressAdc2				0x02000014 /*read only*/
#define kPreviousBankSampleAdc1             0x02000018 /*read only*/
#define kPreviousBankSampleAdc2             0x0200001c /*read only*/
#define kActualSampleValueAdc12				0x02000020 /*read only*/
#define kAdc1TriggerSetupReg				0x02000030 /*read/write*/
#define kAdc1TriggerThresholdReg			0x02000034 /*read/write*/
#define kAdc2TriggerSetupReg				0x02000038 /*read/write*/
#define kAdc2TriggerThresholdReg			0x0200003C /*read/write*/
#define kAccumGate1Adc12                    0x02000040 /*read only*/
#define kAccumGate2Adc12                    0x02000044 /*read only*/
#define kAccumGate3Adc12                    0x02000048 /*read only*/
#define kAccumGate4Adc12                    0x0200004c /*read only*/
#define kAccumGate5Adc12                    0x02000050 /*read only*/
#define kAccumGate6Adc12                    0x02000054 /*read only*/
#define kAccumGate7Adc12                    0x02000058 /*read only*/
#define kAccumGate8Adc12                    0x0200005c /*read only*/
#define kAdcSPIReg12                        0x02000060 //rw

//ADC Group 2
#define kEventConfigAdc34					0x02800000 /*read/write*/
#define kEndAddressThreshold34              0x02800004 /*read/write*/
#define kPreTriggerDelayTriggerGateLength34 0x02800008 /*read/write*/
#define kRawDataBufferConfig34				0x0280000C /*read/write*/
#define kNextSampleAddressAdc3				0x02800010 /*read only*/
#define kNextSampleAddressAdc4				0x02800014 /*read only*/
#define kPreviousBankSampleAdc3             0x02800018 /*read only*/
#define kPreviousBankSampleAdc4             0x0280001c /*read only*/
#define kActualSampleValueAdc34				0x02800020 /*read only*/
#define kAdc3TriggerSetupReg				0x02800030 /*read/write*/
#define kAdc3TriggerThresholdReg			0x02800034 /*read/write*/
#define kAdc4TriggerSetupReg				0x02800038 /*read/write*/
#define kAdc4TriggerThresholdReg			0x0280003C /*read/write*/
#define kAccumGate1Adc34                    0x02800040 /*write only*/
#define kAccumGate2Adc34                    0x02800044 /*write only*/
#define kAccumGate3Adc34                    0x02800048 /*write only*/
#define kAccumGate4Adc34                    0x0280004c /*write only*/
#define kAccumGate5Adc34                    0x02800050 /*write only*/
#define kAccumGate6Adc34                    0x02800054 /*write only*/
#define kAccumGate7Adc34                    0x02800058 /*write only*/
#define kAccumGate8Adc34                    0x0280005c /*write only*/
#define kAdcSPIReg34                        0x02800060 //rw

//ADC Group 3
#define kEventConfigAdc56					0x03000000 /*read/write*/
#define kEndAddressThreshold56              0x03000004 /*read/write*/
#define kPreTriggerDelayTriggerGateLength56 0x03000008 /*read/write*/
#define kRawDataBufferConfig56				0x0300000C /*read/write*/
#define kNextSampleAddressAdc5				0x03000010 /*read only*/
#define kNextSampleAddressAdc6				0x03000014 /*read only*/
#define kPreviousBankSampleAdc5             0x03000018 /*read only*/
#define kPreviousBankSampleAdc6             0x0300001c /*read only*/
#define kActualSampleValueAdc56				0x03000020 /*read only*/
#define kAdc5TriggerSetupReg				0x03000030 /*read/write*/
#define kAdc5TriggerThresholdReg			0x03000034 /*read/write*/
#define kAdc6TriggerSetupReg				0x03000038 /*read/write*/
#define kAdc6TriggerThresholdReg			0x0300003C /*read/write*/
#define kAccumGate1Adc56                    0x03000040 /*write only*/
#define kAccumGate2Adc56                    0x03000044 /*write only*/
#define kAccumGate3Adc56                    0x03000048 /*write only*/
#define kAccumGate4Adc56                    0x0300004c /*write only*/
#define kAccumGate5Adc56                    0x03000050 /*write only*/
#define kAccumGate6Adc56                    0x03000054 /*write only*/
#define kAccumGate7Adc56                    0x03000058 /*write only*/
#define kAccumGate8Adc56                    0x0300005c /*write only*/
#define kAdcSPIReg56                        0x03000060 //rw

//ADC Group 4
#define kEventConfigAdc78					0x03800000 /*read/write*/
#define kEndAddressThreshold78              0x03800004 /*read/write*/
#define kPreTriggerDelayTriggerGateLength78 0x03800008 /*read/write*/
#define kRawDataBufferConfig78				0x0380000C /*read/write*/
#define kNextSampleAddressAdc7				0x03800010 /*read only*/
#define kNextSampleAddressAdc8				0x03800014 /*read only*/
#define kPreviousBankSampleAdc7             0x03800018 /*read only*/
#define kPreviousBankSampleAdc8             0x0380001c /*read only*/
#define kActualSampleValueAdc78				0x03800020 /*read only*/
#define kAdc7TriggerSetupReg				0x03800030 /*read/write*/
#define kAdc7TriggerThresholdReg			0x03800034 /*read/write*/
#define kAdc8TriggerSetupReg				0x03800038 /*read/write*/
#define kAdc8TriggerThresholdReg			0x0380003C /*read/write*/
#define kAccumGate1Adc78                    0x03800040 /*write only*/
#define kAccumGate2Adc78                    0x03800044 /*write only*/
#define kAccumGate3Adc78                    0x03800048 /*write only*/
#define kAccumGate4Adc78                    0x0380004c /*write only*/
#define kAccumGate5Adc78                    0x03800050 /*write only*/
#define kAccumGate6Adc78                    0x03800054 /*write only*/
#define kAccumGate7Adc78                    0x03800058 /*write only*/
#define kAccumGate8Adc78                    0x0380005c /*write only*/
#define kAdcSPIReg78                        0x03800060 //rw


#define kAdc1MemoryPage                     0x04000000 /*readonly*/
#define kAdc2MemoryPage                     0x04800000 /*readonly*/
#define kAdc3MemoryPage                     0x05000000 /*readonly*/
#define kAdc4MemoryPage                     0x05800000 /*readonly*/
#define kAdc5MemoryPage                     0x06000000 /*readonly*/
#define kAdc6MemoryPage                     0x06800000 /*readonly*/
#define kAdc7MemoryPage                     0x07000000 /*readonly*/
#define kAdc8MemoryPage                     0x07800000 /*readonly*/


//Acquisition Reg bit definitions
#define kInternalTriggerBit             0x00000040
#define kEnableLemoTriggerBit           0x00000100
#define kEnableLemoTimeStampClrBit      0x00000200
#define kAcqClockBitOffset              12

//Event Configuration bit definitions
#define kInvertInputMask0                   0x00000001
#define kErrorCorrectionMask0               0x00000002
#define kInternalExternalTriggerMask0       0x0000000c
#define kSaveDataAlwaysMask0                0x00000010
#define kSaveDataIfPileupMask0              0x00000020
#define kSaveDataFIRMask0                   0x00000040
#define kSaveDataFirstEvent0                0x00000080

#define kInvertInputMask1                   0x00000100
#define kErrorCorrectionMask1               0x00000200
#define kInternalExternalTriggerMask1       0x00000c00
#define kSaveDataAlwaysMask1                0x00001000
#define kSaveDataIfPileupMask1              0x00002000
#define kSaveDataFIRMask1                   0x00004000
#define kSaveDataFirstEvent1                0x00008000


typedef struct {
	uint32_t offset;
	NSString* name;
} SIS3320RegisterInformation;

#define kNumSIS3320ReadRegs 66

static SIS3320RegisterInformation register_information[kNumSIS3320ReadRegs] = {
    {kControlStatus,                        @"Control/Status"},
	{kModuleIDReg,                          @"Module Id. and Firmware Revision"},
	{kInterruptConfigReg,                   @"Interrupt configuration"},
	{kInterruptControlReg,                  @"Interrupt control"},
	{kAcquisitionControlReg,                @"Acquisition control/status"},
	{kCBLTBroadcastSetup,                   @"Broadcast Setup register"},
	{kAdcMemoryPageReg,                     @"ADC Memory Page register"},
	{kDacStatusReg,                         @"DAC Control Status register"},
	{kDacDataReg,                           @"DAC Data register"},
	{kXilinxJtagTestReg,                    @"XILINX JTAG_TEST/JTAG_DATA_IN"},
    //--group 1
	{kEventConfigAdc12,                     @"Event configuration (ADC1, ADC2)"},
	{kEndAddressThreshold12,                @"End Address Threshold (ADC1, ADC2)"},
	{kPreTriggerDelayTriggerGateLength12,   @"Pretrigger Delay and Trigger Gate Length (ADC1, ADC2)"},
	{kRawDataBufferConfig12,                @"Raw Data Buffer Configuration (ADC1, ADC2)"},   //function changed with v15xx
	{kNextSampleAddressAdc1,                @"Next Sample address ADC1"},
	{kNextSampleAddressAdc2,                @"Next Sample address ADC2"},
	{kPreviousBankSampleAdc1,               @"Previous Bank Sample address ADC1"},
	{kPreviousBankSampleAdc2,               @"Previous Bank Sample address ADC2"},
	{kActualSampleValueAdc12,               @"Actual Sample Value (ADC1, ADC2)"},
	{kAdc1TriggerSetupReg,                  @"Trigger Setup (ADC1)"},
	{kAdc1TriggerThresholdReg,              @"Trigger Threshold (ADC1)"},
	{kAdc2TriggerSetupReg,                  @"Trigger Setup (ADC2)"},
	{kAdc2TriggerThresholdReg,              @"Trigger Threshold (ADC2)"},
	{kAdcSPIReg12,                          @"SPI (ADC1, ADC2)"},
    //--group 2
	{kEventConfigAdc34,                     @"Event configuration (ADC3, ADC4)"},
	{kEndAddressThreshold34,                @"End Address Threshold (ADC3, ADC4)"},
	{kPreTriggerDelayTriggerGateLength34,   @"Pretrigger Delay and Trigger Gate Length (ADC3, ADC4)"},
	{kRawDataBufferConfig34,                @"Raw Data Buffer Configuration (ADC3, ADC4)"},   //function changed with v15xx
	{kNextSampleAddressAdc3,                @"Next Sample address ADC3"},
	{kNextSampleAddressAdc4,                @"Next Sample address ADC4"},
	{kPreviousBankSampleAdc3,               @"Previous Bank Sample address ADC3"},
	{kPreviousBankSampleAdc4,               @"Previous Bank Sample address ADC4"},
	{kActualSampleValueAdc34,               @"Actual Sample Value (ADC3, ADC4)"},
	{kAdc3TriggerSetupReg,                  @"Trigger Setup (ADC3)"},
	{kAdc3TriggerThresholdReg,              @"Trigger Threshold (ADC3)"},
	{kAdc4TriggerSetupReg,                  @"Trigger Setup (ADC4)"},
	{kAdc4TriggerThresholdReg,              @"Trigger Threshold (ADC4)"},
	{kAdcSPIReg34,                          @"SPI (ADC4, ADC5)"},
    //--group 3
	{kEventConfigAdc56,                     @"Event configuration (ADC5, ADC6)"},
	{kEndAddressThreshold56,                @"End Address Threshold (ADC5, ADC6)"},
	{kPreTriggerDelayTriggerGateLength56,   @"Pretrigger Delay and Trigger Gate Length (ADC5, ADC6)"},
	{kRawDataBufferConfig56,                @"Raw Data Buffer Configuration (ADC5, ADC6)"},   //function changed with v15xx
	{kNextSampleAddressAdc3,                @"Next Sample address ADC5"},
	{kNextSampleAddressAdc4,                @"Next Sample address ADC6"},
	{kPreviousBankSampleAdc3,               @"Previous Bank Sample address ADC5"},
	{kPreviousBankSampleAdc4,               @"Previous Bank Sample address ADC6"},
	{kActualSampleValueAdc56,               @"Actual Sample Value (ADC5, ADC6)"},
	{kAdc3TriggerSetupReg,                  @"Trigger Setup (ADC5)"},
	{kAdc3TriggerThresholdReg,              @"Trigger Threshold (ADC5)"},
	{kAdc4TriggerSetupReg,                  @"Trigger Setup (ADC6)"},
	{kAdc4TriggerThresholdReg,              @"Trigger Threshold (ADC6)"},
	{kAdcSPIReg56,                          @"SPI (ADC5, ADC6)"},
    //--group 3
	{kEventConfigAdc78,                     @"Event configuration (ADC7, ADC8)"},
	{kEndAddressThreshold78,                @"End Address Threshold (ADC7, ADC8)"},
	{kPreTriggerDelayTriggerGateLength78,   @"Pretrigger Delay and Trigger Gate Length (ADC7, ADC8)"},
	{kRawDataBufferConfig78,                @"Raw Data Buffer Configuration (ADC7, ADC8)"},   //function changed with v15xx
	{kNextSampleAddressAdc3,                @"Next Sample address ADC7"},
	{kNextSampleAddressAdc4,                @"Next Sample address ADC8"},
	{kPreviousBankSampleAdc3,               @"Previous Bank Sample address ADC7"},
	{kPreviousBankSampleAdc4,               @"Previous Bank Sample address ADC8"},
	{kActualSampleValueAdc78,               @"Actual Sample Value (ADC7, ADC8)"},
	{kAdc3TriggerSetupReg,                  @"Trigger Setup (ADC7)"},
	{kAdc3TriggerThresholdReg,              @"Trigger Threshold (ADC7)"},
	{kAdc4TriggerSetupReg,                  @"Trigger Setup (ADC8)"},
	{kAdc4TriggerThresholdReg,              @"Trigger Threshold (ADC8)"},
	{kAdcSPIReg78,                          @"SPI (ADC7, ADC8)"},
};


//some arrays of address offsets for convenience

uint32_t accumGate1Address[kNumSIS3320Groups]= {
    kAccumGate1Adc12,
    kAccumGate1Adc34,
    kAccumGate1Adc56,
    kAccumGate1Adc78
};
uint32_t accumGate2Address[kNumSIS3320Groups]= {
    kAccumGate2Adc12,
    kAccumGate2Adc34,
    kAccumGate2Adc56,
    kAccumGate2Adc78
};
uint32_t accumGate3Address[kNumSIS3320Groups]= {
    kAccumGate3Adc12,
    kAccumGate3Adc34,
    kAccumGate3Adc56,
    kAccumGate3Adc78
};
uint32_t accumGate4Address[kNumSIS3320Groups]= {
    kAccumGate4Adc12,
    kAccumGate4Adc34,
    kAccumGate4Adc56,
    kAccumGate4Adc78
};
uint32_t accumGate5Address[kNumSIS3320Groups]= {
    kAccumGate5Adc12,
    kAccumGate5Adc34,
    kAccumGate5Adc56,
    kAccumGate5Adc78
};
uint32_t accumGate6Address[kNumSIS3320Groups]= {
    kAccumGate6Adc12,
    kAccumGate6Adc34,
    kAccumGate6Adc56,
    kAccumGate6Adc78
};
uint32_t accumGate7Address[kNumSIS3320Groups]= {
    kAccumGate7Adc12,
    kAccumGate7Adc34,
    kAccumGate7Adc56,
    kAccumGate7Adc78
};
uint32_t accumGate8Address[kNumSIS3320Groups]= {
    kAccumGate8Adc12,
    kAccumGate8Adc34,
    kAccumGate8Adc56,
    kAccumGate8Adc78
};

uint32_t preTriggerDelayTriggerGateLengthAddress[kNumSIS3320Groups]={
	kPreTriggerDelayTriggerGateLength12,
	kPreTriggerDelayTriggerGateLength34,
	kPreTriggerDelayTriggerGateLength56,
	kPreTriggerDelayTriggerGateLength78
};

uint32_t endAddressThresholdAddress[kNumSIS3320Groups]={
	kEndAddressThreshold12,
	kEndAddressThreshold34,
	kEndAddressThreshold56,
	kEndAddressThreshold78
};

uint32_t rawDataBufferConfigurationAddress[kNumSIS3320Groups]={
    kRawDataBufferConfig12,
	kRawDataBufferConfig34,
	kRawDataBufferConfig56,
	kRawDataBufferConfig78
};

uint32_t previousBankSampleAdcAddress[kNumSIS3320Channels]={
	kPreviousBankSampleAdc1,
	kPreviousBankSampleAdc2,
	kPreviousBankSampleAdc3,
	kPreviousBankSampleAdc4,
	kPreviousBankSampleAdc5,
	kPreviousBankSampleAdc6,
	kPreviousBankSampleAdc7,
	kPreviousBankSampleAdc8
};


uint32_t nextSampleAddress[kNumSIS3320Channels]={
	kNextSampleAddressAdc1,
	kNextSampleAddressAdc2,
	kNextSampleAddressAdc3,
	kNextSampleAddressAdc4,
	kNextSampleAddressAdc5,
	kNextSampleAddressAdc6,
	kNextSampleAddressAdc7,
	kNextSampleAddressAdc8
};

uint32_t adcMemoryPage[kNumSIS3320Channels] = {
	kAdc1MemoryPage,
	kAdc2MemoryPage,
	kAdc3MemoryPage,
	kAdc4MemoryPage,
	kAdc5MemoryPage,
	kAdc6MemoryPage,
	kAdc7MemoryPage,
	kAdc8MemoryPage
};

uint32_t actualSampleAddress[kNumSIS3320Groups]={
	kActualSampleValueAdc12,
	kActualSampleValueAdc34,
	kActualSampleValueAdc56,
	kActualSampleValueAdc78
};

uint32_t triggerSetupAddress[kNumSIS3320Channels]={
	kAdc1TriggerSetupReg,
	kAdc2TriggerSetupReg,
	kAdc3TriggerSetupReg,
	kAdc4TriggerSetupReg,
	kAdc5TriggerSetupReg,
	kAdc6TriggerSetupReg,
	kAdc7TriggerSetupReg,
	kAdc8TriggerSetupReg
};

uint32_t triggerThresholdAddress[kNumSIS3320Channels]={
	kAdc1TriggerThresholdReg,
	kAdc2TriggerThresholdReg,
	kAdc3TriggerThresholdReg,
	kAdc4TriggerThresholdReg,
	kAdc5TriggerThresholdReg,
	kAdc6TriggerThresholdReg,
	kAdc7TriggerThresholdReg,
	kAdc8TriggerThresholdReg
};




@interface ORSIS3320Model (private)
- (void) setUpArrays;
- (NSMutableArray*) arrayOfLength:(int)len;
@end

@implementation ORSIS3320Model

#pragma mark ***Initialization
- (id) init
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setAddressModifier:0x09];
    [self setBaseAddress:0x030000000]; //default
    [self initParams];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc
{
    [dacValues release];
	[preTriggerDelays release];
	[triggerGateLengths release];
	[trigPulseLens release];
	[sumGs release];
	[peakingTimes release];
    [endAddressThresholds release];
	[thresholds release];
    [dataRateAlarm clearAlarm];
    [dataRateAlarm release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SIS3320Card"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORSIS3320Controller"];
}

- (NSString*) helpURL
{
	return @"VME/SIS3320.html";
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x07800000+8*1024*1024);
}

- (void) initParams
{
	[self setUpArrays];
	[self setDefaults];
}

#pragma mark ***Accessors
- (unsigned char)onlineMask {
	
    return onlineMask;
}

- (void)setOnlineMask:(unsigned char)anOnlineMask {
    [[[self undoManager] prepareWithInvocationTarget:self] setOnlineMask:[self onlineMask]];
	
    onlineMask = anOnlineMask;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORSIS3320ModelOnlineChanged
	 object:self];
	
}

- (BOOL)onlineMaskBit:(int)bit
{
	return (onlineMask>>bit)&0x1;
}

- (void) setOnlineMaskBit:(int)bit withValue:(BOOL)aValue
{
	unsigned char aMask = onlineMask;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setOnlineMask:aMask];
}

- (uint32_t) bufferStart:(int)aGroup
{
    if(aGroup>=0 && aGroup<kNumSIS3320Groups) return bufferStart[aGroup];
    else return 0;
}

- (void) setBufferStart:(int)aGroup withValue:(uint32_t)aBufferStart
{
    if(aGroup>=0 && aGroup<kNumSIS3320Groups){
        aBufferStart &= 0x3fe; //bit zero is always zero
        [[[self undoManager] prepareWithInvocationTarget:self] setBufferStart:aGroup withValue:bufferStart[aGroup]];
        
        bufferStart[aGroup] = aBufferStart;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelBufferStartChanged object:self];
    }
}


// --- bufferLength appears to be the number of waveform samples in an event
// --- this should be determined by raw_data_buffer_config registers
// --- for ADC12, this address is 0x0200000C for ADC34, it is 0x0280000C, then 30.., 38..
// --- these registers contain buffer sample lengths and buffer start offsets

- (uint32_t) bufferLength:(int)aGroup
{
    if(aGroup>=0 && aGroup<kNumSIS3320Groups) return bufferLength[aGroup];
    else return 0;
}

- (void) setBufferLength:(int)aGroup withValue:(uint32_t)aBufferLength
{
    if(aBufferLength>1022)aBufferLength= 1022;
    [[[self undoManager] prepareWithInvocationTarget:self] setBufferLength:aGroup withValue:bufferLength[aGroup]];
    aBufferLength = aBufferLength/2 * 2;
    
    bufferLength[aGroup] = aBufferLength;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelBufferLengthChanged object:self];
}

- (unsigned short) moduleID;
{
	return moduleID;
}

- (NSString*) firmwareVersion;
{
    return [NSString stringWithFormat:@"%02x.%02x",majorRev,minorRev ];
}

- (BOOL) lemoTimeStampClrEnabled
{
    return lemoTimeStampClrEnabled;
}

- (void) setLemoTimeStampClrEnabled:(BOOL)aLemoTimeStampClrEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoTimeStampClrEnabled:lemoTimeStampClrEnabled];
    lemoTimeStampClrEnabled = aLemoTimeStampClrEnabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelLemoTimeStampClrEnabledChanged object:self];
}

- (BOOL) lemoTriggerEnabled
{
    return lemoTriggerEnabled;
}

- (void) setLemoTriggerEnabled:(BOOL)aLemoTriggerEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoTriggerEnabled:lemoTriggerEnabled];
    lemoTriggerEnabled = aLemoTriggerEnabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelLemoTriggerEnabledChanged object:self];
}

- (BOOL) internalTriggerEnabled
{
    return internalTriggerEnabled;
}

- (void) setInternalTriggerEnabled:(BOOL)aInternalTriggerEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInternalTriggerEnabled:internalTriggerEnabled];
    internalTriggerEnabled = aInternalTriggerEnabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelInternalTriggerEnabledChanged object:self];
}

- (int) clockSource
{
    return clockSource;
}

- (void) setClockSource:(int)aClockSource
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClockSource:clockSource];
    clockSource = aClockSource;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelClockSourceChanged object:self];
}

- (NSString*) clockSourceName:(int)aValue
{
	switch (aValue) {
		case 0: return @"200MHz";
		case 1: return @"100MHz";
		case 2: return @"50MHz";
		case 3: return @"External x 5";
		case 4: return @"External x 2";
		case 5: return @"Random";
		case 6: return @"External";
		case 7: return @"250 MHz";
		default:return @"Unknown";
	}
}

- (int32_t) dacValue:(int)aChan
{
	if(!dacValues){
		dacValues = [[NSMutableArray arrayWithCapacity:kNumSIS3320Channels] retain];
		int i;
		for(i=0;i<kNumSIS3320Channels;i++)[dacValues addObject:[NSNumber numberWithInt:0]];
    }
    return [[dacValues objectAtIndex:aChan] intValue];
}

- (void) setDacValue:(int)aChan withValue:(int32_t)aValue
{
	if(!dacValues){
		dacValues = [[NSMutableArray arrayWithCapacity:kNumSIS3320Channels] retain];
		int i;
		for(i=0;i<kNumSIS3320Channels;i++)[dacValues addObject:[NSNumber numberWithInt:0]];
    }
	if(aValue<0)aValue = 0;
	if(aValue>0xffff)aValue = 0xffff;
    [[[self undoManager] prepareWithInvocationTarget:self] setDacValue:aChan withValue:[self dacValue:aChan]];
    [dacValues replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInteger:aValue]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelDacValueChanged object:self userInfo:userInfo];
}

- (unsigned char) triggerMode:(int)aGroup
{
    if(aGroup>=0 &&  aGroup<2)return triggerMode[aGroup];
    else return 0;
}

- (void) setTriggerMode:(int)aGroup withValue:(unsigned char)aValue
{
    if(aGroup>=0 && aGroup<2){
        [[[self undoManager] prepareWithInvocationTarget:self] setTriggerMode:aGroup withValue:triggerMode[aGroup]];
        triggerMode[aGroup] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelTriggerModeChanged object:self];
    }
}

- (BOOL) saveAlways:(int)aGroup
{
    if(aGroup>=0 && aGroup<2) return saveAlways[aGroup];
    else return NO;
}

- (void) setSaveAlways:(int)aGroup withValue:(BOOL)aSaveAlways
{
    if(aGroup>=0 && aGroup<2){
        [[[self undoManager] prepareWithInvocationTarget:self] setSaveAlways:aGroup withValue:saveAlways[aGroup]];
        saveAlways[aGroup] = aSaveAlways;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelSaveAlwaysChanged object:self];
    }
}

- (BOOL) saveIfPileUp:(int)aGroup
{
    if(aGroup>=0 && aGroup<2) return saveIfPileUp[aGroup];
    else return 0;
}

- (void) setSaveIfPileUp:(int)aGroup withValue:(BOOL)aSaveIfPileUp
{
    if(aGroup>=0 && aGroup<2){
        [[[self undoManager] prepareWithInvocationTarget:self] setSaveIfPileUp:aGroup withValue:saveIfPileUp[aGroup]];
        saveIfPileUp[aGroup] = aSaveIfPileUp;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelSaveIfPileUpChanged object:self];
    }
}

- (BOOL) saveFIRTrigger:(int)aGroup
{
    if(aGroup>=0 && aGroup<2) return saveFIRTrigger[aGroup];
    else return 0;
}

- (void) setSaveFIRTrigger:(int)aGroup withValue:(BOOL)aSaveFIRTrigger
{
    if(aGroup>=0 && aGroup<2){
        [[[self undoManager] prepareWithInvocationTarget:self] setSaveFIRTrigger:aGroup withValue:saveFIRTrigger[aGroup]];
        saveFIRTrigger[aGroup] = aSaveFIRTrigger;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelSaveFIRTriggerChanged object:self];
    }
}

- (BOOL) saveFirstEvent:(int)aGroup
{
    if(aGroup>=0 && aGroup<2) return saveFirstEvent[aGroup];
    else return 0;
}

- (void) setSaveFirstEvent:(int)aGroup withValue:(BOOL)aSaveFirstEvent
{
    if(aGroup>=0 && aGroup<2){
        [[[self undoManager] prepareWithInvocationTarget:self] setSaveFirstEvent:aGroup withValue:saveFirstEvent[aGroup]];
        saveFirstEvent[aGroup] = aSaveFirstEvent;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelSaveFirstEventChanged object:self];
    }
}

- (BOOL) invertInput:(int)aGroup
{
    if(aGroup>=0 && aGroup<2) return invertInput[aGroup];
    else return 0;
}

- (void) setInvertInput:(int)aGroup withValue:(BOOL)aInvertInput
{
    if(aGroup>=0 && aGroup<2){
        [[[self undoManager] prepareWithInvocationTarget:self] setInvertInput:aGroup withValue:invertInput[aGroup]];
        invertInput[aGroup] = aInvertInput;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelInvertInputChanged object:self];
    }
}

- (BOOL) enableErrorCorrection:(int)aGroup
{
    if(aGroup>=0 && aGroup<2) return enableErrorCorrection[aGroup];
    else return 0;
}

- (void) setEnableErrorCorrection:(int)aGroup withValue:(BOOL)aEnableErrorCorrection
{
    if(aGroup>=0 && aGroup<2){
        
        [[[self undoManager] prepareWithInvocationTarget:self] setEnableErrorCorrection:aGroup withValue:enableErrorCorrection[aGroup]];
        
        enableErrorCorrection[aGroup] = aEnableErrorCorrection;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelEnableErrorCorrectionChanged object:self];
    }
}

- (int) preTriggerDelay:(short)aGroup
{
    if(aGroup>=0 && aGroup<kNumSIS3320Groups)return [[preTriggerDelays objectAtIndex:aGroup]intValue];
    else return 0;
}

- (void) setPreTriggerDelay:(short)aGroup withValue:(int)aPreTriggerDelay
{
    if(aGroup>=0 && aGroup<kNumSIS3320Groups){
        [[[self undoManager] prepareWithInvocationTarget:self] setPreTriggerDelay:aGroup withValue:[self preTriggerDelay:aGroup]];
        int preTriggerDelay = [self limitIntValue:aPreTriggerDelay min:1 max:1023];
        
        [preTriggerDelays replaceObjectAtIndex:aGroup withObject:[NSNumber numberWithInt:preTriggerDelay]];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelPreTriggerDelayChanged object:self];
    }
}

- (int) triggerGateLength:(short)aGroup
{
    if(aGroup>=0 && aGroup<kNumSIS3320Groups)return [[triggerGateLengths objectAtIndex:aGroup]intValue];
    else return 0;
}
- (void) setTriggerGateLength:(short)aGroup withValue:(int)aTriggerGateLength
{
    if(aGroup>=0 && aGroup<kNumSIS3320Groups){
        if(aTriggerGateLength<1)aTriggerGateLength = 1;
        else if(aTriggerGateLength>1022)aTriggerGateLength = 1022;
        aTriggerGateLength = aTriggerGateLength/2 * 2; //make a multiple of two.
        [[[self undoManager] prepareWithInvocationTarget:self] setTriggerGateLength:aGroup withValue:[self triggerGateLength:aGroup]];
        int triggerGateLength = [self limitIntValue:aTriggerGateLength min:0 max:65535];
        [triggerGateLengths replaceObjectAtIndex:aGroup withObject:[NSNumber numberWithInt:triggerGateLength]];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelTriggerGateLengthChanged object:self];
    }
}


- (uint32_t) endAddressThreshold:(short)aGroup
{
    if(aGroup>=0 && aGroup<kNumSIS3320Groups)return [[endAddressThresholds objectAtIndex:aGroup]intValue];
    else return 0;
}

- (void) setEndAddressThreshold:(short)aGroup withValue:(uint32_t)aValue
{
    if(aGroup>=0 && aGroup<kNumSIS3320Groups){
        [[[self undoManager] prepareWithInvocationTarget:self] setEndAddressThreshold:aGroup withValue:[self endAddressThreshold:aGroup]];
        [endAddressThresholds replaceObjectAtIndex:aGroup withObject:[NSNumber numberWithInteger:aValue]];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelEndAddressThresholdChanged object:self];
    }
}

- (int) trigPulseLen:(short)aChan
{
	if(!trigPulseLens){
		trigPulseLens = [[NSMutableArray arrayWithCapacity:kNumSIS3320Channels] retain];
		int i;
		for(i=0;i<kNumSIS3320Channels;i++)[trigPulseLens addObject:[NSNumber numberWithInt:0]];
    }
    return [[trigPulseLens objectAtIndex:aChan] intValue];
}

- (void) setTrigPulseLen:(short)aChan withValue:(int)aValue
{
	if(!trigPulseLens){
		trigPulseLens = [[NSMutableArray arrayWithCapacity:kNumSIS3320Channels] retain];
		int i;
		for(i=0;i<kNumSIS3320Channels;i++)[trigPulseLens addObject:[NSNumber numberWithInt:0]];
	}
	if(aValue<0)aValue = 0;
	if(aValue>0xff)aValue = 0xff;
	[[[self undoManager] prepareWithInvocationTarget:self] setTrigPulseLen:aChan withValue:[self trigPulseLen:aChan]];
	[trigPulseLens replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelTrigPulseLenChanged object:self userInfo:userInfo];
}

- (int) sumG:(short)aChan
{
	if(!sumGs)return 0;
    return [[sumGs objectAtIndex:aChan] intValue];
}

- (void) setSumG:(short)aChan withValue:(int)aValue
{
	if(!sumGs){
		sumGs = [[NSMutableArray arrayWithCapacity:kNumSIS3320Channels] retain];
		int i;
		for(i=0;i<kNumSIS3320Channels;i++)[sumGs addObject:[NSNumber numberWithInt:1]];
	}
	if(aValue<1)aValue = 1;
	if(aValue>16)aValue = 16;
	[[[self undoManager] prepareWithInvocationTarget:self] setSumG:aChan withValue:[self sumG:aChan]];
	[sumGs replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelSumGChanged object:self userInfo:userInfo];
}

- (int) peakingTime:(short)aChan
{
	if(!peakingTimes)return 0;
    return [[peakingTimes objectAtIndex:aChan] intValue];
}

- (void) setPeakingTime:(short)aChan withValue:(int)aValue
{
	if(!peakingTimes){
		peakingTimes = [[NSMutableArray arrayWithCapacity:kNumSIS3320Channels] retain];
		int i;
		for(i=0;i<kNumSIS3320Channels;i++)[peakingTimes addObject:[NSNumber numberWithInt:1]];
	}
	if(aValue<1)aValue = 1;
	if(aValue>16)aValue = 16;
	[[[self undoManager] prepareWithInvocationTarget:self] setPeakingTime:aChan withValue:[self peakingTime:aChan]];
	[peakingTimes replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelPeakingTimeChanged object:self userInfo:userInfo];
}

- (int) threshold:(short)aChan
{
	if(!thresholds){
		thresholds = [[NSMutableArray arrayWithCapacity:kNumSIS3320Channels] retain];
		int i;
		for(i=0;i<kNumSIS3320Channels;i++)[thresholds addObject:[NSNumber numberWithInt:0]];
    }
    return [[thresholds objectAtIndex:aChan] intValue];
}

- (void) setThreshold:(short)aChan withValue:(int)aValue
{
	if(!thresholds){
		thresholds = [[NSMutableArray arrayWithCapacity:kNumSIS3320Channels] retain];
		int i;
		for(i=0;i<kNumSIS3320Channels;i++)[thresholds addObject:[NSNumber numberWithInt:0]];
    }
	if(aValue<0)aValue = 0;
	if(aValue>0x1FFFF)aValue = 0x1FFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChan withValue:[self threshold:aChan]];
    [thresholds replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelThresholdChanged object:self userInfo:userInfo];
}



- (void) setDefaults
{
	int i;
	for(i=0;i<kNumSIS3320Channels;i++){
		[self setThreshold:i	withValue:0];
		[self setDacValue:i		withValue:3000];
		[self setTrigPulseLen:i withValue:10];
		[self setPeakingTime:i	withValue:8];
		[self setSumG:i			withValue:15];
	}
	[self setClockSource:0];
    
    for(i=0;i<kNumSIS3320Groups;i++){
		[self setPreTriggerDelay:i withValue:1];
		[self setTriggerGateLength:i withValue:2048];
	}
}

- (unsigned char) gtMask
{
    return gtMask;
}

- (void) setGtMask:(unsigned char)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGtMask:[self gtMask]];
    gtMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelGtMaskChanged object:self];
}

- (BOOL) gtMaskBit:(int)bit
{
	return gtMask&(1<<bit);
}

- (void) setGtMaskBit:(int)bit withValue:(BOOL)aValue
{
	uint32_t aMask = gtMask;
	if(aValue)aMask |= (1<<bit);
	else      aMask &= ~(1<<bit);
	[self setGtMask:aMask];
}

- (unsigned char) triggerOutMask {
	
    return triggerOutMask;
}

- (void) setTriggerOutMask:(unsigned char)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerOutMask:[self triggerOutMask]];
    triggerOutMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelTriggerOutMaskChanged object:self];
}

- (BOOL) triggerOutMaskBit:(int)bit
{
	return triggerOutMask & (1<<bit);
}

- (void) setTriggerOutMaskBit:(int)bit withValue:(BOOL)aValue
{
	uint32_t aMask = triggerOutMask;
	if(aValue)aMask |= (1<<bit);
	else      aMask &= ~(1<<bit);
	[self setTriggerOutMask:aMask];
}

- (unsigned char) extendedTriggerMask
{
    return extendedTriggerMask;
}

- (void) setExtendedTriggerMask:(unsigned char)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setExtendedTriggerMask:[self extendedTriggerMask]];
    extendedTriggerMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelExtendedTriggerMaskChanged object:self];
}

- (BOOL) extendedTriggerMaskBit:(int)bit
{
	return extendedTriggerMask&(1<<bit);
}

- (void) setExtendedTriggerMaskBit:(int)bit withValue:(BOOL)aValue
{
	uint32_t aMask = extendedTriggerMask;
	if(aValue)aMask |= (1<<bit);
	else      aMask &= ~(1<<bit);
	[self setExtendedTriggerMask:aMask];
}


//-----------------------------------------------------------------
//Accum Gate 1
- (uint32_t) accGate1Length:(int)anIndex
{
    if(anIndex>=0 && anIndex<8)return accGate1Length[anIndex];
    else return 0;
}

- (void) setAccGate1Length:(int)anIndex withValue:(uint32_t)aValue
{
    if(anIndex>=0 && anIndex<8){
        aValue &= 0x1ff;
        [[[self undoManager] prepareWithInvocationTarget:self] setAccGate1Length:anIndex withValue:accGate1Length[anIndex]];
        accGate1Length[anIndex] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelAccGate1LengthChanged object:self];
    }
}

- (uint32_t) accGate1StartIndex:(int)anIndex
{
    if(anIndex>=0 && anIndex<8)return accGate1StartIndex[anIndex];
    else return 0;
}

- (void) setAccGate1StartIndex:(int)anIndex withValue:(uint32_t)aValue
{
    if(anIndex>=0 && anIndex<8){
        aValue &= 0x3ff;
        [[[self undoManager] prepareWithInvocationTarget:self] setAccGate1StartIndex:anIndex withValue:accGate1StartIndex[anIndex]];
        accGate1StartIndex[anIndex] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelAccGate1StartIndexChanged object:self];
    }
}
//-----------------------------------------------------------------
//Accum Gate 2
- (uint32_t) accGate2Length:(int)anIndex
{
    if(anIndex>=0 && anIndex<8)return accGate2Length[anIndex];
    else return 0;
}

- (void) setAccGate2Length:(int)anIndex withValue:(uint32_t)aValue
{
    if(anIndex>=0 && anIndex<8){
        aValue &= 0x1ff;
        [[[self undoManager] prepareWithInvocationTarget:self] setAccGate2Length:anIndex withValue:accGate2Length[anIndex]];
        accGate2Length[anIndex] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelAccGate2LengthChanged object:self];
    }
}

- (uint32_t) accGate2StartIndex:(int)anIndex
{
    if(anIndex>=0 && anIndex<8)return accGate2StartIndex[anIndex];
    else return 0;
}

- (void) setAccGate2StartIndex:(int)anIndex withValue:(uint32_t)aValue
{
    if(anIndex>=0 && anIndex<8){
        aValue &= 0x3ff;
        [[[self undoManager] prepareWithInvocationTarget:self] setAccGate2StartIndex:anIndex withValue:accGate2StartIndex[anIndex]];
        accGate2StartIndex[anIndex] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelAccGate2StartIndexChanged object:self];
    }
}

//-----------------------------------------------------------------
//Accum Gate 3
- (uint32_t) accGate3Length:(int)anIndex
{
    if(anIndex>=0 && anIndex<8)return accGate3Length[anIndex];
    else return 0;
}

- (void) setAccGate3Length:(int)anIndex withValue:(uint32_t)aValue
{
    if(anIndex>=0 && anIndex<8){
        aValue &= 0x1ff;
        [[[self undoManager] prepareWithInvocationTarget:self] setAccGate3Length:anIndex withValue:accGate3Length[anIndex]];
        accGate3Length[anIndex] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelAccGate3LengthChanged object:self];
    }
}

- (uint32_t) accGate3StartIndex:(int)anIndex
{
    if(anIndex>=0 && anIndex<8)return accGate3StartIndex[anIndex];
    else return 0;
}

- (void) setAccGate3StartIndex:(int)anIndex withValue:(uint32_t)aValue
{
    if(anIndex>=0 && anIndex<8){
        aValue &= 0x3ff;
        [[[self undoManager] prepareWithInvocationTarget:self] setAccGate3StartIndex:anIndex withValue:accGate3StartIndex[anIndex]];
        accGate3StartIndex[anIndex] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelAccGate3StartIndexChanged object:self];
    }
}
//-----------------------------------------------------------------
//Accum Gate 4
- (uint32_t) accGate4Length:(int)anIndex
{
    if(anIndex>=0 && anIndex<8)return accGate4Length[anIndex];
    else return 0;
}

- (void) setAccGate4Length:(int)anIndex withValue:(uint32_t)aValue
{
    if(anIndex>=0 && anIndex<8){
        aValue &= 0x1ff;
        [[[self undoManager] prepareWithInvocationTarget:self] setAccGate4Length:anIndex withValue:accGate4Length[anIndex]];
        accGate4Length[anIndex] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelAccGate4LengthChanged object:self];
    }
}

- (uint32_t) accGate4StartIndex:(int)anIndex
{
    if(anIndex>=0 && anIndex<8)return accGate4StartIndex[anIndex];
    else return 0;
}

- (void) setAccGate4StartIndex:(int)anIndex withValue:(uint32_t)aValue
{
    if(anIndex>=0 && anIndex<8){
        aValue &= 0x3ff;
        [[[self undoManager] prepareWithInvocationTarget:self] setAccGate4StartIndex:anIndex withValue:accGate4StartIndex[anIndex]];
        accGate4StartIndex[anIndex] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelAccGate4StartIndexChanged object:self];
    }
}
//-----------------------------------------------------------------
//Accum Gate 5
- (uint32_t) accGate5Length:(int)anIndex
{
    if(anIndex>=0 && anIndex<8)return accGate5Length[anIndex];
    else return 0;
}

- (void) setAccGate5Length:(int)anIndex withValue:(uint32_t)aValue
{
    if(anIndex>=0 && anIndex<8){
        aValue &= 0xf;
        [[[self undoManager] prepareWithInvocationTarget:self] setAccGate5Length:anIndex withValue:accGate5Length[anIndex]];
        accGate5Length[anIndex] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelAccGate5LengthChanged object:self];
    }
}

- (uint32_t) accGate5StartIndex:(int)anIndex
{
    if(anIndex>=0 && anIndex<8)return accGate5StartIndex[anIndex];
    else return 0;
}

- (void) setAccGate5StartIndex:(int)anIndex withValue:(uint32_t)aValue
{
    if(anIndex>=0 && anIndex<8){
        aValue &= 0x3ff;
        [[[self undoManager] prepareWithInvocationTarget:self] setAccGate5StartIndex:anIndex withValue:accGate5StartIndex[anIndex]];
        accGate5StartIndex[anIndex] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelAccGate5StartIndexChanged object:self];
    }
}
//-----------------------------------------------------------------
//Accum Gate 6
- (uint32_t) accGate6Length:(int)anIndex
{
    if(anIndex>=0 && anIndex<8)return accGate6Length[anIndex];
    else return 0;
}

- (void) setAccGate6Length:(int)anIndex withValue:(uint32_t)aValue
{
    if(anIndex>=0 && anIndex<8){
        aValue &= 0xf;
        [[[self undoManager] prepareWithInvocationTarget:self] setAccGate6Length:anIndex withValue:accGate6Length[anIndex]];
        accGate6Length[anIndex] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelAccGate6LengthChanged object:self];
    }
}

- (uint32_t) accGate6StartIndex:(int)anIndex
{
    if(anIndex>=0 && anIndex<8)return accGate6StartIndex[anIndex];
    else return 0;
}

- (void) setAccGate6StartIndex:(int)anIndex withValue:(uint32_t)aValue
{
    if(anIndex>=0 && anIndex<8){
        aValue &= 0x3ff;
        [[[self undoManager] prepareWithInvocationTarget:self] setAccGate6StartIndex:anIndex withValue:accGate6StartIndex[anIndex]];
        accGate6StartIndex[anIndex] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelAccGate6StartIndexChanged object:self];
    }
}
//-----------------------------------------------------------------
//Accum Gate 7
- (uint32_t) accGate7Length:(int)anIndex
{
    if(anIndex>=0 && anIndex<8)return accGate7Length[anIndex];
    else return 0;
}

- (void) setAccGate7Length:(int)anIndex withValue:(uint32_t)aValue
{
    if(anIndex>=0 && anIndex<8){
        aValue &= 0xf;
        [[[self undoManager] prepareWithInvocationTarget:self] setAccGate7Length:anIndex withValue:accGate7Length[anIndex]];
        accGate7Length[anIndex] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelAccGate7LengthChanged object:self];
    }
}

- (uint32_t) accGate7StartIndex:(int)anIndex
{
    if(anIndex>=0 && anIndex<8)return accGate7StartIndex[anIndex];
    else return 0;
}

- (void) setAccGate7StartIndex:(int)anIndex withValue:(uint32_t)aValue
{
    if(anIndex>=0 && anIndex<8){
        aValue &= 0x3ff;
        [[[self undoManager] prepareWithInvocationTarget:self] setAccGate7StartIndex:anIndex withValue:accGate7StartIndex[anIndex]];
        accGate7StartIndex[anIndex] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelAccGate7StartIndexChanged object:self];
    }
}
//-----------------------------------------------------------------
//Accum Gate 8
- (uint32_t) accGate8Length:(int)anIndex
{
    if(anIndex>=0 && anIndex<8)return accGate8Length[anIndex];
    else return 0;
}

- (void) setAccGate8Length:(int)anIndex withValue:(uint32_t)aValue
{
    if(anIndex>=0 && anIndex<8){
        aValue &= 0xf;
        [[[self undoManager] prepareWithInvocationTarget:self] setAccGate8Length:anIndex withValue:accGate8Length[anIndex]];
        accGate8Length[anIndex] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelAccGate8LengthChanged object:self];
    }
}

- (uint32_t) accGate8StartIndex:(int)anIndex
{
    if(anIndex>=0 && anIndex<8)return accGate8StartIndex[anIndex];
    else return 0;
}

- (void) setAccGate8StartIndex:(int)anIndex withValue:(uint32_t)aValue
{
    if(anIndex>=0 && anIndex<8){
        aValue &= 0x3ff;
        [[[self undoManager] prepareWithInvocationTarget:self] setAccGate8StartIndex:anIndex withValue:accGate8StartIndex[anIndex]];
        accGate8StartIndex[anIndex] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelAccGate8StartIndexChanged object:self];
    }
}
//------------------------------------------------------------------



#pragma mark •••Rates
- (uint32_t) getCounter:(int)counterTag forGroup:(int)groupTag
{
	if(groupTag == 0){
		if(counterTag>=0 && counterTag<kNumSIS3320Channels){
			return waveFormCount[counterTag];
		}
		else return 0;
	}
	else return 0;
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320RateGroupChangedNotification object:self];
}

- (id) rateObject:(int)channel
{
    return [waveFormRateGroup rateObject:channel];
}

- (void) setRateIntegrationTime:(double)newIntegrationTime
{
	//we this here so we have undo/redo on the rate object.
    [[[self undoManager] prepareWithInvocationTarget:self] setRateIntegrationTime:[waveFormRateGroup integrationTime]];
    [waveFormRateGroup setIntegrationTime:newIntegrationTime];
}

#pragma mark •••Hardware Access
- (void) reset
{
	uint32_t aValue = 1;
	[[self adapter] writeLongBlock: &aValue
						 atAddress: baseAddress + kResetRegister
						numToWrite: 1
						withAddMod: addressModifier
					 usingAddSpace: 0x01];
	
}

- (void) disarmSamplingLogic
{
	uint32_t aValue = 1;
	[[self adapter] writeLongBlock: &aValue
						 atAddress: baseAddress + kDisarmSamplingLogic
						numToWrite: 1
						withAddMod: addressModifier
					 usingAddSpace: 0x01];
	
}

- (void) trigger
{
	uint32_t aValue = 1;
	[[self adapter] writeLongBlock: &aValue
						 atAddress: baseAddress + kVMETrigger
						numToWrite: 1
						withAddMod: addressModifier
					 usingAddSpace: 0x01];
	
}

- (void) clearTimeStamp
{
	uint32_t aValue = 1;
	[[self adapter] writeLongBlock: &aValue
						 atAddress: baseAddress + kTimeStampClear
						numToWrite: 1
						withAddMod: addressModifier
					 usingAddSpace: 0x01];
	
}

- (void) armBank1
{
	uint32_t aValue = 1;
	[[self adapter] writeLongBlock: &aValue
						 atAddress: baseAddress + kDisarmAndArmBank1
						numToWrite: 1
						withAddMod: addressModifier
					 usingAddSpace: 0x01];
    bank1Armed = YES;
	
}

- (void) armBank2
{
	uint32_t aValue = 1;
	[[self adapter] writeLongBlock: &aValue
						 atAddress: baseAddress + kDisarmAndArmBank2
						numToWrite: 1
						withAddMod: addressModifier
					 usingAddSpace: 0x01];
    bank1Armed = NO;
}


- (void) initBoard
{
	[self writeDacOffsets];
	[self writePageRegister:0];
	[self writeEventConfiguration];
	[self writeEndAddressThresholds];
    [self writePreTriggerDelayAndTriggerGateDelay];
	[self writeRawDataBufferConfiguration];
	[self writeTriggerSetupRegisters];
	[self writeThresholds];
	[self writeAccumulators];
	[self writeControlStatusRegister];
	[self writeAcquisitionRegister];
}

- (void) writeControlStatusRegister
{
	// The register is set up as a J/K flip/flop -- 1 bit to set a function and 1 bit to disable.
	//nothing to do here yet except control the led, which we turn on during running
	uint32_t aMask = (ledOn & 0x1);
	aMask = ((~aMask & 0x0000ffff)<<16) | aMask;    //put the inverse in the top bits
	[[self adapter] writeLongBlock:&aMask
                         atAddress:baseAddress + kControlStatus
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) readModuleID:(BOOL)verbose
{
	uint32_t result = 0;
	[[self adapter] readLongBlock:&result
						atAddress:[self baseAddress] + kModuleIDReg
                        numToRead:1
					   withAddMod:addressModifier
					usingAddSpace:0x01];
	moduleID = result >> 16;
	majorRev = (result >> 8) & 0xff;
	minorRev = result & 0xff;
	if(verbose){
        NSLog(@"%@ ID: %x  Firmware:%x.%x\n",[self fullID],moduleID,majorRev,minorRev);
        //NOTE, the value is in hex. v31 in dec == v49 in hex
        if(majorRev!=49 || minorRev!=8)NSLog(@"Warning: Wrong firmware version. Need version 31.8, but you have verion %x.%x\n",majorRev,minorRev);
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelIDChanged object:self];
}

- (void) testRead
{
    uint32_t theValue1 = 0;
    uint32_t theValue2 = 0;
    uint32_t theValue3 = 0;
    
    id myAdapter = [self adapter];
    [myAdapter readLongBlock:&theValue1
                   atAddress:[self baseAddress] + kModuleIDReg
                   numToRead:1
                  withAddMod:0x09
               usingAddSpace:0x01];
    
    [myAdapter readLongBlock:&theValue2
                   atAddress:0x8610
                   numToRead:1
                  withAddMod:0x29
               usingAddSpace:0x01];
    
    [myAdapter readLongBlock:&theValue3
                   atAddress:0x8610
                   numToRead:1
                  withAddMod:0x29
               usingAddSpace:0x01];
    
    NSLog(@"SIS3320: 0x%0x   Shaper1: 0x%0x   Shaper2: 0x%0x\n",theValue1,theValue2,theValue3);
}
- (void) testReadWithHV
{
    uint32_t theValue1 = 0;
    uint32_t theValue2 = 0;
    uint32_t theValue3 = 0;
    
    id myAdapter = [self adapter];
    [myAdapter readLongBlock:&theValue1
                   atAddress:[self baseAddress] + kModuleIDReg
                   numToRead:1
                  withAddMod:0x09
               usingAddSpace:0x01];
    
    [myAdapter readLongBlock:&theValue2
                   atAddress:0xDD00
                   numToRead:1
                  withAddMod:0x29
               usingAddSpace:0x01];
    
    [myAdapter readLongBlock:&theValue3
                   atAddress:0xDD00
                   numToRead:1
                  withAddMod:0x29
               usingAddSpace:0x01];
    
    NSLog(@"SIS3320: 0x%0x   HV1: 0x%0x   HV2: 0x%0x\n",theValue1,theValue2,theValue3);
}



- (void) writeEndAddressThresholds
{
	int i;
	for(i=0;i<kNumSIS3320Groups;i++){
		[self writeEndAddressThreshold:i];
	}
}


// modified 8/28/13 to write high values to threshold addresses for disabled channels
- (void) writeEndAddressThreshold:(int)aGroup
{
	if(aGroup>=0 && aGroup<kNumSIS3320Groups){
		uint32_t aValue;
        
        if( onlineMask & ( 0x1 << (2*aGroup) ) || onlineMask & ( 0x1 << (2*aGroup + 1) ) )
            aValue = [self endAddressThreshold:aGroup];
        else
            aValue = 0x7777; // just to make sure it isn't 0
        
		[[self adapter] writeLongBlock:&aValue
							 atAddress:[self baseAddress] + endAddressThresholdAddress[aGroup]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
	}
}

- (void) writeAcquisitionRegister
{
	// The register is set up as a J/K flip/flop -- 1 bit to set a function and 1 bit 16 bits higher to disable.
	uint32_t aMask = (clockSource & 0x7) << kAcqClockBitOffset;
	
	if(internalTriggerEnabled)	aMask |= kInternalTriggerBit;
	if(lemoTriggerEnabled)      aMask |= kEnableLemoTriggerBit;
	if(lemoTimeStampClrEnabled)	aMask |= kEnableLemoTimeStampClrBit;
	
	aMask = ((~aMask & 0x0000ffff)<<16) | aMask;    //put the inverse in the top bits
    
	[[self adapter] writeLongBlock:&aMask
                         atAddress:baseAddress + kAcquisitionControlReg
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (uint32_t) readAcqRegister
{
	uint32_t aValue = 0x0;
	[[self adapter] readLongBlock:&aValue
						atAddress:baseAddress + kAcquisitionControlReg
                        numToRead:1
					   withAddMod:addressModifier
					usingAddSpace:0x01];
	return aValue;
}


- (void) writeAdcMemoryPage:(uint32_t)aPage
{
	[[self adapter] writeLongBlock:&aPage
						 atAddress:baseAddress + kAdcMemoryPageReg
						numToWrite:1
						withAddMod:addressModifier
					 usingAddSpace:0x01];
}

- (uint32_t) readAdcMemoryPage
{
	uint32_t aValue = 0;
	[[self adapter] readLongBlock:&aValue
                        atAddress:baseAddress + kAdcMemoryPageReg
						numToRead:1
                       withAddMod:addressModifier
                    usingAddSpace:0x01];
	return aValue;
}

- (uint32_t) readActualAdcSample:(int)aGroup
{
	uint32_t aValue = 0;
	[[self adapter] readLongBlock:&aValue
                        atAddress:baseAddress + actualSampleAddress[aGroup]
						numToRead:1
                       withAddMod:addressModifier
                    usingAddSpace:0x01];
	return aValue;
}

- (uint32_t) readPreviousAdcAddress:(int)aChannel
{
	uint32_t aValue = 0;
	[[self adapter] readLongBlock:&aValue
                        atAddress:baseAddress + previousBankSampleAdcAddress[aChannel]
						numToRead:1
                       withAddMod:addressModifier
                    usingAddSpace:0x01];
	return ( aValue & 0x3ffffc ) >> 1; // divide by two to deal with offset
}

- (uint32_t) readNextAdcAddress:(int)aChannel
{
	uint32_t aValue = 0;
	[[self adapter] readLongBlock:&aValue
                        atAddress:baseAddress + nextSampleAddress[aChannel]
						numToRead:1
                       withAddMod:addressModifier
                    usingAddSpace:0x01];
	return (aValue & 0x3ffffc) >>1; //divide by two to address offset from head of memory (in int32_t words).
}





- (void) writeDacOffsets
{
    
    // modified 8/28/13 to write offsets supplied by user iff channel enabled
    // else, write something low + combo with high trigger threshold to prevent errant triggering
    
    unsigned int disabledChanOffset = 0xBB8; // 3000. change if needed.
    
	uint32_t dataWord;
	uint32_t max_timeout, timeout_cnt;
	
	int i;
	for (i=0;i<kNumSIS3320Channels;i++) {
		
        if( onlineMask & ( 0x1 << i ) )
            dataWord =  [self dacValue:i];
        else
            dataWord = disabledChanOffset;
        
        
		[[self adapter] writeLongBlock:&dataWord
							 atAddress:baseAddress + kDacDataReg
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
		
		dataWord =  0x1 | (i<<4); // write to DAC Register
		[[self adapter] writeLongBlock:&dataWord
							 atAddress:baseAddress + kDacStatusReg
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
		
		max_timeout = 5000 ;
		timeout_cnt = 0 ;
		do {
			[[self adapter] readLongBlock:&dataWord
								atAddress:baseAddress + kDacStatusReg
								numToRead:1
							   withAddMod:addressModifier
							usingAddSpace:0x01];
			timeout_cnt++;
		} while ( ((dataWord & 0x8000) == 0x8000) && (timeout_cnt <  max_timeout) )    ;
		
		if (timeout_cnt >=  max_timeout) {
			NSLog(@"%@ Failed programing the DAC offset for channel %d\n",[self fullID],i);
			continue;
		}
		
		dataWord =  0x2 | (i<<4); // Load DACs
		[[self adapter] writeLongBlock:&dataWord
							 atAddress:baseAddress + kDacStatusReg
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
		
		timeout_cnt = 0 ;
		do {
			[[self adapter] readLongBlock:&dataWord
								atAddress:baseAddress + kDacStatusReg
								numToRead:1
							   withAddMod:addressModifier
							usingAddSpace:0x01];
			timeout_cnt++;
		} while ( ((dataWord & 0x8000) == 0x8000) && (timeout_cnt <  max_timeout) )    ;
		
		if (timeout_cnt >=  max_timeout) {
			NSLog(@"%@ Failed programing the DAC offset for channel %d\n",[self fullID],i);
			continue;
		}
	}
}



- (void) writeEventConfiguration
{
    
    
	uint32_t aMask = ((triggerMode[0] & 0x3)<<2) | ((triggerMode[1] & 0x3)<<10);
	if(invertInput[0])             aMask |= kInvertInputMask0;
	if(enableErrorCorrection[0])   aMask |= kErrorCorrectionMask0;
	if(saveFirstEvent[0])          aMask |= kSaveDataFirstEvent0;
	if(saveFIRTrigger[0])          aMask |= kSaveDataIfPileupMask0;
	if(saveAlways[0])              aMask |= kSaveDataAlwaysMask0;
	if(saveIfPileUp[0])            aMask |= kSaveDataIfPileupMask0;
    
	if(invertInput[1])             aMask |= kInvertInputMask1;
	if(enableErrorCorrection[1])   aMask |= kErrorCorrectionMask1;
	if(saveFirstEvent[1])          aMask |= kSaveDataFirstEvent1;
	if(saveFIRTrigger[1])          aMask |= kSaveDataIfPileupMask1;
	if(saveAlways[1])              aMask |= kSaveDataAlwaysMask1;
	if(saveIfPileUp[1])            aMask |= kSaveDataIfPileupMask1;
	
	[[self adapter] writeLongBlock:&aMask
                         atAddress:baseAddress + kEventConfigAll
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (uint32_t) readEventConfigRegister
{
	//all have to be the same so just read group1
	uint32_t aValue = 0x0;
	[[self adapter] readLongBlock:&aValue
                        atAddress:baseAddress + kEventConfigAdc12
                        numToRead:1
                       withAddMod:addressModifier
                    usingAddSpace:0x01];
	return aValue;
}

- (void) writePreTriggerDelayAndTriggerGateDelay
{
	int i;
	for(i=0;i<kNumSIS3320Groups;i++){
		
		int preTrigDelay = [self preTriggerDelay:i];
		int gateLen      = [self triggerGateLength:i]-1;
		
		uint32_t aValue = ((preTrigDelay&0x3ff)<<16) | (gateLen&0x3ff);
		[[self adapter] writeLongBlock:&aValue
							 atAddress:[self baseAddress] +preTriggerDelayTriggerGateLengthAddress[i]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
	}
}


- (void) writeRawDataBufferConfiguration
{
	int i;
	for(i=0;i<kNumSIS3320Groups;i++){
		
		int sampleLength = (int)[self bufferLength:i];
		int sampleStart  = (int)[self bufferStart:i];
		
        /*        if(sampleLength > 1022) {
         sampleLength = 1022;
         // previously checked for sampleLength == 1024, and if true, set sampleLength to 0
         // this doesn't make sense... changed 9/27/13, GCR
         }
         else {
         // previously was masked with 0x3fc, making max value 1020
         // value adjusted to appropriate one, corresponding to 1022
         // updated 9/27/13, GCR
         sampleLength &= 0x3FE;
         }*/
        // whole block above is handled by this mask..
        // enforces max length of 1022 (9/27/13)
        sampleLength &= 0x3FE;
        
		uint32_t aValue = ((sampleLength&0x3ff)<<16) | (sampleStart&0x3ff);
		[[self adapter] writeLongBlock:&aValue
							 atAddress:[self baseAddress] + rawDataBufferConfigurationAddress[i]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
	}
}

- (uint32_t) nextSampleAddress:(int)aChannel
{
	uint32_t aValue = 0;
	[[self adapter] readLongBlock:&aValue
						atAddress:baseAddress + nextSampleAddress[aChannel]
						numToRead:1
					   withAddMod:addressModifier
					usingAddSpace:0x01];
	return aValue;
	
}

- (uint32_t) actualSampleValue:(int)aGroup
{
	uint32_t aValue = 0;
	[[self adapter] readLongBlock:&aValue
						atAddress:baseAddress + actualSampleAddress[aGroup]
						numToRead:1
					   withAddMod:addressModifier
					usingAddSpace:0x01];
	return aValue;
	
}

- (void) writeTriggerSetupRegisters
{
	int i;
	for(i=0;i<kNumSIS3320Channels;i++){
		[self writeTriggerSetupRegister:i];
	}
}

- (void) writeTriggerSetupRegister:(int)aChannel
{
	uint32_t aMask = 0x0;
	aMask |= ([self trigPulseLen:aChannel] & 0x3F) << 16;
	aMask |= ([self sumG:aChannel]         & 0x1F) <<  8;
	aMask |= ([self peakingTime:aChannel]  & 0x1F) <<  0;
	[[self adapter] writeLongBlock:&aMask
						 atAddress:baseAddress + triggerSetupAddress[aChannel]
						numToWrite:1
						withAddMod:addressModifier
					 usingAddSpace:0x01];
}

- (void) writeThresholds
{
	int i;
	for(i=0;i<kNumSIS3320Channels;i++){
		[self writeThreshold:i];
	}
}


// modified 8/28/13 to write appropriate, predefined values to disabled channels
- (void) writeThreshold:(int)aChannel
{
	uint32_t theThresholdValue =  ([self threshold:aChannel]+0x10000) & 0x1ffff;
	uint32_t gt                = (gtMask >> aChannel) & 0x1;
	uint32_t disableTrigOut    = !(triggerOutMask >> aChannel) & 0x1;
	uint32_t extendedTrigMode  = (extendedTriggerMask >> aChannel) & 0x1;
    
    if( !(onlineMask & ( 0x1 << aChannel )) ) {
        theThresholdValue = 0x1FFFF;
        gt = 0;
        disableTrigOut = 1;
        extendedTrigMode = 0;
        
    }
    
	uint32_t writeValue =	(extendedTrigMode << 24) |
    (gt << 25)               |
    (disableTrigOut << 26)          |
    theThresholdValue ;
	
	[[self adapter] writeLongBlock:&writeValue
						 atAddress:baseAddress + triggerThresholdAddress[aChannel]
						numToWrite:1
						withAddMod:addressModifier
					 usingAddSpace:0x01];
}

- (void) writeAccumulators
{
    
    // from manual..
    // bits 0-9 of the word define the start index (appropriate mask: 0x3ff)
    // bits 16-24 define length
    // --- this is 9 bits, so appropriate mask is 0x1ff
    // for accumulators 5-8, bits 16-19 define length
    // --- in this case, mask should be 0xff
    uint32_t aValue;
    int i;
    for(i=0;i<kNumSIS3320Groups;i++){
        //acc 1
        aValue =  ( (accGate1Length[i] & 0x1ff )<<16) | (accGate1StartIndex[i] & 0x3ff);
        [[self adapter] writeLongBlock:&aValue
                             atAddress:baseAddress + accumGate1Address[i]
                            numToWrite:1
                            withAddMod:addressModifier
                         usingAddSpace:0x01];
        
        //acc 2
        aValue =  ( (accGate2Length[i] & 0x1ff )<<16) | (accGate2StartIndex[i] & 0x3ff);
        [[self adapter] writeLongBlock:&aValue
                             atAddress:baseAddress + accumGate2Address[i]
                            numToWrite:1
                            withAddMod:addressModifier
                         usingAddSpace:0x01];
        
        //acc 3
        aValue =  ( ( accGate3Length[i] & 0x1ff )<<16) | (accGate3StartIndex[i] & 0x3ff);
        [[self adapter] writeLongBlock:&aValue
                             atAddress:baseAddress + accumGate3Address[i]
                            numToWrite:1
                            withAddMod:addressModifier
                         usingAddSpace:0x01];
        
        //acc 4
        aValue =  ( (accGate4Length[i] & 0x1ff )<<16) | (accGate4StartIndex[i] & 0x3ff);
        [[self adapter] writeLongBlock:&aValue
                             atAddress:baseAddress + accumGate4Address[i]
                            numToWrite:1
                            withAddMod:addressModifier
                         usingAddSpace:0x01];
        
        //acc 5
        aValue =  ( ( accGate5Length[i] & 0xf )<<16) | (accGate5StartIndex[i] & 0x3ff);
        [[self adapter] writeLongBlock:&aValue
                             atAddress:baseAddress + accumGate5Address[i]
                            numToWrite:1
                            withAddMod:addressModifier
                         usingAddSpace:0x01];
        
        //acc 6
        aValue =  ( (accGate6Length[i] & 0xf )<<16) | (accGate6StartIndex[i] & 0x3ff);
        [[self adapter] writeLongBlock:&aValue
                             atAddress:baseAddress + accumGate6Address[i]
                            numToWrite:1
                            withAddMod:addressModifier
                         usingAddSpace:0x01];
        
        
        //acc 7
        aValue =  ( (accGate7Length[i] & 0xf )<<16) | (accGate7StartIndex[i] & 0x3ff);
        [[self adapter] writeLongBlock:&aValue
                             atAddress:baseAddress + accumGate7Address[i]
                            numToWrite:1
                            withAddMod:addressModifier
                         usingAddSpace:0x01];
        
        
        //acc 8
        aValue =  ( ( accGate8Length[i] & 0xf )<<16) | (accGate8StartIndex[i] & 0x3ff);
        [[self adapter] writeLongBlock:&aValue
                             atAddress:baseAddress + accumGate8Address[i]
                            numToWrite:1
                            withAddMod:addressModifier
                         usingAddSpace:0x01];
    }
}


- (void) writePageRegister:(int)aPage
{
	uint32_t aValue = aPage;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:baseAddress + kAdcMemoryPageReg
						numToWrite:1
						withAddMod:addressModifier
					 usingAddSpace:0x01];
}




- (void) writeValue:(uint32_t)aValue offset:(int32_t)anOffset
{
	[[self adapter] writeLongBlock:&aValue
                         atAddress:baseAddress + anOffset
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) regDump
{
	@try {
		NSFont* font = [NSFont fontWithName:@"Monaco" size:11];
		NSLogFont(font,@"Reg Dump for SIS3320 (Slot %d)\n",[self slot]);
		NSLogFont(font,@"-----------------------------------\n");
		NSLogFont(font,@"[Add Offset]   Value        Name\n");
		NSLogFont(font,@"-----------------------------------\n");
		
		ORCommandList* aList = [ORCommandList commandList];
		int i;
		for(i=0;i<kNumSIS3320ReadRegs;i++){
			[aList addCommand: [ORVmeReadWriteCommand readLongBlockAtAddress: [self baseAddress] + register_information[i].offset
																   numToRead: 1
																  withAddMod: [self addressModifier]
															   usingAddSpace: 0x01]];
		}
		[self executeCommandList:aList];
		
		//if we get here, the results can retrieved in the same order as sent
		for(i=0;i<kNumSIS3320ReadRegs;i++){
			NSLogFont(font, @"[0x%08x] 0x%08x    %@\n",register_information[i].offset,[aList longValueForCmd:i],register_information[i].name);
		}
		
	}
	@catch(NSException* localException) {
        NSLog(@"SIS3302 Reg Dump FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nSIS3302 Reg Dump FAILED", @"OK", nil, nil,
                        localException);
    }
}

- (void) executeCommandList:(ORCommandList*) aList
{
	[[self adapter] executeCommandList:aList];
}


- (void) printReport
{
	NSFont* font = [NSFont fontWithName:@"Monaco" size:12];
	NSLogFont(font,@"%@:\n",[self fullID]);
	NSLogFont(font,@"-------------------------------------------\n");
	NSLogFont(font,@"Chan TrigOut GT Extended Thresholds \n");
    ORCommandList* aList = [ORCommandList commandList];
	int i;
	for(i =0; i < kNumSIS3320Channels; i++) {
        [aList addCommand: [ORVmeReadWriteCommand readLongBlockAtAddress: [self baseAddress] + triggerThresholdAddress[i]
                                                               numToRead: 1
                                                              withAddMod: [self addressModifier]
                                                           usingAddSpace: 0x01]];
    }
    [self executeCommandList:aList];
    
    
    aList = [ORCommandList commandList];
    for(i=0;i<kNumSIS3320Channels;i++){
		uint32_t aValue = [aList longValueForCmd:i];
		NSString* trigOut	= ((aValue>>26)&0x1) ? @" NO":@"YES";
		NSString* gt		= ((aValue>>25)&0x1) ? @" GT":@" LT";
		NSString* extended  = ((aValue>>24)&0x1) ? @"YES":@" NO";
		NSLogFont(font,@" %2d   %@  %@  %@   %8d\n",i,trigOut,gt,extended,(aValue&0x1ffff));
	}
	
	NSLogFont(font,@"-------------------------------------------\n");
	NSLogFont(font,@"Chan   PulseLen  SumGap  PeakTime\n");
	for(i =0; i < kNumSIS3320Channels; i++) {
        
        [aList addCommand: [ORVmeReadWriteCommand readLongBlockAtAddress: [self baseAddress] + triggerSetupAddress[i]
                                                               numToRead: 1
                                                              withAddMod: [self addressModifier]
                                                           usingAddSpace: 0x01]];
    }
    
    [self executeCommandList:aList];
    
    for(i=0;i<kNumSIS3320Channels;i++){
		uint32_t aValue = [aList longValueForCmd:i];
		NSLogFont(font,@" %2d   %8d    %4d     %4d\n",i, (aValue>>16)&0x3f,(aValue>>8)&0x1f,aValue&0x1f);
	}
	
	NSLogFont(font,@"-------------------------------------------\n");
	uint32_t aValue = [self readAcqRegister];
	NSLogFont(font,@"Clock Source     : %@\n",[self clockSourceName:(aValue>>12 & 0x7)]);
}

#pragma mark •••Data Taker
- (uint32_t) dataId { return dataId; }

- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORSIS3320WaveformDecoder",            @"decoder",
								 [NSNumber numberWithLong:dataId],       @"dataId",
								 [NSNumber numberWithBool:YES],          @"variable",
								 [NSNumber numberWithLong:-1],			 @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Waveform"];
    
    return dataDictionary;
}

#pragma mark •••HW Wizard
-(BOOL) hasParmetersToRamp
{
	return YES;
}

- (int) numberOfChannels
{
    return kNumSIS3320Channels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Online"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setOnlineMaskBit:withValue:) getMethod:@selector(onlineMaskBit:)];
    [p setActionMask:kAction_Set_Mask|kAction_Restore_Mask];
    [a addObject:p];
    
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Clock Source"];
    [p setFormat:@"##0" upperLimit:3 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setClockSource:) getMethod:@selector(clockSource)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0" upperLimit:0x3fff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setThreshold:withValue:) getMethod:@selector(threshold:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Pretrigger Delay"];
    [p setFormat:@"##0" upperLimit:0x3ff lowerLimit:1 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPreTriggerDelay:withValue:) getMethod:@selector(preTriggerDelay:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trigger Gate Length"];
    [p setFormat:@"##0" upperLimit:1024 lowerLimit:1 stepSize:1 units:@""];
    [p setSetMethod:@selector(setTriggerGateLength:withValue:) getMethod:@selector(triggerGateLength:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Dac Value"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setDacValue:withValue:) getMethod:@selector(dacValue:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trig Pulse Length"];
    [p setFormat:@"##0" upperLimit:0x3f lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setTrigPulseLen:withValue:) getMethod:@selector(trigPulseLen:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Gap Length"];
    [p setFormat:@"##0" upperLimit:0x1f lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setSumG:withValue:) getMethod:@selector(sumG:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Peaking Time"];
    [p setFormat:@"##0" upperLimit:0x1f lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPeakingTime:withValue:) getMethod:@selector(peakingTime:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Init"];
    [p setSetMethodSelector:@selector(initBoard)];
    [a addObject:p];
    
    return a;
}


- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
	if(     [param isEqualToString:@"Threshold ON"])	return [[cardDictionary objectForKey:@"thresholds"]		objectAtIndex:aChannel];
    else if([param isEqualToString:@"Threshold OFF"])	return [[cardDictionary objectForKey:@"thresholdOffs"]	objectAtIndex:aChannel];
    else if([param isEqualToString:@"Dac Value"])		return [[cardDictionary objectForKey:@"dacValues"]		objectAtIndex:aChannel];
	else if([param isEqualToString:@"Pulse Length"])	return [[cardDictionary objectForKey:@"trigPulseLens"]	objectAtIndex:aChannel];
	else if([param isEqualToString:@"Gap Length"])		return [[cardDictionary objectForKey:@"sumGs"]			objectAtIndex:aChannel];
	else if([param isEqualToString:@"Peak Length"])		return [[cardDictionary objectForKey:@"peakingTimes"]	objectAtIndex:aChannel];
	else if([param isEqualToString:@"Clock Source"])	return [cardDictionary objectForKey:@"clockSource"];
	else if([param isEqualToString:@"Max Events"])				return [cardDictionary objectForKey:@"maxEvents"];
    else if([param isEqualToString:@"Pretrigger Delay"])			return [cardDictionary objectForKey:@"preTriggerDelay"];
    else if([param isEqualToString:@"Trigger Gate Delay"])			return [cardDictionary objectForKey:@"triggerGateLength"];
    else if([param isEqualToString:@"Online"]) return [cardDictionary objectForKey:@"onlineMask"];
    else return nil;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate"   className:@"ORVmeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel    name:@"Card"    className:@"ORSIS3320Model"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel   name:@"Channel" className:@"ORSIS3320Model"]];
    return a;
}

#pragma mark •••Data Taker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"No Crate controller detected."];
    }
    
    [dataRateAlarm clearAlarm];
    [dataRateAlarm release];
    dataRateAlarm = nil;
    
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORSIS3320Model"];
    
    [self startRates];
	//cache some stuff
    location        = (([self crateNumber]&0x0000000f)<<21) | (([self slot]& 0x0000001f)<<16);
    theController   = [self adapter];
	ledOn = YES;
	
	//[self reset];
	[self initBoard];
	[self armBank1];
    uint32_t status = [self readAcqRegister] & 0xc0000;
    NSLog(@"status word: 0x%0x\n",status);
    
	isRunning		= NO;
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    @try {
		isRunning		= YES;
		uint32_t status = [self readAcqRegister];
		if(!dataRateAlarm && ((status & kEndAddressThresholdFlag) == kEndAddressThresholdFlag)){
            
            if(bank1Armed)  [self armBank2];
            else            [self armBank1];
                        
            int i;
			for (i=0;i<8;i++) {
                
                
                if( !(onlineMask & ( 0x1 << i )) ) continue;
                
                uint32_t endSampleAddressPrevBank = [self readPreviousAdcAddress:i];
                
                if( endSampleAddressPrevBank != 0 ) {
                    uint32_t numLongsToRead = endSampleAddressPrevBank;
                    if(numLongsToRead+2 > 0x3FFFF){ //can't have a record larger than the max ORCA record size.
                        if(!dataRateAlarm){
                            dataRateAlarm = [[ORAlarm alloc] initWithName:@"SIS3320 Rate Too High" severity:kHardwareAlarm];
                            [dataRateAlarm setHelpString:@"Data Rate is too high to take data via the Mac. Use the SBC.\n\nThis alarm will remain until you restart the run with a lower rate. No data will be taken at this rate. You may acknowledge the alarm to silence it"];
                            [dataRateAlarm setSticky:YES];
                        }
                        [dataRateAlarm postAlarm];
                        break;
                    }
                    uint32_t data[ numLongsToRead + 2 ]; //max length plus Orca header
                    // --- in theory, this should perhaps be .. 8 MB, if size is fixed
                    // --- NOTE THIS NOW WILL HOLD MORE THAN A SINGLE EVENT
                    
                    unsigned int nWordsPerEvent = (unsigned int)bufferLength[i/2]/2 + 10;
                    // --- now we can determine the number of events we read
                    // --- this assumes that all events are of equal length (i.e., ALL or NO events record waveforms, options for 'if pileup' or 'first event of buffer' are not selected)
                    unsigned int nEventsInTransferredData = ceil(numLongsToRead / (float)nWordsPerEvent);
                    waveFormCount[i] += nEventsInTransferredData;
                     
                    data[0] = dataId | (2 + numLongsToRead);
                    data[1] = location | (i<<8);
                    [[self adapter] readLongBlock:&data[2]
                                        atAddress:baseAddress + adcMemoryPage[i] // --- this is in line with my code, adcMemoryPage[1] is equivalent to SIS3320_ADC1_OFFSET in Struck's header
                                        numToRead:numLongsToRead // --- this is actually the number of 32bit words to read.. check that this is ok
                                       withAddMod:addressModifier
                                    usingAddSpace:0x01];
                    [aDataPacket addLongsToFrameBuffer:data length:2 + numLongsToRead];
                    
				}
			}
		}
	}
    
    
    
	@catch(NSException* localException) {
		[self incExceptionCount];
		[localException raise];
	}
    
}


- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	ledOn = NO;
	[self writeControlStatusRegister];
	
	[self disarmSamplingLogic];
	isRunning = NO;
    [waveFormRateGroup stop];
    [dataRateAlarm clearAlarm];
    [dataRateAlarm release];
    dataRateAlarm = nil;
}

//this is the data structure for the new SBCs (i.e. VX704 from Concurrent)
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id				= kSIS3320; //should be unique
	configStruct->card_info[index].hw_mask[0]				= dataId;	//better be unique
	configStruct->card_info[index].slot						= [self slot];
	configStruct->card_info[index].crate					= [self crateNumber];
	configStruct->card_info[index].add_mod					= addressModifier;
	configStruct->card_info[index].base_add					= baseAddress;
    int i;
    for(i=0;i<kNumSIS3320Groups;i++){
        configStruct->card_info[index].deviceSpecificData[i]	= [self endAddressThreshold:i];
    }
    configStruct->card_info[index].deviceSpecificData[kNumSIS3320Groups] = onlineMask;
    
	configStruct->card_info[index].num_Trigger_Indexes		= 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;
	
	return index+1;
}


- (BOOL) bumpRateFromDecodeStage:(short)channel
{
    if(isRunning)return NO;
    
    ++waveFormCount[channel];
    return YES;
}


// bump the decoded event count by a number specified by nDecodedEvents
- (BOOL) bumpRateFromDecodeStage:(short)channel nDecodedEvents:(int)bumpNumber
{
    if( isRunning ) return NO;
    
    waveFormCount[channel] += bumpNumber;
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
    for(i=0;i<kNumSIS3320Channels;i++){
        waveFormCount[i]=0;
    }
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setLemoTimeStampClrEnabled:   [decoder decodeBoolForKey: @"lemoTimeStampClrEnabled"]];
    [self setLemoTriggerEnabled:        [decoder decodeBoolForKey: @"lemoTriggerEnabled"]];
    [self setInternalTriggerEnabled:    [decoder decodeBoolForKey: @"internalTriggerEnabled"]];
    [self setGtMask:                    [decoder decodeIntegerForKey:  @"gtMask"]];
    [self setTriggerOutMask:            [decoder decodeIntegerForKey:  @"triggerOutMask"]];
    [self setExtendedTriggerMask:       [decoder decodeIntegerForKey:  @"extendedTriggerMask"]];
    [self setClockSource:               [decoder decodeIntForKey:  @"clockSource"]];
    
    [self setOnlineMask:                [decoder decodeIntegerForKey:  @"onlineMask"]];
    
    int i;
    for(i=0;i<4;i++){
        [self setBufferStart:i      withValue: [decoder decodeIntForKey:[NSString stringWithFormat:@"bufferStart%d",i]]];
        [self setBufferLength:i     withValue: [decoder decodeIntForKey:[NSString stringWithFormat:@"bufferLength%d",i]]];
        [self setAccGate1Length:i     withValue: [decoder decodeIntForKey:[NSString stringWithFormat:@"accGate1Length%d",i]]];
        [self setAccGate1StartIndex:i withValue: [decoder decodeIntForKey:[NSString stringWithFormat:@"accGate1StartIndex%d",i]]];
        [self setAccGate2Length:i     withValue: [decoder decodeIntForKey:[NSString stringWithFormat:@"accGate2Length%d",i]]];
        [self setAccGate2StartIndex:i withValue: [decoder decodeIntForKey:[NSString stringWithFormat:@"accGate2StartIndex%d",i]]];
        [self setAccGate3Length:i     withValue: [decoder decodeIntForKey:[NSString stringWithFormat:@"accGate3Length%d",i]]];
        [self setAccGate3StartIndex:i withValue: [decoder decodeIntForKey:[NSString stringWithFormat:@"accGate3StartIndex%d",i]]];
        [self setAccGate4Length:i     withValue: [decoder decodeIntForKey:[NSString stringWithFormat:@"accGate4Length%d",i]]];
        [self setAccGate4StartIndex:i withValue: [decoder decodeIntForKey:[NSString stringWithFormat:@"accGate4StartIndex%d",i]]];
        [self setAccGate5Length:i     withValue: [decoder decodeIntForKey:[NSString stringWithFormat:@"accGate5Length%d",i]]];
        [self setAccGate5StartIndex:i withValue: [decoder decodeIntForKey:[NSString stringWithFormat:@"accGate5StartIndex%d",i]]];
        [self setAccGate6Length:i     withValue: [decoder decodeIntForKey:[NSString stringWithFormat:@"accGate6Length%d",i]]];
        [self setAccGate6StartIndex:i withValue: [decoder decodeIntForKey:[NSString stringWithFormat:@"accGate6StartIndex%d",i]]];
        [self setAccGate7Length:i     withValue: [decoder decodeIntForKey:[NSString stringWithFormat:@"accGate7Length%d",i]]];
        [self setAccGate7StartIndex:i withValue: [decoder decodeIntForKey:[NSString stringWithFormat:@"accGate7StartIndex%d",i]]];
        [self setAccGate8Length:i     withValue: [decoder decodeIntForKey:[NSString stringWithFormat:@"accGate8Length%d",i]]];
        [self setAccGate8StartIndex:i withValue: [decoder decodeIntForKey:[NSString stringWithFormat:@"accGate8StartIndex%d",i]]];
    }
    for(i=0;i<2;i++){
        [self setTriggerMode:i      withValue: [decoder decodeBoolForKey:[NSString stringWithFormat:@"triggerMode%d",i]]];
        [self setInvertInput:i      withValue: [decoder decodeBoolForKey:[NSString stringWithFormat:@"invertInput%d",i]]];
        [self setEnableErrorCorrection:i withValue:[decoder decodeBoolForKey:[NSString stringWithFormat:@"enableErrorCorrection%d",i]]];
        [self setSaveAlways:i       withValue: [decoder decodeBoolForKey:[NSString stringWithFormat:@"saveAlways%d",i]]];
        [self setSaveIfPileUp:i     withValue: [decoder decodeBoolForKey:[NSString stringWithFormat:@"saveIfPileUp%d",i]]];
        [self setSaveFIRTrigger:i   withValue: [decoder decodeBoolForKey:[NSString stringWithFormat:@"saveFIRTrigger%d",i]]];
        [self setSaveFirstEvent:i   withValue: [decoder decodeBoolForKey:[NSString stringWithFormat:@"saveFirstEvent%d",i]]];
    }
    
	peakingTimes	= [[decoder decodeObjectForKey: @"peakingTimes"] retain];
	thresholds		= [[decoder decodeObjectForKey: @"thresholds"] retain];
	sumGs			= [[decoder decodeObjectForKey: @"sumGs"] retain];
	trigPulseLens	= [[decoder decodeObjectForKey: @"trigPulseLens"] retain];
	dacValues		= [[decoder decodeObjectForKey: @"dacValues"] retain];
    preTriggerDelays= [[decoder decodeObjectForKey: @"preTriggerDelays"] retain];
    triggerGateLengths= [[decoder decodeObjectForKey:@"triggerGateLengths"] retain];
    endAddressThresholds= [[decoder decodeObjectForKey:@"endAddressThresholds"] retain];
    
    [self setUpArrays];
    
	
    [self setWaveFormRateGroup:[decoder decodeObjectForKey:@"waveFormRateGroup"]];
    if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:kNumSIS3320Channels groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];
	
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    
    [encoder encodeBool:lemoTimeStampClrEnabled forKey:@"lemoTimeStampClrEnabled"];
    [encoder encodeBool:lemoTriggerEnabled      forKey:@"lemoTriggerEnabled"];
    [encoder encodeBool:internalTriggerEnabled  forKey:@"internalTriggerEnabled"];
    [encoder encodeInteger:gtMask					forKey:@"gtMask"];
    [encoder encodeInteger:triggerOutMask           forKey:@"triggerOutMask"];
    [encoder encodeInteger:extendedTriggerMask      forKey:@"extendedTriggerMask"];
    [encoder encodeInt:clockSource				forKey:@"clockSource"];
    [encoder encodeInteger:onlineMask               forKey:@"onlineMask"];
    
    int i;
    
    for(i=0;i<kNumSIS3320Groups;i++){
        [encoder encodeInteger:bufferStart[i]             forKey:[NSString stringWithFormat:@"bufferStart%d",i]];
        [encoder encodeInteger:bufferLength[i]            forKey:[NSString stringWithFormat:@"bufferLength%d",i]];
        
        [encoder encodeInt: accGate1StartIndex[i]      forKey:[NSString stringWithFormat:@"accGate1StartIndex%d",i]];
        [encoder encodeInt: accGate1Length[i]        forKey:[NSString stringWithFormat:@"accGate1Length%d",i]];
        [encoder encodeInt: accGate2StartIndex[i]      forKey:[NSString stringWithFormat:@"accGate2StartIndex%d",i]];
        [encoder encodeInt: accGate2Length[i]        forKey:[NSString stringWithFormat:@"accGate2Length%d",i]];
        [encoder encodeInt: accGate3StartIndex[i]      forKey:[NSString stringWithFormat:@"accGate3StartIndex%d",i]];
        [encoder encodeInt: accGate3Length[i]        forKey:[NSString stringWithFormat:@"accGate3Length%d",i]];
        [encoder encodeInt: accGate4StartIndex[i]      forKey:[NSString stringWithFormat:@"accGate4StartIndex%d",i]];
        [encoder encodeInt: accGate4Length[i]        forKey:[NSString stringWithFormat:@"accGate4Length%d",i]];
        [encoder encodeInt: accGate5StartIndex[i]      forKey:[NSString stringWithFormat:@"accGate5StartIndex%d",i]];
        [encoder encodeInt: accGate5Length[i]        forKey:[NSString stringWithFormat:@"accGate5Length%d",i]];
        [encoder encodeInt: accGate6StartIndex[i]      forKey:[NSString stringWithFormat:@"accGate6StartIndex%d",i]];
        [encoder encodeInt: accGate6Length[i]        forKey:[NSString stringWithFormat:@"accGate6Length%d",i]];
        [encoder encodeInt: accGate7StartIndex[i]      forKey:[NSString stringWithFormat:@"accGate7StartIndex%d",i]];
        [encoder encodeInt: accGate7Length[i]        forKey:[NSString stringWithFormat:@"accGate7Length%d",i]];
        [encoder encodeInt: accGate8StartIndex[i]      forKey:[NSString stringWithFormat:@"accGate8StartIndex%d",i]];
        [encoder encodeInt: accGate8Length[i]        forKey:[NSString stringWithFormat:@"accGate8Length%d",i]];
    }
    for(i=0;i<2;i++){
        [encoder encodeBool:triggerMode[i]              forKey:[NSString stringWithFormat:@"triggerMode%d",i]];
        [encoder encodeBool:invertInput[i]              forKey:[NSString stringWithFormat:@"invertInput%d",i]];
        [encoder encodeBool:enableErrorCorrection[i]    forKey:[NSString stringWithFormat:@"enableErrorCorrection%d",i]];
        [encoder encodeBool:saveAlways[i]               forKey:[NSString stringWithFormat:@"saveAlways%d",i]];
        [encoder encodeBool:saveIfPileUp[i]             forKey:[NSString stringWithFormat:@"saveIfPileUp%d",i]];
        [encoder encodeBool:saveFIRTrigger[i]           forKey:[NSString stringWithFormat:@"saveFIRTrigger%d",i]];
        [encoder encodeBool:saveFirstEvent[i]           forKey:[NSString stringWithFormat:@"saveFirstEvent%d",i]];
    }
    
    
    if(preTriggerDelays)[encoder encodeObject:preTriggerDelays		forKey:@"preTriggerDelays"];
	if(dacValues)		[encoder encodeObject:dacValues             forKey:@"dacValues"];
	if(thresholds)		[encoder encodeObject:thresholds            forKey:@"thresholds"];
	if(peakingTimes)	[encoder encodeObject:peakingTimes          forKey:@"peakingTimes"];
	if(sumGs)			[encoder encodeObject:sumGs                 forKey:@"sumGs"];
	if(trigPulseLens)	[encoder encodeObject:trigPulseLens         forKey:@"trigPulseLens"];
	if(triggerGateLengths)      [encoder encodeObject:triggerGateLengths         forKey:@"triggerGateLengths"];
	if(endAddressThresholds)	[encoder encodeObject:endAddressThresholds         forKey:@"endAddressThresholds"];
	
	[encoder encodeObject:waveFormRateGroup		forKey:@"waveFormRateGroup"];
    
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    if(thresholds)		[objDictionary setObject:thresholds						forKey:@"thresholds"];
    if(dacValues)		[objDictionary setObject:dacValues						forKey:@"dacValues"];
    if(trigPulseLens)	[objDictionary setObject:trigPulseLens					forKey:@"trigPulseLens"];
    if(peakingTimes)	[objDictionary setObject:peakingTimes					forKey:@"peakingTimes"];
    if(sumGs)			[objDictionary setObject:sumGs							forKey:@"sumGs"];
    
    [objDictionary setObject:[NSNumber numberWithLong:clockSource]				forKey:@"clockSource"];
    
    [objDictionary setObject:[NSNumber numberWithInteger:onlineMask] forKey:@"onlineMask"];
    [objDictionary setObject: preTriggerDelays		    forKey:@"preTriggerDelays"];
    [objDictionary setObject: triggerGateLengths		forKey:@"triggerGateLengths"];
    
	return objDictionary;
}

#pragma mark •••AutoTesting
- (NSArray*) autoTests
{
	NSMutableArray* myTests = [NSMutableArray array];
	[myTests addObject:[ORVmeReadOnlyTest test:kControlStatus wordSize:4 name:@"Control Status"]];
	[myTests addObject:[ORVmeReadOnlyTest test:kModuleIDReg wordSize:4 name:@"Module ID"]];
	[myTests addObject:[ORVmeReadWriteTest test:kAdcMemoryPageReg wordSize:4 validMask:0x0000000f name:@"Page Reg"]];
    
	[myTests addObject:[ORVmeReadOnlyTest test:kAcquisitionControlReg wordSize:4 name:@"Acquisition Control"]];
    
	int i;
	for(i=0;i<kNumSIS3320Channels;i++){
		[myTests addObject:[ORVmeReadWriteTest test:triggerThresholdAddress[i] wordSize:4 validMask:0xffff name:[NSString stringWithFormat:@"ADC%d",i]]];
	}
	return myTests;
	
}
- (int) limitIntValue:(int)aValue min:(int)aMin max:(int)aMax
{
	if(aValue<aMin)return aMin;
	else if(aValue>aMax)return aMax;
	else return aValue;
}
@end

@implementation ORSIS3320Model (private)

- (void) setUpArrays
{
	if(!dacValues)              dacValues               = [[self arrayOfLength:kNumSIS3320Channels] retain];
	if(!trigPulseLens)          trigPulseLens           = [[self arrayOfLength:kNumSIS3320Channels] retain];
	if(!sumGs)                  sumGs                   = [[self arrayOfLength:kNumSIS3320Channels] retain];
	if(!peakingTimes)           peakingTimes            = [[self arrayOfLength:kNumSIS3320Channels] retain];
	if(!preTriggerDelays)       preTriggerDelays        = [[self arrayOfLength:kNumSIS3320Groups] retain];
	if(!triggerGateLengths)     triggerGateLengths      = [[self arrayOfLength:kNumSIS3320Groups] retain];
	if(!endAddressThresholds)	endAddressThresholds	= [[self arrayOfLength:kNumSIS3320Groups] retain];
	if(!thresholds)             thresholds              = [[self arrayOfLength:kNumSIS3320Channels] retain];
    
}
- (NSMutableArray*) arrayOfLength:(int)len
{
	int i;
	NSMutableArray* anArray = [NSMutableArray arrayWithCapacity:kNumSIS3320Channels];
	for(i=0;i<len;i++)[anArray addObject:[NSNumber numberWithInt:0]];
	return anArray;
}
@end
