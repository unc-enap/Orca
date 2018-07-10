//-------------------------------------------------------------------------
//  ORSIS3302RegisterDefs.h
//
//  Created by Mark A. Howe on Wednesday 11/24/09.
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

#define kNumSIS3302Channels	8 
#define kNumSIS3302Groups	4 

#define kMcaRunMode			0
#define kEnergyRunMode		1

#define kSISLed						0x0001L
#define kSIS3302MaxEnergyWaveform	510

#define CSRMask(state,A) ((state)?(A):(A<<16))

#define kSIS3302ControlStatus                      0x0	  /* read/write; D32 */
#define kSIS3302ModID                             0x4	  /* read only; D32 */
#define kSIS3302IrqConfig                          0x8      /* read/write; D32 */
#define kSIS3302IrqControl                         0xC      /* read/write; D32 */
#define kSIS3302AcquisitionControl                 0x10      /* read/write; D32 */
#define kSIS3302GenericStartDelay                  0x14     /* Generic */
#define kSIS3302GenericStopDelay                   0x18     /* Generic */
#define kSIS3302GenericMaximumNumberOfEvents       0x20     /* Generic */


#define kSIS3302CbltBroadcastSetup               0x30      /* read/write; D32 */
#define kSIS3302AdcMemoryPageRegister            0x34      /* read/write; D32 */

#define kSIS3302DacControlStatus                  0x50      /* read/write; D32 */
#define kSIS3302DacData                           0x54      /* read/write; D32 */

#define kSIS3302McaEnable1357					0x10
#define kSIS3302McaEnable2468					0x20


// Key Addresses  
#define kSIS3302KeyReset                          			0x400	  /* write only; D32 */



#define kSIS3302GenericKeyArmSampleLogic              		0x410	  /* Generic */
#define kSIS3302GenericKeyDisarmSampleLogic        			0x414	  /* Generic */
#define kSIS3302GenericKeySampling                         	0x418	  /* Generic */
#define kSIS3302GenericKeyStopSampling                 		0x41C	  /* Generic */
#define kSIS3302GenericKeyTimestampClear               		0x42C	  /* Generic */

#define kSIS3302Key0x404SampleLogicReset           			0x404	  /* write only; D32 */

#define kSIS3302KeySampleLogicReset              			0x410	  /* write only; D32 */
#define kSIS3302KeyDisarm                         			0x414	  /* write only; D32 */
#define kSIS3302KeyTrigger                         			0x418	  /* write only; D32 */
#define kSIS3302KeyTimestampClear                 			0x41C	  /* write only; D32 */
#define kSIS3302KeyDisarmAndArmBank1           				0x420	  /* write only; D32 */
#define kSIS3302KeyDisarmAndArmBank2           				0x424	  /* write only; D32 */

#define kSIS3302KeyResetDDR2Logic                			0x428	  /* write only; D32 */


// all ADC FPGA groups
#define kSIS3302EventConfigAllAdc                			 0x01000000	  
#define kSIS3302GenericSampleLengthAllAdc                    0x01000004     /* Generic */
#define kSIS3302GenericSampleStartAllAdc                     0x01000008     /* Generic */
#define kSIS3302GenericAdcInputModeAllAdc                    0x0100000C     /* Generic */
#define kSIS3302EndAddressThresholdAllAdc       			 0x01000004	    /* Gamma */
#define kSIS3302PretriggerDelayTriggerGateLengthAllAdc		 0x01000008	    /* Gamma */
#define kSIS3302RawDataBufferConfigAllAdc         			 0x0100000C	    /* Gamma */

#define kSIS3302EnergySetupGPAllAdc   						0x01000040      /* Gamma */
#define kSIS3302EnergyGateLengthAllAdc						0x01000044      /* Gamma */
#define kSIS3302EnergySampleLengthAllAdc					0x01000048      /* Gamma */
#define kSIS3302EnergySampleStartIndex1AllAdc				0x0100004C      /* Gamma */
#define kSIS3302EnergySampleStartIndex2AllAdc				0x01000050      /* Gamma */
#define kSIS3302EnergySampleStartIndex3AllAdc				0x01000054      /* Gamma */
#define kSIS3302EnergyNumberToSumAllAdc						0x01000060		/* v1512 */
#define kSIS3302EnergyTauFactorAdc1357						0x01000058      /* Gamma */
#define kSIS3302EnergyTauFactorAdc2468						0x0100005C      /* Gamma */

