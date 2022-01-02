//
//  HW_Readout.cpp
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
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <time.h>
#include <errno.h>

// options of general read and write ops, history and description: see below
//#define kCodeVersion     2
#define kCodeVersion            3 //code version/release 3 is DMA ready -tb-
#define kFdhwLibVersion         2 //2011-06-16 currently not necessary as it is now fetched dirctly from fdhwlib -tb-
#if PMC_LINK_WITH_DMA_LIB
#define kLinkedWithPCIDMALib    1 //2012-04-16 DMA or not? -tb-
#else
#define kLinkedWithPCIDMALib    0 //2012-04-16 DMA or not? -tb-
#endif


//history and description
//
//The SBC protocol provides functions
// void doGeneralWriteOp(SBC_Packet* aPacket,uint8_t reply)
// and
// void doGeneralReadOp(SBC_Packet* aPacket,uint8_t reply)
//
// option 'kGetSoftwareVersion' returns kCodeVersion as value of the code version, current value: see above.


/*
 kCodeVersion history:
 after all major changes in HW_Readout.cc, FLTv4Readout.cc, FLTv4Readout.hh, SLTv4Readout.cc, SLTv4Readout.hh
 kCodeVersion should be increased!
 
 kCodeVersion 2:
 2011-06-16 readout code ships now new register value 'fifoEventID'
 
 kCodeVersion 1:
 January 2011,  implemented general read and write, new
 */ 



#ifdef __cplusplus
extern "C" {
#endif
#include "SBC_Cmds.h"
#include "SBC_Config.h"
#include "SBC_Readout.h"
#include "CircularBuffer.h"
#include "Katrin_HW_Definitions.h"
#include "SLTv4GeneralOperations.h"
#ifdef __cplusplus
}
#endif


#include "fdhwlib.h"
#include "hwamc/baseregister.h"
#include "Pbus/PbusError.h"
#include "hwtristan/subrack.h"
#include "hwtristan/slt.h"
#include "hwtristan/flttristan.h"
#include <akutil/akinifile.h>

#include "HW_Readout.h"


void SwapLongBlock(void* p, int32_t n);
void SwapShortBlock(void* p, int32_t n);
int32_t writeBuffer(SBC_Packet* aPacket);

extern char needToSwap;
extern int32_t  dataIndex;
extern int32_t* data;

Subrack* get_sub_rack() { return srack; }


void processHWCommand(SBC_Packet* aPacket)
{
    /*look at the first word to get the destination*/
    int32_t aCmdID = aPacket->cmdHeader.cmdID;
    
    switch(aCmdID){
        case kKATRINReadHitRates: readHitRates(aPacket); break;
            //default:               processUnknownCommand(aPacket); break;
    }
}


void FindHardware(void)
{
    //open device driver(s), get device driver handles
    const char* name = "amc.ini";
    //TODO: check here blocking semaphores? -tb-
    srack = new Subrack((char*)name,0);
    srack->checkSlot(); //check for available slots (init for isPresent(slot)); is necessary to prepare readout loop! -tb-
    pbus = new Pbus(); // is connected to the Pbus implementation as singleton
    if(!pbus) fprintf(stdout,"HW_Readout.cc (IPE DAQ): ERROR: could not connect to Pbus!\n");
    
    printf("Slots %08lx\n", srack->isPresent());
    
    //
    // Check the hardware; read serial numbers and versions
    //
    int res, resArray[21];
    akInifile *ini;
    Inifile::result error;
    std::string configDir;
    
    // Get path to configuration database
    ini = new akInifile(name, 0, "$HOME");
    if (ini->Status()==Inifile::kSUCCESS){
        ini->SpecifyGroup("OrcaReadout");
        debug = ini->GetFirstValue("debug", 0, &error);
        nSendToOrca = ini->GetFirstValue("sendtoorca", 0, &error);
        ini->SpecifyGroup("trishell");
        configDir = ini->GetFirstString("configdir","",&error);
    }
    delete ini;
    
    if (debug)    printf("OrcaReadout (compiled for %ldbit)\n", sizeof(int)*8);
    if (debug)    printf("Parameter: debug = %d, sendtoorca %d\n", debug, nSendToOrca);
    
    
    res = srack->readExpectedConfig("hardware.ini", configDir.c_str());
    
    
    if (res == 3) {
        
        if (debug){
            printf("-----------------------------------------------------\n");
            printf("Warning: Configuration database fdhwlib-config not found\n");
            printf("   Use the inifile %s to specify where to find hardware.ini\n", name);
            printf("   e.g. configdir = /home/katrin/etc/fdhwlib-config/fpd/\n");
            printf("-----------------------------------------------------\n");
        }
        
    } else {
        
        res = srack->checkConfig(resArray);
        if (res > 0){
            res = 0;
            
            if (debug){
                printf("-----------------------------------------------------\n");
                printf("  Warning: Hardware configuration has changed\n");
                srack->displayHardwareCheck(stdout, resArray, "  ");
                printf("-----------------------------------------------------\n");
            }
            
            res = srack->saveConfig(configDir.c_str());
            
            if (debug) {
                if (res == 0){
                    printf("Saved configuration to  %s\n", configDir.c_str());
                } else {
                    printf("Error saving hardware configuration (err = %d)\n", res);
                }
            }
            
        }
    }
    
}

