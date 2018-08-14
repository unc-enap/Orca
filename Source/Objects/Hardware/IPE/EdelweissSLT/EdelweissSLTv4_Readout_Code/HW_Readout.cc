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
#define kCodeVersion     2
#define kFdhwLibVersion  2 //2011-06-16 currently not necessary as it is now fetched dirctly from fdhwlib -tb-

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
 
 kCodeVersion 3:
 2013-12-13 readout code ships now 'fltEventID' event records
 
 kCodeVersion 2:
 2011-06-16 readout code ships now new register value 'fifoEventID'
 
 kCodeVersion 1:
 January 2011,  implemented general read and write, new
 */ //-tb-




#ifdef __cplusplus
extern "C" {
#endif
#include "SBC_Cmds.h"
#include "SBC_Config.h"
#include "SBC_Readout.h"
#include "CircularBuffer.h"
#include "EdelweissSLTv4_HW_Definitions.h"
#include "EdelweissSLTv4GeneralOperations.h"
#include "SBC_Job.h"
#ifdef __cplusplus
}
#endif

#ifndef PMC_COMPILE_IN_SIMULATION_MODE
#define PMC_COMPILE_IN_SIMULATION_MODE 0
#endif

#if (PMC_COMPILE_IN_SIMULATION_MODE == 1)
#warning MESSAGE: HW_Readout: PMC_COMPILE_IN_SIMULATION_MODE is 1
#else
#warning MESSAGE: HW_Readout: PMC_COMPILE_IN_SIMULATION_MODE is 0
#endif




#if PMC_COMPILE_IN_SIMULATION_MODE
# warning MESSAGE: PMC_COMPILE_IN_SIMULATION_MODE is 1
#else
//# warning MESSAGE: PMC_COMPILE_IN_SIMULATION_MODE is 0
#include "fdhwlib.h"
//already included #include "Pbus/Pbus.h"
#include "hw4/baseregister.h"
//#include "katrinhw4/subrackkatrin.h"
#include "katrinhw4/sltkatrin.h"
#include "katrinhw4/fltkatrin.h"
#endif

#include "HW_Readout.h"// provides 'Pbus * pbus' pointer


#include "ipe4structure.h"
//#include "ipe4reader.h"
#include "ipe4tbtools.h" //better include in HW_Readout.h? here: MUST follow "ipe4structure.h" (and HW_Readout.h for pbus) -tb-
int (*sendChargeBBStatusFunctionPtr)(uint32_t prog_status,int numFifo) = 0;
#include "ipe4tbtools.cpp"

void SwapLongBlock(void* p, int32_t n);
void SwapShortBlock(void* p, int32_t n);
int32_t writeBuffer(SBC_Packet* aPacket);

extern char needToSwap;
extern int32_t  dataIndex;
extern int32_t* data;

//from SBC_Readout.c ... (for SBC 'job running facility') -tb-
extern SBC_JOB        sbc_job;
extern pthread_mutex_t jobInfoMutex;

//hw4::SubrackKatrin* get_sub_rack() { return srack; }


Pbus *pbus=0;              //for register access with fdhwlib
uint32_t presentFLTMap =0;


#if !PMC_COMPILE_IN_SIMULATION_MODE
// (this is the standard code accessing the v4 crate-tb-)
//----------------------------------------------------------------


void processHWCommand(SBC_Packet* aPacket)
{
    printf("Called SLT::processHWCommand(SBC_Packet* aPacket)\n");
    /*look at the first word to get the destination*/
    //int32_t destination = aPacket->cmdHeader.destination;// we have only the PMC of the IPE4 crate -tb-
    /*look at the first word to get the destination*/
    int32_t aCmdID = aPacket->cmdHeader.cmdID;
    
    switch(aCmdID){
        case kEdelweissSLTchargeBB:        processChargeBBCommand(aPacket); break;
        case kEdelweissSLTchargeFIC:    processChargeFICCommand(aPacket); break;
        default:            break;
            //        default:              processUnknownCommand(aPacket); break;
    }
}


void processChargeBBCommand(SBC_Packet* aPacket)
{
    printf("Called SLT::processChargeBBCommand(SBC_Packet* aPacket)\n");
    startJob(&chargeBB,aPacket);
}