#define kSIS3302GenericPreTriggerDelayAllAdc                0x01000060      /* Generic */

#define kSIS3302EventExtendedConfigAllAdc          			0x01000070	  



// ADC12 FPGA group
#define kSIS3302EventConfigAdc12                			0x02000000 		/* Gamma */	 
#define kSIS3302GenericSampleLengthAdc12                    0x02000004      /* Generic */
#define kSIS3302GenericSampleStartAdc12                     0x02000008      /* Generic */
#define kSIS3302GenericAdcInputModeAdc12                    0x0200000C      /* Generic */
#define kSIS3302EndAddressThresholdAdc12      	 			0x02000004	    /* Gamma */
#define kSIS3302PreTriggerDelayTriggerGateLengthAdc12  		0x02000008	    /* Gamma */
#define kSIS3302RawDataBufferConfigAdc12       				0x0200000C	    /* Gamma */

#define kSIS3302ActualSampleAddressAdc1          			0x02000010	  
#define kSIS3302ActualSampleAddressAdc2          			0x02000014	  
#define kSIS3302PreviousBankSampleAddressAdc1   			0x02000018	  
#define kSIS3302PreviousBankSampleAddressAdc2   			0x0200001C	  

#define kSIS3302ActualSampleValueAdc12           			0x02000020	  
#define kSIS3302DDR2TestRegisterAdc12						0x02000028      
#define kSIS3302BufferControlModeAdc12           			0x0200002C  

#define kSIS3302TriggerSetupAdc1                  			0x02000030	  
#define kSIS3302TriggerThresholdAdc1              			0x02000034
#define kSIS3302HighEnergyThresholdAdc1						0x020000A8		/* v1512 */
#define kSIS3302TriggerSetupAdc2                  			0x02000038	  
#define kSIS3302TriggerThresholdAdc2              			0x0200003C	  
#define kSIS3302HighEnergyThresholdAdc2						0x020000AC		/* v1512 */

#define kSIS3302EnergySetupGPAdc12   						0x02000040      /* Gamma */
#define kSIS3302EnergyGateLengthAdc12						0x02000044      /* Gamma */
#define kSIS3302EnergySampleLengthAdc12						0x02000048      /* Gamma */
#define kSIS3302EnergySampleStartIndex1Adc12				0x0200004C      /* Gamma */

#define kSIS3302EnergySampleStartIndex2Adc12				0x02000050      /* Gamma */
#define kSIS3302EnergySampleStartIndex3Adc12				0x02000054      /* Gamma */
#define kSIS3302EnergyTauFactorAdc1							0x02000058      /* Gamma */
#define kSIS3302EnergyTauFactorAdc2							0x0200005C      /* Gamma */

#define kSIS3302GenericPreTriggerDelayAdc12                 0x02000060      /* Generic */

#define kSIS3302EventExtendedConfigAdc12       				0x02000070 		   
#define kSIS3302TriggerExtendedSetupAdc1             		0x02000078	  
#define kSIS3302TriggerExtendedSetupAdc2             		0x0200007C	  

#define kSIS3302TriggerExtendedThresholdAdc1            	0x020000A0	  
#define kSIS3302TriggerExtendedThresholdAdc2            	0x020000A4	  

#define kSIS3302GenericEventDirectoryAdc1                   0x02010000      /* Generic */
#define kSIS3302GenericEventDirectoryAdc2                   0x02018000      /* Generic */


// ADC34 FPGA group
#define kSIS3302EventConfigAdc34                			0x02800000 		/* Gamma */
#define kSIS3302GenericSampleLengthAdc34                    0x02800004      /* Generic */
#define kSIS3302GenericSampleStartAdc34                     0x02800008      /* Generic */
#define kSIS3302GenericAdcInputModeAdc34                    0x0280000C      /* Generic */
#define kSIS3302EndAddressThresholdAdc34      	 			0x02800004	    /* Gamma */
#define kSIS3302PreTriggerDelayTriggerGateLengthAdc34  		0x02800008	    /* Gamma */
#define kSIS3302RawDataBufferConfigAdc34       				0x0280000C	    /* Gamma */