void ReleaseHardware(void)
{
    //release / close device driver(s)
    pbus = 0;
    delete srack;
}

void doWriteBlock(SBC_Packet* aPacket,uint8_t reply)
{
    SBC_IPEv4WriteBlockStruct* p = (SBC_IPEv4WriteBlockStruct*)aPacket->payload;
    if(needToSwap)SwapLongBlock(p,sizeof(SBC_IPEv4WriteBlockStruct)/sizeof(int32_t));
    
#if 0
    fprintf(stderr, "doWriteBlock: SBC_Packet size %i, SBC_IPEv4WriteBlockStruct size %i, sizeof(unsigned long *)  %i \n",
            sizeof(SBC_Packet),
            sizeof(SBC_IPEv4WriteBlockStruct),
            sizeof(unsigned long *)
            );
    
    fflush(stderr);
    fprintf(stdout, "stdout: stdout  stdout\n");
    fflush(stdout);
#endif
    
    uint32_t startAddress   = p->address;
    uint32_t numItems       = p->numItems;
    
    p++;                                /*point to the data*/
    uint32_t* lptr = (uint32_t*)p;        /*cast to the data type*/
    if(needToSwap) SwapLongBlock(lptr,numItems);
    
    //**** use device driver call to write data to HW
    int32_t perr = 0;
    try {
        //printf("doWriteBlock: adr 0x%08x , val %i (0x%08x) \n",startAddress,*lptr,*lptr);
        //fflush(stdout);
        
        if (numItems == 1){
            pbus->write(startAddress, *lptr);
        }
        else {
            pbus->writeBlock(startAddress, (unsigned long *) lptr, numItems);
        }
    } catch(PbusError &e){
        e.displayMsg(stdout);
        perr = 1;
    }
    
    /* echo the structure back with the error code*/
    /* 0 == no Error*/
    /* non-0 means an error*/
    SBC_IPEv4WriteBlockStruct* returnDataPtr = (SBC_IPEv4WriteBlockStruct*)aPacket->payload;
    returnDataPtr->address         = startAddress;
    returnDataPtr->numItems        = 0;
    
    //assuming that the device driver returns the number of bytes read
    if(perr == 0){
        returnDataPtr->errorCode = 0;
    }
    else {
        aPacket->cmdHeader.numberBytesinPayload = sizeof(SBC_IPEv4WriteBlockStruct);
        returnDataPtr->errorCode = perr;
    }
    
    lptr = (uint32_t*)returnDataPtr;
    if(needToSwap)SwapLongBlock(lptr,numItems);
    
    //send back to ORCA
    if(reply)writeBuffer(aPacket);
    
}

