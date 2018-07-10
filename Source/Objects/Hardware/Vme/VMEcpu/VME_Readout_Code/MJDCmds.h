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

#define kMJDReadPreamps         0x01
#define kMJDSingleAuxIO         0x02
#define kMJDFlashGretinaFPGA    0x03
#define kMJDReadPreampsANL      0x04
#define kMJDSingleAuxIOANL      0x05
#define kMJDFlashGretinaAFPGA   0x06

typedef struct {
    uint32_t baseAddress;
    uint32_t chip;              /*0 or 1 so we know the channel offset*/
    uint32_t readEnabledMask;
    uint32_t adc[8];           /*spiData to SBC .. adcData upon return*/
} GRETINA4_PreAmpReadStruct;

typedef struct {
    uint32_t baseAddress;
    uint32_t readEnabledMask;
    uint32_t spiData;           /*spiData to SBC .. result upon return*/
} GRETINA4_SingleAuxIOStruct;

typedef struct {
	uint32_t baseAddress;
	uint32_t errorCode;		/*filled on return*/
} MJDFlashGretinaFPGAStruct;

#endif