#define kSIS3302ActualSampleAddressAdc3          			0x02800010	  
#define kSIS3302ActualSampleAddressAdc4          			0x02800014	  
#define kSIS3302PreviousBankSampleAddressAdc3   			0x02800018	  
#define kSIS3302PreviousBankSampleAddressAdc4   			0x0280001C	  

#define kSIS3302ActualSampleValueAdc34           			0x02800020	  
#define kSIS3302DDR2TestRegisterAdc34						0x02800028      
#define kSIS3302BufferControlModeAdc34          			0x0280002C  

#define kSIS3302TriggerSetupAdc3                  			0x02800030	  
#define kSIS3302TriggerThresholdAdc3              			0x02800034	
#define kSIS3302HighEnergyThresholdAdc3						0x028000A8		/* v1512 */
#define kSIS3302TriggerSetupAdc4                  			0x02800038	  
#define kSIS3302TriggerThresholdAdc4              			0x0280003C	  
#define kSIS3302HighEnergyThresholdAdc4						0x028000AC		/* v1512 */

#define kSIS3302EnergySetupGPAdc34   						0x02800040      /* Gamma */
#define kSIS3302EnergyGateLengthAdc34						0x02800044      /* Gamma */
#define kSIS3302EnergySampleLengthAdc34						0x02800048      /* Gamma */
#define kSIS3302EnergySampleStartIndex1Adc34				0x0280004C      /* Gamma */

#define kSIS3302EnergySampleStartIndex2Adc34				0x02800050      /* Gamma */
#define kSIS3302EnergySampleStartIndex3Adc34				0x02800054      /* Gamma */
#define kSIS3302EnergyTauFactorAdc3							0x02800058      /* Gamma */
#define kSIS3302EnergyTauFactorAdc4							0x0280005C      /* Gamma */

#define kSIS3302GenericPreTriggerDelayAdc34                 0x02800060      /* Generic */

#define kSIS3302EventExtendedConfigAdc34       				0x02800070 		   
#define kSIS3302TriggerExtendedSetupAdc3             		0x02800078	  
#define kSIS3302TriggerExtendedSetupAdc4             		0x0280007C	  

#define kSIS3302TriggerExtendedThresholdAdc3            	0x028000A0	  
#define kSIS3302TriggerExtendedThresholdAdc4            	0x028000A4	  

#define kSIS3302GenericEventDirectoryAdc3                   0x02810000      /* Generic */
#define kSIS3302GenericEventDirectoryAdc4                   0x02818000      /* Generic */

// ADC56 FPGA group
#define kSIS3302EventConfigAdc56                			0x03000000 		/* Gamma */
#define kSIS3302GenericSampleLengthAdc56                    0x03000004      /* Generic */
#define kSIS3302GenericSampleStartAdc56                     0x03000008      /* Generic */
#define kSIS3302GenericAdcInputModeAdc56                    0x0300000C      /* Generic */
#define kSIS3302EndAddressThresholdAdc56      	 			0x03000004	    /* Gamma */
#define kSIS3302PreTriggerDelayTriggerGateLengthAdc56  		0x03000008	    /* Gamma */
#define kSIS3302RawDataBufferConfigAdc56       				0x0300000C	    /* Gamma */

#define kSIS3302ActualSampleAddressAdc5          			0x03000010	  
#define kSIS3302ActualSampleAddressAdc6          			0x03000014	  
#define kSIS3302PreviousBankSampleAddressAdc5   			0x03000018	  
#define kSIS3302PreviousBankSampleAddressAdc6   			0x0300001C	  

#define kSIS3302ActualSampleValueAdc56           			0x03000020	  
#define kSIS3302DDR2TestRegisterAdc56						0x03000028      
#define kSIS3302BufferControlModeAdc56           			0x0300002C  

