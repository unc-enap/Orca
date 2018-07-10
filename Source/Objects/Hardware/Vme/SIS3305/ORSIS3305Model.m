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

#pragma mark - Imported Files
#import "ORSIS3305Model.h"
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

NSString* ORSIS3305TDCMeasurementEnabledChanged         = @"ORSIS3305ModelTDCMeasurementEnabledChanged";
NSString* ORSIS3305TapDelayChanged                      = @"ORSIS3305TapDelayChanged";
NSString* ORSIS3305ModelPulseModeChanged				= @"ORSIS3305ModelPulseModeChanged";
NSString* ORSIS3305ModelFirmwareVersionChanged			= @"ORSIS3305ModelFirmwareVersionChanged";
NSString* ORSIS3305TemperatureChanged                   = @"ORSIS3305TemperatureChanged";
NSString* ORSIS3305WriteGainPhaseOffsetChanged          = @"ORSIS3305WriteGainPhaseOffsetChanged";

NSString* ORSIS3305ModelBufferWrapEnabledChanged		= @"ORSIS3305ModelBufferWrapEnabledChanged";
//NSString* ORSIS3305ModelCfdControlChanged				= @"ORSIS3305ModelCfdControlChanged";
NSString* ORSIS3305ModelShipTimeRecordAlsoChanged		= @"ORSIS3305ModelShipTimeRecordAlsoChanged";
NSString* ORSIS3305ModelMcaUseEnergyCalculationChanged  = @"ORSIS3305ModelMcaUseEnergyCalculationChanged";
NSString* ORSIS3305ModelMcaEnergyOffsetChanged			= @"ORSIS3305ModelMcaEnergyOffsetChanged";
NSString* ORSIS3305ModelMcaEnergyMultiplierChanged		= @"ORSIS3305ModelMcaEnergyMultiplierChanged";
NSString* ORSIS3305ModelMcaEnergyDividerChanged			= @"ORSIS3305ModelMcaEnergyDividerChanged";
NSString* ORSIS3305ModelMcaModeChanged					= @"ORSIS3305ModelMcaModeChanged";
NSString* ORSIS3305ModelMcaPileupEnabledChanged			= @"ORSIS3305ModelMcaPileupEnabledChanged";
NSString* ORSIS3305ModelMcaHistoSizeChanged				= @"ORSIS3305ModelMcaHistoSizeChanged";
NSString* ORSIS3305ModelMcaNofScansPresetChanged		= @"ORSIS3305ModelMcaNofScansPresetChanged";
NSString* ORSIS3305ModelMcaAutoClearChanged				= @"ORSIS3305ModelMcaAutoClearChanged";
NSString* ORSIS3305ModelMcaPrescaleFactorChanged		= @"ORSIS3305ModelMcaPrescaleFactorChanged";
NSString* ORSIS3305ModelMcaLNESetupChanged				= @"ORSIS3305ModelMcaLNESetupChanged";
NSString* ORSIS3305ModelMcaNofHistoPresetChanged		= @"ORSIS3305ModelMcaNofHistoPresetChanged";

NSString* ORSIS3305ModelInternalExternalTriggersOredChanged = @"ORSIS3305ModelInternalExternalTriggersOredChanged";
NSString* ORSIS3305ModelLemoInEnabledMaskChanged		= @"ORSIS3305ModelLemoInEnabledMaskChanged";
NSString* ORSIS3305ModelRunModeChanged					= @"ORSIS3305ModelRunModeChanged";
NSString* ORSIS3305ModelEndAddressThresholdChanged		= @"ORSIS3305ModelEndAddressThresholdChanged";
NSString* ORSIS3305ModelEnergySampleStartIndex3Changed	= @"ORSIS3305ModelEnergySampleStartIndex3Changed";
NSString* ORSIS3305ModelEnergyTauFactorChanged			= @"ORSIS3305ModelEnergyTauFactorChanged";
NSString* ORSIS3305ModelEnergySampleStartIndex2Changed	= @"ORSIS3305ModelEnergySampleStartIndex2Changed";
NSString* ORSIS3305ModelEnergySampleStartIndex1Changed	= @"ORSIS3305ModelEnergySampleStartIndex1Changed";
NSString* ORSIS3305ModelEnergyNumberToSumChanged		= @"ORSIS3305ModelEnergyNumberToSumChanged";
NSString* ORSIS3305ModelEnergySampleLengthChanged		= @"ORSIS3305ModelEnergySampleLengthChanged";
NSString* ORSIS3305ModelEnergyGapTimeChanged	 = @"ORSIS3305ModelEnergyGapTimeChanged";
NSString* ORSIS3305ModelTriggerGateLengthChanged = @"ORSIS3305ModelTriggerGateLengthChanged";
NSString* ORSIS3305ModelPreTriggerDelayChanged  = @"ORSIS3305ModelPreTriggerDelayChanged";
NSString* ORSIS3305SampleStartIndexChanged		= @"ORSIS3305SampleStartIndexChanged";
NSString* ORSIS3305SampleLengthChanged			= @"ORSIS3305SampleLengthChanged";
NSString* ORSIS3305SampleStartAddressChanged    = @"ORSIS3305SampleStartAddressChanged";
NSString* ORSIS3305DacOffsetChanged				= @"ORSIS3305DacOffsetChanged";
NSString* ORSIS3305LemoInModeChanged			= @"ORSIS3305LemoInModeChanged";
NSString* ORSIS3305LemoOutModeChanged			= @"ORSIS3305LemoOutModeChanged";
//NSString* ORSIS3305AcqRegChanged				= @"ORSIS3305AcqRegChanged";
NSString* ORSIS3305AcquisitionControlRegChanged = @"ORSIS3305AcquisitionControlRegChanged";
NSString* ORSIS3305EventConfigChanged			= @"ORSIS3305EventConfigChanged";
NSString* ORSIS3305InputInvertedChanged			= @"ORSIS3305InputInvertedChanged";

NSString* ORSIS3305ExternalTriggerEnabledChanged = @"ORSIS3305ExternalTriggerEnabledChanged";
NSString* ORSIS3305InternalGateEnabledChanged	= @"ORSIS3305InternalGateEnabledChanged";
NSString* ORSIS3305ExternalGateEnabledChanged	= @"ORSIS3305ExternalGateEnabledChanged";

// acquisition reg
NSString* ORSIS3305ClockSourceChanged			= @"ORSIS3305ClockSourceChanged";
NSString* ORSIS3305ChannelEnabledChanged		= @"ORSIS3305ChannelEnabledChanged";

NSString* ORSIS3305RateGroupChangedNotification	= @"ORSIS3305RateGroupChangedNotification";
NSString* ORSIS3305SettingsLock					= @"ORSIS3305SettingsLock";

NSString* ORSIS3305TriggerOutEnabledChanged		= @"ORSIS3305TriggerOutEnabledChanged";
NSString* ORSIS3305HighEnergySuppressChanged	= @"ORSIS3305HighEnergySuppressChanged";
NSString* ORSIS3305ThresholdChanged				= @"ORSIS3305ThresholdChanged";

NSString* ORSIS3305ThresholdModeChanged         = @"ORSIS3305ThresholdModeChanged";

NSString* ORSIS3305GTThresholdOnChanged         = @"ORSIS3305GTThresholdOnChanged";
NSString* ORSIS3305GTThresholdOffChanged        = @"ORSIS3305GTThresholdOffChanged";
NSString* ORSIS3305LTThresholdOnChanged         = @"ORSIS3305LTThresholdOnChanged";
NSString* ORSIS3305LTThresholdOffChanged        = @"ORSIS3305LTThresholdOffChanged";

NSString* ORSIS3305ThresholdArrayChanged		= @"ORSIS3305ThresholdArrayChanged";

NSString* ORSIS3305LTThresholdEnabledChanged    = @"ORSIS3305LTThresholdEnabledChanged";
NSString* ORSIS3305GTThresholdEnabledChanged    = @"ORSIS3305GTThresholdEnabledChanged";

// control status
NSString* ORSIS3305LEDApplicationModeChanged    = @"ORSIS3305LEDApplicationModeChanged";


// event config
NSString* ORSIS3305EventSavingModeChanged                           = @"ORSIS3305EventSavingModeChanged";
NSString* ORSIS3305ADCGateModeEnabledChanged                        = @"ORSIS3305ADCGateModeEnabledChanged";
NSString* ORSIS3305GlobalTriggerEnabledChanged                      = @"ORSIS3305GlobalTriggerEnabledChanged";
NSString* ORSIS3305InternalTriggerEnabledChanged                    = @"ORSIS3305InternalTriggerEnabledChanged";
NSString* ORSIS3305StartEventSamplingWithExtTrigEnabledChanged      = @"ORSIS3305StartEventSamplingWithExtTrigEnabledChanged";
NSString* ORSIS3305ClearTimestampWhenSamplingEnabledEnabledChanged  = @"ORSIS3305ClearTimestampWhenSamplingEnabledEnabledChanged";
NSString* ORSIS3305GrayCodeEnabledChanged                           = @"ORSIS3305GrayCodeEnabledChanged";
NSString* ORSIS3305ClearTimestampDisabledChanged                    = @"ORSIS3305ClearTimestampDisabledChanged";
NSString* ORSIS3305DirectMemoryHeaderDisabledChanged                = @"ORSIS3305DirectMemoryHeaderDisabledChanged";
NSString* ORSIS3305WaitPreTrigTimeBeforeDirectMemTrigChanged        = @"ORSIS3305WaitPreTrigTimeBeforeDirectMemTrigChanged";


NSString* ORSIS3305ChannelModeChanged   = @"ORSIS3305ChannelModeChanged";
NSString* ORSIS3305BandwidthChanged     = @"ORSIS3305BandwidthChanged";
NSString* ORSIS3305TestModeChanged      = @"ORSIS3305TestModeChanged";
NSString* ORSIS3305AdcOffsetChanged     = @"ORSIS3305AdcOffsetChanged";
NSString* ORSIS3305AdcGainChanged       = @"ORSIS3305AdcGainChanged";
NSString* ORSIS3305AdcPhaseChanged      = @"ORSIS3305AdcPhaseChanged";

//NSString* ORSIS3305ModelLemoOutSelectTriggerChanged = @"ORSIS3305ModelLemoOutSelectTriggerChanged";
//NSString* ORSIS3305ModelLemoOutSelectTriggerInChanged = @"ORSIS3305ModelLemoOutSelectTriggerInChanged";
//NSString* ORSIS3305ModelLemoOutSelectTriggerInPulseChanged  = @"ORSIS3305ModelLemoOutSelectTriggerInPulseChanged";
//NSString* ORSIS3305ModelLemoOutSelectTriggerInPulseWithSampleAndTDCChanged = @"ORSIS3305ModelLemoOutSelectTriggerInPulseWithSampleAndTDCChanged";
//NSString* ORSIS3305ModelLemoOutSelectSampleLogicArmedChanged = @"ORSIS3305ModelLemoOutSelectSampleLogicArmedChanged";
//NSString* ORSIS3305ModelLemoOutSelectSampleLogicEnabledChanged = @"ORSIS3305ModelLemoOutSelectSampleLogicEnabledChanged";
//NSString* ORSIS3305ModelLemoOutSelectKeyOutputPulseChanged = @"ORSIS3305ModelLemoOutSelectKeyOutputPulseChanged";
//NSString* ORSIS3305ModelLemoOutSelectControlLemoTriggerOutChanged = @"ORSIS3305ModelLemoOutSelectControlLemoTriggerOutChanged";
//NSString* ORSIS3305ModelLemoOutSelectExternalVetoChanged = @"ORSIS3305ModelLemoOutSelectExternalVetoChanged";
//NSString* ORSIS3305ModelLemoOutSelectInternalKeyVetoChanged = @"ORSIS3305ModelLemoOutSelectInternalKeyVetoChanged";
//NSString* ORSIS3305ModelLemoOutSelectExternalVetoLengthChanged = @"ORSIS3305ModelLemoOutSelectExternalVetoLengthChanged";
//NSString* ORSIS3305ModelLemoOutSelectMemoryOverrunVetoChanged = @"ORSIS3305ModelLemoOutSelectMemoryOverrunVetoChanged";
NSString* ORSIS3305EnableLemoInputTriggerChanged = @"ORSIS3305EnableLemotrChanged";
NSString* ORSIS3305EnableLemoInputCountChanged = @"ORSIS3305EnableLemoInputCountChanged";
NSString* ORSIS3305EnableLemoInputResetChanged = @"ORSIS3305EnableLemoInputResetChanged";
NSString* ORSIS3305EnableLemoInputDirectVetoChanged = @"ORSIS3305EnableLemoInputDirectVetoChanged";

NSString* ORSIS3305ControlLemoTriggerOut                   = @"ORSIS3305ControlLemoTriggerOut";
NSString* ORSIS3305LemoOutSelectTriggerChanged              = @"ORSIS3305LemoOutSelectTriggerChanged";
NSString* ORSIS3305LemoOutSelectTriggerInChanged            = @"ORSIS3305LemoOutSelectTriggerInChanged";
NSString* ORSIS3305LemoOutSelectTriggerInPulseChanged       = @"ORSIS3305LemoOutSelectTriggerInPulseChanged";
NSString* ORSIS3305LemoOutSelectTriggerInPulseWithSampleAndTDCChanged = @"ORSIS3305LemoOutSelectTriggerInPulseWithSampleAndTDCChanged";
NSString* ORSIS3305LemoOutSelectSampleLogicArmedChanged     = @"ORSIS3305LemoOutSelectSampleLogicArmedChanged";
NSString* ORSIS3305LemoOutSelectSampleLogicEnabledChanged   = @"ORSIS3305LemoOutSelectSampleLogicEnabledChanged";
NSString* ORSIS3305LemoOutSelectKeyOutputPulseChanged       = @"ORSIS3305LemoOutSelectKeyOutputPulseChanged";
NSString* ORSIS3305LemoOutSelectControlLemoTriggerOutChanged= @"ORSIS3305LemoOutSelectControlLemoTriggerOutChanged";
NSString* ORSIS3305LemoOutSelectExternalVetoChanged         = @"ORSIS3305LemoOutSelectExternalVetoChanged";
NSString* ORSIS3305LemoOutSelectInternalKeyVetoChanged      = @"ORSIS3305LemoOutSelectInternalKeyVetoChanged";
NSString* ORSIS3305LemoOutSelectExternalVetoLengthChanged   = @"ORSIS3305LemoOutSelectExternalVetoLengthChanged";
NSString* ORSIS3305LemoOutSelectMemoryOverrunVetoChanged    = @"ORSIS3305LemoOutSelectMemoryOverrunVetoChanged";

NSString* ORSIS3305InvertExternalLEMODirectVetoIn           = @"ORSIS3305InvertExternalLEMODirectVetoIn";


//NSString* ORSIS3305EnableExternalLEMODirectVetoInChanged    = @"ORSIS3305EnableExternalLEMODirectVetoInChanged";
//NSString* ORSIS3305EnableExternalLEMOResetInChanged         = @"ORSIS3305EnableExternalLEMOResetInChanged";
//NSString* ORSIS3305EnableExternalLEMOCountIn                = @"ORSIS3305EnableExternalLEMOCountIn";
//NSString* ORSIS3305InvertExternalLEMODirectVetoIn           = @"ORSIS3305InvertExternalLEMODirectVetoIn";
//NSString* ORSIS3305EnableExternalLEMOTriggerIn              = @"ORSIS3305EnableExternalLEMOTriggerIn";
NSString* ORSIS3305EnableExternalLEMOVetoDelayLengthLogic   = @"ORSIS3305EnableExternalLEMOVetoDelayLengthLogic";
NSString* ORSIS3305EdgeSensitiveExternalVetoDelayLengthLogic    = @"ORSIS3305EdgeSensitiveExternalVetoDelayLengthLogic";
NSString* ORSIS3305InvertExternalVetoInDelayLengthLogic     = @"ORSIS3305InvertExternalVetoInDelayLengthLogic";
NSString* ORSIS3305GateModeExternalVetoInDelayLengthLogic   = @"ORSIS3305GateModeExternalVetoInDelayLengthLogic";
NSString* ORSIS3305EnableMemoryOverrunVeto                  = @"ORSIS3305EnableMemoryOverrunVeto";





NSString* ORSIS3305SampleDone					= @"ORSIS3305SampleDone";
NSString* ORSIS3305IDChanged					= @"ORSIS3305IDChanged";
NSString* ORSIS3305GateLengthChanged			= @"ORSIS3305GateLengthChanged";
NSString* ORSIS3305PulseLengthChanged			= @"ORSIS3305PulseLengthChanged";
NSString* ORSIS3305InternalTriggerDelayChanged	= @"ORSIS3305InternalTriggerDelayChanged";
NSString* ORSIS3305TriggerDecimationChanged		= @"ORSIS3305TriggerDecimationChanged";
NSString* ORSIS3305EnergyDecimationChanged		= @"ORSIS3305EnergyDecimationChanged";
NSString* ORSIS3305LEDEnabledChanged            = @"ORSIS3305LEDEnabledChanged";
NSString* ORSIS3305SetShipWaveformChanged		= @"ORSIS3305SetShipWaveformChanged";
NSString* ORSIS3305SetShipSummedWaveformChanged	= @"ORSIS3305SetShipSummedWaveformChanged";
NSString* ORSIS3305McaStatusChanged				= @"ORSIS3305McaStatusChanged";
NSString* ORSIS3305CardInited					= @"ORSIS3305CardInited";

NSString* ORSIS3305ModelRegisterIndexChanged    = @"ORSIS3305ModelRegisterIndexChanged";
NSString* ORSIS3305ModelRegisterWriteValueChanged = @"ORSIS3305ModelRegisterWriteValueChanged";


//
//const unsigned short kchannelModeAndEventID[16][16] = {
//    {0,1,2,3,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 0
//    {0,1,2,3,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 1
//    {0,1,2,3,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 2
//    {0,1,2,3,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 3
//    
//    {0xF,0xF,0xF,0xF,0,2,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 4
//    {0xF,0xF,0xF,0xF,1,2,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 5
//    {0xF,0xF,0xF,0xF,0,3,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 6
//    {0xF,0xF,0xF,0xF,1,3,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 7
//    
//    {0xF,0xF,0xF,0xF,0xF,0xF,0xF,0,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 8
//    {0xF,0xF,0xF,0xF,0xF,0xF,0xF,1,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 8
//    {0xF,0xF,0xF,0xF,0xF,0xF,0xF,2,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 8
//    {0xF,0xF,0xF,0xF,0xF,0xF,0xF,3,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 8
//    {0xF,0xF,0xF,0xF,0xF,0xF,0xF,0,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 8
//    {0xF,0xF,0xF,0xF,0xF,0xF,0xF,1,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 8
//    {0xF,0xF,0xF,0xF,0xF,0xF,0xF,2,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 8
//    {0xF,0xF,0xF,0xF,0xF,0xF,0xF,3,0xF,0xF,0xF,0xF,0xF,0xF,0xF}  // channel mode 8
//};



@interface ORSIS3305Model (private)
//- (void) writeDacOffsets;
- (void) setUpArrays;
//- (void) pollMcaStatus;
- (NSMutableArray*) arrayOfLength:(int)len;
@end

@implementation ORSIS3305Model

#pragma mark - Static Declarations
//offsets from the base address
typedef struct {
	unsigned long offset;
	NSString* name;
    BOOL canRead;
    BOOL canWrite;
} SIS3305GammaRegisterInformation;


static SIS3305GammaRegisterInformation register_information[kNumSIS3305ReadRegs] = {
	{0x00000,  @"Control/Status", YES, YES},
    {0x00004,  @"Module Id. and Firmware Revision", YES, NO},
	{0x00008,  @"Interrupt configuration", YES, YES},
	{0x0000C,  @"Interrupt control", YES, YES},
    
    {0x00010,  @"Acquisition control/status", YES, YES},
    {0x00014,  @"Veto Length", YES, YES},
    {0x00018,  @"Veto Delay", YES, YES},
    
    {0x00020,  @"TDC Test Register", YES, YES},
    {0x00014,  @"TDC Test Register", YES, YES},
    {0x00028,  @"EEPROM 93C56 Control", YES, YES},
    {0x0002C,  @"EEPROM DS2430 Onewire Control", YES, YES},
    
	{0x00030,  @"Broadcast Setup register", YES, YES},
    {0x00040,  @"LEMO Trigger Out Select", YES, YES},
    {0x0004C,  @"External Trigger In Counter", YES, NO},
    {0x00050,  @"TDC Write Cmd / TDC Status", YES, YES},
    {0x00054,  @"TDC Read Cmd / TDC Read Value", YES, YES},
    {0x00058,  @"TDC Start/Stop Enable", YES, YES},
    {0x0005C,  @"TDC FSM Reg4 Value" , YES, YES},
    {0x00060,  @"XILINX JTAG_TEST/JTAG_DATA_IN", YES, YES},
    {0x00070,  @"Temperature and Temperature Supervisor", YES, YES},
    {0x00074,  @"ADC Serial Interface (SPI)", YES, YES},

    {0x000C0,  @"ADC1 ch1-ch4 FPGA Data Transfer Control", YES, YES},
    {0x000C4,  @"ADC2 ch5-ch8 FPGA Data Transfer Control", YES, YES},
    {0x000C8,  @"ADC1 ch1-ch4 FPGA Data Transfer Status", YES, NO},
    {0x000CC,  @"ADC2 ch5-ch8 FPGA Data Transfer Status", YES, NO},

    {0x000D0,  @"Aurora Protocol Status", YES, NO},
    {0x000D4,  @"Aurora Data Status", YES, NO},
    {0x000D8,  @"Aurora Data Pending Request Counter Status", YES, NO},
    
    
    // Key address registers
    {0x00400,  @"General Reset", YES, YES},
    {0x00410,  @"Arm Sample Logic", YES, YES},
    {0x00414,  @"Disarm/Disable Sample Logic", YES, YES},
    {0x00418,  @"Trigger", YES, YES},
    {0x0041C,  @"Enable Sample Logic", YES, YES},

    {0x00420,  @"Set Veto", YES, YES},
    {0x00424,  @"Clear Veto", YES, YES},

    {0x00430,  @"ADC Clock Synchronization", YES, YES},
    {0x00434,  @"Reset ADC-FPGA-Logic", YES, YES},

    {0x0043C,  @"Trigger Out pulse", YES, YES},

    
	//group 1
	{0x02000,  @"Event configuration (ADC1 ch1-ch4)", YES, YES},
	{0x02004,  @"Sample Memory Start Address (ADC1 ch1-ch4)", YES, YES},
	{0x02008,  @"Sample/Extended Block Length (ADC1 ch1-ch4)", YES, YES},
	{0x0200C,  @"Direct Memory Pretrigger Block Length register (ADC1 ch1-ch4)", YES, YES},
    
	{0x02010,  @"Ringbuffer Pretrigger Delay (ADC1 ch1-ch2)", YES, YES},
	{0x02014,  @"Ringbuffer Pretrigger Delay (ADC1 ch3-ch4)", YES, YES},
	{0x02018,  @"Direct Memory Max N of Events (ADC1 ch1-ch4)", YES, YES},
	{0x0201C,  @"End Address Threshold", YES, YES},
    
	{0x02020,  @"Trigger/Gate GT Threshold (ADC1 ch1)", YES, YES},
	{0x02024,  @"Trigger/Gate LT Threshold (ADC1 ch1)", YES, YES},
	{0x02028,  @"Trigger/Gate GT Threshold (ADC1 ch2)", YES, YES},
	{0x0202C,  @"Trigger/Gate LT Threshold (ADC1 ch2)", YES, YES},
	{0x02030,  @"Trigger/Gate GT Threshold (ADC1 ch3)", YES, YES},
	{0x02034,  @"Trigger/Gate LT Threshold (ADC1 ch3)", YES, YES},
	{0x02038,  @"Trigger/Gate GT Threshold (ADC1 ch4)", YES, YES},
	{0x0203C,  @"Trigger/Gate LT Threshold (ADC1 ch4)", YES, YES},

    {0x02040,  @"Sampling Status (ADC1 ch1-ch4)", YES, NO},
	{0x02044,  @"Actual Sample Address (ADC1 ch1-ch4)", YES, NO},
	{0x02048,  @"Direct Memory Event Counter (ADC1 ch1-ch4)", YES, NO},
	{0x0204C,  @"Direct Memory Actual Event Start Address (ADC1 ch1-ch4)", YES, NO},
    
	{0x02050,  @"Actual Sample Value (ADC1 ch1-ch2)", YES, NO},
	{0x02054,  @"Actual Sample Value (ADC1 ch3-ch4)", YES, NO},
    
	{0x02058,  @"Aurora Protocol/Data Status (ADC1)", YES, NO},
	{0x0205C,  @"Internal Status (ADC1)", YES, NO},
    
	{0x02060,  @"Aurora Protocol TX Live counter (ADC1)", YES, NO},
    
	{0x02070,  @"Individual Channel Select/Set Veto (ADC1 ch1-ch4)", YES, YES},
 
    {0x02400,  @"Input Tap Delay (ADC1 ch1-ch4)", YES, YES},
	
    
	//group 2
	{0x03000,  @"Event configuration (ADC2 ch5-ch8)", YES, YES},
    {0x03004,  @"Sample Memory Start Address (ADC2 ch5-ch8)", YES, YES},
    {0x03008,  @"Sample/Extended Block Length (ADC2 ch5-ch8)", YES, YES},
    {0x0300C,  @"Direct Memory Pretrigger Block Length register (ADC2 ch5-ch8)", YES, YES},
    
    {0x03010,  @"Ringbuffer Pretrigger Delay (ADC2 ch5-ch6)", YES, YES},
    {0x03014,  @"Ringbuffer Pretrigger Delay (ADC2 ch7-ch8)", YES, YES},
    {0x03018,  @"Direct Memory Max N of Events (ADC2 ch5-ch8)", YES, YES},
    {0x0301C,  @"End Address Threshold", YES, YES},
    
    {0x03020,  @"Trigger/Gate GT Threshold (ADC2 ch5)", YES, YES},
    {0x03024,  @"Trigger/Gate LT Threshold (ADC2 ch5)", YES, YES},
    {0x03028,  @"Trigger/Gate GT Threshold (ADC2 ch6)", YES, YES},
    {0x0302C,  @"Trigger/Gate LT Threshold (ADC2 ch6)", YES, YES},
    {0x03030,  @"Trigger/Gate GT Threshold (ADC2 ch7)", YES, YES},
    {0x03034,  @"Trigger/Gate LT Threshold (ADC2 ch7)", YES, YES},
    {0x03038,  @"Trigger/Gate GT Threshold (ADC2 ch8)", YES, YES},
    {0x0303C,  @"Trigger/Gate LT Threshold (ADC2 ch8)", YES, YES},
    
    {0x03040,  @"Sampling Status (ADC2 ch5-ch8)", YES, NO},
    {0x03044,  @"Next Sample Address (ADC2 ch5-ch8)", YES, NO},
    {0x03048,  @"Direct Memory Event Counter (ADC2 ch5-ch8)",YES, NO},
    {0x0304C,  @"Direct Memory Actual Event Start Address (ADC2 ch5-ch8)", YES, NO},
    
    {0x03050,  @"Actual Sample Value (ADC2 ch5-ch6)", YES, NO},
    {0x03054,  @"Actual Sample Value (ADC2 ch7-ch8)", YES, NO},
    
    {0x03058,  @"Aurora Protocol/Data Status (ADC2)", YES, NO},
    {0x0305C,  @"Internal Status (ADC2)", YES, NO},
    
    {0x03060,  @"Aurora Protocol TX Live counter (ADC2)", YES, NO},
    
    {0x03070,  @"Individual Channel Select/Set Veto (ADC2 ch5-ch8)", YES, YES},
    
    {0x03400,  @"Input Tap Delay (ADC2 ch5-ch8)", YES, YES},
    
    {kSIS3305Space1ADCDataFIFOCh14, @"ADC1 Ch1-4 Memory Data FIFO (space 1)",YES, NO},
    {kSIS3305Space1ADCDataFIFOCh58, @"ADC2 Ch5-8 Memory Data FIFO (space 1)",YES, NO},
    {kSIS3305Space2ADCDataFIFOCh14, @"ADC1 Ch1-4 Memory Data FIFO (space 2)",YES, NO},
    {kSIS3305Space2ADCDataFIFOCh58, @"ADC2 Ch5-8 Memory Data FIFO (space 2)",YES, NO},
};

#pragma mark - Initialization
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setAddressModifier:0x09];
    [self setBaseAddress:0x41000000];
    [self initParams];
	
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc 
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	[gateLengths release];
	[pulseLengths release];
    
    [internalTriggerDelays release];
	[endAddressThresholds release];
 	[thresholds release];
	
    [dacOffsets release];
	[sampleLengths release];
    [sampleStartIndexes release];
    [triggerGateLengths release];

	
	[waveFormRateGroup release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SIS3305Card"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORSIS3305Controller"];
}

- (NSString*) helpURL
{
	return @"VME/SIS3305_(Gamma).html";
}

