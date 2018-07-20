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
//----------------------------------------------------------------


#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <dlfcn.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>

extern "C" {
#include "HW_Readout.h"
#include "MJD.h"
#include "MJDCmds.h"
#include "SBC_Config.h"
#include "VME_HW_Definitions.h"
#include "SBC_Job.h"
}

#include "ORMTCReadout.hh"
#include "universe_api.h"
#include <errno.h>

extern char             needToSwap;
extern pthread_mutex_t  jobInfoMutex;
extern SBC_JOB          sbc_job;

TUVMEDevice* fpgaDevice = NULL;
bool flashANLVersion = 0;

void processMJDCommand(SBC_Packet* aPacket)
{
	switch(aPacket->cmdHeader.cmdID){
		case kMJDReadPreamps:       readPreAmpAdcs(aPacket);             break;
        case kMJDSingleAuxIO:       singleAuxIO(aPacket);                break;
        case kMJDFlashGretinaFPGA:  flashANLVersion=false; startJob(&flashGretinaFPGA,aPacket); break;
        case kMJDFlashGretinaAFPGA: flashANLVersion=true; startJob(&flashGretinaFPGA,aPacket); break;
        case kMJDReadPreampsANL:    readANLPreAmpAdcs(aPacket);          break;
        case kMJDSingleAuxIOANL:    singleANLAuxIO(aPacket);             break;
	}
}


//------------------ANL Aux I/O ------------------------------
void singleANLAuxIO(SBC_Packet* aPacket)
{
    //create the packet that will be returned
    GRETINA4_SingleAuxIOStruct* p    = (GRETINA4_SingleAuxIOStruct*)aPacket->payload;
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    
    uint32_t baseAddress = p->baseAddress;
    p->spiData = writeANLAuxIOSPI(baseAddress,p->spiData);
    
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    if (writeBuffer(aPacket) < 0) {
        LogError("SingleAuxIO Error: %s", strerror(errno));
    }
}

//read preAmps from the ANL Gretina card
void readANLPreAmpAdcs(SBC_Packet* aPacket)
{
    //create the packet that will be returned
    GRETINA4_PreAmpReadStruct* p    = (GRETINA4_PreAmpReadStruct*)aPacket->payload;
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    
    uint32_t baseAddress = p->baseAddress;
    uint32_t chip        = p->chip;
    uint32_t enabledMask = p->readEnabledMask>>(chip*8); //mask comes for all channels. shift to get the part we care about.
    uint32_t i;
    for(i=0;i<8;i++){
        uint32_t rawValue = 0;
        if(enabledMask & (0x1<<i)){
            //don't like it, but have to do multiple reads because of latencies
             if( i==0 ){
                // one latency here
                rawValue = writeANLAuxIOSPI(baseAddress,p->adc[i]);
                rawValue = writeANLAuxIOSPI(baseAddress,p->adc[i]);
                rawValue = writeANLAuxIOSPI(baseAddress,p->adc[i+1]);
            }
            if( (i>0) && (i<5) ){
                rawValue = writeANLAuxIOSPI(baseAddress,p->adc[i]);
                rawValue = writeANLAuxIOSPI(baseAddress,p->adc[i+1]);
            }
            if( i==5 ){
                // one latency here
                rawValue = writeANLAuxIOSPI(baseAddress,p->adc[i]);
                rawValue = writeANLAuxIOSPI(baseAddress,p->adc[i+1]);
                rawValue = writeANLAuxIOSPI(baseAddress,p->adc[i+1]);
            }
            if( i==6 ){
                // one write here
                rawValue = writeANLAuxIOSPI(baseAddress,p->adc[i]);
            }
            if( i==7 ){
                // catch up with previous writes here
                rawValue = writeANLAuxIOSPI(baseAddress,p->adc[i]);
                rawValue = writeANLAuxIOSPI(baseAddress,p->adc[i]);
                rawValue = writeANLAuxIOSPI(baseAddress,p->adc[i]);
            }
        }
        else rawValue=0;
        p->adc[i] = rawValue;
    }
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    if (writeBuffer(aPacket) < 0) {
        LogError("PreAmp Error: %s", strerror(errno));
    }
}