#define kSIS3302TriggerSetupAdc5                  			0x03000030	  
#define kSIS3302TriggerThresholdAdc5              			0x03000034	
#define kSIS3302HighEnergyThresholdAdc5						0x030000A8		/* v1512 */
#define kSIS3302TriggerSetupAdc6                  			0x03000038	  
#define kSIS3302TriggerThresholdAdc6              			0x0300003C
#define kSIS3302HighEnergyThresholdAdc6						0x030000AC		/* v1512 */

#define kSIS3302EnergySetupGPAdc56   						0x03000040      /* Gamma */
#define kSIS3302EnergyGateLengthAdc56						0x03000044      /* Gamma */
#define kSIS3302EnergySampleLengthAdc56						0x03000048      /* Gamma */
#define kSIS3302EnergySampleStartIndex1Adc56				0x0300004C      /* Gamma */

#define kSIS3302EnergySampleStartIndex2Adc56				0x03000050      /* Gamma */
#define kSIS3302EnergySampleStartIndex3Adc56				0x03000054      /* Gamma */
#define kSIS3302EnergyTauFactorAdc5							0x03000058      /* Gamma */
#define kSIS3302EnergyTauFactorAdc6							0x0300005C      /* Gamma */

#define kSIS3302GenericPreTriggerDelayAdc56                 0x03000060      /* Generic */

#define kSIS3302EventExtendedConfigAdc56        			0x03000070 		   
#define kSIS3302TriggerExtendedSetupAdc5             		0x03000078	  
#define kSIS3302TriggerExtendedSetupAdc6             		0x0300007C	  

#define kSIS3302TriggerExtendedThresholdAdc5            	0x030000A0	  
#define kSIS3302TriggerExtendedThresholdAdc6            	0x030000A4	  

#define kSIS3302GenericEventDirectoryAdc5                   0x03010000      /* Generic */
#define kSIS3302GenericEventDirectoryAdc6                   0x03018000      /* Generic */

// ADC78 FPGA group
#define kSIS3302EventConfigAdc78                			0x03800000 		/* Gamma */
#define kSIS3302GenericSampleLengthAdc78                    0x03800004      /* Generic */
#define kSIS3302GenericSampleStartAdc78                     0x03800008      /* Generic */
#define kSIS3302GenericAdcInputModeAdc78                    0x0380000C      /* Generic */
#define kSIS3302EndAddressThresholdAdc78      	 			0x03800004	    /* Gamma */
#define kSIS3302PreTriggerDelayTriggerGateLengthAdc78  		0x03800008	    /* Gamma */
#define kSIS3302RawDataBufferConfigAdc78       				0x0380000C	    /* Gamma */

#define kSIS3302ActualSampleAddressAdc7          			0x03800010	  
#define kSIS3302ActualSampleAddressAdc8          			0x03800014	  
#define kSIS3302PreviousBankSampleAddressAdc7   			0x03800018	  
#define kSIS3302PreviousBankSampleAddressAdc8   			0x0380001C	  

#define kSIS3302ActualSampleValueAdc78           			0x03800020	  
#define kSIS3302DDR2TestRegisterAdc78						0x03800028      
#define kSIS3302BufferControlModeAdc78           			0x0380002C  

#define kSIS3302TriggerSetupAdc7                  			0x03800030	  
#define kSIS3302TriggerThresholdAdc7              			0x03800034
#define kSIS3302HighEnergyThresholdAdc7						0x038000A8		/* v1512 */
#define kSIS3302TriggerSetupAdc8                  			0x03800038	  
#define kSIS3302TriggerThresholdAdc8              			0x0380003C	  
#define kSIS3302HighEnergyThresholdAdc8						0x038000AC		/* v1512 */

#define kSIS3302EnergySetupGPAdc78   						0x03800040      /* Gamma */
#define kSIS3302EnergyGateLengthAdc78						0x03800044      /* Gamma */
#define kSIS3302EnergySampleLengthAdc78						0x03800048      /* Gamma */
#define kSIS3302EnergySampleStartIndex1Adc78				0x0380004C      /* Gamma */

