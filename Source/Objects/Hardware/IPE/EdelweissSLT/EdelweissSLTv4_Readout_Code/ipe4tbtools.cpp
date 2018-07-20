/***************************************************************************
    ipe4tbtools.cpp  -  description: tools for the IPE4 Edelweiss readout ipe4reader
                        AND Orca
	history: see below

    begin                : July 07 2012
    copyright            : (C) 2011 by Till Bergmann, KIT
    email                : Till.Bergmann@kit.edu
 ***************************************************************************/







// DO NOT COMPILE THIS FILE!!!


// INCLUDE IT FROM OTHER *.cpp/*.cc files, 
// include ipe4tbtools.h in the according *. files
// -tb- 2013-01






//
//     =====> moved to ipe4reader.cpp -tb-
//
//This is the version of the IPE4 readout code (display is: version/1000, so cew_controle will display 1934003 as 1934.003) -tb-
// VERSION_IPE4_HW is 1934 which means IPE4  (1=I, 9=P, 3=E, 4=4)
// VERSION_IPE4_SW is the version of the readout software (this file)
//#define VERSION_IPE4_HW      1934200
//#define VERSION_IPE4_SW           10
//#define VERSION_IPE4READOUT (VERSION_IPE4_HW + VERSION_IPE4_SW)

/* History:
version 2: 2013 June
           multi FIFO on SLT; FLT-Trigger
version 1: 2013 January
           changed name from ipe4reader6 to ipe4reader;
           added ipe4reader to Orca svn repository
               in shell use:
               (cd ORCA;make -f Makefile.ipe4reader; cd ..)
               (cd ORCA; ./ipe4reader ; cd ..)
           veto flag setting for ipe4reader config file
           FiberOutMask (FLT register) -> Orca GUI
           prohibit write access to not existing FLTs (Orca and ipe4reader)
           sending crate and BB status packet with ipe4reader and receiving it with Orca
           
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <time.h>
#include <errno.h>
#include <libgen.h> //for basename
#include <stdint.h>  //for uint32_t etc.

#include <signal.h> //for kill/SIGTERM

/*--------------------------------------------------------------------
 *    functions
 *       
 *--------------------------------------------------------------------*/ //-tb-


// return slot associated to a address (1..20=FLT #1..#20, slot>=21 means SLT address); address = PCI-address
int slotOfPCIAddr(uint32_t address)
{
    return (address >> 19) & 0x1f;
}

// return slot associated to a address (1..20=FLT #1..#20, slot>=21 means SLT address); address = PCI-address>>2
int slotOfAddr(uint32_t address)
{
    return (address >> 17) & 0x1f;
}

int numOfBits(uint32_t val)
{
    int i,num=0;
    for(i=0; i<32;i++){
        if(val & (0x1<<i)) num++;
    }
    //printf("numOfBits: val 0x%08x has %i bits\n",val,num);
    return num;
}

int count_ipe4reader_instances(void)
{
	char buf[1024 * 4];
	FILE *p;
	int counter = 0;
	p = popen("ps -e |grep ipe4reader | wc -l","r");
	if(p==0){ fprintf(stderr, "could not start popen... -tb-\n"); return counter; }
	
	while (!feof(p)){
	    fscanf(p,"%s",buf);
        counter = atoi(buf);
	    //printf("count_ipe4reader_instances is: %i\n",counter);
		if(feof(p)) break; //??? is this necessary??? -tb-
	};

	pclose(p);
	//printf("count_ipe4reader_instances is: %i\n",counter);
	return counter;
}

//kill all ipe4reader* instances except myself
//
//shell commands to get the list of IP addresses, each in a single line
//ps -e | awk '/bergmann/{ print $1 }'
//  -> removes leading whitespace
//ps -e | grep bergmann | cut  -c 1-6
int kill_ipe4reader_instances(void)
{
	    printf("running 'int kill_ipe4reader_instances(void)'\n");
    int pid = getpid();
	    printf("    kill_ipe4reader_instances()': my own PID is %i\n",pid);
	char buf[1024 * 4];
	//char *cptr;
	FILE *p;
	int val = 0;
	p = popen("ps -e | awk '/ipe4reader/{ print $1 }'","r");
	if(p==0){ fprintf(stderr, "could not start popen... -tb-\n"); return -1; }
	sleep(1);
	while (!feof(p)){
	    fscanf(p,"%s",buf);
		//if(feof(p)) printf("... if(feof(p))  ...\n"); //I think on Mac this was to early and we would have lost one line of return values -tb-
        val = atoi(buf);
	    printf("Found PID >%s<; kill_ipe4reader_instances: PID is: %i\n",buf,val);
        if(pid != val){
	        printf("kill -s SIGTERM %i\n",val);
            kill(val,SIGTERM);
        }
		if(feof(p)){
            printf("... if(feof(p))  ...  break\n");
            break; //??? is this necessary??? -tb-
        }
	};

	pclose(p);
	//printf("kill_ipe4reader_instances is: %i\n",counter);
	return val;
}


   /* 
     fifoReadsFLTIndex: FIFO-to-FLT mapping
     --------------------------------------------------------------------*/
