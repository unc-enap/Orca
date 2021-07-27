//-----------------------------------------------------------
//  SLTv4GeneralOperations.h
//  Orca
//  Created by Mark Howe on 1/26/11
//  Copyright 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of North Carolina
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#ifndef _H_SLTv4GENERALOPS_
#define _H_SLTv4GENERALOPS_

#define kGetSoftwareVersion  0x01
#define kGetFdhwLibVersion   0x02
#define kGetSltPciDriverVersion   0x03  //TODO: only for Linux implemented 2012-03 -tb-
#define kGetIsLinkedWithPCIDMALib 0x04
#define kSetHostTimeToFLTsAndSLT 0x05


// see: HW_Readout.cc
// void doGeneralWriteOp(SBC_Packet* aPacket,uint8_t reply)
// and
// void doGeneralReadOp(SBC_Packet* aPacket,uint8_t reply)
// -tb-

#endif