#define kSIS3302EnergySampleStartIndex2Adc78				0x03800050      /* Gamma */
#define kSIS3302EnergySampleStartIndex3Adc78				0x03800054      /* Gamma */
#define kSIS3302EnergyTauFactorAdc7							0x03800058      /* Gamma */
#define kSIS3302EnergyTauFactorAdc8							0x0380005C      /* Gamma */

#define kSIS3302GenericPreTriggerDelayAdc78                 0x03800060      /* Generic */

#define kSIS3302EventExtendedConfigAdc78               		0x03800070 		   
#define kSIS3302TriggerExtendedSetupAdc7             		0x03800078	  
#define kSIS3302TriggerExtendedSetupAdc8             		0x0380007C	  

#define kSIS3302TriggerExtendedThresholdAdc7            	0x038000A0	  
#define kSIS3302TriggerExtendedThresholdAdc8            	0x038000A4	 

#define kSIS3302GenericEventDirectoryAdc7                   0x03810000      /* Generic */
#define kSIS3302GenericEventDirectoryAdc8                   0x03818000      /* Generic */

#define kSIS3302Adc1Offset                         			0x04000000	  
#define kSIS3302Adc2Offset                         			0x04800000	  
#define kSIS3302Adc3Offset                         			0x05000000	  
#define kSIS3302Adc4Offset                         			0x05800000	  
#define kSIS3302Adc5Offset                         			0x06000000	  
#define kSIS3302Adc6Offset                         			0x06800000	  
#define kSIS3302Adc7Offset                         			0x07000000	  
#define kSIS3302Adc8Offset                         			0x07800000	  

#define kSIS3302NEXTAdcOffset                     			0x00800000	  

/* define sample clock */
#define kSIS3302AcqSetClockTo100MHZ                 0x70000000  /* default after Reset  */
#define kSIS3302AcqSetClockTo50MHZ                  0x60001000
#define kSIS3302AcqSetClockTo25MHZ                  0x50002000
#define kSIS3302AcqSetClockTo10MHZ                  0x40003000
#define kSIS3302AcqSetClockTo1MHZ                   0x30004000
#define kSIS3302AcqSetClockToLemoRandomClockIn		0x20005000
#define kSIS3302AcqSetClockToLemoClockIn			0x10006000
//#define kSIS3302AcqSetClockToP2ClockIn            0x00007000
#define kSIS3302AcqSetClockToSecond100MHZ           0x00007000



#define kSIS3302AcqNumOfHistogramsPresetLemoTrigger      0x01000000 /* GAMMA, 091207 */
#define kSIS3302AcqEnableLemoTrigger					 0x00000100 /* GAMMA, 091207 */
#define kSIS3302AcqNumOfHistogramsPresetLemoTimeStampClr 0x02000000 /* GAMMA, 091207 */
#define kSIS3302AcqEnableLemoTimeStampClr				 0x00000200 /* GAMMA, 091207 */

// new 16.3.2009
#define kSIS3302AcqNumOfHistogramsPresetExternalLemoIn3 0x01000000 /* GAMMA, up V1205 */
#define kSIS3302AcqEnableExternalLemoIn3				0x00000100 /* GAMMA, up V1205 */
#define kSIS3302AcqNumOfHistogramsPresetExternalLemoIn2 0x02000000 /* GAMMA, up V1205 */
#define kSIS3302AcqEnableExternalLemoIn2				0x00000200 /* GAMMA, up V1205 */
#define kSIS3302AcqNumOfHistogramsPresetExternalLemoIn1 0x04000000 /* GAMMA, up V1205 */
#define kSIS3302AcqEnableExternalLemoIn1				0x00000400 /* GAMMA, up V1205 */

#define kSIS3302AcqSetLemoInMode0              	0x00070000  /* GAMMA, up V1205   */
#define kSIS3302AcqSetLemoInMode1         		0x00060001  /* GAMMA, up V1205   */
#define kSIS3302AcqSetLemoInMode2           	0x00050002  /* GAMMA, up V1205   */
#define kSIS3302AcqSetLemoInMode3      			0x00040003  /* GAMMA, up V1205   */
#define kSIS3302AcqSetLemoInMode4          		0x00030004  /* GAMMA, up V1205   */
#define kSIS3302AcqSetLemoInMode5   			0x00020005  /* GAMMA, up V1205   */
#define kSIS3302AcqSetLemoInMode6          		0x00010006  /* GAMMA, up V1205   */
#define kSIS3302AcqSetLemoInMode7           	0x00000007  /* GAMMA, up V1205   */
#define kSIS3302AcqSetLemoInModeBitMask      	0x00000007  /* GAMMA, up V1205   */

