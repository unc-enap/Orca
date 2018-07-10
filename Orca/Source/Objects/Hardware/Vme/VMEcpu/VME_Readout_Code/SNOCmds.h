//-----------------------------------------------------------
//  SNOMtcCmds.h
//  Orca
//  Created by Mark Howe on 9/29/08
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

#ifndef _H_SNOCMDS_
#define _H_SNOCMDS_

#include <sys/types.h>
#include <stdint.h>
#include "SBC_Cmds.h"

#define kSNOMtcLoadXilinx		0x01
#define kSNOXL2LoadClocks		0x02
#define kSNOXL2LoadXilinx		0x03
#define kSNOMtcFirePedestalJobFixedTime	0x04
#define kSNOMtcEnablePedestalsFixedTime	0x05
#define kSNOMtcFirePedestalsFixedTime	0x06
#define kSNOMtcLoadMTCADacs		0x07
#define kSNOMtcatResetMtcat     0x08
#define kSNOMtcatResetAll       0x09
#define kSNOMtcatLoadCrateMask  0x0a
#define kSNOMtcTellReadout      0x0b

#define kSNOMtcTellReadoutHardEnd 0x01
#define kSNOReadHVStop          0x0d //0000_1101 in binary 

typedef struct {
	int32_t baseAddress;
	int32_t addressModifier;
	int32_t programRegOffset;
	uint32_t errorCode;		/*filled on return*/
	int32_t fileSize;		/*zero on return*/
	//raw file data will follow
} SNOMtc_XilinxLoadStruct;

typedef struct {
	int32_t addressModifier;
	int32_t xl2_select_reg;
	int32_t xl2_select_xl2;
	int32_t xl2_clock_cs_reg;
	int32_t xl2_master_clk_en;
	int32_t allClocksEnabled;
	uint32_t errorCode;		/*filled on return*/
	int32_t fileSize;		/*zero on return*/
	//raw file data will follow
}
SNOXL2_ClockLoadStruct;

typedef struct {
	int32_t addressModifier;
	int32_t selectBits;
	int32_t xl2_select_reg;
	int32_t xl2_select_xl2;
	int32_t xl2_control_status_reg;
	int32_t xl2_control_bit11;
	int32_t xl2_xlpermit;
	int32_t xl2_enable_dp;
	int32_t xl2_disable_dp;
	int32_t xl2_xilinx_user_control;
	int32_t xl2_control_clock;
	int32_t xl2_control_data;
	int32_t xl2_control_done_prog;
	uint32_t errorCode;		/*filled on return*/
	int32_t fileSize;		/*zero on return*/
	//raw file data will follow
} SNOXL2_XilinixLoadStruct;

#endif