- (NSRange)	memoryFootprint
{
    return NSMakeRange(baseAddress, 0x0FFFFFF); //0x00780000 + (8*0x1024*0x1024));
}

#pragma mark - Accessors



#pragma mark -- Board Settings

- (int) clockSource
{
    return clockSource;
}

- (void) setClockSource:(int)aClockSource
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClockSource:clockSource];
    clockSource = [self limitIntValue:aClockSource min:0 max:1];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ClockSourceChanged object:self];
}


- (BOOL) TDCMeasurementEnabled {
    return TDCMeasurementEnabled;
}

- (void) setTDCMeasurementEnabled: (BOOL)aState {
    
    [[[self undoManager] prepareWithInvocationTarget:self] setTDCMeasurementEnabled:TDCMeasurementEnabled];
    
    TDCMeasurementEnabled = aState;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305TDCMeasurementEnabledChanged object:self];
}

- (float) firmwareVersion
{
    return firmwareVersion;
}

- (void) setFirmwareVersion:(float)aFirmwareVersion
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFirmwareVersion:firmwareVersion];
    
    firmwareVersion = aFirmwareVersion;
    if(firmwareVersion >= 15.0  && runMode == kMcaRunMode)[self setRunMode:kEnergyRunMode];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelFirmwareVersionChanged object:self];
}


- (BOOL) shipTimeRecordAlso
{
    return shipTimeRecordAlso;
}

- (void) setShipTimeRecordAlso:(BOOL)aShipTimeRecordAlso
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipTimeRecordAlso:shipTimeRecordAlso];
    
    shipTimeRecordAlso = aShipTimeRecordAlso;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelShipTimeRecordAlsoChanged object:self];
}


- (BOOL) writeGainPhaseOffsetEnabled
{
    return writeGainPhaseOffset;
}
- (void) setWriteGainPhaseOffsetEnabled:(BOOL)value
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteGainPhaseOffsetEnabled:writeGainPhaseOffset];
    writeGainPhaseOffset = value;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305WriteGainPhaseOffsetChanged object:self];
}

#pragma mark -- Board Status

- (float) temperature
{
    return temperature;
}

- (void) setTemperature:(float)temp
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTemperature:temperature];
    temperature = temp;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305TemperatureChanged object:self];
}

- (float) getTemperature
{
    unsigned long value = [self readTemperature:NO];
    float temp = tempRawToC(value&0x3FF);
    
    return temp;
}



- (void) probeBoard
{
    [self readModuleID:YES];
    [self readTemperature:NO];
}

#pragma mark -- register r/w accessors
- (short) registerIndex
{
    return registerIndex;
}

- (void) setRegisterIndex:(int)aRegisterIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRegisterIndex:registerIndex];
    registerIndex = aRegisterIndex;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelRegisterIndexChanged object:self];
}

- (unsigned long) registerWriteValue
{
    return registerWriteValue;
}

- (void) setRegisterWriteValue:(unsigned long)aWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRegisterWriteValue:registerWriteValue];
    registerWriteValue = aWriteValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelRegisterWriteValueChanged object:self];
}

- (NSString*) registerNameAt:(unsigned int)index
{
    if (index >= kNumSIS3305ReadRegs) return @"";
    return register_information[index].name;
}

- (unsigned short) registerOffsetAt:(unsigned int)index
{
    if (index >= kNumSIS3305ReadRegs) return 0;
    return register_information[index].offset;
}


#pragma mark -- Event config Accessors

// **********
// Event saving mode bits
// bit 2:0 of event config
// **********
- (short) eventSavingMode:(short)aGroup{    return eventSavingMode[aGroup]; }

- (void) setEventSavingModeOf:(short)aGroup toValue:(short)aMode
{
    // event saving mode gives 3 bits which are eventually written to the event config reg
    [[[self undoManager] prepareWithInvocationTarget:self] setEventSavingModeOf:aGroup toValue:[self eventSavingMode:aGroup]];
    
    eventSavingMode[aGroup] = [self limitIntValue:aMode min:0 max:7];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305EventSavingModeChanged object:self];
}

// **********
// bit 3 of event config unused
// **********


// **********
// ADC Gate mode bit
// bit 4 of event config
// **********
- (BOOL) ADCGateModeEnabled:(unsigned short)group
{
    return ADCGateModeEnabled[group];
}

- (void) setADCGateModeEnabled:(unsigned short)group toValue:(BOOL)value
{
    [[[self undoManager] prepareWithInvocationTarget:self] setADCGateModeEnabled:group toValue:[self ADCGateModeEnabled:group]];
    
    ADCGateModeEnabled[group] = value;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ADCGateModeEnabledChanged object:self];
}



// **********
// Global trigger enable bit
// bit 5 of event config
// **********
- (BOOL) globalTriggerEnabledOnGroup:(unsigned short)group
{
    return globalTriggerEnabled[group];
}

- (void) setGlobalTriggerEnabledOnGroup:(unsigned short)group toValue:(BOOL)value
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGlobalTriggerEnabledOnGroup:group toValue:[self globalTriggerEnabledOnGroup:group]];
    
    globalTriggerEnabled[group] = value;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305GlobalTriggerEnabledChanged object:self];
}


// **********
// Internal trigger enabled bit
// bit 6 of event config
// **********
- (BOOL) internalTriggerEnabled:(short)group { return internalTriggerEnabled[group]; }

- (void) setInternalTriggerEnabled:(short)group toValue:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInternalTriggerEnabled:group toValue:internalTriggerEnabled[group]];
    internalTriggerEnabled[group] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305InternalTriggerEnabledChanged object:self];
}

// **********
// bit 7 of event config unused
// **********

// **********
// Start sampling after first external trigger
// bit 8 of event config
// **********
- (BOOL) startEventSamplingWithExtTrigEnabled:(unsigned short)group {return startEventSamplingWithExtTrigEnabled[group]; }

- (void) setStartEventSamplingWithExtTrigEnabled:(unsigned short)group toValue:(BOOL)value
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStartEventSamplingWithExtTrigEnabled:group toValue:startEventSamplingWithExtTrigEnabled[group]];
    startEventSamplingWithExtTrigEnabled[group] = value;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305StartEventSamplingWithExtTrigEnabledChanged object:self];
}


// **********
// Clear timestamp when sampling enabled
// bit 9 of event config
// **********
- (BOOL) clearTimestampWhenSamplingEnabledEnabled:(unsigned short)group {return clearTimestampWhenSamplingEnabledEnabled[group]; }

- (void) setClearTimestampWhenSamplingEnabledEnabled:(unsigned short)group toValue:(BOOL)value
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClearTimestampWhenSamplingEnabledEnabled:group toValue:clearTimestampWhenSamplingEnabledEnabled[group]];
    clearTimestampWhenSamplingEnabledEnabled[group] = value;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ClearTimestampWhenSamplingEnabledEnabledChanged object:self];
}


// **********
// Disable timestamp clear
// bit 10 of event config
// **********
- (BOOL) clearTimestampDisabled:(unsigned short)group {return clearTimestampDisabled[group];}

- (void) setClearTimestampDisabled:(unsigned short)group toValue:(BOOL)value
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClearTimestampDisabled:group toValue:clearTimestampDisabled[group]];
    clearTimestampDisabled[group] = value;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ClearTimestampDisabledChanged object:self];
}


// **********
// Enable Gray code
// bit 12 of event config
// **********
- (BOOL) grayCodeEnabled:(unsigned short)group {return grayCodeEnabled[group];}

- (void) setGrayCodeEnabled:(unsigned short)group toValue:(BOOL) value
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGrayCodeEnabled:group toValue:grayCodeEnabled[group]];
    grayCodeEnabled[group] = value;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305GrayCodeEnabledChanged object:self];
    
}


// **********
// Disable direct memory header
// bit 16 of event config
// **********
- (BOOL) directMemoryHeaderDisabled:(unsigned short)group {return directMemoryHeaderDisabled[group];}

- (void) setDirectMemoryHeaderDisabled:(unsigned short)group toValue:(BOOL)value
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDirectMemoryHeaderDisabled:group toValue:directMemoryHeaderDisabled[group]];
    directMemoryHeaderDisabled[group] = value;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305DirectMemoryHeaderDisabledChanged object:self];
}


// **********
// "Enable Direct Memory Stop Arm for Trigger adter PreTriggerDelay" bit
// forces you to wait the length of the pretrig delay time before arming the sample logic in wrap mode
// bit 18 of event config
// **********

- (BOOL) waitPreTrigTimeBeforeDirectMemTrig:(unsigned short)group {return waitPreTrigTimeBeforeDirectMemTrig[group];}

- (void) setWaitPreTrigTimeBeforeDirectMemTrig:(unsigned short)group toValue:(BOOL)value
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWaitPreTrigTimeBeforeDirectMemTrig:group toValue:waitPreTrigTimeBeforeDirectMemTrig[group]];
    waitPreTrigTimeBeforeDirectMemTrig[group] = value;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305WaitPreTrigTimeBeforeDirectMemTrigChanged object:self];
}


- (unsigned short) channelMode:(unsigned short)group
{
    return channelMode[group];
}

- (void) setChannelMode:(unsigned short)group withValue:(unsigned short)mode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setChannelMode:group withValue:channelMode[group]];
    channelMode[group] = mode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ChannelModeChanged object:self];
}


- (unsigned short) bandwidth:(unsigned short)group
{
    return bandwidth[group];
}

- (void) setBandwidth:(unsigned short)group withValue:(unsigned short)value
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBandwidth:group withValue:bandwidth[group]];
    bandwidth[group] = value;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305BandwidthChanged object:self];
}

- (unsigned short) testMode:(unsigned short)group
{
    return testMode[group];
}

- (void) setTestMode:(unsigned short)group withValue:(unsigned short)value
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTestMode:group withValue:testMode[group]];
    testMode[group] = value;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305TestModeChanged object:self];
}




// Control status reg things
#pragma mark --- Control Status Reg Accessors


- (void) setLedApplicationMode:(BOOL)mode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLedApplicationMode:ledApplicationMode];
    ledApplicationMode = mode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LEDApplicationModeChanged object:self];
}
- (BOOL) ledApplicationMode
{   return ledApplicationMode;}


- (void) setEnableExternalLEMODirectVetoIn:(BOOL)state{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnableExternalLEMODirectVetoIn:enableExternalLEMODirectVetoIn];
    enableExternalLEMODirectVetoIn = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305EnableLemoInputDirectVetoChanged object:self];
}
- (BOOL) enableExternalLEMODirectVetoIn         {return enableExternalLEMODirectVetoIn;}


- (void) setEnableExternalLEMOResetIn:(BOOL)state{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnableExternalLEMOResetIn:enableExternalLEMOResetIn];
    enableExternalLEMOResetIn = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305EnableLemoInputResetChanged object:self];
}
- (BOOL) enableExternalLEMOResetIn              {return enableExternalLEMOResetIn;}


- (void) setEnableExternalLEMOCountIn:(BOOL)state{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnableExternalLEMOCountIn:enableExternalLEMOCountIn];
    enableExternalLEMOCountIn = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305EnableLemoInputCountChanged object:self];
}
- (BOOL) enableExternalLEMOCountIn              {return enableExternalLEMOCountIn;}


- (void) setEnableExternalLEMOTriggerIn:(BOOL)state{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnableExternalLEMOTriggerIn:enableExternalLEMOTriggerIn];
    enableExternalLEMOTriggerIn = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305EnableLemoInputTriggerChanged object:self];
}
- (BOOL) enableExternalLEMOTriggerIn         {return enableExternalLEMOTriggerIn;}


- (void) setInvertExternalLEMODirectVetoIn:(BOOL)state{
    [[[self undoManager] prepareWithInvocationTarget:self] setInvertExternalLEMODirectVetoIn:invertExternalLEMODirectVetoIn];
    invertExternalLEMODirectVetoIn = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305InvertExternalLEMODirectVetoIn object:self];
}
- (BOOL) invertExternalLEMODirectVetoIn         {return invertExternalLEMODirectVetoIn;}


- (void) setEnableExternalLEMOVetoDelayLengthLogic:(BOOL)state{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnableExternalLEMOVetoDelayLengthLogic:enableExternalLEMOVetoDelayLengthLogic];
    enableExternalLEMOVetoDelayLengthLogic = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305EnableExternalLEMOVetoDelayLengthLogic object:self];
}
- (BOOL) enableExternalLEMOVetoDelayLengthLogic     {return enableExternalLEMOVetoDelayLengthLogic;}


- (void) setEdgeSensitiveExternalVetoDelayLengthLogic:(BOOL)state{
    [[[self undoManager] prepareWithInvocationTarget:self] setEdgeSensitiveExternalVetoDelayLengthLogic:edgeSensitiveExternalVetoDelayLengthLogic];
    edgeSensitiveExternalVetoDelayLengthLogic = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305EdgeSensitiveExternalVetoDelayLengthLogic object:self];
}
- (BOOL) edgeSensitiveExternalVetoDelayLengthLogic  {return edgeSensitiveExternalVetoDelayLengthLogic;}


- (void) setInvertExternalVetoInDelayLengthLogic:(BOOL)state{
    [[[self undoManager] prepareWithInvocationTarget:self] setInvertExternalVetoInDelayLengthLogic:invertExternalVetoInDelayLengthLogic];
    invertExternalVetoInDelayLengthLogic = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305InvertExternalVetoInDelayLengthLogic object:self];
}
- (BOOL) invertExternalVetoInDelayLengthLogic       {return invertExternalVetoInDelayLengthLogic;}


- (void) setGateModeExternalVetoInDelayLengthLogic:(BOOL)state{
    [[[self undoManager] prepareWithInvocationTarget:self] setGateModeExternalVetoInDelayLengthLogic:gateModeExternalVetoInDelayLengthLogic];
    gateModeExternalVetoInDelayLengthLogic = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305GateModeExternalVetoInDelayLengthLogic object:self];
}
- (BOOL) gateModeExternalVetoInDelayLengthLogic     {return gateModeExternalVetoInDelayLengthLogic;}


- (void) setEnableMemoryOverrunVeto:(BOOL)state{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnableMemoryOverrunVeto:enableMemoryOverrunVeto];
    enableMemoryOverrunVeto = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305EnableMemoryOverrunVeto object:self];
}
- (BOOL) enableMemoryOverrunVeto    {return enableMemoryOverrunVeto;}


#pragma mark LEMO Trigger Out settings

- (void) setControlLEMOTriggerOut:(BOOL)state{
    [[[self undoManager] prepareWithInvocationTarget:self] setControlLEMOTriggerOut:controlLEMOTriggerOut];
    controlLEMOTriggerOut = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ControlLemoTriggerOut object:self];
}
- (BOOL) controlLEMOTriggerOut      {return controlLEMOTriggerOut;}

/* 
 There are 19 items which can be OR-ed together to determine what is written to the LEMO trigger out
 
 [19]   Memory overrun veto
 [18]   External Veto Length Logic
 [17]   Internal veto (key veto)
 [16]   External Veto
 [15]   Control LEMO trigger out (control reg [15])
 [14]   Key output pulse
 [13]   Sample logic enabled
 [12]   Sample logic armed
 [11]   Trigger in pulser (if sample logic and TDC Measurement logic are enabled)
 [10]   Trigger in pulse (if LEMO IN is enabled)
 [9]    Trigger in (if LEMO IN is enabled)
 [8]    Trigger in (direct)
 [7:0]  Triggering on channel 8:1

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
*/

- (BOOL) lemoOutSelectTrigger:(unsigned short)chan{
    return lemoOutSelectTrigger[chan];
}
- (void) setLemoOutSelectTrigger:(unsigned short)chan toState:(BOOL)state{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoOutSelectTrigger:chan toState:lemoOutSelectTrigger[chan]];
    lemoOutSelectTrigger[chan] = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LemoOutSelectTriggerChanged object:self];
}



- (BOOL) lemoOutSelectTriggerIn{
    return lemoOutSelectTriggerIn;
}
- (void) setLemoOutSelectTriggerIn:(BOOL)state{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoOutSelectTriggerIn:lemoOutSelectTriggerIn];
    lemoOutSelectTriggerIn = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LemoOutSelectTriggerInChanged object:self];
}



- (BOOL) lemoOutSelectTriggerInPulse{
    return lemoOutSelectTriggerInPulse;
}
- (void) setLemoOutSelectTriggerInPulse:(BOOL)state{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoOutSelectTriggerInPulse:lemoOutSelectTriggerInPulse];
    lemoOutSelectTriggerInPulse = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LemoOutSelectTriggerInPulseChanged object:self];
}



- (BOOL) lemoOutSelectTriggerInPulseWithSampleAndTDC{
    return lemoOutSelectTriggerInPulseWithSampleAndTDC;
}
- (void) setLemoOutSelectTriggerInPulseWithSampleAndTDC:(BOOL)state{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoOutSelectTriggerInPulseWithSampleAndTDC:lemoOutSelectTriggerInPulseWithSampleAndTDC];
    lemoOutSelectTriggerInPulseWithSampleAndTDC = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LemoOutSelectTriggerInPulseWithSampleAndTDCChanged object:self];
}

- (BOOL) lemoOutSelectSampleLogicArmed{
    return lemoOutSelectSampleLogicArmed;
}
- (void) setLemoOutSelectSampleLogicArmed:(BOOL)state{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoOutSelectSampleLogicArmed:lemoOutSelectSampleLogicArmed];
    lemoOutSelectSampleLogicArmed = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LemoOutSelectSampleLogicArmedChanged object:self];
}

- (BOOL) lemoOutSelectSampleLogicEnabled{
    return lemoOutSelectSampleLogicEnabled;
}
- (void) setLemoOutSelectSampleLogicEnabled:(BOOL)state{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoOutSelectSampleLogicEnabled:lemoOutSelectSampleLogicEnabled];
    lemoOutSelectSampleLogicEnabled = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LemoOutSelectSampleLogicEnabledChanged object:self];
}

- (BOOL) lemoOutSelectKeyOutputPulse{
    return lemoOutSelectKeyOutputPulse;
}
- (void) setLemoOutSelectKeyOutputPulse:(BOOL)state{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoOutSelectKeyOutputPulse:lemoOutSelectKeyOutputPulse];
    lemoOutSelectKeyOutputPulse = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LemoOutSelectKeyOutputPulseChanged object:self];
}

- (BOOL) lemoOutSelectControlLemoTriggerOut{
    return lemoOutSelectControlLemoTriggerOut;
}
- (void) setLemoOutSelectControlLemoTriggerOut:(BOOL)state{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoOutSelectControlLemoTriggerOut:lemoOutSelectControlLemoTriggerOut];
    lemoOutSelectControlLemoTriggerOut = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LemoOutSelectControlLemoTriggerOutChanged object:self];
}

- (BOOL) lemoOutSelectExternalVeto{
    return lemoOutSelectExternalVeto;
}
- (void) setLemoOutSelectExternalVeto:(BOOL)state{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoOutSelectExternalVeto:lemoOutSelectExternalVeto];
    lemoOutSelectExternalVeto = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LemoOutSelectExternalVetoChanged object:self];
}

- (BOOL) lemoOutSelectInternalKeyVeto{
    return lemoOutSelectInternalKeyVeto;
}
- (void) setLemoOutSelectInternalKeyVeto:(BOOL)state{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoOutSelectInternalKeyVeto:lemoOutSelectInternalKeyVeto];
    lemoOutSelectInternalKeyVeto = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LemoOutSelectInternalKeyVetoChanged object:self];
}

- (BOOL) lemoOutSelectExternalVetoLength{
    return lemoOutSelectExternalVetoLength;
}
- (void) setLemoOutSelectExternalVetoLength:(BOOL)state{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoOutSelectExternalVetoLength:lemoOutSelectExternalVetoLength];
    lemoOutSelectExternalVetoLength = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LemoOutSelectExternalVetoLengthChanged object:self];
}

- (BOOL) lemoOutSelectMemoryOverrunVeto{
    return lemoOutSelectMemoryOverrunVeto;
}
- (void) setLemoOutSelectMemoryOverrunVeto:(BOOL)state{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoOutSelectMemoryOverrunVeto:lemoOutSelectMemoryOverrunVeto];
    lemoOutSelectMemoryOverrunVeto = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LemoOutSelectMemoryOverrunVetoChanged object:self];
}


#pragma mark Group settings



- (short) externalTriggerEnabledMask { return externalTriggerEnabledMask; }



#pragma mark -- Channel settings

- (BOOL) enabled:(short)chan{
//    return enabled[chan];
    bool state = GTThresholdEnabled[chan] || LTThresholdEnabled[chan];
    return state;
    
}

- (void) setEnabled:(short)chan withValue:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabled:chan withValue:enabled[chan]];
    enabled[chan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ChannelEnabledChanged object:self userInfo:userInfo];
}

//- (BOOL) LTThresholdEnabled:(short)aChan;
//- (BOOL) GTThresholdEnabled:(short)aChan;
//- (void) setLTThresholdEnabled:(short)aChan withValue:(BOOL)aValue;
//- (void) setGTThresholdEnabled:(short)aChan withValue:(BOOL)aValue;

- (void) setTapDelay:(short)chan withValue:(short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTapDelay:chan withValue:tapDelay[chan]];
    tapDelay[chan] = aValue;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305TapDelayChanged object:self];
}

- (short) tapDelay:(short)chan
{
    return tapDelay[chan];
}

- (BOOL) LTThresholdEnabled:(short)aChan{
    if (aChan > kNumSIS3305Channels)
        return NO;

    return LTThresholdEnabled[aChan];
}

- (BOOL) GTThresholdEnabled:(short)aChan{
    if (aChan > kNumSIS3305Channels) {
        return NO;
    }
    return GTThresholdEnabled[aChan];}

- (void) setLTThresholdEnabled:(short)aChan withValue:(BOOL)aValue
{
    if (aChan >= kNumSIS3305Channels || aChan < 0) {
        NSLog(@"Invalid channel (%d) to write LT threshold to. \n", aChan);
        return;
    }
    
    [[[self undoManager] prepareWithInvocationTarget:self] setLTThresholdEnabled:aChan withValue:aValue];
    LTThresholdEnabled[aChan] = aValue;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LTThresholdEnabledChanged object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ChannelEnabledChanged object:self];

//    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ThresholdModeChanged object:self];

}

- (void) setGTThresholdEnabled:(short)aChan withValue:(BOOL)aValue
{
    if (aChan >= kNumSIS3305Channels || aChan < 0) {
        NSLog(@"Invalid channel (%d) to write GT threshold to. \n", aChan);
        return;
    }
    [[[self undoManager] prepareWithInvocationTarget:self] setGTThresholdEnabled:aChan withValue:aValue];

    if (aValue<=3 && aValue>=0) {
        GTThresholdEnabled[aChan] = aValue;
    }
    else
        NSLog(@"That wasn't supposed to happen...\n");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305GTThresholdEnabledChanged object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ChannelEnabledChanged object:self];

    
    //    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ThresholdModeChanged object:self];

}




- (int) limitIntValue:(int)aValue min:(int)aMin max:(int)aMax
{
    if(aValue<aMin)return aMin;
    else if(aValue>aMax)return aMax;
    else return aValue;
}

//- (int) threshold:(short)aChan { return [[thresholds objectAtIndex:aChan]intValue]; }


//- (void) setThreshold:(short)aChan withValue:(int)aValue
//{
//    aValue = [self limitIntValue:aValue min:0 max:0x1FFFF];
//    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChan withValue:[self threshold:aChan]];
//    
//    [thresholds replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
//
//    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ThresholdChanged object:self];
//    //ORAdcInfoProviding protocol requirement
//    [self postAdcInfoProvidingValueChanged];
//}


/* 
    A note on the way threshod modes are implemented
    threshold mode (thresholdMode) is a composite of which thresholds are enabled (GT, LT, GT&LT, !(GT||LT) ).
    You may want to set individually which of these is true, or you may just want to set the mode. 
    In order to encode this correctly for saving, thresholdMode is "derived" by
 
 */

- (short) thresholdMode:(short)chan
{
    /*
        0: Disabled
        1: LT
        2: GT
        3: GT AND LT
     */
    
    BOOL gt = [self GTThresholdEnabled:chan];
    BOOL lt = [self LTThresholdEnabled:chan];
    short mode = -1;

    mode = lt + 2*gt;
    
//    if (!gt && !lt)
//        mode = 0;
//    else if (gt && !lt)
//        mode = 1;
//    else if (!gt && lt)
//        mode = 2;
//    else if (gt && lt)
//        mode = 3;
//    else
//        mode = -1;
    
    
//    WARNING: THIS MAY NOT WORK RIGHT YET - SJM
//    if (mode !=thresholdMode[chan]) {
//        [self setThresholdMode:chan withValue:mode];
//    }
    
    return mode;
}

- (void) setThresholdMode:(short)chan withValue:(short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setThresholdMode:chan withValue:[self thresholdMode:chan]];
    
    if (chan >= kNumSIS3305Channels || chan < 0) {
        NSLog(@"Invalid channel (%d) to apply threshold mode to. \n", chan);
        return;
    }
    
    thresholdMode[chan] = aValue;
    switch (aValue) {
        case 0:     // DISABLED
            [self setGTThresholdEnabled:chan withValue:NO];
            [self setLTThresholdEnabled:chan withValue:NO];
            break;
        case 1:     // LT ENABLED
            [self setGTThresholdEnabled:chan withValue:NO];
            [self setLTThresholdEnabled:chan withValue:YES];
            break;
        case 2:     // GT ENABLED
            [self setGTThresholdEnabled:chan withValue:YES];
            [self setLTThresholdEnabled:chan withValue:NO];
            break;
        case 3:     // BOTH ENABLED
            [self setGTThresholdEnabled:chan withValue:YES];
            [self setLTThresholdEnabled:chan withValue:YES];
            break;
        default:    // I make the default case to enable both, but we shouldn't get here -SJM
            [self setGTThresholdEnabled:chan withValue:YES];
            [self setLTThresholdEnabled:chan withValue:YES];
            NSLog(@"Threshold mode was somehow set to %d, please report this error!\n",aValue);
            break;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ThresholdModeChanged object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ChannelEnabledChanged object:self];
    
    //ORAdcInfoProviding protocol requirement ?
    //[self postAdcInfoProvidingValueChanged];
    
}



- (int) LTThresholdOn:(short)aChan { return LTThresholdOn[aChan]; }
- (void) setLTThresholdOn:(short)aChan withValue:(int)aValue
{
    if (aChan >= kNumSIS3305Channels || aChan < 0) {
        NSLog(@"Invalid channel (%d) to write LT threshold On value to. \n", aChan);
        return;
    }
    aValue = [self limitIntValue:aValue min:0 max:0x3FF];
    [[[self undoManager] prepareWithInvocationTarget:self] setLTThresholdOn:aChan withValue:[self LTThresholdOn:aChan]];
    
    LTThresholdOn[aChan] = aValue;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LTThresholdOnChanged object:self];
    //ORAdcInfoProviding protocol requirement
    //[self postAdcInfoProvidingValueChanged];
}

- (int) LTThresholdOff:(short)aChan { return LTThresholdOff[aChan]; }
- (void) setLTThresholdOff:(short)aChan withValue:(int)aValue
{
    if (aChan >= kNumSIS3305Channels || aChan < 0) {
        NSLog(@"Invalid channel (%d) to write LT threshold Off value to. \n", aChan);
        return;
    }
    aValue = [self limitIntValue:aValue min:0 max:0x3FF];
    [[[self undoManager] prepareWithInvocationTarget:self] setLTThresholdOff:aChan withValue:[self LTThresholdOff:aChan]];
    
    LTThresholdOff[aChan] = aValue;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LTThresholdOffChanged object:self];
    //ORAdcInfoProviding protocol requirement
    //[self postAdcInfoProvidingValueChanged];
}

- (int) GTThresholdOn:(short)aChan { return GTThresholdOn[aChan]; }
- (void) setGTThresholdOn:(short)aChan withValue:(int)aValue
{
    if (aChan >= kNumSIS3305Channels || aChan < 0) {
        NSLog(@"Invalid channel (%d) to write GT threshold On value to. \n", aChan);
        return;
    }
    aValue = [self limitIntValue:aValue min:0 max:0x3FF];
    [[[self undoManager] prepareWithInvocationTarget:self] setGTThresholdOn:aChan withValue:[self GTThresholdOn:aChan]];
    
    GTThresholdOn[aChan] = aValue;
//    [GTThresholdOn replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305GTThresholdOnChanged object:self];
    //ORAdcInfoProviding protocol requirement
    //[self postAdcInfoProvidingValueChanged];
}

- (int) GTThresholdOff:(short)aChan { return GTThresholdOff[aChan]; }
- (void) setGTThresholdOff:(short)aChan withValue:(int)aValue
{
    if (aChan >= kNumSIS3305Channels || aChan < 0) {
        NSLog(@"Invalid channel (%d) to write GT threshold Off value to. \n", aChan);
        return;
    }
    aValue = [self limitIntValue:aValue min:0 max:0x3FF];
    [[[self undoManager] prepareWithInvocationTarget:self] setGTThresholdOff:aChan withValue:[self GTThresholdOff:aChan]];
    
    GTThresholdOff[aChan] = aValue;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305GTThresholdOffChanged object:self];
    //ORAdcInfoProviding protocol requirement
    //[self postAdcInfoProvidingValueChanged];
}

