//
//  HW_Readout.h
//  Orca
//
//  Created by Mark Howe on Mon Sept 10, 2007
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#ifndef _H_HWREADOUT_
#define _H_HWREADOUT_

#include "SBC_Cmds.h"

void processHWCommand(SBC_Packet* aPacket);
void FindHardware(void);
void ReleaseHardware(void);
void doWriteBlock(SBC_Packet* aPacket,uint8_t reply);
void doReadBlock(SBC_Packet* aPacket,uint8_t reply);
void doGeneralWriteOp(SBC_Packet* aPacket,uint8_t reply);
void doGeneralReadOp(SBC_Packet* aPacket,uint8_t reply);

#endif