void doReadBlock(SBC_Packet* aPacket,uint8_t reply)
{
    SBC_IPEv4ReadBlockStruct* p = (SBC_IPEv4ReadBlockStruct*)aPacket->payload;
    if(needToSwap) SwapLongBlock(p,sizeof(SBC_IPEv4ReadBlockStruct)/sizeof(int32_t));
    
    uint64_t startAddress   = (((uint64_t) p->address & 0xff000000) << 32) | (p->address & 0x00ffffff);
    int32_t numItems        = p->numItems;
    //TODO: -tb- debug printf("starting read: %08x %d\n",startAddress,numItems);
    
    if (numItems*sizeof(uint32_t) > kSBC_MaxPayloadSizeBytes) {
        sprintf(aPacket->message,"error: requested greater than payload size.");
        p->errorCode = -1;
        if(reply)writeBuffer(aPacket);
        return;
    }
    
    /*OK, got address and # to read, set up the response and go get the data*/
    aPacket->cmdHeader.destination = kSBC_Process;
    aPacket->cmdHeader.cmdID       = kSBC_ReadBlock;
    aPacket->cmdHeader.numberBytesinPayload    = sizeof(SBC_IPEv4ReadBlockStruct) + numItems*sizeof(uint32_t);
    
    SBC_IPEv4ReadBlockStruct* returnDataPtr = (SBC_IPEv4ReadBlockStruct*)aPacket->payload;
    char* returnPayload = (char*)(returnDataPtr+1);
    uint32_t *lPtr = (uint32_t *) returnPayload;
    
    int32_t perr   = 0;
    try {
        if (debug > 1) {
            struct timezone tz;
            struct timeval t0;
            
            gettimeofday(&t0, &tz);
            //printf("%ld.%06ld: doReadBlock addr = %08lx, items = %d\n", t0.tv_sec, t0.tv_usec,
            //        startAddress, numItems);
            //fflush(stdout);
        }
        
        if (numItems == 1){
            *lPtr = pbus->read(startAddress);
        }
        else  {
            pbus->readBlock(startAddress, (unsigned long *) lPtr, numItems);
        }
        
    } catch(PbusError &e){
        e.displayMsg(stdout);
        perr = 1;
    }
    
    returnDataPtr->address         = startAddress;
    returnDataPtr->numItems        = numItems;
    if(perr == 0){
        returnDataPtr->errorCode = 0;
        if(needToSwap) SwapLongBlock((int32_t*)returnPayload,numItems);
    }
    else {
        //TODO: -tb- sprintf(aPacket->message,"error: %d %d : %s\n",perr,(int32_t)errno,strerror(errno));
        aPacket->cmdHeader.numberBytesinPayload = sizeof(SBC_IPEv4ReadBlockStruct);
        returnDataPtr->numItems  = 0;
        returnDataPtr->errorCode = perr;
    }
    
    if(needToSwap) SwapLongBlock(returnDataPtr,sizeof(SBC_IPEv4ReadBlockStruct)/sizeof(int32_t));
    if(reply)writeBuffer(aPacket);
}

void readHitRates(SBC_Packet* aPacket)
{
    katrinV4_HitRateStructure* p = (katrinV4_HitRateStructure*)aPacket->payload;
    if(needToSwap)SwapLongBlock(p,sizeof(katrinV4_HitRateStructure)/sizeof(int32_t));
    int32_t station     = p->station-1;
    int32_t enabledMask = p->enabledMask;
    
    if(srack->theFlt[station]->isPresent()){
        
        for(int32_t chan=0; chan<24;chan++){
            if(enabledMask & (0x1<<chan)){
                //p->hitRates[chan] = srack->theFlt[station]->hitrate->read(chan);
                p->hitRates[chan] = 0;
            } else {
               p->hitRates[chan] = 0;
            }
        }
    }
    
/*
    p->subSeconds   = srack->theSlt->subSecCounter->read();//first read subsec counter!
    p->seconds      = srack->theSlt->secCounter->read();
    p->status       = srack->theSlt->status->read();
*/
    p->subSeconds   = 0;//first read subsec counter!
    p->seconds      = 0;
    p->status       = 0;

    
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    if (writeBuffer(aPacket) < 0) {
        LogError("Read HitRate Error: %s", strerror(errno));
    }
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
        case kSetHostTimeToFLTsAndSLT:
            //if(numLongs == 1) *lPtr = kCodeVersion;
            //if(num!=2) ERROR ...
            //DEBUG    fprintf(stderr,"kSetHostTimeToFLTsAndSLT reply %i, num %i\n",reply,num);
            //DEBUG    fprintf(stderr,"   args 0x%x %u\n",dataToWrite[0],dataToWrite[1]);
            setHostTimeToFLTsAndSLT(dataToWrite);
            break;
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
    aPacket->cmdHeader.destination    = kSBC_Process;
    aPacket->cmdHeader.cmdID        = kSBC_GeneralRead;
    aPacket->cmdHeader.numberBytesinPayload    = sizeof(SBC_ReadBlockStruct) + numLongs*sizeof(int32_t);
    
    SBC_ReadBlockStruct* dataPtr = (SBC_ReadBlockStruct*)aPacket->payload;
    dataPtr->numLongs = numLongs;
    dataPtr->address  = operation;
    if(needToSwap)SwapLongBlock(dataPtr,sizeof(SBC_ReadBlockStruct)/sizeof(int32_t));
    dataPtr++;
    
    int32_t* lPtr        = (int32_t*)dataPtr;
    int32_t* startPtr    = lPtr;
    int32_t i;
    switch(operation){
        case kGetSoftwareVersion:
            if(numLongs == 1) *lPtr = kCodeVersion;
            break;
        case kGetFdhwLibVersion:
            //first test: if(numLongs == 1) *lPtr = kFdhwLibVersion;
            if(numLongs == 1) *lPtr = FDHWLIB_VER;
            break;
        case kGetSltPciDriverVersion:
            if(numLongs == 1) *lPtr = getSltLinuxKernelDriverVersion();
            break;
        case kGetIsLinkedWithPCIDMALib:
            if(numLongs == 1) *lPtr = kLinkedWithPCIDMALib;
            break;
        default:
            for(i=0;i<numLongs;i++)*lPtr++ = 0; //undefined operation so just return zeros
            break;
    }
    if(needToSwap)SwapLongBlock(startPtr,numLongs/sizeof(int32_t));
    
    if(reply)writeBuffer(aPacket);
}