//- (int) highThreshold:(short)aChan { return [[highThresholds objectAtIndex:aChan]intValue]; }
//- (void) setHighThreshold:(short)aChan withValue:(int)aValue
//{
//    aValue = [self limitIntValue:aValue min:0 max:0x1FFFF];
//    [[[self undoManager] prepareWithInvocationTarget:self] setHighThreshold:aChan withValue:[self highThreshold:aChan]];
//    [highThresholds replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
//    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305HighThresholdChanged object:self];
//    //ORAdcInfoProviding protocol requirement
//    [self postAdcInfoProvidingValueChanged];
//}

- (unsigned short) gain:(unsigned short) aChan
{
    return 0;   // ERROR: this is not the correct answer -SJM
}
- (void) setGain:(unsigned short) aChan withValue:(unsigned short) aGain
{
}
- (BOOL) partOfEvent:(unsigned short)chan
{
    return NO;  // ERROR: FIX THIS -SJM
//    return (gtMask & (1L<<chan)) != 0;
}

//- (BOOL)onlineMaskBit:(int)bit
//{
//    //translate back to the triggerEnabled Bit
////    return (gtMask & (1L<<bit)) != 0;
//}

- (unsigned long) sampleStartAddress:(unsigned short)group
{
    return sampleStartAddress[group];
}

- (void) setSampleStartAddress:(unsigned short)group toValue:(unsigned long)value
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSampleStartAddress:group toValue:[self sampleStartAddress:group]];
    
    sampleStartAddress[group] = value;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305SampleStartAddressChanged object:self];
}



- (unsigned long) sampleLength:(short)group {
    return [[sampleLengths objectAtIndex:group] unsignedLongValue];
}

- (void) setSampleLength:(short)group withValue:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSampleLength:group withValue:[self sampleLength:group]];

    
    if ([self eventSavingMode:group] <= 4 ) {
        aValue = [self limitIntValue:aValue min:0 max:0xff];
    }
    else if([self eventSavingMode:group] >4){
        aValue = [self limitIntValue:aValue min:0 max:0xffFFFF];
    }
    
//    aValue = (aValue/4)*4;  // FIX: What is this for again?
    
    [sampleLengths replaceObjectAtIndex:group withObject:[NSNumber numberWithInt:aValue]];
//    [self calculateSampleValues];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305SampleLengthChanged object:self];
}

- (unsigned short) dacOffset:(short)aChan { return [[dacOffsets objectAtIndex:aChan]intValue]; }
- (void) setDacOffset:(short)aChan withValue:(int)aValue
{
    aValue = [self limitIntValue:aValue min:0 max:0xffff];
    [[[self undoManager] prepareWithInvocationTarget:self] setDacOffset:aChan withValue:[self dacOffset:aChan]];
    [dacOffsets replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305DacOffsetChanged object:self];
}

- (short) gateLength:(short)aChan { return [[gateLengths objectAtIndex:aChan] shortValue]; }
- (void) setGateLength:(short)aChan withValue:(short)aValue
{
    aValue = [self limitIntValue:aValue min:0 max:0x3f];
    [[[self undoManager] prepareWithInvocationTarget:self] setGateLength:aChan withValue:[self gateLength:aChan]];
    [gateLengths replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305GateLengthChanged object:self];
}

- (short) pulseLength:(short)aChan { return [[pulseLengths objectAtIndex:aChan] shortValue]; }
- (void) setPulseLength:(short)aChan withValue:(short)aValue
{
    aValue = [self limitIntValue:aValue min:0 max:0xff];
    [[[self undoManager] prepareWithInvocationTarget:self] setPulseLength:aChan withValue:[self pulseLength:aChan]];
    [pulseLengths replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305PulseLengthChanged object:self];
}


- (short) internalTriggerDelay:(short)aChan { return [[internalTriggerDelays objectAtIndex:aChan] shortValue]; }
- (void) setInternalTriggerDelay:(short)aChan withValue:(short)aValue
{
    if (aChan >= [internalTriggerDelays count]) {
        NSLog(@"Internal trigger delay is too large\n");
        return;
    }
    aValue = [self limitIntValue:aValue min:0 max:firmwareVersion<15?63:255];
    [[[self undoManager] prepareWithInvocationTarget:self] setInternalTriggerDelay:aChan withValue:[self internalTriggerDelay:aChan]];
    
    @try{
    [internalTriggerDelays replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305InternalTriggerDelayChanged object:self];
    }
    @catch(NSException* localException){
        [localException raise];
        NSLog(@"Failed to set Internal Trigger Delay\n");
    }
    
    //force a constraint check by reloading the pretrigger delay
//    [self setPreTriggerDelay:aChan/2 withValue:[self preTriggerDelay:aChan/2]];
}


- (unsigned long) adcOffset:(unsigned short)chan{
    return adcOffset[chan];
}

- (void) setAdcOffset:(unsigned short)chan toValue:(unsigned long)value
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAdcOffset:chan toValue:adcOffset[chan]];
    
    if(value>0x3FF)
        value = 0x3ff;
    
    adcOffset[chan] = value;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305AdcOffsetChanged object:self];

}

- (unsigned long) adcGain:(unsigned short)chan{
    return adcGain[chan];
}

- (void) setAdcGain:(unsigned short)chan toValue:(unsigned long)value
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAdcGain:chan toValue:adcGain[chan]];
    
    if(value>0x3FF)
        value = 0x3ff;

    adcGain[chan] = value;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305AdcGainChanged object:self];
    
}

- (unsigned long) adcPhase:(unsigned short)chan{
    return adcPhase[chan];
}

- (void) setAdcPhase:(unsigned short)chan toValue:(unsigned long)value
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAdcPhase:chan toValue:adcPhase[chan]];
    
    if(value>0x3FF)
        value = 0x3ff;
    
    adcPhase[chan] = value;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305AdcPhaseChanged object:self];
    
}


#pragma mark -- Unsorted 
- (BOOL) pulseMode
{
    return pulseMode;
}

- (void) setPulseMode:(BOOL)aPulseMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPulseMode:pulseMode];
    
    pulseMode = aPulseMode;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelPulseModeChanged object:self];
}


- (BOOL) internalExternalTriggersOred {
    return internalExternalTriggersOred;
}

- (void) setInternalExternalTriggersOred:(BOOL)aInternalExternalTriggersOred
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInternalExternalTriggersOred:internalExternalTriggersOred];
    internalExternalTriggersOred = aInternalExternalTriggersOred;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelInternalExternalTriggersOredChanged object:self];
}

- (unsigned short) lemoInEnabledMask {
    return lemoInEnabledMask;
}

- (void) setLemoInEnabledMask:(unsigned short)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoInEnabledMask:lemoInEnabledMask];
    lemoInEnabledMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelLemoInEnabledMaskChanged object:self];
}

- (BOOL) lemoInEnabled:(unsigned short)aBit {
    return lemoInEnabledMask & (1<<aBit);
}

- (void) setLemoInEnabled:(unsigned short)aBit withValue:(BOOL)aState
{
	unsigned short aMask = [self lemoInEnabledMask];
	if(aState)	aMask |= (1<<aBit);
	else		aMask &= ~(1<<aBit);
	[self setLemoInEnabledMask:aMask];
}

- (int) runMode {
    return runMode;
}

- (void) setRunMode:(int)aRunMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRunMode:runMode];
    runMode = aRunMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelRunModeChanged object:self];
//	[self calculateSampleValues];
}

- (int) triggerGateLength:(short)aGroup 
{
	if(aGroup>kNumSIS3305Groups)return 0;
	return [[triggerGateLengths objectAtIndex:aGroup] intValue]; 
}
- (void) setTriggerGateLength:(short)aGroup withValue:(int)aTriggerGateLength
{
    
    //FIX: THIS isn't currently used, I don't think
    
    
	if(aGroup>kNumSIS3305Groups)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerGateLength:aGroup withValue:[self triggerGateLength:aGroup]];
	if (aTriggerGateLength < [self sampleLength:aGroup]) aTriggerGateLength = [self sampleLength:aGroup];
    int triggerGateLength = [self limitIntValue:aTriggerGateLength min:0 max:65535];
	[triggerGateLengths replaceObjectAtIndex:aGroup withObject:[NSNumber numberWithInt:triggerGateLength]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelTriggerGateLengthChanged object:self];
}

- (int) preTriggerDelay:(short)aChannel
{
 //   if(aChannel>kNumSIS3305Channels)return 0; //FIX: set this up to use the array, or change the other bits to use this object
//    int value  = [[preTriggerDelays objectAtIndex:aChannel] intValue];
    
    return ringbufferPreDelay[aChannel];
    
 //   return value;
}

- (void) setPreTriggerDelay:(short)aChannel withValue:(int)aPreTriggerDelay
{
	if(aChannel>kNumSIS3305Channels)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setPreTriggerDelay:aChannel withValue:[self preTriggerDelay:aChannel]];
    int preTriggerDelay = [self limitIntValue:aPreTriggerDelay min:1 max:1023];
	
//    short maxInternalTrigDelay = [[internalTriggerDelays valueForKeyPath:@"@max.self"] intValue];//MAX([self internalTriggerDelay:aChannel*2],[self internalTriggerDelay:aChannel*2+1]);
//	short decimation = powf(2.,(float)[self triggerDecimation:aChannel]);
//	if(preTriggerDelay< (decimation + maxInternalTrigDelay)){
//		preTriggerDelay = decimation + maxInternalTrigDelay;
//		NSLogColor([NSColor redColor], @"SIS3305: Increased the pretrigger delay (channel %d) to be >= decimation+triggerDelay\n",aChannel);
//	}
//	[preTriggerDelays replaceObjectAtIndex:aChannel withObject:[NSNumber numberWithInt:preTriggerDelay]];
    
    ringbufferPreDelay[aChannel] = preTriggerDelay;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelPreTriggerDelayChanged object:self];
}

- (int) sampleStartIndex:(int)aGroup 
{ 
	if(aGroup>=kNumSIS3305Groups)return 0;
	return [[sampleStartIndexes objectAtIndex:aGroup] intValue];
}
- (void) setSampleStartIndex:(int)aGroup withValue:(unsigned short)aSampleStartIndex
{
	if(aGroup>=kNumSIS3305Groups)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setSampleStartIndex:aGroup withValue:[self sampleStartIndex:aGroup]];
    int sampleStartIndex = aSampleStartIndex & 0xfffe;
	[sampleStartIndexes replaceObjectAtIndex:aGroup withObject:[NSNumber numberWithInt:sampleStartIndex]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305SampleStartIndexChanged object:self];
}

- (short) lemoInMode { return lemoInMode; }
- (void) setLemoInMode:(short)aLemoInMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoInMode:lemoInMode];
    lemoInMode = aLemoInMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LemoInModeChanged object:self];
}

- (NSString*) lemoInAssignments
{
	if(runMode == kEnergyRunMode){
		if(lemoInMode == 0)      return @"3:Trigger\n2:TimeStamp Clr\n1:Veto";
		else if(lemoInMode == 1) return @"3:Trigger\n2:TimeStamp Clr\n1:Gate";
		else if(lemoInMode == 2) return @"3:Reserved\n2:Reserved\n1:Reserved";
		else if(lemoInMode == 3) return @"3:Reserved\n2:Reserved\n1:Reserved";
		else if(lemoInMode == 4) return @"3:N+1 Trig/Gate In\n2:Trigger\n1:N-1 Trig/Gate In";
		else if(lemoInMode == 5) return @"3:N+1 Trig/Gate In\n2:TimeStamp Clr\n1:N-1 Trig/Gate In";
		else if(lemoInMode == 6) return @"3:N+1 Trig/Gate In\n2:Veto\n1:N-1 Trig/Gate In";
		else if(lemoInMode == 7) return @"3:N+1 Trig/Gate In\n2:Gate\n1:N-1 Trig/Gate In";
		else return @"Undefined";
	} 
	else {
		if(lemoInMode == 0)      return @"3:Reserved\n2:Ext MCA Start\n1:Ext Next Pulse";
		else if(lemoInMode == 1) return @"3:Trigger\n2:Ext MCA Start\n1:Ext Next Pulse";
		else if(lemoInMode == 2) return @"3:Veto\n2:Ext MCA Start\n1:Ext Next Pulse";
		else if(lemoInMode == 3) return @"3:Gate\n2:Ext MCA Start\n1:Ext Next Pulse";
		else if(lemoInMode == 4) return @"3:Reserved\n2:Reserved\n1:Reserved";
		else if(lemoInMode == 5) return @"3:Reserved\n2:Reserved\n1:Reserved";
		else if(lemoInMode == 6) return @"3:Reserved\n2:Reserved\n1:Reserved";
		else if(lemoInMode == 7) return @"3:Reserved\n2:Reserved\n1:Reserved";
		else return @"Undefined";
	}
}

- (short) lemoOutMode { return lemoOutMode; }
- (void) setLemoOutMode:(short)aLemoOutMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoOutMode:lemoOutMode];
    lemoOutMode = aLemoOutMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LemoOutModeChanged object:self];
}
- (NSString*) lemoOutAssignments
{
	if(runMode == kEnergyRunMode){
		if(lemoOutMode == 0)      return @"3:Sample logic armed\n2:Busy\n1:Trigger output";
		else if(lemoOutMode == 1) return @"3:Sample logic armed\n2:Busy or Veto\n1:Trigger output";
		else if(lemoOutMode == 2) return @"3:N+1 Trig/Gate Out\n2:Trigger output\n1:N-1 Trig/Gate Out";
		else if(lemoOutMode == 3) return @"3:N+1 Trig/Gate Out\n2:Busy or Veto\n1:N-1 Trig/Gate Out";
		else return @"Undefined";
	} 
	else {
		if(lemoOutMode == 0)      return @"3:Sample logic armed\n2:Busy\n1:Trigger output";
		else if(lemoOutMode == 1) return @"3:First Scan Signal\n2:LNE\n1:Scan Enable";
		else if(lemoOutMode == 2) return @"3:Scan Enable\n2:LNE\n1:Trigger Output";
		else if(lemoOutMode == 3) return @"3:Reserved\n2:Reserved\n1:Reserved";
		else return @"Undefined";
	}
}

- (void) setDefaults
{
	[self setRunMode:kEnergyRunMode];
	int i;
	for(i=0;i<kNumSIS3305Channels;i++){
//		[self setThreshold:i withValue:0x64];
//		[self setHighThreshold:i withValue:0x0];
//        [self setEnabled:i withValue:YES];
		[self setInternalTriggerDelay:i withValue:0];
		[self setDacOffset:i withValue:30000];
        [self setPreTriggerDelay:i withValue:1];
        [self setLTThresholdEnabled:i withValue:YES];
        [self setGTThresholdEnabled:i withValue:YES];
        [self setLTThresholdOff:i withValue:1023];
        [self setLTThresholdOn:i withValue:1023];
        [self setGTThresholdOff:i withValue:1023];
        [self setGTThresholdOn:i withValue:1023];
        [self setTapDelay:i withValue:0];

        [self setPreTriggerDelay:i withValue:0];
        [self setGateLength:i withValue:64];
        [self setGain:i withValue:1];
        [self setLemoOutSelectTrigger:i toState:YES];
        
        [self setAdcGain:i toValue:0x200];
        [self setAdcOffset:i toValue:0x200];
        [self setAdcPhase:i toValue:0x200];

	}
	for(i=0;i<kNumSIS3305Groups;i++){
		[self setSampleLength:i withValue:2048];
		[self setTriggerGateLength:i withValue:2048];
		[self setSampleStartIndex:i withValue:0];
        [self setSampleStartAddress:i toValue:0];
        
        [self setInternalTriggerEnabled:i toValue:YES];
        [self setGlobalTriggerEnabledOnGroup:i toValue:NO];
        [self setClearTimestampDisabled:i toValue:NO];
        [self setClearTimestampWhenSamplingEnabledEnabled:i toValue:YES];
        [self setGrayCodeEnabled:i toValue:NO];
        [self setDirectMemoryHeaderDisabled:i toValue:NO];
        [self setADCGateModeEnabled:i toValue:NO];
        [self setWaitPreTrigTimeBeforeDirectMemTrig:i toValue:YES];
        
        [self setEventSavingModeOf:i toValue:4];
        [self setChannelMode:i withValue:0];
        
        [self setBandwidth:i withValue:1];
        [self setTestMode:i withValue:0];
    }
    
    [self setWriteGainPhaseOffsetEnabled:NO];

	[self setTriggerOutEnabledMask:0x0];
	[self setInputInvertedMask:0x0];
	[self setInternalGateEnabledMask:0xff];
	[self setExternalGateEnabledMask:0x00];
    [self setTDCMeasurementEnabled:NO];
    
    [self setLedApplicationMode:YES];
    [self setEnableExternalLEMODirectVetoIn:NO];
    [self setEnableExternalLEMOResetIn:NO];
    [self setEnableExternalLEMOCountIn:NO];
    [self setEnableExternalLEMOTriggerIn:NO];
    [self setInvertExternalLEMODirectVetoIn:NO];
    [self setEnableExternalLEMOVetoDelayLengthLogic:NO];
    [self setEdgeSensitiveExternalVetoDelayLengthLogic:NO];
    [self setInvertExternalVetoInDelayLengthLogic:NO];
    [self setGateModeExternalVetoInDelayLengthLogic:NO];
    [self setEnableMemoryOverrunVeto:YES];
    [self setControlLEMOTriggerOut:YES];
    
    [self setLemoOutSelectTriggerIn:YES];
    
    [self setLemoOutSelectTriggerInPulse:NO];
    [self setLemoOutSelectTriggerInPulseWithSampleAndTDC:NO];
    [self setLemoOutSelectSampleLogicArmed:YES];
    [self setLemoOutSelectSampleLogicEnabled:YES];
    [self setLemoOutSelectKeyOutputPulse:YES];
    [self setLemoOutSelectControlLemoTriggerOut:NO];
    [self setLemoOutSelectExternalVeto:NO];
    [self setLemoOutSelectInternalKeyVeto:NO];
    [self setLemoOutSelectExternalVetoLength:NO];
    [self setLemoOutSelectMemoryOverrunVeto:NO];
    
     
	[self setBufferWrapEnabledMask:0x0];
	[self setExternalTriggerEnabledMask:0x0];
	
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
	 postNotificationName:ORSIS3305RateGroupChangedNotification
	 object:self];    
}

- (id) rateObject:(int)channel
{
    return [waveFormRateGroup rateObject:channel];
}

- (void) initParams
{
	[self setUpArrays];
	[self setDefaults];
}

- (void) setRateIntegrationTime:(double)newIntegrationTime
{
	//we this here so we have undo/redo on the rate object.
    [[[self undoManager] prepareWithInvocationTarget:self] setRateIntegrationTime:[waveFormRateGroup integrationTime]];
    [waveFormRateGroup setIntegrationTime:newIntegrationTime];
}

- (unsigned long) getCounter:(int)counterTag forGroup:(int)groupTag
{
	if(groupTag == 0){
		if(counterTag>=0 && counterTag<kNumSIS3305Channels){
			return waveFormCount[counterTag];
		}	
		else return 0;
	}
	else return 0;
}

- (short) bufferWrapEnabledMask { return bufferWrapEnabledMask; }
- (void) setBufferWrapEnabledMask:(short)aMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setBufferWrapEnabledMask:bufferWrapEnabledMask];
	bufferWrapEnabledMask = aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelBufferWrapEnabledChanged object:self];
}

- (BOOL) bufferWrapEnabled:(short)group 
{ 
	if(group>=0 && group<kNumSIS3305Groups) return bufferWrapEnabledMask & (1<<group); 
	else return NO;
}
- (void) setBufferWrapEnabled:(short)group withValue:(BOOL)aValue
{
	if(group>=0 && group<kNumSIS3305Groups){
		unsigned char aMask = bufferWrapEnabledMask;
		if(aValue)aMask |= (1<<group);
		else aMask &= ~(1<<group);
		[self setBufferWrapEnabledMask:aMask];
	}
}


- (void) setExternalTriggerEnabledMask:(short)aMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setExternalTriggerEnabledMask:externalTriggerEnabledMask];
	externalTriggerEnabledMask = aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ExternalTriggerEnabledChanged object:self];
}

- (BOOL) externalTriggerEnabled:(short)chan { return externalTriggerEnabledMask & (1<<chan); }
- (void) setExternalTriggerEnabled:(short)chan withValue:(BOOL)aValue
{
	unsigned char aMask = externalTriggerEnabledMask;
	if(aValue)aMask |= (1<<chan);
	else aMask &= ~(1<<chan);
	[self setExternalTriggerEnabledMask:aMask];
}

- (short) internalGateEnabledMask { return internalGateEnabledMask; }
- (void) setInternalGateEnabledMask:(short)aMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setInternalGateEnabledMask:internalGateEnabledMask];
	internalGateEnabledMask = aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305InternalGateEnabledChanged object:self];
}

- (BOOL) internalGateEnabled:(short)chan { return internalGateEnabledMask & (1<<chan); }
- (void) setInternalGateEnabled:(short)chan withValue:(BOOL)aValue
{
	unsigned char aMask = internalGateEnabledMask;
	if(aValue)aMask |= (1<<chan);
	else aMask &= ~(1<<chan);
	[self setInternalGateEnabledMask:aMask];
}

- (short) externalGateEnabledMask { return externalGateEnabledMask; }
- (void) setExternalGateEnabledMask:(short)aMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setExternalGateEnabledMask:externalGateEnabledMask];
	externalGateEnabledMask = aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ExternalGateEnabledChanged object:self];
}

- (BOOL) externalGateEnabled:(short)chan { return externalGateEnabledMask & (1<<chan); }
- (void) setExternalGateEnabled:(short)chan withValue:(BOOL)aValue
{
	unsigned char aMask = externalGateEnabledMask;
	if(aValue)aMask |= (1<<chan);
	else aMask &= ~(1<<chan);
	[self setExternalGateEnabledMask:aMask];
}


- (short) inputInvertedMask { return inputInvertedMask; }
- (void) setInputInvertedMask:(short)aMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setInputInvertedMask:inputInvertedMask];
	inputInvertedMask = aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305InputInvertedChanged object:self];
}

- (BOOL) inputInverted:(short)chan { return inputInvertedMask & (1<<chan); }
- (void) setInputInverted:(short)chan withValue:(BOOL)aValue
{
	unsigned char aMask = inputInvertedMask;
	if(aValue)aMask |= (1<<chan);
	else aMask &= ~(1<<chan);
	[self setInputInvertedMask:aMask];
}

- (short) triggerOutEnabledMask { return triggerOutEnabledMask; }
- (void) setTriggerOutEnabledMask:(short)aMask	
{ 
	[[[self undoManager] prepareWithInvocationTarget:self] setTriggerOutEnabledMask:triggerOutEnabledMask];
	triggerOutEnabledMask = aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305TriggerOutEnabledChanged object:self];
}

- (BOOL) triggerOutEnabled:(short)chan { return triggerOutEnabledMask & (1<<chan); }
- (void) setTriggerOutEnabled:(short)chan withValue:(BOOL)aValue		
{ 
	unsigned char aMask = triggerOutEnabledMask;
	if(aValue)aMask |= (1<<chan);
	else aMask &= ~(1<<chan);
	[self setTriggerOutEnabledMask:aMask];
}



//- (short) cfdControl:(short)aChannel 
//{ 
//	if(aChannel>=kNumSIS3305Channels)return 0;
//	return [[cfdControls objectAtIndex:aChannel] intValue]; 
//}
//- (void) setCfdControl:(short)aChannel withValue:(short)aValue 
//{ 
// 	if(aChannel>=kNumSIS3305Channels)return;
//	[[[self undoManager] prepareWithInvocationTarget:self] setCfdControl:aChannel withValue:[self cfdControl:aChannel]];
//    int cfd = [self limitIntValue:aValue min:0 max:0x3];
//	[cfdControls replaceObjectAtIndex:aChannel withObject:[NSNumber numberWithInt:cfd]];
//	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelCfdControlChanged object:self];
//}
//



- (BOOL) ledEnabled:(unsigned short)ledNum
{
    return ledEnable[ledNum];
}

- (void) setLed:(unsigned short)ledNum to:(BOOL)state
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLed:ledNum to:[self ledEnabled:ledNum]];
    
    ledEnable[ledNum] = state;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LEDEnabledChanged object:self];
   
}

- (unsigned long) endAddressThreshold:(short)aGroup  
{
    /*
        The end address threshold indicates when a group has reached the end od one of its memory banks and has stopped sampling. I have no idea why you should ever write to it.
        The value of "actual next sample" should be compared with this
     */
    
	if(aGroup>=kNumSIS3305Groups)return 0;
	return [[endAddressThresholds objectAtIndex:aGroup] intValue]; 
}

- (void) setEndAddressThreshold:(short)aGroup withValue:(unsigned long)aValue 
{
	[[[self undoManager] prepareWithInvocationTarget:self] setEndAddressThreshold:aGroup withValue:[self endAddressThreshold:aGroup]];
	[endAddressThresholds replaceObjectAtIndex:aGroup withObject:[NSNumber numberWithInt:aValue]];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelEndAddressThresholdChanged object:self];
}



//- (void) calculateSampleValues
//{
////	if(runMode == kMcaRunMode)   return;
////	else {
//		numEnergyValues = energySampleLength;
//		
//		if(numEnergyValues > kSIS3305MaxEnergyWaveform){
//			// This should never be happen in the current implementation since we 
//			// handle this value internally, but checking nonetheless in case 
//			// in the future we modify this.  
//			NSLogColor([NSColor redColor],@"Number of energy values is to high (max = %d) ; actual = %d \n",
//					   kSIS3305MaxEnergyWaveform, numEnergyValues);
//			NSLogColor([NSColor redColor],@"Value forced to %d\n", kSIS3305MaxEnergyWaveform);
//			numEnergyValues = kSIS3305MaxEnergyWaveform;
//			[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelEnergySampleLengthChanged object:self];
////		}
//		
//		int group;
//		for(group=0;group<kNumSIS3305Groups;group++){
//			numRawDataLongWords = [self sampleLength:group]/2;
//			rawDataIndex  = 2 ;
//			
//			eventLengthLongWords = 2 + 4  ; // Timestamp/Header, MAX, MIN, Trigger-FLags, Trailer
//			if(bufferWrapEnabledMask && firmwareVersion>15)eventLengthLongWords+=2; //1510 added two words to the header 
//			eventLengthLongWords = eventLengthLongWords + numRawDataLongWords  ;  
//			eventLengthLongWords = eventLengthLongWords + numEnergyValues  ;   
//			
//			unsigned long maxEvents = (0x200000 / eventLengthLongWords)/2;
//			//unsigned long maxEvents = 1;
//			[self setEndAddressThreshold:group withValue:maxEvents*eventLengthLongWords];
//			// Check the sample indices
//			// Don't call setEnergy* from in here!  Cause stack overflow...
//			if (numEnergyValues == 0) {
//				// Set all indices to 0
//				energySampleStartIndex1 = 1;
//				energySampleStartIndex2 = 0;
//				energySampleStartIndex3 = 0;
//			} 
//			else if (energySampleStartIndex2 != 0 || energySampleStartIndex3 != 0) {
//				// Means we are requesting different pieces of the waveform.
//				// Make sure they are correct.
//				if (energySampleStartIndex2 < energySampleStartIndex1 + energySampleLength/3 + 1) {
//					int aValue = energySampleLength/3 + energySampleStartIndex1 + 1;
//					energySampleStartIndex2 = aValue;
//					if (energySampleStartIndex3 == 0) {
//						// This forces us to also reset the third index if it is set to 0.
//						energySampleStartIndex3 = 0;
//					}
//				}
//				
//				if (energySampleStartIndex2 == 0 && energySampleStartIndex3 != 0) {
//					energySampleStartIndex3 = 0;
//				} 
//				else if (energySampleStartIndex2 != 0 && 
//						 energySampleStartIndex3 < energySampleStartIndex2 + energySampleLength/3 + 1) {
//					int aValue = energySampleLength/3 + energySampleStartIndex2 + 1;
//					energySampleStartIndex3 = aValue;
//				}
//			}			
//			[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelEnergySampleStartIndex1Changed object:self];
//			[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelEnergySampleStartIndex2Changed object:self];
//			[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelEnergySampleStartIndex3Changed object:self];
//			
//			// Finally check the trigger gate length to make sure it is big enough
//			if ([self triggerGateLength:group] < [self sampleLength:group]) {
//				[self setTriggerGateLength:group withValue:[self sampleLength:group]];
//			}
//		}
//	}
//}





#pragma mark - Hardware Access

#pragma mark Setup for register R/W in dialog

- (unsigned long) readRegister:(unsigned int)index
{
    if (index >= kNumSIS3305ReadRegs) return -1;
    if (![self canReadRegister:index]) return -1;
    unsigned long theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[index].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return theValue;
}

