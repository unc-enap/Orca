//-------------------------------------------------------------------------
//  ORSIS3305RegisterDefs.h
//
//  Created by Sam Meijer on Wednesday 11/24/09.
//  Copyright (c) 2009 University of North Carolina. All rights reserved.
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

#pragma mark - General Card Properties
#define kNumSIS3305Channels	8 
#define kNumSIS3305Groups	2 
#define kNumSIS3305ReadRegs 96


#define kMcaRunMode			0
#define kEnergyRunMode		1

#define kSISLed1            0x0001L
#define kSISLed2            0x0002L
#define kSISLed3            0x0003L

//#define kSIS3305MaxEnergyWaveform	510


//** These come from the example SIS code
#define kSIS3305_HEADER_EVENT_ID_1_25G_ADC1				0x00000000
#define kSIS3305_HEADER_EVENT_ID_1_25G_ADC2				0x10000000
#define kSIS3305_HEADER_EVENT_ID_1_25G_ADC3				0x20000000
#define kSIS3305_HEADER_EVENT_ID_1_25G_ADC4				0x30000000
#define kSIS3305_HEADER_EVENT_ID_2_5G_ADC12				0x40000000
#define kSIS3305_HEADER_EVENT_ID_2_5G_ADC34				0x50000000
#define kSIS3305_HEADER_EVENT_ID_5G_ADC1234				0x70000000
#define kSIS3305_HEADER_EVENT_ID_TDC					0x80000000

#define kSIS3305_HEADER_EVENT_ID_DIRECT_MEMORY_START	0xC0000000	  // add 1.2.2011
#define kSIS3305_HEADER_EVENT_ID_DIRECT_MEMORY_STOP		0xD0000000	  // add 1.2.2011

#define kSIS3305_HEADER_EVENT_ID_MASK					0xf0000000
#define kSIS3305_HEADER_EVENT_ID_END_MARKER				0xF0000000
//**


#define CSRMask(state,A) ((state)?(A):(A<<16))
#define tempRawToC(value) ((float)((signed short)(value))) / 4 // method described in manual...





// Config addresses
#pragma mark - Config Registers

#define kSIS3305ControlStatus                       0x0	  /* read/write; D32 */
#define kSIS3305ModID                               0x4	  /* read only; D32 */
#define kSIS3305IrqConfig                           0x8      /* read/write; D32 */
#define kSIS3305IrqControl                          0xC      /* read/write; D32 */

#define kSIS3305AcquisitionControl                  0x10      /* read/write; D32 */
#define kSIS3305VetoLength                          0x14    /* read/write */
#define kSIS3305VetoDelayLength                     0x18    /* read/write */

#define kSIS3305EEPROMControl                       0x28    /* read/write D32 */
#define kSIS3305OneWireControlReg                   0x2C    /* read/write D32 */

#define kSIS3305CbltBroadcastSetup                  0x30    /* read/write; D32 */
#define kSIS3305TriggerOutSelectReg                 0x40    /* read/write D32 */
#define kSIS3305ExternalTriggerCounter              0x4C    /* read/write D32 */

#define kSIS3305TDCWriteCmdReg                      0x50    /* read/write D32 */
#define kSIS3305TDCReadCmdReg                       0x54    /* read/write D32 */
#define kSIS3305TDCStartStopEnableReg               0x58    /* read/write D32 */
#define kSIS3305TDCFSMReg4ValueReg                  0x5C    /* read/write D32 */

#define kSIS3305XilinxJTAGTest                      0x60    /* read only D32, the same as JTAG Data In*/
#define kSIS3305XilinxJTAGDataIn                    0x60    /* write only D32, the same as JTAG Test */

#define kSIS3305InternalTemperatureReg              0x70    /* read/write D32 */

#define kSIS3305ADCSerialInterfaceReg               0x74    /* read/write D32 */

#define kSIS3305DataTransferADC14CtrlReg            0xC0    /* read/write D32 */
#define kSIS3305DataTransferADC58CtrlReg            0xC4    /* read/write D32 */
#define kSIS3305DataTransferADC14StatusReg          0xC8    /* read D32 */
#define kSIS3305DataTransferADC58StatusReg          0xCC    /* read D32 */

#define kSIS3305VmeFpgaAuroraProtStatus             0xD0    /* read/write D32 */
#define kSIS3305VmeFpgaAuroraDataStatus             0xD4    /* read/write D32 */


// Key Addresses
#pragma mark - Key Addresses

#define kSIS3305KeyReset                            0x400	/* write only; D32 */
#define kSIS3305KeyArmSampleLogic                   0x410   /* write only; D32 */
#define kSIS3305KeyDisarmSampleLogic                0x414   /* write only, D32 */
#define kSIS3305KeyTrigger                          0x418	/* write only; D32 */
#define kSIS3305KeyEnableSampleLogic                0x41C   /* write only; D32 */
#define kSIS3305KeySetVeto                          0x420   /* write only; D32 */
#define kSIS3305KeyClrVeto                          0x424	/* write only; D32 */
#define kSIS3305ADCSynchPulse                       0x430   /* write only D32 */
#define kSIS3305ADCFpgaReset                        0x434   /* write only D32 */
#define kSIS3305ADCExternalTriggerOutPulse          0x43C   /* write only D32 */