/*--------------------------------------------------------------------------------------
 *        HARDWARE SPECIFIC PART:
 *--------------------------------------------------------------------------------------
 */


/*--------------------------------------------------------------------------------------
 *int getSltLinuxKernelDriverVersion(): search string in /proc/devices, works only for Linux!!
 *--------------------------------------------------------------------------------------
 */
//#include <stdlib.h>  //atioi, strtol
//#include <stdio.h>
//#include <string.h>  //strtstr

//currently we have only Linux, but we want to run simulation mode on all OSs -tb-
#ifdef __linux__
#define DRIVERNAME "xdma"
int getSltLinuxKernelDriverVersion(void)
{
    int version = -2;

/*
    char buf[1024 * 4];
    char *cptr;
    FILE *p;

    p = popen("cat /proc/devices | grep fzk_ipe_slt","r");
    if(p==0){ fprintf(stderr, "could not start popen... -tb-\n"); return version; }
    
    while (!feof(p)){
        fscanf(p,"%s",buf);
        if( (cptr=strstr(buf, DRIVERNAME)) ){  // dont use strncmp, it finds fzk_ipe_slt1, too, which does not exist -tb-
            version = -1;
            if( strlen(buf) == strlen(DRIVERNAME)){ version = 0; break; }   // v0, 1st version "fzk_ipe_slt"
            if( strstr(buf, DRIVERNAME "_dma") ){ version = 1; break;}      // v1, 2nd version "fzk_ipe_slt_dma"
            cptr = cptr + strlen(DRIVERNAME);                               // vX, (X+1)nd version "fzk_ipe_sltX" -> go to string after basename
            version = atoi(cptr);
            //alternative: version = strtol(cptr, (char **) NULL, 10);
            break;
        }
        if(feof(p)) break; //??? is this necessary??? -tb-
    };
    
    pclose(p);
    //printf("version is: %i\n",version);
     
*/

    return version;
}
#else
//non Linux version
int getSltLinuxKernelDriverVersion(void)
{
    int version = -2;
    return version;
}
#endif



void readSltSecSubsec(uint32_t & sec, uint32_t & subsec)
{
    if(!srack) return;
/*
    uint32_t subsecreg   = srack->theSlt->subSecCounter->read();//first read subsec counter!
    sec                  = srack->theSlt->secCounter->read();
    subsec               = ((subsecreg>>11)&0x3fff)*2000   +  (subsecreg & 0x7ff);//TODO: move this to the fdhwlib -tb-
*/
    
    sec = 0;
    subsec = 0;
}



void setHostTimeToFLTsAndSLT(int32_t* args)
{
    unsigned long time = srack->setSecondCounter();
    
    if (debug) {
        if (time > 0)
            fprintf(stdout,"Set second counter to %lds\n", time);
        else
            fprintf(stdout,"The timer was not set properly - repeat!\n");
    }
    
}

