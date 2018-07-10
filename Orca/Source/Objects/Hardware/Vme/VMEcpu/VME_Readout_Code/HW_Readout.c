//
//  HW_Readout.m
//  Orca
//
//  Created by Mark Howe on Mon Sept 10, 2007
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
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <time.h>
#include <errno.h>
#include "SBC_Cmds.h"
#include "SBC_Config.h"
#include "HW_Readout.h"
#include "SBC_Readout.h"
#include "CircularBuffer.h"
#include "VME_HW_Definitions.h"
#include "SNO.h"
#include "MJD.h"
#include "universe_api.h"
#include "VmeSBCGeneralOperations.h"

#define kCodeVersion 1

#define kDMALowerLimit   0x100 //require 256 bytes
#define kControlSpace    0xFFFF
#define kPollSameAddress 0xFF


void SwapLongBlock(void* p, int32_t n);
void SwapShortBlock(void* p, int32_t n);
int32_t writeBuffer(SBC_Packet* aPacket);

extern char     needToSwap;
extern int32_t  dataIndex;
extern int32_t* data;

TUVMEDevice* fDevice = NULL;
TUVMEDevice* controlHandle = NULL;

void processHWCommand(SBC_Packet* aPacket)
{
	/*look at the first word to get the destination*/
	int32_t destination = aPacket->cmdHeader.destination;
	switch(destination){
		case kSNO:		processSNOCommand(aPacket); break;
		case kMJD:		processMJDCommand(aPacket); break;
		default:			break;
	}
}

void FindHardware(void)
{  
    controlHandle = get_ctl_device(); 
    if (controlHandle == NULL) LogBusError("Device controlHandle: %s",strerror(errno));

	fDevice = get_new_device(0x0, 0x9, 4, 0x0);
    if (fDevice == NULL) LogBusError("fDevice: %s",strerror(errno));

    /* The following is particular to the concurrent boards. */
    set_hw_byte_swap(true);
}

void ReleaseHardware(void)
{
    if (fDevice) close_device(fDevice);    
}


void doWriteBlock(SBC_Packet* aPacket,uint8_t reply)
{
    SBC_VmeWriteBlockStruct* p = (SBC_VmeWriteBlockStruct*)aPacket->payload;
    if(needToSwap) SwapLongBlock(p,sizeof(SBC_VmeWriteBlockStruct)/sizeof(int32_t));

    uint32_t startAddress   = p->address;
    uint32_t oldAddress     = p->address;
    int32_t addressModifier = p->addressModifier;
    int32_t addressSpace    = p->addressSpace;
    int32_t unitSize        = p->unitSize;
    int32_t numItems        = p->numItems;
    TUVMEDevice* memMapHandle;
    bool useDMADevice = false;
    // Quick sanity checks, this is to ensure we are actually requesting
    // a valid address
    if ((addressModifier == 0x29 && startAddress >= 0x10000) ||
        (addressModifier == 0x39 && startAddress >= 0x1000000)) {
            sprintf(aPacket->message,"error: Address modifier requested (%x) but address out of range : %x\n",
                    addressModifier, startAddress);
            if(reply)writeBuffer(aPacket);
            return;
    
    } 

    if (addressSpace == kControlSpace) {
        memMapHandle = controlHandle;
        if (unitSize != sizeof(uint32_t) && numItems != 1) {
            sprintf(aPacket->message,"error: size and number not correct");
            p->errorCode = -1;
            if(reply)writeBuffer(aPacket);
            return;
        }
    } 
	else if(unitSize*numItems >= kDMALowerLimit) {
		useDMADevice = true;
        memMapHandle = get_dma_device(oldAddress, addressModifier, unitSize, addressSpace != kPollSameAddress);
        addressSpace=0x1;
        startAddress = 0x0;
    } 
	else {
        memMapHandle = fDevice;
	}
    
    p++; /*point to the data*/
    if(needToSwap){
        int16_t* sptr;
        int32_t* lptr;
        switch(unitSize){
            case 2: /*shorts*/
                sptr = (int16_t*)p; /* cast to the data type*/ 
                 SwapShortBlock(sptr,numItems);
            break;
            
            case 4: /*longs*/
                lptr = (int32_t*)p; /* cast to the data type*/ 
                SwapLongBlock(lptr,numItems);
            break;
        }
    }
    if (!useDMADevice) lock_device(memMapHandle);
	
	if(memMapHandle==fDevice){
		setup_device(fDevice,oldAddress,addressModifier,unitSize);
    }
    
	int32_t result = 0;
	if (addressSpace == kPollSameAddress) {
        /* We have to poll the same address. */
        int32_t i = 0;
        for (i=0;i<numItems;i++) {
            result = write_device(memMapHandle,(char*)p + i*unitSize,unitSize,startAddress&0xffff);
            if (result != unitSize) break;
        }
        if (result == unitSize) result = unitSize*numItems; 
    } 
	else {
        result = write_device(memMapHandle,(char*)p,numItems*unitSize,startAddress&0xffff);
    }
    if (!useDMADevice) unlock_device(memMapHandle);
    if (useDMADevice)  release_dma_device();
    
    /* echo the structure back with the error code*/
    /* 0 == no Error*/
    /* non-0 means an error*/
    SBC_VmeWriteBlockStruct* returnDataPtr = (SBC_VmeWriteBlockStruct*)aPacket->payload;

    returnDataPtr->address         = oldAddress;
    returnDataPtr->addressModifier = addressModifier;
    returnDataPtr->addressSpace    = addressSpace;
    returnDataPtr->unitSize        = unitSize;
    returnDataPtr->numItems        = 0;

    if(result == (numItems*unitSize)){
        returnDataPtr->errorCode = 0;
    } 
	else {
        aPacket->cmdHeader.numberBytesinPayload = sizeof(SBC_VmeWriteBlockStruct);
        returnDataPtr->errorCode = errno;        
    }

    int32_t* lptr = (int32_t*)returnDataPtr;
    if(needToSwap) SwapLongBlock(lptr,numItems);

    if(reply)writeBuffer(aPacket);    
}