//this should maybe go to OREdelweissSLTv4Readout.cc (?) -tb-
//see tbtools.c, function "int chargeBBWithFILEPtr(FILE * fichier,int * numserie, int numFifo)"
void chargeBB(SBC_Packet* aPacket)// see void loadXL2Xilinx_penn(SBC_Packet* aPacket)
{
    //
    //this function is meant to be launched as a job
    //
    EdelweissSLTchargeBBStruct* p = (EdelweissSLTchargeBBStruct*)aPacket->payload;
    //swap if needed, but note that we don't swap the data file part
    if(needToSwap) SwapLongBlock(p,sizeof(EdelweissSLTchargeBBStruct)/sizeof(int32_t));
    
    //pull the addresses and other data from the payload
    uint32_t length                    = p->fileSize;
    uint8_t* charData                = (uint8_t*)p;            //recast p so we can treat it like a char ptr.
    charData += sizeof(EdelweissSLTchargeBBStruct);                //point to the clock file data
    
    char  errorMessage[80];
    memset(errorMessage,'\0',80);
    uint32_t  errorFlag     = 0;
    uint32_t  finalStatus = 0; //assume failure
    
    //request semaphore
    //TODO:
    //TODO:
    //TODO:
    //TODO:
    
    //prepare loading
    usleep(500000);
    usleep(100000);
    pbus->write(CmdFIFOReg ,  235);
    
    printf("Switch BB to microprocessor mode ...\n");
    usleep(50000);    pbus->write(CmdFIFOReg ,  256);//  une data a zero
    usleep(50000);    pbus->write(CmdFIFOReg ,  256);//  une data a zero
    usleep(50000);    pbus->write(CmdFIFOReg ,  256);//  une data a zero
    usleep(50000);    pbus->write(CmdFIFOReg ,  256);//  une data a zero
    usleep(100000);    // laisser le temps (0.1sec) pour que le biphase se rende compte que l'horloge est arretee
    
    
    uint32_t  b,i;
    b=0x0120;
    for(i=0;i<10;i++)    pbus->write(CmdFIFOReg ,  b++);  // ici avec _attente_cmd_vide ca ne marche pas
    
    uint32_t  size=length;
    printf("fichier de programmation : %d octets \n",(int)size);
    b=(size & 0xff) + 0x0100;         pbus->write(CmdFIFOReg, b);//_attente_cmd_vide
    b=( (size>>8) & 0xff ) + 0x0100;  pbus->write(CmdFIFOReg, b);//_attente_cmd_vide
    b=( (size>>16) & 0xff ) + 0x0100; pbus->write(CmdFIFOReg, b);//_attente_cmd_vide
    b=( (size>>24) & 0xff ) + 0x0100; pbus->write(CmdFIFOReg, b);//_attente_cmd_vide
    usleep(10000);    // attente pour mise en mode conf du fpga (10 msec)
    
    //now do the loading
    uint32_t n,data_start, data_end;
    data_start=0;
    data_end=1000;
    for(i=0; i<1000; i++){
        
        if(sbc_job.killJobNow){
            //FATAL_ERROR(666,"Job Killed. Early Exit.")
            strncpy(errorMessage,"Job Killed. Early Exit.",80);    errorFlag = 666; finalStatus = errorFlag;    goto earlyExit;
        }
        
        //do the job
        //usleep(100000);
        //we write bunches of 1000 bytes to the comand FIFO
        for(n=data_start; n<data_end; n++){
            b=( (unsigned short) charData[n] ) + 0x0100;
            pbus->write(CmdFIFOReg, b);
            _attente_cmd_vide
        }
        
        //job monitoring
        strcpy(errorMessage,"chargeBB: loop running.");
        printf("SBC job loop: i=%i; job message: %s\n",i,errorMessage);
        strncpy(sbc_job.message,errorMessage,255);
        pthread_mutex_lock (&jobInfoMutex);     //begin critical section
        sbc_job.progress = ((double)i)/2.5;                    //percent done
        sbc_job.finalStatus = finalStatus;
        pthread_mutex_unlock (&jobInfoMutex);   //end critical section
        
        if(data_end==size) break;//end loop: this was the last block
        data_start=data_end;
        data_end+=1000; if(data_end>size) data_end=size;
    }
    
    //finish loading
    printf("Charging BB finished ... \n");
    usleep(50000);    pbus->write(CmdFIFOReg ,  256);//  une data a zero
    usleep(50000);    pbus->write(CmdFIFOReg ,  256);//  une data a zero
    //usleep(50000);    write_word(driver_fpga,REG_CMD, (uint32_t) 256);    //  une data a zero
    //usleep(50000);    write_word(driver_fpga,REG_CMD, (uint32_t) 256);    //  une data a zero
    
    usleep(500000);    // laisser le temps pour lire le message d'erreur eventuel
    b=0x200;  pbus->write(CmdFIFOReg, b);  //fin de commande
    //-tb- old code: b=0x200;  write_word(driver_fpga,REG_CMD, b);  //fin de commande
    usleep(500000);    // laisser le temps pour lire le message d'erreur eventuel
    printf("on attend 2 pour terminer : ");
    
    //job done -> success
    finalStatus=1;//flags success
    strcpy(errorMessage,"chargeBB: loop finished.");
    
    
earlyExit://no success
    
    //house keeping
    
    pthread_mutex_lock (&jobInfoMutex);     //begin critical section
    sbc_job.progress    = 100;
    sbc_job.running     = 0;
    sbc_job.killJobNow  = 0;
    sbc_job.finalStatus = finalStatus;
    strncpy(sbc_job.message,errorMessage,255);
    sbc_job.message[255] = '\0';
    pthread_mutex_unlock (&jobInfoMutex);   //end critical section
    
    
    
}