//FIFO-to-FLT mapping 
int fifoReadsFLTIndexChecker(int fltIndex, int numfifo, int availableNumFIFO, int maxNumFIFO)
{
    if(availableNumFIFO==0) return 1;//this was the 'old' firmware: all FLTs to one FIFO (however, 'availableNumFIFO' should be 1)
    
    if(availableNumFIFO==1){
        if(numfifo==0 && fltIndex>=0 && fltIndex<maxNumFIFO)
            return 1;
        else
            return 0;
    }
    
    if(availableNumFIFO==8){//mapping: fifo0=FLT0,1; fifo1=FLT2,3; fifo2=FLT4,5; fifo3=FLT6,7; ...
        if(fltIndex>=0 && fltIndex<maxNumFIFO){
            return (fltIndex >>1) == numfifo;
        }else
            return 0;
    }
    
    #if 0
    //removed:
    //mapping was previously: fifo0=FLT0,1,2,3; fifo1=FLT4,5,6,7; fifo2=FLT8,9,10,11; fifo3=FLT12,13,14,15  ---> then mapping is: return (fltIndex >> 2) == numfifo;
    if(availableNumFIFO==4){//mapping: fifo0=FLT0,1,2,3; fifo1=FLT4,5,6,7; fifo2=FLT8,9,10,11; fifo3=FLT12,13,14,15
        if(fltIndex>=0 && fltIndex<maxNumFIFO){
            return (fltIndex >> 2) == numfifo;
        }else
            return 0;
    }
    #endif

    //2013-07-11: this is currently the only existing version -tb-
    if(availableNumFIFO==4){//mapping: fifo0=FLT0,1,2,3,4; fifo1=FLT5,6,7,8,9; fifo2=FLT10,11,12,13,14; fifo3=FLT15,16,17,18,19
        if(fltIndex>=0 && fltIndex<maxNumFIFO){
            return (fltIndex / 5) == numfifo;
        }else
            return 0;
    }
    
    //2014-01-27: new 4+4+4+4+3+1 configuration -tb-
    if(availableNumFIFO==6){//mapping: fifo0=FLT0,1,2,3; fifo1=FLT4,5,6,7; fifo2=FLT8,9,10,11; fifo3=FLT12,13,14,15; fifo4=FLT16,17,18; fifo5=19
        if(fltIndex>=0 && fltIndex<maxNumFIFO){
			if(fltIndex>=0 && fltIndex<=15) return (fltIndex / 4) == numfifo;
			if(numfifo==4 && fltIndex>=16 && fltIndex<=18) return 1;
			if(numfifo==5 && fltIndex==19) return 1;
            return 0;
        }else
            return 0;
    }
    
    if(availableNumFIFO==2){//mapping: fifo0=FLT0,1,2,3,4,5,6,7; fifo1=FLT8,9,10,11,12,13,14,15
        if(fltIndex>=0 && fltIndex<maxNumFIFO){
            return (fltIndex >> 3) == numfifo;
        }else
            return 0;
    }
    
    return 0;
}

/*--------------------------------------------------------------------
  includes
  --------------------------------------------------------------------*/


/*--------------------------------------------------------------------
  globals and functions for hardware access
  --------------------------------------------------------------------*/
#include <Pbus/Pbus.h>
#include <akutil/semaphore.h>

//TODO: #pragma warning TODO remove -lkatrinhw4 in Makefile
//#include "hw4/baseregister.h"
//#include "Pbus/pbusimp.h"
//#include "katrinhw4/subrackkatrin.h"
//#include "katrinhw4/sltkatrin.h"
//#include "katrinhw4/fltkatrin.h"









#if 0
//defined in ipe4tbtools.h

//TODO: use this for ipe4reader AND Orca -tb-


    //SLT registers
	static const uint32_t SLTControlReg			= 0xa80000 >> 2;
	static const uint32_t SLTStatusReg			= 0xa80004 >> 2;
	static const uint32_t SLTCommandReg			= 0xa80008 >> 2;
	static const uint32_t SLTInterruptMaskReg	= 0xa8000c >> 2;
	static const uint32_t SLTInterruptRequestReg= 0xa80010 >> 2;
	static const uint32_t SLTVersionReg			= 0xa80020 >> 2;

	static const uint32_t SLTPixbusPErrorReg     = 0xa80024 >> 2;
	static const uint32_t SLTPixbusEnableReg     = 0xa80028 >> 2;
	static const uint32_t SLTBBOpenedReg         = 0xa80034 >> 2;

	
	static const uint32_t SLTSemaphoreReg    = 0xb00000 >> 2;
	
	static const uint32_t CmdFIFOReg         = 0xb00004 >> 2;
	static const uint32_t CmdFIFOStatusReg   = 0xb00008 >> 2;
	static const uint32_t OperaStatusReg0    = 0xb0000c >> 2;
	static const uint32_t OperaStatusReg1    = 0xb00010 >> 2;
	static const uint32_t OperaStatusReg2    = 0xb00014 >> 2;
	
	static const uint32_t FIFO0Addr         = 0xd00000 >> 2;
	
	//TODO: multiple FIFOs are obsolete, remove it -tb-
	static const uint32_t FIFO0ModeReg      = 0xe00000 >> 2;//obsolete 2012-10 
	static const uint32_t FIFO0StatusReg    = 0xe00004 >> 2;//obsolete 2012-10
	static const uint32_t BB0PAEOffsetReg   = 0xe00008 >> 2;//obsolete 2012-10
	static const uint32_t BB0PAFOffsetReg   = 0xe0000c >> 2;//obsolete 2012-10
	static const uint32_t BB0csrReg         = 0xe00010 >> 2;//obsolete 2012-10
	
	#if 0
	static const uint32_t FIFOModeReg       = 0xe00000 >> 2;
	static const uint32_t FIFOStatusReg     = 0xe00004 >> 2;
	static const uint32_t PAEOffsetReg      = 0xe00008 >> 2;
	static const uint32_t PAFOffsetReg      = 0xe0000c >> 2;
	static const uint32_t FIFOcsrReg        = 0xe00010 >> 2;
    #endif

	static const uint32_t SLTTimeLowReg     = 0xb00018 >> 2;
	static const uint32_t SLTTimeHighReg    = 0xb0001c >> 2;




    //FLT registers
	static const uint32_t FLTStatusRegBase      = 0x000000 >> 2;
	static const uint32_t FLTControlRegBase     = 0x000004 >> 2;
	static const uint32_t FLTCommandRegBase     = 0x000008 >> 2;
	static const uint32_t FLTVersionRegBase     = 0x00000c >> 2;
	
	static const uint32_t FLTFiberOutMaskRegBase  = 0x000018 >> 2;
    
	static const uint32_t FLTFiberSet_1RegBase  = 0x000024 >> 2;
	static const uint32_t FLTFiberSet_2RegBase  = 0x000028 >> 2;
	static const uint32_t FLTStreamMask_1RegBase  = 0x00002c >> 2;
	static const uint32_t FLTStreamMask_2RegBase  = 0x000030 >> 2;
	static const uint32_t FLTTriggerMask_1RegBase  = 0x000034 >> 2;
	static const uint32_t FLTTriggerMask_2RegBase  = 0x000038 >> 2;

	static const uint32_t FLTAccessTestRegBase     = 0x000040 >> 2;
	
	static const uint32_t FLTTotalTriggerNRegBase  = 0x000084 >> 2;

	static const uint32_t FLTBBStatusRegBase    = 0x00001400 >> 2;

	static const uint32_t FLTRAMDataRegBase     = 0x00003000 >> 2;