- (void) writeRegister:(unsigned int)index withValue:(unsigned long)value
{
    if (index >= kNumSIS3305ReadRegs) return;
    if (![self canWriteRegister:index]) return;
    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + register_information[index].offset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeToAddress:(unsigned long)anAddress aValue:(unsigned long)aValue
{
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + anAddress
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}

- (unsigned long) readFromAddress:(unsigned long)anAddress
{
    unsigned long value = 0;
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + anAddress
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return value;
}

- (BOOL) canReadRegister:(unsigned int)index
{
    if (index >= kNumSIS3305ReadRegs) return NO;
    return register_information[index].canRead;
}

- (BOOL) canWriteRegister:(unsigned int)index
{
    if (index >= kNumSIS3305ReadRegs) return NO;
    return register_information[index].canWrite;
}



#pragma mark Control Status Register(s)

- (void) writeControlStatus
{
    /*
     The CSRMask puts a negative as a positive in the top 16 of the word,
     or keeps a positive in the bottom 16.
     */
    unsigned long value = 0;
    
    value |= CSRMask([self ledApplicationMode],                         3);
    value |= CSRMask([self enableExternalLEMODirectVetoIn],             4);
    value |= CSRMask([self enableExternalLEMOResetIn],                  5);
    value |= CSRMask([self enableExternalLEMOCountIn],                  6);
    value |= CSRMask([self enableExternalLEMOTriggerIn],                7);
    value |= CSRMask([self invertExternalLEMODirectVetoIn],             8);
    value |= CSRMask([self enableExternalLEMOVetoDelayLengthLogic],     9);
    value |= CSRMask([self edgeSensitiveExternalVetoDelayLengthLogic],  10);
    value |= CSRMask([self invertExternalVetoInDelayLengthLogic],       11);
    value |= CSRMask([self gateModeExternalVetoInDelayLengthLogic],     12);
    value |= CSRMask([self enableMemoryOverrunVeto],                    13);
    // no 14
    value |= CSRMask([self controlLEMOTriggerOut],                      15);
    
    
    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + kSIS3305ControlStatus
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}


- (void) writeLed1:(BOOL)state
{
    state = state << 0;
    unsigned long aValue = CSRMask(state,kSISLed1);
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3305ControlStatus
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeLed:(short)ledNum to:(BOOL)state
{
    unsigned long addr = 0;
    unsigned long value = 0;
    
    switch (ledNum) {
        case 1:
            addr = kSISLed1;
            break;
        case 2:
            addr = kSISLed2;
            break;
        case 3:
            addr = kSISLed3;
            break;
        default:
            NSLog(@"SIS3305: Invalid LED number");
            addr = 0;
            break;
    }
    
    value = CSRMask(state,addr);
    
    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + kSIS3305ControlStatus
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeLedApplicationMode
{
    // in control/status reg (0x0), sets the LED Application Mode
    //      0: Full user control of LEDs
    //      1: Mostly board defined (probably more useful for now, and set to default)
    //          U1 - full user control
    //          U2 - indicates data sampling
    //          U3 - indicates that data sampling logic is enabled
    
    BOOL state = ledApplicationMode;
    unsigned long aValue = CSRMask(state,0x8);     // NEED to check if this makes sense and works...
    
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3305ControlStatus
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}


#pragma mark -- More regs


- (void) readModuleID:(BOOL)verbose
{	
	unsigned long result = 0;
	[[self adapter] readLongBlock:&result
						atAddress:[self baseAddress] + kSIS3305ModID
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	unsigned long moduleID = result >> 16;
	unsigned short majorRev = (result >> 8) & 0xff;
	unsigned short minorRev = result & 0xff;
	NSString* s = [NSString stringWithFormat:@"%x.%x",majorRev,minorRev];
	[self setFirmwareVersion:[s floatValue]];
	if(verbose){
		NSLog(@"SIS3305 ID: %x  Firmware:%.2f\n",moduleID,firmwareVersion);
		if(moduleID != 0x3305)NSLogColor([NSColor redColor], @"Warning: HW mismatch. 3305 object is 0x%x HW\n",moduleID);
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305IDChanged object:self];
}

- (unsigned long) readInterruptConfig:(BOOL)verbose
{
    // Interrupt config register is at 0x8, and is read/write D32
    
    unsigned long value;
    
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + kSIS3305IrqConfig
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    if(verbose)
    {
        NSLog(@"SIS3305 Interrupt Config: 0x%x\n",value);
    }
    
    return value;

}

- (void) writeInterruptConfig:(unsigned long)value
{
    // Interrupt config register is at 0x8, and is read/write D32
    
    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + kSIS3305IrqConfig
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    return;
}

- (unsigned long) readInterruptControl:(BOOL)verbose
{
    // Interrupt control register is at 0xC, and is read/write D32
    
    unsigned long value;
    
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + kSIS3305IrqControl
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    if(verbose)
    {
        NSLog(@"SIS3305 Interrupt Control: 0x%x\n",value);
    }
    
    return value;
}


- (void) writeInterruptControl:(unsigned long)value
{
    // Interrupt control register is at 0xC, and is read/write D32

    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + kSIS3305IrqControl
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    return;
}

#pragma mark -- Acquisition control regs

- (unsigned long) readAcquisitionControl:(BOOL)verbose
{
    // Acquisition control register is at 0x10, and is read/write
    // This register sets up most od the config for the digitization process
    // It is set up in a J/K fashion for writing
    
    
    unsigned long aValue = 0;
    
    [[self adapter] readLongBlock:&aValue
                        atAddress:[self baseAddress] + kSIS3305AcquisitionControl
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    if (verbose)
    {
        short triggerInTDC                  = (aValue >> 4)     & 0x1;
        short clockSourceStatus             = (aValue >> 12)    & 0x3;
        short ADCSampleLogicArmed           = (aValue >> 16)    & 0x1;
        short ADCSampleLogicEnabled         = (aValue >> 17)    & 0x1;
        short eventsToMemoryLogicBusy       = (aValue >> 18)    & 0x1;
        short memoryEndAddressThreshold     = (aValue >> 19)    & 0x1;
        short ADC1EventsToMemoryLogicBusy   = (aValue >> 20)    & 0x1;
        short ADC2EventsToMemoryLogicBusy   = (aValue >> 21)    & 0x1;
        short ADC1MemoryEndAddressThreshold = (aValue >> 22)    & 0x1;
        short ADC2MemoryEndAddressThreshold = (aValue >> 23)    & 0x1;
        short externalDirectVetoStatus      = (aValue >> 24)    & 0x1;
        short internalVetoFlag              = (aValue >> 25)    & 0x1;
        short externalVetoDelayLengthLogic  = (aValue >> 26)    & 0x1;
        short enabledMemoryOverrunVetoFlag  = (aValue >> 27)    & 0x1;
        short directMemoryBusyFlag          = (aValue >> 28)    & 0x1;
        short directMemoryStoppedFlag       = (aValue >> 29)    & 0x1;
        short ADC1MemoryOverrunVetoFlag     = (aValue >> 30)    & 0x1;
        short ADC2MemoryOverrunVetoFlag     = (aValue >> 31)    & 0x1;

        NSLog(@"Acquisition Register (0x%04x) \n",kSIS3305AcquisitionControl);
        NSLog(@"    Trigger-in TDC MEasurement Logic is: %2s\n",triggerInTDC ? "ENABLED" : "DISABLED");
        NSLog(@"    Clock Source: %2s \n", (clockSourceStatus&0x1) ? "external" : "internal 2.5 GHz");
        NSLog(@"    ADC Sample Logic: %2s and %2s \n", ADCSampleLogicArmed ? "ARMED" : "DISARMED",
                                                    ADCSampleLogicEnabled ? "ENABLED" : "DISABLED");
        NSLog(@"    Events to Memory logic: %2s \n", eventsToMemoryLogicBusy ? "BUSY" : "NOT BUSY");      // not sure what this is
        NSLog(@"    Memory End Address Threshold Flag: %d \n", memoryEndAddressThreshold);
        NSLog(@"    ADC1 Events to Memory Logic: %2s \n", ADC1EventsToMemoryLogicBusy ? "BUSY" : "NOT BUSY");
        NSLog(@"    ADC2 Events to Memory Logic: %2s \n", ADC2EventsToMemoryLogicBusy ? "BUSY" : "NOT BUSY");
        NSLog(@"    ADC1 Memory End Address Threshold: %2s \n", ADC1MemoryEndAddressThreshold ? "1" : "0");   // no idea what this means
        NSLog(@"    ADC2 Memory End Address Threshold: %2s \n", ADC2MemoryEndAddressThreshold ? "1" : "0");   // no idea what this means
        NSLog(@"    External Direct Veto: %2s \n", externalDirectVetoStatus ? "ENABLED" : "DISABLED");
        NSLog(@"    Internal veto (from key reg): %2s \n", internalVetoFlag ? "ENABLED" : "DISABLED");
        NSLog(@"    External Veto delay/length logic: %2s \n", externalVetoDelayLengthLogic ? "ENABLED" : "DISABLED");
        NSLog(@"    \"Enabled memory overrun veto flag\" %2s \n", enabledMemoryOverrunVetoFlag ? "ENABLED" : "DISABLED");
        NSLog(@"    Direct memory: %2s and  %2s \n ", directMemoryBusyFlag ? "BUSY" : "NOT BUSY",
                                                    directMemoryStoppedFlag ? "STOPPED" : "NOT STOPPED");
        NSLog(@"    ADC1 memory is %2s \n", ADC1MemoryOverrunVetoFlag ? "OVERRUN (veto-ing)" : "NOT OVERRUN");
        NSLog(@"    ADC2 memory is %2s \n", ADC2MemoryOverrunVetoFlag ? "OVERRUN (veto-ing)" : "NOT OVERRUN");
        
    }
    return aValue;
}

- (void) writeAcquisitionControl
{
    /*
     The register is set up as a J/K flip/flop -- 1 bit to set a function and 1 bit to disable.
     Set is 15:0, clear is 31:16.
     
     clock source:
     0 = internal
     1 = external
     The higher bit (13) is never used (always = 0) since there are only two possible sources
     The lower bit (12) is equal to clockSource.
     
     trigger-in TDC measurement logic:
     writing to bit 4 enables,
     writing to bit 20 disables
     
     
     Power up default reads 0x0.
     
     */
    
    unsigned long aMask = 0x0;
    
    aMask |= ((clockSource & 0x1)<< 12);
    aMask |= ((TDCMeasurementEnabled & 0x1) << 4);
    
    //put the inverse in the top bits to turn off everything else
    aMask = ((~aMask & 0x0000ffff)<<16) | aMask;
    
    [[self adapter] writeLongBlock:&aMask
                         atAddress:[self baseAddress] + kSIS3305AcquisitionControl
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}


- (void) writeClockSource:(unsigned long)aState
{
    /*
     
     As the acquisition register is implemented in a J/K fashion, we can write to the individual bits
     
     */
    
    aState = (aState & 0x2) << 12;    // max 2 bits for the clock source
    
    [[self adapter] writeLongBlock:&aState
                         atAddress:[self baseAddress] + kSIS3305AcquisitionControl
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}





#pragma mark -- More regs

- (unsigned long) readVetoLength:(BOOL)verbose
{
    // Register 0x14 R/W
    // Defines a veto length, which is used if the external LEMO veto Delay/Length logis is enabled in the control reg
    
    unsigned long value = 0;
    
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + kSIS3305VetoLength
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    if(verbose)
        NSLog(@"SIS305 Veto Length: 0x%x (%d ns) \n",value,(value+1)*20);
    
    return value;
}

- (void) writeVetoLength:(unsigned long)timeInNS
{
    // Register 0x14 R/W
    // Defines a veto length, which is used if the external LEMO veto Delay/Length logis is enabled in the control reg
    // probably the amount of time between veto signal and a trigger that would prevent trigger from causing readout
    // time is: (reg value + 1)*20 in nanoseconds
    //      so the minumum veto time is 20 ns
    // FIX: may exceed unsigned long if being silly here
    
    unsigned long value = (timeInNS/20)-1;
    
    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + kSIS3305VetoLength
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}

- (unsigned long) readVetoDelay:(BOOL)verbose
{
    // Register 0x18 R/W
    // Defines a veto delay, which is used if the external LEMO veto Delay/Length logis is enabled in the control reg
    // presumably this is the amount of time after receiving the LEMO signal when the VETO actually occurs
    
    unsigned long value = 0;
    
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + kSIS3305VetoDelayLength
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    if(verbose)
        NSLog(@"SIS305 Veto Delay Length: 0x%x (%d ns) \n",value,(value+1)*20);
    
    return value;
}

- (void) writeVetoDelay:(unsigned long)timeInNS
{
    // Register 0x18 R/W
    // Defines a veto delay, which is used if the external LEMO veto Delay/Length logis is enabled in the control reg
    // presumably this is the amount of time after receiving the LEMO signal when the VETO actually occurs
    
    unsigned long value = (timeInNS/20)-1;
    
    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + kSIS3305VetoDelayLength
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}



- (unsigned long) EEPROMControlwithCommand:(short)command andAddress:(short)addr andData:(unsigned int)data
{
    // Register 0x28 R/W
    // Accesses the 2kBit onboard EEPROM (128 words * 16 bits)
    
    unsigned long writeValue = 0;       // full register to write
    unsigned long readValue = 0;        // returned value
    writeValue = (data>>0) | (addr>>16) | (command>>24);

    
    BOOL read,write,erase,writeEnable,writeDisable;
    
    read        = (command & 0x1);
    write       = (command & 0x2);
    erase       = (command & 0x4);
    writeEnable = (command & 0x8);
    writeDisable= (command & 0x10);
    
    // check that a command has been issued at all
    if (command == 0)
    {
        NSLog(@"SIS3305: Looks like no command was given to the EEPROM...");
        return -1;
    }
    
    // check that only one command has been issued
    // ... probably a simple logical trick to this
    
    

    // perform the command requested
    // FIX: This should check the top bit (EEPROM busy) before trying anything
    
    [[self adapter] writeLongBlock:&writeValue
                         atAddress:[self baseAddress] + kSIS3305EEPROMControl
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
    [[self adapter] readLongBlock:&readValue
                        atAddress:[self baseAddress] + kSIS3305EEPROMControl
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];

    if ((readValue>>31)&1) {
        // EEPROM busy.... FIX
        NSLog(@"SIS3305: Error, EEPROM busy\n");
    }

    return readValue;
}

- (unsigned long) onewireControlwithCommand:(short)command andData:(unsigned int)data
{
    // at 0x2C R/w D32
    // FIX: Not really sure what to do with this, since it seems like it should take a 5 bit address, but
    // there isn't one.
    // I will minimally implement this... writes the command and data provided, then returns whatever is read out
    
    unsigned long writeValue = 0;
    unsigned long readValue = 0;
    
    writeValue = data | command<<8;
    
    
    [[self adapter] writeLongBlock:&writeValue
                         atAddress:[self baseAddress] + kSIS3305OneWireControlReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
    [[self adapter] readLongBlock:&readValue
                        atAddress:[self baseAddress] + kSIS3305OneWireControlReg
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    return readValue;
}

- (unsigned long) readBroadcastSetup:(bool)verbose
{
    // at 0x30
    // FIX: since I haven't implemented the write method for this register, we can't setup broadcast yet...
    unsigned long value;
    BOOL bEnabled,bMaster;
    unsigned int bAddr;
    
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + kSIS3305CbltBroadcastSetup
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    
    if(verbose)
    {
        bEnabled = value&0x10;
        bMaster = value &0x20;
        bAddr = value >> 24;
        NSLog(@"SIS3305: Broadcast is %s \n",bEnabled? "enabled":"not enabled");
        NSLog(@"SIS3305: This device is %s \n",bMaster? "the broadcast master": "not the broadcast master");
        NSLog(@"SIS3305: Broadcast address is 0x%x \n",bAddr);
    }
    
    return value;
}

- (unsigned long) readLEMOTriggerOutSelect
{
    // 0x40
    // writing to this register picks which items will be OR-ed together to appear on the LEMO trigger out
    unsigned long value;
    
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + kSIS3305TriggerOutSelectReg
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return value;
}


- (void) writeLEMOTriggerOutSelect:(unsigned long)value
{
    // 0x40
    // writing to this register picks which items will be OR-ed together to appear on the LEMO trigger out
    
    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + kSIS3305TriggerOutSelectReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    return;
}

- (void) writeLEMOTriggerOutSelect
{
    unsigned long writeValue = 0;
    unsigned short chan;
    
    for (chan = 0; chan<kNumSIS3305Channels; chan++) {
        writeValue |= (lemoOutSelectTrigger[chan]?1:0) << chan;
    }
    writeValue |= (lemoOutSelectTriggerIn?1:0)              << 8;
    writeValue |= (lemoOutSelectTriggerIn?1:0)              << 9;   // 8 and 9 are made the same value!
    writeValue |= (lemoOutSelectTriggerInPulse?1:0)         << 10;
    writeValue |= (lemoOutSelectTriggerInPulseWithSampleAndTDC?1:0) << 11;
    writeValue |= (lemoOutSelectSampleLogicArmed?1:0)       << 12;
    writeValue |= (lemoOutSelectSampleLogicEnabled?1:0)     << 13;
    writeValue |= (lemoOutSelectKeyOutputPulse?1:0)         << 14;
    writeValue |= (lemoOutSelectControlLemoTriggerOut?1:0)  << 15;
    writeValue |= (lemoOutSelectExternalVeto?1:0)           << 16;
    writeValue |= (lemoOutSelectInternalKeyVeto?1:0)        << 17;
    writeValue |= (lemoOutSelectExternalVetoLength?1:0)     << 18;
    writeValue |= (lemoOutSelectMemoryOverrunVeto?1:0)      << 19;

    [self writeLEMOTriggerOutSelect:writeValue];
}


- (unsigned long) readExternalTriggerCounter
{
    // at 0x4C, Read only D32
    
    // A 32-bit counter which will be cleared if "Sample Logic or TDC Measurement logic" is disabled
    // It is incremented with ech External trigger IN signal IF the Sample Logic AND TDC Measurement Logic are enabled
    
    unsigned long value;
    
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + kSIS3305ExternalTriggerCounter
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return value;
}


#pragma mark --- TDC Regs

- (unsigned long) readTDCWrite:(BOOL)verbose
{
    
    // Despite the confusing name, there is a TDC Write reg 0x50, which can be read. This returns that value
 
    unsigned long value;
    
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + kSIS3305TDCWriteCmdReg
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    if(verbose)
    {
        NSLog(@"SIS3305: TDC FIFO1 Empty Flag: %s \n",value&1?"YES":"NO");
        NSLog(@"SIS3305: TDC FIFO2 Empty Flag: %s \n",value&2?"YES":"NO");
        NSLog(@"SIS3305: TDC FIFO1 Load Flag: %s \n",value&4?"YES":"NO");
        NSLog(@"SIS3305: TDC FIFO2 Load Flag: %s \n",value&8?"YES":"NO");
        NSLog(@"SIS3305: TDC Error Flag: %s \n",value&0x10?"YES":"NO");
        NSLog(@"SIS3305: TDC IRQ Flag: %s \n",value&0x20?"YES":"NO");
    }
    
    return value;
}

- (void) writeTDCWriteWithData:(unsigned long)data atAddress:(unsigned short)addr
{
    // Despite the confusing name, there is a TDC Write reg 0x50, which can be read. This returns that value

    unsigned long writeValue = 0;

    writeValue = data | addr<<28;
    
    [[self adapter] writeLongBlock:&writeValue
                         atAddress:[self baseAddress] + kSIS3305TDCWriteCmdReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    return;
}




- (unsigned long) readTDCRead:(BOOL)verbose
{
    
    // Despite the confusing name, there is a TDC Read reg 0x54, which can be read. This returns that value
    
    unsigned long value;
    
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + kSIS3305TDCWriteCmdReg
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    if(verbose)
    {
        NSLog(@"SIS3305: TDC FIFO1 Empty Flag: %s \n",value&1?"YES":"NO");
        NSLog(@"SIS3305: TDC FIFO2 Empty Flag: %s \n",value&2?"YES":"NO");
        NSLog(@"SIS3305: TDC FIFO1 Load Flag: %s \n",value&4?"YES":"NO");
        NSLog(@"SIS3305: TDC FIFO2 Load Flag: %s \n",value&8?"YES":"NO");
        NSLog(@"SIS3305: TDC Error Flag: %s \n",value&0x10?"YES":"NO");
        NSLog(@"SIS3305: TDC IRQ Flag: %s \n",value&0x20?"YES":"NO");
    }
    
    return value;
}

- (void) writeTDCReadatAddress:(unsigned short)addr
{
    // Despite the confusing name, there is a TDC Read reg 0x54, which can be written.
    // This writes the address to read
    
    
    unsigned long writeValue = 0;
    
    writeValue = addr<<28;
    
    [[self adapter] writeLongBlock:&writeValue
                         atAddress:[self baseAddress] + kSIS3305TDCReadCmdReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    return;
}

- (unsigned long) readTDCStartStopEnable:(BOOL)verbose
{
    // reads 0x58, the TDC Start/Stop Enable Register
    // Only 3 bits to write or read
    // Bit 0: TDC Start Enable
    // Bit 1: TDC Stop1 Enable
    // Bit 2: TCD Stop2 Enable
    
    unsigned long value;
    
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + kSIS3305TDCStartStopEnableReg
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    if(verbose)
    {
        NSLog(@"SIS3305: TDC Start %s\n",value&1 ? "enabled. " : "disabled. ");
        NSLog(@"SIS3305: TDC Stop1 %s\n",value&2 ? "enabled. " : "disabled. ");
        NSLog(@"SIS3305: TDC Stop2 %s\n",value&4 ? "enabled. " : "disabled. ");
    }
    
    return value;
}

- (void) writeTDCStartStopEnable:(unsigned long)value
{
    // TDC Start/Stop Enable register 0x58
    // Only 3 bits to write or read
    // Bit 0: TDC Start Enable
    // Bit 1: TDC Stop1 Enable
    // Bit 2: TCD Stop2 Enable
    
    // presumably writing 0 to these disables, 1 enables
    
    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + kSIS3305TDCStartStopEnableReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    return;
}


- (void) writeXilinxJTAGTestWithTDI:(char)tdi andTMS:(char)tms
{
    // Xilinx JTAG Test register (0x60) write only D32
    // Used for firmware upgrade over VME
    // Only 2 bits can be written, for TDI and TMS
    // TCK is generated on each write
    // This register will probably not be used, since it may just be easier to plug in directly and use the JTAG port
    
    unsigned long value = 0;
    
    value = tdi | 2*tms;
    
    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + kSIS3305XilinxJTAGTest
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    return;
}

- (unsigned long) readXilinxJTAGDataIn
{
    
    // Also at 0x60, but read-only D32
    // Bit 31 contains the most recent TDO, and each TCK the value shifts right one (to 30, etc) as a shift reg
    
    unsigned long value;
    
    [[self adapter] readLongBlock:&value
                    atAddress:[self baseAddress] + kSIS3305XilinxJTAGDataIn
                    numToRead:1
                   withAddMod:[self addressModifier]
                usingAddSpace:0x01];

    return value;
}


#pragma mark -- Other regs



- (unsigned long) readTemperature:(BOOL)verbose
{
    // This digitizer has a temperature sensor onboard which can disable ADCs at a given threshold
    // This is read at 0x70 R/W D32
    
    // Note that the number returned is NOT the temperature, but the whole register
    
    unsigned long value = 0;
    
    
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + kSIS3305InternalTemperatureReg
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];


    float temp =        tempRawToC(value&0x3FF);
    float threshTemp =  tempRawToC((value>>16)&0x3FF);
    
    BOOL threshFlag     = (value>>28)&1;
    BOOL supervisorEnable = (value>>31)&1;
    
    [self setTemperature:temp];

    if (verbose)
    {
        NSLog(@"SIS3305: Board Temperature %3.1f C \n",temp);
        NSLog(@"SIS3305: Threshold Temp: %3.1f C \n",threshTemp);
        NSLog(@"SIS3305: Threshold Flag %s .\n", threshFlag?"SET":"NOT SET");
        NSLog(@"SIS3305: Temperature Supervisor is %s .\n", supervisorEnable?"ENABLED":"DISABLED");
    }
    
    return value;

}

- (void) writeTemperatureThreshold:(unsigned long)thresh
{
    
    unsigned long value = 0;
    
    value = (thresh << 16) | (temperatureSupervisorEnable<<31);
    
    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + kSIS3305InternalTemperatureReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    return;
}

#pragma mark ADC Serial Interface Control

- (unsigned long) readADCSerialInterface:(BOOL)verbose
{
    // reads out the ADC SPI at 0x74
    
    unsigned long value;
    
    [[self adapter] readLongBlock: &value
                        atAddress: [self baseAddress] + kSIS3305ADCSerialInterfaceReg
                        numToRead: 1
                       withAddMod: [self addressModifier]
                    usingAddSpace: 0x01];
    
    if(verbose)
    {
        NSLog(@"SIS3305 SPI: Data read: 0x%x \n ",value&0xFF);
        NSLog(@"SIS3305 SPI: Force ADC Standby Flag is %s .\n",(value>>29)&1?"SET":"NOT SET");
        NSLog(@"SIS3305 SPI: Set ADC Standby Logic Busy Flag is %s .\n",(value>>30)&1?"SET":"NOT SET");
        NSLog(@"SIS3305 SPI: Write/Read Logic Busy Flag is %s .\n",(value>>31)&1?"SET":"NOT SET");
    }

    return value;
}

- (unsigned long) readADCSerialInterfaceOnADC:(char)adcSelect fromAddress:(unsigned int)addr
{
    // Reading from the Serial Interface is a 2 step process:
    //      1: Write to the interface with the address you're interested in
    //      2: Read back from the register
    
    unsigned long writeValue = 0;
    writeValue = (addr << 16) | (adcSelect << 24);
    
    [self writeToAddress:kSIS3305ADCSerialInterfaceReg aValue:writeValue];
    [self waitUntilADCSerialInterfaceNotBusy];
    
    unsigned long value = [self readFromAddress:kSIS3305ADCSerialInterfaceReg];
    
    return value;
}

- (void) writeADCSerialInterface:(unsigned int)data onADC:(char)adcSelect toAddress:(unsigned int)addr viaSPI:(char)spi
{
    // write to the ADC SPI on 0x74
    // used for talking directly to the ADC chip to setup bandwidth, channel mode (1.25/2.5/5 gsps)
    
    unsigned long writeValue = 0;
    unsigned short write = 1;
    writeValue = data | (addr << 16) | (write << 23) | (adcSelect << 24) | (spi << 31);
 
    [[self adapter] writeLongBlock:&writeValue
                         atAddress:[self baseAddress] + kSIS3305ADCSerialInterfaceReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    [self waitUntilADCSerialInterfaceNotBusy];

    return;
}

- (void) writeADCSerialInterface:(unsigned int)data onADC:(char)adcSelect toAddress:(unsigned int)addr
{
    [self writeADCSerialInterface:data onADC:adcSelect toAddress:addr viaSPI:NO];
}

- (void) writeADCSerialInterface
{
//    this method is incomplete as written, and has more or less been replaced by the above:
//    [self writeADCSerialInterface:
//                            onADC:
//                        toAddress:
//                           viaSPI:];
    /*
     This is completely adapted from the SIS3305_ADC_SPI_Setup method in sis3305_configuration_readout_lib.c:888
     
     1. First we read the ID's for ADC1 and ADC2.
     
     2. Read Status of ADC14 and ADC58
     
     3. Write control register 14 and 58
     
     4. Assign the right "calibration parameters"
     
     
     */
}

- (unsigned long) readADCChipID
{
    /*
        Uses the SPI protocol of the ADC to read out the ADC Chip ID. 
        Only 16 bits of data per chip
            15:8    Chip type
            7:4     Branch number
            3:0     Version number
        So I return both in the same 32 bit word
            31:24   ADC 1: Chip type
            23:20   ADC 1: Branch number
            19:16   ADC 1: Version number
            15:8    ADC 0: Chip type
            7:4     ADC 0: Branch number
            3:0     ADC 0: Version number
     */
    
    unsigned long readValue = 0;
    unsigned long writeValue = 0;
    BOOL logicBusy = YES;
    
    unsigned long addr, adc;
    unsigned long RWcmd; // Read/write command (0 = read, 1 = write)
    
    unsigned int readCount = 0;
    unsigned int maxPolls = 100;
    
//    ORCommandList* aList = [ORCommandList commandList];
    
    struct SIS3305_ADC_SPI_Config_Struct packet;
    for (adc = 0; adc<2; adc++) {
        // read ADC Chip ID
        addr = 0x0;     // chip ID reg
        RWcmd = 0x0;    // read command
        
        writeValue =  ((RWcmd   & 0x1)  << 23)
                    | ((addr    &0x7F)  << 16)
                    | ((adc     & 0x1)  << 24);
        
        [self writeToAddress:kSIS3305ADCSerialInterfaceReg aValue:writeValue];
    
        do {
            readCount++;
            readValue = [self readFromAddress:kSIS3305ADCSerialInterfaceReg];
            logicBusy = (readValue >> 31) & 0x1;    // Is bit 31 high?
        }
        while ((readCount<maxPolls) && logicBusy == YES);
        if (logicBusy == YES) {
            NSLog(@"SIS3305 ADC %d SPI logic is busy, unable to write to it...",adc);
            return 0x0;
        }
        packet.chipID[adc] = readValue;
    }
    
    // make the output as expected
    readValue = 0;
    readValue = packet.chipID[0] | (packet.chipID[1] << 16);
    return readValue;
}


- (unsigned long) readADCControlReg:(bool)verbose
{
    /*
     Uses the SPI protocol of the ADC to read out the ADC Chip Configuration.
     Only 16 bits of data per chip
     15:14  Unused
     13     0
     12     Test
     11     0
     10     RM
     9      Unused
     8      Bandwidth
     7      Binary/Gray
     6      Unused
     5:4    Standby
     3:0    ADC Mode

     
     */
    
    unsigned long readValue = 0;
    unsigned long writeValue = 0;
    BOOL logicBusy = YES;
    
    unsigned long addr, adc;
    unsigned long RWcmd; // Read/write command (0 = read, 1 = write)
    
    unsigned int readCount = 0;
    unsigned int maxPolls = 100;
    
    //    ORCommandList* aList = [ORCommandList commandList];
    
    [self writeADCSerialChannelSelect:0xF];   // resets us to not having any channel selected
    
    
    struct SIS3305_ADC_SPI_Config_Struct packet;
    for (adc = 0; adc<kNumSIS3305Groups; adc++) {
        // read ADC Chip ID
        addr = 0x1;     // control reg
        RWcmd = 0x0;    // read command
        
        writeValue =  ((RWcmd   & 0x1)  << 23)
        | ((addr    &0x7F)  << 16)
        | ((adc     & 0x1)  << 24);
        
        [self writeToAddress:kSIS3305ADCSerialInterfaceReg aValue:writeValue];
        
        do {
            readCount++;
            readValue = [self readFromAddress:kSIS3305ADCSerialInterfaceReg];
            logicBusy = (readValue >> 31) & 0x1;    // Is bit 31 high?
        }
        while ((readCount<maxPolls) && logicBusy == YES);   // check until not busy or too many polls
        if (logicBusy == YES) {
            NSLog(@"SIS3305 ADC %d SPI logic is busy, unable to write to it...",adc);
            return 0x0;
        }
        packet.control[adc] = readValue;
    }
    
    if (verbose) {
        for (adc =0; adc<kNumSIS3305Groups; adc++) {
            //BOOL test =                 ((packet.control[adc] >>12) & 0x1);
            //BOOL rm =                   ((packet.control[adc] >>10) & 0x1);
            BOOL bw =                   ((packet.control[adc] >> 8) & 0x1);
            BOOL grayMode =             ((packet.control[adc] >> 7) & 0x1);
            unsigned short standby =    ((packet.control[adc] >> 4) & 0x3);
            unsigned short adcMode =    ((packet.control[adc]       & 0xF));
            
            BOOL fourChannel, twoChannel,oneChannel, chanA, chanB, chanC, chanD;
            
            NSMutableString* mode = [[NSMutableString alloc]init]; // FIX does this need to be released? (--MAH--YES. I fixed by adding a release at the bottom. 10/12/15)
            
            switch (adcMode) {
                case 0:
                case 1:
                case 2:
                case 3:
                    [mode setString:@"Four-channel mode (1.25 Gsps per channel)"];
                    oneChannel = NO;
                    twoChannel = NO;
                    fourChannel = YES;
                    chanA = YES;
                    chanB = YES;
                    chanC = YES;
                    chanD = YES;
                    break;
                case 0x4:
                    [mode setString:@"Two-channel mode (Channel A and Channel C, 2.5 Gsps per channel)"];
                    chanA = YES;
                    chanB = NO;
                    chanC = YES;
                    chanD = NO;
                    break;
                case 0x5:
                    [mode setString:@"Two-channel mode (Channel B and Channel C, 2.5 Gsps per channel)"];
                    chanA = NO;
                    chanB = YES;
                    chanC = YES;
                    chanD = NO;
                    break;
                case 0x6:
                    // FIX: fill the rest of this out...
                    [mode setString:@"Two-channel mode (Channel B and Channel C, 2.5 Gsps per channel)"];
                    break;
                case 0x7:
                    [mode setString:@"Two-channel mode (Channel B and Channel D, 2.5 Gsps per channel)"];
                    break;
                case 0x8:
                    [mode setString:@"One-channel mode (Channel A, 5 Gsps)"];
                    break;
                case 0x9:
                    [mode setString:@"One-channel mode (Channel B, 5 Gsps)"];
                    break;
                case 0xA:
                    [mode setString:@"One-channel mode (Channel C, 5 Gsps)"];
                    break;
                case 0xB:
                    [mode setString:@"One-channel mode (Channel D, 5 Gsps)"];
                    break;
                case 0xC:
                    [mode setString:@"Common input mode, simultaneous sampling (Channel A)"];
                    break;
                case 0xD:
                    [mode setString:@"Common input mode, simultaneous sampling (Channel B)"];
                    break;
                case 0xE:
                    [mode setString:@"Common input mode, simultaneous sampling (Channel C)"];
                    break;
                case 0xF:
                    [mode setString:@"Common input mode, simultaneous sampling (Channel D)"];
                    break;
                default:
                    [mode setString:@"Invalid ADC mode... there is a problem."];
                    break;
            }
            
            
//          10     RM
            // FIX: implement RM, but I don't know what it means, really...
            
//          8      Bandwidth
            NSLog(@"ADC%d bandwidth is: %@ \n", adc, (bw?@"Full bandwidth":@"Nominal bandwidth (1 GHz typical)"));
//          7      Binary/Gray
            NSLog(@"ADC%d is using %@ coding\n", adc, grayMode?@"gray":@"binary");

            //          5:4    Standby
            // FIX: this is a dodgy way of handling this, and it probably doesn't work right.
            switch (standby) {
                case 0x0:
                    NSLog(@"ADC%d standby mode: FULL ACTIVE\n",adc);
                    break;
                case 0x1:
                    NSLog(@"ADC%d standby mode: A/B STANDBY \n",adc);
                    break;
                case 0x2:
                    NSLog(@"ADC%d standby mode: C/D STANDBY \n",adc);
                    break;
                case 0x3:
                    NSLog(@"ADC%d standby mode: FULL STANDBY \n",adc);
                    break;
            }
            
 /*
            NSLog(@"ADC%d standby is %@ \n",adc), ((standby&0x2)?
                                                            ((standby&0x1)?@"Full standby":@"C/D standby")
                                                           :((standby&0x1)?@"A/B standby":@"Full active"));
*/
  //          3:0    ADC Mode
            NSLog(@"ADC%d mode: %@ \n",adc,mode);
            [mode release];
        }
        
    }
    
    // make the output as expected
    readValue = packet.control[0] | (packet.control[1] << 16);
    return readValue;
}

- (void) writeADCControlReg
{
    /*
     Uses the SPI protocol of the ADC to write out the ADC Chip Configuration.
     Only 16 bits of data per chip
     15:14  Unused
     13     0
     12     Test
     11     0
     10     RM
     9      Unused
     8      Bandwidth
     7      Binary/Gray
     6      Unused
     5:4    Standby
     3:0    ADC Mode
     */
    
    unsigned long writeData = 0;
    unsigned long addr, adc;
    
    [self writeADCSerialChannelSelect:0xF];   // resets us to not having any channel selected

    for (adc = 0; adc<kNumSIS3305Groups; adc++)
    {
        addr = 0x1;     // control reg
        writeData = (([self channelMode:adc]    & 0xF)  << 0)
                |   (([self grayCodeEnabled:adc] &0x1)  << 7)
                |   (([self bandwidth:adc]      & 0x1)  << 8)
                |   (([self testMode:adc]       & 0x1)  << 12);
        
        [self writeADCSerialInterface:writeData onADC:adc toAddress:addr viaSPI:NO];
    }
    [self waitUntilADCSerialInterfaceNotBusy];
    [self ADCSynchReset];   // this is necessary every time you change channel mode, I write it every time here.
}

- (void) writeADCSerialChannelSelect:(unsigned short)cardChan
{
    /*
     Uses the SPI protocol of the ADC to read out the ADC Chip Configuration.
     Only 16 bits of data per chip
     
     Only three bits can be written to in this register (2:0)
     000: No channel selected
     001: Channel A
     010: Channel B
     011: Channel C
     100: Channel D
     else: No channel selected
     
     After finishing the channel-basis settings, this should probably be set back to 0.
     */
 
    // `chan` here is the actual channel, not the ADC channel
    
    unsigned long writeData = 0;
    
    unsigned long addr, adc, adcChan;
    
    BOOL resetFlag = NO;
    
    //    unsigned int readCount = 0;
    
    
    if (cardChan<8){
        adc = floor(cardChan/4);    // the adc the channel is on
        adcChan = (cardChan - 4*adc);   // the relative channel on each ADC
//        adcChan = chan%4;
//        adc = (chan-adcChan)/4;
    }
    else{
        adc = 0;
        adcChan = 0x5;  // just a made up value, greater than 4
        resetFlag = YES;
    }
    
    addr = 0xF;     // Channel Selector register
    
    // 16-bit value written to the SPI chip
    if(resetFlag == NO)
        writeData = ((adcChan+1   & 0x7)  << 0);
    else
        writeData = 0;
    
    [self writeADCSerialInterface:writeData onADC:adc toAddress:addr];

//    if (resetFlag == YES) { // reset the other chip too for good measure.
//        adc = 1;
//        [self writeADCSerialInterface:writeData onADC:adc toAddress:addr];
//    }
}


- (unsigned long) readADCSerialChannelSelect:(unsigned short)adc
{
    unsigned long addr;
    unsigned long readValue;
    
    if (adc >= kNumSIS3305Groups) {
        NSLog(@"Invalid ADC specified for readADCChannelSelect.... Returning.\n");
        return 0xFFFF;
    }
    addr = 0xF;     // Channel Selector register

    readValue = [self readADCSerialInterfaceOnADC:adc fromAddress:addr];
    return readValue & 0xFFFF;
}




- (unsigned long) readADCOffset:(unsigned short)chan
{
    // this reads from 0x21 of the ADC, the "Offset Register", a read only reg
    unsigned short adcChan,adc;
    unsigned long readValue = 0;
    unsigned long addr;
    
    adcChan = chan%4;       // the relative channel on each ADC
    adc = (chan-adcChan)/4;     // the adc the channel is on
    addr = 0x21;    // offset reg

    readValue = [self readADCSerialInterfaceOnADC:adc fromAddress:addr];

    return  readValue;
}



- (void) writeADCOffsets
{
    //unsigned long writeValue = 0;
    unsigned long writeData = 0;
    
    unsigned long addr, adc;
    unsigned long RWcmd;        // Read/write command (0 = read, 1 = write)
    
    unsigned short adcChan,chan;

    addr = 0x20;    // External Offset register
    RWcmd = 0x1;    // write command
    
    // 16-bit value written to the SPI chip
    for (chan = 0; chan<kNumSIS3305Channels; chan++) {
        adcChan = chan%4;       // the relative channel on each ADC
        adc = (chan-adcChan)/4;     // the adc the channel is on
        [self writeADCSerialChannelSelect:chan];
        
        writeData = (([self adcOffset:chan]   & 0x3FF)  << 0);
        [self writeADCSerialInterface:writeData onADC:adc toAddress:addr];
        
        // next, force the ADC to pull in these values as the "calibration"
        [self applyADCCalibration:adc];
    }
    
    [self writeADCSerialChannelSelect:0xF]; // reset to `no channel selected`
}

- (unsigned long) readADCGain:(unsigned short)chan
{
    // this reads from 0x23 of the ADC, the "Offset Register", a read only reg
    unsigned short adcChan,adc;
    unsigned long readValue = 0;
    unsigned long addr;
    
    adcChan = chan%4;       // the relative channel on each ADC
    adc = (chan-adcChan)/4;     // the adc the channel is on
    
    addr = 0x23;    // gain reg
    readValue = [self readADCSerialInterfaceOnADC:adc fromAddress:addr];
    
    return  readValue;
}

- (void) writeADCGains
{
    unsigned long writeData = 0;
    unsigned long gainExtAddr, gainIntAddr, chanSelectAddr, calAddr;
    unsigned short adc,chan;
    
    gainExtAddr = 0x22;    // External Gain register
    gainIntAddr = 0x23;
    chanSelectAddr = 0xF;
    calAddr = 0x10;
    
//    unsigned short bigChan;
    for(chan=0;chan<8;chan++)
    {
        adc = floor(chan/4);
        
        [self writeADCSerialChannelSelect:chan];
        
        // write the gain
        writeData =  ([self adcGain:chan] & 0xFFF);
        [self writeADCSerialInterface:writeData onADC:adc toAddress:gainExtAddr];
        
        // now we pull this into the gain reg
        writeData = 0x20;
        [self writeADCSerialInterface:writeData onADC:adc toAddress:calAddr];

        if([self checkADCCalibrationMailboxReady:adc])
        {
            writeData = 0x00;
            [self writeADCSerialInterface:writeData onADC:adc toAddress:calAddr];
        };	
    }
    
    return;
    /*
    
    
    
    
    for (chan = 0; chan<kNumSIS3305Channels; chan++) {
        adcChan = chan%4;       // the relative channel on each ADC
        adc = floor(chan/4);

        [self writeADCSerialChannelSelect:chan];
        
        [self writeADCSerialInterface:0x0 onADC:adc toAddress:calAddr]; // reset calibration
        
        writeData = ([self adcGain:chan]   & 0x3FF);
        [self writeADCSerialInterface:writeData onADC:adc toAddress:gainExtAddr];

        // next, force the ADC to pull in these values as the "calibration"
//        [self applyADCCalibration:adc];
//        [self applyADCGainCalibration:chan];

//        writeData = 0x20;
//        [self writeADCSerialInterface:writeData onADC:adc toAddress:calAddr];
        
//        [self checkADCCalibrationMailboxReady:adc];
//        [self writeADCSerialInterface:0x0 onADC:adc toAddress:calAddr];
//        [self checkADCCalibrationMailboxReady:adc];
    }
    
    [self writeADCSerialChannelSelect:0xF]; // reset to `no channel selected`
    
    
    */
}


- (unsigned long) readADCPhase:(unsigned short)chan
{
    // this reads from 0x25 of the ADC, the "Phase Register", a read only reg
    unsigned short adcChan,adc;
    unsigned long readValue = 0;
    unsigned long addr;

    adcChan = chan%4;       // the relative channel on each ADC
    adc = (chan-adcChan)/4;     // the adc the channel is on
    
    addr = 0x25;    // gain reg
    
    readValue = [self readADCSerialInterfaceOnADC:adc fromAddress:addr];
    return  readValue;
}

- (void) writeADCPhase
{
    unsigned long writeData = 0;
    unsigned long addr, adc;
    unsigned short adcChan,chan;
    
    
    addr = 0x24;    // External Gain register
    
    // 16-bit value written to the SPI chip
    for (chan = 0; chan<kNumSIS3305Channels; chan++) {
        adcChan = chan%4;       // the relative channel on each ADC
        adc = (chan-adcChan)/4;     // the adc the channel is on
        
        [self writeADCSerialChannelSelect:chan];
        writeData = (([self adcPhase:chan]   & 0x3FF)  << 0);
        [self writeADCSerialInterface:writeData onADC:adc toAddress:addr];
 
        // next, force the ADC to pull in these values as the "calibration"
        [self applyADCCalibration:adc];
    }
    
    [self writeADCSerialChannelSelect:0xF]; // reset to `no channel selected`
}

- (unsigned long) readADCCalibrationMailbox:(unsigned short)adc
{
    return [self readADCSerialInterfaceOnADC:adc fromAddress:0x11];
}

- (BOOL) checkADCCalibrationMailboxReady:(unsigned short)adc
{
    // checking this is just a way of introducing some delay
    // there's nothing I can do except reset the chip if it gets stuck high...
    
    unsigned long value;
    unsigned long numReads = 0;
    unsigned long maxReads = 1000;
    do{
        value = [self readADCCalibrationMailbox:adc];
        numReads++;
    }while ((value != 0) && (numReads < maxReads));
    
    if (value != 0) {
        unsigned short currentChan = [self readADCSerialChannelSelect:adc];
        NSLogColor([NSColor redColor], @"ADC Calibration mailbox for channel %d not ready\n",currentChan);
        return NO;
    }
    else
        return YES;
    
}
- (void) applyADCGainCalibration:(unsigned short)chan
{
    unsigned short addr = 0x10;
    unsigned short setGain = 0x2;
    unsigned short setIdle = 0x0;
    unsigned short adc = floor(chan/4);
    
    // check that we're ready to do a calibration
    if([self checkADCCalibrationMailboxReady:adc] == NO)
    {
        NSLogColor([NSColor redColor], @"Error: ADC mailbox indicates channel 0x%x is not ready to calibrate\n", chan);
        return;
    }
    
    // apply the calibration
    [self writeADCSerialInterface:setGain onADC:adc toAddress:addr];
    
    // check that it's all good afterwards
    if([self checkADCCalibrationMailboxReady:adc] == NO)
    {
        NSLogColor([NSColor redColor], @"Error: ADC mailbox indicates channel 0x%x is still calibrating? Probably an error?",chan);
        return;
    }
    
    // return the calibration setting manually?
    [self writeADCSerialInterface:setIdle onADC:adc toAddress:addr];

}


- (void) applyADCCalibration:(unsigned short)adc
{
    /* 
     After writing values to the external gain, phase, or offset, the values have to be
     pulled in as "calibration". To do this, we write to the ADC calibration reg.
     
     This is written as a worst case, slightly lower performance version, since it 
     tries to write all three (gain, phase, offset), though they may not all need 
     writing.
     
     0xA8 = b 1010 1000
     */
    
    unsigned long writeData = 0;    // 16 bit value written to ADC chip
    
    unsigned long addr;         // address in ADC chip
    unsigned long RWcmd;        // Read/write command (0 = read, 1 = write)
    
    
    addr = 0x10;    // calibration control reg
    RWcmd = 0x1;    // write
    

    [self checkADCCalibrationMailboxReady:adc];

    writeData = 0x8;    // force external offset adjust for selected channel
    [self writeADCSerialInterface:writeData onADC:adc toAddress:addr];
    [self checkADCCalibrationMailboxReady:adc];
    
    writeData = 0x20;    // force external gain adjust for selected channel
    [self writeADCSerialInterface:writeData onADC:adc toAddress:addr];
    [self checkADCCalibrationMailboxReady:adc];
    
    writeData = 0x80;    // force external phase adjust for selected channel
    [self writeADCSerialInterface:writeData onADC:adc toAddress:addr];
    [self checkADCCalibrationMailboxReady:adc];

    writeData = 0x00;    // when we're done, set it back to 0
    [self writeADCSerialInterface:writeData onADC:adc toAddress:addr];
    [self checkADCCalibrationMailboxReady:adc];
    
    [self validateSerialADCCalibration];
    return;
}

- (BOOL) checkADCSerialInterfaceBusy
{
    BOOL busy;
    unsigned long readValue = 0;
    
    readValue = [self readFromAddress:kSIS3305ADCSerialInterfaceReg];
    
    busy = ((readValue>>31)&0x1)?YES:NO;
    
    return busy;
}

- (void) waitUntilADCSerialInterfaceNotBusy
{
    [self waitUntilADCSerialInterfaceNotBusy:100];
}

- (unsigned long) waitUntilADCSerialInterfaceNotBusy:(unsigned long)maxReads
{
    unsigned int numReads = 0;
    BOOL busy;
    do{
        numReads++;
        busy = [self checkADCSerialInterfaceBusy];
    } while( busy == YES && (numReads < maxReads));
    
    if (busy == YES)
    {
        NSLogColor([NSColor blueColor], @"Logic is busy!");
    } // Logic is busy
    
    return numReads;
}


- (unsigned long) validateSerialADCCalibrationOnChannel:(unsigned short)chan
{
    unsigned long error = 0;
    
    if([self readADCGain:chan] != [self adcGain:chan])
    {
        NSLogColor([NSColor redColor], @"SIS3305 (slot %d) did not correctly write ADC gain of channel %d. \n",[self slot],chan);
        error++;
    }
    if([self readADCPhase:chan] != [self adcPhase:chan])
    {
        NSLogColor([NSColor redColor], @"SIS3305 (slot %d) did not correctly write ADC phase of channel %d. \n",[self slot],chan);
        error++;
    }
    if([self readADCOffset:chan] != [self adcOffset:chan])
    {
        NSLogColor([NSColor redColor], @"SIS3305 (slot %d) did not correctly write ADC offset of channel %d. \n",[self slot],chan);
        error++;
    }

    if (error > 0)
    {
        NSLogColor([NSColor redColor], @"SIS3305 (slot %d) had %d values that did not get correctly written to the ADC. \n",[self slot],error);
    
    }
    return error;
}

- (unsigned long) validateSerialADCCalibration
{
    // here I put in some error checking to make sure that the values "stick" and are actually written
    unsigned short chan;
    unsigned long error = 0;
    for (chan=0; chan<8; chan++) {
        if([self readADCGain:chan] != [self adcGain:chan])
        {
            NSLogColor([NSColor redColor], @"SIS3305 (slot %d) did not correctly write ADC gain of channel %d. \n",[self slot],chan);
            error++;
        }
        if([self readADCPhase:chan] != [self adcPhase:chan])
        {
            NSLogColor([NSColor redColor], @"SIS3305 (slot %d) did not correctly write ADC phase of channel %d. \n",[self slot],chan);
            error++;
        }
        if([self readADCOffset:chan] != [self adcOffset:chan])
        {
            NSLogColor([NSColor redColor], @"SIS3305 (slot %d) did not correctly write ADC offset of channel %d. \n",[self slot],chan);
            error++;
        }
    }
    if (error > 0)
    {
        NSLogColor([NSColor redColor], @"SIS3305 (slot %d) had %d values that did not get correctly written to the ADC. \n",[self slot],error);
        
    }
    return error;
}


#pragma mark end ADC Serial control


- (void) writeDataTransferControlRegister:(short)group withCommand:(short)command withAddress:(unsigned long)value
{
    // commands:
    //      00      reset transfer FSM
    //      01      reset transfer FSM
    //      10      start Read transfer
    //      11      start Write transfer
    
    if (group>=kNumSIS3305Groups) {
        NSLog(@" invalid number for group\n");
        return;
    }
    
    unsigned long addr = 0;
    
    switch (group) {
        case 0:
            addr = kSIS3305DataTransferADC14CtrlReg;
            break;
        case 1:
            addr = kSIS3305DataTransferADC58CtrlReg;
            break;
        default:
            addr = 0;
            break;
    }
    
    if (group>=0 && group <kNumSIS3305Groups) {
        unsigned long writeValue = command<<30;
        writeValue |= value;
        
        [[self adapter] writeLongBlock:&writeValue
                             atAddress:[self baseAddress] + addr
                            numToWrite:1
                            withAddMod:[self addressModifier]
                         usingAddSpace:0x01];
    }
}

- (unsigned long) readDataTransferControlRegister:(short)group
{
    unsigned long addr = 0;
    unsigned long data = 0;
    
    switch (group) {
        case 0:
            addr = kSIS3305DataTransferADC14CtrlReg;
            break;
        case 1:
            addr = kSIS3305DataTransferADC58CtrlReg;
            break;
        default:
            addr = 0;
            NSLog(@" Invalid group number");
            return 0;
            break;
    }
    
    [[self adapter] readLongBlock:&data
                        atAddress:[self baseAddress] + addr
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    return data;
}

- (unsigned long) readDataTransferStatusRegister:(short)group
{
    // Read data transfer status of each ADC on 0xC8 and 0xCC Read-only D32
    // this should be checked to know how full the FIFO is, and if the Data is ready or still being transfered
    
    unsigned long addr = 0;
    unsigned long data = 0;
    
    switch (group) {
        case 0:
            addr = kSIS3305DataTransferADC14StatusReg;
            break;
        case 1:
            addr = kSIS3305DataTransferADC58StatusReg;
            break;
        default:
            addr = 0;
            NSLog(@" Invalid group number");
            return 0;
            break;
    }
    
    [[self adapter] readLongBlock:&data
                        atAddress:[self baseAddress] + addr
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    return data;
}


- (unsigned long) readAuroraProtocolStatus
{
    // no idea what this is, but it probably won't be used
    
    unsigned long value = 0;
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + kSIS3305VmeFpgaAuroraProtStatus
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    return value;
}

- (void) writeAuroraProtocolStatus:(unsigned long)value
{
    // no idea what this is, but it probably won't be used

    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + kSIS3305VmeFpgaAuroraProtStatus
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];

    return;
}

- (unsigned long) readAuroraDataStatus
{
    unsigned long value = 0;
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + kSIS3305VmeFpgaAuroraDataStatus
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    return value;
}
- (void) writeAuroraDataStatus:(unsigned long)value
{
    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + kSIS3305VmeFpgaAuroraDataStatus
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
    return;
}


#pragma mark -- Key Addresses
- (void) reset
{
    unsigned long aValue = 0; //value doesn't matter
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3305KeyReset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
    NSLog(@"SIS3305 reset\n");
}

- (void) armSampleLogic
{
    unsigned long aValue = 0;
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3305KeyArmSampleLogic
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
//    NSLog(@"SIS3305 Sample logic armed\n");
}

- (void) disarmSampleLogic
{
    unsigned long aValue = 0;
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3305KeyDisarmSampleLogic
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
//    NSLog(@"SIS3305 Sample logic disarmed\n");
}


- (void) forceTrigger
{
    unsigned long aValue = 0;
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3305KeyTrigger
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
    NSLog(@"SIS3305 Trigger forced \n");
    return;
}


- (void) enableSampleLogic
{
    unsigned long aValue = 0xAAAA;
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3305KeyEnableSampleLogic
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
//    NSLog(@"SIS3305 Sample logic enabled \n");
    
}

- (void) setVeto
{
    unsigned long aValue = 0xAAAA;
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3305KeySetVeto
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
    NSLog(@"SIS3305 Veto set \n");
}

- (void) clearVeto
{
    unsigned long aValue = 0xAAAA;
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3305KeyClrVeto
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
    NSLog(@"SIS3305 Veto cleared\n");
}

- (void) ADCSynchReset
{
    //    SIS3305_ADC_SYNCH_PULSE
    /*
     This is necessary to synchronize the 4 ADC channels within the ADC chips.
     Any write to this register (with arbitrary data) makes the ADC out clock signals go low, and
     resets the ISERDES Logic in the FPGA for the ADC data.
     The ADC out clock signals restart after [the TDR + pipeline delay + some programmed number of
     input clock cycles (set via SPI in the SYNCH reg)].
     */
    unsigned long aValue = 0;
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3305ADCSynchPulse
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
    NSLog(@"SIS3305 ADC Synch Reset\n");
}

- (void) ADCFPGAReset
{
    /*
     Resets the ADC-FPGA logic (including the DDR2 memory controller).
     Used for test purposes only, and probably should never be used.
     */
    unsigned long aValue = 0xAAAA;
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3305ADCFpgaReset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
    NSLog(@"SIS3305 ADC-FPGA logic reset\n");
}

- (void) pulseExternalTriggerOut
{
    /*
     Generates a pulse on the external trigger out (if it is enabled in the LEMO trigger out select register, bit 15).
     */
    unsigned long aValue = 0xAAAA;
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3305ADCExternalTriggerOutPulse
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}

#pragma mark -- more regs

- (unsigned long) getEventConfigOffsets:(int)group
{
    switch (group) {
        case 0: return kSIS3305EventConfigADC14;
        case 1: return kSIS3305EventConfigADC58;
    }
    return (unsigned long) -1;
}

- (unsigned long) readEventConfigurationOfGroup:(short)group
{

    unsigned long addr = 0;
    unsigned long value;
    
    switch (group) {
        case 0:         addr = kSIS3305EventConfigADC14;
            break;
        case 1:         addr = kSIS3305EventConfigADC58;
            break;
        default:   addr = -1;
            NSLog(@"Invalid group selection");
            return 0xFFFF;
    }

    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + addr
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];

    return value;
}

- (void) writeEventConfiguration
{
    //******?the extern/internal gates seem to have an inverted logic, so the extern/internal gate matrixes in IB are swapped.
    /*
     The are two event config registers, one for each channel group. They control the following:
     [2:0]   - Event saving mode
     3       unused
     4       - ADC Gate mode (else trigger mode)
     5       - Enable global trigger/Gate (synchronous mode)
     6       - Enable internal trigger/gate (asynchronous mode)
     7       unused
     8       - Enable ADC event sampling with next external trigger (TDC) (else with enable)
     9       - Enable "timestamp clear with sample enable" bit
     10      - Disable timestamp clear
     11      unused
     12      - Grey code enable
     [14:13] unused
     15      - ADC memory write via VME test enable
     16      - Disable "direct memory header" bit
     17      unused (and apparently Enable "direct memory TDC measurement" bit?)
     18      - Enable "Direct memory stop arm for trigger after pretrigger delay" bit
     19      unused
     [23:20] - ADC event header programmable info bits
     [31:24] - ADC event header programmable ID bits
     24: reads as 0= ADC chip 1, 1= ADC chip 2
     */
    
    int i;

    
//    ORCommandList* aList = [ORCommandList commandList];
    for(i=0;i<kNumSIS3305Groups;i++){
        unsigned long aValueMask = 0x0;
        
        aValueMask |= (eventSavingMode[i]               & 0x7)      << 0;
        // bit 3: unused
        // bit 4 ADC Gate Mode
        aValueMask |= ([self ADCGateModeEnabled:i]      & 0x1)      << 4;
        aValueMask |= (globalTriggerEnabled[i]          & 0x1)      << 5;
        aValueMask |= ([self internalTriggerEnabled:i]  & 0x1)      << 6;
        // bit 7: unused
        // bit 8: enable "ADC event sampling with next external trigger"
        aValueMask |= ([self startEventSamplingWithExtTrigEnabled:i] & 0x1) << 8;
        // bit 9: enable timestamp clear with sample enable
        aValueMask |= ([self clearTimestampWhenSamplingEnabledEnabled:i] & 0x1) << 9;

        // bit 10: disable timestamp clear
        aValueMask |= ([self clearTimestampDisabled:i] & 0x1)       << 10;
        
        // bit 11: unused
        // bit 12: Gray code enable
        aValueMask |= ([self grayCodeEnabled:i]        & 0x1)       << 12;
        
        // bit 13,14: unused
        // bit 15: ADC Memory write via VME Test Enable (FIX: should implement)
        // bit 16: Disable "direct memory header" bit
        aValueMask |= ([self directMemoryHeaderDisabled:i] & 0x1)   << 16;

        // bit 17: unused
        // bit 18: Enable "direct memory stop arm for trigger after pretrigger delay" (FIX: should implement)

        // bit 19: unused
        // bit 20-23: ADC event header programmable info bits 0-3
        aValueMask |= (0x0)  << 20;
        // bit 24-31: ADC event header programmable ID bits 0-7
        aValueMask |= (0x0) << 24; //i << 24;
        aValueMask |= (0x0) << 1; // ([self baseAddress] & 0x7F000000) << 1;    // this is the geographic address 30:24 pushed to 31:25 of this register
        
        [[self adapter] writeLongBlock: &aValueMask
                                                       atAddress: [self baseAddress] + [self getEventConfigOffsets:i]
                                                      numToWrite: 1
                                                      withAddMod: [self addressModifier]
                                                   usingAddSpace: 0x01];
    }

//    [self executeCommandList:aList];
    
}




- (unsigned long) readSampleStartAddressOfGroup:(short)group
{
    // This returns the sample start address
    // The contents of the sample memory start address register is assigned as "memory data storage address"
    // with the KEY ARM command or with the KEY ENABLE command
    // So, when you arm or enable, this register will contain the address of the memory data.
    
    unsigned long addr, value;
    
    // select the correct group address
    switch (group) {
        case 0: addr = kSIS3305SampleStartAddressADC14;
            break;
        case 1: addr = kSIS3305SampleStartAddressADC58;
            break;
        default:
            addr = -1;
            break;
    }
    
    // FIX: the manual says 16 32-bit words (512 bit blocks). Do I need to read a block of 16 words and return it all?
    
    [[self adapter] readLongBlock: &value
                        atAddress: [self baseAddress] + addr
                        numToRead: 1
                       withAddMod: [self addressModifier]
                    usingAddSpace: 0x01];

    //    NSLog(@" Reading sample start address\n");
    //    NSLog(@"    address: 0x%x\n", addr);
    //    NSLog(@"    value: 0x%x\n", value);
    
    return value;
}

- (void) writeSampleStartAddressOfGroup:(short)group toValue:(unsigned long)value
{
    unsigned long addr;
    
    if (value != (value&0xFFFFFF) )
    {
        NSLog(@"SIS3305: Invalid sample start address value, must be less than 2^24\n");
        return;
    }
    
    value = (value & 0xFFFFFF);     // F^6 = 23:0, mask to ensure no bad write
    
    // select the correct group address
    switch (group) {
        case 0: addr = kSIS3305SampleStartAddressADC14;
            break;
        case 1: addr = kSIS3305SampleStartAddressADC58;
            break;
        default:
            addr = -1;
            break;
    }
    
    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + addr
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
    return;
}

- (void) writeSampleStartAddresses
{
    unsigned short group;
    for (group =0; group>kNumSIS3305Groups; group++) {
        [self writeSampleStartAddressOfGroup:group toValue:[self sampleStartAddress:group]];
    }
}


- (unsigned long) readSampleLength:(short) group
{
    // 0x2008 or 0x3008
    // The value of this register indicates the size of the sample. You must know the event saving mode to know how to interpret this
    
    // Event FIFO Mode: Saving modes 0,1,4
    //      sample or extended block size is the bottom 7 downto 0
    // Event Direct Memory Mode: Saving modes 6,7
    //      sample or extended block size is the bottom 23 downto 0
    
    // the actual number of 128 bit blocks is (the sample/extended block length + 1)
    // The number of samples in this block depends on the rate
    
    unsigned long addr = 0;
    unsigned long value = 0;
    unsigned long length = 0;
    unsigned short mode;        // event saving mode
    
    // select the correct group's address
    switch (group) {
        case 0: addr = kSIS3305SampleLengthADC14;
            break;
        case 1: addr = kSIS3305SampleLengthADC58;
            break;
        default:
            addr = -1;
            break;
    }
    
    mode = [self eventSavingMode:group];
    
    [[self adapter] readLongBlock: &value
                        atAddress: [self baseAddress] + addr
                        numToRead: 1
                       withAddMod: [self addressModifier]
                    usingAddSpace: 0x01];
    
    if (mode == 0 || mode == 1 || mode == 4)
        length = value&0xFF;        // FF = 7:0
    
    if (mode == 6 || mode == 7)
        length = value&0xFFFFFF;    // F^6 = 23:0
    
    return length;
}


- (void) writeSampleLengthOfGroup:(short)group toValue:(unsigned long)value
{
    // 0x2008 or 0x3008
    // The value of this register indicates the size of the sample. You must know the event saving mode to know how to interpret this
    
    // Event FIFO Mode: Saving modes 0,1,4
    //      sample or extended block size is the bottom 7 downto 0
    // Event Direct Memory Mode: Saving modes 6,7
    //      sample or extended block size is the bottom 23 downto 0
    
    // the actual number of 128 bit blocks is (the sample/extended block length + 1)
    // The number of samples in this block depends on the rate (see manual)
    
    
    unsigned long addr = 0;
    unsigned short mode = [self eventSavingMode:group];

    switch (group) {
        case 0: addr = kSIS3305SampleLengthADC14;
            break;
        case 1: addr = kSIS3305SampleLengthADC58;
            break;
        default:
            addr = -1;
            break;
    }
    
    if (mode == 0 || mode == 1 || mode == 4)
    {
        if (value > 0xFF)
        {
            NSLog(@"SIS3305: The sample length value you tried to write was too large for this mode (mode %d). It will clip!!!\n",mode);
            value = 0xFF;
        }
        value = value&0xFF;        // F^2 = 7:0
    }
    
    if (mode == 6 || mode == 7)
        if (value > 0xFFFFFF)
        {
            NSLog(@"SIS3305: The sample length value you tried to write was too large for this mode (mode %d). It will clip!!!\n",mode);
            value = 0xFFFFFF;
        }
            value = value&0xFFFFFF;    // F^6 = 23:0
    
    
    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + addr
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeSampleLengths
{
    unsigned short group;
    for (group =0; group<kNumSIS3305Groups; group++) {
        [self writeSampleLengthOfGroup:group toValue:[self sampleLength:group]];
    }
}

- (unsigned long) readSamplePretriggerLengthOfGroup:(short)group
{
    // Direct Memory Stop Pretrigger Block Length Registers (0x200C, 0x300C)
    // The value read here tells us how many sample blocks are in each event, when in Direct Memory Stop (Wrap) mode (mode 7)
    // Each block is 128 bits, 4 x 32-bit, 12 samples
    // Only valid if (eventSavingMode == 7)
    // Max value is 23:0 bits
    
    unsigned long value,addr;
    
    // select the correct group's address
    switch (group) {
        case 0: addr = kSIS3305SamplePretriggerLengthADC14;
            break;
        case 1: addr = kSIS3305SamplePretriggerLengthADC58;
            break;
        default:
            addr = -1;
            break;
    }
    
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + addr
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    return value&0xFFFFFF;  // F^6 = 23:0
}

- (void) writeSamplePretriggerLengthOfGroup:(short)group toValue:(unsigned long)value
{
    // Direct Memory Stop Pretrigger Block Length Registers (0x200C, 0x300C)
    // The value read here tells us how many sample blocks are in each event, when in Direct Memory Stop (Wrap) mode (mode 7)
    // Each block is 128 bits, 4 x 32-bit, 12 samples
    // Only valid if (eventSavingMode == 7)
    // Max value is 23:0 bits
    unsigned long addr;
    
    // select the correct group's address
    switch (group) {
        case 0: addr = kSIS3305SamplePretriggerLengthADC14;
            break;
        case 1: addr = kSIS3305SamplePretriggerLengthADC58;
            break;
        default:
            addr = -1;
            break;
    }
    
    // check the size of the value is valid
    if (value != (value & 0xFFFFFF))
        NSLog(@"SIS3305: The sample pretrigger length value you tried to write was too large. This should not happen. It will clip!!!\n");
    
    value = (value & 0xFFFFFF);     // F^6 = 23:0
    
    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + addr
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
    return;
}

- (unsigned long) getRingbufferPretriggerDelayOffset:(int) aChannel
{
    // FIX: I don't think this should be used anywhere and can be deleted - actually, not true... reconsidering...
    switch (aChannel) {
        case 0: return kSIS3305RingbufferPreDelayADC12;
        case 1: return kSIS3305RingbufferPreDelayADC12;
            
        case 2: return kSIS3305RingbufferPreDelayADC34;
        case 3: return kSIS3305RingbufferPreDelayADC34;
            
        case 4: return kSIS3305RingbufferPreDelayADC56;
        case 5: return kSIS3305RingbufferPreDelayADC56;
            
        case 6: return kSIS3305RingbufferPreDelayADC78;
        case 7: return kSIS3305RingbufferPreDelayADC78;
            
        default: return 1;
    }
    return 2;
}

- (unsigned long) readRingbufferPretriggerDelayOnChannel:(short)chan
{
    // Ringbuffer Pretrigger Delay readout (0x2010, 0x2014, 0x3010, 0x3014)
    // Gives the "delay" of the pretrigger delay
    // The actual number of delayed samples will depend on the sample rate used.
    // the returned value does not convert by the sample rate, it is the "raw" value
    
    unsigned long value = 0;
    unsigned long delay = 0;

    
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + [self getRingbufferPretriggerDelayOffset:chan]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    if (chan%2 == 0)
        delay = (value & 0x3FF);
    else if (chan%2 == 1)
        delay = ((value >> 16) & 0x3FF);

    return delay;       // raw value, not converted to take into account the rate
}

//- (void) writeRingbufferPretriggerDelayOnChannel:(unsigned short)chan toValue:(unsigned long)value
//{
//    // to handle this, we need to know all of the values ahead of time (so we don't write 0 to the chan shared in the same reg)
//    // to do this, we will pull from an object ringbufferPreDelay[chan]
//    // FIX: this method needs no inputs....
//    
//    
//    unsigned long addr, writeValue, topVal, bottomVal;
//    unsigned short topChan, bottomChan;
//    
//    addr = [self getRingbufferPretriggerDelayOffset:chan];
//    chan = chan + 1; // these are referred to in a 1-index way....
//    
//    if((chan%2) == 0)     // channel number is 2,4,6,8
//    {
//        topChan     = chan - 1;
//        bottomChan  = chan;
//    }
//    else if((chan%2) == 1)     // channel number is 1,3,5,7
//    {
//        topChan     = chan;
//        bottomChan  = chan + 1;
//    }
//    else
//    {
//        NSLog(@"SIS3305: Invalid channel (%d). Pretrigger delay not written!\n", chan);
//        return;
//    }
//    
//    topVal = ringbufferPreDelay[topChan];
//    bottomVal = ringbufferPreDelay[bottomChan];
//    
//    writeValue = (topVal << 16) | (bottomVal);
//
//    
//    [[self adapter] writeLongBlock:&writeValue
//                         atAddress:[self baseAddress] + addr
//                        numToWrite:1
//                        withAddMod:[self addressModifier]
//                     usingAddSpace:0x01];
//    
//    return;
//}

- (void) writeRingbufferPretriggerDelays
{
//    unsigned short chan;
//    unsigned long delayValue;
    unsigned long writeValue[4];
    unsigned long addr;

//    for (chan = 0; chan<kNumSIS3305Channels; chan++) {
//        delayValue = [self preTriggerDelay:chan];
//        [self writeRingbufferPretriggerDelayOnChannel:chan toValue:delayValue];
//    }
//    
    unsigned short i;
    for (i = 0; i<4; i++) {
        writeValue[i] = (ringbufferPreDelay[2*i] << 16) | ringbufferPreDelay[(2*i)+1];
        addr = [self getRingbufferPretriggerDelayOffset:2*i];
        [[self adapter] writeLongBlock:&writeValue[i]
                             atAddress:[self baseAddress] + addr
                            numToWrite:1
                            withAddMod:[self addressModifier]
                         usingAddSpace:0x01];
        
        //[self writeToAddress:addr aValue:writeValue[i]];
    }
}


- (unsigned long) readMaxNumOfEventsInGroup:(short)group
{
    // (0x2018, 0x3018)
    // Gives the maximum Number of Events in each group
    
    unsigned long value = 0;
    unsigned long addr = 0;
    unsigned long events = 0;
    
    switch (group) {
        case 0:
            addr = kSIS3305MaxNofEventsADC14;
            break;
        case 1:
            addr = kSIS3305MaxNofEventsADC58;
            break;
        default:
            NSLog(@"SIS3305: Invalid group\n");
            addr = 0;
            break;
    }
    
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + addr
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];

    events = (value & 0xFFFF);

    return events;
}

- (void) writeMaxNumOfEventsInGroup:(short)group toValue:(unsigned int)maxValue
{
    // (0x2018, 0x3018)
    // Gives the maximum Number of Events in each group
    // sampling will stop when the event counter reaches the value of this register (except if 0, it will run continuously)
    
    // FIX: The default for this should be set to 0, probably (maybe).
    
    unsigned long writeValue = 0;
    unsigned long addr = 0;
 
    if (maxValue > 0xFFFF)
        maxValue = 0xFFFF;

    writeValue = maxValue;
    
    switch (group) {
        case 0:
            addr = kSIS3305MaxNofEventsADC14;
            break;
        case 1:
            addr = kSIS3305MaxNofEventsADC58;
            break;
        default:
            NSLog(@"SIS3305: Invalid group\n");
            addr = 0;
            break;
    }
    
    [[self adapter] writeLongBlock:&writeValue
                         atAddress:[self baseAddress] + addr
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}




- (unsigned long) getEndAddressThresholdRegOffsets:(int)group
{
    switch (group) {
        case 0: return 	 kSIS3305EndAddressThresholdADC14;
        case 1: return 	 kSIS3305EndAddressThresholdADC58;
    }
    return (unsigned long) -1;
}


- (unsigned long) readEndAddressThresholdOfGroup:(short)group
{
    // End Address Threshold Registers (0x201C and 0x301C)
    // There's one end address threshold per group
    
    unsigned long value;
    
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + [self getEndAddressThresholdRegOffsets:group]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    //[self setEndAddressThreshold:group withValue:value];
    
    return value;
}

- (void) writeEndAddressThresholds
{
    int i;
    for(i=0;i<kNumSIS3305Groups;i++){
        [self writeEndAddressThresholdOfGroup:i];
    }
}

- (void) writeEndAddressThresholdOfGroup:(int)group
{
    [self writeEndAddressThresholdOfGroup:group toValue:[self endAddressThreshold:group]];
}

- (void) writeEndAddressThresholdOfGroup:(short)group toValue:(unsigned long)value
{
    if(group>=0 && group<kNumSIS3305Groups){

        [[self adapter] writeLongBlock:&value
                             atAddress:[self baseAddress] + [self getEndAddressThresholdRegOffsets:group]
                            numToWrite:1
                            withAddMod:[self addressModifier]
                         usingAddSpace:0x01];
    }
}



- (unsigned long) getGTThresholdRegOffsets:(int) channel
{
    //    "Greater than"-threshold registers
    switch (channel) {
        case 0: return 	kSIS3305TriggerGateGTThresholdsADC1;
        case 1: return 	kSIS3305TriggerGateGTThresholdsADC2;
        case 2: return 	kSIS3305TriggerGateGTThresholdsADC3;
        case 3: return 	kSIS3305TriggerGateGTThresholdsADC4;
        case 4:	return 	kSIS3305TriggerGateGTThresholdsADC5;
        case 5: return 	kSIS3305TriggerGateGTThresholdsADC6;
        case 6: return 	kSIS3305TriggerGateGTThresholdsADC7;
        case 7: return 	kSIS3305TriggerGateGTThresholdsADC8;
    }
    return (unsigned long) -1;
}

- (unsigned long) getLTThresholdRegOffsets:(int) channel
{
    //  "Less than"-threshold registers
    switch (channel) {
        case 0: return 	kSIS3305TriggerGateLTThresholdsADC1;
        case 1: return 	kSIS3305TriggerGateLTThresholdsADC2;
        case 2: return 	kSIS3305TriggerGateLTThresholdsADC3;
        case 3: return 	kSIS3305TriggerGateLTThresholdsADC4;
        case 4:	return 	kSIS3305TriggerGateLTThresholdsADC5;
        case 5: return 	kSIS3305TriggerGateLTThresholdsADC6;
        case 6: return 	kSIS3305TriggerGateLTThresholdsADC7;
        case 7: return 	kSIS3305TriggerGateLTThresholdsADC8;
    }
    return (unsigned long) -1;
}



- (unsigned long) readLTThresholdOnChannel:(short)chan
{
    unsigned long aValue;
    [[self adapter] readLongBlock: &aValue
                        atAddress: [self baseAddress] + [self getLTThresholdRegOffsets:chan]
                        numToRead: 1
                       withAddMod: [self addressModifier]
                    usingAddSpace: 0x01];
    return aValue;
}




- (void) readLTThresholds:(BOOL)verbose
{
    int i;
    unsigned long aValue;
    
    if(verbose) NSLog(@"Reading LT Thresholds:\n");
    
    for(i =0; i < kNumSIS3305Channels; i++) {
        aValue = [self readLTThresholdOnChannel:i];
        
        if(verbose){
            unsigned short onThresh     = (aValue & 0x3FF);
            unsigned short offThresh    = ((aValue>>16) & 0x3FF);
            BOOL triggerModeLT          = (aValue>>31) & 0x1;
            
            NSLog(@"%d: %2s On:0x%04x Off:0x%04x\n",
                  i,
                  triggerModeLT   ? "LT enabled"            : "LT disabled" ,
                  onThresh,
                  offThresh);
        }
    }
}

- (unsigned long) readGTThresholdOnChannel:(short)chan
{
    unsigned long aValue;
    [[self adapter] readLongBlock: &aValue
                        atAddress: [self baseAddress] + [self getGTThresholdRegOffsets:chan]
                        numToRead: 1
                       withAddMod: [self addressModifier]
                    usingAddSpace: 0x01];
    return aValue;
}


- (void) readGTThresholds:(BOOL)verbose
{
    int i;
    unsigned long aValue;
    
    if(verbose) NSLog(@"Reading GT Thresholds:\n");
    
    for(i =0; i < kNumSIS3305Channels; i++) {
        aValue = [self readGTThresholdOnChannel:i];
        
        if(verbose){
            unsigned short onThresh = (aValue       & 0x3FF);
            unsigned short offThresh= ((aValue>>16) & 0x3FF);
            
            BOOL triggerModeGT    = (aValue>>31) & 0x1;
            //              NSLog(@"%d: %8s %2s 0x%4x\n",
            NSLog(@"%d: %2s On:0x%04x Off:0x%04x\n",
                  i,
                  triggerModeGT   ? "GT enabled"            : "GT disabled" ,
                  onThresh,
                  offThresh);
        }
    }
}

- (void) readThresholds:(BOOL)verbose
{
    [self readLTThresholds:verbose];
    [self readGTThresholds:verbose];
    
    return;
}



- (void) writeThresholds
{
    [self writeLTThresholds];
    [self writeGTThresholds];
}

- (void) writeLTThresholds
{
//    ORCommandList* aList = [ORCommandList commandList];
    int i;
    unsigned long thresholdMask;
    unsigned long onThresh;
    unsigned long offThresh;
    unsigned long LTEnabled;
    for(i = 0; i < kNumSIS3305Channels; i++)
    {
        
        onThresh = [self LTThresholdOn:i];
        offThresh = [self LTThresholdOff:i];
        LTEnabled = [self LTThresholdEnabled:i];
        
        thresholdMask = 0;
        thresholdMask |= (onThresh   & 0x3ff)    <<0;
        thresholdMask |= (offThresh  & 0x3ff)    <<16;
        thresholdMask |= (LTEnabled  &0x1)      <<31;
        
        [[self adapter] writeLongBlock: &thresholdMask
                                                       atAddress: [self baseAddress] + [self getLTThresholdRegOffsets:i]
                                                      numToWrite: 1
                                                      withAddMod: [self addressModifier]
                                                   usingAddSpace: 0x01];
    }
}

- (void) writeGTThresholds
{
    int i;
    unsigned long thresholdMask;
    for(i = 0; i < kNumSIS3305Channels; i++)
    {
        
        thresholdMask = 0;
        thresholdMask |= ([self GTThresholdOn:i]    & 0x3ff)    <<0;
        thresholdMask |= ([self GTThresholdOff:i]   & 0x3ff)    <<16;
        thresholdMask |= ([self GTThresholdEnabled:i]&0x1)      <<31;
        
        [[self adapter] writeLongBlock: &thresholdMask
                                                       atAddress: [self baseAddress] + [self getGTThresholdRegOffsets:i]
                                                      numToWrite: 1
                                                      withAddMod: [self addressModifier]
                                                   usingAddSpace: 0x01];
    }
}

- (unsigned long) getSamplingStatusAddressForGroup:(short)group
{
    switch (group) {
        case 0:
            return kSIS3305SamplingStatusRegADC14;
        case 1:
            return kSIS3305SamplingStatusRegADC58;
        default:
            NSLog(@" Invalid group number\n");
            return 0;
    }
}

- (unsigned long) readSamplingStatusForGroup:(short)group
{
    unsigned long value = 0;

    [[self adapter] readLongBlock: &value
                        atAddress: [self baseAddress] + [self getSamplingStatusAddressForGroup:group]
                        numToRead: 1
                       withAddMod: [self addressModifier]
                    usingAddSpace: 0x01];
    return value;
}



- (unsigned long) readActualSampleAddress:(short)group
{
    // Reads the address of the sample in group `group`
    
    unsigned long addr;
    unsigned long value;
    
    switch (group) {
        case 0:
            addr = kSIS3305ActualSampleAddressADC14;
            break;
        case 1:
            addr = kSIS3305ActualSampleAddressADC58;
            break;
        default:
            addr = 0;
            NSLog(@" Invalid group number\n");
            return 0;
            break;
    }
    
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + addr
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];

    value = (value & 0xFFFFFF);     // sample memory address is 23:0
    return value;
}


- (unsigned long) readDirectMemoryEventCounterOfGroup:(short)group
{
    // Reads the counter of group `group`
    
    unsigned long addr;
    unsigned long value;
    
    switch (group) {
        case 0:
            addr = kSIS3305DirectMemoryEventCounterADC14;
            break;
        case 1:
            addr = kSIS3305DirectMemoryEventCounterADC58;
            break;
        default:
            addr = 0;
            NSLog(@" Invalid group number\n");
            return 0;
            break;
    }
    
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + addr
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    value = (value & 0xFFFF);     // sample memory address is 15:0
    return value;
}


- (unsigned long) readDirectMemoryActualEventStartAddressOfGroup:(short)group
{
    // Reads the counter of group `group`
    
    unsigned long addr;
    unsigned long value;
    
    switch (group) {
        case 0:
            addr = kSIS3305DirectMemoryActualEventStartAddressADC14;
            break;
        case 1:
            addr = kSIS3305DirectMemoryActualEventStartAddressADC58;
            break;
        default:
            addr = 0;
            NSLog(@" Invalid group number\n");
            return 0;
            break;
    }
    
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + addr
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    value = (value & 0xFFFFFF);     // sample memory address is 23:0
    return value;
}


- (unsigned long) readActualSampleValueOfChannel:(short)chan
{
    // Reads the sample value from the ADC on-the-fly.
    // Not sure what this is used for.
    
    unsigned long addr;
    unsigned long value, topValue, bottomValue;
    
    if (    chan == 0 || chan == 1)
        addr = kSIS3305ActualSampleValueADC12;
    else if(chan == 2 || chan == 3)
        addr = kSIS3305ActualSampleValueADC34;
    else if(chan == 4 || chan == 5)
        addr = kSIS3305ActualSampleValueADC56;
    else if(chan == 6 || chan == 7)
        addr = kSIS3305ActualSampleValueADC78;
    else{
        addr = 0;
        NSLog(@" Invalid channel number\n");
        return 0;
    }
    
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + addr
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    bottomValue = (value & 0x3FF);
    topValue = (value >> 16) & 0x3FF;
    
    if (chan%2 == 0)    // chan = 2,4,6,8
        return bottomValue;
    if (chan%2 == 1)
        return topValue;

    return 0;
}

- (unsigned long) getIndividualChannelSelectSeVetoAddressOfGroup:(unsigned short)group
{
    if (    group == 0 )
        return kSIS3305IndividualSelectSetVetoADC14;
    else if(group == 1)
        return kSIS3305IndividualSelectSetVetoADC58;
    else{
        NSLog(@" Invalid group number\n");
        return 0;
    }
}

- (unsigned long) readIndividualChannelSelectSetVetoOfGroup:(unsigned short)group
{
    unsigned long value;

    
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + [self getIndividualChannelSelectSeVetoAddressOfGroup:group]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return value;
}

- (void) writeIndividualChannelSelectSetVetoOfGroup:(unsigned short)group withValue:(unsigned long)value
{

    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + [self getIndividualChannelSelectSeVetoAddressOfGroup:group]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (unsigned long) getADCTapDelayOffsets:(int)group
{
    switch (group) {
        case 0: return kSIS3305ADCInputTapDelayADC14;
        case 1: return kSIS3305ADCInputTapDelayADC58;
        default: return 0;
    }
    return (unsigned long) -1;
}

- (unsigned long) readADCInputTapDelayOfGroup:(unsigned short)group
{
    unsigned long value;
    
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + [self getADCTapDelayOffsets:group]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return value;
}

- (void) writeADCInputTapDelayOfGroup:(unsigned short)group toValue:(unsigned long)value
{
    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + [self getADCTapDelayOffsets:group]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}


- (void) writeTapDelays
{
    //    SIS3305_ADC_INPUT_TAP_DELAY
    /*
     This is to set up the Tap Delays on each ADC channel. These adjust the ADC-FPGA data strobe timing.
     These can be written
     
     [5:0]   Tap delay value (x78 ps)
     [7:6]   Unused
     [8]     ADC 1 Select
     [9]     ADC 2 select
     [10]    ADC 3 select
     [11]    ADC 4 select
     [31-12] unused
     
     */
    
    ORCommandList* aList = [ORCommandList commandList];
    unsigned long aValueMask = 0;
    
    short group = 0;
    short channel = 0;
    short adc = 0;
    
    for(group=0; group<kNumSIS3305Groups; group++)
    {
        for(adc = 0; adc < (kNumSIS3305Channels/kNumSIS3305Groups); adc++)
        {
            channel = (group+1)*(adc+1);        // get the channel for a given ADC of a given group
            
            aValueMask = 0;
            aValueMask |=   (tapDelay[channel] & 0x3F);
            aValueMask |=   (1<<(adc+8));
            
            
            [aList addCommand: [ORVmeReadWriteCommand writeLongBlock: &aValueMask
                                                           atAddress: [self baseAddress] + [self getADCTapDelayOffsets:group]
                                                          numToWrite: 1
                                                          withAddMod: [self addressModifier]
                                                       usingAddSpace: 0x01]];
            
        }
    }
    
    [self executeCommandList:aList];
    NSLog(@"SIS3305 Tap Delays Written\n");
    return;
    
}

- (unsigned long) getFIFOAddressOfGroup:(unsigned short)group
{
    switch (group) {
        case 0:
            return kSIS3305Space1ADCDataFIFOCh14;
            break;
        case 1:
            return kSIS3305Space1ADCDataFIFOCh58;
            break;
        default:
            NSLog(@"Invalid group to getFIFOAddress\n");
            return 0;
            break;
    }
}


#pragma mark -Working point


- (void) regDump
{
    @try {
        NSFont* font = [NSFont fontWithName:@"Monaco" size:11];
        NSLogFont(font,@"Reg Dump for SIS3305 (Slot %d)\n",[self slot]);
        NSLogFont(font,@"-----------------------------------\n");
        NSLogFont(font,@"[Add Offset]   Value        Name\n");
        NSLogFont(font,@"-----------------------------------\n");
        
        ORCommandList* aList = [ORCommandList commandList];
        int i;
        for(i=0;i<kNumSIS3305ReadRegs;i++){
            [aList addCommand: [ORVmeReadWriteCommand readLongBlockAtAddress: [self baseAddress] + register_information[i].offset
                                                                   numToRead: 1
                                                                  withAddMod: [self addressModifier]
                                                               usingAddSpace: 0x01]];
        }
        [self executeCommandList:aList];
        
        //if we get here, the results can retrieved in the same order as sent
        for(i=0;i<kNumSIS3305ReadRegs;i++){
            NSLogFont(font, @"[0x%08x] 0x%08x    %@\n",register_information[i].offset,[aList longValueForCmd:i],register_information[i].name);
        }
        
    }
    @catch(NSException* localException) {
        NSLog(@"SIS3305 Reg Dump FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nSIS3305 Reg Dump FAILED", @"OK", nil, nil,
                        localException);
    }
}

- (void) briefReport
{
    NSLog(@"Brief Report\n");

    [self readThresholds:YES];
    //	[self readHighThresholds:YES];
    [self readAcquisitionControl:YES];
    
    unsigned long eventConfig = 0;
    [[self adapter] readLongBlock:&eventConfig
                        atAddress:[self baseAddress] + kSIS3305EventConfigADC14
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    NSLog(@"EventConfig: 0x%08x\n",eventConfig);
    
    //	unsigned long pretrigger = 0;
    //	[[self adapter] readLongBlock:&pretrigger
    //						atAddress:[self baseAddress] + kSIS3305PreTriggerDelayTriggerGateLengthAdc14
    //						numToRead:1
    //					   withAddMod:[self addressModifier]
    //					usingAddSpace:0x01];
    //
    //	NSLog(@"pretrigger: 0x%08x\n",pretrigger);
    

    
    unsigned long actualNextSampleAddress1 = 0;
    [[self adapter] readLongBlock:&actualNextSampleAddress1
                        atAddress:[self baseAddress] + kSIS3305ActualSampleAddressADC14
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    NSLog(@"actualNextSampleAddress1: 0x%08x\n",actualNextSampleAddress1);
    
    unsigned long actualNextSampleAddress2 = 0;
    [[self adapter] readLongBlock:&actualNextSampleAddress2
                        atAddress:[self baseAddress] + kSIS3305ActualSampleAddressADC58
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    NSLog(@"actualNextSampleAddress2: 0x%08x\n",actualNextSampleAddress2);
    

}





#pragma mark Write



- (void) executeCommandList:(ORCommandList*) aList
{
	[[self adapter] executeCommandList:aList];
}

- (void) initBoard
{  
//	[self calculateSampleValues];
    [self readTemperature:NO];
	[self readModuleID:NO];
	[self writeEventConfiguration];
	[self writeEndAddressThresholds];

	[self writeThresholds];
    
    [self writeADCControlReg];              // set up the bandwidth, channel mode etc.

    if([self writeGainPhaseOffsetEnabled])
    {
        [self writeADCOffsets];
        [self writeADCGains];
        [self writeADCPhase];
    }
    else
        NSLogColor([NSColor redColor], @"Not writing the ADC Gain/Offset/Phase!\n");

    

	[self writeAcquisitionControl];			// set up the Acquisition Register
    [self writeControlStatus];              // set all the control status reg at once
    [self writeLEMOTriggerOutSelect];
    
    [self writeRingbufferPretriggerDelays];
    
//    [self disarmAndArmBank:0];

	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305CardInited object:self];
	
}

- (BOOL) isEvent
{
	unsigned long data_rd = 0;
	[[self adapter] readLongBlock:&data_rd
						atAddress:[self baseAddress] + kSIS3305AcquisitionControl
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
//	uint32_t bankMask = bankOneArmed?0x10000:0x20000;
//	return ((data_rd & 0x80000) == 0x80000) && ((data_rd & bankMask) == bankMask);
    
    // return yes if either group has reached the end address threshold?
    return (data_rd & 0x800000) | (data_rd & 0x400000);
}


- (NSString*) runSummary
{
    NSString* summary;
    //	if(runMode == kMcaRunMode){
    //		return @"MCA Spectrum";
    //	}
    //	else {
//    BOOL tracesShipped = ([self sampleLength:0] || [self sampleLength:1]);
    summary = @"";
    summary = [summary stringByAppendingString:@"Traces"];
    summary = [summary stringByAppendingString:@"\n"];
//    if(shipSummedWaveform) summary = [summary stringByAppendingString:@" + Summed Raw Trace"];
//    summary = [summary stringByAppendingString:@"\n"];
    
    summary = [summary stringByAppendingFormat:@"Traces 0:%ld  1:%ld \n", 3*[self longsInSample:0],3*[self longsInSample:1]];
    
//    if(shipSummedWaveform) summary = [summary stringByAppendingFormat:@"Summed Raw Trace: 510 values\n"];
    return summary;
//    	}
}

- (void) writeHistogramParams
{
    //	unsigned long aValue =   kSIS3305McaEnable2468 | kSIS3305McaEnable1357 | ((mcaPileupEnabled << 3) + mcaHistoSize);
    //	[[self adapter] writeLongBlock:&aValue
    //						 atAddress:[self baseAddress] + kSIS3305McaHistogramParamAllAdc
    //						numToWrite:1
    //						withAddMod:[self addressModifier]
    //					 usingAddSpace:0x01];	
}


#pragma mark - Data Taker

- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId   = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	NSDictionary* aDictionary;
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORSIS3305DecoderForWaveform",	@"decoder",
				   [NSNumber numberWithLong:dataId],@"dataId",
				   [NSNumber numberWithBool:YES],   @"variable",
				   [NSNumber numberWithLong:-1],	@"length",
				   nil];
    [dataDictionary setObject:aDictionary forKey:@"Waveform"];
	
    return dataDictionary;
}

//- (unsigned short) getChannelfromEventID:(unsigned short)eventID andGroup:(unsigned short)group
//{
//    // This method is incomplete! It does not account for all event IDs / modes
//    // Instead, it is expected that the analyst will determine the channel number after, to speed the data taking.
//    
////    unsigned short channel;
////    unsigned short eventMode = [self eventSavingMode:group];
////    unsigned short chanMode = [self channelMode:group];
//    
//    
////    if(eventID < 8)
//        return kchannelModeAndEventID[ channelMode[group] ][ eventID ] + group<<2;
//    
////    if ((chanMode >> 2) == 0)                   // 4-channel modes
////        channel = (4*group) + (eventID & 0x3);
////
////    else if ((chanMode >> 2) == 0x02)           // 1-channel modes
////        channel = (4*group) + (eventID & 0x3);
////    
////    else if ((chanMode >> 2) == 0x03)           // common input modes
////        channel = (4*group) + (eventID & 0x3);
////    
////    // the harder case...
////    else if ((chanMode >> 2) == 0x01)           // 2-channel modes
////        channel = (chanMode >> ((eventID>>1) & 0x1))&0x1 + ((chanMode >> ((eventID>>1) & 0x1))&0x1)<<2 + group<<2;
////    else
////        channel = 0xF;  // error!
//    
//
//    
////    return channel;
//
//    /*
//    switch (chanMode) {
//        case 0x0:
//        case 0x1:
//        case 0x2:
//        case 0x3:// 4-channel event FIFO Mode, 1.25 GSPS. Event ID is channel here (modulo group)
//            channel = eventID+(4*group);
//            break;
//        case 0x4:// 2-channel A and C enabled at 2.5 gsps
//            if (eventMode == 1) {
//                if(eventID == 4)
//                    channel = 1 + (4*group); // 1 or 5 (ADC1 or ADC2)
//                else if (eventID == 5)
//                    channel = 3 +(4*group); // 3 or 7
//                else{// Nothing else should be possible!
//                    channel = 0xFF;
//                    NSLog(@"Error, event ID  %d shouldn't be possible here!",eventID);
//                }
//            }
//            else{
//                channel = 0xFF;
//                NSLog(@"Error, only Event Saving Mode 1 should be possible for two channel mode! Your data taking setup should not be allowed!\n");
//            }
//            break;
//        case 0x5: // 2-channel B and C enabled at 2.5 Gsps
//            if (eventMode == 1) // 2-ch event FIFO mode
//            {
//                if(eventID == 4)        // A or B (but must be B here)
//                    channel = 2 + (4*group);        // 2 or 6 (ADC1 or ADC2)
//                else if (eventID == 5)  // C or D (but must be C here)
//                    channel = 3 +(4*group);         // 3 or 7
//                else{// Nothing else should be possible!
//                    channel = 0xFF;
//                    NSLog(@"Error, event ID  %d shouldn't be possible here!",eventID);
//                }
//            }
//            else{
//                channel = 0xFF;
//                NSLog(@"Error, only Event Saving Mode 1 should be possible for two channel mode! Your data taking setup should not be allowed!\n");
//            }
//            break;
//        case 0x6:   // 2-channel A and D enabled at 2.5 Gsps
//            if (eventMode == 1) // 2-ch event FIFO mode
//            {
//                if(eventID == 4)        // A or B (but must be A here)
//                    channel = 0 + (4*group);        // 2 or 6 (ADC1 or ADC2)
//                else if (eventID == 5)  // C or D (but must be D here)
//                    channel = 4 +(4*group);         // 3 or 7
//                else{// Nothing else should be possible!
//                    channel = 0xFF;
//                    NSLog(@"Error, event ID  %d shouldn't be possible here!",eventID);
//                }
//            }
//            else{
//                channel = 0xFF;
//                NSLog(@"Error, only Event Saving Mode 1 should be possible for two channel mode! Your data taking setup should not be allowed!\n");}
//            // FIX: This doesn't allow for most of the possible event modes. This is not at all a completed method!!!
//            break;
//            
//            
//        default:
//            channel = 0xFF;
//            break;
//    }
//    */
//    
//}


- (unsigned short) digitizationRate:(unsigned short) group
{
    // Returns an indication of the digitization rate for a given group:
    //      0: 1.25 Ghz
    //      1: 2.5 Gsps
    //      2: 5 Gsps
    
    unsigned short chanMode = [self channelMode:group];
    unsigned short speed = chanMode >> 2;               // this is just a coincidence, but it is basically true
    
    switch (speed) {
        case 0x0:   // 4-channel event FIFO Mode, 1.25 GSPS. Event ID is channel here (modulo group)
            return 0;
        case 0x1:   // 2 channel 2.5 Gsps mode
            return 1;
        case 0x2:   // One channel 5 Gsps mode
            return 2;
        case 0x3:   // Common input mode, which is some kind of 1.25 Gsps mode.
            return 0;
        default:
            NSLog(@"Rate unknown! Error...");
            return 0xFF;
            break;
    }
}

- (unsigned long) longsInSample:(unsigned short)group
{
    // the number of longs in a sample will depend on the event saving mode and the rate of digitization
    // (as well as obviously the sample size)
//    unsigned short savingMode = [self eventSavingMode:group];

    // Sample length is number of 128-bit (4-word) blocks minus 1.
    // Higher sample rates interlace between 
    unsigned long value;
    unsigned long multiplier;
    
    unsigned long sampleLength = [self sampleLength:group];     // number of 128-bit blocks minus 1
    unsigned short rate = [self digitizationRate:group];
    // 'rate' carries a value of one of the following:
    //      0: 1.25 Ghz
    //      1: 2.5 Gsps
    //      2: 5 Gsps
    multiplier = (rate+1)*4;
    value = (sampleLength+1) * multiplier;
    
    return value;
}


#pragma mark - HW Wizard
-(BOOL) hasParmetersToRamp
{
	return YES;
}
- (int) numberOfChannels
{
    return kNumSIS3305Channels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
  	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Run Mode"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setRunMode:) getMethod:@selector(runMode)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Extra Time Record"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setShipTimeRecordAlso:) getMethod:@selector(shipTimeRecordAlso)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"LTThresholdEnabled"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setLTThresholdEnabled:withValue:) getMethod:@selector(LTThresholdEnabled:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"GTThresholdEnabled"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setGTThresholdEnabled:withValue:) getMethod:@selector(GTThresholdEnabled:)];
    [a addObject:p];

	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Input Inverted"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setInputInverted:withValue:) getMethod:@selector(inputInverted:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Buffer Wrap Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setBufferWrapEnabled:withValue:) getMethod:@selector(bufferWrapEnabled:)];
    [a addObject:p];
	
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Internal Trigger Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setInternalTriggerEnabled:toValue:) getMethod:@selector(internalTriggerEnabled:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"External Trigger Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setExternalTriggerEnabled:withValue:) getMethod:@selector(externalTriggerEnabled:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Internal Gate Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setInternalGateEnabled:withValue:) getMethod:@selector(internalGateEnabled:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"External Gate Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setExternalGateEnabled:withValue:) getMethod:@selector(externalGateEnabled:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Clock Source"];
    [p setFormat:@"##0" upperLimit:7 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setClockSource:) getMethod:@selector(clockSource)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
	
//    p = [[[ORHWWizParam alloc] init] autorelease];
//    [p setName:@"Threshold"];
//    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:1 units:@""];
//    [p setSetMethod:@selector(setThreshold:withValue:) getMethod:@selector(threshold:)];
//	[p setCanBeRamped:YES];
//    [a addObject:p];
	
//    p = [[[ORHWWizParam alloc] init] autorelease];
//    [p setName:@"CFD"];
//    [p setFormat:@"##0" upperLimit:0x2 lowerLimit:0 stepSize:1 units:@"Index"];
//    [p setSetMethod:@selector(setCfdControl:withValue:) getMethod:@selector(cfdControl:)];
//    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Gate Length"];
    [p setFormat:@"##0" upperLimit:0x3f lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setGateLength:withValue:) getMethod:@selector(gateLength:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Pulse Length"];
    [p setFormat:@"##0" upperLimit:0xff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPulseLength:withValue:) getMethod:@selector(pulseLength:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Dac Offset"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setDacOffset:withValue:) getMethod:@selector(dacOffset:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"InternalTriggerDelay"];
    [p setFormat:@"##0" upperLimit:(firmwareVersion<15?63:255) lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setInternalTriggerDelay:withValue:) getMethod:@selector(internalTriggerDelay:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Sample Length"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:4 stepSize:1 units:@""];
    [p setSetMethod:@selector(setSampleLength:withValue:) getMethod:@selector(sampleLength:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Pretrigger Delay"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:1 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPreTriggerDelay:withValue:) getMethod:@selector(preTriggerDelay:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trigger Gate Length"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setTriggerGateLength:withValue:) getMethod:@selector(triggerGateLength:)];
    [a addObject:p];
	


	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Init"];
    [p setSetMethodSelector:@selector(initBoard)];
    [a addObject:p];
    
    return a;
}


- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORVmeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:@"ORSIS3305Model"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORSIS3305Model"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
	if([param isEqualToString:@"Threshold"])						return [[cardDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel];
//	else if([param isEqualToString:@"highThreshold"])				return [[cardDictionary objectForKey:@"highThresholds"] objectAtIndex:aChannel];
//	else if([param isEqualToString:@"CFD"])							return [[cardDictionary objectForKey:@"cfdControls"] objectAtIndex:aChannel];
	else if([param isEqualToString:@"GateLength"])					return [[cardDictionary objectForKey:@"gateLengths"] objectAtIndex:aChannel];
	else if([param isEqualToString:@"PulseLength"])					return [[cardDictionary objectForKey:@"pulseLengths"] objectAtIndex:aChannel];
	else if([param isEqualToString:@"InternalTriggerDelay"])		return [[cardDictionary objectForKey:@"internalTriggerDelays"] objectAtIndex:aChannel];
	else if([param isEqualToString:@"Dac Offset"])					return [[cardDictionary objectForKey:@"dacOffsets"] objectAtIndex:aChannel];
	else if([param isEqualToString:@"TriggerDecimation"])			return [cardDictionary objectForKey:@"triggerDecimation"];
	else if([param isEqualToString:@"EnergyDecimation"])			return [cardDictionary objectForKey:@"energyDecimation"];
    else if([param isEqualToString:@"Clock Source"])				return [cardDictionary objectForKey:@"clockSource"];
    else if([param isEqualToString:@"Run Mode"])					return [cardDictionary objectForKey:@"runMode"];
    else if([param isEqualToString:@"Extra Time Record"])			return [cardDictionary objectForKey:@"shipTimeRecordAlso"];
    else if([param isEqualToString:@"GT"])							return [cardDictionary objectForKey:@"gtMask"];
    else if([param isEqualToString:@"Input Inverted"])				return [cardDictionary objectForKey:@"inputInvertedMask"];
    else if([param isEqualToString:@"Buffer Wrap Enabled"])			return [cardDictionary objectForKey:@"bufferWrapEnabledMask"];
    else if([param isEqualToString:@"Internal Trigger Enabled"])	return [cardDictionary objectForKey:@"internalTriggerEnabledMask"];
    else if([param isEqualToString:@"External Trigger Enabled"])	return [cardDictionary objectForKey:@"externalTriggerEnabledMask"];
    else if([param isEqualToString:@"Internal Gate Enabled"])		return [cardDictionary objectForKey:@"internalGateEnabledMask"];
    else if([param isEqualToString:@"External Gate Enabled"])		return [cardDictionary objectForKey:@"externalGateEnabledMask"];
    else if([param isEqualToString:@"Trigger Decimation"])			return [cardDictionary objectForKey:@"triggerDecimation"];
    else if([param isEqualToString:@"Energy Decimation"])			return [cardDictionary objectForKey:@"energyDecimation"];
    else if([param isEqualToString:@"Energy Tau Factor"])			return [cardDictionary objectForKey:@"energyTauFactor"];
    else if([param isEqualToString:@"Energy Sample Length"])		return [cardDictionary objectForKey:@"energySampleLength"];
    else if([param isEqualToString:@"Energy Gap Time"])				return [cardDictionary objectForKey:@"energyGapTime"];
    else if([param isEqualToString:@"Trigger Gate Delay"])			return [cardDictionary objectForKey:@"triggerGateLength"];
    else if([param isEqualToString:@"Pretrigger Delay"])			return [cardDictionary objectForKey:@"preTriggerDelay"];
    else if([param isEqualToString:@"Sample Length"])				return [cardDictionary objectForKey:@"sampleLength"];
	
	else return nil;
}

#pragma mark - DataTaking
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORSIS3305"];    
    
    //cache some stuff
    location        = (([self crateNumber]&0x0000000f)<<21) | (([self slot]& 0x0000001f)<<16);
    theController   = [self adapter];
    
    
    /*
     
        From struck example code we should:
     1. Reset the module
            This is handled by the reset method
     
     2. Define/set the ADC clock
            Set to internal or external clock (clock source)
            This is in the acquisition register [self writeAcquisitionRegister] but can be handled just by [self writeClockSource]
     
     3. ADC synch reset 
            There is a key register for this (SIS3305_ADC_SYNCH_PULSE, 0x430)
     
     4. Set ADC data FPGA input delay configuration
            This should only be needed the first time, but probably doesn't hurt to keep doing
            SIS3305_ADC_Input_TapDelay_Setup method in SIS documentation
            [self writeTapDelays];
            
     5. ADC Chips configuration via SPI
            SIS3305_ADC_SPI_Setup
            [self writeADCSerialInterface]
     
     6. Trigger configuration
            this probably means setting trigger mode, and thresholds???
     
     7. Everything...?
        7a. Control Reg
                LED application mode
                Enable External LEMO direct veto in
                enable external LEMO reset in
                enable external LEMO count in
                Enable external LEMO trigger in
                Invert ecternal LEMO direct veto in
                Enable external LEMO veto delay/length logic
                E
                [self writeControlReg], done in initboard
     
        7b. LEMO out selection
                - probably not essential
        7c. Interrupt configuration
                - probably not essential
        7d. Broadcast config
                - probably not essential
        7d. Acquisition reg config
                only the clock source and TDC measure enabled
                [self writeAcquisitionRegister]
     
     8. SampleStartMemoryAddress
                get the start address
     
     9. SampleLength
                will just depend on the readout mode
     
     9. AddressThreshold
            "Memory end address threshold"
     
     10. RingbufferPreDelay
            needs to be set for each channel
     
     11. Event Configuration Registers
            [self writeEventConfiguration]

     12. TDC config
     
     
     Then initialize program paramters
     
     Then start sampling -> readout loop
     
     */
    
	[self reset];
	[self initBoard];
    
    [self writeClockSource:NO];
    [self ADCSynchReset];
    [self writeTapDelays];
    [self writeADCControlReg];
    
    [self writeThresholds];
    [self writeControlStatus];  // actually done already in initBoard
    [self writeAcquisitionControl];
    
    // FIX: this is a hack
    [self writeSampleStartAddressOfGroup:0 toValue:0];
    [self writeSampleStartAddressOfGroup:1 toValue:0];
    
    // could write sample start address, but it will always be zero?
    [self writeSampleLengths];
    
    // FIX: Should this actually write to    [self writeMaxNumOfEventsInGroup:<#(short)#> toValue:<#(unsigned int)#>] ?
    int group;
    for (group =0; group<kNumSIS3305Groups; group++) {
        eventLengthLongWords[group]     = 2 + [self sampleLength:group];
        [self setEndAddressThreshold:group withValue:1];    //maxEvents*eventLengthLongWords[group]];
    }
    
    [self writeEndAddressThresholds];
    [self writeRingbufferPretriggerDelays];
    [self writeEventConfiguration];
    //    [self sampleStartIndex:1];
    
//    [self writeLedApplicationMode];
//    [self writeLed:1 to:YES];
//	[self clearTimeStamp];

    
	firstTime	= YES;

    isRunning	= NO;
	count=0;
	wrapMaskForRun = bufferWrapEnabledMask;
    [self startRates];
	
    groupToRead = 0;

}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	//reading events from the mac is very, very slow. If the buffer is filling up, it can take a long time to readout all events.
	//Because of this we limit the number of events from any one buffer read. The SBC should be used if possible.
    @try {
        if(firstTime){
            isRunning = YES;
            firstTime = NO;
        
            [self enableSampleLogic];
            [self pulseExternalTriggerOut];     // this may or may not be desired
            
//           [self armSampleLogic];
           
        }
        else {
            /*
            bool DMStopped = NO;
            while (!DMStopped)   // while direct memory is not stopped, keep waiting for the direct memory to stop
            {
                ac = [self readAcquisitionControl:NO];
                pollcount++;
                if(pollcount%1000 == 0){
                    NSLog(@"Polling for direct memory stopped flag... \n");
                }
                if(pollcount%100000 == 0){
                    NSLog(@"Not triggering????");
                    return;
                }
                DMStopped = (ac & 0x20000000);
            }
            */
            
            unsigned long ac        = [self readAcquisitionControl:NO];
            BOOL endAddThreshFlag   = ((ac>>19)&0x1)?YES:NO;
            if (endAddThreshFlag == NO) return;
            
            //if we get here, there may be something to read out

            [self disarmSampleLogic]; //can't readout while sampling
            
            // read now all Sample Addresses
            // prepare readout statemachines
            // Transfer Control ch1to4, start internal readout (copy from Memory to VME FPGA)
            // Transfer Control ch5to8, start internal readout (copy from Memory to VME FPGA)
            [self writeDataTransferControlRegister:0 withCommand:2 withAddress:0];  // read command
            [self writeDataTransferControlRegister:1 withCommand:2 withAddress:0];  // read command


            unsigned long adcBufferLength = 0x10000000; // 256 MLWorte ; 1G Mbyte MByte (from sis3305_global.h:440)
            
            unsigned short gr;
            for (gr =0; gr<2; gr++) {
                unsigned long numberOfWords     = [self readActualSampleAddress:gr] * 16;        // 1 block == 64 bytes == 16 Lwords
                unsigned long numberBytesToRead = numberOfWords * 4;
                
                // we can only readout at max one full buffer at once
                if (numberOfWords > adcBufferLength) {
                    numberOfWords = adcBufferLength;
                }
                
                if(numberBytesToRead > 0){ // if there is data to read out, we'll compute handy things and read it out
                    BOOL wrapMode = (wrapMaskForRun & (1L<<gr))!=0;

                    unsigned long sisHeaderLength   = 4;  // 4 long words in the normal sis headers
                    unsigned long orcaHeaderLength  = 4;   // 3 words in the Orca header
                    unsigned long dataRecordLength  = sisHeaderLength  + [self longsInSample:gr]; //just the data length in longs
                    
                    unsigned long maxBytesForSBC = 1024*1024*1; //2 MB max SBC packet size, we limit to 1 here for safety
                    unsigned long actualBytesToBeRead = (numberBytesToRead%64) + numberBytesToRead;
                    unsigned short numEventsInBuffer = actualBytesToBeRead/(dataRecordLength*sizeof(unsigned long));
                    unsigned long bytesOfData = sizeof(unsigned long)*(numEventsInBuffer*dataRecordLength);
                    
                    unsigned long bufferAddLongs = (orcaHeaderLength + bytesOfData/4); //(numEventsInBuffer*dataRecordLength)); // num longs to add to the data stream

//                    unsigned long maxReadBuffer = 1024*1024*1; // limit it to 1 MB (actually can take 2)
                    
                    unsigned long dataRecord[bufferAddLongs+8];
                    
                    // here we start filling the data record:
                    
                    dataRecord[0] = dataId | bufferAddLongs;
                    
                    dataRecord[1] =	(([self crateNumber]                & 0xF) << 28)   |
                                    (([self slot]                       & 0x1F)<< 20)   |
                                    (([self channelMode:groupToRead]    & 0xF) << 16)   |
                                    ((gr                                & 0x1) << 12)   |
                                    (([self digitizationRate:groupToRead] & 0xF) << 8)    |
                                    (([self eventSavingMode:groupToRead]  & 0xF) << 4)    |
                                    (wrapMode                           & 0x1);
                    
                    dataRecord[2] = dataRecordLength;               // length of single record 1 x (SIS header + SIS data)
                    
                    dataRecord[3] = (numEventsInBuffer & 0xFFFF) |    // number of events expected in the event
                                    ((0 & 0xFFFF) << 16);  //
                    
                    unsigned long bytesLeftToRead = actualBytesToBeRead;
                    unsigned long bytesToReadNow;
                    unsigned long currentIndex = 4;
                    unsigned short eventCount = 0;
                    while (bytesLeftToRead > 0)
                    {
                        if (bytesLeftToRead > maxBytesForSBC) {
                            NSLog(@"Separating 0x%x bytes into more than 1 read\n",bytesLeftToRead);
                            bytesToReadNow = maxBytesForSBC;
                        }
                        else
                            bytesToReadNow = bytesLeftToRead + (bytesLeftToRead%4);
                        
//                        
                        [[self adapter] readLongBlock: &dataRecord[currentIndex]
                                            atAddress: [self baseAddress] + [self getFIFOAddressOfGroup:gr]
                                            numToRead: bytesToReadNow/4
                                           withAddMod: [self addressModifier]
                                        usingAddSpace: 0x01];
                        
                        // could read one at a time instead of as a block.... no real difference
//                        [theController readLong:&dataRecord[currentIndex]
//                                      atAddress:[self baseAddress] + [self getFIFOAddressOfGroup:gr]
//                                    timesToRead:bytesToReadNow/4
//                                     withAddMod:[self addressModifier]
//                                  usingAddSpace:0x01];
                        
                        currentIndex += bytesToReadNow/4;
                        bytesLeftToRead -= bytesToReadNow;
                        if(++eventCount > 25)break;
                    }
                    
                    [aDataPacket addLongsToFrameBuffer:dataRecord length:bufferAddLongs];
                    dataRecord[0] = 0xA;
                }
            } // loop over groups
            
            // after reading out everything:
            [self writeRingbufferPretriggerDelays]; // if in maintenance mode you can change this in realtime
            
            // key arm/enable again
            [self enableSampleLogic];
            [self armSampleLogic];
            
        }   // End if: not first time
	}   // end TRY
	@catch(NSException* localException) {
		[self incExceptionCount];
		[localException raise];
	}
}


- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	isRunning = NO;
	
//	if(runMode == kMcaRunMode){
//		unsigned long mcaLength;
//		switch (mcaHistoSize) {
//			case 0:  mcaLength = 1024; break;
//			case 1:  mcaLength = 2048; break;
//			case 2:  mcaLength = 4096; break;
//			case 3:  mcaLength = 8192; break;
//			default: mcaLength = 2048; break;
//		}
//		unsigned long pageOffset = 0x0;
//		if(mcaScanBank2Flag) pageOffset = 8 * 0x1024 * 0x1024;
		
//		int channel;
//		for(channel=0;channel<kNumSIS3305Channels;channel++){
//			if(gtMask & (1<<channel)){
////				NSMutableData* mcaData = [NSMutableData dataWithLength:(mcaLength + 2)*sizeof(long)];
//				unsigned long* mcaBytes = (unsigned long*)[mcaData bytes];
//				mcaBytes[0] = mcaId | (mcaLength+2);
//				mcaBytes[1] =	(([self crateNumber]&0x0000000f)<<21) | 
//								(([self slot] & 0x0000001f)<<16)      |
//								((channel & 0x000000ff)<<8);
//				
//				[[self adapter] readLongBlock: &mcaBytes[2]
//									atAddress: [self baseAddress] + [self getADCBufferRegisterOffset:channel] + pageOffset
//									numToRead: mcaLength
//								   withAddMod: [self addressModifier]
//								usingAddSpace: 0x01];
//				[aDataPacket addData:mcaData];
//			}
//		}
//	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
//	if(runMode == kMcaRunMode){	
//		unsigned long aValue = 0;
//		[[self adapter] writeLongBlock:&aValue
//							 atAddress:[self baseAddress] + kSIS3305KeyMcaMultiScanDisable
//							numToWrite:1
//							withAddMod:[self addressModifier]
//						 usingAddSpace:0x01];	
//		
//		[[self adapter] writeLongBlock:&aValue
//							 atAddress:[self baseAddress] + kSIS3305KeyMcaScanStop
//							numToWrite:1
//							withAddMod:[self addressModifier]
//						 usingAddSpace:0x01];	
//		
//		[self readMcaStatus];
//	}
	
//	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollMcaStatus) object:nil];
	
	[self disarmSampleLogic];
    [waveFormRateGroup stop];
    //[self setLed:1 to:NO];
	
//	int group;
//	for(group=0;group<kNumSIS3305Groups;group++){
//		if(dataRecord){
//			free(dataRecord);
//			dataRecord = nil;
//		}
//	}
	
}

//this is the data structure for the new SBCs (i.e. VX704 from Concurrent)
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{

		configStruct->total_cards++;
		configStruct->card_info[index].hw_type_id				= kSIS3305; //should be unique
		configStruct->card_info[index].hw_mask[0]				= dataId;	//better be unique
		configStruct->card_info[index].slot						= [self slot];
		configStruct->card_info[index].crate					= [self crateNumber];
		configStruct->card_info[index].add_mod					= [self addressModifier];
		configStruct->card_info[index].base_add					= [self baseAddress];
        
        configStruct->card_info[index].deviceSpecificData[0]    = [self longsInSample:0];
        configStruct->card_info[index].deviceSpecificData[1]    = [self longsInSample:1];
        
        configStruct->card_info[index].deviceSpecificData[2]    = [self channelMode:0];
        configStruct->card_info[index].deviceSpecificData[3]    = [self channelMode:1];

        configStruct->card_info[index].deviceSpecificData[4]    = [self digitizationRate:0];
        configStruct->card_info[index].deviceSpecificData[5]    = [self digitizationRate:1];
        
        configStruct->card_info[index].deviceSpecificData[6]    = [self eventSavingMode:0];
        configStruct->card_info[index].deviceSpecificData[7]    = [self eventSavingMode:1];
        
//		configStruct->card_info[index].deviceSpecificData[0]	= [self sampleLength:0]/2;
//		configStruct->card_info[index].deviceSpecificData[1]	= [self sampleLength:1]/2;
//		configStruct->card_info[index].deviceSpecificData[2]	= [self sampleLength:2]/2;
//		configStruct->card_info[index].deviceSpecificData[3]	= [self sampleLength:3]/2;
////		configStruct->card_info[index].deviceSpecificData[4]	= [self energySampleLength];
//		configStruct->card_info[index].deviceSpecificData[5]	= [self bufferWrapEnabledMask];
//		configStruct->card_info[index].deviceSpecificData[6]	= [self pulseMode];
		
		configStruct->card_info[index].num_Trigger_Indexes		= 0;
		
		configStruct->card_info[index].next_Card_Index 	= index+1;	
		
		return index+1;

}



//- (void) resetSamplingLogic
//{
// 	unsigned long aValue = 0; //value doesn't matter 
//	[[self adapter] writeLongBlock:&aValue
//                         atAddress:[self baseAddress] + kSIS3305KeySampleLogicReset
//                        numToWrite:1
//                        withAddMod:[self addressModifier]
//                     usingAddSpace:0x01];
//}

- (BOOL) bumpRateFromDecodeStage:(short)channel
{
    if(isRunning)return NO;
    
    ++waveFormCount[channel];
    return YES;
}

- (unsigned long) waveFormCount:(int)aChannel
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
    for(i=0;i<kNumSIS3305Channels;i++){
        waveFormCount[i]=0;
    }
}

#pragma mark - Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    /*
        These are all the parameters that are saved when a configuration file is saved
     */
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
	
    [self setPulseMode:                 [decoder decodeBoolForKey:@"pulseMode"]];
    [self setFirmwareVersion:			[decoder decodeFloatForKey:@"firmwareVersion"]];
    [self setShipTimeRecordAlso:		[decoder decodeBoolForKey:@"shipTimeRecordAlso"]];
	
    [self setRunMode:					[decoder decodeIntForKey:@"runMode"]];
    [self setInternalExternalTriggersOred:[decoder decodeBoolForKey:@"internalExternalTriggersOred"]];
    [self setLemoInEnabledMask:			[decoder decodeIntForKey:@"lemoInEnabledMask"]];
    
    [self setLemoInMode:				[decoder decodeIntForKey:@"lemoInMode"]];
    [self setLemoOutMode:				[decoder decodeIntForKey:@"lemoOutMode"]];
	
    [self setClockSource:				[decoder decodeIntForKey:@"clockSource"]];
    [self setTriggerOutEnabledMask:		[decoder decodeInt32ForKey:@"triggerOutEnabledMask"]];

    [self setInputInvertedMask:			[decoder decodeInt32ForKey:@"inputInvertedMask"]];
    
    int i;
    for (i=0; i<kNumSIS3305Groups; i++) {
        [self setEventSavingModeOf:i            toValue:[decoder decodeInt32ForKey:[@"eventSavingMode" stringByAppendingFormat:@"%d",i]]];

        [self setGlobalTriggerEnabledOnGroup:i toValue:[decoder decodeInt32ForKey:[@"globalTriggerEnabled" stringByAppendingFormat:@"%d",i]]];
        [self setInternalTriggerEnabled:i toValue:[decoder decodeInt32ForKey:[@"internalTriggerEnabled" stringByAppendingFormat:@"%d",i]]];
        [self setStartEventSamplingWithExtTrigEnabled:i toValue:[decoder decodeInt32ForKey:[@"startSamplingAfterFirstExternalTrigger" stringByAppendingFormat:@"%d",i]]];
        [self setClearTimestampWhenSamplingEnabledEnabled:i toValue:[decoder decodeInt32ForKey:[@"clearTimestampWhenSamplingEnabledEnabled" stringByAppendingFormat:@"%d",i]]];
        [self setClearTimestampDisabled:i toValue:[decoder decodeInt32ForKey:[@"clearTimestampDisabled" stringByAppendingFormat:@"%d",i]]];
        [self setWaitPreTrigTimeBeforeDirectMemTrig:i toValue:[decoder decodeInt32ForKey:[@"waitPreTrigTimeBeforeDirectMemTrig" stringByAppendingFormat:@"%d",i]]];
        [self setDirectMemoryHeaderDisabled:i toValue:[decoder decodeInt32ForKey:[@"directMemoryHeaderDisabled" stringByAppendingFormat:@"%d",i]]];
        
        
        [self setGrayCodeEnabled:i toValue:[decoder decodeInt32ForKey:[@"grayCodeEnabled" stringByAppendingFormat:@"%d",i]]];
        [self setADCGateModeEnabled:i toValue:[decoder decodeInt32ForKey:[@"ADCGateModeEnabled" stringByAppendingFormat:@"%d",i]]];
        [self setBandwidth:i withValue:[decoder decodeInt32ForKey:[@"bandwidth" stringByAppendingFormat:@"%d",i]]];
        
        [self setTestMode:i withValue:[decoder decodeInt32ForKey:[@"testMode" stringByAppendingFormat:@"%d",i]]];
        [self setChannelMode:i withValue:[decoder decodeInt32ForKey:[@"channelMode" stringByAppendingFormat:@"%d",i]]];
    }
    
    [self setExternalTriggerEnabledMask:[decoder decodeInt32ForKey:@"externalTriggerEnabledMask"]];
    [self setInternalGateEnabledMask:	[decoder decodeInt32ForKey:@"internalGateEnabledMask"]];
    [self setExternalGateEnabledMask:	[decoder decodeInt32ForKey:@"externalGateEnabledMask"]];
    
//	[self setShipSummedWaveform:		[decoder decodeBoolForKey:@"shipSummedWaveform"]];
    [self setWaveFormRateGroup:			[decoder decodeObjectForKey:@"waveFormRateGroup"]];
	
    // becauase these are set up as c-arrays, we have to step through them
    int chan;
    for (chan = 0; chan<kNumSIS3305Channels; chan++)
    {
        //threshold mode can't be set directly, since we store the individual LT ang GT enabled with the encoder
        [self setLTThresholdEnabled:chan    withValue:[decoder decodeIntForKey:[@"LTThresholdEnabled"	    stringByAppendingFormat:@"%d",chan]]];
        [self setGTThresholdEnabled:chan    withValue:[decoder decodeIntForKey:[@"GTThresholdEnabled"	    stringByAppendingFormat:@"%d",chan]]];
        [self setLTThresholdOn:chan         withValue:[decoder decodeIntForKey:[@"LTThresholdOn"            stringByAppendingFormat:@"%d",chan]]];
        [self setLTThresholdOff:chan        withValue:[decoder decodeIntForKey:[@"LTThresholdOff"           stringByAppendingFormat:@"%d",chan]]];
        [self setGTThresholdOn:chan         withValue:[decoder decodeIntForKey:[@"GTThresholdOn"            stringByAppendingFormat:@"%d",chan]]];
        [self setGTThresholdOff:chan        withValue:[decoder decodeIntForKey:[@"GTThresholdOff"           stringByAppendingFormat:@"%d",chan]]];

        [self setPreTriggerDelay:chan       withValue:[decoder decodeIntForKey:[@"preTriggerDelay"          stringByAppendingFormat:@"%d",chan]]];
        [self setAdcOffset:chan             toValue:[decoder decodeIntForKey:[@"adcOffset"                  stringByAppendingFormat:@"%d",chan]]];
        [self setAdcGain:chan               toValue:[decoder decodeIntForKey:[@"adcGain"                    stringByAppendingFormat:@"%d",chan]]];
        [self setAdcPhase:chan              toValue:[decoder decodeIntForKey:[@"adcPhase"                   stringByAppendingFormat:@"%d",chan]]];
        
    }
    
    sampleLengths = 			[[decoder decodeObjectForKey:@"sampleLengths"]retain];
	thresholds  =				[[decoder decodeObjectForKey:@"thresholds"] retain];
//	highThresholds =			[[decoder decodeObjectForKey:@"highThresholds"] retain];
    dacOffsets  =				[[decoder decodeObjectForKey:@"dacOffsets"] retain];
	gateLengths =				[[decoder decodeObjectForKey:@"gateLengths"] retain];
	pulseLengths =				[[decoder decodeObjectForKey:@"pulseLengths"] retain];
	internalTriggerDelays =		[[decoder decodeObjectForKey:@"internalTriggerDelays"] retain];
    triggerGateLengths =		[[decoder decodeObjectForKey:@"triggerGateLengths"] retain];
    sampleStartIndexes =		[[decoder decodeObjectForKey:@"sampleStartIndexes"] retain];

	
	//force a constraint check by reloading the pretrigger delays
	int aGroup;
	for(aGroup=0;aGroup<kNumSIS3305Groups;aGroup++){
		[self setPreTriggerDelay:aGroup withValue:[self preTriggerDelay:aGroup]];
	}

    
	//firmware 15xx
//    cfdControls =					[[decoder decodeObjectForKey:@"cfdControls"] retain];
    [self setBufferWrapEnabledMask:	[decoder decodeInt32ForKey:@"bufferWrapEnabledMask"]];
	
	if(!waveFormRateGroup){
		[self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:kNumSIS3305Channels groupTag:0] autorelease]];
	    [waveFormRateGroup setIntegrationTime:5];
    }
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];
	
	[self setUpArrays];
	
	
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    /*
        This takes all the things that have been initialized in initWithCoder and writes values to them
        This should be called when a configuration is saved.
    */
    [super encodeWithCoder:encoder];
	
	[encoder encodeBool:pulseMode               forKey:@"pulseMode"];
	[encoder encodeFloat:firmwareVersion		forKey:@"firmwareVersion"];
	[encoder encodeBool:shipTimeRecordAlso		forKey:@"shipTimeRecordAlso"];
	
    //channel-level c-arrays:
    int chan;
    for (chan=0; chan<kNumSIS3305Channels; chan++) {
        [encoder encodeInt:LTThresholdEnabled[chan]		forKey:[@"LTThresholdEnabled"	stringByAppendingFormat:@"%d",chan]];
        [encoder encodeInt:GTThresholdEnabled[chan]		forKey:[@"GTThresholdEnabled"	stringByAppendingFormat:@"%d",chan]];
        [encoder encodeInt:LTThresholdOn[chan]          forKey:[@"LTThresholdOn"		stringByAppendingFormat:@"%d",chan]];
        [encoder encodeInt:LTThresholdOff[chan]         forKey:[@"LTThresholdOff"		stringByAppendingFormat:@"%d",chan]];
        [encoder encodeInt:GTThresholdOn[chan]          forKey:[@"GTThresholdOn"		stringByAppendingFormat:@"%d",chan]];
        [encoder encodeInt:GTThresholdOff[chan]         forKey:[@"GTThresholdOff"		stringByAppendingFormat:@"%d",chan]];
        
        [encoder encodeInt:gain[chan]                   forKey:[@"Gain"                 stringByAppendingFormat:@"%d",chan]];
        [encoder encodeInt:ringbufferPreDelay[chan]       forKey:[@"preTriggerDelay"      stringByAppendingFormat:@"%d",chan]];
        
        
        [encoder encodeInt:adcOffset[chan]              forKey:[@"adcOffset"            stringByAppendingFormat:@"%d",chan]];
        [encoder encodeInt:adcGain[chan]                forKey:[@"adcGain"              stringByAppendingFormat:@"%d",chan]];
        [encoder encodeInt:adcPhase[chan]               forKey:[@"adcPhase"             stringByAppendingFormat:@"%d",chan]];

    }
    int i;
    for (i=0; i<kNumSIS3305Groups; i++) {
        [encoder encodeInt:eventSavingMode[i]         forKey:[@"eventSavingMode" stringByAppendingFormat:@"%d",i]];
        
        [encoder encodeInt:globalTriggerEnabled[i] forKey:[@"globalTriggerEnabled" stringByAppendingFormat:@"%d",i]];
        [encoder encodeInt:internalTriggerEnabled[i] forKey:[@"internalTriggerEnabled" stringByAppendingFormat:@"%d",i]];
        [encoder encodeInt:startEventSamplingWithExtTrigEnabled[i] forKey:[@"startSamplingAfterFirstExternalTrigger" stringByAppendingFormat:@"%d",i]];
        [encoder encodeInt:clearTimestampWhenSamplingEnabledEnabled[i] forKey:[@"clearTimestampWhenSamplingEnabledEnabled" stringByAppendingFormat:@"%d",i]];
        [encoder encodeInt:clearTimestampDisabled[i]  forKey:[@"clearTimestampDisabled" stringByAppendingFormat:@"%d",i]];
        [encoder encodeInt:waitPreTrigTimeBeforeDirectMemTrig[i]  forKey:[@"waitPreTrigTimeBeforeDirectMemTrig" stringByAppendingFormat:@"%d",i]];
        [encoder encodeInt:directMemoryHeaderDisabled[i]  forKey:[@"directMemoryHeaderDisabled" stringByAppendingFormat:@"%d",i]];
        [encoder encodeInt:grayCodeEnabled[i] forKey:[@"grayCodeEnabled" stringByAppendingFormat:@"%d",i]];
        [encoder encodeInt:ADCGateModeEnabled[i] forKey:[@"ADCGateModeEnabled" stringByAppendingFormat:@"%d",i]];
        [encoder encodeInt:bandwidth[i] forKey:[@"bandwidth" stringByAppendingFormat:@"%d",i]];
        [encoder encodeInt:testMode[i] forKey:[@"testMode" stringByAppendingFormat:@"%d",i]];
        [encoder encodeInt:channelMode[i] forKey:[@"channelMode" stringByAppendingFormat:@"%d",i]];
    }
    
    [encoder encodeInt:runMode					forKey:@"runMode"];
    [encoder encodeInt:clockSource				forKey:@"clockSource"];
	[encoder encodeInt:lemoInEnabledMask		forKey:@"lemoInEnabledMask"];
	[encoder encodeInt:lemoInMode				forKey:@"lemoInMode"];
	[encoder encodeInt:lemoOutMode				forKey:@"lemoOutMode"];
	
	[encoder encodeBool:internalExternalTriggersOred	forKey:@"internalExternalTriggersOred"];
	[encoder encodeInt32:triggerOutEnabledMask			forKey:@"triggerOutEnabledMask"];
	[encoder encodeInt32:inputInvertedMask				forKey:@"inputInvertedMask"];
	[encoder encodeInt32:internalTriggerEnabledMask		forKey:@"internalTriggerEnabledMask"];
	[encoder encodeInt32:externalTriggerEnabledMask		forKey:@"externalTriggerEnabledMask"];
	[encoder encodeInt32:internalGateEnabledMask		forKey:@"internalGateEnabledMask"];
	[encoder encodeInt32:externalGateEnabledMask		forKey:@"externalGateEnabledMask"];
	

    [encoder encodeObject:waveFormRateGroup		forKey:@"waveFormRateGroup"];
	[encoder encodeObject:sampleLengths			forKey:@"sampleLengths"];
	[encoder encodeObject:thresholds			forKey:@"thresholds"];
	[encoder encodeObject:dacOffsets			forKey:@"dacOffsets"];
	[encoder encodeObject:gateLengths			forKey:@"gateLengths"];
	[encoder encodeObject:pulseLengths			forKey:@"pulseLengths"];
	[encoder encodeObject:internalTriggerDelays	forKey:@"internalTriggerDelays"];
	[encoder encodeObject:triggerGateLengths	forKey:@"triggerGateLengths"];
	[encoder encodeObject:sampleStartIndexes	forKey:@"sampleStartIndexes"];
	//firmware 15xx
    [encoder encodeInt32:bufferWrapEnabledMask	forKey:@"bufferWrapEnabledMask"];

	
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    /* 
        This dictionary is what gets written to the header of each run data file.
        The parameters must be included below for the values to show up there.
     */
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	
    [objDictionary setObject: [NSNumber numberWithLong:LTThresholdEnabled]			forKey:@"LTThresholdEnabled"];
    [objDictionary setObject: [NSNumber numberWithLong:GTThresholdEnabled]			forKey:@"GTThresholdEnabled"];
	[objDictionary setObject: [NSNumber numberWithInt:clockSource]					forKey:@"clockSource"];

	[objDictionary setObject: [NSNumber numberWithLong:triggerOutEnabledMask]		forKey:@"triggerOutEnabledMask"];
	[objDictionary setObject: [NSNumber numberWithLong:inputInvertedMask]			forKey:@"inputInvertedMask"];
	[objDictionary setObject: [NSNumber numberWithLong:internalTriggerEnabledMask]	forKey:@"internalTriggerEnabledMask"];
	[objDictionary setObject: [NSNumber numberWithLong:externalTriggerEnabledMask]	forKey:@"externalTriggerEnabledMask"];
	[objDictionary setObject: [NSNumber numberWithLong:internalGateEnabledMask]		forKey:@"internalGateEnabledMask"];
	[objDictionary setObject: [NSNumber numberWithLong:externalGateEnabledMask]		forKey:@"externalGateEnabledMask"];
 	
	[objDictionary setObject:[NSNumber numberWithInt:runMode]						forKey:@"runMode"];
	[objDictionary setObject:[NSNumber numberWithInt:shipTimeRecordAlso]			forKey:@"shipTimeRecordAlso"];
	
	[objDictionary setObject:[NSNumber numberWithInt:lemoInEnabledMask]				forKey:@"lemoInEnabledMask"];
	[objDictionary setObject:[NSNumber numberWithInt:lemoInMode]					forKey:@"lemoInMode"];
	[objDictionary setObject:[NSNumber numberWithInt:lemoOutMode]					forKey:@"lemoOutMode"];
//	[objDictionary setObject:[NSNumber numberWithBool:shipSummedWaveform]			forKey:@"shipSummedWaveform"];
	[objDictionary setObject:[NSNumber numberWithBool:internalExternalTriggersOred]	forKey:@"internalExternalTriggersOred"];
	[objDictionary setObject:[NSNumber numberWithBool:pulseMode]					forKey:@"pulseMode"];
	
	[objDictionary setObject: internalTriggerDelays	forKey:@"internalTriggerDelays"];	

	[objDictionary setObject: sampleLengths		forKey:@"sampleLengths"];
	[objDictionary setObject: dacOffsets		forKey:@"dacOffsets"];
    [objDictionary setObject: thresholds		forKey:@"thresholds"];	
    [objDictionary setObject: gateLengths		forKey:@"gateLengths"];	
    [objDictionary setObject: pulseLengths		forKey:@"pulseLengths"];	
	[objDictionary setObject: triggerGateLengths	forKey:@"triggerGateLengths"];
	[objDictionary setObject: sampleStartIndexes	forKey:@"sampleStartIndexes"];
	
    // not sure if this is the right way to add this
    // group level parameters for those stored as c-arrays
    int i = 0;
    for (i=0; i<kNumSIS3305Groups; i++) {
        [objDictionary setObject:[NSNumber numberWithInteger:eventSavingMode[i]] forKey:[@"eventSavingMode" stringByAppendingFormat:@"%d",i]];
    }
    
    // channel level params for those stored as c-arrays
    for (i=0; i<kNumSIS3305Channels; i++) {
        [objDictionary setObject:[NSNumber numberWithInteger:ringbufferPreDelay[i]]		forKey:[@"preTriggerDelays" stringByAppendingFormat:@"%d",i]];

        [objDictionary setObject:[NSNumber numberWithInteger:adcGain[i]]		forKey:[@"adcGain" stringByAppendingFormat:@"%d",i]];
        [objDictionary setObject:[NSNumber numberWithInteger:adcPhase[i]]		forKey:[@"adcPhase" stringByAppendingFormat:@"%d",i]];
        [objDictionary setObject:[NSNumber numberWithInteger:adcOffset[i]]		forKey:[@"adcOffset" stringByAppendingFormat:@"%d",i]];
        
    }
    
	[objDictionary setObject: [NSNumber numberWithLong:bufferWrapEnabledMask]		forKey:@"bufferWrapEnabledMask"];
	
    return objDictionary;
}

- (NSArray*) autoTests 
{
	NSMutableArray* myTests = [NSMutableArray array];
	[myTests addObject:[ORVmeReadOnlyTest test:kSIS3305AcquisitionControl wordSize:4 name:@"Acquistion Reg"]];
	[myTests addObject:[ORVmeWriteOnlyTest test:kSIS3305KeyReset wordSize:4 name:@"Reset"]];
	//TO DO.. add more tests
	
//	int i;
//	for(i=0;i<kNumSIS3305Channels;i++){
//		[myTests addObject:[ORVmeReadWriteTest test:[self getThresholdRegOffsets:i] wordSize:4 validMask:0x1ffff name:@"Threshold"]];
//	}
	return myTests;
}

//ORAdcInfoProviding protocol requirement
//- (void) postAdcInfoProvidingValueChanged
//{
//	[[NSNotificationCenter defaultCenter]
//	 postNotificationName:ORAdcInfoProvidingValueChanged
//	 object:self
//	 userInfo: nil];
//}
//for adcProvidingProtocol... but not used for now
- (unsigned long) eventCount:(int)channel
{
	return 0;
}
- (void) clearEventCounts
{
}

// for adcProvidingProtocol, unused for now
- (unsigned long) thresholdForDisplay:(unsigned short) aChan
{
	return [self GTThresholdOn:aChan];
}

- (unsigned short) gainForDisplay:(unsigned short) aChan
{
	return [self gain:aChan];
}
@end

@implementation ORSIS3305Model (private)
- (NSMutableArray*) arrayOfLength:(int)len
{
	int i;
	NSMutableArray* anArray = [NSMutableArray arrayWithCapacity:kNumSIS3305Channels];
	for(i=0;i<len;i++)[anArray addObject:[NSNumber numberWithInt:0]];
	return anArray;
}

- (void) setUpArrays
{
    /*
        This method allocates memory to these arrays, in case they haven't been allocated yet. 
        Should be called by initWithCoder
     */
	if(!thresholds)				thresholds			  = [[self arrayOfLength:kNumSIS3305Channels] retain];
//	if(!highThresholds)			highThresholds			  = [[self arrayOfLength:kNumSIS3305Channels] retain];
	if(!dacOffsets)				dacOffsets			  = [[self arrayOfLength:kNumSIS3305Channels] retain];
	if(!gateLengths)			gateLengths			  = [[self arrayOfLength:kNumSIS3305Channels] retain];
	if(!pulseLengths)			pulseLengths		  = [[self arrayOfLength:kNumSIS3305Channels] retain];
	if(!internalTriggerDelays)	internalTriggerDelays = [[self arrayOfLength:kNumSIS3305Channels] retain];
//	if(!cfdControls)			cfdControls		      = [[self arrayOfLength:kNumSIS3305Channels] retain];
    
    if(!triggerGateLengths)	triggerGateLengths	= [[self arrayOfLength:kNumSIS3305Channels] retain];
	
	if(!sampleLengths)		sampleLengths		= [[self arrayOfLength:kNumSIS3305Groups] retain];

	if(!sampleStartIndexes)	sampleStartIndexes	= [[self arrayOfLength:kNumSIS3305Groups] retain];
	if(!endAddressThresholds)endAddressThresholds	= [[self arrayOfLength:kNumSIS3305Groups] retain];
	
	if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:kNumSIS3305Channels groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }
	
}

//- (void) writeDacOffsets
//{
//	
//	unsigned int max_timeout, timeout_cnt;
//	
//	int i;
//	for (i=0;i<kNumSIS3305Channels;i++) {
//		unsigned long data =  [self dacOffset:i];
//		unsigned long addr = [self baseAddress] + kSIS3305DacData  ;
//		
//		// Set the Data in the DAC Register
//		[[self adapter] writeLongBlock:&data
//							 atAddress:addr
//							numToWrite:1
//							withAddMod:addressModifier
//						 usingAddSpace:0x01];
//		
//		
//		data =  1 + (i << 4); // write to DAC Register
//		addr = [self baseAddress] + kSIS3305DacControlStatus  ;
//		// Tell card to set the DAC shift Register
//		[[self adapter] writeLongBlock:&data
//							 atAddress:addr
//							numToWrite:1
//							withAddMod:addressModifier
//						 usingAddSpace:0x01];
//		
//		max_timeout = 5000 ;
//		timeout_cnt = 0 ;
//		addr = [self baseAddress] + kSIS3305DacControlStatus  ;
//		// Wait until done.
//		do {
//			[[self adapter] readLongBlock:&data
//								atAddress:addr
//								numToRead:1
//							   withAddMod:addressModifier
//							usingAddSpace:0x01];
//			
//			timeout_cnt++;
//		} while ( ((data & 0x8000) == 0x8000) && (timeout_cnt <  max_timeout) )    ;
//		
//		if (timeout_cnt >=  max_timeout) {
//			NSLog(@"%@ Failed programing the DAC offset for channel %d\n",[self fullID],i); 
//			return;
//		}
//		
//		[[self adapter] writeLongBlock:&data
//							 atAddress:addr
//							numToWrite:1
//							withAddMod:addressModifier
//						 usingAddSpace:0x01];
//		
//		
//		data =  2 + (i << 4); // Load DACs 
//		addr = [self baseAddress] + kSIS3305DacControlStatus  ;
//		[[self adapter] writeLongBlock:&data
//							 atAddress:addr
//							numToWrite:1
//							withAddMod:addressModifier
//						 usingAddSpace:0x01];
//		
//		timeout_cnt = 0 ;
//		addr = [self baseAddress] + kSIS3305DacControlStatus  ;
//		do {
//			[[self adapter] readLongBlock:&data
//								atAddress:addr
//								numToRead:1
//							   withAddMod:addressModifier
//							usingAddSpace:0x01];
//			timeout_cnt++;
//		} while ( ((data & 0x8000) == 0x8000) && (timeout_cnt <  max_timeout) )    ;
//		
//		if (timeout_cnt >=  max_timeout) {
//			NSLog(@"%@ Failed programing the DAC offset for channel %d\n",[self fullID],i); 
//			return;
//		}
//	}
//}

//- (void) pollMcaStatus
//{
//	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollMcaStatus) object:nil];
//	if([gOrcaGlobals runInProgress]){
//		[self readMcaStatus];
//		[self performSelector:@selector(pollMcaStatus) withObject:self afterDelay:2];
//	}
//}

@end