//this should maybe go to OREdelweissSLTv4Readout.cc (?) -tb-
void chargeBB_template_without_HW_access(SBC_Packet* aPacket)// see void loadXL2Xilinx_penn(SBC_Packet* aPacket)
{
    //
    //this function is meant to be launched as a job
    //
    EdelweissSLTchargeBBStruct* p = (EdelweissSLTchargeBBStruct*)aPacket->payload;
    //swap if needed, but note that we don't swap the data file part
    if(needToSwap) SwapLongBlock(p,sizeof(EdelweissSLTchargeBBStruct)/sizeof(int32_t));
    
    //pull the addresses and other data from the payload
    uint32_t length                    = p->fileSize;
    uint8_t* charData                = (uint8_t*)p;            //recast p so we can treat it like a char ptr.
    charData += sizeof(EdelweissSLTchargeBBStruct);                //point to the clock file data
    
    char  errorMessage[80];
    memset(errorMessage,'\0',80);
    uint32_t  errorFlag     = 0;
    uint32_t  finalStatus = 0; //assume failure
    
    //now do the loading
    uint32_t i;
    for(i=0; i<100; i++){
        
        if(sbc_job.killJobNow){
            //FATAL_ERROR(666,"Job Killed. Early Exit.")
            strncpy(errorMessage,"Job Killed. Early Exit.",80);    errorFlag = 666; finalStatus = errorFlag;    goto earlyExit;
        }
        
        usleep(100000);
        
        //job monitoring
        strcpy(errorMessage,"chargeBB: loop running.");
        printf("SBC job loop: %i; job message: %s\n",i,errorMessage);
        strncpy(sbc_job.message,errorMessage,255);
        pthread_mutex_lock (&jobInfoMutex);     //begin critical section
        sbc_job.progress = i;                    //percent done
        sbc_job.finalStatus = finalStatus;
        pthread_mutex_unlock (&jobInfoMutex);   //end critical section
    }
    
    //job done -> success
    finalStatus=1;//flags success
    strcpy(errorMessage,"chargeBB: loop finished.");
    
    
earlyExit://no success
    
    
    pthread_mutex_lock (&jobInfoMutex);     //begin critical section
    sbc_job.progress    = 100;
    sbc_job.running     = 0;
    sbc_job.killJobNow  = 0;
    sbc_job.finalStatus = finalStatus;
    strncpy(sbc_job.message,errorMessage,255);
    sbc_job.message[255] = '\0';
    pthread_mutex_unlock (&jobInfoMutex);   //end critical section
    
    
    
}


/****************************** Denis *************************/

void send_BBcmd(char bb_id, char subadd, char byte_high, char byte_low) { // bb_id = 255 for broadcast
    //    int b;
    
    pbus->write(CmdFIFOReg, 0xf0);
    pbus->write(CmdFIFOReg, bb_id + 0x0100);//BB id
    pbus->write(CmdFIFOReg, subadd + 0x0100);// sub-address
    pbus->write(CmdFIFOReg, byte_high + 0x0100);//data high
    pbus->write(CmdFIFOReg, byte_low + 0x0100);//data low
    pbus->write(CmdFIFOReg, 0x200);//end cmd
    usleep(1800);
    //    _attente_cmd_vide
    
    
}  /****************************** Denis *************************/



void processChargeFICCommand(SBC_Packet* aPacket)
{
    printf("Called SLT::processChargeFICCommand(SBC_Packet* aPacket)\n");
    startJob(&chargeFIC,aPacket);
}