#endif



//SLT registers

	
uint32_t FIFOStatusReg(int numFIFO){
    return FIFO0StatusReg | ((numFIFO & 0xf) <<14);  //PCI adress would be <<16, but we use Pbus adress -tb-
}

uint32_t FIFOModeReg(int numFIFO){
    return FIFO0ModeReg | ((numFIFO & 0xf) <<14);  //PCI adress would be <<16, but we use Pbus adress -tb-
}

uint32_t FIFOAddr(int numFIFO){
    return FIFO0Addr | ((numFIFO & 0xf) <<14);  //PCI adress would be <<16, but we use Pbus adress -tb-
}

uint32_t PAEOffsetReg(int numFIFO){
    return BB0PAEOffsetReg | ((numFIFO & 0xf) <<14);  //PCI adress would be <<16, but we use Pbus adress -tb-
}

uint32_t PAFOffsetReg(int numFIFO){
    return BB0PAFOffsetReg | ((numFIFO & 0xf) <<14);  //PCI adress would be <<16, but we use Pbus adress -tb-
}

uint32_t BBcsrReg(int numFIFO){
    return BB0csrReg | ((numFIFO & 0xf) <<14);  //PCI adress would be <<16, but we use Pbus adress -tb-
}







//FLT registers


	
// 
// NOTE: numFLT from 1...20  !!!!!!!!!!!!
//
// (NOT from 0 ... 19!!!)
//
	//TODO: 0x3f or 0x1f?????????????
uint32_t FLTStatusReg(int numFLT){
    return FLTStatusRegBase | ((numFLT & 0x3f) <<17);  //PCI adress would be <<16, but we use Pbus adress -tb-
}

uint32_t FLTControlReg(int numFLT){
    return FLTControlRegBase | ((numFLT & 0x3f) <<17);  
}

uint32_t FLTCommandReg(int numFLT){
    return FLTCommandRegBase | ((numFLT & 0x3f) <<17);  
}

uint32_t FLTVersionReg(int numFLT){
    return FLTVersionRegBase | ((numFLT & 0x3f) <<17);  
}

uint32_t FLTFiberOutMaskReg(int numFLT){
    return FLTFiberOutMaskRegBase | ((numFLT & 0x3f) <<17);  
}

uint32_t FLTFiberSet_1Reg(int numFLT){
    return FLTFiberSet_1RegBase | ((numFLT & 0x3f) <<17);  
}

uint32_t FLTFiberSet_2Reg(int numFLT){
    return FLTFiberSet_2RegBase | ((numFLT & 0x3f) <<17);  
}

uint32_t FLTStreamMask_1Reg(int numFLT){
    return FLTStreamMask_1RegBase | ((numFLT & 0x3f) <<17);  
}

uint32_t FLTStreamMask_2Reg(int numFLT){
    return FLTStreamMask_2RegBase | ((numFLT & 0x3f) <<17);  
}

uint32_t FLTTriggerMask_1Reg(int numFLT){
    return FLTTriggerMask_1RegBase | ((numFLT & 0x3f) <<17);  
}

uint32_t FLTTriggerMask_2Reg(int numFLT){
    return FLTTriggerMask_2RegBase | ((numFLT & 0x3f) <<17);  
}

uint32_t FLTPostTriggI2HDelayReg(int numFLT){
    return FLTPostTriggI2HDelayRegBase | ((numFLT & 0x3f) <<17);  
}

uint32_t FLTAccessTestReg(int numFLT){
    return FLTAccessTestRegBase | ((numFLT & 0x3f) <<17); 
}

uint32_t FLTBBStatusReg(int numFLT, int numChan){
    return FLTBBStatusRegBase | ((numFLT & 0x3f) <<17) | ((numChan & 0x1f) <<12); 
}

uint32_t FLTTotalTriggerNReg(int numFLT){
    return FLTTotalTriggerNRegBase | ((numFLT & 0x3f) <<17);  
}


uint32_t FLTRAMDataReg(int numFLT, int numChan){
    return FLTRAMDataRegBase | ((numFLT & 0x3f) <<17) | ((numChan & 0x1f) <<12); 
}

uint32_t FLTHeatTriggParReg(int numFLT, int numChan){
    return FLTHeatTriggParRegBase | ((numFLT & 0x3f) <<17) | ((numChan & 0x1f) <<12); 
}

uint32_t FLTIonTriggParReg(int numFLT, int numChan){
    return FLTIonTriggParRegBase | ((numFLT & 0x3f) <<17) | ((numChan & 0x1f) <<12); 
}