#pragma mark - Event Configuration Registers
#define kSIS3305EventConfigADC14                    0x2000  /* read/write */
#define kSIS3305EventConfigADC58                    0x3000  /* read/write */


#pragma mark - Sample Memory Start Address Registers
#define kSIS3305SampleStartAddressADC14             0x2004
#define kSIS3305SampleStartAddressADC58             0x3004

#pragma mark - Sample/Extended Block Length Registers
#define kSIS3305SampleLengthADC14                   0x2008
#define kSIS3305SampleLengthADC58                   0x3008

#pragma mark - Direct Memory Stop Pretrigger Block Length Registers
#define kSIS3305SamplePretriggerLengthADC14         0x200C
#define kSIS3305SamplePretriggerLengthADC58         0x300C

#pragma mark - Ringbuffer Pretrigger delay register
#define kSIS3305RingbufferPreDelayADC12             0x2010
#define kSIS3305RingbufferPreDelayADC34             0x2014
#define kSIS3305RingbufferPreDelayADC56             0x3010
#define kSIS3305RingbufferPreDelayADC78             0x3014

#pragma mark - Direct Memory Max Nof Events Registers
#define kSIS3305MaxNofEventsADC14                   0x2018
#define kSIS3305MaxNofEventsADC58                   0x3018

#pragma mark - End Address Threshold registers
#define kSIS3305EndAddressThresholdADC14            0x201C
#define kSIS3305EndAddressThresholdADC58            0x301C

#pragma mark - Trigger/Gate Threshold registers
#define kSIS3305TriggerGateGTThresholdsADC1         0x2020
#define kSIS3305TriggerGateLTThresholdsADC1         0x2024
#define kSIS3305TriggerGateGTThresholdsADC2         0x2028
#define kSIS3305TriggerGateLTThresholdsADC2         0x202C
#define kSIS3305TriggerGateGTThresholdsADC3         0x2030
#define kSIS3305TriggerGateLTThresholdsADC3         0x2034
#define kSIS3305TriggerGateGTThresholdsADC4         0x2038
#define kSIS3305TriggerGateLTThresholdsADC4         0x203C

#define kSIS3305TriggerGateGTThresholdsADC5         0x3020
#define kSIS3305TriggerGateLTThresholdsADC5         0x3024
#define kSIS3305TriggerGateGTThresholdsADC6         0x3028
#define kSIS3305TriggerGateLTThresholdsADC6         0x302C
#define kSIS3305TriggerGateGTThresholdsADC7         0x3030
#define kSIS3305TriggerGateLTThresholdsADC7         0x3034
#define kSIS3305TriggerGateGTThresholdsADC8         0x3038
#define kSIS3305TriggerGateLTThresholdsADC8         0x303C

#pragma mark - Sampling Status
#define kSIS3305SamplingStatusRegADC14              0x2040
#define kSIS3305SamplingStatusRegADC58              0x3040

#pragma mark - Actual Sample Address register
#define kSIS3305ActualSampleAddressADC14            0x2044
#define kSIS3305ActualSampleAddressADC58            0x3044

#pragma mark - Direct Memory Event Counter
#define kSIS3305DirectMemoryEventCounterADC14       0x2048
#define kSIS3305DirectMemoryEventCounterADC58       0x3048

#pragma mark - Direct Memory Actual Next Event Start address register
#define kSIS3305DirectMemoryActualEventStartAddressADC14     0x204C
#define kSIS3305DirectMemoryActualEventStartAddressADC58     0x304C

#pragma mark - Actual Sample Value Registers
#define kSIS3305ActualSampleValueADC12              0x2050   /* read */
#define kSIS3305ActualSampleValueADC34              0x2054   /* read */
#define kSIS3305ActualSampleValueADC56              0x3050   /* read */
#define kSIS3305ActualSampleValueADC78              0x3054   /* read */

#pragma mark - Aurora Protocol/Data Status register
#define kSIS3305FpgaAuroraStatusADC14               0x2058    /* r/w, D32 */
#define kSIS3305FpgaAuroraStatusADC58               0x3058    /* r/w, D32 */
#define kSIS3305FpgaAuroraStatusKeyClearADC14       0x200C    /* write D32 */
#define kSIS3305FpgaAuroraStatusKeyClearADC58       0x300C    /* write D32 */

#pragma mark - Individual Channel Select/Set Veto Register
#define kSIS3305IndividualSelectSetVetoADC14        0x2070     /* r/w, D32 */
#define kSIS3305IndividualSelectSetVetoADC58        0x3070     /* r/w, D32 */

#pragma mark - Input tap delay registers
#define kSIS3305ADCInputTapDelayADC14               0x2400
#define kSIS3305ADCInputTapDelayADC58               0x3400


#define kSIS3305Space1ADCDataFIFOCh14      0x8000
#define kSIS3305Space1ADCDataFIFOCh58      0xC000

#define kSIS3305Space2ADCDataFIFOCh14      0x800000
#define kSIS3305Space2ADCDataFIFOCh58      0xC00000

//#define kSIS3305     0x