//this should maybe go to OREdelweissSLTv4Readout.cc (?) -tb-
//see tbtools.c, function "int chargeBBWithFILEPtr(FILE * fichier,int * numserie, int numFifo)"
void chargeFIC(SBC_Packet* aPacket)// see void loadXL2Xilinx_penn(SBC_Packet* aPacket)
{
    
    //
    //this function is meant to be launched as a job
    //
    EdelweissSLTchargeBBStruct* p = (EdelweissSLTchargeBBStruct*)aPacket->payload;
    //swap if needed, but note that we don't swap the data file part
    if(needToSwap) SwapLongBlock(p,sizeof(EdelweissSLTchargeBBStruct)/sizeof(int32_t));
    
    //pull the addresses and other data from the payload
    uint32_t length                    = p->fileSize;
    uint8_t* charData                = (uint8_t*)p;            //recast p so we can treat it like a char ptr.
    charData += sizeof(EdelweissSLTchargeBBStruct);                //point to the clock file data
    
    char  errorMessage[80];
    memset(errorMessage,'\0',80);
    uint32_t  errorFlag     = 0;
    uint32_t  finalStatus = 0; //assume failure
    
    //request semaphore
    //TODO:
    //TODO:
    //TODO:
    //TODO:
    uint32_t  b,i;
    
    //this is the "chargeBB" code start sequence, removed -tb-
#if 0
    //prepare loading
    usleep(500000);
    usleep(100000);
    pbus->write(CmdFIFOReg ,  235);
    
    printf("Switch FIC to microprocessor mode ...\n");
    usleep(50000);    pbus->write(CmdFIFOReg ,  256);//  une data a zero
    usleep(50000);    pbus->write(CmdFIFOReg ,  256);//  une data a zero
    usleep(50000);    pbus->write(CmdFIFOReg ,  256);//  une data a zero
    usleep(50000);    pbus->write(CmdFIFOReg ,  256);//  une data a zero
    usleep(100000);    // laisser le temps (0.1sec) pour que le biphase se rende compte que l'horloge est arretee
    
    b=0x0120;
    for(i=0;i<10;i++)    pbus->write(CmdFIFOReg ,  b++);  // ici avec _attente_cmd_vide ca ne marche pas
    
    uint32_t  size=length;
    printf("fichier de programmation : %d octets \n",(int)size);
    b=(size & 0xff) + 0x0100;         pbus->write(CmdFIFOReg, b);//_attente_cmd_vide
    b=( (size>>8) & 0xff ) + 0x0100;  pbus->write(CmdFIFOReg, b);//_attente_cmd_vide
    b=( (size>>16) & 0xff ) + 0x0100; pbus->write(CmdFIFOReg, b);//_attente_cmd_vide
    b=( (size>>24) & 0xff ) + 0x0100; pbus->write(CmdFIFOReg, b);//_attente_cmd_vide
    usleep(10000);    // attente pour mise en mode conf du fpga (10 msec)
#endif
    uint32_t  size=length;
    uint8_t blo,bhi;
    
    //as start sequence: W command (see sendCommandFifo(...))
    //b=0xf0; //this is either 255/0xff (command 'h') or 240/0xf0 (commande 'W')
    //pbus->write(CmdFIFOReg, b);
    //usleep(50000);
    
    //gve some time to wait until cmd fifo empty ....
    _attente_cmd_vide
    
    //now do the loading
    uint32_t n,data_start, data_end;
    data_start=0;
    data_end=1000;
    
    /****************************** Denis *************************/
    // 1. Prepare FIC card
    //    send_BBcmd(0xff, 0x73, 0x00, 0x00); // switch on ADC clock
    pbus->write(CmdFIFOReg, 0xf0);
    pbus->write(CmdFIFOReg, 0xff + 0x0100);//BB id
    pbus->write(CmdFIFOReg, 0x73 + 0x0100);// sub-address
    pbus->write(CmdFIFOReg, 0x00 + 0x0100);//data high
    pbus->write(CmdFIFOReg, 0x00 + 0x0100);//data low
    pbus->write(CmdFIFOReg, 0x200);//end cmd
    usleep(1800);
    //    send_BBcmd(0xff, 0x71, 0x00, 0x00); // stop data taking into RAM
    pbus->write(CmdFIFOReg, 0xf0);
    pbus->write(CmdFIFOReg, 0xff + 0x0100);//BB id
    pbus->write(CmdFIFOReg, 0x71 + 0x0100);// sub-address
    pbus->write(CmdFIFOReg, 0x00 + 0x0100);//data high
    pbus->write(CmdFIFOReg, 0x00 + 0x0100);//data low
    pbus->write(CmdFIFOReg, 0x200);//end cmd
    usleep(1800);
    usleep(10000);
    usleep(10000);
    // 2. Write incoming data to RAM
    //    send_BBcmd(0xff, 0x75, 0x00, 0x01); // config2ram flag
    pbus->write(CmdFIFOReg, 0xf0);
    pbus->write(CmdFIFOReg, 0xff + 0x0100);//BB id
    pbus->write(CmdFIFOReg, 0x75 + 0x0100);// sub-address
    pbus->write(CmdFIFOReg, 0x00 + 0x0100);//data high
    pbus->write(CmdFIFOReg, 0x01 + 0x0100);//data low
    pbus->write(CmdFIFOReg, 0x200);//end cmd
    usleep(1800);
    usleep(10000);
    
    
    // 3. send .pof file with 2bytes / 1ms
    //// send bytes 156...68555 only!
    printf("Charging FIC ... \n");
    uint16_t checksum = 0;
    for(i=156; i<68555; i+=2){ // 68400 bytes
        checksum = checksum + charData[i];
        checksum = checksum + charData[i+1];
        if (i % 2048 == 0) {
            //job monitoring
            strcpy(errorMessage,"chargeFIC: loop running.");
            printf("SBC job loop: i=%i; job message: %s\n",i,errorMessage);
            strncpy(sbc_job.message,errorMessage,255);
            pthread_mutex_lock (&jobInfoMutex);     //begin critical section
            sbc_job.progress = (i*3)/2048; //(double)(i*3)/2048;    //percent done
            sbc_job.finalStatus = finalStatus;
            pthread_mutex_unlock (&jobInfoMutex);   //end critical section
            usleep(20000);
        }
        
        //        send_BBcmd(0xff, 0x76, (charData[i+1] & 0xff), (charData[i] & 0xff));
        pbus->write(CmdFIFOReg, 0xf0);
        pbus->write(CmdFIFOReg, 0xff + 0x0100);//BB id
        pbus->write(CmdFIFOReg, 0x76 + 0x0100);//charge FIC cmd
        pbus->write(CmdFIFOReg, (charData[i+1] & 0xff) + 0x0100);//data
        pbus->write(CmdFIFOReg, (charData[i] & 0xff) + 0x0100);//data
        pbus->write(CmdFIFOReg, 0x200);//end cmd
        usleep(1800);
        //    _attente_cmd_vide
    }
    usleep(10000); //
    // 4. Copy config data from RAM into EEPROM
    //    send_BBcmd(0xff, 0x75, 0x00, 0x02); // config2eprom flag
    pbus->write(CmdFIFOReg, 0xf0);
    pbus->write(CmdFIFOReg, 0xff + 0x0100);//BB id
    pbus->write(CmdFIFOReg, 0x75 + 0x0100);// sub-address
    pbus->write(CmdFIFOReg, 0x00 + 0x0100);//data high
    pbus->write(CmdFIFOReg, 0x02 + 0x0100);//data low
    pbus->write(CmdFIFOReg, 0x200);//end cmd
    usleep(1800);
    for (i=0; i < 25; i++) {
        if (i == 0) {
            strcpy(errorMessage,"Erase EEPROM ....");
            strncpy(sbc_job.message,errorMessage,255);
            printf("Erase EEPROM ... \n");
        }
        if (i == 4) {
            strcpy(errorMessage,"Write to EEPROM ....");
            strncpy(sbc_job.message,errorMessage,255);
            printf("Write to EEPROM ... \n");
        }
        pthread_mutex_lock (&jobInfoMutex);     //begin critical section
        sbc_job.progress = (i*4); //(double)(i*3)/2048;    //percent done
        sbc_job.finalStatus = finalStatus;
        pthread_mutex_unlock (&jobInfoMutex);   //end critical section
        
        usleep(1000000); // 1 sec.
        
    }
    // 5. send chechsum on channel 0
    //    send_BBcmd(0xff, 0x75, 0x00, 0x04); // send_checksum flag
    pbus->write(CmdFIFOReg, 0xf0);
    pbus->write(CmdFIFOReg, 0xff + 0x0100);//BB id
    pbus->write(CmdFIFOReg, 0x75 + 0x0100);// sub-address
    pbus->write(CmdFIFOReg, 0x00 + 0x0100);//data high
    pbus->write(CmdFIFOReg, 0x04 + 0x0100);//data low
    pbus->write(CmdFIFOReg, 0x200);//end cmd
    usleep(1800);
    sprintf(errorMessage,"Charging FIC finished ... checksum = 0x4F", checksum);
    strncpy(sbc_job.message,errorMessage,255);
    printf("Charging FIC finished ... checksum = 0x4F\n", checksum);
    /****************************** Denis *************************/
    /*
     for(i=0; i<1000; i++){
     
     if(sbc_job.killJobNow){
     //FATAL_ERROR(666,"Job Killed. Early Exit.")
     strncpy(errorMessage,"Job Killed. Early Exit.",80);    errorFlag = 666; finalStatus = errorFlag;    goto earlyExit;
     }
     
     //do the job
     //usleep(100000);
     //we write bunches of 1000 bytes to the comand FIFO
     for(n=data_start; n<data_end; n+=2){
     blo = charData[n];
     bhi = charData[n+1];
     //b=(((unsigned short) bhi)<<8) | ((unsigned short) blo);
     //b= ((unsigned short) blo);
     pbus->write(CmdFIFOReg, 0xf0);
     pbus->write(CmdFIFOReg, 0xff + 0x0100);//BB id
     pbus->write(CmdFIFOReg, 0x76 + 0x0100);//charge FIC cmd
     pbus->write(CmdFIFOReg, (n & 0xff) + 0x0100);//data
     pbus->write(CmdFIFOReg, ((n>>8) & 0xff) + 0x0100);//data
     //            pbus->write(CmdFIFOReg, blo + 0x0100);//data
     //            pbus->write(CmdFIFOReg, bhi + 0x0100);//data
     pbus->write(CmdFIFOReg, 0x200);//end cmd
     usleep(1800);
     _attente_cmd_vide
     }
     
     //  //"Original" -tb-
     //  //do the job
     //  //usleep(100000);
     //  //we write bunches of 1000 bytes to the comand FIFO
     //  for(n=data_start; n<data_end; n++){
     //      b=( (unsigned short) charData[n] ) + 0x0100;
     //      pbus->write(CmdFIFOReg, b);
     //      _attente_cmd_vide
     //  }
     
     
     //job monitoring
     strcpy(errorMessage,"chargeFIC: loop running.");
     printf("SBC job loop: i=%i; job message: %s\n",i,errorMessage);
     strncpy(sbc_job.message,errorMessage,255);
     pthread_mutex_lock (&jobInfoMutex);     //begin critical section
     sbc_job.progress = ((double)i)/2.5;                    //percent done
     sbc_job.finalStatus = finalStatus;
     pthread_mutex_unlock (&jobInfoMutex);   //end critical section
     
     if(data_end==size) break;//end loop: this was the last block
     data_start=data_end;
     data_end+=1000; if(data_end>size) data_end=size;
     }
     
     //finish loading
     printf("Charging FIC finished ... \n");
     usleep(50000);    pbus->write(CmdFIFOReg ,  256);//  une data a zero
     usleep(50000);    pbus->write(CmdFIFOReg ,  256);//  une data a zero
     //usleep(50000);    write_word(driver_fpga,REG_CMD, (uint32_t) 256);    //  une data a zero
     //usleep(50000);    write_word(driver_fpga,REG_CMD, (uint32_t) 256);    //  une data a zero
     
     usleep(500000);    // laisser le temps pour lire le message d'erreur eventuel
     b=0x200;  pbus->write(CmdFIFOReg, b);  //fin de commande
     //-tb- old code: b=0x200;  write_word(driver_fpga,REG_CMD, b);  //fin de commande
     usleep(500000);    // laisser le temps pour lire le message d'erreur eventuel
     printf("on attend 2 pour terminer : ");
     */
    //job done -> success
    finalStatus=1;//flags success
    strcpy(errorMessage,"chargeFIC: loop finished.");
    
    
earlyExit://no success
    
    //house keeping
    
    pthread_mutex_lock (&jobInfoMutex);     //begin critical section
    sbc_job.progress    = 100;
    sbc_job.running     = 0;
    sbc_job.killJobNow  = 0;
    sbc_job.finalStatus = finalStatus;
    strncpy(sbc_job.message,errorMessage,255);
    sbc_job.message[255] = '\0';
    pthread_mutex_unlock (&jobInfoMutex);   //end critical section
    
    
    
}