uint32_t FLTTriggParReg(int numFLT, int numChan){
    if(numChan>=0 && numChan<6)
        return FLTHeatTriggParRegBase | ((numFLT & 0x3f) <<17) | ((numChan & 0x1f) <<12); 
    if(numChan>=6 && numChan<18)
        return FLTIonTriggParRegBase | ((numFLT & 0x3f) <<17) | (((numChan-6) & 0x1f) <<12); 
    //fallback
    return FLTIonTriggParRegBase | ((numFLT & 0x3f) <<17);
}

uint32_t FLTReadPageNumReg(int numFLT){
    return FLTReadPageNumRegBase | ((numFLT & 0x3f) <<17);  
}

uint32_t FLTRegAddr(uint32_t regAddrBase, int numFLT){
    return regAddrBase | ((numFLT & 0x3f) <<17);  
}

//TODO: write standard function, which takes addr and FLT num ...



/*--------------------------------------------------------------------
  globals and functions for hardware access
  --------------------------------------------------------------------*/
 
 
 /*--------------------------------------------------------------------
 *    function prototypes (moved from ipe4reader to provide access for OrcaReadout)
 *--------------------------------------------------------------------*/ //-tb-

 
/*--------------------------------------------------------------------
 *    function:     requestHWSemaphore, requestHWSemaphoreWaitUsec, releaseHWSemaphore
 *    purpose:      request/release HW semaphore on SLT to avoid conflicts 
 *                  on writing to command FIFO from 2 or more concurrent processes
 *    author:       Till Bergmann, 2011
 *
 *--------------------------------------------------------------------*/ //-tb-
int requestHWSemaphore(void)
{
    uint32_t sltSemaphore;
    sltSemaphore = pbus->read(SLTSemaphoreReg);
    return sltSemaphore;
 }

//request semaphore, if no succes, wait 1 usec and try again; retry max. usec times
uint32_t requestHWSemaphoreWaitUsec(int usec)
{
    uint32_t sltSemaphore=0;
	int i;
	for(i=0; i<usec; i++){
        sltSemaphore = pbus->read(SLTSemaphoreReg);// or ... = requestHWSemaphore()
		if(sltSemaphore) return sltSemaphore;
		usleep(1);
	}
    
    return sltSemaphore;
}


void releaseHWSemaphore(void)
{
	pbus->write(SLTSemaphoreReg ,  0x00000001);
}

void releaseHWSemaphoreWith(uint32_t bitmap)
{
	pbus->write(SLTSemaphoreReg ,  bitmap);
}

/*--------------------------------------------------------------------
 *    function:     sendCommandFifo
 *    purpose:      write command to command FIFO
 *    author:       taken from envoie_commande from cew.c, modified by Till Bergmann, 2011
 *
 *--------------------------------------------------------------------*/ //-tb-
//write_word to FPGA: Inbuf: will be sent to FPGA, status=number of bytes to be sent -tb-
//this is the counterpart of void	envoie_commande(unsigned char * Inbuf,int status) in cew.c
//
// NOTE: the first byte should be 'W' or 'h' (or anything else - it will be dropped/ignored!) 
//
void sendCommandFifo(unsigned char * buffer, int len)
{

    uint32_t cmdFifoStatus;
    unsigned char Code_Commande;
    uint32_t b;
    int i;
	
	//wait until command FIFO is empty
	const int MAXWAIT=25;
	for(i=0; i< MAXWAIT; i++){
	    cmdFifoStatus = pbus->read(CmdFIFOStatusReg);
		if (cmdFifoStatus & 0x8000) {
			break; //cmd FIFO empty, leave loop
		}
		usleep(10);
	}
	if(i==MAXWAIT){
	    printf("WARNING: cmd FIFO still not empty, continue to send command anyway! This may be caused by a error!\n");
	}
	
    //this errourously was sent out for each FIFO command, removed 2011-12-23
	//pbus->write(CmdFIFOReg ,  0x00f0);
	
	//try to request the HW semaphore
    uint32_t sltSemaphore=0;
    sltSemaphore = requestHWSemaphoreWaitUsec(100);// argument is 'usec': "wait max usec time" (e.g. usec = 100 means wait max. 100 usec = 0.1 msec)
	if(!sltSemaphore){
	    printf("ERROR: HW semaphore request timeout in void sendCommandFifo()! Could not send command! ERROR!\n");//TODO: use debug level setting -tb-
		return;
	}
	
	//now write command to cmd FIFO
    Code_Commande = buffer[1];
 	//  d'abord un mot de 8 bit precede de 0 en bit 9 pour indiquer le 1er mot
	//write_word(driver_fpga,REG_CMD, (uint32_t) Code_Commande);
	pbus->write(CmdFIFOReg ,  Code_Commande);  //this is either 255/0xff or 240/0xf0 (commande 'W')

	printf("cmd %u (%d octets) ",Code_Commande,len-2);//TODO: use debug level setting -tb-
	//  les mots suivants par mots de 8 bit
	for(i=2;i<len;i++){
		b=buffer[i];
        // En fait, c'est le msb d'abors
		printf("%X ",b);
		b=b+0x0100;
		//write_word(driver_fpga,REG_CMD, b);
		pbus->write(CmdFIFOReg ,  b);
	}
	b=0x200;
	pbus->write(CmdFIFOReg ,  b);
	printf("\n");

    //release semaphore
	//if(sltSemaphore){	    releaseHWSemaphore();	}
	releaseHWSemaphoreWith(sltSemaphore);
}

/*--------------------------------------------------------------------
 *    function:     sendCommandFifoBlockFibers
 *    purpose:      write command to command FIFO
 *    author:       taken from envoie_commande from cew.c, modified by Till Bergmann, 2011
 *
 *--------------------------------------------------------------------*/ //-tb-