#define kSIS3302AcqSetLemoOutMode0             	0x00300000  /* GAMMA, up V1205   */
#define kSIS3302AcqSetLemoOutMode1         		0x00200010  /* GAMMA, up V1205   */
#define kSIS3302AcqSetLemoOutMode2           	0x00100020  /* GAMMA, up V1205   */
#define kSIS3302AcqSetLemoOutMode3      		0x00000030  /* GAMMA, up V1205   */
#define kSIS3302AcqSetLemoOutModeBitMask 		0x00000030  /* GAMMA, up V1205   */

#define kSIS3302AcqSetFeedbackInternalTrigger 	0x00000040  /* GAMMA, up V1205   */
#define kSIS3302AcqCLtFeedbackInternalTrigger 	0x00400000  /* GAMMA, up V1205   */

#define kSIS3302BroadcastMasterEnable        		0x20	
#define kSIS3302BroadcastEnable               		0x10	

/* gamma  */
#define kEventConfAdc2ExternGateEnableBit		0x2000	  /* GAMMA, up V1205   */ 
#define kEventConfAdc2InternGateEnableBit		0x1000	  /* GAMMA, up V1205   */
#define kEventConfAdc2ExternTriggerEnableBit	0x800	   
#define kEventConfAdc2InternTriggerEnableBit	0x400	
#define kEventConfAdc2InputInvertBit			0x100	  

#define kEventConfAdc1ExternGateEnableBit		0x20	  /* GAMMA, up V1205   */ 
#define kEventConfAdc1InternGateEnableBit		0x10	  /* GAMMA, up V1205   */
#define kEventConfAdc1ExternTriggerEnableBit	0x8	  
#define kEventConfAdc1InternTriggerEnableBit	0x4	 
#define kEventConfAdc1InputInvertBit			0x1	   

#define kDecimationNumOfHistogramsPreset		0x00000000
#define kDecimation2							0x10000000
#define kDecimation4							0x20000000
#define kDecimation8							0x30000000

/* gamma  MCA */
/*******************************************************************************************************/
#define kSIS3302McaScanNumOfHistogramsPreset	    		0x80	  /* read/write; D32 */
#define kSIS3302McaScanHistogramCounter	    				0x84	  /* read only; D32  */
#define kSIS3302McaScanSetupPrescaleFactor    				0x88	  /* read only; D32  */
#define kSIS3302McaScanControl			    				0x8C	  /* read/write; D32  */

#define kSIS3302McaMultiScanNumOfScansPreset	    		0x90	  /* read/write; D32 */
#define kSIS3302McaMultiScanScanCounter	    				0x94	  /* read only; D32  */
#define kSIS3302McaMultiScanLastScanHistogramCounter		0x98	  /* read only; D32  */


#define kSIS3302KeyMcaScanLnePulse           				0x410	  /* write only; D32 */
#define kSIS3302KeyMcaScanArm         						0x414	  /* write only; D32 */
#define kSIS3302KeyMcaScanStart          					0x418	  /* write only; D32 */
#define kSIS3302KeyMcaScanStop								0x41C	  /* write only; D32 */

#define kSIS3302KeyMcaMultiScanStartResetPulse				0x420	  /* write only; D32 */
#define kSIS3302KeyMcaMultiScanArmScanArm        			0x424	  /* write only; D32 */
#define kSIS3302KeyMcaMultiScanArmScanEnable				0x428	  /* write only; D32 */
#define kSIS3302KeyMcaMultiScanDisable						0x42C	  /* write only; D32 */