void FindHardware(void)
{
    //open device driver(s), get device driver handles
    const char* name = "FE.ini";
    //TODO: check here blocking semaphores? -tb-
    
    
    
    //TODO: changed for EW ... -tb- ...
#if 0
    srack = new hw4::SubrackKatrin((char*)name,0);
    srack->checkSlot(); //check for available slots (init for isPresent(slot)); is necessary to prepare readout loop! -tb-
    pbus = srack->theSlt->version; //all registers inherit from Pbus, we choose "version" as it shall exist for all FPGA configurations
#else
    //similar to readword.cpp:
    int err = 0;
    try {
        if (pbus > 0) pbus->free();
        pbus = new Pbus();
        pbus->init();
        //TODO: when stopping (!) Orca (closing the socket) 'FindHardware()' is called AND pbus->init() seems to fail (with perror: File exists) -tb- 2013
        //     -> stopping Orca calls FindHardware()!
        //anyway OrcaReadout works correct! (... 'pbus' changes i.e. seems to be released correctly ... [was 'nil' before entering FindHardware()])
        //         printf("    test  after pbus->init(): pbus is %p \n",pbus);
    } catch (PbusError &e){
        err = 1;
    }
    if(err) printf("HW_Readout.cc (IPE EW DAQ V4): ERROR: Creating Pbus failed!\n");
    if(err) perror("   perror is");
#endif
    if(!pbus) fprintf(stdout,"HW_Readout.cc (IPE EW DAQ V4): ERROR: could not connect to Pbus!\n");
    
    //check for all present FLTs
    if(pbus){
        int flt;
        uint32_t val;
        presentFLTMap = 0;
        for(flt=0; flt<MAX_NUM_FLT_CARDS; flt++){
            //for(flt=0; flt<16; flt++){ //TODO:  <-------------------USE ABOVE LINE!!!!! Sascha NEEDS TO FIX IT -tb-  DONE 2013-06 -tb-
            val = pbus->read(FLTVersionReg(flt+1));
            //printf("FLT#%i (idx %i): version 0x%08x\n",flt+1,flt,val);
            if(val!=0x1f000000 && val!=0xffffffff){
                presentFLTMap |= 0x1 << flt;//bit[flt];
                //FLTSETTINGS::FLT[flt].isPresent = 1;
            }
        }
        printf("Checked presence of FLT cards: presentFLTMap is: 0x%08x\n",presentFLTMap);
    }
    
    //pbus test
    std::string getStr, cmdStr;
    cmdStr = "blockmode";
    pbus->get(cmdStr,&getStr);
    printf("   SLT PCI mode test: Pbus:: get %s: result: %s \n",cmdStr.c_str(),getStr.c_str());
    
    // test/force the C++ link to fdhwlib -tb-
    if(0){// unused, but compiled! -tb-
        printf("Try to create a BaseRegister object -tb-\n");
        fflush(stdout);
        hw4::BaseRegister *reg;
        reg = new hw4::BaseRegister("dummy",3,7,1,1);
        printf("  ->register name is %s, addr 0x%08lx\n", reg->getName(),reg->getAddr());
        fflush(stdout);
    }
}