//write_word to FPGA: Inbuf: will be sent to FPGA, status=number of bytes to be sent -tb-
//this is the counterpart of void	envoie_commande(unsigned char * Inbuf,int status) in cew.c
//
// NOTE: the first byte should be 'W' or 'h' (or anything else - it will be dropped/ignored!) 
//
void sendCommandFifoUnblockFiber(unsigned char * buffer, int len, int flt, int fiber)
{

    uint32_t cmdFifoStatus;
    unsigned char Code_Commande;
    uint32_t b;
    int i;
	
	//wait until command FIFO is empty
	const int MAXWAIT=25;
	for(i=0; i< MAXWAIT; i++){
	    cmdFifoStatus = pbus->read(CmdFIFOStatusReg);
		if (cmdFifoStatus & 0x8000) {
			break; //cmd FIFO empty, leave loop
		}
		usleep(10);
	}
	if(i==MAXWAIT){
	    printf("WARNING: cmd FIFO still not empty, continue to send command anyway! This may be caused by a error!\n");
	}
	
    //this errourously was sent out for each FIFO command, removed 2011-12-23
	//pbus->write(CmdFIFOReg ,  0x00f0);
	
	//try to request the HW semaphore
    uint32_t sltSemaphore=0;
    sltSemaphore = requestHWSemaphoreWaitUsec(100);// argument is 'usec': "wait max usec time" (e.g. usec = 100 means wait max. 100 usec = 0.1 msec)
	if(!sltSemaphore){
	    printf("ERROR: HW semaphore request timeout in void sendCommandFifo()! Could not send command! ERROR!\n");//TODO: use debug level setting -tb-
		return;
	}
	
    //unblock the fiber
    uint32_t mask= ~(0x1 << fiber) & 0x3f;
    printf("sendCommandFifoUnblockFiber:0x%08x\n",mask);//TODO: use debug level setting -tb-
    pbus->write(FLTFiberOutMaskReg(flt) ,  mask);

    
	//now write command to cmd FIFO
    Code_Commande = buffer[1];
 	//  d'abord un mot de 8 bit precede de 0 en bit 9 pour indiquer le 1er mot
	//write_word(driver_fpga,REG_CMD, (uint32_t) Code_Commande);
	pbus->write(CmdFIFOReg ,  Code_Commande);  //this is either 255/0xff or 240/0xf0 (commande 'W')

	printf("cmd %u (%d octets) ",Code_Commande,len-2);//TODO: use debug level setting -tb-
	//  les mots suivants par mots de 8 bit
	for(i=2;i<len;i++){
		b=buffer[i];
        // En fait, c'est le msb d'abors
		printf("%X ",b);
		b=b+0x0100;
		//write_word(driver_fpga,REG_CMD, b);
		pbus->write(CmdFIFOReg ,  b);
	}
	b=0x200;
	pbus->write(CmdFIFOReg ,  b);
	printf("\n");

    //block the fiber
    pbus->write(FLTFiberOutMaskReg(flt) ,  0x3f);


    //release semaphore
	//if(sltSemaphore){	    releaseHWSemaphore();	}
	releaseHWSemaphoreWith(sltSemaphore);
}


/*--------------------------------------------------------------------
 *    function:     envoie_commande_standard_BBv2
 *    purpose:      restart bolo box (BB)
 *    author:       from cew.c, modified by Till Bergmann, 2011
 *
 *--------------------------------------------------------------------*/ //-tb-
void envoie_commande_standard_BBv2(void)
{
	//int Table_nb_synchro[8]=_valeur_synchro;
	unsigned char buf[10];
	buf[0]='h';
	buf[1]=255;
	buf[2]=30;		//  valeur de X
	buf[3]=0;		//  poid fort de X 
	buf[4]=0;		// retard
	buf[5]=1;		// masque BB
	buf[6]=code_acqui_EDW_BB2;		// code acqui
	buf[7]=code_synchro_100000;
	//envoie_commande(buf,8);
	sendCommandFifo(buf,8);
}


/*--------------------------------------------------------------------
 *    function:     envoie_commande_horloge
 *    purpose:      send command to OPERA (horloge=send over clock line)
 *    author:       from cew.c, modified by Till Bergmann, 2011
 *
 *--------------------------------------------------------------------*/ //-tb-

//FROM ipe4structure.h -tb-
 //  les bit 0 et 1 du code synchro   -->  4 valeur possibles
#define		_valeur_synchro	{20160,25000,100000,100000}
//  le bit 2 et 3 du Code_synchro dit que l'horloge doit etre esclave (synchro et/ou temps)

void envoie_commande_horloge(int X, int Retard, int Masque_BB, int Code_acqui, int Code_synchro, int Nb_mots_lecture)
{
	int Table_nb_synchro[8]=_valeur_synchro;
	unsigned char buf[10];

/*
	if(x_fixe>0)	x=x_fixe;
	if(retard_fixe>0)	retard=retard_fixe;
	if(masque_BB_fixe>0)	masque_BB=masque_BB_fixe;
	if(code_acqui_fixe>0)	Code_acqui=code_acqui_fixe;
	if(code_synchro_fixe>0)	Code_synchro=code_synchro_fixe;
*/
	buf[0]='h';
	buf[1]=255;
	buf[2]=X&0xff;		//  sur 16 bit 
	buf[3]=X>>8;		//  sur 16 bit 
	buf[4]=Retard;
	buf[5]=Masque_BB;
	buf[6]=Code_acqui;
	buf[7]=Code_synchro;
	
    int
	Nb_synchro=Table_nb_synchro[Code_synchro&0x3];
	printf("\nHorloge: x=%d retard=%d Code_acqui=%d masque_BB=%d  Nb_mots=%d Code_synchro=%d, Nb_synchro=%d\n",X,Retard,Code_acqui,Masque_BB,Nb_mots_lecture,Code_synchro,Nb_synchro);
	sendCommandFifo(buf,8);   //envoie_commande(buf,8);
}