#define kSIS3302McaEnergy2HistogramParamAdc1357    			0x01000060	  /* write only; D32 */
#define kSIS3302McaEnergy2HistogramParamAdc2468    			0x01000064	  /* write only; D32 */
#define kSIS3302McaHistogramParamAllAdc    					0x01000068	  /* write only; D32 */

#define kSIS3302McaEnergy2HistogramParamAdc1				0x02000060	  /* read/write; D32 */
#define kSIS3302McaEnergy2HistogramParamAdc2    			0x02000064	  /* read/write; D32 */
#define kSIS3302McaHistogramParamAdc12    					0x02000068	  /* read/write; D32 */

#define kSIS3302McaTriggerStartCounterAdc1 					0x02000080	  /* read only; D32 */
#define kSIS3302McaPileupCounterAdc1 						0x02000084	  /* read only; D32 */
#define kSIS3302McaEnergy2HighCounterAdc1 					0x02000088	  /* read only; D32 */
#define kSIS3302McaEnergy2LowCounterAdc1 					0x0200008C	  /* read only; D32 */

#define kSIS3302McaTriggerStartCounterAdc2 					0x02000090	  /* read only; D32 */
#define kSIS3302McaPileupCounterAdc2 						0x02000094	  /* read only; D32 */
#define kSIS3302McaEnergy2HighCounterAdc2 					0x02000098	  /* read only; D32 */
#define kSIS3302McaEnergy2LowCounterAdc2 					0x0200009C	  /* read only; D32 */


#define kSIS3302McaTriggerStartCounterAdc3 					0x02800080	  /* read only; D32 */
#define kSIS3302McaPileupCounterAdc3 						0x02800084	  /* read only; D32 */
#define kSIS3302McaEnergy2HighCounterAdc3 					0x02800088	  /* read only; D32 */
#define kSIS3302McaEnergy2LowCounterAdc3 					0x0280008C	  /* read only; D32 */

#define kSIS3302McaTriggerStartCounterAdc4 					0x02800090	  /* read only; D32 */
#define kSIS3302McaPileupCounterAdc4 						0x02800094	  /* read only; D32 */
#define kSIS3302McaEnergy2HighCounterAdc4 					0x02800098	  /* read only; D32 */
#define kSIS3302McaEnergy2LowCounterAdc4 					0x0280009C	  /* read only; D32 */

#define kSIS3302McaTriggerStartCounterAdc5 					0x03000080	  /* read only; D32 */
#define kSIS3302McaPileupCounterAdc5 						0x03000084	  /* read only; D32 */
#define kSIS3302McaEnergy2HighCounterAdc5 					0x03000088	  /* read only; D32 */
#define kSIS3302McaEnergy2LowCounterAdc5 					0x0300008C	  /* read only; D32 */

#define kSIS3302McaTriggerStartCounterAdc6 					0x03000090	  /* read only; D32 */
#define kSIS3302McaPileupCounterAdc6 						0x03000094	  /* read only; D32 */
#define kSIS3302McaEnergy2HighCounterAdc6 					0x03000098	  /* read only; D32 */
#define kSIS3302McaEnergy2LowCounterAdc6 					0x0300009C	  /* read only; D32 */

#define kSIS3302McaTriggerStartCounterAdc7 					0x03800080	  /* read only; D32 */
#define kSIS3302McaPileupCounterAdc7 						0x03800084	  /* read only; D32 */
#define kSIS3302McaEnergy2HighCounterAdc7 					0x03800088	  /* read only; D32 */
#define kSIS3302McaEnergy2LowCounterAdc7 					0x0380008C	  /* read only; D32 */

#define kSIS3302McaTriggerStartCounterAdc8 					0x03800090	  /* read only; D32 */
#define kSIS3302McaPileupCounterAdc8 						0x03800094	  /* read only; D32 */
#define kSIS3302McaEnergy2HighCounterAdc8 					0x03800098	  /* read only; D32 */
#define kSIS3302McaEnergy2LowCounterAdc8 					0x0380009C	  /* read only; D32 */

#define kSIS3302AcqSetMcaMode								0x00000008  /* GAMMA, up V1205   */
#define kSIS3302AcqClrMcaMode								0x00080000  /* GAMMA, up V1205   */