void doReadBlock(SBC_Packet* aPacket,uint8_t reply)
{
    SBC_VmeReadBlockStruct* p = (SBC_VmeReadBlockStruct*)aPacket->payload;
    if(needToSwap) {
        SwapLongBlock(p,sizeof(SBC_VmeReadBlockStruct)/sizeof(int32_t));
    }
    uint32_t startAddress   = p->address;
    uint32_t oldAddress     = p->address;
    int32_t addressModifier = p->addressModifier;
    int32_t addressSpace    = p->addressSpace;
    int32_t unitSize        = p->unitSize;
    int32_t numItems        = p->numItems;
    TUVMEDevice* memMapHandle;
    bool useDMADevice = false;

    if (numItems*unitSize > kSBC_MaxPayloadSizeBytes) {
        sprintf(aPacket->message,"error: requested greater than payload size.");
        p->errorCode = -1;
        if(reply)writeBuffer(aPacket);
        return;
    }
    if (addressSpace == kControlSpace) {
        memMapHandle = controlHandle;
        if (unitSize != sizeof(uint32_t) && numItems != 1) {
            sprintf(aPacket->message,"error: size and number not correct");
            p->errorCode = -1;
            if(reply) writeBuffer(aPacket);
            return;
         }
    } 
    else if(unitSize*numItems >= kDMALowerLimit) {
        // Use DMA access which is normally faster.
		useDMADevice = true;
        memMapHandle = get_dma_device(oldAddress, addressModifier, unitSize, addressSpace != kPollSameAddress);
        //addressSpace =0x1; // reset this for the later call.
        startAddress = 0x0;
    }
    else {
        memMapHandle = fDevice;
    } 

    /*OK, got address and # to read, set up the response and go get the data*/
    aPacket->cmdHeader.destination			= kSBC_Process;
    aPacket->cmdHeader.cmdID				= kSBC_ReadBlock;
    aPacket->cmdHeader.numberBytesinPayload = sizeof(SBC_VmeReadBlockStruct) + numItems*unitSize;

    SBC_VmeReadBlockStruct* returnDataPtr = (SBC_VmeReadBlockStruct*)aPacket->payload;
    char* returnPayload = (char*)(returnDataPtr+1);

    int32_t result = 0;
    
    if (!useDMADevice) lock_device(memMapHandle);
	
	if(memMapHandle==fDevice){	
		setup_device(fDevice,oldAddress,addressModifier,unitSize);
	}
	
    if (addressSpace == kPollSameAddress) {
        /* We have to poll the same address. */
        int32_t i = 0;
        for (i=0;i<numItems;i++) {
            result = read_device(memMapHandle, returnPayload + i*unitSize,unitSize,startAddress&0xffff);
            if (result != unitSize) break;
        }
        if (result == unitSize) result = unitSize*numItems; 
    } 
	else {
        result = read_device(memMapHandle,returnPayload,numItems*unitSize,startAddress&0xffff);
    }
    if (!useDMADevice) unlock_device(memMapHandle);
    if (useDMADevice)  release_dma_device();
    
    returnDataPtr->address         = oldAddress;
    returnDataPtr->addressModifier = addressModifier;
    returnDataPtr->addressSpace    = addressSpace;
    returnDataPtr->unitSize        = unitSize;
    returnDataPtr->numItems        = numItems;
    if(result == (numItems*unitSize)){
        returnDataPtr->errorCode = 0;
        if(needToSwap){
            switch(unitSize){
             case 2: /*shorts*/
                SwapShortBlock((int16_t*)returnPayload,numItems);
                break;
             case 4: /*longs*/
                SwapLongBlock((int32_t*)returnPayload,numItems);
                break;
            }
        }
    }
	else {
        sprintf(aPacket->message,"error: %d %d : %s\n",(int32_t)result,(int32_t)errno,strerror(errno));
        aPacket->cmdHeader.numberBytesinPayload  = sizeof(SBC_VmeReadBlockStruct);
        returnDataPtr->numItems					 = 0;
        returnDataPtr->errorCode				 = errno;        
    }

    if(needToSwap) {
        SwapLongBlock(returnDataPtr, sizeof(SBC_VmeReadBlockStruct)/sizeof(int32_t));
    }
    if(reply)writeBuffer(aPacket);
}