/*--------------------------------------------------------------------
 *    function:     chargeBBWithFILEPtr
 *    purpose:      reload BB FPGA configuration from FILE* pointer (called from chargeBBWithFile)
 *                    arguments:
 *                      int * numserie - kind of return value
 *                      int numFifo - FIFO socket used to send status packet
 *
 *    author:       from cew.c, modified by Till Bergmann, 2011
 *
 *--------------------------------------------------------------------*/ //-tb-
//from constant_fpga.h and cew.c -> remove all -tb-
//#define REG_CMD (0x14) 
//int		driver_fpga=0;


int32_t  fsize(FILE* fd)
{
   int32_t size;
   fseek(fd, 0, SEEK_END);       /* aller en fin */
   size = ftell(fd);             /* lire la taille */
   return size;
}


//  programme bbv2 retourne 0 si tout est bon
// sinon retourne un code d'erreur


/*
#define _attente_cmd_vide	{int timeout=100; do read_word(driver_fpga,REG_CMD_STATUS,&b);	while ( (!(b&0x8000)) && (timeout--) ) ;\
							if(timeout<1) printf("erreur timeout attente commande vide \n");}
*/

#define _attente_cmd_vide	{int timeout=100; do b=pbus->read(CmdFIFOStatusReg);	while ( (!(b&0x8000)) && (timeout--) ) ;\
							if(timeout<1) printf("erreur timeout attente commande vide _attente_cmd_vide\n");}


/*
INFO Till 2013:
_send_status_programmation(n)  sends status packet with prog_status=n
n is: numserie + (p<<8) where
    numserie: seems to be a FIFO status/general status with: 1=started loading; 2=during loading; 3=during/after loading
    p: percentage of file upload 0..100 (or 0..101??)

_send_status_programmation(n) is called 10 times during loading, and several times (3-5?) at beginning and after end

It seems to be safe to use "numserie==3" all the time?
*/