uint32_t writeANLAuxIOSPI(uint32_t baseAddress,uint32_t spiData)
{
//--------------------------------------------------------------------------------------------------
//Bits 20:19 control whether the Aux I/O pins are inputs or outputs.
//value of "00" sets bits 9:8 and bits 3:0 as enabled outputs, other pins are inputs.
//In this mode the value written to bits 30:21 of this same register (address 0x424) are mapped to the AUX I/O pins:
//Register bit  =>  30   29   28   27   26   25   24   23   22   21
//Aux I/O  bit  =>   9    8    7    6    5    4    3    2    1    0
//When you have bits 20:19 of register 0x424 set to "00", other bits in that register allow you to drive data out of bits
//9:8 and 3:0 of the AUX I/O connector, but the assumption is that bits 7:4 of the connector are inputs.  To read the
//state of the input pins, you read the register at address 0x020.  Bits 7:4 of that register read back the state of
//bits 7:4 of the AUX I/O connector.
//--------------------------------------------------------------------------------------------------

#define kANLSPIDataHi       (0x1 << 22)   //bit 22 of the control/mode/data register
#define kANLSPIDataLo       0x0           //just to have a clean definition for the bit when lo
#define kANLSPIClock        (0x1 << 23)   //bit 23 of the control/mode/data register
#define kANLSPIChipSelect   (0x1 << 24)   //bit 24 of the control/mode/data register
#define kANLSPIRead         (0x1 <<  4)   //bit  4 of status register is the SPIRead pin
    
#define kSPIMode00          (0x00 << 19)  //9:8 and 3:0 outputs, others are inputs
#define kSPIMode01          (0x01 << 19)  //all bits are outputs, driving pulses when channels have hits
#define kSPIMode10          (0x10 << 19)  //all bits are outputs, driving all zeros
#define kSPIMode11          (0x11 << 19)  //same as mode 00 but ALL are outputs
    
    TUVMEDevice* device = get_new_device(baseAddress, 0x09, 4, 0x0);
    uint32_t readBack   = 0;
    if(device!=0){
        uint32_t auxIORead   =  0x020;   //status register
        uint32_t auxIOWrite  =  0x424;   //aux io control/data/mode register
        uint32_t auxIOConfig =  0x424;   //aux io control/data/mode register
        
        uint32_t valueToWrite = (kSPIMode00 | kANLSPIChipSelect | kANLSPIClock);    //set mode, chip select high, clock high
        write_device(device, (char*)(&valueToWrite), 4, auxIOConfig);
        //signify that we are starting
        valueToWrite = kANLSPIChipSelect | kANLSPIClock | kANLSPIDataHi;
        write_device(device, (char*)(&valueToWrite), 4, auxIOWrite);

        uint32_t dataBit;
        uint32_t bit;
        for(bit=0x80000000; bit; bit >>= 1) {
            
            dataBit = (spiData & bit)?kANLSPIDataLo:kANLSPIDataHi;
            
            //write data with clock low
            valueToWrite = kSPIMode00 | kANLSPIChipSelect | dataBit  | kANLSPIClock;
            write_device(device, (char*)(&valueToWrite), 4, auxIOWrite);

            //repeat with clock high
            valueToWrite = kSPIMode00 | kANLSPIChipSelect  | dataBit;
            write_device(device, (char*)(&valueToWrite), 4, auxIOWrite);

            //get the readBack value
            uint32_t valueRead;
            read_device(device,(char*)(&valueRead),4,auxIORead);
            
            if(valueRead & kANLSPIRead){
                readBack |= bit;
            }
        }
        
        //unset kSPIChipSelect to signify that we are done
        valueToWrite = kANLSPIClock | kANLSPIDataHi;
        write_device(device, (char*)(&valueToWrite), 4, auxIOWrite);
        close_device(device);
    }
    return readBack;
}


