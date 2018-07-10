/*
 *  SNO.h
 *  Orca
 *
 *  Created by Mark Howe on 9/29/08.
 *  Copyright 2008 CENPA, University of Washington. All rights reserved.
 *
 */
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
#ifndef __SNO_H__
#define __SNO_H__

#include "SBC_Cmds.h"

void loadMtcXilinx(SBC_Packet* aPacket);
void loadXL2Clocks(SBC_Packet* aPacket);
void loadXL2Xilinx(SBC_Packet* aPacket);
void firePedestalsFixedTime(SBC_Packet* aPacket);
void stopPedestalsFixedTime(SBC_Packet* aPacket);
void processSNOCommand(SBC_Packet* aPacket);
void firePedestalJobFixedTime(SBC_Packet* aPacket);
void enablePedestalsFixedTime(SBC_Packet* aPacket);
void firePedestalsFixedTime(SBC_Packet* aPacket);
void loadMTCADacs(SBC_Packet* aPacket);
void mtcatResetMtcat(SBC_Packet* aPacket);
void mtcatResetAll(SBC_Packet* aPacket);
void mtcatLoadCrateMask(SBC_Packet* aPacket);
void hvEStopPoll(SBC_Packet* aPacket);
void mtcTellReadout(SBC_Packet* aPacket);

#endif // __SNO_H__