//  chargeBBWithFILEPtr retourne 0 si tout est bon
// sinon retourne un code d'erreur
int chargeBBWithFILEPtr(FILE * fichier,int * numserie, int numFifo)
{
	int i,a,n;
	uint32_t  b;
	unsigned char filebuf[1100];
	uint32_t  size;
	//TODO: needed?   _send_status_programmation(2)
	//#define _send_status_programmation(n)	{kill(pid,SIGUSR1); Trame_status_udp.status_opera.micro_bbv2=n;	_SEND_UDP_clients_status(&Trame_status_udp,sizeof(Structure_trame_status))}
    if(sendChargeBBStatusFunctionPtr) sendChargeBBStatusFunctionPtr(2, numFifo);
	
	usleep(500000);			// je rajoute 500 msec au debut
	//TODO: needed? vide_data_FIFO();		// pour vider la fifo
	usleep(100000);
//	write_word(driver_fpga,REG_CMD, (uint32_t) 235);	//  c'est le code commande pour passer en mode_micro
    pbus->write(CmdFIFOReg ,  235);

	printf("\npassage de la BBv2 en mode microprocesseur\n");
    #if 1
	usleep(50000);	pbus->write(CmdFIFOReg ,  256);//  une data a zero
	usleep(50000);	pbus->write(CmdFIFOReg ,  256);//  une data a zero
	usleep(50000);	pbus->write(CmdFIFOReg ,  256);//  une data a zero
	usleep(50000);	pbus->write(CmdFIFOReg ,  256);//  une data a zero
	usleep(100000);	// laisser le temps (0.1sec) pour que le biphase se rende compte que l'horloge est arretee
    #else
	usleep(50000);	write_word(driver_fpga,REG_CMD, (uint32_t) 256);	//  une data a zero
	usleep(50000);	write_word(driver_fpga,REG_CMD, (uint32_t) 256);	//  une data a zero
	usleep(50000);	write_word(driver_fpga,REG_CMD, (uint32_t) 256);	//  une data a zero
	usleep(50000);	write_word(driver_fpga,REG_CMD, (uint32_t) 256);	//  une data a zero
	//TODO: needed? vide_data_FIFO();		// pour vider la fifo
	usleep(100000);	// laisser le temps (0.1sec) pour que le biphase se rende compte que l'horloge est arretee
	//TODO: needed? vide_data_FIFO();		// pour vider la fifo
    #endif
    
	b=0x0120;
	
	for(i=0;i<10;i++)	pbus->write(CmdFIFOReg ,  b++);  // ici avec _attente_cmd_vide ca ne marche pas
	//-tb- old code: for(i=0;i<10;i++)	write_word(driver_fpga,REG_CMD,b++);		// ici avec _attente_cmd_vide ca ne marche pas
    
    *numserie=3;
    #if 0
    /*
	for(i=0;i<10;i++)		// je fais une boucle en attendant le numero de serie
	{
		*numserie=lecture_data_FIFO_microbbv2();
		if(*numserie>2) break;
	}
	printf(" ---> (i=%d) nmserie = %d  \n",i,*numserie);
	if(*numserie<3)	return -1;
    */
	#endif
    
	//TODO: needed?   _send_status_programmation(*numserie)
	
	size = fsize(fichier);
	fseek(fichier, 0, SEEK_SET);       /* aller au debut */
	printf("fichier de programmation : %d octets \n",(int)size);
	b=(size & 0xff) + 0x0100;         pbus->write(CmdFIFOReg, b);//_attente_cmd_vide
	b=( (size>>8) & 0xff ) + 0x0100;  pbus->write(CmdFIFOReg, b);//_attente_cmd_vide
	b=( (size>>16) & 0xff ) + 0x0100; pbus->write(CmdFIFOReg, b);//_attente_cmd_vide
	b=( (size>>24) & 0xff ) + 0x0100; pbus->write(CmdFIFOReg, b);//_attente_cmd_vide
    #if 0 //old code -tb-
	b=(size & 0xff) + 0x0100;write_word(driver_fpga,REG_CMD,b);//_attente_cmd_vide
	b=( (size>>8) & 0xff ) + 0x0100;write_word(driver_fpga,REG_CMD,b);//_attente_cmd_vide
	b=( (size>>16) & 0xff ) + 0x0100;write_word(driver_fpga,REG_CMD,b);//_attente_cmd_vide
	b=( (size>>24) & 0xff ) + 0x0100;write_word(driver_fpga,REG_CMD,b);//_attente_cmd_vide
    #endif
	usleep(10000);	// attente pour mise en mode conf du fpga (10 msec)
	printf("on attend 0 :  ");  
//TODO: test -tb- if(lecture_data_FIFO_microbbv2()!=0) return -2;
	printf("\n");
	
	
    //file size is (usually?) 247942 bytes ->will finish at a==248 (a/2.5==99)
	for(a=0;a<1000;a++)
	{
		    //printf("--> %d%c (a:%i)\n",(int)(a/2.5),'%',a);//TODO: use next line instead of this line -tb-
		if(a%25==0){
		    printf("--> %d%c (a:%i)\n",(int)(a/2.5),'%',a);//TODO: use next line instead of this line -tb-
		    //printf("--> %d%c \n",(int)(a/2.5),'%');
			//TODO: needed?   _send_status_programmation(*numserie + (((int)(a/2.5))<<8)) 
            if(sendChargeBBStatusFunctionPtr) sendChargeBBStatusFunctionPtr(   *numserie + (((int)(a/2.5))<<8)   , numFifo);
		}
//TODO:test -tb-		if(lecture_data_FIFO_microbbv2()!=-1) return -3;		// erreur durant l'emission des data
		n=fread(filebuf,1,1000,fichier);
		if(n<=0)	break;
		//TODO: needed?   if(a%10==0)	led_B(_vert);
		//TODO: needed?   if(a%10==7)	led_B(_rouge);
		for(i=0;i<n;i++)
		{
			b=( (unsigned short) filebuf[i] ) + 0x0100; 
            pbus->write(CmdFIFOReg, b);
			// old code -tb- write_word(driver_fpga,REG_CMD, b); 
			_attente_cmd_vide
		}
	}
	printf(" programmation de la BBv2 terminee \n");
	//TODO: needed?   _send_status_programmation(*numserie+ (100<<8)) 
    if(sendChargeBBStatusFunctionPtr) sendChargeBBStatusFunctionPtr(   *numserie + (100<<8)  , numFifo);
	usleep(50000);	pbus->write(CmdFIFOReg ,  256);//  une data a zero
	usleep(50000);	pbus->write(CmdFIFOReg ,  256);//  une data a zero
	//usleep(50000);	write_word(driver_fpga,REG_CMD, (uint32_t) 256);	//  une data a zero
	//usleep(50000);	write_word(driver_fpga,REG_CMD, (uint32_t) 256);	//  une data a zero
	
	usleep(500000);	// laisser le temps pour lire le message d'erreur eventuel
	b=0x200;  pbus->write(CmdFIFOReg, b);  //fin de commande 
	//-tb- old code: b=0x200;  write_word(driver_fpga,REG_CMD, b);  //fin de commande 
	usleep(500000);	// laisser le temps pour lire le message d'erreur eventuel
	//printf("on attend 2 pour terminer : ");
    
  	printf("100%c - DONE\n",'%');

    if(sendChargeBBStatusFunctionPtr) sendChargeBBStatusFunctionPtr(   *numserie + (101<<8)  , numFifo);

//TODO: test -tb-
return 0;
    //removed this: -tb-
	//if(lecture_data_FIFO_microbbv2()!=2) return -4;
	//printf("\n");
	//TODO: needed?   _send_status_programmation(*numserie+ (101<<8)) 
	//return 0;
}

/*--------------------------------------------------------------------
 *    function:     chargeBBWithFile
 *    purpose:      load the FPGA configuration for the BBs
 *                     in cew.c: void	 mise_a_jour_bbv2(int recharge)
 *
 *    author:       Till Bergmann, 2013
 *
 *--------------------------------------------------------------------*/ //-tb-

