//
//  HW_Readout.h
//  Orca
//
//  Created by Mark Howe on Mon Mar 10, 2008
//  Copyright � 2002 CENPA, University of Washington. All rights reserved.
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

#ifdef __cplusplus
//  namespace hw4 {
//  	class SubrackKatrin;
//  }
using namespace hw4;
class Pbus;
//class hw4::SubrackKatrin;
extern Pbus *pbus;              //for register access with fdhwlib
extern uint32_t presentFLTMap; // store a map of the present FLT cards
#endif

#ifdef __cplusplus
extern "C" {
#endif

//#include "SBC_Cmds.h"
	
void processHWCommand(SBC_Packet* aPacket);
void processChargeBBCommand(SBC_Packet* aPacket);
void chargeBB(SBC_Packet* aPacket);
void processChargeFICCommand(SBC_Packet* aPacket);
void chargeFIC(SBC_Packet* aPacket);

void FindHardware(void);
void ReleaseHardware(void);
void doWriteBlock(SBC_Packet* aPacket,uint8_t reply);
void doReadBlock(SBC_Packet* aPacket,uint8_t reply);
void doGeneralWriteOp(SBC_Packet* aPacket,uint8_t reply);
void doGeneralReadOp(SBC_Packet* aPacket,uint8_t reply);

int getSltLinuxKernelDriverVersion(void);


#ifdef __cplusplus
}
#endif

#endif