//------------------LBL Aux I/O ------------------------------
void singleAuxIO(SBC_Packet* aPacket)
{
    //create the packet that will be returned
    GRETINA4_SingleAuxIOStruct* p    = (GRETINA4_SingleAuxIOStruct*)aPacket->payload;
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    
    uint32_t baseAddress = p->baseAddress;
    p->spiData = writeAuxIOSPI(baseAddress,p->spiData);
    
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    if (writeBuffer(aPacket) < 0) {
        LogError("SingleAuxIO Error: %s", strerror(errno));
    }
}


//read preAmps from the LBL Gretina card
void readPreAmpAdcs(SBC_Packet* aPacket)
{
    //create the packet that will be returned
	GRETINA4_PreAmpReadStruct* p    = (GRETINA4_PreAmpReadStruct*)aPacket->payload;
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    
    uint32_t baseAddress = p->baseAddress;
    uint32_t chip        = p->chip;
    uint32_t enabledMask = p->readEnabledMask>>(chip*8); //mask comes for all channels. shift to get the part we care about.
    uint32_t i;
    for(i=0;i<8;i++){
        uint32_t rawValue = 0;
        if(enabledMask & (0x1<<i)){
            //don't like it, but have to do this four times
            //rawValue = writeAuxIOSPI(baseAddress,p->adc[i]);
            //rawValue = writeAuxIOSPI(baseAddress,p->adc[i]);
			//rawValue = writeAuxIOSPI(baseAddress,p->adc[i]);
			//rawValue = writeAuxIOSPI(baseAddress,p->adc[i]);
            if( i==0 ){
                // one latency here
                rawValue = writeAuxIOSPI(baseAddress,p->adc[i]);
                rawValue = writeAuxIOSPI(baseAddress,p->adc[i]);
                rawValue = writeAuxIOSPI(baseAddress,p->adc[i+1]);
            }
            if( (i>0) && (i<5) ){
                
                rawValue = writeAuxIOSPI(baseAddress,p->adc[i]);
                rawValue = writeAuxIOSPI(baseAddress,p->adc[i+1]);
            }
            if( i==5 ){
                
                // one latency here
                rawValue = writeAuxIOSPI(baseAddress,p->adc[i]);
                rawValue = writeAuxIOSPI(baseAddress,p->adc[i+1]);
                rawValue = writeAuxIOSPI(baseAddress,p->adc[i+1]);
            }
            if( i==6 ){
                
                // one write here
                rawValue = writeAuxIOSPI(baseAddress,p->adc[i]);
            }
            if( i==7 ){
                
                // catch up with previous writes here
                rawValue = writeAuxIOSPI(baseAddress,p->adc[i]);
                rawValue = writeAuxIOSPI(baseAddress,p->adc[i]);
                rawValue = writeAuxIOSPI(baseAddress,p->adc[i]);
            }
        }
        else rawValue=0;
        p->adc[i] = rawValue;
        
    }
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    if (writeBuffer(aPacket) < 0) {
        LogError("PreAmp Error: %s", strerror(errno));
    }
}


uint32_t writeAuxIOSPI(uint32_t baseAddress,uint32_t spiData)
{
#define kSPIData	    0x2
#define kSPIClock	    0x4
#define kSPIChipSelect	0x8
#define kSPIRead        0x10
    TUVMEDevice* device = get_new_device(baseAddress, 0x09, 4, 0x0);
    uint32_t readBack = 0;
    if(device!=0){
        
        uint32_t auxIORead   = /*baseAddress +*/ 0x800;
        uint32_t auxIOWrite  = /*baseAddress +*/ 0x804;
        uint32_t auxIOConfig = /*baseAddress +*/ 0x808;
        
        // Set AuxIO to mode 3 and set bits 0-3 to OUT (bit 0 is under FPGA control)
        uint32_t valueToWrite = 0x3025;
        write_device(device, (char*)(&valueToWrite), 4, auxIOConfig);

        // Read kAuxIOWrite to preserve bit 0, and zero bits used in SPI protocol
        uint32_t spiBase;
		read_device(device,(char*)(&spiBase),4,auxIOWrite);
        
        spiBase = spiBase & ~(kSPIData | kSPIClock | kSPIChipSelect);
        
        uint32_t valueRead;
        
        // set kSPIChipSelect to signify that we are starting
        valueToWrite = kSPIChipSelect | kSPIClock | kSPIData;
		write_device(device, (char*)(&valueToWrite), 4, auxIOWrite);
        
        // now write spiData starting from MSB on kSPIData, pulsing kSPIClock
        // each iteration
        uint32_t i;
        for(i=0; i<32; i++) {
            uint32_t rawValueToWrite = spiBase | kSPIChipSelect | kSPIData;
            if( (spiData & 0x80000000) != 0) rawValueToWrite &= (~kSPIData);
            //toggle the kSPIClock bit
            valueToWrite = rawValueToWrite | kSPIClock;
            write_device(device, (char*)(&valueToWrite),    4, auxIOWrite);//clock hi
            write_device(device, (char*)(&rawValueToWrite), 4, auxIOWrite);//clock lo
            
            read_device(device,(char*)(&valueRead),4,auxIORead);
           
            readBack |= ((valueRead & kSPIRead) > 0) << (31-i);
            spiData = spiData << 1;
        }
        
        // unset kSPIChipSelect to signify that we are done
        valueToWrite = kSPIClock | kSPIData;
        write_device(device, (char*)(&valueToWrite), 4, auxIOWrite);
        close_device(device);
    }
    return readBack;
}

