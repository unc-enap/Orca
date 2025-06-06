//
//  ORMTC_Constants.h
//  Orca
//
//  Created by Mark Howe on 5/5/08.
//  Copyright 2008 CENPA, University of Washington. All rights reserved.
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

#define kMTCMemModifier			0x09
#define kMTCMemAccess			0x02

typedef struct  {
	NSString*   regName;
	short		addressOffset;
	short		addressModifier;
	short		addressSpace;
} SnoMtcNamesStruct; 

enum {
	kMtcControlReg,   
	kMtcSerialReg,   
	kMtcDacCntReg,   
	kMtcSoftGtReg,  
	kMtcPwIdReg,  
	kMtcRtdelReg,  
	kMtcAddelReg,  
	kMtcThresModReg,  
	kMtcPmskReg,  
	kMtcScaleReg,  
	kMtcBwrAddOutReg,  
	kMtcBbaReg,  
	kMtcGtLockReg,  
	kMtcMaskReg,  
	kMtcXilProgReg,  
	kMtcGmskReg,  
	kMtcOcGtReg, 
	kMtcC50_0_31Reg,
	kMtcC50_32_42Reg,
	kMtcC10_0_31Reg,
	kMtcC10_32_52Reg,
	kMtcNumRegisters //must be last
};

// GTWord Masks for the MTC
#define MTC_NHIT_100_LO_MASK				0x00000001
#define MTC_NHIT_100_MED_MASK				0x00000002
#define MTC_NHIT_100_HI_MASK				0x00000004
#define MTC_NHIT_20_MASK					0x00000008
#define MTC_NHIT_20_LB_MASK					0x00000010
#define MTC_ESUM_LO_MASK					0x00000020
#define MTC_ESUM_HI_MASK					0x00000040
#define MTC_OWLN_MASK						0x00000080
#define MTC_OWLE_LO_MASK					0x00000100
#define MTC_OWLE_HI_MASK					0x00000200
#define MTC_PULSE_GT_MASK					0x00000400
#define MTC_PRESCALE_MASK					0x00000800
#define MTC_PEDESTAL_MASK					0x00001000
#define MTC_PONG_MASK						0x00002000
#define MTC_SYNC_MASK						0x00004000
#define MTC_EXT_ASYNC_MASK					0x00008000
#define MTC_EXT_2_MASK						0x00010000
#define MTC_EXT_3_MASK						0x00020000
#define MTC_EXT_4_MASK						0x00040000
#define MTC_EXT_5_MASK						0x00080000
#define MTC_EXT_6_MASK						0x00100000
#define MTC_EXT_7_MASK						0x00200000
#define MTC_EXT_8_MASK						0x00400000
#define MTC_SP_RAW_MASK						0x00800000
#define MTC_NCD_MASK						0x01000000
#define MTC_SOFT_GT_MASK					0x02000000

// MTC Control Register 0 bit Masks
#define MTC_CSR_PED_EN						0x00000001
#define MTC_CSR_PULSE_EN					0x00000002
#define MTC_CSR_LOAD_ENPR					0x00000004
#define MTC_CSR_LOAD_ENPS					0x00000008
#define MTC_CSR_LOAD_ENPW					0x00000010
#define MTC_CSR_LOAD_ENLK					0x00000020
#define MTC_CSR_ASYNC_EN					0x00000040
#define MTC_CSR_RESYNC						0x00000080
#define MTC_CSR_TESTGT						0x00000100
#define MTC_CSR_TEST50						0x00000200
#define MTC_CSR_TEST10						0x00000400
#define MTC_CSR_LOAD_ENGT					0x00000800
#define MTC_CSR_LOAD_EN50					0x00001000
#define MTC_CSR_LOAD_EN10					0x00002000
#define MTC_CSR_TESTMEM1					0x00004000
#define MTC_CSR_TESTMEM2					0x00008000
#define MTC_CSR_FIFO_RESET					0x00010000
#define MTC_CSR_TMONSEL						0x00020000
#define MTC_CSR_TMON0						0x00040000
#define MTC_CSR_TMON1						0x00080000
#define MTC_CSR_TMON2						0x00100000
#define MTC_CSR_TMON3						0x00200000

// MTC Serial Register 1 bit Masks
#define MTC_SERIAL_REG_SEN					0x00000001
#define MTC_SERIAL_REG_DIN					0x00000002
#define MTC_SERIAL_SHFTCLKGT				0x00000004
#define MTC_SERIAL_SHFTCLK50				0x00000008
#define MTC_SERIAL_SHFTCLK10				0x00000010
#define MTC_SERIAL_SHFTCLKPS				0x00000020

// MTC/A DAC loadig 
#define MTC_DAC_CNT_DACSEL					0x00004000
#define MTC_DAC_CNT_DACCLK					0x00008000

#define MTC_DAC_CNT_BIT0					0x00000001
#define MTC_DAC_CNT_BIT1					0x00000002
#define MTC_DAC_CNT_BIT2					0x00000004
#define MTC_DAC_CNT_BIT3					0x00000008
#define MTC_DAC_CNT_BIT4					0x00000010
#define MTC_DAC_CNT_BIT5					0x00000020
#define MTC_DAC_CNT_BIT6					0x00000040
#define MTC_DAC_CNT_BIT7					0x00000080
#define MTC_DAC_CNT_BIT8					0x00000100
#define MTC_DAC_CNT_BIT9					0x00000200
#define MTC_DAC_CNT_BIT10					0x00000400
#define MTC_DAC_CNT_BIT11					0x00000800

#define TUB_SDATA  							0x00000400
#define TUB_SCLK  						 	0x00000800
#define TUB_SLATCH 							0x00001000