void ReleaseHardware(void)
{
    //release / close device driver(s)
    pbus->free();
    pbus = 0;
    presentFLTMap=0;
}


void doWriteBlock(SBC_Packet* aPacket,uint8_t reply)
{
    SBC_IPEv4WriteBlockStruct* p = (SBC_IPEv4WriteBlockStruct*)aPacket->payload;
    if(needToSwap)SwapLongBlock(p,sizeof(SBC_IPEv4WriteBlockStruct)/sizeof(int32_t));
    
    uint32_t startAddress   = p->address;
    uint32_t numItems       = p->numItems;
    
    p++;                                /*point to the data*/
    int32_t* lptr = (int32_t*)p;        /*cast to the data type*/
    if(needToSwap) SwapLongBlock(lptr,numItems);
    
    
    
    //**** use device driver call to write data to HW
    int32_t perr = 0;
    //address check:
    int fltID = slotOfAddr(startAddress);
    if((fltID >=1) && (fltID <=20)){//its a FLT
        //printf("Mask 0x%08x:  0x%08x   !& is 0x%08x  \n",presentFLTMap,(0x1 << (fltID-1)), !(   presentFLTMap & (0x1 << (fltID-1)) )   );
        if(! (  presentFLTMap & (0x1 << (fltID-1))  ) ){
            printf("ERROR: refused reading address 0x%08x: is from flt # %i which is NOT present!\n",startAddress,fltID);
            perr = 1;
            goto SKIP_WRITE_ACCESS;
        }
    }
    //HW access:
    try{
        if (numItems == 1)  pbus->write(startAddress, *lptr);
        else                pbus->writeBlock(startAddress, (unsigned long *) lptr, numItems);
    }catch(PbusError &e){
        perr = 1;
    }
    
    
SKIP_WRITE_ACCESS: // sorry for the goto ... -tb-
    
    
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
    
    lptr = (int32_t*)returnDataPtr;
    if(needToSwap)SwapLongBlock(lptr,numItems);
    
    //send back to ORCA
    if(reply)writeBuffer(aPacket);
    
}