void flashGretinaFPGA(SBC_Packet* aPacket)
{
    
#define FILEPATH "/home/daq/GretinaFPGA.bin"
#define NUMINTS  (1000)
#define FILESIZE (NUMINTS * sizeof(int))

	char  errorMessage[255];
	memset(errorMessage,'\0',80);
	uint8_t  finalStatus = 0; //assume failure
    
    MJDFlashGretinaFPGAStruct* p    = (MJDFlashGretinaFPGAStruct*)aPacket->payload;
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    
    uint32_t baseAddress = p->baseAddress;

    fpgaDevice = get_new_device(baseAddress, 0x09, 4, 0x0);
    
    pthread_mutex_lock (&jobInfoMutex);     //begin critical section
    sbc_job.running = 1;
    pthread_mutex_unlock (&jobInfoMutex);   //end critical section
    
    if(fpgaDevice!=0){
        blockEraseFlash();
        //memory map the fpga file and get a pointer to it
        int32_t   fd;
        uint8_t* map;  /* mmapped array of int's */
        
        fd = open(FILEPATH, O_RDONLY);
        if (fd == -1) strcpy(errorMessage,"Error");
        else {
            struct stat sb;
            fstat(fd, &sb);

            map = (uint8_t*)mmap(0, sb.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
            if (map == MAP_FAILED) {
                close(fd);
                strcpy(errorMessage,"Error");
            }
            else {
                programFlashBuffer(map,sb.st_size);
                if(verifyFlashBuffer(map,sb.st_size)&& !sbc_job.killJobNow){
                    strcpy(errorMessage,"Done$No Errors Reported");
                    if(flashANLVersion==false)  reloadMainFpgaFromFlash();
                    else                        reloadMainFpgaFromFlash_ANL();
                    finalStatus = 1;
                }
                else {
                    if(sbc_job.killJobNow){
                        strcpy(errorMessage,"User Halted");
                    }
                    else strcpy(errorMessage,"Error");
                    finalStatus = 0;
                }
                if (munmap(map, FILESIZE) == -1) strcpy(errorMessage,"Error");
                
            }
            close(fd);
        }
        close_device(fpgaDevice);
    }
    else {
		strcpy(errorMessage,"Unable to get device.");
    }
    
    pthread_mutex_lock (&jobInfoMutex);     //begin critical section
    sbc_job.progress    = 0;
    sbc_job.running     = 0;
    sbc_job.killJobNow  = 0;
    sbc_job.finalStatus = finalStatus;
    strncpy(sbc_job.message,errorMessage,255);
    sbc_job.message[255] = '\0';
    pthread_mutex_unlock (&jobInfoMutex);   //end critical section
}


void blockEraseFlash()
{
    setJobStatus("Block Erase",0);
    /* We only erase the blocks currently used in the  specification. */
    
    // Set VPEN signal == 1
    writeDevice(kVMEGPControlReg, kFlashEnableWrite);
	
    // Erase [first quarter of] flash
    int32_t count = 0;
    int32_t end = (kFlashBlocks / 4) * kFlashBlockSize;
    for (int32_t addr = 0; addr < end; addr += kFlashBlockSize) {
        if(sbc_job.killJobNow)break;
        char str[255];
        sprintf(str,"Block Erase$%d of %d Blocks Erased",count++,kFlashBufferBytes);
        setJobStatus(str,100. * (count+1)/(float)kFlashBufferBytes);
        
        writeDevice(kFlashAddressReg, addr);
        writeDevice(kFlashCommandReg, kFlashBlockEraseCmd);
        writeDevice(kFlashCommandReg, kFlashConfirmCmd);
        
        uint32_t stat;
        readDevice(kMainFPGAStatusReg, &stat);
        while (stat & kFlashBusy) {
            if(sbc_job.killJobNow)break;
            readDevice(kMainFPGAStatusReg, &stat);
        }
    }
	   
    if(sbc_job.killJobNow){
        setJobStatus("User Halted",0);
    }
}

void programFlashBuffer(uint8_t* theData, uint32_t totalSize)
{
    char statusString[255];
    sprintf(statusString,"Programming");
    setJobStatus(statusString,0);
    
    writeDevice(kFlashAddressReg,0x0);
    writeDevice(kFlashCommandReg,kFlashReadArrayCmd);    //set to array mode
    
	uint32_t address = 0x0;
	while (address < totalSize ) {
        uint32_t numberBytesToWrite;
        if(totalSize-address >= kFlashBufferBytes)  numberBytesToWrite = kFlashBufferBytes;   //whole block
        else                                        numberBytesToWrite = totalSize - address; //near eof -- partial block
        
        programFlashBufferBlock(theData,address,numberBytesToWrite);
        
        address += numberBytesToWrite;
        
        sprintf(statusString,"Programming$Flashed: %d/%d KB",address/1000,totalSize/1000);
        setJobStatus(statusString,100. * address/(float)totalSize);
        
        if(sbc_job.killJobNow)break;;

	}
    if(sbc_job.killJobNow)return;
    writeDevice(kFlashAddressReg, 0x00);
    writeDevice(kFlashCommandReg, kFlashReadArrayCmd);    //set to array mode
    writeDevice(kVMEGPControlReg, 0x0);
    setJobStatus("Programming Done",0);
}

void programFlashBufferBlock(uint8_t* theData,uint32_t anAddress,uint32_t aNumber)
{
    uint32_t statusRegValue;

    //issue the set-up command at the starting address
    writeDevice(kFlashAddressReg,anAddress);
    writeDevice(kFlashCommandReg,kFlashWriteCmd);
    
	while(1) {
        if(sbc_job.killJobNow)return;
		
		// Checking status to make sure that flash is ready
        readDevice(kMainFPGAStatusReg,&statusRegValue);
		
		if ( (statusRegValue & kFlashBusy)  == kFlashBusy ) {
            //not ready, so re-issue the set-up command
            writeDevice(kFlashAddressReg,anAddress);
            writeDevice(kFlashCommandReg, kFlashWriteCmd);
		}
        else break;
	}
    
	//Set the word count. Max is 0xF.
	uint32_t valueToWrite = (aNumber/2) - 1;
    writeDevice(kFlashCommandReg,valueToWrite );
	
	// Loading all the words in
    /* Load the words into the bufferToWrite */
	uint32_t i;
	for ( i=0; i<aNumber; i+=4 ) {
        uint32_t* lPtr = (uint32_t*)&theData[anAddress+i];
        writeDevice(kFlashDataAutoIncReg, lPtr[0]);
	}
	
    // Confirm the write
    writeDevice(kFlashCommandReg, kFlashConfirmCmd);
    
    readDevice(kMainFPGAStatusReg,&statusRegValue);
    while(statusRegValue & kFlashBusy) {
        if(sbc_job.killJobNow)return;
        readDevice(kMainFPGAStatusReg,&statusRegValue);
    }

}


uint8_t verifyFlashBuffer(uint8_t* theData, uint32_t totalSize)
{
    char statusString[255];
    setJobStatus("Verifying",0);
	/* First reset to make sure it is read mode. */
    
    writeDevice(kFlashAddressReg,0x0);
    writeDevice(kFlashCommandReg,kFlashReadArrayCmd);    //set to array mode
    
    uint32_t errorCount =   0;
	uint32_t address    =   0;
	uint32_t valueToRead;
	uint32_t valueToCompare;
	while ( address < totalSize ) {
        readDevice(kFlashDataAutoIncReg,&valueToRead);

		/* Now compare to file*/
		if ( address + 3 < totalSize) {
            uint32_t* ptr = (uint32_t*)&theData[address];
            valueToCompare = ptr[0];
		}
        else {
            //less than four bytes left
			uint32_t numBytes = totalSize - address - 1;
			valueToCompare = 0;
			uint32_t i;
			for ( i=0;i<numBytes;i++) {
				valueToCompare += (((uint32_t)theData[address]) << i*8) & (0xFF << i*8);
			}
		}
		if ( valueToRead != valueToCompare ) {
            errorCount++;
		}
        sprintf(statusString,"Verifying$Verified: %d/%d KB Errors: %d",address/1000,totalSize/1000,errorCount);
        setJobStatus(statusString, 100. * address/(float)totalSize);
		address += 4;
	}
    if(errorCount==0){
        setJobStatus("Done$No Errors", 0);
        return 1;
    }
    else {
        setJobStatus("Error$Comparision Error", 0);
        return 0;
    }
}

void reloadMainFpgaFromFlash()
{
    //LBL version
    writeDevice(kMainFPGAControlReg,kResetMainFPGACmd);
    writeDevice(kMainFPGAControlReg,kReloadMainFPGACmd);
    setJobStatus("FinishingLBL$Flash Memory-->FPGA", 0);
    //wait until done or timeout
    time_t start = time(NULL);
    uint32_t statusRegValue;
    readDevice(kMainFPGAStatusReg,&statusRegValue);
    while(!(statusRegValue & kMainFPGAIsLoaded)) {
        if(sbc_job.killJobNow)return;
        readDevice(kMainFPGAStatusReg,&statusRegValue);
        if(time(NULL) > start+10){
            setJobStatus("Timeout$Flash Memory", 0);
            break;
        }
    }
}

void reloadMainFpgaFromFlash_ANL()
{
//ANL version
    time_t start = time(NULL);
    uint32_t statusRegValue;
    readDevice(kMainFPGAStatusReg,&statusRegValue);
    setJobStatus("FinishingLBL$Flash Memory-->FPGA", 0);

    writeDevice(kANLMainFPGAControlReg,0x2); //acknowledge power-up is complete
    writeDevice(kANLMainFPGAControlReg,0x0); //remove acknowledge
    writeDevice(kANLMainFPGAControlReg,0x1); //ask for  reconfiguration

    readDevice(kMainFPGAStatusReg,&statusRegValue);

    while(!(statusRegValue & 0x01)) {
        if(sbc_job.killJobNow)return;
        readDevice(kMainFPGAStatusReg,&statusRegValue);
       if(time(NULL) > start+10){
           setJobStatus("Timeout$Flash Memory", 0);
           break;
        }
    }
    printf("got here 2: 0x%08x\n",statusRegValue);

    writeDevice(kANLMainFPGAControlReg,0x0); //remove request
}

void setJobStatus(const char* message,uint32_t progress)
{
	char  errorMessage[255];
    strcpy(errorMessage,message);
    pthread_mutex_lock (&jobInfoMutex);         //begin critical section
    strncpy(sbc_job.message,errorMessage,255);
    sbc_job.progress = progress;                //percent done
    pthread_mutex_unlock (&jobInfoMutex);       //end critical section
}

void readDevice(uint32_t address,uint32_t* retValue)
{
    uint32_t stat;
    read_device(fpgaDevice,(char*)(&stat),4,address);
    *retValue = stat;
}

void writeDevice(uint32_t address,uint32_t aValue)
{
    write_device(fpgaDevice,(char*)(&aValue),4,address);
}
