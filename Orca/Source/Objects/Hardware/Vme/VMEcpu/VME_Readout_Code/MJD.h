/*
 *  MJD.h
 *  Orca
 *
 *  Created by Mark Howe on 08/27/13.
 *  Copyright 2013 ENAP, University of North Carolina. All rights reserved.
 *
 */
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina at the Experimental Nuclear and Astroparticle Physics
//(ENAP) group sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#ifndef __MJD_H__
#define __MJD_H__

#define kFlashBlocks                128
#define kFlashBlockSize             (kFlashBlocks * 1024)
#define kFlashBufferBytes           32

#define kMainFPGAControlReg         0x900
#define kMainFPGAStatusReg          0x904
#define kVMEGPControlReg            0x910
#define kFlashAddressReg            0x980
#define kFlashDataAutoIncReg        0x984
#define kFlashDataReg               0x988
#define kFlashCommandReg            0x98C
#define kANLMainFPGAControlReg      0x90C



#define kFlashBusy                  0x80
#define kFlashEnableWrite           0x10
#define kFlashDisableWrite          0x0
#define kFlashConfirmCmd            0xD0
#define kFlashWriteCmd              0xE8
#define kFlashBlockEraseCmd         0x20
#define kFlashReadArrayCmd          0xFF
#define kFlashStatusRegCmd          0x70
#define kFlashClearSRCmd            0x50

#define kResetMainFPGACmd           0x30
#define kReloadMainFPGACmd          0x3
#define kMainFPGAIsLoaded           0x41


void processMJDCommand(SBC_Packet* aPacket);
void readPreAmpAdcs(SBC_Packet* inputPacket);
void singleAuxIO(SBC_Packet* aPacket);
uint32_t writeAuxIOSPI(uint32_t baseAddress,uint32_t spiData);
void readANLPreAmpAdcs(SBC_Packet* aPacket);
void singleANLAuxIO(SBC_Packet* aPacket);
uint32_t writeANLAuxIOSPI(uint32_t baseAddress,uint32_t spiData);

void flashGretinaFPGA(SBC_Packet* aPacket);
void setJobStatus(const char* message,uint32_t progress);

void blockEraseFlash();
void programFlashBuffer(uint8_t* theData, uint32_t numBytes);
uint8_t verifyFlashBuffer(uint8_t* theData, uint32_t numBytes);
void programFlashBufferBlock(uint8_t* theData,uint32_t anAddress,uint32_t aNumber);
void readDevice(uint32_t address,uint32_t* retValue);
void writeDevice(uint32_t address,uint32_t aValue);
void reloadMainFpgaFromFlash();
void reloadMainFpgaFromFlash_ANL();


#endif //__MJD_H__