void doReadBlock(SBC_Packet* aPacket,uint8_t reply)
{
    SBC_IPEv4ReadBlockStruct* p = (SBC_IPEv4ReadBlockStruct*)aPacket->payload;
    if(needToSwap) SwapLongBlock(p,sizeof(SBC_IPEv4ReadBlockStruct)/sizeof(int32_t));
    
    uint32_t startAddress   = p->address;
    int32_t numItems        = p->numItems;
    //TODO: -tb- debug     printf("starting read: %08x numItems: %d\n",startAddress,numItems);
    
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
    try{
        if (numItems == 1){
            *lPtr = pbus->read(startAddress);
            //            printf("read from 0x%x, value is %i (0x%x)\n",startAddress, *lPtr,*lPtr);//TODO: debugging
        }
        else                pbus->readBlock(startAddress, (unsigned long *) lPtr, numItems);
    }catch(PbusError &e){
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

#else //of #if !PMC_COMPILE_IN_SIMULATION_MODE
// (here follow the 'simulation' versions of all functions -tb-)
//----------------------------------------------------------------

void processHWCommand(SBC_Packet* aPacket)  // 'simulation' version -tb-
{
    /*look at the first word to get the destination*/
    int32_t aCmdID = aPacket->cmdHeader.cmdID;
    
    switch(aCmdID){
            //        default:              processUnknownCommand(aPacket); break;
    }
}

void FindHardware(void)  // 'simulation' version -tb-
{
    printf("Called HW_Readout-FindHardware\n");
}

void ReleaseHardware(void)  // 'simulation' version -tb-
{
    printf("Called HW_Readout-ReleaseHardware\n");
}


void doWriteBlock(SBC_Packet* aPacket,uint8_t reply)  // 'simulation' version -tb-
{
    printf("Called HW_Readout-doWriteBlock\n");
    SBC_IPEv4WriteBlockStruct* p = (SBC_IPEv4WriteBlockStruct*)aPacket->payload;
    if(needToSwap)SwapLongBlock(p,sizeof(SBC_IPEv4WriteBlockStruct)/sizeof(int32_t));
    
    uint32_t startAddress   = p->address;
    uint32_t numItems       = p->numItems;
    
    p++;                                /*point to the data*/
    int32_t* lptr = (int32_t*)p;        /*cast to the data type*/
    if(needToSwap) SwapLongBlock(lptr,numItems);
    
    //**** use device driver call to write data to HW
    int32_t perr = 0;
    //hardware write access removed (was here) -tb-
    
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
    
    lptr = (int32_t*)returnDataPtr;
    if(needToSwap)SwapLongBlock(lptr,numItems);
    
    //send back to ORCA
    if(reply)writeBuffer(aPacket);
    
}

void doReadBlock(SBC_Packet* aPacket,uint8_t reply)  // 'simulation' version -tb-
{
    SBC_IPEv4ReadBlockStruct* p = (SBC_IPEv4ReadBlockStruct*)aPacket->payload;
    if(needToSwap) SwapLongBlock(p,sizeof(SBC_IPEv4ReadBlockStruct)/sizeof(int32_t));
    
    uint32_t startAddress   = p->address;
    int32_t numItems        = p->numItems;
    //DEBUGGING
    {
        static int counter=0;
        counter++;
        if(counter<150){ printf("Called HW_Readout-doReadBlock in Simulation mode, log some accesses: addr: 0x%x, (numitems %i)\n",startAddress,numItems);fflush(stdout);}
    }
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
    //hardware read access removed (was here) -tb-
    for(int i=0; i<numItems;i++) lPtr[i] = 0;
    {
        //this simulates a hitrate (startAddress &  0x001100>>2  are the hitrate registers) -tb
        if(startAddress & (0x001100>>2)){ //this is KATRINv4FLT specific! -tb-
            //printf("Probably Hitrate readout: addr 0x%x (numItems %i)\n",startAddress,numItems);
            //fflush(stdout);
            for(int i=0; i<numItems;i++) lPtr[i] = 100 * ((startAddress>>17)&0x1f)+ ((startAddress>>12)&0x1f) + i*1000;
            //*lPtr = 2;
        }
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


#endif //of #if !PMC_COMPILE_IN_SIMULATION_MODE ... #else ...
//----------------------------------------------------------------

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
        case kWriteToCmdFIFO:
        {
            unsigned char* buf=(unsigned char*)&dataToWrite[1];
            //if(numLongs == 1) *lPtr = kCodeVersion;
            //if(num!=2) ERROR ...
            //DEBUG               fprintf(stderr,"kWriteToCmdFIFO reply %i, num %i\n",reply,num);
            //DEBUG               fprintf(stderr,"   args 0x%x 0x%x ...\n",dataToWrite[0],dataToWrite[1]);
            //DEBUG
            //int i; for(i=0; i<  dataToWrite[0];i++){                   int val=*(buf+i) & 0xff;
            //    fprintf(stderr,"   byte %i: 0x%x  ...\n",i,val);            }
            //KATRIN example: setHostTimeToFLTsAndSLT(dataToWrite); , option kSetHostTimeToFLTsAndSLT
            sendCommandFifo(buf,dataToWrite[0]);
        }
            break;
        case kChargeBBWithFile:
        {
            //fork test BEGIN
            pid_t cpid;
            int flag=0;
            pbus->write(FLTAccessTestReg(1),flag);
            cpid = fork();
            if (cpid == -1) {
                perror("fork");
                printf("fork() failed\n");
                //exit(EXIT_FAILURE);
            }else{
                if (cpid == 0) {    /* Child reads from pipe */
                    flag=pbus->read(FLTAccessTestReg(1));
                    printf("fork(): this is the child process - busy ... (flag:%i)\n",flag);
                    sleep(3);
                    flag=pbus->read(FLTAccessTestReg(1));
                    printf("fork(): this is the child process - done ... (flag:%i)\n",flag);
                    _exit(EXIT_SUCCESS);
                    
                } else {            /* Parent writes argv[1] to pipe */
                    sleep(1);
                    flag=1;
                    pbus->write(FLTAccessTestReg(1),flag);
                    flag=pbus->read(FLTAccessTestReg(1));
                    printf("fork(): this is the parent process - continue ... (flag:%i)\n",flag);
                    //wait(NULL);             /* Wait for child */
                    //exit(EXIT_SUCCESS);
                }
            }
            //fork test END
            char* buf=(char*)&dataToWrite[1];
            //if(numLongs == 1) *lPtr = kCodeVersion;
            //if(num!=2) ERROR ...
            //DEBUG
            fprintf(stderr,"kChargeBBWithFile reply %i, num %i\n",reply,num);
            //DEBUG
            fprintf(stderr,"   args 0x%x 0x%x ...\n",dataToWrite[0],dataToWrite[1]);
            //DEBUG
            if(dataToWrite[0]>1)fprintf(stderr,"   filename: %s  \n",buf);
            //DEBUG
            //int i; for(i=0; i<  dataToWrite[0];i++){                   int val=*(buf+i) & 0xff;
            //    fprintf(stderr,"   byte %i: 0x%x  ...\n",i,val);            }
            //KATRIN example: setHostTimeToFLTsAndSLT(dataToWrite); , option kSetHostTimeToFLTsAndSLT
            snprintf(aPacket->message, kSBC_MaxMessageSizeBytes, "PMC-doGeneralWriteOp-called with kChargeBBWithFile");
            chargeBBWithFile(buf,-1);
            dataToWrite[1]=0x74696c6c;//=till in ascii
            //sendCommandFifo(buf,dataToWrite[0]);
        }
            break;
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
#if defined FDHWLIB_VER
            if(numLongs == 1) *lPtr = FDHWLIB_VER; //in fdhwlib.h -tb-
#else
            if(numLongs == 1) *lPtr = 0xffffffff; //we are probably in simulation mode and not linking with fdhwlib -tb-
#endif
            break;
        case kGetSltPciDriverVersion:
            if(numLongs == 1) *lPtr = getSltLinuxKernelDriverVersion();
            break;
        case kGetPresentFLTsMap:
            if(numLongs == 1) *lPtr = presentFLTMap;
            break;
        default:
            for(i=0;i<numLongs;i++)*lPtr++ = 0; //undefined operation so just return zeros
            break;
    }
    if(needToSwap)SwapLongBlock(startPtr,numLongs/sizeof(int32_t));
    
    if(reply)writeBuffer(aPacket);
}



/*--------------------------------------------------------------------------------------
 *int getSltLinuxKernelDriverVersion(): search string in /proc/devices, works only for Linux!!
 *--------------------------------------------------------------------------------------
 */
//#include <stdlib.h>  //atioi, strtol
//#include <stdio.h>
//#include <string.h>  //strtstr

//currently we have only Linux, but we want to run simulation mode on all OSs -tb-
#ifdef __linux__
#define DRIVERNAME "fzk_ipe_slt"
#define KIT_DRIVERNAME "kit_ipe_slt"
int getSltLinuxKernelDriverVersion(void)
{
    char buf[1024 * 4];
    char *cptr;
    FILE *p;
    int version = -2;
    p = popen("cat /proc/devices | grep ipe_slt","r");
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
        if( (cptr=strstr(buf, KIT_DRIVERNAME)) ){  // dont use strncmp, it finds fzk_ipe_slt1, too, which does not exist -tb-
            version = 4;
            break;
        }
        if(feof(p)) break; //??? is this necessary??? -tb-
    };
    
    pclose(p);
    //printf("version is: %i\n",version);
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