void chargeBBWithFile(char * filename, int fromFifo)
{
    printf("chargeBBWithFile: >%s<, requested for FIFO %i\n",filename,fromFifo);//DEBUG
    //printf("------------> sendChargeBBStatusFunctionPtr is %p\n",sendChargeBBStatusFunctionPtr); exit(9);


FILE *mon_fichier;
int j=0,err=0;
int numserie;
//TODO: ? led_B(_rouge);

				
//TODO: _send_status_programmation(2)
printf("fichier %s ",filename);   // was /var/bbv2.rbf
if( (mon_fichier = fopen(filename,"rw")) )
	{
	for(j=0;j<10;j++)		// j'essaye 10 fois
		{
		//envoie_commande_standard_BBv2();
	    //changed 2013-11-11 -tb- envoie_commande_horloge( 20,  0,  3,  8,  2, 3);
	    envoie_commande_horloge( 20,  0,  1,  8,  2, 3);
		err=chargeBBWithFILEPtr(mon_fichier,&numserie,fromFifo);
		if(!err) break;
		}
	}
    
    if(!mon_fichier) printf("    ERROR: could not open file: %s\n",filename);
    
printf("***********   bilan de chargement :  numserie=%d  j=%d  err=%d  ********\n",numserie,j,err);
//envoie_commande_horloge();
//envoie_commande_horloge( X,  Retard,  Masque_BB,  Code_acqui,  Code_synchro, Nb_mots_lecture);
// is usually:
//Horloge: x=30 retard=0 Code_acqui=8 masque_BB=1  Nb_mots=3 Code_synchro=2, Nb_synchro=100000
//cmd 255 (6 octets) 1E 0 0 1 8 2 

//try:
	//envoie_commande_horloge( 30,  0,  1,  8,  2, 3); //2013-07 changed to X=20 -tb-
	    //changed 2013-11-11 -tb- envoie_commande_horloge( 20,  0,  3,  8,  2, 3);
	envoie_commande_horloge( 20,  0,  1,  8,  2, 3);

//int Table_nb_synchro[8]=_valeur_synchro;
//Nb_synchro=Table_nb_synchro[Code_synchro&0x3];//this was in void envoie_commande_horloge(void) but is probably not necessary (?) -tb-
//TODO: led_B(_vert);
return;
}




/*--------------------------------------------------------------------
 *    function:     setSLTtimerWithUTC
 *    purpose:      set the SLT timer register to UTC
 *                     
 *
 *    author:       Till Bergmann, 2013
 *
 *--------------------------------------------------------------------*/ //-tb-
 
#define kSetSLTtimerWithUTCFlag_Value     0x1     //init with "utcTime", else use system time in UTC
#define kSetSLTtimerWithUTCFlag_Verbose   0x2     //print output to console
#define kSetSLTtimerWithUTCFlag_ReadBack  0x4     //read back after setting (with a sleep(1))

uint64_t setSLTtimerWithUTC(uint32_t flags, uint64_t utcTime, uint64_t utcTimeOffset, uint64_t utcTimeCorrection100kHz)
{
    int useInputValueUTC = flags & kSetSLTtimerWithUTCFlag_Value;
    int beVerbose        = flags & kSetSLTtimerWithUTCFlag_Verbose;
    int readBack         = flags & kSetSLTtimerWithUTCFlag_ReadBack;

    struct timeval currenttime;//    struct timezone tz; is obsolete ... -tb-
    uint32_t currentSec = 0;  //I use currentSec to compute the the setpoint time - sorry, bad name (change to setpointTime in the future) -tb-
    gettimeofday(&currenttime,NULL);
    currentSec = currenttime.tv_sec;  
    
    if(useInputValueUTC){
        currentSec = utcTime;
    }else{//read from system
    }

    //take into account the offset:
    currentSec = currentSec - utcTimeOffset;
    
    uint32_t sltTimeLo = 0;  
    uint32_t sltTimeHi = 0;  
    uint64_t sltTime = 0;  
    int64_t timeDiff = 0;  
    sltTimeLo = pbus->read(SLTTimeLowReg);
    sltTimeHi = pbus->read(SLTTimeHighReg);
    sltTime = (((uint64_t)sltTimeHi << 32) | sltTimeLo) /100000 ;
    if(beVerbose) printf("Set SLT timer: UTC:%i  (current value  (hi: 0x%08x  lo:  0x%08x ): 0x%016lx, %u)\n",currentSec,sltTimeHi,sltTimeLo,sltTime,sltTime); //by Bernhard to see the time in the ipe4reader output
    timeDiff=currentSec-sltTime;
    //if((timeDiff < -1) || (timeDiff >1)){
    if(timeDiff != 0){
        if(beVerbose) printf("    Set SLT timer: timeDiff:  %li - set timer!\n", timeDiff);
        currentSec = currentSec + 1;//maybe this is not necessary
        sltTime = (((uint64_t)currentSec) * 100000LL) + utcTimeCorrection100kHz;//TODO: +1: this is a fix for the timestamp error (SLT timer register sends ...-1 to BB)
        sltTimeLo =  sltTime        & 0xffffffff;
        sltTimeHi = (sltTime >> 32) & 0xffffffff;
        if(beVerbose) printf("    Writing SLT timer reg: timeLo:  %u (0x%08x) - timeHi: %u  (0x%08x) \n", sltTimeLo, sltTimeLo, sltTimeHi, sltTimeHi);
        pbus->write(SLTTimeLowReg, sltTimeLo);
        //need to correct pd_fort/pd_faible in the status packet!!!!! -tb- 2014-07-18
        pbus->write(SLTTimeHighReg, sltTimeHi);
        if(readBack){
            sleep(1);
            sltTimeLo = pbus->read(SLTTimeLowReg);
            sltTimeHi = pbus->read(SLTTimeHighReg);
            sltTime = (((uint64_t)sltTimeHi << 32) | sltTimeLo) /100000 ;
            if(beVerbose) printf("    Set SLT timer: read back (current value  (hi: 0x%08x  lo:  0x%08x ): 0x%016lx, %u)\n",sltTimeHi,sltTimeLo,sltTime,sltTime); //by Bernhard to see the time in the ipe4reader output
        }
        #if 0
        pbus->write(SLTTimeLowReg, 0);
        pbus->write(SLTTimeHighReg, 0);
        sleep(1);
        #endif


    }else{
        if(beVerbose) printf("   timeDiff:  %li - OK!\n", timeDiff);
    }
    
    return sltTime;

}



/*--------------------------------------------------------------------
  globals
  --------------------------------------------------------------------*/

/*--------------------------------------------------------------------
  UDP communication
  --------------------------------------------------------------------*/

/*--------------------------------------------------------------------
  UDP communication - 1.) client communication
  --------------------------------------------------------------------*/