void doGeneralWriteOp(SBC_Packet* aPacket,uint8_t reply)
{
	SBC_WriteBlockStruct* p = (SBC_WriteBlockStruct*)aPacket->payload;
	if(needToSwap)SwapLongBlock(p,sizeof(SBC_WriteBlockStruct)/sizeof(int32_t));
	int32_t operation = p->address;
	int32_t num = p->numLongs;
	p++;
	int32_t* dataToWrite = (int32_t*)p;
	if(needToSwap)SwapLongBlock(dataToWrite,num);
	switch(operation){
		//nothing defined yet
		default:
		break;
	}
	//just return the packet for now...	
	if(reply)writeBuffer(aPacket);
}

void doGeneralReadOp(SBC_Packet* aPacket,uint8_t reply)
{
	//what to read?
	SBC_ReadBlockStruct* p = (SBC_ReadBlockStruct*)aPacket->payload;
	if(needToSwap)SwapLongBlock(p,sizeof(SBC_ReadBlockStruct)/sizeof(int32_t));
	int32_t numLongs = p->numLongs;
	int32_t operation  = p->address;

	//OK, got address and # to read, set up the response and go get the data
	aPacket->cmdHeader.destination	= kSBC_Process;
	aPacket->cmdHeader.cmdID		= kSBC_GeneralRead;
	aPacket->cmdHeader.numberBytesinPayload	= sizeof(SBC_ReadBlockStruct) + numLongs*sizeof(int32_t);
	
	SBC_ReadBlockStruct* dataPtr = (SBC_ReadBlockStruct*)aPacket->payload;
	dataPtr->numLongs = numLongs;
	dataPtr->address  = operation;
	if(needToSwap)SwapLongBlock(dataPtr,sizeof(SBC_ReadBlockStruct)/sizeof(int32_t));
	dataPtr++;
	
	int32_t* lPtr		= (int32_t*)dataPtr;
	int32_t* startPtr	= lPtr;
	int32_t i;
	switch(operation){
		case kGetSoftwareVersion:
			if(numLongs == 1) *lPtr = kCodeVersion;
		break;
		default:
			for(i=0;i<numLongs;i++)*lPtr++ = 0; //yndefined operation so just return zeros
		break;
	}
	if(needToSwap)SwapLongBlock(startPtr,numLongs/sizeof(int32_t));

	if(reply)writeBuffer(aPacket);
}

/*************************************************************/
/*  All HW Readout code for VMEcpu follows here.             */
/*                                                           */
/*  Readout_CARD() function returns the index of the next    */
/*   card to read out                                        */
/*************************************************************/


